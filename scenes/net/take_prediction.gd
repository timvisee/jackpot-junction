class_name TakePrediction
extends RefCounted
## What a client's own kart takes off the table, answered here, GAME.md 10.3: the chips, dice,
## boxes and cards it drives over and the Royal Flush pads it drives onto. Waiting a round trip for
## the host to say a chip was taken is a kart driving through a chip that is still there, and then
## the chip flying into it from behind; so the take is seen and heard the tick the kart gets there,
## and what it was worth, the item in a box and whether a flush came of a pad, stay the host's.
##
## Only this machine's own karts, and only where the host follows them: the host takes this
## machine's word for where its kart is, see [KartPrediction], so it finds the kart on the chip on
## the same tick and nearly always agrees. When it does not, the chip or the pad is back as the
## host has it once [constant Pickup.PREDICTED_HOLD] has run out.

## How many takes this machine has made, and how many of those the host did not agree to, for the
## debug overlay and the multiplayer check. The second is what a pickup or a pad put back is seen
## as: a chip flying into the kart and then lying on the floor again.
var taken := 0
var put_back := 0

## How long a box taken here keeps the kart from taking another, for the host to say what is in it.
var _boxes_left := 0.0
## Cards taken here that the host has not dealt into the hand yet, and how long each is waited for,
## and how many the hand held when last looked at, for telling when one has been.
var _cards: Array[float] = []
var _hand := 0
## The body of the kart it last looked after, and that kart, for the pads to measure it by: found
## once a kart rather than every tick.
var _body: CollisionShape3D
var _body_of: Kart
## What has been taken here and not settled yet, to count how it went. Untyped, since what the host
## took off the floor has been freed by the time it is looked at again.
var _waiting: Array = []


## One tick of [param prediction]'s kart, just driven: whatever it has reached is taken.
func step(match_node: Match, prediction: KartPrediction, delta: float) -> void:
	_boxes_left = maxf(_boxes_left - delta, 0.0)
	for i: int in range(_cards.size() - 1, -1, -1):
		_cards[i] -= delta
		if _cards[i] <= 0.0:
			_cards.remove_at(i)
	var kart := prediction.kart
	_count_settled(kart.slot)
	var hand := kart.jokers.jokers.size()
	for _dealt: int in clampi(hand - _hand, 0, _cards.size()):
		_cards.pop_front()
	_hand = hand
	if match_node.arena == null or not kart.is_active():
		return
	var where := prediction.simulated_transform()
	for value: Variant in match_node.puppet_pickups.values():
		if not is_instance_valid(value):
			continue
		var pickup := value as Pickup
		if not pickup.predicted_take() and _takes(kart, pickup):
			if pickup.within_reach(kart, where.origin):
				_take(kart, pickup)
	if kart.is_decoy():
		return
	for pad: FlushPad in match_node.arena.flush_pads:
		if pad.predicted_claim() or not pad.can_be_taken_by(kart):
			continue
		if pad.would_take(_body_on(kart), where):
			pad.predict_claim(kart)
			Audio.ahead(&"pad_claimed", [kart.slot])
			taken += 1
			_waiting.append(pad)


func _body_on(kart: Kart) -> CollisionShape3D:
	if kart != _body_of or not is_instance_valid(_body):
		_body_of = kart
		_body = kart.get_node_or_null(^"CollisionShape3D") as CollisionShape3D
	return _body


## Whether the kart may take [param pickup] as far as this machine knows: the pickup's own rule,
## with the box and the cards taken here but not yet the host's counted in.
func _takes(kart: Kart, pickup: Pickup) -> bool:
	if pickup is ItemBox and _boxes_left > 0.0:
		return false
	if pickup is FloorJoker and _hand + _cards.size() >= kart.jokers.capacity():
		return false
	return pickup.can_collect(kart)


func _take(kart: Kart, pickup: Pickup) -> void:
	if pickup is ItemBox:
		_boxes_left = Pickup.PREDICTED_HOLD
	elif pickup is FloorJoker:
		_cards.append(Pickup.PREDICTED_HOLD)
	var heard := pickup.heard_as(kart)
	pickup.predict_take(kart)
	if not heard.is_empty():
		Audio.ahead(heard[0], heard[1])
	taken += 1
	_waiting.append(pickup)


## What the host made of the takes waiting on it: a pickup it took off the floor, or a pad it gave
## [param slot] or cleared for a flush, agreed; anything back as it was, put back.
func _count_settled(slot: int) -> void:
	for i: int in range(_waiting.size() - 1, -1, -1):
		var node: Variant = _waiting[i]
		if not is_instance_valid(node) or (node as Node).is_queued_for_deletion():
			_waiting.remove_at(i)
			continue
		var pickup := node as Pickup
		var pad := node as FlushPad
		if pickup != null and not pickup.predicted_take():
			put_back += 1
			_waiting.remove_at(i)
		elif pad != null and not pad.predicted_claim():
			if pad.owner_slot != slot and not pad.is_disabled():
				put_back += 1
			_waiting.remove_at(i)


func debug_text() -> String:
	return "takes %d, %d put back" % [taken, put_back]
