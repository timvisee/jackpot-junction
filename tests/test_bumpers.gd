extends GdUnitTestSuite
## Pop bumpers, GAME.md 6.2: a kart driving into one is thrown straight back off its middle, as
## hard whatever it came in at and never far enough to go down a hole; a shot meets one as it
## meets a wall; the bots go round them; and what a player sees and hears of a kick is said once.
## Played on Pin Alley, the map that has them, 6.3.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DEFAULT_RULES: MatchRules = preload("res://data/match/default.tres")
const STATS: KartStats = preload("res://data/kart/default.tres")
const CANNON: CannonStats = preload("res://data/cannons/default.tres")
const TICK := 1.0 / 60.0

var _runner: GdUnitSceneRunner


func _match(inputs: Array[KartInput]) -> Match:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 120.0
	rules.map = &"pin_alley"
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


## GAME.md 6.2: a bumper kicks every shot back, as a pinball machine's kicks the ball, whether or
## not the shot has a bounce in it, and the kick is the bumper's: no bounce is spent on it, so a
## shot with one still has it for the walls after, and none is counted off a wall. The bumper
## lights for it on every screen, from the word that a shot landed, and is never shot away.
func test_a_bumper_kicks_every_shot_back() -> void:
	var match_node := _match([KartInput.new()] as Array[KartInput])
	await _runner.simulate_frames(20, 17)
	var bumper: Bumper = match_node.arena.bumpers[1]
	var stats: CannonStats = CANNON.duplicate()
	stats.aim_assist = false
	var from := bumper.global_position + Vector3(0.0, 0.0, 4.0)
	for bounces: int in [0, 1]:
		stats.bounces = bounces
		var shot := match_node.bullets.spawn(1, from, Vector3.FORWARD, stats, Color.RED)
		for i: int in 40:
			await get_tree().physics_frame
			if not is_instance_valid(shot) or shot.is_dead() or shot.turns > 0:
				break
		(
			assert_bool(is_instance_valid(shot) and not shot.is_dead())
			. override_failure_message("a shot with %d bounces stopped on a bumper" % bounces)
			. is_true()
		)
		assert_float(shot.velocity.z).override_failure_message("it did not come back").is_greater(
			0.0
		)
		assert_int(shot.bounces_left).is_equal(bounces)
		assert_int(shot.bounced_times).is_equal(0)
		assert_bool(bumper.lit()).is_true()
		shot.destroy()
		await _runner.simulate_frames(30, 17)
	# Never shot away: it is not cover that breaks.
	assert_int(bumper.collision_layer).is_equal(Layers.WORLD)
	# Aimed at, but only for want of anything else, see the test of that below.
	assert_bool(bumper.is_in_group(Bullet.TARGET_GROUP)).is_true()


## GAME.md 6.2 and 7.3: on Pin Alley a bumper's kick pays Cushion Shot as a wall's bounce does, the
## room's bank shots its own cushion; off that map a bumper pays it nothing.
func test_a_bumper_kick_pays_cushion_shot_on_pin_alley() -> void:
	var match_node := _match([KartInput.new()] as Array[KartInput])
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	kart.jokers.add(load("res://data/jokers/cushion_shot.tres"))
	var bumper: Bumper = match_node.arena.bumpers[1]
	var stats: CannonStats = CANNON.duplicate()
	stats.aim_assist = false
	stats.bounces = 0
	var from := bumper.global_position + Vector3(0.0, 0.0, 4.0)
	var before := kart.pot.coins
	match_node.bullets.spawn(0, from, Vector3.FORWARD, stats, Color.RED)
	for i: int in 40:
		await get_tree().physics_frame
		if kart.pot.coins > before:
			break
	assert_int(kart.pot.coins).override_failure_message("a kick paid nothing").is_greater(before)
	# Off Pin Alley the same kick is no cushion, and pays nothing.
	match_node.rules.map = &"vault"
	var was := kart.pot.coins
	match_node.bullets.spawn(0, from, Vector3.FORWARD, stats, Color.RED)
	await _runner.simulate_frames(40, 17)
	assert_int(kart.pot.coins).override_failure_message("a kick paid off Pin Alley").is_equal(was)


