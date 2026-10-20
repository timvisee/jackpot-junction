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
## A kart standing on the pad also refills its nitro tank several times as fast, GAME.md 3.4.
## Cashing out parks a kart in the open in the middle of the arena for a couple of seconds, so
## the pad hands it the one thing that gets it out of there again.
##
## The pad calls for attention when a local player is riding around with a big unbanked pot,
## louder the more is at stake, as a nudge to come and cash it in, and in a note of its own for a
## pot that would win the match outright, GAME.md 3.4. How it calls is the room's, a [JunctionCue]
## the room built on the pad's face: a wheel turning, bulbs chasing, or the House's magenta ring.

signal bank_started(kart: Kart)
signal bank_tick(kart: Kart, points: int)
signal bank_completed(kart: Kart, coins: int, mult: float, total: int)

## Seconds before the pad patches the same kart up again, GAME.md 3.4. Without the wait a kart
## sitting on the pad is healed the instant it is wounded, and nobody can ever finish it off
## there; with it, whoever wounded it has a few seconds to come back and do it.
const PATCH_INTERVAL := 3.0

var rules: MatchRules
var radius := 2.5
## 2.0 during Last Call.
var payout_multiplier := 1.0
var puppet := false
## The room's call to attention on the pad's face, handed over by the arena once the room has
## built it, see [method RoomKit.junction]. The pad plays it; the room decided what it is.
var cue: JunctionCue
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


func _ready() -> void:
	collision_layer = Layers.TRIGGER
	# Puppets too, so a client's own kart gets the faster tank on the tick it drives on rather
	# than a round trip later, GAME.md 10.3. The pad is in the same place on both machines, so
	# who is standing on it is as safe to answer here as who is standing on a turbo pad. Banking
	# is not: see below, that stays the host's.
	collision_mask = Layers.KART | Layers.PROTECTED | Layers.PUPPET
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = 2.0
	shape.shape = cylinder
	shape.position = Vector3(0.0, 1.0, 0.0)
	add_child(shape)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## The call to attention, GAME.md 3.4: quiet below the hint threshold, then louder the more is
## at stake, and a note of its own for a winning pot. Held steady for a player who asked for fewer
## flashes, 8.5.
func _process(delta: float) -> void:
	if cue != null:
		cue.play(delta, hint, winning, Game.settings.flash_reduction)


func _on_body_entered(body: Node3D) -> void:
	var kart := body as Kart
	if not _ours(kart):
		return
	kart.junction_recharge = rules.junction_nitro_recharge
	# A kart on the puppet layer is either somebody else's, drawn here where the host last said
	# it was, or this client's own. Neither one's pot is this pad's to drain: banking is decided
	# once, on the host, and arrives in the snapshot.
	if kart.puppet:
		return
	_channels[kart.get_instance_id()] = _new_channel()


func _on_body_exited(body: Node3D) -> void:
	var kart := body as Kart
	if not _ours(kart):
		return
	kart.junction_recharge = 1.0
	_channels.erase(kart.get_instance_id())
	kart.channel_progress = -1.0


## Whether this kart belongs to the same match as this pad. A host match and a puppet match can
## share a scene tree, in tests and in a future split screen, and they share the physics space
## with it: without this the pad in one room would bank and refuel karts standing in the other.
## Every kart in a match holds the same [MatchRules] instance the pad was handed.
func _ours(kart: Kart) -> bool:
	return kart != null and rules != null and kart.rules == rules


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


## Whether [param kart] is in the middle of a cash-out here, with some of its pot still to go in.
func is_banking(kart: Kart) -> bool:
	var channel: Dictionary = _channels.get(kart.get_instance_id(), {})
	return (
		not channel.is_empty() and float(channel["start_value"]) > 0.0 and not kart.pot.is_empty()
	)


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
