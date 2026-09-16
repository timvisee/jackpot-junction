class_name JunctionPad
extends Area3D
## The cash-out pad, GAME.md 3.4. A kart standing on it drains its pot into banked score at a
## rate that doubles every few tenths of a second. Leaving keeps what was banked and resets the
## ramp; emptying the pot resets coins and mult. The match listens for the ticks and totals.
## Banking a pot dry also patches a wounded kart up to full lives, GAME.md 3.6, as does taking
## somebody out. The patch-up is the reward for finishing the cash-out, not for arriving: a
## wounded kart has to stand there with everything it is carrying until the pot is empty.
##
## The neon ring blinks when a local player is riding around with a big unbanked pot, harder
## and faster the more is at stake, as a nudge to come and cash it in.

signal bank_started(kart: Kart)
signal bank_tick(kart: Kart, points: int)
signal bank_completed(kart: Kart, coins: int, mult: float, total: int)

var rules: MatchRules
var radius := 2.5
## 2.0 during Last Call.
var payout_multiplier := 1.0
var puppet := false
## The ring's own material, handed over by the arena so the blink is not shared with the pads.
var ring_material: StandardMaterial3D
## How loudly the pad asks to be visited, 0 to 1. The match keeps it up to date.
var hint := 0.0

## Kart instance id to channel state: t, carry, total, start_coins, start_mult, start_value.
var _channels: Dictionary[int, Dictionary] = {}
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


## True while any kart is banking.
func is_busy() -> bool:
	return not _channels.is_empty()


## The blink: off below the hint threshold, then brighter and quicker the more is at stake.
func _process(delta: float) -> void:
	if ring_material == null:
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
	for id: int in _channels.keys():
		var kart := instance_from_id(id) as Kart
		if kart == null:
			_channels.erase(id)
			continue
		if not kart.is_active() or kart.pot.is_empty():
			kart.channel_progress = -1.0
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
		if kart.is_wounded():
			kart.restore_life()
		kart.pot.reset()
		kart.channel_progress = -1.0
		_channels[kart.get_instance_id()] = _new_channel()
