extends GdUnitTestSuite
## Steam Input's controllers as the game's own pads, GAME.md 10.8: each a pad of its own, its
## button actions pressed as the pad's own buttons where one button is bound to just those, as a
## button no pad has otherwise, its sticks and triggers on the pad's axes, and Steam's settings and
## knocks reached through it. Against [FakeSteamInput]; nothing here talks to Steam.

## A controller's handle as Steam gives it, and Steam's type for a DualSense.
const HANDLE := 7
const OTHER := 9
const DUALSENSE := 13
## The pad the first controller is.
const PAD := SteamPads.FIRST_DEVICE
## Two buttons of the controller's, as Steam's origins.
const BUTTON_A := 1
const BUTTON_R1 := 2


## Hears every event that comes into the window, as a screen of the game's would.
class Ear:
	extends Node
	var heard: Array[InputEvent] = []

	func _input(event: InputEvent) -> void:
		if event.device >= SteamPads.FIRST_DEVICE:
			heard.append(event)

	## The presses heard, buttons and actions, leaving out the sticks.
	func presses() -> Array[InputEvent]:
		var pressed: Array[InputEvent] = []
		for event: InputEvent in heard:
			if event.is_pressed() and not event is InputEventJoypadMotion:
				pressed.append(event)
		return pressed


var _steam: FakeSteamInput
var _pads: SteamPads
var _ear: Ear


func before_test() -> void:
	_steam = FakeSteamInput.new()
	var names: Array = []
	for action: StringName in SteamActions.BUTTONS:
		names.append(String(action))
	names.append_array(SteamActions.STICKS.keys())
	names.append_array(SteamActions.TRIGGERS.keys())
	_steam.know_actions(names)
	_ear = Ear.new()
	add_child(_ear)


func after_test() -> void:
	if is_instance_valid(_pads):
		_pads.free()
	_ear.free()
	InputActions.register_defaults()
	DeviceInput.recent.clear()
	PadFamily.reset()


## Steam Input started with the controllers plugged in so far.
func _start() -> SteamPads:
	_pads = SteamPads.new(_steam)
	add_child(_pads)
	return _pads


## [param actions] held on [param handle], each on the controller's button in [param on], and a
## frame read.
func _hold(actions: Array, on: Dictionary = {}, handle := HANDLE) -> void:
	for action: String in on:
		_steam.origins[action] = on[action]
	_steam.held[handle] = actions
	_pads.poll()


func test_each_controller_is_a_pad_of_its_own() -> void:
	_steam.plug(HANDLE, DUALSENSE)
	_start()
	assert_array(DeviceInput.pads()).contains([PAD])
	assert_int(PadFamily.of_device(PAD)).is_equal(PadFamily.Family.PLAYSTATION)
	_steam.plug(OTHER)
	assert_array(DeviceInput.pads()).contains([PAD, PAD + 1])
	_steam.unplug(HANDLE)
	assert_array(DeviceInput.pads()).not_contains([PAD])
	# The first pad's id is free again for the next controller.
	_steam.plug(HANDLE)
	assert_array(DeviceInput.pads()).contains([PAD, PAD + 1])


func test_the_manifest_and_the_set_go_to_steam() -> void:
	_steam.plug(HANDLE)
	_start()
	_pads.poll()
	assert_str(_steam.manifest).ends_with(SteamActions.MANIFEST)
	assert_int(_steam.active_set.get(HANDLE, 0)).is_equal(_steam.action_handles[SteamActions.SET])


func test_a_button_of_the_games_layout_is_the_pads_own_button() -> void:
	_steam.plug(HANDLE)
	_start()
	var on_a := {"fire": [BUTTON_A], "joker_drop": [BUTTON_A], "ui_accept": [BUTTON_A]}
	_hold(["fire", "joker_drop", "ui_accept"], on_a)
	assert_bool(Input.is_joy_button_pressed(PAD, JOY_BUTTON_A)).is_true()
	assert_bool(DeviceInput.pressed(InputActions.FIRE, PAD)).is_true()
	assert_bool(DeviceInput.pressed(InputActions.JOKER_DROP, PAD)).is_true()
	# One press, as a pad's own A is, which a screen taking the pick over the drop hears once.
	assert_int(_ear.presses().size()).is_equal(1)
	_hold([])
	assert_bool(Input.is_joy_button_pressed(PAD, JOY_BUTTON_A)).is_false()
	assert_bool(DeviceInput.pressed(InputActions.FIRE, PAD)).is_false()


func test_an_action_bound_apart_in_steam_is_heard_alone() -> void:
	_steam.plug(HANDLE)
	_start()
	_hold(["fire"], {"fire": [BUTTON_R1]})
	assert_bool(DeviceInput.pressed(InputActions.FIRE, PAD)).is_true()
	assert_bool(DeviceInput.pressed(InputActions.JOKER_DROP, PAD)).is_false()
	assert_bool(Input.is_action_pressed(&"ui_accept")).is_false()
	var press := _ear.presses()[0] as InputEventJoypadButton
	assert_bool(InputActions.is_chord(press)).is_true()
	_hold([])
	assert_bool(DeviceInput.pressed(InputActions.FIRE, PAD)).is_false()


