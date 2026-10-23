extends GdUnitTestSuite
## The Touch controls setting, GAME.md 4.2: forced on or off, or auto, which starts from the
## platform and switches at runtime as a finger lands on the glass or the pad is used again.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DEFAULT_RULES := preload("res://data/match/default.tres")

var _was_enabled := false
var _was_auto := true


func before_test() -> void:
	_was_enabled = TouchInput.enabled
	_was_auto = TouchInput.auto


func after_test() -> void:
	TouchInput.set_mode(TouchInput.MODE_AUTO)
	TouchInput.enabled = _was_enabled
	TouchInput.auto = _was_auto


## On forces touch play, Off forces it off, whatever the platform; neither is left to switch.
func test_on_and_off_force_the_mode() -> void:
	TouchInput.set_mode(TouchInput.MODE_ON)
	assert_bool(TouchInput.enabled).is_true()
	assert_bool(TouchInput.auto).is_false()
	TouchInput.set_mode(TouchInput.MODE_OFF)
	assert_bool(TouchInput.enabled).is_false()
	assert_bool(TouchInput.auto).is_false()


## Auto starts from the platform, off on this desktop, and follows the last thing reached for: a
## real touch turns it on, a key or a pad turns it off again.
func test_auto_follows_the_last_input() -> void:
	TouchInput.set_mode(TouchInput.MODE_AUTO)
	assert_bool(TouchInput.auto).is_true()
	assert_bool(TouchInput.enabled).is_equal(OS.has_feature("mobile"))
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	TouchInput.saw(touch)
	assert_bool(TouchInput.enabled).is_true()
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	TouchInput.saw(key)
	assert_bool(TouchInput.enabled).is_false()


## The mouse the engine makes out of the finger does not undo the touch that finger just made: a
## mouse event hard on the heels of a touch is let be, but a real one later turns touch off.
func test_the_mouse_made_of_a_finger_does_not_undo_the_touch() -> void:
	TouchInput.set_mode(TouchInput.MODE_AUTO)
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	TouchInput.saw(touch)
	assert_bool(TouchInput.enabled).is_true()
	# A mouse move right after the touch is the finger's own; touch play stays on.
	TouchInput.saw(InputEventMouseMotion.new())
	assert_bool(TouchInput.enabled).is_true()
	# A move well after it is a real mouse; touch play goes.
	TouchInput._touched_ms -= TouchInput.TOUCH_GUARD_MS + 1
	TouchInput.saw(InputEventMouseMotion.new())
	assert_bool(TouchInput.enabled).is_false()


## A forced mode ignores the input it sees: On stays on under a key, Off stays off under a touch.
func test_a_forced_mode_does_not_switch() -> void:
	TouchInput.set_mode(TouchInput.MODE_ON)
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	TouchInput.saw(key)
	assert_bool(TouchInput.enabled).is_true()
	TouchInput.set_mode(TouchInput.MODE_OFF)
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	TouchInput.saw(touch)
	assert_bool(TouchInput.enabled).is_false()


## The match HUD puts up the mouse's joker clicks or the on-screen touch controls to match the
## mode, GAME.md 4.2, and swaps them when it switches, so the controls come and go with it.
func test_the_match_hud_swaps_its_input_when_touch_switches() -> void:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = true
	var runner := scene_runner(match_node)
	match_node.start([DemoInput.new(0), BotInput.new()], 21)
	await runner.simulate_frames(3, 17)
	var hud := match_node.hud
	# Off touch: the mouse's joker clicks, no on-screen controls.
	assert_int(hud._input_nodes.size()).is_equal(1)
	assert_bool(hud._input_nodes[0] is MouseJokers).is_true()
	# Touch switched on: the on-screen controls and emotes take their place.
	Events.touch_mode_changed.emit(true)
	await runner.simulate_frames(2, 17)
	assert_int(hud._input_nodes.size()).is_equal(2)
	assert_bool(hud._input_nodes[0] is TouchControls).is_true()
	# And back off.
	Events.touch_mode_changed.emit(false)
	await runner.simulate_frames(2, 17)
	assert_bool(hud._input_nodes[0] is MouseJokers).is_true()


## The setting is one of the three values and survives a trip through the settings file.
func test_the_touch_mode_is_remembered() -> void:
	var settings := Settings.new()
	settings.path = "user://test_touch_mode.cfg"
	settings.touch_mode = TouchInput.MODE_ON
	assert_int(settings.save_to_disk()).is_equal(OK)
	var read := Settings.new()
	read.path = settings.path
	read.load_from_disk()
	assert_str(read.touch_mode).is_equal(TouchInput.MODE_ON)
	assert_array(TouchInput.MODES).contains([read.touch_mode])
	Settings.remove_files(settings.path)
