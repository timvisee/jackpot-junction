extends GdUnitTestSuite
## The start gantry from GAME.md 8.3: the countdown is a rack of lamps, not a number.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DEFAULT_RULES: MatchRules = preload("res://data/match/default.tres")


func test_the_lamps_fill_up_across_the_countdown_and_turn_green_on_the_drop() -> void:
	var light: StartLight = auto_free(StartLight.new())
	light.set_countdown(1)
	assert_int(light.lit).is_equal(1)
	assert_bool(light.go).is_false()
	light.set_countdown(3)
	assert_int(light.lit).is_equal(3)
	# Never past the rack, whatever it is handed.
	light.set_countdown(StartLight.LAMPS + 4)
	assert_int(light.lit).is_equal(StartLight.LAMPS)
	assert_bool(light.go).is_false()
	# The drop: the whole row goes green at once.
	light.set_go()
	assert_int(light.lit).is_equal(StartLight.LAMPS)
	assert_bool(light.go).is_true()


## The rack and the start tones are one countdown, GAME.md 8.3: every lamp that lights plays a
## tone, so a player watching and a player listening are counting the same thing.
func test_a_lamp_lights_with_every_start_tone() -> void:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 3.0
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	var runner := scene_runner(match_node)
	var tones: Array[int] = []
	Events.countdown_tick.connect(func(count: int) -> void: tones.append(count))
	var inputs: Array[KartInput] = [KartInput.new()]
	match_node.start(inputs, 3)
	# The first lamp and its tone come with the field being held, before any time has passed.
	assert_array(tones).is_equal([1])
	while match_node.state == Match.State.COUNTDOWN:
		await runner.simulate_frames(1, 1)
	assert_array(tones).is_equal([1, 2, 3, 4, 5])
	assert_int(Match.COUNTDOWN_LAMPS).is_equal(StartLight.LAMPS)


## A room with no countdown holds nobody up and says nothing about it.
func test_a_match_with_no_countdown_plays_no_tones() -> void:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.0
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	var runner := scene_runner(match_node)
	var tones := 0
	Events.countdown_tick.connect(func(_count: int) -> void: tones += 1)
	var inputs: Array[KartInput] = [KartInput.new()]
	match_node.start(inputs, 3)
	await runner.simulate_frames(10, 17)
	assert_int(tones).is_equal(0)
	assert_int(match_node.state).is_not_equal(Match.State.COUNTDOWN)
