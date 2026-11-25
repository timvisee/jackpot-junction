extends GdUnitTestSuite
## A pad's right stick scrolling the pane the cursor is in, GAME.md 4.2, see [StickScroll]: the one
## it is in, or with the cursor on what does not scroll the biggest that does on its screen; not
## while a view that takes the stick is up, nor a pane that scrolls with it by itself, nor while a
## kart of this machine's is driven under the menus; and nothing without the cursor.

## How tall the pane shows and how many rows are in it, each how tall.
const SHOWN := Vector2(400.0, 300.0)
const ROWS := 30
const ROW_TALL := 50.0

var _layer: CanvasLayer
var _stick: StickScroll
var _scroll: ScrollContainer
var _beside: Button


func before_test() -> void:
	_layer = CanvasLayer.new()
	add_child(_layer)
	var screen := VBoxContainer.new()
	_layer.add_child(screen)
	_beside = Button.new()
	_beside.text = "Tab"
	screen.add_child(_beside)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = SHOWN
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	screen.add_child(_scroll)
	var rows := VBoxContainer.new()
	_scroll.add_child(rows)
	for i: int in ROWS:
		var row := Button.new()
		row.name = "Row%d" % i
		row.custom_minimum_size = Vector2(200.0, ROW_TALL)
		rows.add_child(row)
	_stick = StickScroll.new()
	add_child(_stick)
	# No pad's stick of its own: the tests push it.
	_stick.set_process(false)
	await get_tree().process_frame
	await get_tree().process_frame


func after_test() -> void:
	get_viewport().gui_release_focus()
	_stick.free()
	_layer.free()


## The first row given the cursor, and the stick pushed [param push] for [param seconds]: where the
## pane is scrolled to then.
func _pushed(push: float, seconds := 0.1) -> int:
	_stick.scroll_with(push, seconds)
	return _scroll.scroll_vertical


func test_the_stick_scrolls_the_pane_with_the_cursor() -> void:
	(_scroll.find_child("Row0", true, false) as Button).grab_focus()
	# All the way down for a tenth of a second, then halfway up for as long: slower.
	assert_int(_pushed(1.0)).is_equal(roundi(StickScroll.RATE * 0.1))
	var halfway := (0.5 - StickScroll.REST) / (1.0 - StickScroll.REST)
	var back := roundi(halfway * halfway * StickScroll.RATE * 0.1)
	assert_int(_pushed(-0.5)).is_equal(roundi(StickScroll.RATE * 0.1) - back)
	# Resting, it stays.
	var was := _scroll.scroll_vertical
	assert_int(_pushed(StickScroll.REST * 0.5)).is_equal(was)


## With the cursor on a tab over the page, the page scrolls all the same: the biggest pane that
## scrolls on its screen.
func test_the_cursor_beside_the_pane_scrolls_its_screens() -> void:
	_beside.grab_focus()
	assert_object(_stick.pane()).is_same(_scroll)
	assert_int(_pushed(1.0)).is_greater(0)


func test_nothing_scrolls_without_the_cursor() -> void:
	get_viewport().gui_release_focus()
	assert_object(_stick.pane()).is_null()
	assert_int(_pushed(1.0)).is_equal(0)


## A view up that takes the right stick itself, the kart dialog say, leaves it to that; a pane that
## scrolls with it by itself, the payout slip, is left to itself.
func test_not_where_the_stick_is_something_elses() -> void:
	_beside.grab_focus()
	var view: Control = auto_free(Control.new())
	add_child(view)
	StickScroll.leave_to(view)
	assert_int(_pushed(1.0)).is_equal(0)
	view.hide()
	assert_int(_pushed(1.0)).is_greater(0)
	_scroll.add_to_group(StickScroll.OWN)
	var was := _scroll.scroll_vertical
	assert_int(_pushed(1.0)).is_equal(was)


## A kart of this machine's driven under the menus aims with the stick and opens the emote wheel;
## one a menu holds still, as the lobby's are, leaves it to the pane.
func test_not_while_a_kart_here_is_driven() -> void:
	_beside.grab_focus()
	var script := GDScript.new()
	script.source_code = "extends Node\nvar input: Object\nvar held := false\n"
	script.reload()
	var kart: Node = auto_free(Node.new())
	kart.set_script(script)
	kart.set(&"input", PlayerInput.new())
	kart.add_to_group(&"karts")
	add_child(kart)
	assert_int(_pushed(1.0)).is_equal(0)
	kart.set(&"held", true)
	assert_int(_pushed(1.0)).is_greater(0)
	# A bot's kart drives with no stick at all.
	kart.set(&"held", false)
	kart.set(&"input", KartInput.new())
	var was := _scroll.scroll_vertical
	assert_int(_pushed(1.0)).is_greater(was)
