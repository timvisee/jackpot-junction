extends GdUnitTestSuite
## Rubber banding, GAME.md 9.1: the bots read the players' habits and the score gap, and play at
## the pitch the players set.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const TRAIT: BotTrait = preload("res://data/ai/traits/balanced.tres")

var _runner: GdUnitSceneRunner


func _start_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 300.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(), BotInput.new()]
	match_node.start(inputs, 37)
	return match_node


func test_a_quiet_player_leaves_the_bots_quiet_and_a_busy_one_wakes_them_up() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var mirror := match_node.bot_mirror
	# Nothing done yet: bots sit on their items, keep their nitro and drive tidily.
	assert_float(mirror.items).is_equal(0.0)
	assert_float(mirror.nitro).is_equal(0.0)
	assert_float(mirror.drift).is_equal(0.0)
	assert_float(mirror.item_patience(5.0)).is_greater(25.0)
	assert_float(mirror.nitro_threshold()).is_greater(1.0)
	assert_float(mirror.drift_angle()).is_greater(2.0)
	assert_float(mirror.item_appetite()).is_less(0.3)
	# A player who plays hard drags them up with them.
	var stats := match_node.slots[0].stats
	match_node.time_left = match_node.rules.duration - 60.0
	stats.add(&"items", 4.0)
	stats.add(&"nitro", 4.0)
	stats.add(&"driven", 400.0)
	stats.add(&"drifted", 140.0)
	mirror.update(match_node)
	assert_float(mirror.items).is_equal(1.0)
	assert_float(mirror.nitro).is_equal(1.0)
	assert_float(mirror.drift).is_equal(1.0)
	assert_float(mirror.item_patience(5.0)).is_equal_approx(2.0, 0.01)
	assert_float(mirror.nitro_threshold()).is_equal_approx(0.3, 0.01)
	assert_float(mirror.drift_angle()).is_equal_approx(0.9, 0.01)


func test_effort_leans_on_the_banked_gap_but_never_speeds_a_bot_up() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var mirror := match_node.bot_mirror
	assert_float(mirror.effort).is_equal_approx(1.0, 0.001)
	match_node.slots[0].banked = 1000
	mirror.update(match_node)
	assert_float(mirror.effort).is_equal_approx(BotMirror.EFFORT_MAX, 0.001)
	match_node.slots[1].banked = 3000
	mirror.update(match_node)
	assert_float(mirror.effort).is_equal_approx(BotMirror.EFFORT_MIN, 0.001)
	# The throttle only ever comes off; it is never turned past the kart's own top speed.
	var brain: BotBrain = match_node.slots[1].kart.get_node("Brain")
	await _runner.simulate_frames(20, 17)
	assert_float(brain.input.throttle).is_less(1.0)
	match_node.slots[1].banked = 0
	mirror.update(match_node)
	await _runner.simulate_frames(20, 17)
	assert_float(brain.input.throttle).is_equal_approx(1.0, 0.001)


func test_the_item_goal_follows_the_appetite_but_a_trait_still_counts() -> void:
	var context: Dictionary = {
		"pot_value": 0, "has_item": false, "item_distance": 5.0, "item_appetite": 1.5
	}
	assert_str(BotBrain.choose_goal(context, TRAIT)).is_equal("item")
	context["item_appetite"] = 0.15
	context["pickup_distance"] = 9.0
	context["pickup_value"] = 2.0
	assert_str(BotBrain.choose_goal(context, TRAIT)).is_equal("collect")


func test_a_bot_behind_on_points_settles_for_a_smaller_pot() -> void:
	var context: Dictionary = {"pot_value": 100, "bank_urgency": 1.0}
	assert_str(BotBrain.choose_goal(context, TRAIT)).is_equal("wander")
	context["bank_urgency"] = BotMirror.EFFORT_MAX
	assert_str(BotBrain.choose_goal(context, TRAIT)).is_equal("bank")
