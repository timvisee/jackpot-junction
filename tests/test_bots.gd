extends GdUnitTestSuite
## Grid navigation and the bot brain from GAME.md 9.1.

const DEFAULT_RULES: MatchRules = preload("res://data/match/default.tres")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LUCKY_CROSSING: ArenaLayout = preload("res://data/maps/lucky_crossing.tres")

var _runner: GdUnitSceneRunner


func _trait(id: String) -> BotTrait:
	return load("res://data/ai/traits/%s.tres" % id)


func test_paths_avoid_walls_and_reopen_when_a_crate_dies() -> void:
	var layout: ArenaLayout = LUCKY_CROSSING
	var grid := layout.parse()
	var nav := ArenaNav.new(grid)
	var from := grid.cell_center(grid.spawns[0])
	var to := grid.rect_center(grid.junction)
	var path := nav.path(from, to)
	assert_int(path.size()).is_greater(5)
	for point: Vector3 in path:
		var cell := nav.world_to_cell(point)
		(
			assert_bool(grid.is_wall(cell))
			. override_failure_message("path crosses wall at %s" % cell)
			. is_false()
		)
	assert_vector(nav.world_to_cell(Vector3.ZERO)).is_equal(Vector2i(16, 9))
	var crate := grid.crates[0]
	assert_bool(nav.is_blocked(crate)).is_true()
	nav.set_cell_blocked(crate, false)
	assert_bool(nav.is_blocked(crate)).is_false()
	var inside_wall := nav.nearest_open_cell(Vector2i(0, 0))
	assert_bool(grid.is_wall(inside_wall)).is_false()


func test_goal_choice_follows_the_design_priorities() -> void:
	var balanced := _trait("balanced")
	(
		assert_str(BotBrain.choose_goal({"boost_enemy_distance": 4.0, "pot_value": 500}, balanced))
		. is_equal("flee")
	)
	assert_str(BotBrain.choose_goal({"pot_value": 130}, balanced)).is_equal("bank")
	assert_str(BotBrain.choose_goal({"pot_value": 5, "time_left": 10.0}, balanced)).is_equal("bank")
	(
		assert_str(
			BotBrain.choose_goal(
				{"pot_value": 5, "time_left": 100.0, "jackpot_chips": 25}, balanced
			)
		)
		. is_equal("jackpot")
	)
	(
		assert_str(
			BotBrain.choose_goal(
				{
					"jackpot_chips": 25,
					"jackpot_contested": true,
					"enemy_distance": 5.0,
					"enemy_visible": true
				},
				balanced
			)
		)
		. is_equal("hunt")
	)
	(
		assert_str(
			BotBrain.choose_goal(
				{
					"enemy_distance": 17.0,
					"enemy_visible": true,
					"pickup_distance": 3.0,
					"pickup_value": 1.0
				},
				balanced
			)
		)
		. is_equal("collect")
	)
	(
		assert_str(
			BotBrain.choose_goal(
				{"pickup_distance": 30.0, "pickup_value": 1.0, "item_distance": 4.0}, balanced
			)
		)
		. is_equal("item")
	)
	assert_str(BotBrain.choose_goal({}, balanced)).is_equal("wander")
	var greedy := _trait("greedy")
	assert_str(BotBrain.choose_goal({"pot_value": 130, "time_left": 100.0}, greedy)).is_equal(
		"wander"
	)
	(
		assert_str(
			BotBrain.choose_goal({"pot_value": 3, "time_left": 25.0, "last_call": true}, greedy)
		)
		. is_equal("bank")
	)
	var cautious := _trait("cautious")
	assert_str(BotBrain.choose_goal({"pot_value": 70}, cautious)).is_equal("bank")


## GAME.md 3.9 and 9.1: the pads pay while they are held, so a bot goes and takes one when it is
## worth the detour, and drops everything for the one that completes the set.
func test_a_bot_goes_for_a_flush_pad_when_it_is_worth_the_detour() -> void:
	var balanced := _trait("balanced")
	var near := {"flush_distance": 6.0, "flush_value": BotBrain.PAD_VALUE}
	assert_str(BotBrain.choose_goal(near, balanced)).is_equal("flush")
	# A chip under its nose beats a pad across the arena.
	var far := {
		"flush_distance": 22.0,
		"flush_value": BotBrain.PAD_VALUE,
		"pickup_distance": 3.0,
		"pickup_value": 1.0,
	}
	assert_str(BotBrain.choose_goal(far, balanced)).is_equal("collect")
	# The one that completes the flush is worth crossing the arena for, chip or no chip.
	var completing := {
		"flush_distance": 22.0,
		"flush_value": BotBrain.PAD_FLUSH_VALUE,
		"pickup_distance": 3.0,
		"pickup_value": 1.0,
	}
	assert_str(BotBrain.choose_goal(completing, balanced)).is_equal("flush")
	# A fat pot still comes first: a flush is no use to a bot that is about to lose its pot.
	var loaded := {"pot_value": 500, "flush_distance": 6.0, "flush_value": BotBrain.PAD_FLUSH_VALUE}
	assert_str(BotBrain.choose_goal(loaded, balanced)).is_equal("bank")


