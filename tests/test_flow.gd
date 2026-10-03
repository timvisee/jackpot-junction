extends GdUnitTestSuite
## Settings persistence, the menu scenes and the match scene built from a lobby configuration.

const TEST_SETTINGS_PATH := "user://test_settings.cfg"
const SETTINGS_SCENE := preload("res://scenes/ui/settings_screen.tscn")
const TITLE_SCENE := preload("res://scenes/ui/title.tscn")
const MATCH_SCENE := preload("res://scenes/match/match_scene.tscn")
const ONLINE_SCENE := preload("res://scenes/ui/online.tscn")
const ROOM_SCENE := preload("res://scenes/match/match.tscn")


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


## GAME.md 8.5: a fresh install starts at half volume, since at full the game came on loud enough
## to reach for.
func test_the_game_starts_at_half_volume() -> void:
	assert_float(Settings.new().master_volume).is_equal(0.5)


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
	# The match is chosen over the lobby room rather than on a screen of its own, GAME.md 9.6.
	var pane: HostSettings = auto_free(HostSettings.add_to(self, true))
	pane.options.bots_option.selected = 1
	pane.options.difficulty_option.selected = 2
	var config := MatchConfig.new()
	pane.options.apply_to(config)
	assert_int(config.bot_count).is_equal(1)
	assert_str(config.difficulty).is_equal("hard")
	var settings: Control = auto_free(SETTINGS_SCENE.instantiate())
	add_child(settings)
	assert_int(settings.tabs.get_tab_count()).is_equal(7)


## GAME.md 3.8: somebody joining a friend's match never passes through the local lobby, so the
## screen they do pass through asks what they are called.
func test_the_online_screen_carries_the_name_you_type() -> void:
	var online: Control = auto_free(ONLINE_SCENE.instantiate())
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
	screen._input(shoulder.call(JOY_BUTTON_RIGHT_SHOULDER))
	assert_int(screen.tabs.current_tab).is_equal(0)
	assert_str(String(screen._listening_action)).is_empty()
	InputActions.register_defaults()
	Game.settings = real
	# The glyphs the rebind replaced go at the end of the frame.
	await await_idle_frame()


## GAME.md 8.5: a mouse button binds like a key, fire on the left button, say. The press is a
## click on the screen, and it has to reach the rebind before the screen's own controls take it.
func test_a_mouse_button_can_be_bound() -> void:
	var real := Game.settings
	Game.settings = Settings.new()
	Game.settings.path = TEST_SETTINGS_PATH
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	await await_idle_frame()
	var row: Array = screen._binding_labels[InputActions.FIRE]
	(row[0] as Button).pressed.emit()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = (row[0] as Button).get_global_rect().get_center()
	click.global_position = click.position
	Input.parse_input_event(click)
	await await_idle_frame()
	await await_idle_frame()
	var bound := false
	for event: InputEvent in InputMap.action_get_events(InputActions.FIRE):
		var mouse := event as InputEventMouseButton
		bound = bound or (mouse != null and mouse.button_index == MOUSE_BUTTON_LEFT)
	var listening := screen._listening_action
	InputActions.register_defaults()
	Game.settings = real
	await await_idle_frame()
	assert_bool(bound).override_failure_message("the left button was never bound").is_true()
	assert_str(String(listening)).is_empty()


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
## stands on the loading screen's dark instead of on an empty world: the same dark the loading
## screen that follows it is, so going to the next map is one dark screen.
func test_a_status_before_the_room_stands_on_the_loading_screens_dark() -> void:
	var holder: Node = auto_free(Node.new())
	add_child(holder)
	var pane := StatusPane.add_to(holder)
	pane.say("Starting the match...")
	assert_bool(pane._backdrop.visible).is_false()
	pane.backdrop = true
	assert_bool(pane._backdrop.visible).is_true()
	assert_object(pane._backdrop.color).is_equal(LoadingScreen.BACKDROP)
	assert_int(pane._backdrop.get_index()).is_less(pane._panel.get_index())


## GAME.md 3.8: a menu over a room darkens the whole of it, the pause menu and the host's match
## settings both. The shade used to be centered along with the pane, at the nothing it asks for.
## A phone's Back, GAME.md 4.2: in a room with nothing up, the room's menu, as the corner button
## opens it; with the menu up, what B does there, closing it; with a pane up over the room, that
## pane goes and the menu stays shut. Never quitting.
func test_a_phones_back_does_what_b_does_or_opens_the_menu() -> void:
	var real := Game.settings
	Game.settings = Settings.new()
	Game.settings.path = TEST_SETTINGS_PATH
	var holder: Control = auto_free(Control.new())
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(holder)
	var menu := PauseMenu.add_to(holder)
	await await_idle_frame()
	Game.go_back()
	assert_bool(menu.is_open()).is_true()
	Game.go_back()
	assert_bool(menu.is_open()).is_false()
	var host := HostSettings.add_to(holder)
	host.open()
	await await_idle_frame()
	Game.go_back()
	assert_bool(host._panel.visible).override_failure_message("the pane stayed").is_false()
	assert_bool(menu.is_open()).override_failure_message("the menu came up too").is_false()
	assert_bool(ProjectSettings.get_setting("application/config/quit_on_go_back")).is_false()
	get_tree().paused = false
	DirAccess.remove_absolute(Game.settings.path)
	Game.settings = real


