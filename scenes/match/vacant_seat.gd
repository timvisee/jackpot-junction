class_name VacantSeat
extends KartInput
## A seat somebody got up from in the waiting room online, GAME.md 9.6 and 10.3. It is not handed
## to a bot, since bots only come into a match once it starts, but left empty: the kart goes out of
## the room with a puff in its color, the one it goes out with on every screen, and stays out until
## somebody new sits down in the seat, when it comes back in for them as a kart does after dying.
## Nobody drives it, not even a brain, and nothing counts it: it is neither a player nor a bot.


## Empties [param slot] of [param match_node].
static func leave(match_node: Match, slot: PlayerSlot) -> void:
	# What whoever got up did in here is theirs, written down before the seat is emptied.
	MatchRecord.seat_leaving(match_node, slot)
	var kart := slot.kart
	var brain := kart.get_node_or_null("Brain")
	if brain != null:
		brain.queue_free()
	slot.input = VacantSeat.new()
	kart.input = slot.input
	if kart.alive:
		Burst.spawn(kart.get_parent(), kart.global_position, slot.color(), 1.0, 20)
	# Down the way a kart goes down, with none of what dying does: nothing is dropped, banked or
	# counted, and no clock is set running to bring it back.
	kart.alive = false
	kart.falling = false
	kart.collision_layer = 0
	kart.collision_mask = 0
	kart.motor.velocity = Vector3.ZERO
	kart.velocity = Vector3.ZERO
	(kart.get_node("Body") as Node3D).visible = false
	kart.smoke.emitting = false
	kart.enable_sound(false)
	slot.respawn_left = INF
	# On no team while empty, so it counts toward none of them, GAME.md 3.14.
	slot.team = -1
	match_node.camera_rig.targets.erase(kart)
	match_node.refresh_listener()
	if match_node.hud != null:
		match_node.hud.remove_block(slot)
	Events.player_left.emit(slot.index)


## Somebody is sitting down in [param slot]: its kart comes back into the room for them, on the
## next tick, as a kart does after dying, and in the next free color if its own was taken while
## the seat was empty.
static func fill(match_node: Match, slot: PlayerSlot) -> void:
	if not SeatIdentity.is_free(match_node, slot, slot.color_index):
		SeatIdentity.paint(match_node, slot, SeatIdentity.next_color(match_node, slot))
	# Whoever sits down goes to the smallest team, GAME.md 3.14.
	if match_node.rules.teams > 0:
		SeatIdentity.join_team(slot, Teams.smallest(match_node.slots, match_node.rules.teams))
	slot.respawn_left = 0.0
	if not match_node.camera_rig.targets.has(slot.kart):
		match_node.camera_rig.targets.append(slot.kart)
