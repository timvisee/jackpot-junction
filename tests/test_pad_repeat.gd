extends GdUnitTestSuite
## A pad held over a way walks the cursor on, GAME.md 4.2: nothing more for a moment after the push
## the engine walks on itself, then a step every so often for as long as it is held, the way last
## pushed only, and nothing at all while no control has the cursor.

const RIGHT: Array[StringName] = [&"ui_right"]
const RIGHT_DOWN: Array[StringName] = [&"ui_right", &"ui_down"]
const NONE: Array[StringName] = []

var _grid: GridContainer
var _repeat: PadRepeat


func before_test() -> void:
	_grid = auto_free(GridContainer.new())
	_grid.columns = 6
	for i: int in 18:
		var button := Button.new()
		button.custom_minimum_size = Vector2(40.0, 40.0)
		_grid.add_child(button)
	add_child(_grid)
	_repeat = auto_free(PadRepeat.new())
	_repeat.set_process(false)
	add_child(_repeat)
	await get_tree().process_frame


## The column and row of the button with the cursor.
func _at() -> Vector2i:
	var focus := get_viewport().gui_get_focus_owner()
	var index := focus.get_index() if focus != null and focus.get_parent() == _grid else -1
	return Vector2i(index % _grid.columns, index / _grid.columns)


func test_a_way_held_goes_on_after_a_moment() -> void:
	(_grid.get_child(0) as Button).grab_focus()
	_repeat.hold(0, RIGHT, PadRepeat.DELAY * 0.9)
	assert_that(_at()).is_equal(Vector2i(0, 0))
	_repeat.hold(0, RIGHT, PadRepeat.DELAY * 0.1 + 0.001)
	assert_that(_at()).is_equal(Vector2i(1, 0))
	_repeat.hold(0, RIGHT, PadRepeat.EVERY * 0.5)
	assert_that(_at()).is_equal(Vector2i(1, 0))
	_repeat.hold(0, RIGHT, PadRepeat.EVERY * 0.5 + 0.001)
	assert_that(_at()).is_equal(Vector2i(2, 0))
	# However long a frame took, it steps once.
	_repeat.hold(0, RIGHT, 1.0)
	assert_that(_at()).is_equal(Vector2i(3, 0))
	# Let go and pushed again, it waits the moment over.
	_repeat.hold(0, NONE, 0.02)
	_repeat.hold(0, RIGHT, PadRepeat.DELAY * 0.9)
	assert_that(_at()).is_equal(Vector2i(3, 0))


## A second way pushed while the first is held is the one that goes on, after its own moment; let
## go, the first does not take up again though it is still held, as with keys.
func test_the_way_pushed_last_goes_on() -> void:
	(_grid.get_child(0) as Button).grab_focus()
	_repeat.hold(0, RIGHT, PadRepeat.DELAY + 0.001)
	assert_that(_at()).is_equal(Vector2i(1, 0))
	_repeat.hold(0, RIGHT_DOWN, PadRepeat.DELAY * 0.9)
	assert_that(_at()).is_equal(Vector2i(1, 0))
	_repeat.hold(0, RIGHT_DOWN, PadRepeat.DELAY * 0.1 + 0.001)
	assert_that(_at()).is_equal(Vector2i(1, 1))
	_repeat.hold(0, RIGHT, 1.0)
	_repeat.hold(0, RIGHT, 1.0)
	assert_that(_at()).is_equal(Vector2i(1, 1))


## Each pad holds its own way, and one letting go does not stop the other.
func test_each_pad_holds_its_own() -> void:
	(_grid.get_child(0) as Button).grab_focus()
	_repeat.hold(0, RIGHT, PadRepeat.DELAY * 0.5)
	_repeat.hold(1, RIGHT, PadRepeat.DELAY * 0.5)
	_repeat.hold(0, NONE, PadRepeat.DELAY * 0.5)
	assert_that(_at()).is_equal(Vector2i(0, 0))
	_repeat.hold(1, RIGHT, PadRepeat.DELAY * 0.5 + 0.001)
	assert_that(_at()).is_equal(Vector2i(1, 0))


## The way goes on as the pad's: an event of the way's action, pressed, with the pad's id.
func test_a_step_is_the_pad_pushing_the_way() -> void:
	var heard: Array[InputEvent] = []
	var button := _grid.get_child(0) as Button
	button.focus_neighbor_right = button.get_path()
	button.gui_input.connect(heard.append)
	button.grab_focus()
	_repeat.hold(3, RIGHT, PadRepeat.DELAY + 0.001)
	assert_int(heard.size()).is_equal(1)
	var step := heard[0] as InputEventAction
	assert_object(step).is_not_null()
	assert_str(String(step.action)).is_equal("ui_right")
	assert_bool(step.pressed).is_true()
	assert_int(step.device).is_equal(3)


## With nothing to walk, a match being driven say, nothing goes.
func test_nothing_goes_without_a_cursor() -> void:
	var heard: Array[InputEvent] = []
	var button := _grid.get_child(0) as Button
	button.gui_input.connect(heard.append)
	button.grab_focus()
	button.release_focus()
	_repeat.hold(0, RIGHT, PadRepeat.DELAY + 0.001)
	_repeat.hold(0, RIGHT, 1.0)
	assert_that(get_viewport().gui_get_focus_owner()).is_null()
	assert_int(heard.size()).is_equal(0)
