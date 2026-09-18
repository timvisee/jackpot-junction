extends GdUnitTestSuite
## The jokers that pay their holder of their own accord, GAME.md 7.3: a tick of time, a metre
## driven or a metre drifted turned into coins, mult or banked points. [JokerTick] is called
## directly where a figure has to be exact, since a match running underneath the test is paying
## the same jokers on its own clock.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _start_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 21)
	return match_node


## A match past its countdown, with [param id] freshly attached to slot 0 and an empty pot. The
## joker is attached last so its own clock starts here rather than part way through.
func _armed(match_node: Match, id: String) -> Kart:
	var kart := match_node.kart_of(0)
	kart.jokers.add(load("res://data/jokers/%s.tres" % id))
	kart.pot.reset()
	return kart


func test_payday_pays_a_coin_a_second() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := _armed(match_node, "payday")
	assert_bool(JokerTick.step(match_node.slots, 0.5)).is_false()
	assert_int(kart.pot.coins).is_equal(0)
	JokerTick.step(match_node.slots, 0.5)
	assert_int(kart.pot.coins).is_equal(1)
	JokerTick.step(match_node.slots, 3.0)
	assert_int(kart.pot.coins).is_equal(4)


## The wiring rather than the sum: a match steps its jokers on its own, without being asked.
func test_a_running_match_pays_the_jokers_that_pay() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := _armed(match_node, "payday")
	await _runner.simulate_frames(120, 17)
	assert_int(kart.pot.coins).is_between(1, 3)


## A dead kart earns nothing: the pot it would be paid into is not on the floor.
func test_nothing_is_paid_to_a_kart_that_is_not_driving() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := _armed(match_node, "payday")
	kart.die(&"pit", -1)
	JokerTick.step(match_node.slots, 5.0)
	assert_int(kart.pot.coins).is_equal(0)
