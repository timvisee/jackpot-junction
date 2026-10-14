extends GdUnitTestSuite
## The speedometer in the HUD block, GAME.md 8.3: the dial and the number both read what the kart
## is doing, and both light up while the nitro is lit.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _start_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	match_node.start(inputs, 31)
	return match_node


## Puts the kart at a speed along its own nose, both as the motor's own figure and as the
## velocity the gauge reads off it.
func _set_speed(kart: Kart, speed: float) -> void:
	kart.motor.forward_speed = speed
	kart.motor.velocity = kart.motor.forward_vector() * speed


## The number off the readout, in km/h: the unit is written on the dial rather than after it.
func _reading(readout: Label) -> int:
	return int(readout.text)


func test_the_dial_and_the_number_follow_the_kart() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(30, 17)
	assert_int(match_node.state).is_equal(Match.State.PLAYING)
	var kart := match_node.kart_of(0)
	# Nobody at the wheel but this test, so the kart holds whatever it is given.
	kart.input = KartInput.new()
	var block: Dictionary = match_node.hud._blocks[0]
	var dial: SpeedDial = block["speed_dial"]
	var readout: Label = block["speed"]
	# In km/h whatever the machine's locale would say, see [SpeedUnits].
	var were := Game.settings.speed_unit_chosen
	Game.settings.speed_unit_chosen = SpeedUnits.KMH
	_set_speed(kart, 0.0)
	await _runner.simulate_frames(2, 17)
	assert_float(dial.value).is_equal_approx(0.0, 0.5)
	assert_int(_reading(readout)).is_equal(0)
	# Flat out without nitro: a long way up the dial, but with room left on it.
	_set_speed(kart, kart.stats.top_speed)
	await _runner.simulate_frames(2, 17)
	assert_float(dial.value).is_between(45.0, 60.0)
	var flat_out := roundi(kart.stats.top_speed * MatchHud.SPEED_SCALE)
	assert_int(_reading(readout)).is_between(flat_out - 15, flat_out)
	var calm: Color = readout.get_theme_color("font_color")
	# On nitro the needle uses that room, and both parts of the gauge light up.
	kart.input.nitro = true
	_set_speed(kart, kart.stats.top_speed * kart.stats.nitro_speed_multiplier)
	await _runner.simulate_frames(2, 17)
	assert_bool(kart.nitro_active).is_true()
	assert_float(dial.value).is_greater(95.0)
	assert_int(_reading(readout)).is_greater(flat_out + 100)
	assert_object(readout.get_theme_color("font_color")).is_not_equal(calm)
	assert_object(dial.modulate).is_equal(readout.get_theme_color("font_color"))
	# In miles an hour, chosen, the number and the unit on the dial both say so.
	Game.settings.speed_unit_chosen = SpeedUnits.MPH
	await _runner.simulate_frames(2, 17)
	assert_str(dial.unit).is_equal(SpeedUnits.MPH_WORD)
	assert_int(_reading(readout)).is_less(flat_out + 100)
	Game.settings.speed_unit_chosen = were
	# A dead kart reads nothing rather than keeping the speed it died at.
	kart.input.nitro = false
	kart.die(&"test", -1)
	await _runner.simulate_frames(2, 17)
	assert_int(_reading(readout)).is_equal(0)
	assert_float(dial.value).is_equal_approx(0.0, 0.5)


## The block a speedometer sits in holds its width, GAME.md 8.3. It used to be measured from
## whatever was written in it, so it grew as the speed went from 99 to 100 and shrank again at
## the next corner, and a pane that never stops moving is a pane the eye keeps going back to.
func test_the_block_holds_its_width_whatever_the_numbers_say() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(30, 17)
	var kart := match_node.kart_of(0)
	kart.input = KartInput.new()
	var block: Dictionary = match_node.hud._blocks[0]
	var card: Control = block["box"]
	var widths: Array[float] = []
	for speed: float in [0.0, 7.0, 19.0, 3.0]:
		_set_speed(kart, speed)
		kart.pot.coins = int(speed * 137.0)
		kart.pot.mult = 1.0 + speed
		await _runner.simulate_frames(4, 17)
		widths.append(card.size.x)
	for width: float in widths:
		assert_float(width).is_equal_approx(widths[0], 0.01)
	assert_float(widths[0]).is_greater_equal(MatchHud.BLOCK_WIDTH)


## The pointer swings onto the speed on a spring and settles there, GAME.md 8.3, and the foil mark
## holds the highest speed of the last moment once the speed has fallen, then falls back to it.
func test_the_pointer_settles_and_the_peak_holds() -> void:
	var dial: SpeedDial = auto_free(SpeedDial.new())
	dial.size = Vector2(88.0, 88.0)
	add_child(dial)
	dial.value = 80.0
	for i: int in 90:
		dial._process(1.0 / 60.0)
	assert_float(dial._pointer.rotation).is_equal_approx(SpeedDial._angle(0.8), 0.06)
	dial.value = 20.0
	for i: int in 12:
		dial._process(1.0 / 60.0)
	assert_bool(dial._peak.visible).is_true()
	assert_float(dial._peak.rotation).is_equal_approx(SpeedDial._angle(0.8), 0.001)
	for i: int in roundi((SpeedDial.PEAK_HOLD + 2.0) * 60.0):
		dial._process(1.0 / 60.0)
	assert_bool(dial._peak.visible).is_false()
	assert_float(dial._pointer.rotation).is_equal_approx(SpeedDial._angle(0.2), 0.06)
