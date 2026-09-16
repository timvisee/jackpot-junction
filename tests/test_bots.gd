extends GdUnitTestSuite
## Grid navigation and the bot brain from GAME.md 9.1.

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
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
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
