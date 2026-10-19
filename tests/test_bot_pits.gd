extends GdUnitTestSuite
## Keeping a bot out of the holes, GAME.md 9.1: paths that keep clear of them, and the controls
## played forward against them as the last word on the driving, see [BotPits].

const DEFAULT_RULES: MatchRules = preload("res://data/match/default.tres")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LUCKY_CROSSING: ArenaLayout = preload("res://data/maps/lucky_crossing.tres")

var _runner: GdUnitSceneRunner


## A running match of two bots on the default map, Lucky Crossing, whose holes sit above and
## below the Junction.
func _match() -> Match:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [BotInput.new(), BotInput.new()]
	match_node.start(inputs, 9)
	return match_node


## GAME.md 9.1: the floor right round a hole is dear to cross, so a path past one keeps a cell
## clear of it where the room allows, rather than hugging it like a wall.
func test_paths_keep_a_cell_clear_of_a_hole() -> void:
	var grid := LUCKY_CROSSING.parse()
	var nav := ArenaNav.new(grid)
	var rect := grid.pits[0]
	var row := rect.position.y
	var from := grid.cell_center(Vector2i(rect.position.x - 4, row))
	var to := grid.cell_center(Vector2i(rect.end.x + 3, row))
	var grown := rect.grow(1)
	var path := nav.path(from, to)
	assert_int(path.size()).is_greater(5)
	for point: Vector3 in path:
		var cell := nav.world_to_cell(point)
		(
			assert_bool(grown.has_point(cell))
			. override_failure_message("path runs beside the hole at %s" % cell)
			. is_false()
		)


## GAME.md 9.1: a kart goes down a hole when any corner of it touches the edge, not when its
## middle arrives, so a short cut has to leave room for a kart's width either side of its line.
func test_a_short_cut_leaves_room_for_the_whole_kart() -> void:
	var grid := LUCKY_CROSSING.parse()
	var nav := ArenaNav.new(grid)
	var rect := grid.pits[0]
	var pit := grid.rect_center(rect)
	var edge := grid.rect_size(rect).x * 0.5
	# A run along the hole's side a hand's width off its cells: clear for its middle, not for a
	# kart a meter and a bit across.
	var beside := pit + Vector3(edge + 0.3, 0.0, 0.0)
	var along := Vector3(0.0, 0.0, 3.0)
	assert_bool(nav.clear_run(beside - along, beside + along, 0.0)).is_true()
	assert_bool(nav.clear_run(beside - along, beside + along, BotDrive.SWATHE)).is_false()
	# A kart's width and more away it is clear either way, and one across the hole never is.
	var clear := pit + Vector3(edge + 1.0, 0.0, 0.0)
	assert_bool(nav.clear_run(clear - along, clear + along, BotDrive.SWATHE)).is_true()
	var across := Vector3(edge + 3.0, 0.0, 0.0)
	assert_bool(nav.clear_run(pit - across, pit + across, 0.0)).is_false()


## GAME.md 9.1: paths go around a pit, but a pit stops nothing and blocks no raycast, so a bot
## cutting a corner would drive straight over one. Its controls are played forward against the
## holes, and where they lead in it takes another wheel and turns out.
func test_a_bot_turns_out_of_a_pit_it_is_headed_for() -> void:
	var match_node := _match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	var nav := match_node.nav
	var pit := match_node.arena.grid.rect_center(match_node.arena.grid.pits[0])
	assert_bool(nav.is_pit_at(pit)).is_true()
	assert_bool(nav.is_pit_at(match_node.arena.junction_position)).is_false()
	# Driven flat out straight at the hole on nitro, the wheel dead ahead.
	kart.global_position = pit + Vector3(5.0, 0.0, 0.8)
	kart.face(Vector3(-1.0, 0.0, 0.0))
	kart.motor.forward_speed = kart.stats.top_speed
	kart.motor.velocity = kart.motor.forward_vector() * kart.stats.top_speed
	brain.input.steer = 0.0
	brain.input.throttle = 1.0
	brain.input.brake = 0.0
	brain.input.nitro = true
	brain.pits.guard()
	assert_bool(brain.input.nitro).is_false()
	assert_float(absf(brain.input.steer)).is_greater(0.0)
	# A second of the bot's own driving, with the goal on the far side of the hole, and the kart
	# has gone around it rather than into it.
	brain.target = pit - Vector3(5.0, 0.0, 0.0)
	brain.drive._path = PackedVector3Array()
	assert_bool(_drives_clear(brain, 60)).override_failure_message("drove into the pit").is_true()