## GAME.md 9.1: a bot knows a bumper sends every shot back. One whose own shots hurt it does not
## fire square into one near, whatever its cannon, and one whose shots do not bounce off walls
## still takes a shot off a bumper at a kart it cannot see, and never off a wall.
func test_a_bot_knows_a_bumper_sends_shots_back() -> void:
	var match_node := _match([BotInput.new()] as Array[KartInput])
	match_node.rules.own_bullets_hurt = true
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	var tactics: BotTactics = (kart.get_node("Brain") as BotBrain).tactics
	assert_int(kart.cannon.current_stats().bounces).is_equal(0)
	var bumper: Bumper = match_node.arena.bumpers[1]
	# Held where it is put: left to drive, the bot turns its nose off the bumper toward its own
	# errand in whatever ticks pass before it is asked, and more of them pass the busier the
	# machine running the test is, which is how this once failed only in a full run.
	kart.frozen = true
	kart.global_position = bumper.global_position + Vector3(0.0, 0.0, 2.5)
	kart.face(Vector3.FORWARD)
	assert_bool(tactics.bounces_back()).override_failure_message("fired into a bumper").is_true()
	kart.face(Vector3.BACK)
	assert_bool(tactics.bounces_back()).is_false()
	var eye := Vector3(0.0, BotBrain.BULLET_HEIGHT, 0.0)
	var from := bumper.global_position + Vector3(0.0, 0.0, 5.0) + eye
	var mark := bumper.global_position + Vector3(0.0, 0.0, 2.5) + eye
	assert_bool(tactics._banks(from, Vector3.FORWARD, mark, 20.0, false)).is_true()
	# A wall, square on, sends nothing back to a cannon whose shots do not bounce.
	var wall := match_node.arena.grid.cell_center(Vector2i(20, 0)) + eye
	var under := wall + Vector3(0.0, 0.0, 4.0)
	(
		assert_bool(tactics._banks(under, Vector3.FORWARD, wall + Vector3.BACK * 2.0, 20.0, false))
		. is_false()
	)


## GAME.md 9.1: the bots' map has a bumper solid and the floor round it dear, so a way past a
## cluster of three goes round it, a cell clear.
func test_the_bots_map_goes_round_a_cluster() -> void:
	var grid := ArenaMaps.layout(&"pin_alley").parse()
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


## GAME.md 5.1: a shot fired roughly at a bumper is bent onto it, since every shot comes off one,
## but only for want of anything else: a kart anywhere in the cone takes the aim off it, however
## much further off, and so does a box.
func test_a_shot_is_bent_onto_a_bumper_for_want_of_anything_else() -> void:
	var match_node := _match([KartInput.new(), KartInput.new()] as Array[KartInput])
	await _runner.simulate_frames(20, 17)
	var away := Vector3(0.0, 0.0, -400.0)
	for crate: Crate in match_node.arena.crates:
		crate.global_position = away
		away += Vector3(4.0, 0.0, 0.0)
	var other := match_node.kart_of(1)
	other.global_position = Vector3(-300.0, 0.0, 300.0)
	await _runner.simulate_frames(2, 17)
	var bumper: Bumper = match_node.arena.bumpers[1]
	var from := bumper.global_position + Vector3(0.0, 0.0, 6.0)
	var space := match_node.get_world_3d().direct_space_state
	var aimed := Bullet.nearest_target(get_tree(), from, 0, 20.0, Vector3.FORWARD, 0.6, space)
	assert_object(aimed).is_same(bumper)
	# A kart in the cone, further off than the bumper, takes the aim.
	other.global_position = from + Vector3(-2.5, 0.0, -7.0)
	await _runner.simulate_frames(2, 17)
	aimed = Bullet.nearest_target(get_tree(), from, 0, 20.0, Vector3.FORWARD, 0.6, space)
	assert_object(aimed).is_same(other)
	# And so does a box, further off still.
	other.global_position = Vector3(-300.0, 0.0, 300.0)
	var crate: Crate = match_node.arena.crates[0]
	crate.global_position = from + Vector3(-2.5, 0.5, -8.0)
	await _runner.simulate_frames(2, 17)
	aimed = Bullet.nearest_target(get_tree(), from, 0, 20.0, Vector3.FORWARD, 0.6, space)
	assert_object(aimed).is_same(crate)