## GAME.md 3.4: a full cash-out is what gives a wounded kart its second life back, so a wounded
## bot heads for the Junction with a smaller pot than it otherwise would.
func test_a_wounded_bot_settles_for_a_smaller_pot() -> void:
	var balanced := _trait("balanced")
	var pot := {"pot_value": balanced.bank_threshold / 2, "time_left": 100.0}
	assert_str(BotBrain.choose_goal(pot, balanced)).is_not_equal("bank")
	pot["wounded"] = true
	assert_str(BotBrain.choose_goal(pot, balanced)).is_equal("bank")
	# An empty pot still buys nothing, so there is nothing to go to the Junction for.
	(
		assert_str(
			BotBrain.choose_goal({"pot_value": 0, "time_left": 100.0, "wounded": true}, balanced)
		)
		. is_equal("wander")
	)


## A running match of two bots, for the tests that need a brain in a real arena.
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


## Which piece of scenery the brain would shoot at, as an instance id, or 0 for none.
func _picked(brain: BotBrain) -> int:
	var mark := brain._scenery_mark()
	return mark.get_instance_id() if mark != null else 0


## GAME.md 9.1: with nobody worth shooting, a bot puts its shots into the scenery, which pays.
func test_a_bot_with_nobody_to_shoot_picks_the_scenery_in_front_of_it() -> void:
	var match_node := _match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	var crate := match_node.arena.crates[0]
	assert_bool(crate.alive).is_true()
	# Instance ids rather than the nodes: two crates are alike in everything but which one they are.
	kart.global_position = crate.global_position + Vector3(3.0, 0.0, 0.0)
	await _runner.simulate_frames(2, 17)
	assert_int(_picked(brain)).is_equal(crate.get_instance_id())
	# A crate right across the arena is not worth a shot.
	kart.global_position = -crate.global_position
	await _runner.simulate_frames(2, 17)
	assert_int(_picked(brain)).is_not_equal(crate.get_instance_id())
	# Nor is a broken one, even from right next to it.
	kart.global_position = crate.global_position + Vector3(3.0, 0.0, 0.0)
	crate.hit(1)
	await _runner.simulate_frames(2, 17)
	assert_int(_picked(brain)).is_not_equal(crate.get_instance_id())


## GAME.md 9.1: paths go around a pit, but a pit stops nothing and blocks no raycast, so a bot
## cutting a corner would drive straight over one. It checks where it is headed and turns out.
func test_a_bot_turns_out_of_a_pit_it_is_headed_for() -> void:
	var match_node := _match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	var nav := match_node.nav
	var pit := match_node.arena.grid.rect_center(match_node.arena.grid.pits[0])
	assert_bool(nav.is_pit_at(pit)).is_true()
	assert_bool(nav.is_pit_at(match_node.arena.junction_position)).is_false()
	# A line across the hole reads as crossing it; one well clear of it does not.
	(
		assert_bool(nav.crosses_pit(pit + Vector3(6.0, 0.0, 0.0), pit - Vector3(6.0, 0.0, 0.0)))
		. is_true()
	)
	(
		assert_bool(nav.crosses_pit(pit + Vector3(6.0, 0.0, 9.0), pit + Vector3(-6.0, 0.0, 9.0)))
		. is_false()
	)
	# Driven flat out straight at the hole, with the goal on the far side of it.
	kart.global_position = pit + Vector3(5.0, 0.0, 0.8)
	kart.face(Vector3(-1.0, 0.0, 0.0))
	kart.motor.forward_speed = kart.stats.top_speed
	kart.motor.velocity = kart.motor.forward_vector() * kart.stats.top_speed
	brain.target = pit - Vector3(5.0, 0.0, 0.0)
	brain._path = PackedVector3Array()
	brain.input.nitro = true
	brain._steer(1.0 / 60.0)
	assert_float(brain.input.throttle).is_less_equal(BotBrain.PIT_THROTTLE)
	assert_bool(brain.input.nitro).is_false()
	# A second of it, and the kart has gone around the hole rather than into it.
	var fell := false
	for i: int in 60:
		brain._steer(1.0 / 60.0)
		kart.motor.step(brain.input, 1.0 / 60.0)
		kart.global_position += kart.motor.velocity * (1.0 / 60.0)
		fell = fell or nav.is_pit_at(kart.global_position)
	assert_bool(fell).override_failure_message("the bot drove into the pit").is_false()