func test_a_menu_over_the_room_darkens_all_of_it() -> void:
	# Closing the host's pane keeps what it was showing, which is not the player's to have written.
	var real := Game.settings
	Game.settings = Settings.new()
	Game.settings.path = TEST_SETTINGS_PATH
	var holder: Control = auto_free(Control.new())
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(holder)
	var menu := PauseMenu.add_to(holder)
	menu.set_paused(true)
	var host := HostSettings.add_to(holder)
	host.open()
	await await_idle_frame()
	var screen := get_viewport().get_visible_rect().size
	for shade: ColorRect in [menu._panel.get_child(0), host._panel.get_child(0)]:
		assert_vector(shade.size).is_equal(screen)
		assert_float(shade.color.a).is_greater(0.3)
	menu.set_paused(false)
	host.close()
	get_tree().paused = false
	DirAccess.remove_absolute(Game.settings.path)
	Game.settings = real


## GAME.md 10.3: the host's menu has Manage players, which comes up in place of the menu and goes
## again on Back; nobody else's menu has it.
func test_the_hosts_menu_manages_its_players() -> void:
	var holder: Node = auto_free(Node.new())
	add_child(holder)
	var room: Match = auto_free(ROOM_SCENE.instantiate())
	room.with_hud = false
	room.offer_size = 0
	holder.add_child(room)
	room.start([PlayerInput.new(DeviceInput.ANY, 0), BotInput.new()] as Array[KartInput], 3)
	var session: NetSession = auto_free(NetSession.new())
	session.is_host = true
	session.match_node = room
	var menu := PauseMenu.add_to(holder, session)
	await await_idle_frame()
	assert_bool(menu._manage.visible).is_true()
	menu._manage.pressed.emit()
	assert_bool(menu._players.visible).is_true()
	assert_bool(menu._main.visible).is_false()
	# The host itself is on it, marked Me, with nothing to kick; the bot is nobody's to kick.
	var rows := menu._players._rows
	var mine := rows.get_child(0) as HBoxContainer
	assert_str((mine.get_child(0) as Label).text).is_equal(room.slots[0].display_name())
	assert_str((mine.get_child(1) as Label).text).is_equal("Me")
	assert_int(mine.find_children("*", "Button", true, false).size()).is_equal(0)
	assert_int(rows.find_children("*", "Button", true, false).size()).is_equal(0)
	assert_str((rows.get_child(1) as Label).text).is_equal("Nobody else is here.")
	menu._players._back.pressed.emit()
	assert_bool(menu._players.visible).is_false()
	assert_bool(menu._main.visible).is_true()
	session.is_host = false
	await await_idle_frame()
	assert_bool(menu._manage.visible).is_false()


## GAME.md 9.6: a lobby that wants a password asks for it and knocks again with what was typed;
## Back, or B, gives up on it. That it then goes to Play LAN, and a wrong password does too, is
## played through by the multiplayer check, which changes scenes as a test here cannot.
func test_the_password_pane_asks_and_knocks_again() -> void:
	var holder: Node = auto_free(Node.new())
	add_child(holder)
	var pane := PasswordPane.add_to(holder)
	assert_array(_texts(pane)).contains(["This game needs a password."])
	var typed := [""]
	pane.entered.connect(func(password: String) -> void: typed[0] = password)
	pane._box.text = "sesame"
	pane._join.pressed.emit()
	assert_str(typed[0]).is_equal("sesame")
	assert_bool(pane._box.secret).is_true()
	var left := [0]
	pane.left.connect(func() -> void: left[0] += 1)
	pane._back.pressed.emit()
	var back := InputEventAction.new()
	back.action = &"ui_cancel"
	back.pressed = true
	pane._input(back)
	assert_int(left[0]).is_equal(2)


## GAME.md 9.6: Play LAN come back to from a game that turned this machine away says why, once.
func test_play_lan_says_why_it_is_back() -> void:
	Game.online_note = "Wrong password"
	var screen: Control = auto_free(ONLINE_SCENE.instantiate())
	add_child(screen)
	assert_str(screen.status.text).is_equal("Wrong password")
	assert_str(Game.online_note).is_empty()
	var again: Control = auto_free(ONLINE_SCENE.instantiate())
	add_child(again)
	assert_str(again.status.text).is_empty()


