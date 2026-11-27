extends GdUnitTestSuite
## A kart outside the room it plays in respawned, GAME.md 3.6: off the room's grid, inside a wall,
## or sunk under the floor, once it has been out for half a second, as after a death but with its
## pot its own still; a kart on the floor left where it is; and nothing done on a client's copy of
## a match, whose karts the host moves.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _start_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 120.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new(), KartInput.new()]
	match_node.start(inputs, 31)
	return match_node


## The first wall cell of [param grid], in reading order.
func _a_wall(grid: ArenaGrid) -> Vector2i:
	for y: int in grid.height:
		for x: int in grid.width:
			if grid.is_wall(Vector2i(x, y)):
				return Vector2i(x, y)
	return Vector2i(-1, -1)


func test_what_is_out_of_the_room() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(5)
	var grid := match_node.arena.grid
	var size := grid.world_size()
	assert_bool(KartBounds.outside(grid, Vector3(size.x, 0.0, 0.0))).is_true()
	assert_bool(KartBounds.outside(grid, Vector3(0.0, 0.0, -size.y))).is_true()
	assert_bool(KartBounds.outside(grid, grid.cell_center(_a_wall(grid)))).is_true()
	var under := match_node.arena.junction_position + Vector3.DOWN * 4.0
	assert_bool(KartBounds.outside(grid, under)).is_true()
	var over := match_node.arena.junction_position + Vector3.UP * 4.0
	assert_bool(KartBounds.outside(grid, over)).is_true()
	assert_bool(KartBounds.outside(grid, match_node.slots[0].kart.global_position)).is_false()


## Carried off the grid and into a wall, two karts come back to the room, their pots kept, and so
## does one up over the floor; the one on the floor stays put.
func test_a_kart_out_of_the_room_is_respawned() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(30)
	var grid := match_node.arena.grid
	var away := match_node.slots[0].kart
	var walled := match_node.slots[1].kart
	var staying := match_node.slots[2].kart
	away.pot.add_coins(40)
	away.global_position = Vector3(grid.world_size().x * 2.0, 0.0, 0.0)
	walled.global_position = grid.cell_center(_a_wall(grid))
	var stood := staying.global_position
	await await_millis(1200)
	assert_bool(KartBounds.outside(grid, away.global_position)).is_false()
	assert_bool(KartBounds.outside(grid, walled.global_position)).is_false()
	# Up over the floor, where nothing in a match lifts a kart, held there rather than let drop
	# back of itself: brought back once more.
	var respawned: Array[int] = []
	var count := func(slot: int, _at: Vector3) -> void: respawned.append(slot)
	Events.kart_respawned.connect(count)
	away.set_physics_process(false)
	away.global_position += Vector3.UP * 6.0
	await await_millis(1200)
	Events.kart_respawned.disconnect(count)
	away.set_physics_process(true)
	assert_array(respawned).contains([0])
	assert_float(away.global_position.y).is_less(KartBounds.ABOVE)
	assert_bool(away.alive).is_true()
	assert_int(away.pot.coins).is_equal(40)
	assert_float(staying.global_position.distance_to(stood)).is_less(2.0)


## Out for less than half a second, as a kart shoved at a wall might be for a moment, it is left.
func test_a_moment_out_is_left_alone() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(30)
	var grid := match_node.arena.grid
	var kart := match_node.slots[0].kart
	var stood := kart.global_position
	kart.global_position = Vector3(grid.world_size().x * 2.0, 0.0, 0.0)
	await await_millis(150)
	kart.global_position = stood
	await await_millis(800)
	assert_float(kart.global_position.distance_to(stood)).is_less(2.0)


## On a client's copy the host moves the karts: nothing is respawned there.
func test_a_client_respawns_nothing() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(30)
	match_node.puppet = true
	var kart := match_node.slots[0].kart
	var far := Vector3(match_node.arena.grid.world_size().x * 2.0, 0.0, 0.0)
	kart.global_position = far
	await await_millis(1000)
	assert_float(kart.global_position.distance_to(far)).is_less(0.5)
	match_node.puppet = false
