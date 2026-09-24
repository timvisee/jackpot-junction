extends GdUnitTestSuite
## Playing on a touch screen, GAME.md 4.2: the controls drawn over the room and answered finger by
## finger.

var _was_enabled := false


func before_test() -> void:
	_was_enabled = TouchInput.enabled


func after_test() -> void:
	TouchInput.enabled = _was_enabled
	Input.emulate_touch_from_mouse = false
	get_tree().paused = false


func _controls() -> TouchControls:
	var layer: CanvasLayer = auto_free(CanvasLayer.new())
	add_child(layer)
	return TouchControls.attach(layer)


func _touch(controls: TouchControls, finger: int, at: Vector2, down: bool) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = finger
	touch.position = at
	touch.pressed = down
	controls._input(touch)


## Off on a desktop unless asked for, and asked for either way on the command line.
func test_touch_is_for_phones_unless_asked_for() -> void:
	TouchInput.detect(PackedStringArray())
	assert_bool(TouchInput.enabled).is_equal(OS.has_feature("mobile"))
	TouchInput.detect(PackedStringArray(["--touch=1"]))
	assert_bool(TouchInput.enabled).is_true()
	TouchInput.detect(PackedStringArray(["--touch=0"]))
	assert_bool(TouchInput.enabled).is_false()


## The menu button is the way to the room's menu for a player with no Escape key: it opens as the
## finger comes up on it, and not if the finger slid off it first.
func test_the_menu_button_opens_the_rooms_menu() -> void:
	var room: Node = auto_free(Node.new())
	add_child(room)
	var menu := PauseMenu.add_to(room)
	var controls := _controls()
	await await_idle_frame()
	var button := controls.pad(TouchControls.MENU)
	assert_float(button.center.x).is_greater(controls.size.x * 0.5)
	assert_float(button.center.y).is_less(controls.size.y * 0.5)
	_touch(controls, 0, button.center, true)
	assert_int(button.held).is_equal(1)
	assert_bool(menu.is_open()).is_false()
	_touch(controls, 0, button.center, false)
	assert_bool(menu.is_open()).is_true()
	assert_int(button.held).is_equal(0)
	menu.set_paused(false)
	_touch(controls, 1, button.center, true)
	_touch(controls, 1, button.center + Vector2(-300.0, 300.0), false)
	assert_bool(menu.is_open()).is_false()
	# And nothing under the menu is pressed while it is up.
	menu.set_paused(true)
	_touch(controls, 2, button.center, true)
	assert_int(button.held).is_equal(0)