## GAME.md 9.1: a bot at full tilt turns wider than the pad it is aiming for, so it used to sail
## past and circle it forever. It eases off on the last stretch, and backs onto a goal behind it.
func test_a_bot_lands_on_its_goal_instead_of_circling_it() -> void:
	var match_node := _match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	# The Jackpot is the hard one: a bot has to stop on the spot rather than inside a wide pad.
	var goal := match_node.arena.jackpot_zones[0].global_position
	# Overshot: past the spot at speed, nose pointing away from it.
	kart.global_position = goal + Vector3(2.5, 0.0, 0.0)
	kart.face(Vector3(1.0, 0.0, 0.0))
	kart.motor.forward_speed = kart.stats.top_speed
	assert_bool(_drives_onto(brain, kart, goal)).is_true()
	# And the ordinary case: coming in fast and off to one side.
	kart.global_position = goal + Vector3(7.0, 0.0, 4.5)
	kart.face(Vector3(-1.0, 0.0, 0.0))
	kart.motor.forward_speed = kart.stats.top_speed
	assert_bool(_drives_onto(brain, kart, goal)).is_true()


## Drives the brain and the motor by hand for four seconds, and says whether the kart is sitting
## on its goal at the end of it. Touching the pad in passing is what a circling bot does; what it
## has to manage is still being there. Stepping the two directly keeps the run to the steering
## under test.
func _drives_onto(brain: BotBrain, kart: Kart, goal: Vector3) -> bool:
	brain.goal = &"jackpot"
	brain.target = goal
	brain.target_node = null
	brain._path = PackedVector3Array()
	for i: int in 240:
		brain._steer(1.0 / 60.0)
		kart.motor.step(brain.input, 1.0 / 60.0)
		kart.global_position += kart.motor.velocity * (1.0 / 60.0)
	return kart.global_position.distance_to(goal) < 0.8


## GAME.md 9.1: a bot going nowhere with the throttle down backs out with the wheel over, and
## does it promptly when it can feel a wall on its nose.
func test_a_bot_nosed_against_a_wall_backs_out_of_it() -> void:
	var match_node := _match()
	await _runner.simulate_frames(30, 17)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	# Parked up against a wall of the arena, pointing into it, going nowhere.
	var wall := match_node.arena.grid.rect_center(match_node.arena.grid.walls[0])
	var inward := (Vector3.ZERO - wall).normalized()
	kart.global_position = wall + inward * 1.6
	kart.face(-inward)
	kart.motor.forward_speed = 0.0
	kart.motor.velocity = Vector3.ZERO
	assert_bool(brain._nose_on_a_wall()).is_true()
	# Half a second of it is enough with a wall there, where open ground gets a second.
	assert_bool(_gets_stuck(brain, 0.5)).is_true()
	assert_float(brain.input.brake).is_equal(1.0)
	assert_float(brain.input.throttle).is_equal(0.0)
	assert_float(absf(brain.input.steer)).is_equal(1.0)
	# The wheel stays where it was put for the whole manoeuvre rather than sawing at it.
	var first_way := signf(brain.input.steer)
	for i: int in 20:
		brain._step_stuck(1.0 / 60.0)
		assert_float(signf(brain.input.steer)).is_equal(first_way)
	# Once it has backed up it drives out again on the wheel it backed up with, rather than
	# being handed straight back to a navigator that points it at the wall it just came off.
	while brain._reverse_left > 0.0:
		brain._step_stuck(1.0 / 60.0)
	assert_float(brain._swing_left).is_greater(0.0)
	brain._step_stuck(1.0 / 60.0)
	assert_float(brain.input.throttle).is_greater(0.0)
	assert_float(brain.input.brake).is_equal(0.0)
	assert_float(signf(brain.input.steer)).is_equal(first_way)
	# Backed into the same corner again, it tries the other way out.
	_run_out_reverse(brain)
	assert_bool(_gets_stuck(brain, 0.5)).is_true()
	assert_float(signf(brain.input.steer)).is_equal(-first_way)
	# Out in the open a bot puts up with going nowhere for longer before giving up on it.
	_run_out_reverse(brain)
	kart.global_position = match_node.arena.junction_position
	assert_bool(brain._nose_on_a_wall()).is_false()
	assert_bool(_gets_stuck(brain, 0.5)).is_false()
	assert_bool(_gets_stuck(brain, 1.0)).is_true()