func test_the_d_pad_walks_the_menus() -> void:
	_steam.plug(HANDLE)
	_start()
	_hold(["joker_prev", "ui_left"], {"joker_prev": [BUTTON_A], "ui_left": [BUTTON_A]})
	assert_bool(Input.is_action_pressed(&"ui_left")).is_true()
	assert_bool(DeviceInput.pad_strength(&"ui_left", PAD) > 0.0).is_true()
	assert_bool(DeviceInput.pressed(InputActions.JOKER_PREV, PAD)).is_true()
	assert_int(_ear.presses().size()).is_equal(1)
	_hold([])
	assert_bool(Input.is_action_pressed(&"ui_left")).is_false()


func test_two_buttons_at_once_are_two_presses() -> void:
	_steam.plug(HANDLE)
	_start()
	_hold(["fire", "nitro"], {"fire": [BUTTON_A], "nitro": [BUTTON_R1]})
	assert_int(_ear.presses().size()).is_equal(2)
	assert_bool(DeviceInput.pressed(InputActions.FIRE, PAD)).is_true()
	assert_bool(DeviceInput.pressed(InputActions.NITRO, PAD)).is_true()
	# Letting one go leaves the other held.
	_hold(["nitro"])
	assert_bool(DeviceInput.pressed(InputActions.FIRE, PAD)).is_false()
	assert_bool(DeviceInput.pressed(InputActions.NITRO, PAD)).is_true()


func test_the_sticks_and_triggers_move_the_pads_own() -> void:
	_steam.plug(HANDLE)
	_start()
	_steam.analog[HANDLE] = {
		"steer_stick": Vector2(0.5, 1.0),
		"aim_stick": Vector2(-1.0, 0.0),
		"throttle_trigger": Vector2(0.8, 0.0),
	}
	_pads.poll()
	assert_float(Input.get_joy_axis(PAD, JOY_AXIS_LEFT_X)).is_equal_approx(0.5, 0.001)
	# Steam's up is the engine's less.
	assert_float(Input.get_joy_axis(PAD, JOY_AXIS_LEFT_Y)).is_equal_approx(-1.0, 0.001)
	assert_float(DeviceInput.strength(InputActions.DRIVE_UP, PAD)).is_greater(0.9)
	assert_float(DeviceInput.strength(InputActions.AIM_LEFT, PAD)).is_greater(0.9)
	assert_float(Input.get_joy_axis(PAD, JOY_AXIS_TRIGGER_RIGHT)).is_equal_approx(0.8, 0.001)
	assert_float(DeviceInput.strength(InputActions.THROTTLE, PAD)).is_greater(0.7)
	_steam.analog[HANDLE] = {}
	_pads.poll()
	assert_float(Input.get_joy_axis(PAD, JOY_AXIS_LEFT_X)).is_equal(0.0)
	assert_float(DeviceInput.strength(InputActions.THROTTLE, PAD)).is_equal(0.0)


func test_a_controller_gone_lets_go_of_everything() -> void:
	_steam.plug(HANDLE)
	_start()
	_steam.analog[HANDLE] = {"steer_stick": Vector2(1.0, 0.0)}
	_hold(["fire"], {"fire": [BUTTON_A]})
	_steam.unplug(HANDLE)
	assert_bool(DeviceInput.pressed(InputActions.FIRE, PAD)).is_false()
	assert_float(Input.get_joy_axis(PAD, JOY_AXIS_LEFT_X)).is_equal(0.0)


func test_nothing_is_read_before_steam_has_the_manifest() -> void:
	_steam.action_handles.clear()
	_steam.plug(HANDLE)
	_start()
	_hold(["fire"], {"fire": [BUTTON_A]})
	assert_int(_ear.presses().size()).is_equal(0)


func test_steams_controller_settings_and_knocks_go_through_steam() -> void:
	_steam.plug(HANDLE)
	_start()
	assert_bool(_pads.show_layout()).is_true()
	assert_array(_steam.calls).contains(["showBindingPanel %d" % HANDLE])
	DeviceInput.rumble(PAD, 0.25, 1.0, 0.1)
	assert_array(_steam.knocks).contains([[HANDLE, 65535, 16384]])


func test_the_chords_are_never_kept_nor_drawn() -> void:
	InputActions.chord([InputActions.FIRE, &"ui_accept"])
	assert_array(InputActions.descriptors(InputActions.FIRE)).is_equal(
		InputActions.DEFAULTS[InputActions.FIRE]
	)
	var shown := InputActions.first_event(InputActions.FIRE, false) as InputEventJoypadButton
	assert_int(shown.button_index).is_equal(JOY_BUTTON_A)
	# Rebinding the pad's button leaves the chord, Steam's, where it is.
	InputActions.rebind(InputActions.FIRE, {"button": JOY_BUTTON_X})
	var chorded := false
	for event: InputEvent in InputMap.action_get_events(InputActions.FIRE):
		chorded = chorded or InputActions.is_chord(event)
	assert_bool(chorded).is_true()
	InputActions.forget_chords()
	for event: InputEvent in InputMap.action_get_events(&"ui_accept"):
		assert_bool(InputActions.is_chord(event)).is_false()


func test_steam_input_is_on_as_the_player_has_it() -> void:
	var was := Store.steam
	Store.steam = null
	assert_bool(Store.steam_input_wanted(PackedStringArray(), true)).is_false()
	Store.steam = SteamStore.new(_steam)
	assert_bool(Store.steam_input_wanted(PackedStringArray(), true)).is_true()
	assert_bool(Store.steam_input_wanted(PackedStringArray(), false)).is_false()
	assert_bool(Store.steam_input_wanted(PackedStringArray(["--steam-input"]), false)).is_true()
	assert_bool(Store.steam_input_wanted(PackedStringArray(["--no-steam-input"]), true)).is_false()
	Store.steam = was
