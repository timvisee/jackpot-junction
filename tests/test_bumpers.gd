extends GdUnitTestSuite
## Pop bumpers, GAME.md 6.2: a kart driving into one is thrown straight back off its middle, as
## hard whatever it came in at and never far enough to go down a hole; a shot meets one as it
## meets a wall; the bots go round them; and what a player sees and hears of a kick is said once.
## Played on Pin Alley, the map that has them, 6.3.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DEFAULT_RULES: MatchRules = preload("res://data/match/default.tres")
const STATS: KartStats = preload("res://data/kart/default.tres")
const TICK := 1.0 / 60.0

var _runner: GdUnitSceneRunner


func _match(inputs: Array[KartInput]) -> Match:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 120.0
	rules.map = &"vault_xl"
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.arena_layout = ArenaMaps.layout(rules.map)
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start(inputs, 11)
	return match_node


## Puts [param kart] [param back] meters south of [param bumper], nose on it, at [param speed].
func _line_up(kart: Kart, bumper: Bumper, back: float, speed: float) -> void:
	kart.global_position = bumper.global_position + Vector3(0.0, 0.0, back)
	kart.face(Vector3.FORWARD)
	kart.motor.forward_speed = speed
	kart.motor.velocity = Vector3.FORWARD * speed
	kart.velocity = kart.motor.velocity
	kart.reset_physics_interpolation()


## Drives until [param kart] is thrown, up to [param ticks], and returns the velocity it was
## thrown at, or zero when it never was.
func _thrown_at(kart: Kart, ticks: int) -> Vector3:
	for i: int in ticks:
		await get_tree().physics_frame
		if kart.motor.thrown():
			return kart.motor.velocity
	return Vector3.ZERO


## GAME.md 6.2: straight away from the bumper's middle, and as hard crawling in as flat out.
func test_a_bumper_throws_a_kart_straight_back_as_hard_whatever_it_came_in_at() -> void:
	var input := KartInput.new()
	var match_node := _match([input] as Array[KartInput])
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	var bumper: Bumper = match_node.arena.bumpers[1]
	var speeds: Array[float] = []
	for start: Array in [[1.6, 2.0], [4.0, 6.0], [5.0, 10.5]]:
		_line_up(kart, bumper, start[0], start[1])
		input.throttle = 1.0
		var thrown := await _thrown_at(kart, 90)
		input.throttle = 0.0
		(
			assert_float(thrown.length())
			. override_failure_message("not thrown coming in at %.1f m/s" % start[1])
			. is_greater(1.0)
		)
		var away := kart.global_position - bumper.global_position
		away.y = 0.0
		var off := rad_to_deg(thrown.angle_to(away))
		assert_float(off).override_failure_message("thrown %.1f deg off the line" % off).is_less(
			3.0
		)
		speeds.append(thrown.length())
		await _runner.simulate_frames(30, 17)
	for speed: float in speeds:
		assert_float(speed).is_equal_approx(KartMotor.THROW_SPEED, 0.05)
	assert_bool(kart.alive).is_true()


## GAME.md 6.2: a glancing blow keeps half of what the kart had across the line, so it goes on
## round the bumper rather than straight back the way it came.
func test_a_glancing_kart_goes_on_round_the_bumper() -> void:
	var motor := KartMotor.new(STATS)
	motor.heading = -PI * 0.5
	var travel := Vector3(8.0, 0.0, 0.0)
	motor.velocity = travel
	motor.throw_off(Vector3(-0.2, 0.0, 1.0), travel)
	var away := Vector3(-0.2, 0.0, 1.0).normalized()
	assert_float(motor.velocity.dot(away)).is_greater(KartMotor.THROW_SPEED - 2.0)
	assert_float(motor.velocity.dot(Vector3.RIGHT)).is_greater(1.0)
	assert_bool(motor.drifting).is_false()
	assert_float(motor.turbo_time_left).is_equal(0.0)


