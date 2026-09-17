extends GdUnitTestSuite
## The announcer, GAME.md 3.12: it calls the kills worth calling and stays quiet for the rest.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner
var _calls: Array[String] = []
var _who: Array[int] = []


## [Events] outlives a test, so the recorder is hooked up and taken off around each one rather
## than left to pile up across the suite.
func before_test() -> void:
	_calls = []
	_who = []
	Events.announced.connect(_record)


func after_test() -> void:
	Events.announced.disconnect(_record)


func _record(slot: int, call: String) -> void:
	_who.append(slot)
	_calls.append(call)


## An announcer of its own, listening to the same global events a match's one would.
func _announcer() -> Announcer:
	var announcer := Announcer.new()
	add_child(announcer)
	return auto_free(announcer)


func _start_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 120.0
	rules.respawn_delay = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new(), KartInput.new()]
	match_node.start(inputs, 31)
	return match_node


## Two kills close together is a double, a third is a triple, and the first kill on its own is
## nothing at all: one kill is the game, not an event.
func test_kills_in_quick_succession_are_called() -> void:
	_announcer()
	Events.kart_killed.emit(1, 0, &"bullet")
	assert_array(_calls).is_empty()
	Events.kart_killed.emit(2, 0, &"bullet")
	assert_array(_calls).is_equal(["DOUBLE KILL"])
	Events.kart_killed.emit(1, 0, &"bullet")
	assert_array(_calls).is_equal(["DOUBLE KILL", "TRIPLE KILL"])


## A run has to be a run: kills far enough apart start again from nothing.
func test_a_slow_pair_of_kills_is_not_a_double() -> void:
	var announcer := _announcer()
	Events.kart_killed.emit(1, 0, &"bullet")
	announcer._now += Announcer.COMBO_WINDOW + 0.5
	Events.kart_killed.emit(2, 0, &"bullet")
	assert_array(_calls).is_empty()


## Two players taking each other out is a trade, however many frames apart it happened.
func test_killing_the_player_who_just_killed_you_is_a_trade() -> void:
	var announcer := _announcer()
	Events.kart_killed.emit(1, 0, &"ram")
	announcer._now += 0.4
	Events.kart_killed.emit(0, 1, &"bullet")
	assert_array(_calls).is_equal(["TRADE KILL"])
	assert_array(_who).is_equal([1])
	# Long enough afterwards it is just a kill.
	announcer._now += Announcer.TRADE_WINDOW + 1.0
	Events.kart_killed.emit(2, 0, &"bullet")
	announcer._now += Announcer.TRADE_WINDOW + 1.0
	Events.kart_killed.emit(0, 2, &"bullet")
	assert_array(_calls).is_equal(["TRADE KILL"])


## Kills without dying add up to a streak, and dying wipes it.
func test_a_streak_is_called_and_dying_ends_it() -> void:
	var announcer := _announcer()
	# Spread out, so nothing reads as a run and the streak is what is left to call.
	for i: int in 3:
		Events.kart_killed.emit(1, 0, &"bullet")
		announcer._now += Announcer.COMBO_WINDOW + 0.5
	assert_array(_calls).is_equal(["HOT STREAK"])
	assert_int(announcer.streaks[0]).is_equal(3)
	Events.kart_killed.emit(0, 1, &"bullet")
	assert_int(announcer.streaks[0]).is_equal(0)


## Falling down a pit or blowing yourself up is nobody's moment.
func test_a_death_with_nobody_to_credit_says_nothing() -> void:
	_announcer()
	Events.kart_killed.emit(0, -1, &"pit")
	Events.kart_killed.emit(0, -1, &"pit")
	Events.kart_killed.emit(1, 1, &"bomb")
	assert_array(_calls).is_empty()


## A real match carries one, and what it calls reaches the HUD.
func test_a_match_announces_through_the_hud() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	assert_object(match_node.announcer).is_not_null()
	match_node.kart_of(1).die(&"bullet", 0)
	match_node.kart_of(2).die(&"bullet", 0)
	await _runner.simulate_frames(2, 17)
	assert_array(_calls).is_equal(["DOUBLE KILL"])
	assert_array(_who).is_equal([0])
