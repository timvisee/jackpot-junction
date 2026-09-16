class_name JunctionPad
extends Area3D
## The cash-out pad, GAME.md 3.4. A kart standing on it drains its pot into banked score at a
## rate that doubles every few tenths of a second. Leaving keeps what was banked and resets the
## ramp; emptying the pot resets coins and mult. The match listens for the ticks and totals.
## Driving onto the pad also patches a wounded kart up to full lives, GAME.md 3.6.

signal bank_started(kart: Kart)
signal bank_tick(kart: Kart, points: int)
signal bank_completed(kart: Kart, coins: int, mult: float, total: int)

var rules: MatchRules
var radius := 2.5
## 2.0 during Last Call.
var payout_multiplier := 1.0
var puppet := false

## Kart instance id to channel state: t, carry, total, start_coins, start_mult, start_value.
var _channels: Dictionary[int, Dictionary] = {}


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
		if kart.alive and not kart.falling and not kart.frozen and kart.is_wounded():
			kart.restore_life()
		if not kart.alive or kart.falling or kart.frozen or kart.pot.is_empty():
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
		kart.pot.reset()
		kart.channel_progress = -1.0
		_channels[kart.get_instance_id()] = _new_channel()