## GAME.md 6.3: a bumper's pit is five cells off, see test_arena_maps.gd, so a throw has to stop
## well short of that, from flat out and on nitro, left to coast or held on the throttle and the
## brake alike.
func test_a_throw_never_carries_a_kart_to_a_pit() -> void:
	# How far a kart's middle may go from where it was thrown before it reaches a hole five cells
	# off: to the hole's edge from the bumper's middle, and past it to the pit's own shape, less
	# where the kart's middle starts, a bumper and half a kart out, and the half a kart that goes
	# first.
	var length := STATS.length
	var hole := (5.0 - 0.5) * 1.25 + 1.25 * 0.15
	var reach := hole - (Bumper.RADIUS + length * 0.5) - length * 0.5
	for burning: bool in [false, true]:
		for pedal: String in ["coast", "brake", "throttle"]:
			var motor := KartMotor.new(STATS)
			motor.nitro_bonus = motor.stats.nitro_speed_multiplier if burning else 1.0
			var arriving := Vector3.FORWARD * motor.max_speed()
			motor.velocity = arriving
			motor.throw_off(Vector3.BACK, arriving)
			var input := KartInput.new()
			var gone := Vector3.ZERO
			# Out along the line it was thrown down, until it stops or turns round.
			for i: int in 240:
				input.brake = 1.0 if pedal == "brake" and motor.thrown() else 0.0
				input.throttle = 1.0 if pedal == "throttle" else 0.0
				motor.step(input, TICK)
				if motor.velocity.dot(Vector3.BACK) <= 0.05:
					break
				gone += motor.velocity * TICK
			var how := "%s%s carried %.2f m" % [pedal, " on nitro" if burning else "", gone.z]
			assert_float(gone.z).override_failure_message(how).is_less(reach)


## GAME.md 6.2: a shot meets a bumper as it meets a wall, stopping there or, with a bounce in it,
## coming off; either way the bumper lights, on every screen, from the word that a shot landed.
func test_a_shot_meets_a_bumper_as_it_meets_a_wall() -> void:
	var match_node := _match([KartInput.new()] as Array[KartInput])
	await _runner.simulate_frames(20, 17)
	var bumper: Bumper = match_node.arena.bumpers[1]
	var stats: CannonStats = load("res://data/cannons/default.tres").duplicate()
	stats.aim_assist = false
	stats.bounces = 0
	var from := bumper.global_position + Vector3(0.0, 0.0, 4.0)
	var shot := match_node.bullets.spawn(1, from, Vector3.FORWARD, stats, Color.RED)
	var gone := false
	for i: int in 40:
		await get_tree().physics_frame
		gone = not is_instance_valid(shot) or shot.is_dead()
		if gone:
			break
	assert_bool(gone).override_failure_message("a shot went through a bumper").is_true()
	assert_bool(bumper.lit()).is_true()
	await _runner.simulate_frames(30, 17)
	stats.bounces = 1
	var bouncing := match_node.bullets.spawn(1, from, Vector3.FORWARD, stats, Color.RED)
	for i: int in 40:
		await get_tree().physics_frame
		if bouncing.bounced:
			break
	assert_bool(bouncing.bounced).is_true()
	assert_float(bouncing.velocity.z).override_failure_message("it did not come back").is_greater(
		0.0
	)
	# Never shot away: it is not cover that breaks.
	assert_int(bumper.collision_layer).is_equal(Layers.WORLD)
	assert_bool(bumper.is_in_group(Bullet.TARGET_GROUP)).is_false()


## GAME.md 9.1: the bots' map has a bumper solid and the floor round it dear, so a way past a
## cluster of three goes round it, a cell clear.
func test_the_bots_map_goes_round_a_cluster() -> void:
	var grid := ArenaMaps.layout(&"vault_xl").parse()
	var nav := ArenaNav.new(grid)
	for cell: Vector2i in grid.bumpers:
		assert_bool(nav.is_blocked(cell)).is_true()
	var top := grid.bumpers[0]
	var from := grid.cell_center(top + Vector2i(0, 5))
	var to := grid.cell_center(top + Vector2i(0, -2))
	var path := nav.path(from, to)
	assert_int(path.size()).is_greater(0)
	for point: Vector3 in path:
		var cell := nav.world_to_cell(point)
		for bumper: Vector2i in grid.bumpers:
			var near := maxi(absi(cell.x - bumper.x), absi(cell.y - bumper.y))
			(
				assert_int(near)
				. override_failure_message("the way runs %s, beside %s" % [cell, bumper])
				. is_greater(1)
			)