## GAME.md 6.2: a run of ten kicks with no more than a second and a half between them and the
## bumpers let the kart be for five seconds, plain solid round pieces to it; the run starts again
## after that, and a gap long enough ends a run before it gets there.
func test_a_long_run_of_kicks_lets_the_kart_be() -> void:
	var motor := KartMotor.new(STATS)
	var input := KartInput.new()
	for k: int in KartMotor.KICK_CAP:
		assert_bool(motor.kickable()).is_true()
		motor.throw_off(Vector3.BACK, Vector3.FORWARD * 5.0)
		for tick: int in 30:
			motor.step(input, TICK)
	assert_bool(motor.kickable()).override_failure_message("kicked past the cap").is_false()
	assert_int(motor.kicks).is_equal(0)
	assert_float(motor.kick_rest_left).is_greater(KartMotor.KICK_REST - 1.0)
	for tick: int in int(KartMotor.KICK_REST * 60.0) + 2:
		motor.step(input, TICK)
	assert_bool(motor.kickable()).is_true()
	# A run with a long enough gap in it starts again from one.
	for k: int in 3:
		motor.throw_off(Vector3.BACK, Vector3.FORWARD * 5.0)
	assert_int(motor.kicks).is_equal(3)
	for tick: int in int(KartMotor.KICK_GAP * 60.0) + 2:
		motor.step(input, TICK)
	assert_int(motor.kicks).is_equal(0)


## GAME.md 6.2: while the bumpers let a kart be it drives against one as against a wall: no throw,
## no light and no knock.
func test_a_bumper_letting_a_kart_be_is_a_wall_to_it() -> void:
	var input := KartInput.new()
	var match_node := _match([input] as Array[KartInput])
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	var bumper: Bumper = match_node.arena.bumpers[1]
	kart.motor.kick_rest_left = KartMotor.KICK_REST
	var heard: Array[int] = []
	var count := func(slot: int, _bumper: int) -> void: heard.append(slot)
	Events.bumper_kicked.connect(count)
	_line_up(kart, bumper, 2.5, 4.0)
	input.throttle = 1.0
	var thrown := await _thrown_at(kart, 60)
	Events.bumper_kicked.disconnect(count)
	assert_vector(thrown).is_equal(Vector3.ZERO)
	assert_array(heard).is_empty()
	assert_float(kart.global_position.distance_to(bumper.global_position)).is_greater(Bumper.RADIUS)


## The middle of the map's first three of bumpers, on the floor, GAME.md 6.3.
func _pocket(match_node: Match) -> Vector3:
	var bumpers := match_node.arena.bumpers
	var middle := Vector3.ZERO
	for i: int in 3:
		assert_float(bumpers[i].global_position.distance_to(bumpers[0].global_position)).is_less(
			3.0
		)
		middle += bumpers[i].global_position / 3.0
	return Vector3(middle.x, 0.0, middle.z)


## GAME.md 6.2: the floor in the middle of a three is a pocket a kart can get into, and be thrown
## about in for a moment, but the run of kicks it takes there ends in the rest, and resting it
## drives straight out through any of the three gaps without another kick.
func test_a_kart_in_the_middle_of_a_three_drives_out_once_let_be() -> void:
	var input := KartInput.new()
	var match_node := _match([input] as Array[KartInput])
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	var pocket := _pocket(match_node)
	var bumpers := match_node.arena.bumpers
	# Dropped in at speed, nose on a bumper: thrown about, and never past the cap before the rest.
	kart.global_position = pocket
	kart.face(bumpers[0].global_position - pocket)
	kart.motor.velocity = kart.motor.forward_vector() * 6.0
	kart.velocity = kart.motor.velocity
	kart.reset_physics_interpolation()
	input.throttle = 1.0
	var kicked := 0
	var was := 0.0
	for tick: int in 60 * 3:
		await get_tree().physics_frame
		if kart.motor.thrown_left > was + 0.001:
			kicked += 1
		was = kart.motor.thrown_left
		if not kart.motor.kickable():
			break
	assert_int(kicked).is_between(1, KartMotor.KICK_CAP)
	# Let be, it drives out through each gap from the middle, nose on it.
	for i: int in 3:
		var gap := (bumpers[i].global_position + bumpers[(i + 1) % 3].global_position) * 0.5
		gap.y = 0.0
		kart.global_position = pocket
		kart.face(gap - pocket)
		kart.motor.velocity = Vector3.ZERO
		kart.motor.forward_speed = 0.0
		kart.velocity = Vector3.ZERO
		kart.motor.thrown_left = 0.0
		kart.motor.kick_rest_left = KartMotor.KICK_REST
		kart.reset_physics_interpolation()
		var out := false
		for tick: int in 90:
			await get_tree().physics_frame
			assert_bool(kart.motor.thrown()).override_failure_message("kicked resting").is_false()
			if (
				(
					Vector2(kart.global_position.x - pocket.x, kart.global_position.z - pocket.z)
					. length()
				)
				> 2.4
			):
				out = true
				break
		assert_bool(out).override_failure_message("never out through gap %d" % i).is_true()
	input.throttle = 0.0


