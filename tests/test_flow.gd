extends GdUnitTestSuite
## Settings persistence, the menu scenes and the match scene built from a lobby configuration.

const TEST_SETTINGS_PATH := "user://test_settings.cfg"
const SETTINGS_SCENE := preload("res://scenes/ui/settings_screen.tscn")
const TITLE_SCENE := preload("res://scenes/ui/title.tscn")
const MATCH_SCENE := preload("res://scenes/match/match_scene.tscn")


func after_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS_PATH))


## The karts have a slider of their own, GAME.md 8.5: their engine and tires run the whole time
## rather than in bursts, so how loud that bed sits is a taste the effects slider cannot express.
func test_the_kart_slider_drives_the_kart_bus() -> void:
	var bus := AudioServer.get_bus_index(Buses.KART)
	assert_int(bus).is_greater(0)
	assert_str(AudioServer.get_bus_send(bus)).is_equal(Buses.SFX)
	var before := AudioServer.get_bus_volume_db(bus)
	var settings := Settings.new()
	settings.kart_volume = 0.25
	settings.apply_audio()
	assert_float(AudioServer.get_bus_volume_db(bus)).is_less(-6.0)
	settings.kart_volume = 1.0
	settings.apply_audio()
	assert_float(AudioServer.get_bus_volume_db(bus)).is_equal_approx(0.0, 0.01)
	AudioServer.set_bus_volume_db(bus, before)


func test_the_audio_tab_offers_the_kart_slider() -> void:
	var screen: Control = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	await await_idle_frame()
	var labels: PackedStringArray = []
	for node: Node in _all(screen):
		var label := node as Label
		if label != null:
			labels.append(label.text)
	assert_array(labels).contains(["Master", "Music", "Effects", "Karts"])


func _all(node: Node) -> Array[Node]:
	var found: Array[Node] = [node]
	for child: Node in node.get_children():
		found.append_array(_all(child))
	return found


func test_settings_round_trip_through_disk() -> void:
	var saved := Settings.new()
	saved.path = TEST_SETTINGS_PATH
	saved.music_volume = 0.25
	saved.kart_volume = 0.35
	saved.muffle_on_death = false
	saved.fullscreen = true
	saved.aim_assist = 0.4
	saved.bot_count = 2
	saved.difficulty = "hard"
	saved.bindings = {"fire": [{"key": KEY_F}]}
	assert_int(saved.save_to_disk()).is_equal(OK)
	var loaded := Settings.new()
	loaded.path = TEST_SETTINGS_PATH
	loaded.load_from_disk()
	assert_float(loaded.music_volume).is_equal(0.25)
	assert_float(loaded.kart_volume).is_equal(0.35)
	assert_bool(loaded.muffle_on_death).is_false()
	assert_bool(loaded.fullscreen).is_true()
	assert_float(loaded.aim_assist).is_equal_approx(0.4, 0.0001)
	assert_int(loaded.bot_count).is_equal(2)
	assert_str(loaded.difficulty).is_equal("hard")
	assert_bool(loaded.bindings.has("fire")).is_true()


func test_applying_bindings_changes_the_input_map_and_reset_restores_defaults() -> void:
	var settings := Settings.new()
	settings.bindings = {"fire": [{"key": KEY_F}]}
	settings.apply_input()
	var events := InputMap.action_get_events(InputActions.FIRE)
	assert_int(events.size()).is_equal(1)
	assert_int((events[0] as InputEventKey).physical_keycode).is_equal(KEY_F)
	settings.reset_bindings()
	assert_int(InputMap.action_get_events(InputActions.FIRE).size()).is_equal(2)
	assert_str(InputActions.binding_text(InputActions.FIRE, true)).contains("Space")


func test_rebind_replaces_only_the_same_device_kind() -> void:
	InputActions.register_defaults()
	InputActions.rebind(InputActions.FIRE, {"key": KEY_J})
	assert_str(InputActions.binding_text(InputActions.FIRE, true)).is_equal("J")
	assert_str(InputActions.binding_text(InputActions.FIRE, false)).is_equal("A")
	assert_str(InputActions.binding_text(InputActions.FIRE, false)).is_not_equal("-")
	InputActions.register_defaults()


