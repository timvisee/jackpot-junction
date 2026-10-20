extends GdUnitTestSuite
## The lobby's ways to the match settings, GAME.md 9.6: a key of their own, E or a pad's View, drawn
## in front of the plan on the board, and a touch screen's button beside its menu button.

const WAITING_SCENE := preload("res://scenes/waiting/waiting_room.tscn")

var _runner: GdUnitSceneRunner
## The player's own settings, put aside while a test that saves them runs on a scratch copy.
var _settings_were: Settings


func before_test() -> void:
	Game.pending_config = MatchConfig.new()
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_lobby_keys.cfg"


func after_test() -> void:
	Game.pending_config = null
	get_tree().paused = false
	Net.close()
	if _settings_were != null:
		Settings.remove_files(Game.settings.path)
		Game.settings = _settings_were
		_settings_were = null


## A room on one machine, past its loading screen, with the way out of it unhooked and the match
## settings it opens with put away.
func _open() -> Node3D:
	var room: Node3D = auto_free(WAITING_SCENE.instantiate())
	_runner = scene_runner(room)
	await _runner.simulate_frames(45, 17)
	if room.ready_room.everybody_ready.is_connected(room._begin):
		room.ready_room.everybody_ready.disconnect(room._begin)
	if room.host_settings != null:
		room.host_settings.close()
	return room


## The match settings have a key of their own in the room, GAME.md 9.6, E or a pad's View, said
## under the plan on the board, besides the pause menu's entry; it does nothing while a menu is up.
func test_the_match_settings_have_a_key_in_the_room() -> void:
	var room := await _open()
	assert_bool(room.host_settings.is_open()).is_false()
	var board: Control = room.ready_room._settings_key
	assert_object(board).is_not_null()
	# In front of the plan, on its line: "[E] Next: ...".
	var plan: Label = room.ready_room._plan
	assert_object(board.get_parent()).is_same(plan.get_parent())
	assert_int(board.get_index()).is_less(plan.get_index())
	await _runner.simulate_frames(2, 17)
	assert_int(board.get_child_count()).is_greater(0)
	for event: InputEvent in [_key_e(), _view()]:
		room._input(event)
		assert_bool(room.host_settings.is_open()).is_true()
		room.host_settings.close()
	var menu: PauseMenu = room.get_node("PauseMenu")
	menu.set_paused(true)
	room._input(_key_e())
	assert_bool(room.host_settings.is_open()).is_false()
	menu.set_paused(false)


## A touch screen has a round button for them beside the menu button instead, and the emote
## button stands on past it.
func test_a_touch_screen_has_a_button_for_the_match_settings() -> void:
	var room := await _open()
	var hud: MatchHud = room.match_node.hud
	var button := TouchSettings.attach(hud, room.choose)
	var emotes := TouchEmotes.attach(hud)
	await _runner.simulate_frames(2, 17)
	assert_float(emotes.button_center().x).is_less(button.button_center().x)
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	tap.position = button.get_global_transform_with_canvas() * button.button_center()
	button._input(tap)
	assert_bool(room.host_settings.is_open()).is_true()
	room.host_settings.close()


func _key_e() -> InputEventKey:
	var key := InputEventKey.new()
	key.physical_keycode = KEY_E
	key.keycode = KEY_E
	key.pressed = true
	return key


func _view() -> InputEventJoypadButton:
	var push := InputEventJoypadButton.new()
	push.button_index = JOY_BUTTON_BACK
	push.pressed = true
	return push
