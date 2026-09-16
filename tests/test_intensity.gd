extends GdUnitTestSuite
## The excitement meter, GAME.md 8.4: heat from what just happened plus pressure from how the
## match stands, and the music layer following it.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _start_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	match_node.start(inputs, 23)
	return match_node


## Parks both karts well apart and empties their pots, so the meter starts from nothing.
func _settle(match_node: Match) -> void:
	match_node.kart_of(0).global_position = Vector3(-15.0, 0.0, -9.0)
	match_node.kart_of(1).global_position = Vector3(15.0, 0.0, 9.0)
	for slot: PlayerSlot in match_node.slots:
		slot.kart.pot.reset()
	match_node.intensity.reset()
	await _runner.simulate_frames(6, 17)


func test_one_kill_alone_does_not_wind_the_music_up_but_a_flurry_does() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	await _settle(match_node)
	var meter := match_node.intensity
	assert_float(meter.value).is_less(0.2)
	assert_str(Audio.current_layer).is_equal("calm")
	meter.add(MatchIntensity.KILL)
	await _runner.simulate_frames(20, 17)
	assert_float(meter.value).is_less(Audio.TENSE_ON)
	assert_str(Audio.current_layer).is_equal("calm")
	# Two more on top of it, and the room is hot enough for the music to step up.
	meter.add(MatchIntensity.KILL)
	meter.add(MatchIntensity.KILL)
	await _runner.simulate_frames(40, 17)
	assert_float(meter.value).is_greater(Audio.TENSE_ON)
	assert_str(Audio.current_layer).is_equal("tense")
	# It fades once the shooting stops.
	await _runner.simulate_frames(180, 17)
	assert_float(meter.value).is_less(Audio.TENSE_OFF)
	assert_str(Audio.current_layer).is_equal("calm")


func test_pressure_comes_from_a_fat_pot_a_duel_and_a_cash_out() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	await _settle(match_node)
	var meter := match_node.intensity
	assert_float(meter.pressure).is_equal_approx(0.0, 0.001)
	match_node.kart_of(0).pot.add_coins(int(match_node.rules.junction_hint_full))
	await _runner.simulate_frames(4, 17)
	var with_pot := meter.pressure
	assert_float(with_pot).is_between(0.2, 0.3)
	match_node.kart_of(1).global_position = (
		match_node.kart_of(0).global_position + Vector3(2.0, 0.0, 0.0)
	)
	await _runner.simulate_frames(4, 17)
	assert_float(meter.pressure).is_greater(with_pot + 0.15)


func test_last_call_pins_the_meter_and_everyone_down_drops_it() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	await _settle(match_node)
	var meter := match_node.intensity
	match_node._enter_last_call()
	await _runner.simulate_frames(60, 17)
	assert_float(meter.value).is_equal_approx(1.0, 0.001)
	assert_str(Audio.current_layer).is_equal("peak")
	match_node._set_state(Match.State.RESULTS)
	meter.add(MatchIntensity.KILL)
	meter.reset()
	assert_float(meter.value).is_equal(0.0)
	assert_str(Audio.current_layer).is_equal("calm")