## GAME.md 9.1: a bot parked beside a hole, its errand along the edge of it, drives off. Checking
## a straight line along a kart that is not moving said nothing until it moved and then said
## stop, so it sat there for seconds on end with the throttle and the brakes taking turns.
func test_a_bot_beside_a_hole_drives_off_along_it() -> void:
	var match_node := _match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	var grid := match_node.arena.grid
	var rect := grid.pits[0]
	var pit := grid.rect_center(rect)
	# Stopped in the cell beside the hole, nose along its edge, the goal past the far end.
	var beside := pit + Vector3(0.0, 0.0, grid.rect_size(rect).y * 0.5 + grid.cell_size * 0.5)
	kart.global_position = beside
	kart.face(Vector3(1.0, 0.0, 0.0))
	kart.motor.forward_speed = 0.0
	kart.motor.velocity = Vector3.ZERO
	brain.goal = &"collect"
	brain.target_node = null
	brain.target = beside + Vector3(8.0, 0.0, 0.0)
	brain.drive._path = PackedVector3Array()
	brain.drive._replan_left = 0.0
	assert_bool(_drives_clear(brain, 90)).override_failure_message("drove into the pit").is_true()
	assert_float(kart.global_position.distance_to(beside)).is_greater(4.0)


## GAME.md 9.1: backing out of a wall is driving too, and a hole behind a bot backing out is a
## hole it would back into.
func test_a_bot_backing_out_does_not_back_into_a_hole() -> void:
	var match_node := _match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	var grid := match_node.arena.grid
	var pit := grid.rect_center(grid.pits[0])
	# Nose away from the hole, tail most of a meter from its trigger, and backing out.
	var half := grid.rect_size(grid.pits[0]).x * Pit.TRIGGER_SHARE * 0.5
	kart.global_position = pit + Vector3(half + 0.8 + 0.7, 0.0, 0.0)
	kart.face(Vector3(1.0, 0.0, 0.0))
	kart.motor.forward_speed = 0.0
	kart.motor.velocity = Vector3.ZERO
	brain.stuck.reset()
	brain.stuck.begin_backing_out()
	var fell := false
	for i: int in 60:
		brain.stuck.step(1.0 / 60.0)
		brain.pits.guard()
		kart.motor.step(brain.input, 1.0 / 60.0)
		kart.global_position += kart.motor.velocity * (1.0 / 60.0)
		fell = fell or _over_a_hole(match_node, kart)
	assert_bool(fell).override_failure_message("backed into the pit").is_false()


## Whether any of [param kart] is over a hole's trigger, as a fall is decided, see [Pit].
func _over_a_hole(match_node: Match, kart: Kart) -> bool:
	var grid := match_node.arena.grid
	var nose := kart.motor.forward_vector()
	var side := nose.cross(Vector3.UP)
	for rect: Rect2i in grid.pits:
		var center := grid.rect_center(rect)
		var half := grid.rect_size(rect) * Pit.TRIGGER_SHARE * 0.5
		for corner: Vector3 in [
			nose * 0.8 + side * 0.5,
			nose * 0.8 - side * 0.5,
			-nose * 0.8 + side * 0.5,
			-nose * 0.8 - side * 0.5
		]:
			var at := kart.global_position + corner
			if absf(at.x - center.x) <= half.x and absf(at.z - center.z) <= half.y:
				return true
	return false


## Drives the brain's whole say over the controls and the motor by hand for [param ticks], and
## says whether the kart stayed out of every hole all the while.
func _drives_clear(brain: BotBrain, ticks: int) -> bool:
	var kart := brain.kart
	for i: int in ticks:
		brain._steer(1.0 / 60.0)
		brain.pits.guard()
		kart.motor.step(brain.input, 1.0 / 60.0)
		kart.global_position += kart.motor.velocity * (1.0 / 60.0)
		if _over_a_hole(brain.match_node, kart):
			return false
	return true