func test_match_config_builds_inputs_and_rules() -> void:
	var config := MatchConfig.new()
	config.bot_count = 2
	config.duration = 180.0
	config.target_score = 0
	var inputs := config.inputs()
	assert_int(inputs.size()).is_equal(3)
	assert_bool(inputs[0] is PlayerInput).is_true()
	assert_bool(inputs[1] is BotInput).is_true()
	var rules := config.rules(load("res://data/match/default.tres"))
	assert_float(rules.duration).is_equal(180.0)
	assert_int(rules.target_score).is_greater(1000000)


## GAME.md 4.2: a player who has been driving with a pad should not have to reach for the
## keyboard to press a button on a menu.
func test_the_menu_actions_carry_a_gamepad_as_well_as_a_key() -> void:
	InputActions.register_defaults()
	var accept := InputActions.make_event({"button": JOY_BUTTON_A})
	var cancel := InputActions.make_event({"button": JOY_BUTTON_B})
	assert_bool(InputMap.action_has_event(&"ui_accept", accept)).is_true()
	assert_bool(InputMap.action_has_event(&"ui_cancel", cancel)).is_true()
	# The keys they came with stay, and asking a second time does not add the pad twice.
	var accepts := InputMap.action_get_events(&"ui_accept").size()
	assert_int(accepts).is_greater(1)
	InputActions.register_defaults()
	assert_int(InputMap.action_get_events(&"ui_accept").size()).is_equal(accepts)


## Every pad's buttons are the bindings, not only the first pad's. A binding made in code belongs
## to the first pad unless it is told otherwise, and then a second pad could not take a seat, pause
## or work a menu, GAME.md 3.8.
func test_every_pad_presses_the_bound_buttons() -> void:
	InputActions.register_defaults()
	for pad: int in 4:
		var start := InputEventJoypadButton.new()
		start.device = pad
		start.button_index = JOY_BUTTON_START
		start.pressed = true
		assert_bool(InputMap.event_is_action(start, InputActions.JOIN)).is_true()
		assert_bool(InputMap.event_is_action(start, InputActions.PAUSE)).is_true()
		var accept := InputEventJoypadButton.new()
		accept.device = pad
		accept.button_index = JOY_BUTTON_A
		accept.pressed = true
		assert_bool(InputMap.event_is_action(accept, &"ui_accept")).is_true()


func test_menu_scenes_build() -> void:
	var title: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(title)
	assert_object(title.play_button).is_not_null()
	assert_str(title.play_button.text).is_equal("Play")
	# One way in to playing: which kind is the lobby's first question, GAME.md 9.7.
	for button: Node in title.find_children("*", "Button", true, false):
		assert_str((button as Button).text).is_not_equal("Quick play")
	var lobby: Control = auto_free(load("res://scenes/ui/lobby.tscn").instantiate())
	add_child(lobby)
	lobby.options.bots_option.selected = 1
	lobby.options.difficulty_option.selected = 2
	var config: MatchConfig = lobby.config()
	assert_int(config.bot_count).is_equal(1)
	assert_str(config.difficulty).is_equal("hard")
	var settings: Control = auto_free(SETTINGS_SCENE.instantiate())
	add_child(settings)
	assert_int(settings.tabs.get_tab_count()).is_equal(4)


## GAME.md 3.8: somebody joining a friend's match never passes through the local lobby, so the
## screen they do pass through asks what they are called.
func test_the_online_screen_carries_the_name_you_type() -> void:
	var online: Control = auto_free(load("res://scenes/ui/online.tscn").instantiate())
	add_child(online)
	online.name_field.text = "  [b]Bartholomew Winterbottom[/b]  "
	var config: MatchConfig = online.config("join")
	assert_str(config.online).is_equal("join")
	assert_int(config.human_names.size()).is_equal(1)
	assert_int(config.human_names[0].length()).is_less_equal(PlayerNames.MAX_LENGTH)
	assert_bool(config.human_names[0].contains("[")).is_false()
	assert_str(config.human_names[0]).starts_with("bBartholomew")


