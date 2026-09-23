extends GdUnitTestSuite
## Settings persistence, the menu scenes and the match scene built from a lobby configuration.

const TEST_SETTINGS_PATH := "user://test_settings.cfg"
const SETTINGS_SCENE := preload("res://scenes/ui/settings_screen.tscn")
const TITLE_SCENE := preload("res://scenes/ui/title.tscn")


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
	# Over the flat colour, under the menu: everything a player came here to read is on top.
	assert_int(back.get_index()).is_equal(1)
	assert_int(back.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	var turned := back._spin
	await runner.simulate_frames(20, 17)
	assert_float(back._spin).is_not_equal(turned)


func test_match_scene_starts_from_the_pending_configuration() -> void:
	var config := MatchConfig.new()
	config.bot_count = 1
	config.difficulty = "easy"
	config.duration = 120.0
	Game.pending_config = config
	var scene: Node3D = auto_free(load("res://scenes/match/match_scene.tscn").instantiate())
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


## A kept seat keeps the colour its player had in the waiting room, and the bots take what is left.
## A kept colour somebody here already has gives way, so no two karts share one.
func test_kept_seats_keep_their_colours_and_the_bots_take_the_rest() -> void:
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
