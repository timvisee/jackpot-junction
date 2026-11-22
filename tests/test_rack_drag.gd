extends GdUnitTestSuite
## The kart dialog's rack dragged along by the mouse and by a finger, GAME.md 4.4a: see [PartTray]
## and [TouchScroll].

const PATH := "user://test_rack_drag.cfg"

var _settings_were: Settings
var _holder: Control


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	_holder = Control.new()
	add_child(_holder)


func after_test() -> void:
	if is_instance_valid(_holder):
		remove_child(_holder)
		_holder.free()
	Settings.remove_files(PATH)
	Game.settings = _settings_were


func _open() -> KartDialog:
	var dialog := KartDialog.open(_holder)
	await get_tree().process_frame
	await get_tree().process_frame
	return dialog


## The mouse drags the rack along: held down on it and moved, the rack follows the mouse and the
## pieces it passes over are not tried on; let go, the piece it was pressed on is not worn. A click
## that does not move still wears the piece.
func test_the_mouse_drags_the_rack() -> void:
	var dialog := await _open()
	dialog.open_tray(1)
	await get_tree().process_frame
	await get_tree().process_frame
	var tray := dialog.tray
	var chosen: Array[int] = []
	tray.chosen.connect(func(index: int) -> void: chosen.append(index))
	var cell := tray.cells[4]
	var at := cell.get_global_transform_with_canvas() * (cell.size / 2.0)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = at
	tray._input(press)
	var was := tray._scroll.scroll_horizontal
	for step: int in 4:
		var motion := InputEventMouseMotion.new()
		motion.position = at - Vector2(40.0 * (step + 1), 0.0)
		motion.relative = Vector2(-40.0, 0.0)
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		tray._input(motion)
	assert_int(tray._scroll.scroll_horizontal).is_greater(was)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = at
	tray._input(release)
	cell.pressed.emit()
	assert_array(chosen).is_empty()
	await get_tree().process_frame
	tray._input(press)
	tray._input(release)
	cell.pressed.emit()
	assert_array(chosen).contains_exactly([cell.index])
	dialog.close()


## A finger drags the rack along too: the list only goes across, so a drag scrolls it across.
func test_a_finger_drags_the_rack() -> void:
	var was_touch := TouchInput.enabled
	TouchInput.enabled = true
	var dialog := await _open()
	dialog.open_tray(1)
	await get_tree().process_frame
	await get_tree().process_frame
	var scroll := dialog.tray._scroll
	var finger := scroll.get_node("TouchScroll") as TouchScroll
	var cell := dialog.tray.cells[4]
	var at := cell.get_global_transform_with_canvas() * (cell.size / 2.0)
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = at
	finger._input(touch)
	var was := scroll.scroll_horizontal
	for step: int in 4:
		var drag := InputEventScreenDrag.new()
		drag.position = at - Vector2(40.0 * (step + 1), 0.0)
		drag.relative = Vector2(-40.0, 0.0)
		finger._input(drag)
	assert_int(scroll.scroll_horizontal).is_greater(was)
	touch.pressed = false
	finger._input(touch)
	TouchInput.enabled = was_touch
	dialog.close()
