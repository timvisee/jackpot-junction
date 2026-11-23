extends GdUnitTestSuite
## The game's actions as Steam Input knows them, GAME.md 10.8: every action of the game's there for
## a player to bind in Steam, the files Steam reads as `make steam-input` writes them, and each
## layout binding a controller as the game's own pad is bound.

## The game's actions Steam is not told of: the dialogs' second arrows, WASD, and the four ways to
## aim, which are the aim stick.
const LEFT_OUT: Array[StringName] = [
	InputActions.MENU_UP,
	InputActions.MENU_DOWN,
	InputActions.MENU_LEFT,
	InputActions.MENU_RIGHT,
	InputActions.AIM_LEFT,
	InputActions.AIM_RIGHT,
	InputActions.AIM_UP,
	InputActions.AIM_DOWN,
]


func test_steam_knows_every_action_of_the_games() -> void:
	var known := SteamActions.actions()
	for table: Dictionary[StringName, Array] in [InputActions.DEFAULTS, InputActions.MENU]:
		for action: StringName in table:
			if action not in LEFT_OUT:
				assert_array(known).contains([action])
	for action: StringName in SteamActions.MENU_PAD:
		assert_array(known).contains([action])
	# And nothing the game does not have.
	for action: StringName in SteamActions.BUTTONS:
		assert_bool(InputMap.has_action(action)).override_failure_message(action).is_true()


func test_the_files_steam_reads_are_written_from_here() -> void:
	var files := SteamActions.files()
	for name: String in files:
		var path := SteamActions.FOLDER.path_join(name)
		var kept := FileAccess.get_file_as_string(path)
		assert_str(kept).override_failure_message("%s is old: make steam-input" % path).is_equal(
			files[name]
		)
	# None kept that is no longer written.
	for name: String in DirAccess.get_files_at(SteamActions.FOLDER):
		if name.ends_with(".vdf"):
			assert_bool(files.has(name)).override_failure_message(name).is_true()


func test_the_manifest_names_every_action_and_its_words() -> void:
	var manifest := SteamActions.manifest()
	for action: StringName in SteamActions.BUTTONS:
		assert_str(manifest).contains('"%s"\t\t"#Action_%s"' % [action, action])
		assert_str(manifest).contains(
			'"Action_%s"\t\t"%s"' % [action, SteamActions.BUTTONS[action]]
		)
	for controller: String in SteamActions.CONTROLLERS:
		assert_str(manifest).contains('"path"\t\t"%s.vdf"' % controller)


func test_a_layout_binds_a_controller_as_the_games_own_pad() -> void:
	var xbox := SteamActions.layout("controller_xboxone")
	assert_str(xbox).contains('"controller_type"\t\t"controller_xboxone"')
	# A at once fires, drops a joker and presses the menu's button, as the pad's own A does.
	var a := xbox.substr(xbox.find('"button_a"'), 400)
	for action: String in ["fire", "joker_drop", "ui_accept"]:
		assert_str(a).contains("game_action Play %s," % action)
	assert_str(xbox).contains('"Play"\t\t"steer_stick"')
	assert_str(xbox).contains('"Play"\t\t"aim_stick"')
	assert_str(xbox).contains('"Play"\t\t"throttle_trigger"')
	assert_str(xbox).contains('"right_joystick active"')
	# The first Steam Controller's trackpads stand in for the right stick and the D-pad.
	var gordon := SteamActions.layout("controller_steamcontroller_gordon")
	assert_str(gordon).contains('"right_trackpad active"')
	assert_str(gordon).contains('"left_trackpad active"')
	assert_str(gordon).not_contains('"right_joystick active"')


func test_every_binding_is_an_action_of_the_sets() -> void:
	var known: Array[String] = []
	for action: StringName in SteamActions.BUTTONS:
		known.append(String(action))
	for controller: String in SteamActions.CONTROLLERS:
		for line: String in SteamActions.layout(controller).split("\n"):
			var at := line.find("game_action Play ")
			if at >= 0:
				var action := line.substr(at + 17).get_slice(",", 0)
				assert_array(known).contains([action])