## GAME.md 8.1: the title screen has something behind it, turning slowly, and it is behind the
## words rather than over them.
func test_the_title_screen_turns_behind_its_words() -> void:
	var title: Control = auto_free(TITLE_SCENE.instantiate())
	var runner: GdUnitSceneRunner = scene_runner(title)
	await runner.simulate_frames(4, 17)
	var back: TitleBackground = title.get_node("Background")
	assert_object(back).is_not_null()
	# Over the flat color, under the menu: everything a player came here to read is on top.
	assert_int(back.get_index()).is_equal(1)
	assert_int(back.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	var turned := back._spin
	await runner.simulate_frames(20, 17)
	assert_float(back._spin).is_not_equal(turned)


## GAME.md 8.5: on a pad the shoulder buttons step through the settings tabs, round at the ends,
## unless a rebind is listening, when a shoulder button is a binding like any other.
func test_the_shoulder_buttons_step_through_the_settings_tabs() -> void:
	var real := Game.settings
	Game.settings = Settings.new()
	Game.settings.path = TEST_SETTINGS_PATH
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	await await_idle_frame()
	var shoulder := func(button: JoyButton) -> InputEventJoypadButton:
		var press := InputEventJoypadButton.new()
		press.button_index = button
		press.pressed = true
		return press
	assert_int(screen.tabs.current_tab).is_equal(0)
	screen._unhandled_input(shoulder.call(JOY_BUTTON_RIGHT_SHOULDER))
	assert_int(screen.tabs.current_tab).is_equal(1)
	screen._unhandled_input(shoulder.call(JOY_BUTTON_LEFT_SHOULDER))
	screen._unhandled_input(shoulder.call(JOY_BUTTON_LEFT_SHOULDER))
	assert_int(screen.tabs.current_tab).is_equal(screen.tabs.get_tab_count() - 1)
	# Focus left in a tab that has gone goes to the first thing in the one that has come.
	screen.tabs.current_tab = 1
	await await_idle_frame()
	var slider := SettingsScreen._first_focusable(screen.tabs.get_current_tab_control())
	slider.grab_focus()
	screen.switch_tab(1)
	var focus := screen.get_viewport().gui_get_focus_owner()
	assert_object(focus).is_not_null()
	assert_bool(focus.is_visible_in_tree()).is_true()
	# Listening for a binding, a shoulder is what is being bound, and the page stays put.
	screen.tabs.current_tab = 0
	screen._listening_action = InputActions.NITRO
	screen._listening_keyboard = false
	screen._unhandled_input(shoulder.call(JOY_BUTTON_RIGHT_SHOULDER))
	assert_int(screen.tabs.current_tab).is_equal(0)
	InputActions.register_defaults()
	Game.settings = real
	# The glyphs the rebind replaced go at the end of the frame.
	await await_idle_frame()


## GAME.md 8.5: Settings from the pause menu opens over the room, and Back comes back to the menu
## over the same match. It used to change scene, and coming back built a fresh match from the
## lobby's settings, throwing away the one being played.
func test_settings_from_the_pause_menu_come_back_to_the_same_match() -> void:
	var real := Game.settings
	Game.settings = Settings.new()
	Game.settings.path = TEST_SETTINGS_PATH
	Game.pending_config = MatchConfig.new()
	var scene: Node3D = auto_free(MATCH_SCENE.instantiate())
	add_child(scene)
	await assert_signal(scene).is_emitted("loaded")
	var match_node: Match = scene.get_node("Match")
	var kart := match_node.kart_of(0)
	var menu: PauseMenu = scene.get_node("PauseMenu")
	menu.set_paused(true)
	menu.open_settings()
	await await_idle_frame()
	assert_bool(menu.settings_open()).is_true()
	assert_bool(get_tree().paused).is_true()
	# The settings have the controls: the pause button there is not a request to close the menu.
	var pause := InputEventAction.new()
	pause.action = InputActions.PAUSE
	pause.pressed = true
	menu._unhandled_input(pause)
	assert_bool(menu.settings_open()).is_true()
	var screen: SettingsScreen = menu._settings
	screen._back()
	await await_idle_frame()
	assert_bool(menu.settings_open()).is_false()
	assert_bool(menu._panel.visible).is_true()
	assert_object(get_tree().current_scene).is_not_equal(null)
	# The same room and the same match, still paused on the menu it was opened from.
	assert_object(scene.get_node("Match")).is_same(match_node)
	assert_object(match_node.kart_of(0)).is_same(kart)
	assert_bool(get_tree().paused).is_true()
	menu.set_paused(false)
	assert_bool(get_tree().paused).is_false()
	Game.pending_config = null
	Game.settings = real


func test_match_scene_starts_from_the_pending_configuration() -> void:
	var config := MatchConfig.new()
	config.bot_count = 1
	config.difficulty = "easy"
	config.duration = 120.0
	Game.pending_config = config
	var scene: Node3D = auto_free(MATCH_SCENE.instantiate())
	add_child(scene)
	# The room goes up a phase at a time behind a loading screen now, GAME.md 8.6, so the scene
	# says when it is playable rather than being playable the moment it is added.
	await assert_signal(scene).is_emitted("loaded")
	var match_node: Match = scene.get_node("Match")
	assert_int(match_node.slots.size()).is_equal(2)
	assert_float(match_node.rules.duration).is_equal(120.0)
	assert_str(match_node.bot_difficulty.id).is_equal("easy")
	assert_object(scene.get_node("PauseMenu")).is_not_null()
	assert_object(match_node.kart_of(0).get_node_or_null("ControlHint")).is_not_null()
	var hints := 0
	for child: Node in match_node.kart_of(0).get_children():
		if child is ControlHint:
			hints += 1
	assert_int(hints).is_equal(1)
	Game.pending_config = null


func test_a_freed_control_hint_leaves_no_connection_behind() -> void:
	var kart: Kart = auto_free(load("res://scenes/kart/kart.tscn").instantiate())
	add_child(kart)
	var hint := ControlHint.attach(kart, DeviceInput.KEYBOARD)
	assert_bool(kart.fired.is_connected(hint._on_fired)).is_true()
	hint.free()
	assert_int(kart.fired.get_connections().size()).is_equal(0)
	var none: Array[Bullet] = []
	kart.fired.emit(none)


## Seats kept for players connected from elsewhere come after the people at this machine and
## before the bots, and are not counted as bots: the bots are what the host asked for on top.
func test_seats_kept_for_remote_players_sit_between_the_humans_and_the_bots() -> void:
	var config := MatchConfig.new()
	var devices: Array[int] = [DeviceInput.KEYBOARD]
	config.human_devices = devices
	config.network_seats = 2
	config.bot_count = 1
	var inputs := config.inputs()
	assert_int(inputs.size()).is_equal(4)
	assert_bool(inputs[0] is PlayerInput).is_true()
	for i: int in range(1, 4):
		assert_bool(inputs[i] is BotInput).is_true()
	assert_int(config.colors().size()).is_equal(4)


## A kept seat keeps the color its player had in the waiting room, and the bots take what is left.
## A kept color somebody here already has gives way, so no two karts share one.
func test_kept_seats_keep_their_colors_and_the_bots_take_the_rest() -> void:
	var config := MatchConfig.new()
	var devices: Array[int] = [DeviceInput.KEYBOARD]
	var picked: Array[int] = [2]
	var kept: Array[int] = [0, 2]
	config.human_devices = devices
	config.human_colors = picked
	config.network_seats = 2
	config.network_colors = kept
	config.bot_count = 1
	assert_array(config.colors()).contains_exactly([2, 0, 1, 3])


## A client's "Starting the match..." is said before there is any room to stand it over, so it
## stands on the menus' own background instead of on an empty world.
func test_a_status_before_the_room_stands_on_the_menu_background() -> void:
	var holder: Node = auto_free(Node.new())
	add_child(holder)
	var pane := StatusPane.add_to(holder)
	pane.say("Starting the match...")
	assert_bool(pane._backdrop.visible).is_false()
	pane.backdrop = true
	assert_bool(pane._backdrop.visible).is_true()
	assert_object(pane._backdrop.color).is_equal(MenuTheme.BACKGROUND)
	assert_int(pane._backdrop.get_index()).is_less(pane._panel.get_index())
