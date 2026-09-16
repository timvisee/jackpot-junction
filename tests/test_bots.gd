extends GdUnitTestSuite
## Grid navigation and the bot brain from GAME.md 9.1.

const DEFAULT_RULES: MatchRules = preload("res://data/match/default.tres")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _trait(id: String) -> BotTrait:
	return load("res://data/ai/traits/%s.tres" % id)


func test_paths_avoid_walls_and_reopen_when_a_crate_dies() -> void:
	var layout: ArenaLayout = load("res://data/maps/lucky_crossing.tres")
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