## GAME.md 9.6: the host's Lobby settings set how many may play and a password, at once; the
## number is kept for next time and the password is not.
func test_the_hosts_lobby_settings_set_the_door() -> void:
	var real := Game.settings
	Game.settings = Settings.new()
	Game.settings.path = TEST_SETTINGS_PATH
	var holder: Node = auto_free(Node.new())
	add_child(holder)
	var session: NetSession = auto_free(NetSession.new())
	session.is_host = true
	var menu := PauseMenu.add_to(holder, session)
	await await_idle_frame()
	assert_bool(menu._door_button.visible).is_true()
	# Who may come in, then who has: Manage players right under it.
	assert_int(menu._manage.get_index()).is_equal(menu._door_button.get_index() + 1)
	menu._door_button.pressed.emit()
	assert_bool(menu._door.visible).is_true()
	menu._door._players.select(1)
	menu._door._players.item_selected.emit(1)
	assert_int(session.door.max_players).is_equal(3)
	assert_int(Game.settings.lobby_players).is_equal(3)
	menu._door._password.text = " sesame "
	menu._door._password.text_changed.emit(menu._door._password.text)
	assert_str(session.door.password).is_equal("sesame")
	var read := Settings.new()
	read.path = TEST_SETTINGS_PATH
	read.load_from_disk()
	assert_int(read.lobby_players).is_equal(3)
	# Watching: free of the password, then shut altogether, which makes the first moot.
	assert_bool(menu._door._watch_free.disabled).is_false()
	menu._door._watch_free.button_pressed = true
	assert_bool(session.door.watchers_need_password).is_false()
	menu._door._watchers.button_pressed = false
	assert_bool(session.door.watchers_allowed).is_false()
	assert_bool(menu._door._watch_free.disabled).is_true()
	read.load_from_disk()
	assert_bool(read.lobby_watchers).is_false()
	assert_bool(read.lobby_watch_free).is_true()
	menu._door._back.pressed.emit()
	assert_bool(menu._main.visible).is_true()
	Game.settings = real


## GAME.md 3.8: the host's Pause game is straight under Resume, over the match settings the
## waiting room adds, since stopping everybody is the first thing a host reaches for.
func test_pause_game_is_over_the_match_settings() -> void:
	var holder: Node = auto_free(Node.new())
	add_child(holder)
	var menu := PauseMenu.add_to(holder)
	var entry := menu.add_entry("Match settings", func() -> void: pass)
	assert_int(menu._force.get_index()).is_equal(menu._resume.get_index() + 1)
	assert_int(entry.get_index()).is_equal(menu._force.get_index() + 1)


## GAME.md 9.6: on a screen too short for the match settings, a phone's under a big UI scale, the
## rows scroll between the title and Done, which stay on the screen; on a tall one nothing does.
func test_the_match_settings_scroll_on_a_short_screen() -> void:
	var holder: Node = auto_free(Node.new())
	add_child(holder)
	var host := HostSettings.add_to(holder, true)
	host.open()
	await await_idle_frame()
	var rows := host._rows.get_combined_minimum_size().y
	host._panel.size = Vector2(1600.0, 480.0)
	host._fit()
	assert_float(host._scroll.custom_minimum_size.y).is_less(rows)
	var need := host._pane.get_combined_minimum_size().y
	assert_float(need).is_less_equal(480.0 - HostSettings.FIT_EDGE * 2.0)
	assert_vector(host._middle.scale).is_equal(Vector2.ONE)
	host._panel.size = Vector2(1600.0, 2000.0)
	host._fit()
	assert_float(host._scroll.custom_minimum_size.y).is_equal_approx(rows, 0.5)
	host._panel.visible = false


## GAME.md 3.8: a map has a way back to the lobby for whoever decides where the room goes, and it
## asks first, since it ends the map and any Grand Prix it is part of. No, or Back, is the menu.
func test_back_to_lobby_asks_before_ending_the_grand_prix() -> void:
	var holder: Control = auto_free(Control.new())
	add_child(holder)
	var menu := PauseMenu.add_to(holder)
	var lobby := menu.offer_the_lobby()
	assert_int(lobby.get_index()).is_equal(menu._quit.get_index() - 1)
	var was := Game.grand_prix
	Game.grand_prix = GrandPrix.new()
	lobby.pressed.emit()
	assert_bool(menu.asking()).is_true()
	assert_str(menu._confirm.said()).contains("Grand Prix ends here")
	assert_bool(menu._main.visible).is_false()
	var back := InputEventAction.new()
	back.action = &"ui_cancel"
	back.pressed = true
	menu._panel.visible = true
	menu._unhandled_input(back)
	assert_bool(menu.asking()).is_false()
	assert_bool(menu._main.visible).is_true()
	assert_bool(menu._panel.visible).is_true()
	Game.grand_prix = was
	assert_str(PauseMenu.lobby_words(false, false)[1]).is_equal("This match ends here.")
	assert_str(PauseMenu.lobby_words(true, true)[1]).contains("stays connected")