## GAME.md 9.1: a bot picks a goal ten times a second, so without something holding them
## together two errands it is equally near pull it back and forth and it drives down the middle.
func test_a_bot_sticks_with_its_errand_instead_of_dithering() -> void:
	var match_node := _match()
	await _runner.simulate_frames(30, 17)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	brain.goal = &"collect"
	brain.target = kart.global_position + Vector3(20.0, 0.0, 0.0)
	var offer := {"pickup": true, "item": true, "boost_enemy": true}
	# Freshly picked, a merely different errand does not get to take it off.
	brain._goal_held = 0.0
	assert_bool(brain._may_switch(&"item", offer)).is_false()
	# Once it has had its run, anything may.
	brain._goal_held = BotBrain.GOAL_DWELL
	assert_bool(brain._may_switch(&"item", offer)).is_true()
	# Something about to hit it always cuts in.
	brain._goal_held = 0.0
	assert_bool(brain._may_switch(&"flee", offer)).is_true()
	# So does an errand that has stopped existing: the pickup was taken.
	assert_bool(brain._may_switch(&"item", {"item": true})).is_true()
	# And one it is standing on is finished, whatever the clock says.
	brain.target = kart.global_position
	assert_bool(brain._may_switch(&"item", offer)).is_true()


## GAME.md 9.1: the wheel comes off as the nose comes round. Holding full lock until the kart
## is pointed at the waypoint arrives there turning too fast to stop, which is the saw.
func test_a_bot_winds_the_wheel_off_as_the_nose_comes_round() -> void:
	var match_node := _match()
	await _runner.simulate_frames(30, 17)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	kart.global_position = match_node.arena.junction_position + Vector3(0.0, 0.0, 10.0)
	kart.face(Vector3(1.0, 0.0, 0.0))
	kart.motor.forward_speed = kart.stats.top_speed * 0.5
	kart.motor.velocity = kart.motor.forward_vector() * kart.motor.forward_speed
	brain.goal = &"wander"
	brain.target_node = null
	# A gentle bend, so the wheel has somewhere between here and full lock to go.
	brain.target = kart.global_position + Vector3(12.0, 0.0, -2.0)
	brain._path = PackedVector3Array()
	brain._replan_left = 0.0
	# Dead ahead of the corner with the nose still straight: the wheel goes on.
	brain._turn_rate = 0.0
	brain._last_heading = kart.motor.heading
	brain._steer(1.0 / 60.0)
	var straight := brain.input.steer
	assert_float(absf(straight)).is_greater(0.0)
	# The same corner with the nose already swinging into it asks for less of the same wheel.
	brain._turn_rate = -signf(straight) * 0.4
	brain._last_heading = kart.motor.heading
	brain._steer(1.0 / 60.0)
	assert_float(signf(brain.input.steer)).is_equal(signf(straight))
	assert_float(absf(brain.input.steer)).is_less(absf(straight))


## GAME.md 9.1: a kart wedged on a corner can keep a speed on the clock while arriving nowhere,
## so what a bot goes by is the ground it has covered, not the speedometer.
func test_a_bot_that_covers_no_ground_backs_out_even_with_speed_on_the_clock() -> void:
	var match_node := _match()
	await _runner.simulate_frames(30, 17)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	kart.global_position = match_node.arena.junction_position
	# Scrubbing along at a speed that would never read as stuck, and staying put.
	kart.motor.forward_speed = BotBrain.STUCK_SPEED * 4.0
	kart.motor.velocity = kart.motor.forward_vector() * kart.motor.forward_speed
	brain._forget_progress()
	var backed := false
	for i: int in int((BotBrain.PROGRESS_TIME + 0.5) * 60.0):
		brain.input.throttle = 1.0
		brain._step_stuck(1.0 / 60.0)
		if brain._reverse_left > 0.0:
			backed = true
			break
	assert_bool(backed).is_true()


