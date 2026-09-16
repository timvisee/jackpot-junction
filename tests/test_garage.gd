extends GdUnitTestSuite
## The Garage, GAME.md 9.4: a practice room with everything on the floor, nobody to fight and no
## clock running.

const GARAGE_SCENE := preload("res://scenes/garage/garage.tscn")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/garage.tres")
const RULES: MatchRules = preload("res://data/match/garage.tres")

var _runner: GdUnitSceneRunner


func test_the_map_has_one_of_everything_to_practise_on() -> void:
	assert_array(LAYOUT.validate()).is_empty()
	var grid := LAYOUT.parse()
	assert_int(grid.spawns.size()).is_greater_equal(2)
	assert_int(grid.targets.size()).is_equal(3)
	assert_int(grid.joker_pads.size()).is_equal(1)
	assert_int(grid.turbo_pads.size()).is_equal(2)
	assert_int(grid.flush_pads.size()).is_equal(4)
	assert_int(grid.coin_pads.size()).is_greater_equal(4)
	assert_int(grid.power_pads.size()).is_greater_equal(2)
	assert_int(grid.crates.size()).is_greater_equal(8)
	assert_int(grid.pits.size()).is_equal(1)
	assert_int(grid.jackpots.size()).is_equal(1)
	# The Junction sits in the middle of the room.
	assert_vector(grid.rect_center(grid.junction)).is_equal_approx(Vector3.ZERO, Vector3.ONE * 0.01)


func test_the_room_runs_one_player_no_bots_and_no_clock() -> void:
	var garage: Node3D = auto_free(GARAGE_SCENE.instantiate())
	var runner: GdUnitSceneRunner = scene_runner(garage)
	# Long enough for the countdown to run out, so the room is actually under way.
	await runner.simulate_frames(120, 17)
	var match_node: Match = garage.get_node("Match")
	assert_int(match_node.slots.size()).is_equal(1)
	assert_bool(match_node.slots[0].is_local_human()).is_true()
	assert_object(match_node.slots[0].bot_trait).is_null()
	assert_int(match_node.arena.targets.size()).is_equal(3)
	assert_int(match_node.arena.joker_pads.size()).is_equal(1)
	# The clock stands still, so the room never reaches Last Call or the results.
	assert_bool(match_node.rules.timed).is_false()
	var left := match_node.time_left
	await runner.simulate_frames(40, 17)
	assert_float(match_node.time_left).is_equal(left)
	assert_int(match_node.state).is_equal(Match.State.PLAYING)
	assert_bool(match_node.hud._timer.visible).is_false()


func test_shooting_a_target_pays_the_shooter() -> void:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.arena_layout = LAYOUT
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start([KartInput.new()] as Array[KartInput], 43)
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var target: Target = match_node.arena.targets[0]
	assert_int(kart.pot.coins).is_equal(0)
	# Lined up 4 m below the target, shooting straight up the table.
	kart.global_position = target.global_position + Vector3(0.0, 0.0, 4.0)
	kart.face(Vector3(0.0, 0.0, -1.0))
	kart.cannon.stats.aim_assist = false
	kart.cannon.cooldown_left = 0.0
	await _runner.simulate_frames(2, 17)
	kart.cannon.fire(
		match_node.bullets,
		0,
		kart.global_position + Vector3(0.0, 0.0, -1.0),
		Vector3(0.0, 0.0, -1.0),
		Color.WHITE
	)
	await _runner.simulate_frames(20, 17)
	assert_bool(target.alive).is_false()
	assert_int(kart.pot.coins).is_equal(rules.target_coins)
	assert_float(match_node.slots[0].stats.value(&"targets")).is_equal(1.0)