## A session somebody has joined, or has not, without a connection to have them on.
class Joined:
	extends NetSession

	var joined := true

	func anybody_connected() -> bool:
		return joined


## GAME.md 3.8: online, the way back to the title asks first. The host is told everybody who has
## joined goes with it; a client only leaves. Offline nothing is asked: nobody else is there, and
## nor is it of a host nobody has joined yet, to play or to watch.
func test_back_to_title_online_asks_and_says_who_it_disconnects() -> void:
	var holder: Control = auto_free(Control.new())
	add_child(holder)
	var session: Joined = auto_free(Joined.new())
	session.is_host = true
	var menu := PauseMenu.add_to(holder, session)
	assert_bool(PauseMenu.add_to(holder, null).asks_before_leaving()).is_false()
	session.joined = false
	assert_bool(menu.asks_before_leaving()).is_false()
	session.joined = true
	assert_bool(menu.asks_before_leaving()).is_true()
	menu._quit.pressed.emit()
	assert_bool(menu.asking()).is_true()
	assert_str(menu._confirm.said()).contains("will be disconnected")
	menu._confirm.no_button().pressed.emit()
	assert_bool(menu.asking()).is_false()
	session.is_host = false
	menu._quit.pressed.emit()
	assert_str(menu._confirm.said()).contains("You leave the room")
	menu._confirm.no_button().pressed.emit()
	# GAME.md 9.3a: the host's say passes on to somebody still playing, and there is only
	# somebody to pass it to when somebody else is playing.
	assert_str(PauseMenu.leave_words(false, true, 1, 0)[1]).contains("passes on")
	var alone := PauseMenu.leave_words(false, true, 0, 0)[1]
	assert_str(alone).not_contains("passes on")
	assert_str(alone).contains("the game ends")
	var watched := PauseMenu.leave_words(false, true, 0, 2)[1]
	assert_str(watched).not_contains("passes on")
	assert_str(watched).contains("watching")
	# Yes goes ahead with whatever the question was asked before.
	var went := [0]
	var words: Array[String] = ["Sure?", "Really.", "Yes"]
	menu.ask(words, func() -> void: went[0] += 1, menu._quit)
	menu._confirm.yes_button().pressed.emit()
	assert_int(went[0]).is_equal(1)
	assert_bool(menu.asking()).is_false()


## GAME.md 3.8: online, the host can stop the room for everybody from its menu, and a client that
## has no menu open is told why nothing is moving. Closing the host's menu lets go of it.
func test_the_host_can_pause_everybody_and_a_client_is_told() -> void:
	var holder: Control = auto_free(Control.new())
	add_child(holder)
	var session: NetSession = auto_free(NetSession.new())
	session.is_host = true
	# In the tree, for the room it stops to have a multiplayer to ask.
	holder.add_child(session)
	var menu := PauseMenu.add_to(holder, session)
	menu._panel.visible = true
	menu._process(0.0)
	assert_bool(menu._force.visible).is_true()
	assert_object(menu._force.icon).is_null()
	# Pressed, it stops the room and says so with a tick; it stays up while the room stands, and
	# pressed again it lets go.
	menu._force.pressed.emit()
	assert_bool(session.host_controls.forcing).is_true()
	session.paused = true
	menu._process(0.0)
	assert_bool(menu._force.visible).is_true()
	assert_object(menu._force.icon).is_same(MenuTheme.tick())
	assert_bool(menu._force.button_pressed).is_true()
	menu._force.pressed.emit()
	assert_bool(session.host_controls.forcing).is_false()
	menu._process(0.0)
	assert_object(menu._force.icon).is_null()
	var client: NetSession = auto_free(NetSession.new())
	var theirs := PauseMenu.add_to(holder, client)
	client.paused = true
	theirs._process(0.0)
	assert_bool(theirs._held.visible).is_true()
	theirs._panel.visible = true
	theirs._process(0.0)
	assert_bool(theirs._held.visible).is_false()
	get_tree().paused = false


func _texts(node: Node) -> Array[String]:
	var found: Array[String] = []
	var label := node as Label
	if label != null:
		found.append(label.text)
	for child: Node in node.get_children():
		found.append_array(_texts(child))
	return found
