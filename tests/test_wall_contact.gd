extends GdUnitTestSuite
## A kart meeting walls, GAME.md 4.1, see [KartCollisions]: the end of a wall clipped with a little
## of the kart's width eases it round rather than stopping it dead, a wall square across the way
## or a corner still stops it, and a kart pinned against a wall backs straight off it.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")
## Far out past the arena, where nothing of the map is in the way of the walls a test builds.
const AWAY := Vector3(300.0, 0.0, 300.0)
## A wall across the way 8 m ahead of the start, its right-hand end at x = 2.
const ACROSS: Array = [Vector3(-3.0, 0.0, -8.0), Vector3(10.0, 1.0, 1.0)]

var _runner: GdUnitSceneRunner


## A match with a kart of [param input]'s far out at [param start] facing [param facing], among
## the [param walls], each a center and a size.
func _kart(input: KartInput, walls: Array, start: Vector3, facing: Vector3) -> Kart:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start([input, BotInput.new()] as Array[KartInput], 31)
	await _runner.simulate_frames(20, 17)
	for wall: Array in walls:
		var body := StaticBody3D.new()
		body.collision_layer = Layers.WORLD
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = wall[1]
		shape.shape = box
		body.add_child(shape)
		match_node.add_child(body)
		body.global_position = AWAY + (wall[0] as Vector3) + Vector3(0.0, 0.5, 0.0)
	var kart := match_node.kart_of(0)
	kart.global_position = AWAY + start
	kart.face(facing)
	kart.motor.velocity = Vector3.ZERO
	await _runner.simulate_frames(2, 17)
	kart.global_position = AWAY + start
	return kart


## The end of a wall clipped with 15 cm of the kart is driven past, the kart eased a little to the
## side and on at its speed, with no crash.
func test_the_end_of_a_wall_clipped_is_driven_past() -> void:
	var input := KartInput.new()
	var kart: Kart = await _kart(input, [ACROSS], Vector3(2.35, 0.0, 0.0), Vector3.FORWARD)
	var crashes: Array[int] = [0]
	var crashed := func(_slot: int, _force: float) -> void: crashes[0] += 1
	Events.kart_crashed.connect(crashed)
	input.throttle = 1.0
	await _runner.simulate_frames(90, 17)
	Events.kart_crashed.disconnect(crashed)
	var at := kart.global_position - AWAY
	assert_float(at.z).is_less(-9.0)
	assert_float(at.x).is_between(2.5, 2.35 + kart.stats.wall_edge_nudge + 0.05)
	assert_float(kart.motor.speed()).is_greater(kart.stats.top_speed * 0.8)
	assert_int(crashes[0]).is_equal(0)


## Half the kart into a wall is no clip: it is stopped there.
func test_a_wall_met_with_half_the_kart_stops_it() -> void:
	var input := KartInput.new()
	var kart: Kart = await _kart(input, [ACROSS], Vector3(2.0, 0.0, 0.0), Vector3.FORWARD)
	input.throttle = 1.0
	await _runner.simulate_frames(90, 17)
	var at := kart.global_position - AWAY
	assert_float(at.z).is_greater(-7.0)
	assert_float(at.x).is_equal_approx(2.0, 0.01)


## A gap narrower than the kart is no way round: a wall beside it keeps the kart from being eased
## off the end of the one ahead of it.
func test_a_gap_too_narrow_is_not_eased_into() -> void:
	var input := KartInput.new()
	# Its near face at x = 2.9, 5 cm off the kart's right-hand side: 90 cm of gap past the end.
	var side: Array = [Vector3(3.4, 0.0, -4.0), Vector3(1.0, 1.0, 8.0)]
	var kart: Kart = await _kart(input, [ACROSS, side], Vector3(2.35, 0.0, 0.0), Vector3.FORWARD)
	var from := kart.global_position.x
	input.throttle = 1.0
	await _runner.simulate_frames(90, 17)
	assert_float(kart.global_position.z - AWAY.z).is_greater(-7.0)
	assert_float(kart.global_position.x).is_equal_approx(from, 0.05)


## Pinned against a wall with the throttle down, a kart backs straight off it the moment the brake
## goes on, rather than first braking off a speed into the wall it was not doing.
func test_a_kart_pinned_against_a_wall_backs_straight_off_it() -> void:
	var input := KartInput.new()
	var kart: Kart = await _kart(input, [ACROSS], Vector3(0.0, 0.0, 0.0), Vector3.FORWARD)
	input.throttle = 1.0
	await _runner.simulate_frames(90, 17)
	assert_float(kart.motor.speed()).is_less(1.0)
	var pinned := kart.global_position.z
	input.throttle = 0.0
	input.brake = 1.0
	await _runner.simulate_frames(15, 17)
	assert_float(kart.motor.forward_speed).is_less(-1.0)
	assert_float(kart.global_position.z).is_greater(pinned + 0.1)