## Holds the throttle down on a kart that is going nowhere for [param seconds], and says whether
## the bot gave up and started backing out.
func _gets_stuck(brain: BotBrain, seconds: float) -> bool:
	for i: int in int(seconds * 60.0):
		brain.input.throttle = 1.0
		brain._step_stuck(1.0 / 60.0)
		if brain._reverse_left > 0.0:
			return true
	return false


## Lets the whole manoeuvre finish, backing out and driving out again, with nobody asking for
## anything.
func _run_out_reverse(brain: BotBrain) -> void:
	for i: int in 240:
		if brain._reverse_left <= 0.0 and brain._swing_left <= 0.0:
			return
		brain.input.throttle = 0.0
		brain._step_stuck(1.0 / 60.0)


## GAME.md 9.1: the kart drifts the oversteer way, where the handbrake is a flick. A bot throws it
## into a tight corner and then drives the slide on the wheel; holding the handbrake down would
## break the rear loose again every time the slide was caught.
func test_a_bot_flicks_the_handbrake_into_a_tight_corner_and_then_drives_it() -> void:
	var match_node := _match()
	await _runner.simulate_frames(30, 17)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	# Flat out with the corner square to the left: as tight as it gets.
	kart.global_position = match_node.arena.junction_position + Vector3(0.0, 0.0, 12.0)
	kart.face(Vector3(1.0, 0.0, 0.0))
	kart.motor.forward_speed = kart.stats.top_speed
	kart.motor.velocity = kart.motor.forward_vector() * kart.stats.top_speed
	brain.goal = &"wander"
	brain.target = kart.global_position + Vector3(0.0, 0.0, -14.0)
	brain.target_node = null
	brain._path = PackedVector3Array()
	var pulls := 0
	var held := 0
	var slid := 0
	var was_down := false
	for i: int in 180:
		brain._steer(1.0 / 60.0)
		if brain.input.handbrake:
			held += 1
			if not was_down:
				pulls += 1
		was_down = brain.input.handbrake
		kart.motor.step(brain.input, 1.0 / 60.0)
		kart.global_position += kart.motor.velocity * (1.0 / 60.0)
		if kart.motor.drifting:
			slid += 1
	assert_int(pulls).override_failure_message("the bot never threw it in").is_greater(0)
	# Flicks, not a held handbrake: three seconds of corner, well under a second of brake.
	assert_float(held / 60.0).is_less(1.0)
	# And the flick did what it was for: the rear came out, and was caught again rather than
	# held. A bot steering its travel catches it the moment the kart is pointed down the new
	# road, which is the tidy way to use one rather than a failure to hold it, so what is
	# checked is that there was a slide and that it was brief, not its length to the frame.
	assert_float(slid / 60.0).is_between(0.1, 0.8)


## A bot in a slide steers where the kart is going rather than where its nose points, which is
## what winds on opposite lock at the moment a driver would.
func test_a_drifting_bot_steers_its_travel_not_its_nose() -> void:
	var match_node := _match()
	await _runner.simulate_frames(30, 17)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	kart.global_position = match_node.arena.junction_position + Vector3(0.0, 0.0, 10.0)
	kart.face(Vector3(1.0, 0.0, 0.0))
	kart.motor.forward_speed = kart.stats.top_speed
	kart.motor.velocity = kart.motor.forward_vector() * kart.stats.top_speed
	brain.goal = &"wander"
	# Straight on, so any steering is the bot answering the slide rather than aiming at a corner.
	brain.target = kart.global_position + kart.motor.forward_vector() * 20.0
	brain.target_node = null
	brain._path = PackedVector3Array()
	# Thrown sideways by hand: the rear is out to the right and nobody asked for it.
	kart.motor.drifting = true
	kart.motor.drift_amount = 1.0
	kart.motor.slide_rate = deg_to_rad(160.0)
	brain._steer(1.0 / 60.0)
	# The nose is swinging right, so the wheel goes left: opposite lock.
	assert_float(brain.input.steer).is_less(0.0)


