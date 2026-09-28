class_name SeatIdentity
extends RefCounted
## What a player at this machine is called and what color they are, changed from their switch in
## the pause menu in the lobby and the Garage, GAME.md 4.4. Here, and on the host, it happens at
## once; a client asks the host, which decides, and the snapshot brings the answer back to every
## screen, its own included. A name is kept in the seat's settings, where the Players tab keeps it.
## A color goes with the player from room to room the way the one they were given always has.


## A name typed for [param slot]'s player. An empty one is the seat going back to being handed a
## funny name, which it is at the next match; until then it keeps the one it has.
static func rename(slot: PlayerSlot, typed: String) -> void:
	var player := slot.input as PlayerInput
	if player == null or player.seat < 0:
		return
	var name := PlayerNames.clean(typed)
	var settings := Game.settings
	if player.seat < settings.player_names.size() and settings.player_names[player.seat] != name:
		settings.player_names[player.seat] = name
		settings.save_to_disk()
	var session := _client_of(slot)
	if session != null:
		session.claim_name(name, slot.index)
	if not name.is_empty():
		slot.player_name = name


## The next color round from [param slot]'s that nobody else in [param match_node] is in, or its
## own when every other one is taken.
static func next_color(match_node: Match, slot: PlayerSlot) -> int:
	var count := Palette.PLAYER_COLORS.size()
	for step: int in range(1, count):
		var color := posmod(slot.color_index + step, count)
		if is_free(match_node, slot, color):
			return color
	return slot.color_index


## [param slot]'s player on to the next free color: at once here and on the host, and on a client
## asked of the host.
static func recolor(match_node: Match, slot: PlayerSlot) -> void:
	var color := next_color(match_node, slot)
	if color == slot.color_index:
		return
	var session := _client_of(slot)
	if session != null:
		session.claim_color(color, slot.index)
		return
	paint(match_node, slot, color)


## Puts [param slot] and its kart in [param color], unless somebody else in the room is already in
## it: no two karts are ever the same color.
static func paint(match_node: Match, slot: PlayerSlot, color: int) -> void:
	if color < 0 or color >= Palette.PLAYER_COLORS.size() or not is_free(match_node, slot, color):
		return
	slot.color_index = color
	if slot.kart != null and is_instance_valid(slot.kart):
		KartVisuals.recolor(slot.kart, color)


## Whether nobody in [param match_node] but [param slot] is in [param color]. An emptied seat,
## see [VacantSeat], is nobody: whoever sits down in it next is put in a free one.
static func is_free(match_node: Match, slot: PlayerSlot, color: int) -> bool:
	for other: PlayerSlot in match_node.slots:
		if other != slot and other.color_index == color and not other.input is VacantSeat:
			return false
	return true


## The session to ask, when [param slot] is one of this client's own players; null here and on the
## host, where it is this machine's to decide.
static func _client_of(slot: PlayerSlot) -> NetSession:
	var session := Net.session if Net.online() else null
	if session == null or session.is_host:
		return null
	var own := session.local_slot == slot.index or session.seat_at(slot.index) != null
	return session if own else null
