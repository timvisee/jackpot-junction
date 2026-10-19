extends GdUnitTestSuite
## The room's emblem on the pause menu's corner, GAME.md 8.1c: every room but the House's own
## wears a sticker of its own, no two the same, and the menu shows the House's chip for a room with
## none and nothing at all with no room under it.

## The House's own room, which wears the House's chip.
const HOUSES: Array[StringName] = [&"count_room"]


func _rooms() -> Array[RoomLook]:
	var rooms: Array[RoomLook] = []
	for file: String in ResourceLoader.list_directory("res://data/rooms"):
		if file.ends_with(".tres"):
			rooms.append(load("res://data/rooms/" + file) as RoomLook)
	return rooms


func _arena(room: RoomLook) -> Arena:
	var arena: Arena = auto_free(Arena.new())
	arena.room = room
	return arena


func test_every_room_but_the_houses_wears_a_sticker_of_its_own() -> void:
	var seen: Array[String] = []
	var rooms := _rooms()
	assert_int(rooms.size()).is_greater(HOUSES.size())
	for room: RoomLook in rooms:
		if room.id in HOUSES:
			assert_object(room.emblem).is_null()
			continue
		assert_object(room.emblem).override_failure_message(room.id).is_not_null()
		assert_array(seen).not_contains([room.emblem.resource_path])
		seen.append(room.emblem.resource_path)


func test_the_menu_shows_the_rooms_sticker_or_the_houses_chip() -> void:
	var emblem: RoomEmblem = auto_free(RoomEmblem.new())
	var garage: RoomLook = load("res://data/rooms/garage.tres")
	emblem.show_for(_arena(garage))
	assert_bool(emblem.visible).is_true()
	assert_object(emblem.texture).is_same(garage.emblem)
	emblem.show_for(_arena(load("res://data/rooms/count_room.tres")))
	assert_bool(emblem.visible).is_true()
	assert_object(emblem.texture).is_same(RoomEmblem.HOUSE)
	emblem.show_for(null)
	assert_bool(emblem.visible).is_false()


func test_the_sticker_is_flat_and_drawn_at_twice_its_size() -> void:
	for room: RoomLook in _rooms():
		var sticker := room.emblem if room.emblem != null else RoomEmblem.HOUSE
		assert_object(sticker).is_not_instanceof(ViewportTexture)
		assert_int(sticker.get_width()).is_greater_equal(int(RoomEmblem.SIDE * 1.5))
