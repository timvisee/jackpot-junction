class_name JunctionPad
extends Area3D
## The cash-out pad, GAME.md 3.4. A kart standing on it drains its pot into banked score at a
## rate that doubles every few tenths of a second. Leaving keeps what was banked and resets the
## ramp; emptying the pot resets coins and mult. The match listens for the ticks and totals.
## Standing on the pad with an empty pot also patches a wounded kart up to full lives, GAME.md
## 3.6, as does taking somebody out. What the pad will not do is patch up a kart that is still
## carrying something: the pot goes in first and the life comes with the last coin of it. Nor
## will it do it twice in a row: after a patch-up the pad needs a moment before it has another
## one to give, so a kart parked in the middle of the arena can still be finished off there.
##
## The neon ring blinks when a local player is riding around with a big unbanked pot, harder
## and faster the more is at stake, as a nudge to come and cash it in. A pot that would win the
## match outright takes the ring over: flat gold, flat out, GAME.md 3.4.

signal bank_started(kart: Kart)
signal bank_tick(kart: Kart, points: int)
signal bank_completed(kart: Kart, coins: int, mult: float, total: int)

## The blink that says the match is one cash-out away, over and above the one that says a pot is
## worth protecting.
const WIN_RATE := 3.2
const WIN_ENERGY := 2.6
## Seconds before the pad patches the same kart up again, GAME.md 3.4. Without the wait a kart
## sitting on the pad is healed the instant it is wounded, and nobody can ever finish it off
## there; with it, whoever wounded it has a few seconds to come back and do it.
const PATCH_INTERVAL := 3.0

var rules: MatchRules
var radius := 2.5
## 2.0 during Last Call.
var payout_multiplier := 1.0
var puppet := false
## The ring's own material, handed over by the arena so the blink is not shared with the pads.
var ring_material: StandardMaterial3D
## How loudly the pad asks to be visited, 0 to 1. The match keeps it up to date.
var hint := 0.0
## Whether somebody on this screen would win the match by cashing in now. Also the match's to set.
var winning := false

## Kart instance id to channel state: t, carry, total, start_coins, start_mult, start_value.
var _channels: Dictionary[int, Dictionary] = {}
## Kart instance id to the seconds left before that kart may be patched up again. Kept here
## rather than on the kart, and kept while the kart is away, so that driving off the pad and
## straight back on is not a way around the wait.
var _patch_wait: Dictionary[int, float] = {}
var _pulse := 0.0


func _ready() -> void:
	collision_layer = Layers.TRIGGER
	collision_mask = Layers.KART | Layers.PROTECTED
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = 2.0
	shape.shape = cylinder
	shape.position = Vector3(0.0, 1.0, 0.0)
	add_child(shape)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## The blink: off below the hint threshold, then brighter and quicker the more is at stake. A
## winning pot is not more of the same thing, so it gets a note of its own rather than the top
## of the same scale: no colour left to travel, no rate left to climb, just gold on and off.
func _process(delta: float) -> void:
	if ring_material == null:
		return
	if winning:
		_pulse += delta * WIN_RATE
		var beat := 0.5 + 0.5 * sin(_pulse * TAU)
		ring_material.emission_energy_multiplier = WIN_ENERGY * (0.12 + 0.88 * beat)
		ring_material.albedo_color = Palette.CHIP_GOLD
		return
	_pulse += delta * (1.3 + 2.6 * hint)
	var wave := 0.5 + 0.5 * sin(_pulse * TAU)
	ring_material.emission_energy_multiplier = hint * (0.3 + 1.7 * wave)
	ring_material.albedo_color = Palette.NEON_MAGENTA.lerp(Palette.CHIP_GOLD, hint * wave * 0.6)


func _on_body_entered(body: Node3D) -> void:
	var kart := body as Kart
	if kart == null:
		return
	_channels[kart.get_instance_id()] = _new_channel()


func _on_body_exited(body: Node3D) -> void:
	var kart := body as Kart
	if kart == null:
		return
	_channels.erase(kart.get_instance_id())
	kart.channel_progress = -1.0


func _new_channel() -> Dictionary:
	return {
		"t": 0.0, "carry": 0.0, "total": 0, "start_coins": 0, "start_mult": 1.0, "start_value": 0.0
	}


func _physics_process(delta: float) -> void:
	if rules == null or puppet:
		return
	_step_patch_wait(delta)
	for id: int in _channels.keys():
		var kart := instance_from_id(id) as Kart
		if kart == null:
			_channels.erase(id)
			continue
		if not kart.is_active() or kart.pot.is_empty():
			kart.channel_progress = -1.0
			# Nothing to bank is nothing to wait for: the patch-up is owed straight away.
			if kart.is_active():
				_patch_up(kart)
			continue
		_step_channel(kart, _channels[id], delta)


func _step_channel(kart: Kart, channel: Dictionary, delta: float) -> void:
	if channel["start_value"] <= 0.0:
		channel["start_coins"] = kart.pot.coins
		channel["start_mult"] = kart.pot.mult
		channel["start_value"] = kart.pot.exact_value()
		bank_started.emit(kart)
	var t: float = channel["t"]
	var amount := Scoring.banked_between(t, t + delta, rules.bank_rate_base, kart.bank_doubling())
	channel["t"] = t + delta
	var taken := kart.pot.drain(amount)
	var carry: float = channel["carry"] + taken * payout_multiplier * kart.bank_payout()
	var points := floori(carry)
	channel["carry"] = carry - points
	if points > 0:
		channel["total"] = int(channel["total"]) + points
		bank_tick.emit(kart, points)
	kart.channel_progress = clampf(kart.pot.exact_value() / float(channel["start_value"]), 0.0, 1.0)
	if kart.pot.is_empty():
		var leftover := roundi(channel["carry"])
		var total := int(channel["total"]) + leftover
		if leftover > 0:
			bank_tick.emit(kart, leftover)
		bank_completed.emit(kart, channel["start_coins"], channel["start_mult"], total)
		# The whole pot is in: GAME.md 3.6 pays for that with the lost life back.
		_patch_up(kart)
		kart.pot.reset()
		kart.channel_progress = -1.0
		_channels[kart.get_instance_id()] = _new_channel()


## Patches a wounded kart up, unless the pad has given this one a life too recently to have
## another ready, GAME.md 3.4.
func _patch_up(kart: Kart) -> void:
	if not kart.is_wounded() or _patch_wait.get(kart.get_instance_id(), 0.0) > 0.0:
		return
	kart.restore_life()
	_patch_wait[kart.get_instance_id()] = PATCH_INTERVAL


## Counts the waits down, whether or not their kart is still standing here.
func _step_patch_wait(delta: float) -> void:
	for id: int in _patch_wait.keys():
		var left: float = _patch_wait[id] - delta
		if left <= 0.0:
			_patch_wait.erase(id)
		else:
			_patch_wait[id] = left
