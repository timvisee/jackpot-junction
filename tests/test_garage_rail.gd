extends GdUnitTestSuite
## The Garage's rail, GAME.md 9.4: the slot machines on it in to be fixed, a clock stopped beside
## the Showroom's door and a pegboard of tools behind the range. See [GarageRail].

const GARAGE_SCENE := preload("res://scenes/garage/garage.tscn")


## The Garage up, and its rail dressed: by the Garage itself, or here when it has not been.
func _rail() -> Array:
	var garage: Node3D = auto_free(GARAGE_SCENE.instantiate())
	var runner: GdUnitSceneRunner = scene_runner(garage)
	await runner.simulate_frames(60, 17)
	var match_node: Match = garage.get_node("Match")
	var rail := match_node.arena.get_node_or_null("GarageRail") as GarageRail
	if rail == null:
		rail = GarageRail.add_to(match_node)
	await runner.simulate_frames(2, 17)
	return [match_node, rail]


## One machine's door swung open with its reels on it, one taped OUT OF ORDER, a toolbox and a
## screwdriver by them; and the row still a row, lit by a big cash-out as anywhere.
func test_the_machines_are_in_for_repair() -> void:
	var got: Array = await _rail()
	var match_node: Match = got[0]
	var rail: GarageRail = got[1]
	var machines := match_node.arena.get_node("RailMachines") as RailMachines
	assert_int(machines.get_child_count()).is_equal(RailMachines.ALONG.size())
	var open := machines.get_node("Machine%d" % GarageRail.OPEN_MACHINE)
	assert_object(open.get_node_or_null("Hinge/Face")).is_not_null()
	for i: int in RailMachines.ALONG.size():
		if i != GarageRail.OPEN_MACHINE:
			assert_object(machines.get_node("Machine%d" % i).get_node_or_null("Face")).is_not_null()
	var spots := RailMachines.spots(match_node.arena)
	assert_object(rail.tag).is_not_null()
	assert_float(rail.tag.position.x).is_equal_approx(spots[GarageRail.TAGGED_MACHINE].x, 0.01)
	var words := rail.tag.get_node("Words") as Label3D
	assert_str(words.text.replace("\n", " ")).is_equal("OUT OF ORDER")
	assert_bool(rail.has_node("Toolbox")).is_true()
	assert_bool(rail.has_node("Screwdriver")).is_true()
	Events.bank_completed.emit(0, 100, 5.0, RailMachines.BIG_BANK)
	assert_float(machines._lit).is_equal(RailMachines.LIT)


## The clock beside the roller door, left of its frame and level with its lintel, stopped.
func test_a_clock_stopped_beside_the_door() -> void:
	var got: Array = await _rail()
	var match_node: Match = got[0]
	var rail: GarageRail = got[1]
	assert_object(rail.clock).is_not_null()
	var grid := match_node.arena.grid
	var door_left := grid.cell_center(Vector2i(Showroom.OPENING.x, 0)).x - grid.cell_size * 0.5
	var at := rail.clock.position
	assert_float(at.x).is_less(door_left)
	assert_float(at.x).is_greater(door_left - 1.5)
	assert_float(at.y).is_greater(Showroom.DOOR_TALL)
	var wall := grid.cell_center(Vector2i(Showroom.OPENING.x, 0)).z
	assert_float(at.z).is_between(wall, wall + grid.cell_size)
	# Nothing in it moves: the time it stopped at is the time it shows.
	var before := rail.clock.global_transform
	await get_tree().process_frame
	assert_bool(rail.clock.global_transform.is_equal_approx(before)).is_true()


## The pegboard on the rail behind the range, clear of the first machine along it.
func test_a_pegboard_behind_the_range() -> void:
	var got: Array = await _rail()
	var match_node: Match = got[0]
	var rail: GarageRail = got[1]
	assert_object(rail.pegboard).is_not_null()
	var board := rail.pegboard.position
	var near := INF
	for target: Target in match_node.arena.targets:
		near = minf(near, absf(target.global_position.x - board.x))
		assert_float(board.z).is_less(target.global_position.z)
	assert_float(near).is_less(match_node.arena.grid.cell_size * 2.0)
	var first := RailMachines.spots(match_node.arena)[0]
	var reach := GarageRail.BOARD.x * 0.5 + RailMachines.BODY.x * 0.5
	assert_float(first.x - board.x).is_greater_equal(reach)
