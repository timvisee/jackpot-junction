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
	assert_str(BotGoals.choose({"boost_enemy_distance": 4.0, "pot_value": 500}, balanced)).is_equal(
		"flee"
	)
	assert_str(BotGoals.choose({"pot_value": 130}, balanced)).is_equal("bank")
	assert_str(BotGoals.choose({"pot_value": 5, "time_left": 10.0}, balanced)).is_equal("bank")
	(
		assert_str(
			BotGoals.choose({"pot_value": 5, "time_left": 100.0, "jackpot_chips": 25}, balanced)
		)
		. is_equal("jackpot")
	)
	(
		assert_str(
			BotGoals.choose(
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
			BotGoals.choose(
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
			BotGoals.choose(
				{"pickup_distance": 30.0, "pickup_value": 1.0, "item_distance": 4.0}, balanced
			)
		)
		. is_equal("item")
	)
	assert_str(BotGoals.choose({}, balanced)).is_equal("wander")
	var greedy := _trait("greedy")
	assert_str(BotGoals.choose({"pot_value": 130, "time_left": 100.0}, greedy)).is_equal("wander")
	(
		assert_str(BotGoals.choose({"pot_value": 3, "time_left": 25.0, "last_call": true}, greedy))
		. is_equal("bank")
	)
	var cautious := _trait("cautious")
	assert_str(BotGoals.choose({"pot_value": 70}, cautious)).is_equal("bank")


## GAME.md 3.9 and 9.1: the pads pay while they are held, so a bot goes and takes one when it is
## worth the detour, and drops everything for the one that completes the set.
func test_a_bot_goes_for_a_flush_pad_when_it_is_worth_the_detour() -> void:
	var balanced := _trait("balanced")
	var near := {"flush_distance": 6.0, "flush_value": BotBrain.PAD_VALUE}
	assert_str(BotGoals.choose(near, balanced)).is_equal("flush")
	# A chip under its nose beats a pad across the arena.
	var far := {
		"flush_distance": 22.0,
		"flush_value": BotBrain.PAD_VALUE,
		"pickup_distance": 3.0,
		"pickup_value": 1.0,
	}
	assert_str(BotGoals.choose(far, balanced)).is_equal("collect")
	# The one that completes the flush is worth crossing the arena for, chip or no chip.
	var completing := {
		"flush_distance": 22.0,
		"flush_value": BotBrain.PAD_FLUSH_VALUE,
		"pickup_distance": 3.0,
		"pickup_value": 1.0,
	}
	assert_str(BotGoals.choose(completing, balanced)).is_equal("flush")
	# A fat pot still comes first: a flush is no use to a bot that is about to lose its pot.
	var loaded := {"pot_value": 500, "flush_distance": 6.0, "flush_value": BotBrain.PAD_FLUSH_VALUE}
	assert_str(BotGoals.choose(loaded, balanced)).is_equal("bank")


## A bot that has made up its mind to a slot machine goes for it against a pickup, and a fat pot
## still goes to the bank first, GAME.md 9.1.
func test_a_bot_goes_for_a_slot_machine_it_has_its_mind_on() -> void:
	var balanced := _trait("balanced")
	var near := {"slot_distance": 6.0, "pickup_distance": 6.0, "pickup_value": 1.0}
	assert_str(BotGoals.choose(near, balanced)).is_equal("slot")
	var loaded := {"pot_value": 500, "slot_distance": 3.0}
	assert_str(BotGoals.choose(loaded, balanced)).is_equal("bank")
	# The keen roll is the trait's: a greedy bot is keener than a cautious one.
	assert_float(_trait("greedy").slot_appetite).is_greater(_trait("balanced").slot_appetite)
	assert_float(_trait("cautious").slot_appetite).is_less(_trait("balanced").slot_appetite)


## A bot keen on the machines, with chips enough, drives onto one and pulls it, and is done with
## them for a while after.
func test_a_keen_bot_drives_to_a_slot_machine_and_pulls() -> void:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.arena_layout = load("res://data/maps/crossfire.tres")
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [BotInput.new(), KartInput.new()]
	match_node.start(inputs, 9)
	await _runner.simulate_frames(10, 17)
	var kart := match_node.slots[0].kart
	var brain: BotBrain = kart.get_node("Brain")
	var greedy := _trait("greedy").duplicate() as BotTrait
	greedy.slot_appetite = 10.0
	greedy.bank_threshold = 100000
	brain.bot_trait = greedy
	brain.slots._until_thought = 0.0
	kart.pot.add_coins(60)
	var spun: Array[int] = []
	var listen := func(slot: int, _pad: int, _bet: int, _faces: PackedByteArray) -> void:
		spun.append(slot)
	Events.slot_spun.connect(listen)
	for i: int in 40:
		await _runner.simulate_frames(30, 17)
		if not spun.is_empty():
			break
	Events.slot_spun.disconnect(listen)
	assert_array(spun).contains([0])
	# Its next decision sees it pulled.
	await _runner.simulate_frames(12, 17)
	assert_float(brain.slots._keen_left).is_equal(0.0)


## GAME.md 3.4: a full cash-out is what gives a wounded kart its second life back, so a wounded
## bot heads for the Junction with a smaller pot than it otherwise would.
func test_a_wounded_bot_settles_for_a_smaller_pot() -> void:
	var balanced := _trait("balanced")
	var pot := {"pot_value": balanced.bank_threshold / 2, "time_left": 100.0}
	assert_str(BotGoals.choose(pot, balanced)).is_not_equal("bank")
	pot["wounded"] = true
	assert_str(BotGoals.choose(pot, balanced)).is_equal("bank")
	# An empty pot still buys nothing, so there is nothing to go to the Junction for.
	(
		assert_str(BotGoals.choose({"pot_value": 0, "time_left": 100.0, "wounded": true}, balanced))
		. is_equal("wander")
	)


## A running match of two bots, for the tests that need a brain in a real arena.
## GAME.md 9.1: collecting the Jackpot, a bot stays on it until the pile is gone, whatever its pot
## has grown to, and leaves only for danger: a kart about to ram it, the clock about to take the pot
## anyway, or, wounded, somebody close enough to land the hit that loses everything.
func test_a_bot_collecting_the_jackpot_stays_unless_in_danger() -> void:
	var balanced := _trait("balanced")
	var on_it := {"collecting_jackpot": true, "pot_value": 900, "jackpot_chips": 2}
	assert_str(BotGoals.choose(on_it, balanced)).is_equal("jackpot")
	# Not collecting, the same pot goes to the bank and the same few chips are not worth the trip.
	var passing := on_it.duplicate()
	passing["collecting_jackpot"] = false
	assert_str(BotGoals.choose(passing, balanced)).is_equal("bank")
	var rammed := on_it.duplicate()
	rammed["boost_enemy_distance"] = 3.0
	assert_str(BotGoals.choose(rammed, balanced)).is_equal("flee")
	var late := on_it.duplicate()
	late["time_left"] = 10.0
	assert_str(BotGoals.choose(late, balanced)).is_equal("bank")
	var wounded := on_it.duplicate()
	wounded["wounded"] = true
	wounded["near_enemy_distance"] = 20.0
	wounded["near_enemy_visible"] = true
	assert_str(BotGoals.choose(wounded, balanced)).is_equal("jackpot")
	wounded["near_enemy_distance"] = 6.0
	assert_str(BotGoals.choose(wounded, balanced)).is_equal("bank")
	# Seen through a wall is not somebody about to land a hit.
	wounded["near_enemy_visible"] = false
	assert_str(BotGoals.choose(wounded, balanced)).is_equal("jackpot")


## And in a match: a bot carrying far more than it would usually bank stays on the pile to the
## last chip. It used to break off for the Junction as soon as the pile had filled its pot.
func test_a_bot_drains_the_jackpot_before_it_banks() -> void:
	var match_node := _match()
	match_node.rules.jackpot_accrual = 0.0
	await _runner.simulate_frames(12, 17)
	var other := match_node.kart_of(1)
	other.get_node("Brain").queue_free()
	other.input = KartInput.new()
	var zone: JackpotZone = null
	for candidate: JackpotZone in match_node.arena.jackpot_zones:
		if candidate.active:
			zone = candidate
	zone.chips = 60.0
	other.global_position = zone.global_position + Vector3(0.0, 0.0, 14.0)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	kart.global_position = zone.global_position
	kart.pot.add_coins(400)
	brain.goal = &"jackpot"
	brain.target = zone.global_position
	var left_early := false
	for i: int in 300:
		await _runner.simulate_frames(1, 17)
		if zone.chips > 0.0 and brain.goal != &"jackpot":
			left_early = true
		if zone.chips <= 0.0:
			break
	assert_bool(left_early).override_failure_message("left the pile half collected").is_false()
	assert_float(zone.chips).is_equal(0.0)
	assert_int(kart.pot.coins).is_greater(450)


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
		assert_bool(nav.crosses_pit(pit + Vector3(6.0, 0.0, 7.0), pit + Vector3(-6.0, 0.0, 7.0)))
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
	assert_bool(brain.stuck._nose_on_a_wall()).is_true()
	# Half a second of it is enough with a wall there, where open ground gets a second.
	assert_bool(_gets_stuck(brain, 0.5)).is_true()
	assert_float(brain.input.brake).is_equal(1.0)
	assert_float(brain.input.throttle).is_equal(0.0)
	assert_float(absf(brain.input.steer)).is_equal(1.0)
	# The wheel stays where it was put for the whole maneuver rather than sawing at it.
	var first_way := signf(brain.input.steer)
	for i: int in 20:
		brain.stuck.step(1.0 / 60.0)
		assert_float(signf(brain.input.steer)).is_equal(first_way)
	# Once it has backed up it drives out again on the wheel it backed up with, rather than
	# being handed straight back to a navigator that points it at the wall it just came off.
	while brain.stuck._reverse_left > 0.0:
		brain.stuck.step(1.0 / 60.0)
	assert_float(brain.stuck._swing_left).is_greater(0.0)
	brain.stuck.step(1.0 / 60.0)
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
	assert_bool(brain.stuck._nose_on_a_wall()).is_false()
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
	kart.motor.forward_speed = BotStuck.STUCK_SPEED * 4.0
	kart.motor.velocity = kart.motor.forward_vector() * kart.motor.forward_speed
	brain.stuck._forget_progress()
	var backed := false
	for i: int in int((BotStuck.PROGRESS_TIME + 0.5) * 60.0):
		brain.input.throttle = 1.0
		brain.stuck.step(1.0 / 60.0)
		if brain.stuck._reverse_left > 0.0:
			backed = true
			break
	assert_bool(backed).is_true()


## GAME.md 9.1: a bot that has stayed in one small circle for ten seconds, backing out or not,
## gives up on its errand, backs away and goes somewhere else; still there five seconds later it
## is put down on a free spawn point, alive and with what it had.
func test_a_bot_stuck_for_long_goes_elsewhere_and_then_is_put_down() -> void:
	var match_node := _match()
	await _runner.simulate_frames(30, 17)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	var stuck := brain.stuck
	var spot := match_node.arena.junction_position + Vector3(6.0, 0.0, 6.0)
	brain.goal = &"collect"
	stuck.reset()
	kart.pot.reset()
	kart.pot.add_coins(5)
	var lives := kart.lives
	# Nine and a half seconds in the one place: not yet.
	assert_float(_held_still(brain, spot, BotStuck.LONG_TIME - 0.5)).is_equal(0.0)
	assert_bool(stuck.gave_up()).is_false()
	# Ten: it gives up, backs away and is off somewhere well away from here.
	assert_float(_held_still(brain, spot, 1.0)).is_greater(0.0)
	assert_bool(stuck.gave_up()).is_true()
	assert_str(brain.goal).is_equal("wander")
	assert_float(brain.target.distance_to(spot)).is_greater(BotBrain.ELSEWHERE_DISTANCE)
	assert_bool(stuck.maneuvering()).is_true()
	# And held there five seconds more, it is put down on a spawn point, as it was otherwise.
	_held_still(brain, spot, BotStuck.PUT_DOWN_AFTER + 0.2)
	var nearest := INF
	for point: Vector3 in match_node.arena.spawn_points:
		nearest = minf(nearest, kart.global_position.distance_to(Vector3(point.x, 0.0, point.z)))
	assert_float(nearest).is_less(0.01)
	assert_bool(kart.alive).is_true()
	assert_int(kart.lives).is_equal(lives)
	assert_int(kart.pot.coins).is_equal(5)
	assert_bool(stuck.gave_up()).is_false()


## GAME.md 9.1: waiting on the Junction to bank is waiting on purpose, and in a room nothing is
## late, so neither ever counts as stuck however long it lasts.
func test_a_bot_waiting_on_purpose_is_never_moved_on() -> void:
	var match_node := _match()
	await _runner.simulate_frames(30, 17)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	brain.goal = &"bank"
	brain.stuck.reset()
	var junction := match_node.arena.junction_position
	_held_still(brain, junction, BotStuck.LONG_TIME + BotStuck.PUT_DOWN_AFTER + 1.0)
	assert_bool(brain.stuck.gave_up()).is_false()
	assert_str(brain.goal).is_equal("bank")
	assert_float(kart.global_position.distance_to(junction)).is_less(0.01)
	match_node.rules.timed = false
	brain.goal = &"collect"
	_held_still(brain, junction, BotStuck.LONG_TIME + 1.0)
	assert_bool(brain.stuck.gave_up()).is_false()


## Steps [param brain]'s stuck watch for [param seconds] with its kart held at [param spot], the
## throttle down, and says when, in seconds, it first gave up, or zero if it never did. Held for
## as long as it has not been put down somewhere else.
func _held_still(brain: BotBrain, spot: Vector3, seconds: float) -> float:
	var kart := brain.kart
	kart.global_position = spot
	var when := 0.0
	for i: int in int(seconds * 60.0):
		if kart.global_position.distance_to(spot) < BotStuck.LONG_STEP:
			kart.global_position = spot
		brain.input.throttle = 1.0
		var was := brain.stuck.gave_up()
		brain.stuck.step(1.0 / 60.0)
		if not was and brain.stuck.gave_up() and when == 0.0:
			when = (i + 1) / 60.0
	return when


## Holds the throttle down on a kart that is going nowhere for [param seconds], and says whether
## the bot gave up and started backing out.
func _gets_stuck(brain: BotBrain, seconds: float) -> bool:
	for i: int in int(seconds * 60.0):
		brain.input.throttle = 1.0
		brain.stuck.step(1.0 / 60.0)
		if brain.stuck._reverse_left > 0.0:
			return true
	return false


## Lets the whole maneuver finish, backing out and driving out again, with nobody asking for
## anything.
func _run_out_reverse(brain: BotBrain) -> void:
	for i: int in 240:
		if brain.stuck._reverse_left <= 0.0 and brain.stuck._swing_left <= 0.0:
			return
		brain.input.throttle = 0.0
		brain.stuck.step(1.0 / 60.0)


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
	kart.motor.drifting = false
	brain.goal = &"wander"
	brain.target = kart.global_position + Vector3(0.0, 0.0, -14.0)
	brain.target_node = null
	brain._path = PackedVector3Array()
	# Against players who drift a little, whose bots throw it into a corner just past square, and
	# with nothing left over from the frames before: without these, whether the flick came at
	# all was a race between the corner opening up past the bots' own reading of the players
	# and the wheel bringing the nose round, which a loaded machine lost.
	match_node.bot_mirror.drift = 0.3
	brain._flick_left = 0.0
	brain._flick_wait = 0.0
	brain._turn_rate = 0.0
	brain._last_heading = kart.motor.heading
	brain.stuck._stuck_time = 0.0
	brain.stuck._reverse_left = 0.0
	brain.stuck._swing_left = 0.0
	brain._dodge_left = 0.0
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
	# GAME.md 9.1: every way of driving comes round once before any comes round twice, so seven
	# bots, a room of eight with one player, are all six and one of them again.
	var rng := RandomNumberGenerator.new()
	for seed: int in 20:
		rng.seed = seed
		var dealt: Array[BotTrait] = []
		for i: int in 7:
			dealt.append(table.pick(rng, dealt))
		for entry: BotTrait in table.entries:
			assert_int(dealt.count(entry)).is_between(1, 2)
	# And a Grand Prix deals its run's bots the same way, GAME.md 9.7.
	var run := GrandPrix.new()
	run.deal_bots(table, 6, rng)
	for entry: BotTrait in table.entries:
		assert_int(run.bots.count(entry)).is_equal(1)


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


## GAME.md 9.1: a hard bot reads the board. A pot is coins somebody has already collected and
## not yet made safe, so whoever is carrying one is worth crossing the room for, and worth
## going after in preference to the fight that happens to be nearest.
func test_a_hard_bot_goes_after_a_fat_pot() -> void:
	var balanced := _trait("balanced")
	var context: Dictionary = {
		"pot_value": 0,
		"enemy_distance": 22.0,
		"enemy_visible": true,
		"pickup_distance": 3.0,
		"pickup_value": 4.0,
	}
	# Out of reach and carrying nothing anybody cares about: the errand wins.
	assert_str(BotGoals.choose(context, balanced)).is_equal("collect")
	# The same kart, the same distance, with 900 points on board and a bot that reads pots.
	context["enemy_pot"] = 900
	context["pot_greed"] = 1.0
	assert_str(BotGoals.choose(context, balanced)).is_equal("hunt")
	# A bot that does not read pots never notices.
	context["pot_greed"] = 0.0
	assert_str(BotGoals.choose(context, balanced)).is_equal("collect")
	# Nor does a pot too small to be worth the detour move anybody far.
	context["pot_greed"] = 1.0
	context["enemy_pot"] = 30
	assert_str(BotGoals.choose(context, balanced)).is_equal("collect")


## Only the hard bots read the board, which is what makes them hard.
func test_only_the_hard_preset_hunts_pots() -> void:
	var easy: BotDifficulty = load("res://data/ai/easy.tres")
	var normal: BotDifficulty = load("res://data/ai/normal.tres")
	var hard: BotDifficulty = load("res://data/ai/hard.tres")
	assert_float(easy.pot_hunting).is_equal(0.0)
	assert_float(normal.pot_hunting).is_equal(0.0)
	assert_float(hard.pot_hunting).is_greater(0.0)


## GAME.md 9.1: a kart pressed up against a bot is a long way off its nose and impossible to
## miss, and a bot that only fired within eight degrees shoved it around instead of shooting it.
func test_a_bot_shoots_the_kart_it_is_bumping_into() -> void:
	var match_node := _match()
	await _runner.simulate_frames(12, 17)
	for crate: Crate in match_node.arena.crates:
		crate.global_position = Vector3(0.0, 0.0, -400.0)
	var kart := match_node.kart_of(0)
	var enemy := match_node.kart_of(1)
	var brain: BotBrain = kart.get_node("Brain")
	# A bumper drives into people instead of shooting them, GAME.md 9.1, and which trait a bot
	# gets is rolled: this test is about the ones that do shoot.
	brain.bot_trait = _trait("hunter")
	# Asked of the brain directly, with the wobble in its aim held still, so the answer is the
	# rule being tested rather than wherever a random spread happened to land.
	brain._willing_to_fire = true
	brain._aim_error = 0.0
	brain._aim_error_left = 99.0
	# Up against the bot's front corner: nineteen degrees off the nose and a meter and a half
	# away, which is a shot that cannot miss and used to be one the bot would not take.
	assert_bool(_fires_at(brain, enemy, Vector3(1.3, 0.0, 0.45))).is_true()
	# Out at that angle across the room the same shot goes nowhere near, and is not taken.
	assert_bool(_fires_at(brain, enemy, Vector3(13.0, 0.0, 4.5))).is_false()


## A decoy shoots, whatever trait it is dealt, GAME.md 7.2: a bumper, which rams rather than
## shoots, and one that rolled to hold its fire this life both fire at the kart in front of them.
func test_a_decoy_always_shoots() -> void:
	var match_node := _match()
	await _runner.simulate_frames(12, 17)
	for crate: Crate in match_node.arena.crates:
		crate.global_position = Vector3(0.0, 0.0, -400.0)
	var kart := match_node.kart_of(0)
	var enemy := match_node.kart_of(1)
	var brain: BotBrain = kart.get_node("Brain")
	brain.bot_trait = _trait("bumper")
	brain._willing_to_fire = false
	brain._aim_error = 0.0
	brain._aim_error_left = 99.0
	assert_bool(_fires_at(brain, enemy, Vector3(1.3, 0.0, 0.45))).is_false()
	# A decoy, as a client's are marked: its own owner, so its seat's other karts are not targets.
	kart.decoy_owner = kart
	assert_bool(_fires_at(brain, enemy, Vector3(1.3, 0.0, 0.45))).is_true()
	kart.decoy_owner = null


## Whether the brain would pull the trigger on an enemy standing at [param at], given a moment
## to settle on it. The bot is put back on its mark looking along +X for each question, and the
## enemy is parked and out of its spawn protection: a bot does not shoot at what it cannot hurt,
## and a moving target is a lead, which is a different question.
func _fires_at(brain: BotBrain, enemy: Kart, at: Vector3) -> bool:
	brain.kart.global_position = Vector3.ZERO
	brain.kart.face(Vector3(1.0, 0.0, 0.0))
	enemy.global_position = at
	enemy.protection_left = 0.0
	enemy.hurt_left = 0.0
	enemy.motor.velocity = Vector3.ZERO
	brain._aim_timer = 0.0
	for i: int in 30:
		brain._shoot(1.0 / 60.0)
	return brain.input.fire


## GAME.md 9.1: a rival whose cash-out would win the match is gone after by every bot, the most
## cautious included, seen or not and from across the table, ahead of pickups; and a bot whose
## own cash-out would win goes to bank it.
func test_a_rival_about_to_win_is_gone_after_and_a_winning_pot_is_banked() -> void:
	var far := {
		"enemy_distance": 60.0,
		"enemy_visible": false,
		"enemy_winning": true,
		"pickup_distance": 2.0,
		"pickup_value": 3.0,
	}
	for id: String in ["cautious", "greedy", "balanced", "hunter"]:
		assert_str(BotGoals.choose(far, _trait(id))).override_failure_message(id).is_equal("hunt")
	far["enemy_winning"] = false
	assert_str(BotGoals.choose(far, _trait("cautious"))).is_equal("collect")
	assert_str(BotGoals.choose({"pot_value": 20, "self_winning": true}, _trait("hunter"))).is_equal(
		"bank"
	)


## And the brain picks that rival out over a nearer kart that would not win, if its trait's chance
## says it goes after them: decided once while the rival stays about to win, and again next time.
func test_a_bot_hunts_the_rival_about_to_win_over_the_nearest() -> void:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	rules.target_score = 1000
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [BotInput.new(), KartInput.new(), KartInput.new()]
	match_node.start(inputs, 9)
	await _runner.simulate_frames(30, 17)
	var bot := match_node.kart_of(0)
	var brain: BotBrain = bot.get_node("Brain")
	var near := match_node.kart_of(1)
	var winner := match_node.kart_of(2)
	near.global_position = bot.global_position + Vector3(3.0, 0.0, 0.0)
	winner.global_position = bot.global_position + Vector3(-20.0, 0.0, 0.0)
	await _runner.simulate_frames(2, 17)
	assert_object(brain._hunt_target()).is_same(near)
	var sure: BotTrait = brain.bot_trait.duplicate()
	sure.winner_chase = 1.0
	brain.bot_trait = sure
	match_node.slots[2].banked = 900
	winner.pot.add_coins(150)
	assert_object(brain._hunt_target()).is_same(winner)
	assert_bool(brain._context()["enemy_winning"]).is_true()
	# Decided, it sticks while the rival stays about to win, whatever the chance says now.
	sure.winner_chase = 0.0
	assert_object(brain._hunt_target()).is_same(winner)
	# Once they are not, it is forgotten, and decided again the next time.
	winner.pot.reset()
	assert_object(brain._hunt_target()).is_same(near)
	winner.pot.add_coins(150)
	assert_object(brain._hunt_target()).is_same(near)
	assert_bool(brain._context().get("enemy_winning", false)).is_false()