func test_closest_approach_predicts_near_misses() -> void:
	var head_on := BotBrain.closest_approach(Vector3(0.0, 0.0, -6.0), Vector3(0.0, 0.0, 20.0), 1.0)
	assert_float(head_on).is_equal_approx(0.0, 0.001)
	var passing := BotBrain.closest_approach(Vector3(2.0, 0.0, -6.0), Vector3(0.0, 0.0, 20.0), 1.0)
	assert_float(passing).is_equal_approx(2.0, 0.001)
	var receding := BotBrain.closest_approach(Vector3(0.0, 0.0, 6.0), Vector3(0.0, 0.0, 20.0), 1.0)
	assert_float(receding).is_equal_approx(6.0, 0.001)
	var slow := BotBrain.closest_approach(Vector3(0.0, 0.0, -6.0), Vector3(0.0, 0.0, 2.0), 1.0)
	assert_float(slow).is_equal_approx(4.0, 0.001)


func test_trait_table_covers_every_trait() -> void:
	var table: BotTraitTable = load("res://data/ai/traits.tres")
	assert_int(table.entries.size()).is_equal(6)
	assert_object(table.by_id(&"bumper")).is_not_null()
	assert_bool(table.by_id(&"bumper").rams).is_true()


func test_bots_drive_collect_and_bank_in_a_short_match() -> void:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [BotInput.new(), BotInput.new(), BotInput.new()]
	match_node.start(inputs, 9)
	var starts: Array[Vector3] = []
	for slot: PlayerSlot in match_node.slots:
		assert_object(slot.bot_trait).is_not_null()
		assert_object(slot.kart.get_node_or_null("Brain")).is_not_null()
		starts.append(slot.kart.global_position)
	await _runner.simulate_frames(360, 17)
	var moved := 0
	var coins := 0
	for i: int in match_node.slots.size():
		var kart := match_node.slots[i].kart
		if kart.global_position.distance_to(starts[i]) > 4.0 or not kart.alive:
			moved += 1
		coins += kart.pot.coins + match_node.slots[i].banked
	assert_int(moved).is_greater_equal(2)
	assert_int(coins).is_greater(0)


## GAME.md 9.1: a bot decides once per bullet whether it reacts to that one, so it does not
## change its mind every frame. It keeps those decisions only while the bullets are in the air:
## a match fires thousands, and carrying all of them to the whistle is a leak with a clock on it.
func test_a_bot_forgets_its_dodge_decisions_with_the_bullets() -> void:
	var match_node := _match()
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	# A handful of shots heading straight at the bot, so it has to make up its mind about them.
	kart.motor.velocity = Vector3.ZERO
	for i: int in 6:
		var at := kart.global_position + Vector3(4.0 + i * 0.3, 0.0, 0.0)
		match_node.bullets.spawn(
			1, at, Vector3(-1.0, 0.0, 0.0), match_node.kart_of(1).cannon_stats, Color.WHITE
		)
	await _runner.simulate_frames(4, 17)
	assert_int(brain._dodge_rolls.size()).is_greater(0)
	# Gone, and forgotten by the next time the bot thinks.
	for bullet: Bullet in match_node.bullets.bullets.duplicate():
		bullet.destroy()
	await _runner.simulate_frames(int(BotBrain.DECISION_INTERVAL * 60.0) + 6, 17)
	assert_int(brain._dodge_rolls.size()).is_equal(0)


## GAME.md 9.1: a kart goes down a hole when any corner of it touches the edge, not when its
## middle arrives, so a bot that aims to miss the hole itself aims to clip it.
func test_a_bot_leaves_room_for_its_own_body_around_a_hole() -> void:
	var nav := ArenaNav.new(LUCKY_CROSSING.parse())
	var pit := nav.first_pit_center(Vector3.ZERO, Vector3(0.0, 0.0, -9.0))
	assert_vector(pit).is_not_equal(Vector3.ZERO)
	# A point just outside the hole's own cells is clear of the hole and not clear of a kart.
	var beside := pit + Vector3(1.25 + 0.3, 0.0, 0.0)
	assert_bool(nav.is_pit_at(beside)).is_false()
	assert_bool(nav.is_pit_within(beside, BotBrain.PIT_CLEARANCE)).is_true()
	# Far enough away and it is clear either way.
	var clear := pit + Vector3(4.0, 0.0, 0.0)
	assert_bool(nav.is_pit_within(clear, BotBrain.PIT_CLEARANCE)).is_false()
	# A line that grazes the hole counts as crossing it once the margin is asked for.
	assert_bool(nav.crosses_pit(beside + Vector3(0.0, 0.0, -4.0), beside)).is_false()
	(
		assert_bool(
			nav.crosses_pit(beside + Vector3(0.0, 0.0, -4.0), beside, BotBrain.PIT_CLEARANCE)
		)
		. is_true()
	)
