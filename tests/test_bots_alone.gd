extends GdUnitTestSuite
## Bots in sudden death and bots with nobody else, GAME.md 3.13 and 9.1: sudden death has no clock
## to send them to the bank with every chip; left on their own in it, they go after each other
## harder as it goes on and then end it; and a seat of the demo its bot drives is a bot's to all of
## that, 9.8.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")
const BALANCED: BotTrait = preload("res://data/ai/traits/balanced.tres")

var _runner: GdUnitSceneRunner


func _match(inputs: Array[KartInput]) -> Match:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	rules.target_score = 100000
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start(inputs, 13)
	return match_node


## Into sudden death, as the clock running out takes a match, GAME.md 3.13.
func _sudden_death(match_node: Match) -> void:
	match_node.time_left = 0.0
	match_node._set_state(Match.State.OVERTIME)


## Sudden death's clock reads nought, and a bot took that for no time left: the first chip off the
## Jackpot went straight to the bank, and the pile was left to anybody. It has no clock to a bot.
func test_sudden_death_has_no_clock_for_a_bot() -> void:
	var match_node := _match([BotInput.new(), BotInput.new()] as Array[KartInput])
	await _runner.simulate_frames(12, 17)
	_sudden_death(match_node)
	var brain: BotBrain = match_node.kart_of(0).get_node("Brain")
	var context := brain._context()
	assert_float(float(context["time_left"])).is_equal(INF)
	context["pot_value"] = 3
	context["collecting_jackpot"] = true
	context["jackpot_position"] = Vector3.ZERO
	assert_str(BotGoals.choose(context, BALANCED)).is_equal("jackpot")
	# Nor, away from it and the finale aside, which banks anything, a pot of three for the clock.
	context["collecting_jackpot"] = false
	context["last_call"] = false
	assert_str(BotGoals.choose(context, BALANCED)).is_not_equal("bank")


## With a player still standing nothing changes; with nobody but bots left in sudden death they go
## after each other harder as it goes on, and past a few seconds go after each other over anything
## else, short of a cash-out that takes the match.
func test_bots_left_alone_in_sudden_death_end_it() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(0), BotInput.new(), BotInput.new()]
	var match_node := _match(inputs)
	await _runner.simulate_frames(12, 17)
	var mirror := match_node.bot_mirror
	_sudden_death(match_node)
	mirror.update(match_node, 5.0)
	assert_float(mirror.bots_alone).is_equal(0.0)
	assert_float(mirror.hunt_urgency()).is_equal(mirror.effort)
	match_node.kart_of(0).alive = false
	mirror.update(match_node, 5.0)
	assert_float(mirror.bots_alone).is_equal(5.0)
	assert_bool(mirror.finishing()).is_false()
	assert_float(mirror.hunt_urgency()).is_greater(mirror.effort)
	mirror.update(match_node, BotMirror.FINISH_AFTER)
	assert_bool(mirror.finishing()).is_true()
	assert_float(mirror.hunt_urgency()).is_equal_approx(
		mirror.effort * BotMirror.FINISH_PULL, 0.001
	)
	var brain: BotBrain = match_node.kart_of(1).get_node("Brain")
	var context := brain._context()
	assert_bool(bool(context["finish_it"])).is_true()
	# Wherever the other kart is, seen or not.
	assert_bool(bool(context["enemy_visible"])).is_true()
	context["collecting_jackpot"] = true
	context["jackpot_position"] = Vector3.ZERO
	context["pot_value"] = 900
	assert_str(BotGoals.choose(context, BALANCED)).is_equal("hunt")
	context["self_winning"] = true
	assert_str(BotGoals.choose(context, BALANCED)).is_equal("bank")
	# Out of sudden death it starts again from nothing.
	match_node._set_state(Match.State.PLAYING)
	mirror.update(match_node, 1.0)
	assert_float(mirror.bots_alone).is_equal(0.0)


## A seat of the demo its bot drives is a bot's: bots with only those for company drive as a keen
## player does and end sudden death on their own; somebody taking a seat is a player in it again.
func test_a_seat_of_the_demo_its_bot_drives_is_a_bots() -> void:
	var inputs: Array[KartInput] = [DemoInput.new(0), BotInput.new()]
	var match_node := _match(inputs)
	await _runner.simulate_frames(12, 17)
	var mirror := match_node.bot_mirror
	assert_float(mirror.items).is_equal(BotMirror.ALONE)
	_sudden_death(match_node)
	mirror.update(match_node, 2.0)
	assert_float(mirror.bots_alone).is_greater_equal(2.0)
	(match_node.slots[0].input as DemoInput).take(0)
	mirror.update(match_node, 2.0)
	assert_float(mirror.bots_alone).is_equal(0.0)