## GAME.md 9.1: a bot sent to the far side of a cluster gets there, and is not thrown back and
## forth off it on the way.
func test_a_bot_drives_round_a_cluster_rather_than_off_it() -> void:
	var match_node := _match([BotInput.new()] as Array[KartInput])
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	var grid := match_node.arena.grid
	var top := grid.bumpers[0]
	var kicks: Array[int] = []
	var count := func(slot: int, _bumper: int) -> void: kicks.append(slot)
	Events.bumper_kicked.connect(count)
	for run: Array in [[Vector2i(0, 5), Vector2i(0, -2)], [Vector2i(-3, 3), Vector2i(3, 0)]]:
		kart.global_position = grid.cell_center(top + (run[0] as Vector2i))
		kart.face(grid.cell_center(top) - kart.global_position)
		kart.reset_physics_interpolation()
		var goal := grid.cell_center(top + (run[1] as Vector2i))
		# An errand somewhere else, held, so the brain drives there and decides nothing else.
		brain.goal = &"wander"
		brain.target = goal
		brain.target_node = null
		brain.drive._planned_target = Vector3.INF
		brain._elsewhere_left = 999.0
		var arrived := false
		for i: int in 60 * 8:
			await get_tree().physics_frame
			if kart.global_position.distance_to(goal) < BotBrain.ARRIVED_RADIUS:
				arrived = true
				break
		(
			assert_bool(arrived)
			. override_failure_message("never got round from %s" % [run[0]])
			. is_true()
		)
	Events.bumper_kicked.disconnect(count)
	assert_int(kicks.size()).override_failure_message("thrown %d times" % kicks.size()).is_less(2)


## GAME.md 9.1: a bot thrown off a bumper again and again, sent back at it by whatever it is
## after, gives up on that and goes elsewhere rather than rattling there for the rest of the match.
func test_a_bot_thrown_about_goes_elsewhere() -> void:
	var match_node := _match([BotInput.new()] as Array[KartInput])
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	brain.goal = &"collect"
	for i: int in BotStuck.THROWN_TIMES:
		assert_str(String(brain.goal)).is_not_equal("wander")
		kart.motor.throw_off(Vector3.BACK, Vector3.FORWARD * 5.0)
		for tick: int in 30:
			brain.stuck.step(TICK)
			kart.motor.step(brain.input, TICK)
	assert_str(String(brain.goal)).is_equal("wander")
	assert_bool(brain.stuck.maneuvering()).is_true()


## GAME.md 10.3: a client's own kart kicked is lit and heard on its own machine at once, and the
## host's word for the same kick, a round trip later, is not shown a second time; anybody else's
## kick is shown from the host's word as it comes.
func test_a_kick_is_shown_once_on_a_client() -> void:
	var match_node := _match([KartInput.new()] as Array[KartInput])
	await _runner.simulate_frames(20, 17)
	var bumper: Bumper = match_node.arena.bumpers[2]
	bumper.ahead(0)
	assert_bool(bumper.lit()).is_true()
	await _runner.simulate_frames(40, 17)
	assert_bool(bumper.lit()).is_false()
	Events.bumper_kicked.emit(0, bumper.index)
	assert_bool(bumper.lit()).override_failure_message("the host's word lit it again").is_false()
	Events.bumper_kicked.emit(1, bumper.index)
	assert_bool(bumper.lit()).is_true()
	# Another bumper's word is not this one's.
	var other: Bumper = match_node.arena.bumpers[0]
	assert_bool(other.lit()).is_false()
	assert_bool(NetEvents.RELAYED.has(&"bumper_kicked")).is_true()