## GAME.md 6.2: a shot loose in the middle of a three rattles round it for a moment and comes out
## through a gap, within a second whichever way it went, rather than for the rest of its life.
func test_a_shot_in_the_middle_of_a_three_comes_out() -> void:
	var match_node := _match([KartInput.new()] as Array[KartInput])
	await _runner.simulate_frames(20, 17)
	match_node.kart_of(0).global_position = Vector3(-20.0, 0.0, 10.0)
	var pocket := _pocket(match_node)
	var stats: CannonStats = CANNON.duplicate()
	for k: int in 12:
		var way := Vector3.FORWARD.rotated(Vector3.UP, TAU * float(k) / 12.0 + 0.1)
		var shot := match_node.bullets.spawn(1, pocket, way, stats, Color.RED)
		var ticks := 0
		while is_instance_valid(shot) and not shot.is_dead():
			var at := shot.global_position
			if Vector2(at.x - pocket.x, at.z - pocket.z).length() > 2.4:
				break
			ticks += 1
			await get_tree().physics_frame
		(
			assert_int(ticks)
			. override_failure_message("shot %d rattled round for %d ticks" % [k, ticks])
			. is_less(60)
		)
		if is_instance_valid(shot):
			shot.destroy()
		await _runner.simulate_frames(2, 17)


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


## GAME.md 6.2: on Pin Alley a pop bumper shakes a chip out of the kart it kicks, one of its coins
## onto the floor: once a pop rather than every tick a pinned kart touches it, nothing on a quiet
## kick a client predicts for its own kart, and nothing out of a kart with no coin to drop.
func test_a_bumper_sheds_a_chip_on_pin_alley() -> void:
	var match_node := _match([KartInput.new()] as Array[KartInput])
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	var bumper: Bumper = match_node.arena.bumpers[1]
	kart.global_position = match_node.arena.junction_position
	kart.pot.add_coins(5)
	var before := match_node.arena.pickups.get_child_count()
	bumper.throw(kart, Vector3.FORWARD)
	assert_int(kart.pot.coins).override_failure_message("no coin shed").is_equal(4)
	assert_int(match_node.arena.pickups.get_child_count()).is_equal(before + 1)
	# A second touch inside the refire window is the same pop, and sheds nothing more.
	bumper.throw(kart, Vector3.FORWARD)
	assert_int(kart.pot.coins).override_failure_message("shed twice in one pop").is_equal(4)
	assert_int(match_node.arena.pickups.get_child_count()).is_equal(before + 1)
	# The window past, a fresh pop sheds again.
	bumper._quiet_left = 0.0
	bumper.throw(kart, Vector3.FORWARD)
	assert_int(kart.pot.coins).is_equal(3)
	assert_int(match_node.arena.pickups.get_child_count()).is_equal(before + 2)
	# A quiet kick, a client's own, sheds nothing: the host's drop rides the snapshot.
	bumper._quiet_left = 0.0
	bumper.throw(kart, Vector3.FORWARD, true)
	assert_int(kart.pot.coins).override_failure_message("a quiet kick shed a chip").is_equal(3)
	# Broke, it drops nothing rather than a coin it has not got.
	bumper._quiet_left = 0.0
	kart.pot.add_coins(-3)
	var floor_now := match_node.arena.pickups.get_child_count()
	bumper.throw(kart, Vector3.FORWARD)
	assert_int(kart.pot.coins).is_equal(0)
	assert_int(match_node.arena.pickups.get_child_count()).is_equal(floor_now)


## A bumper on another map leaves the pot alone: the chip is Pin Alley's rule, GAME.md 6.2.
func test_a_bumper_sheds_nothing_off_pin_alley() -> void:
	var match_node := _match([KartInput.new()] as Array[KartInput])
	match_node.rules.map = &"vault"
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	var bumper: Bumper = match_node.arena.bumpers[1]
	kart.global_position = match_node.arena.junction_position
	kart.pot.add_coins(5)
	var before := match_node.arena.pickups.get_child_count()
	bumper.throw(kart, Vector3.FORWARD)
	assert_int(kart.pot.coins).override_failure_message("shed off Pin Alley").is_equal(5)
	assert_int(match_node.arena.pickups.get_child_count()).is_equal(before)


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
