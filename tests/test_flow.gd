extends GdUnitTestSuite
## Settings persistence, the menu scenes and the match scene built from a lobby configuration.

const TEST_SETTINGS_PATH := "user://test_settings.cfg"


func after_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS_PATH))


func test_settings_round_trip_through_disk() -> void:
	var saved := Settings.new()
	saved.path = TEST_SETTINGS_PATH
	saved.music_volume = 0.25
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
	assert_str(InputActions.binding_text(InputActions.FIRE, false)).is_equal("RB")
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


func test_menu_scenes_build() -> void:
	var title: Control = auto_free(load("res://scenes/ui/title.tscn").instantiate())
	add_child(title)
	assert_object(title.play_button).is_not_null()
	var lobby: Control = auto_free(load("res://scenes/ui/lobby.tscn").instantiate())
	add_child(lobby)
	lobby.bots_option.selected = 1
	lobby.difficulty_option.selected = 2
	var config: MatchConfig = lobby.config()
	assert_int(config.bot_count).is_equal(1)
	assert_str(config.difficulty).is_equal("hard")
	var settings: Control = auto_free(load("res://scenes/ui/settings_screen.tscn").instantiate())
	add_child(settings)
	assert_int(settings.tabs.get_tab_count()).is_equal(4)


func test_match_scene_starts_from_the_pending_configuration() -> void:
	var config := MatchConfig.new()
	config.bot_count = 1
	config.difficulty = "easy"
	config.duration = 120.0
	Game.pending_config = config
	var scene: Node3D = auto_free(load("res://scenes/match/match_scene.tscn").instantiate())
	add_child(scene)
	var match_node: Match = scene.get_node("Match")
	assert_int(match_node.slots.size()).is_equal(2)
	assert_float(match_node.rules.duration).is_equal(120.0)
	assert_str(match_node.bot_difficulty.id).is_equal("easy")
	assert_object(scene.get_node("PauseMenu")).is_not_null()
	assert_object(match_node.kart_of(0).get_node_or_null("ControlHint")).is_null()
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
