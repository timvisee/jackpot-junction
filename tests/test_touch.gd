extends GdUnitTestSuite
## Playing on a touch screen, GAME.md 4.2: the controls drawn over the room and answered finger by
## finger.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")
const BOOST: PowerUp = preload("res://data/powerups/boost.tres")

var _was_enabled := false


func before_test() -> void:
	_was_enabled = TouchInput.enabled


func after_test() -> void:
	TouchInput.enabled = _was_enabled
	TouchInput.release()
	Input.emulate_touch_from_mouse = false
	get_tree().paused = false


## The controls on their own, with no match under them: the menu and nothing to drive.
func _controls() -> TouchControls:
	var layer: CanvasLayer = auto_free(CanvasLayer.new())
	var controls := TouchControls.new()
	layer.add_child(controls)
	add_child(layer)
	return controls


## A match with a player at this screen on a touch screen, and the controls the HUD put up for them.
func _driving() -> TouchControls:
	TouchInput.enabled = true
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = true
	match_node.offer_size = 0
	var runner := scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	match_node.start(inputs, 5)
	await runner.simulate_frames(12, 17)
	return match_node.hud.get_node("TouchControls")


func _drag(controls: TouchControls, finger: int, at: Vector2) -> void:
	var drag := InputEventScreenDrag.new()
	drag.index = finger
	drag.position = at
	controls._input(drag)


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


## The pedals and the buttons are held for as long as a finger is on them, and the player at this
## screen reads them with everything else; a player on a pad of their own does not.
func test_the_pedals_and_buttons_drive_the_player_here() -> void:
	var controls := await _driving()
	assert_bool(controls.driving()).is_true()
	var gas := controls.pad(TouchControls.THROTTLE)
	_touch(controls, 0, gas.center, true)
	assert_float(TouchInput.throttle).is_equal(1.0)
	var here := PlayerInput.new()
	here.poll(0.016)
	assert_float(here.throttle).is_equal(1.0)
	var pinned := PlayerInput.new(DeviceInput.KEYBOARD)
	pinned.poll(0.016)
	assert_float(pinned.throttle).is_equal(0.0)
	# A thumb sliding on to fire lets go of the gas and fires.
	_drag(controls, 0, controls.pad(TouchControls.FIRE).center)
	assert_float(TouchInput.throttle).is_equal(0.0)
	assert_bool(TouchInput.fire).is_true()
	here.poll(0.016)
	assert_bool(here.fire_pressed).is_true()
	# And one on the seam between the two presses both.
	var fire := controls.pad(TouchControls.FIRE)
	var seam := gas.center.lerp(fire.center, gas.radius / (gas.radius + fire.radius))
	_drag(controls, 0, seam)
	assert_float(TouchInput.throttle).is_equal(1.0)
	assert_bool(TouchInput.fire).is_true()
	_touch(controls, 0, seam, false)
	assert_float(TouchInput.throttle).is_equal(0.0)
	assert_bool(TouchInput.fire).is_false()
	# A finger that comes down again without having been seen to come up is the one finger, and
	# lets go of whatever it was on first.
	_touch(controls, 3, controls.pad(TouchControls.DRIFT).center, true)
	_touch(controls, 3, controls.pad(TouchControls.BRAKE).center, true)
	assert_float(TouchInput.brake).is_equal(1.0)
	assert_bool(TouchInput.handbrake).is_false()
	_touch(controls, 3, controls.pad(TouchControls.BRAKE).center, false)
	_touch(controls, 4, controls.pad(TouchControls.DRIFT).center, true)
	_touch(controls, 5, controls.pad(TouchControls.NITRO).center, true)
	here.poll(0.016)
	assert_bool(here.handbrake).is_true()
	assert_bool(here.nitro).is_true()


## The stick comes to wherever the left thumb goes down in the lower left and steers by how far it
## is pushed to the side, while the other thumb holds the gas.
func test_the_stick_steers_where_the_thumb_goes_down() -> void:
	var controls := await _driving()
	var down := Vector2(controls.size.x * 0.2, controls.size.y * 0.7)
	_touch(controls, 0, down, true)
	assert_vector(controls._stick_at).is_equal(down)
	assert_float(TouchInput.steer).is_equal(0.0)
	_touch(controls, 1, controls.pad(TouchControls.THROTTLE).center, true)
	_drag(controls, 0, down + Vector2(TouchControls.STICK_RADIUS * 0.5, 40.0))
	assert_float(TouchInput.steer).is_between(0.3, 0.6)
	_drag(controls, 0, down + Vector2(-TouchControls.STICK_RADIUS * 3.0, 0.0))
	assert_float(TouchInput.steer).is_equal(-1.0)
	var here := PlayerInput.new()
	here.poll(0.016)
	assert_float(here.steer).is_equal(-1.0)
	assert_float(here.throttle).is_equal(1.0)
	_touch(controls, 0, down, false)
	assert_float(TouchInput.steer).is_equal(0.0)
	assert_float(TouchInput.throttle).is_equal(1.0)
	assert_vector(controls._stick_at).is_equal(controls.stick_home())
	# The top of the screen is the corner of the HUD, not the stick's.
	_touch(controls, 2, Vector2(controls.size.x * 0.2, controls.size.y * 0.2), true)
	assert_int(controls._stick_finger).is_equal(-1)


## Over the podium there is nothing to drive, and the buttons go rather than sit over its own.
func test_the_driving_buttons_go_when_the_match_is_over() -> void:
	var controls := await _driving()
	controls.match_node.state = Match.State.RESULTS
	assert_bool(controls.driving()).is_false()
	_touch(controls, 0, controls.pad(TouchControls.THROTTLE).center, true)
	assert_float(TouchInput.throttle).is_equal(0.0)


## The item button is always there and faint with nothing to play; with an item in hand, and the
## box it came in open, it plays it.
func test_the_item_button_plays_what_is_in_hand() -> void:
	var controls := await _driving()
	var kart := controls.match_node.kart_of(0)
	kart.held_item = null
	assert_bool(controls.has_item()).is_false()
	kart.held_item = BOOST
	kart.item_reveal_left = 0.5
	assert_bool(controls.has_item()).is_false()
	kart.item_reveal_left = 0.0
	assert_bool(controls.has_item()).is_true()
	var here := PlayerInput.new()
	_touch(controls, 0, controls.pad(TouchControls.ITEM).center, true)
	here.poll(0.016)
	assert_bool(here.use_item_pressed).is_true()
	here.poll(0.016)
	assert_bool(here.use_item_pressed).is_false()
	_touch(controls, 0, controls.pad(TouchControls.ITEM).center, false)
	assert_bool(TouchInput.use_item).is_false()
