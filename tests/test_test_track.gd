extends GdUnitTestSuite
## The test track, GAME.md 9.4: the room before the Garage. A road with corners on it, a wall of
## boxes to shoot through, a straight to open the bottle on, a chicane to drift and a room at the
## end, with a portal to the Garage proper in the middle of it.

const TRACK: ArenaLayout = preload("res://data/maps/test_track.tres")
const GARAGE: ArenaLayout = preload("res://data/maps/garage.tres")
const GARAGE_SCENE := preload("res://scenes/garage/garage.tscn")


## Every cell that can be driven to from the spawn, treating [param blocking] as solid.
func _reachable(grid: ArenaGrid, blocking: Array[String]) -> Dictionary[Vector2i, bool]:
	var start: Vector2i = grid.spawns[0]
	var seen: Dictionary[Vector2i, bool] = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for step: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var next := cell + step
			if seen.has(next) or next.x < 0 or next.y < 0:
				continue
			if next.x >= grid.width or next.y >= grid.height:
				continue
			if grid.glyph(next) in blocking:
				continue
			seen[next] = true
			queue.append(next)
	return seen


func test_the_track_is_a_valid_map_with_one_way_round_it() -> void:
	assert_array(TRACK.validate()).is_empty()
	var grid := TRACK.parse()
	assert_int(grid.spawns.size()).is_greater_equal(1)
	assert_int(grid.portals.size()).is_equal(1)
	# Nothing to collect and nothing to bank: it is a road.
	assert_object(grid.junction).is_equal(Rect2i())
	assert_int(grid.coin_pads.size()).is_equal(0)
	assert_int(grid.jackpots.size()).is_equal(0)
	assert_int(grid.pits.size()).is_equal(0)
	# A wall of boxes across it, and it is a wall: the way on is through them.
	assert_int(grid.crates.size()).is_greater_equal(3)
	var standing := _reachable(grid, ["#", "B"] as Array[String])
	assert_bool(standing.has(grid.portals[0])).is_false()
	# Once they are broken, every last cell of the track can be driven to.
	var broken := _reachable(grid, ["#"] as Array[String])
	assert_bool(broken.has(grid.portals[0])).is_true()
	for y: int in grid.height:
		for x: int in grid.width:
			var cell := Vector2i(x, y)
			if grid.glyph(cell) in ["#", "B"]:
				continue
			(
				assert_bool(broken.has(cell))
				. override_failure_message("cell %d,%d is walled off from the start" % [x, y])
				. is_true()
			)


## Both rooms have a way to the other, so going once locks nothing away.
func test_each_room_has_a_portal_to_the_other() -> void:
	assert_int(GARAGE.parse().portals.size()).is_equal(1)
	assert_int(TRACK.parse().portals.size()).is_equal(1)


func test_the_first_visit_from_the_title_is_the_track_and_the_rest_are_not() -> void:
	var before := Game.settings.seen_test_track
	var path := Game.settings.path
	Game.settings.path = "user://test_seen_track.cfg"
	Game.settings.seen_test_track = false
	assert_str(String(Game.next_garage_room())).is_equal(String(Game.ROOM_TRACK))
	assert_bool(Game.settings.seen_test_track).is_true()
	assert_str(String(Game.next_garage_room())).is_equal(String(Game.ROOM_GARAGE))
	Game.settings.seen_test_track = before
	Game.settings.path = path
	Game.garage_room = Game.ROOM_GARAGE


## The track is a road: nobody is parked on it, and the signs name the buttons rather than the
## furniture, because there is none.
func test_the_track_room_has_no_dummies_and_faces_the_kart_down_the_road() -> void:
	Game.garage_room = Game.ROOM_TRACK
	var garage: Node3D = auto_free(GARAGE_SCENE.instantiate())
	var runner: GdUnitSceneRunner = scene_runner(garage)
	await runner.simulate_frames(60, 17)
	var match_node: Match = garage.get_node("Match")
	Game.garage_room = Game.ROOM_GARAGE
	assert_bool(garage.on_track).is_true()
	assert_int(match_node.slots.size()).is_equal(1)
	assert_int(match_node.arena.portals.size()).is_equal(1)
	# Pointed along the opening straight rather than at the middle of the map.
	var nose := -match_node.kart_of(0).global_basis.z
	assert_float(nose.x).is_greater(0.7)
