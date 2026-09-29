class_name LocalSeats
extends RefCounted
## On a client, the players at it, GAME.md 10.3, each a [ClientSeat]: the first, made from what the
## session was given before it joined, and anybody who sat down beside them. Kept apart from
## [NetSession] so that file stays about the connection.

var seats: Array[ClientSeat] = []


## Every player here, the first made from [param input], [param named] and [param dressed] the
## first time they are asked for.
func here(input: KartInput, named: String, dressed: PackedInt32Array) -> Array[ClientSeat]:
	if seats.is_empty():
		seats.append(ClientSeat.make(0, input, named, dressed))
	return seats


## The player in [param index], or null for a seat played elsewhere.
func at(index: int) -> ClientSeat:
	for each: ClientSeat in seats:
		if index >= 0 and each.slot == index:
			return each
	return null


func numbered(number: int) -> ClientSeat:
	for each: ClientSeat in seats:
		if each.seat == number:
			return each
	return null


## A newcomer on [param device], given the lowest number nobody here has, and the name and dress
## that seat of the settings keeps. A player on any device already here keeps the one they last
## used, so the two do not both answer the newcomer's, the way [method Match.join_human] has it.
## Null for a device somebody here already sits at, whose seat may still be on its way.
func sit_down(device: int) -> ClientSeat:
	for each: ClientSeat in seats:
		var player := each.input as PlayerInput
		if player != null and player.device == DeviceInput.ANY:
			var chosen := player.last_device
			if chosen == DeviceInput.ANY or chosen == device:
				chosen = DeviceInput.KEYBOARD if device >= 0 else 0
			player.device = chosen
	# A second press on a pad whose seat has been asked for is the same player, not another one.
	for each: ClientSeat in seats:
		var player := each.input as PlayerInput
		if player != null and player.device == device:
			return null
	var number := 0
	while numbered(number) != null:
		number += 1
	var settings := Game.settings
	var named := settings.player_names[number] if number < settings.player_names.size() else ""
	var dressed := PackedInt32Array()
	if number < settings.kart_styles.size():
		dressed = PackedInt32Array(settings.kart_styles[number])
	var made := ClientSeat.make(number, PlayerInput.new(device, number), named, dressed)
	seats.append(made)
	return made


## Takes [param each] off [param match_node]: its seat is somebody else's now, or nobody's.
func stand_up(each: ClientSeat, match_node: Match) -> void:
	seats.erase(each)
	if match_node == null or each.slot < 0:
		return
	# Whether or not a snapshot has built the slot yet: under load one can be told its seat and
	# shown out of it before it has, and a seat left on the books would be played here the moment
	# the slot arrived.
	match_node.drop_local_seat(each.slot)
	if each.slot >= match_node.slots.size():
		return
	var slot := match_node.slots[each.slot]
	if slot.input == each.input:
		slot.input = KartInput.new()
	if slot.kart != null:
		slot.kart.input = slot.input
	if match_node.hud != null:
		match_node.hud.remove_block(slot)
	match_node.refresh_listener()
