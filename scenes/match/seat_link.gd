class_name SeatLink
extends RefCounted
## Another profile kept on this machine sat in at a seat past the first, GAME.md 3.8, picked from
## that player's switch in the pause menu, see [DriveSwitches]. The seat is that profile from then
## on: its name, its kart's dress, its plate, its favorite color where nobody else in the room is
## in it, and how it drives, and the maps it plays to the end go
## into that profile's statistics, see [MatchRecord]. Unlinked, it is a guest of the profile
## playing again. Only for the sitting: at the title every seat is a guest again, see
## [method Settings.unlink_all]. Here and on the host it shows at once; a client says it to the
## host, as it says a name, and the snapshot brings it back to every screen.


## [param slot]'s player plays as the profile kept as [param id] from now on, or as a guest again
## for an empty one, and it is saved. False when it cannot be: the first seat, the profile playing,
## or one another seat has.
static func link(match_node: Match, slot: PlayerSlot, id: String) -> bool:
	var player := slot.input as PlayerInput
	# A client's seat is the slot's from the next snapshot on, and the match's from the moment it
	# was given.
	if player == null and match_node.local_seats.has(slot.index):
		player = match_node.local_seats[slot.index]
	var settings := Game.settings
	if player == null or not settings.link_seat(player.seat, id):
		return false
	settings.save_to_disk()
	var seat := player.seat
	var named := settings.seat_name(seat)
	if named.is_empty():
		# A guest who never gave a name is handed a funny one again, rather than keep the name of
		# the profile that has just got up.
		var taken: Array[String] = []
		for other: PlayerSlot in match_node.slots:
			taken.append(other.player_name)
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		named = PlayerNames.pick(rng, taken)
	var style := settings.seat_style(seat)
	var plate := settings.seat_plate(seat)
	var color := settings.seat_color(seat)
	var session := SeatIdentity.client_of(slot)
	if session != null:
		session.claim_name(named, slot.index)
		if color >= 0:
			session.claim_color(color, slot.index)
		var mine := session.seat_at(slot.index)
		if mine != null and not style.is_empty():
			mine.style = style
		# Said the way the seat says them when it sits down, see [method NetSession._assign_slot].
		if not style.is_empty():
			session.rpc_id(1, &"_claim_style", style, seat)
		session.rpc_id(1, &"_claim_plate", plate, seat)
		return true
	slot.player_name = named
	SeatIdentity.paint(match_node, slot, color)
	if not style.is_empty():
		StyleStalls.dress(slot, style)
	if slot.kart != null and is_instance_valid(slot.kart):
		KartVisuals.plate_for_seat(slot.kart)
	return true
