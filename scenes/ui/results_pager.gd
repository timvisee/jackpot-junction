class_name ResultsPager
extends VBoxContainer
## The pages of the payout slip, GAME.md 3.8 and 9.7, stood upright beside it: an arrow up and an
## arrow down, drawn rather than lettered, with a dot for each page between them and the page in
## view lit in gold. An arrow with no page that way is out of sight, keeping its room so the dots
## stay where they are. The arrows are the mouse's and a finger's and never take the cursor, which
## stays on the ways on under the slip: on a pad the shoulders turn the pages, the left back and the
## right on, as they turn the tabs of the settings, and on the keys Page Up and Page Down, hung on
## the arrows while keys or a pad are in hand, see [ButtonBinds].

const ARROW := Vector2(64.0, 52.0)
## The arrowhead drawn on each arrow's button, wide and tall.
const HEAD := Vector2(20.0, 12.0)
const DOT := 10.0
const DOT_GAP := 10.0
const FAINT := Color(1.0, 1.0, 1.0, 0.25)
const INK := Color(0.88, 0.88, 0.92)
## The shoulders and the keys that turn the pages back and on.
const BACK_BUTTON := JOY_BUTTON_LEFT_SHOULDER
const ON_BUTTON := JOY_BUTTON_RIGHT_SHOULDER
const BACK_KEY := KEY_PAGEUP
const ON_KEY := KEY_PAGEDOWN

## Back a page, and on a page.
var back: Button
var on: Button
var page := 0
var pages := 2
var _dots: Control
## What the binds on the arrows were last drawn for: none, the keys or a pad.
var _binds_for := -1


static func create() -> ResultsPager:
	var pager := ResultsPager.new()
	pager.name = "Pager"
	pager.alignment = BoxContainer.ALIGNMENT_CENTER
	pager.add_theme_constant_override("separation", roundi(12.0 + ButtonBinds.ROOM))
	pager.back = pager._arrow(-1.0)
	pager.back.name = "Back"
	ButtonBinds.mark(pager.back, &"", BACK_KEY, BACK_BUTTON)
	pager.add_child(pager.back)
	pager._dots = Control.new()
	pager._dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pager._dots.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pager._dots.draw.connect(pager._draw_dots)
	pager.add_child(pager._dots)
	pager.on = pager._arrow(1.0)
	pager.on.name = "On"
	ButtonBinds.mark(pager.on, &"", ON_KEY, ON_BUTTON)
	pager.add_child(pager.on)
	pager.show_page(0, 2)
	return pager


## A press of a shoulder or a key that turns the page, the way the arrow on its side does. Returns
## whether it did, which it does not with no page that way or while the pager is not up.
func turn(event: InputEvent) -> bool:
	if not is_visible_in_tree() or not event.is_pressed():
		return false
	var arrow: Button = null
	var pad := event as InputEventJoypadButton
	var key := event as InputEventKey
	if pad != null:
		arrow = back if pad.button_index == BACK_BUTTON else arrow
		arrow = on if pad.button_index == ON_BUTTON else arrow
	elif key != null:
		var pressed := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
		arrow = back if pressed == BACK_KEY else arrow
		arrow = on if pressed == ON_KEY else arrow
	if arrow == null or arrow.disabled:
		return false
	arrow.pressed.emit()
	return true


func _process(_delta: float) -> void:
	var wanted := 0 if Game.last_input_pointer else (1 if Game.last_input_keyboard else 2)
	if wanted != _binds_for:
		_binds_for = wanted
		ButtonBinds.show([back, on], Game.last_input_keyboard, wanted != 0)


## On [param shown] of [param count], with an arrow only where there is a page that way.
func show_page(shown: int, count: int) -> void:
	page = shown
	pages = count
	_dots.custom_minimum_size = Vector2(DOT, count * DOT + maxi(count - 1, 0) * DOT_GAP)
	ButtonBinds.show_arrow(back, shown > 0)
	ButtonBinds.show_arrow(on, shown < count - 1)
	_binds_for = -1
	back.queue_redraw()
	on.queue_redraw()
	_dots.queue_redraw()


## A button with an arrowhead on it pointing [param way], -1 for up and 1 for down. Drawn rather
## than typed, the way [RankArrow] is, so it does not depend on the font having an arrow in it.
func _arrow(way: float) -> Button:
	var arrow := MenuTheme.button("")
	arrow.custom_minimum_size = ARROW
	arrow.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	arrow.focus_mode = Control.FOCUS_NONE
	arrow.draw.connect(_draw_head.bind(arrow, way))
	return arrow


func _draw_head(arrow: Button, way: float) -> void:
	var middle := arrow.size * 0.5
	var tip := middle + Vector2(0.0, HEAD.y * 0.5 * way)
	var tail := middle.y - HEAD.y * 0.5 * way
	var points := PackedVector2Array(
		[tip, Vector2(middle.x - HEAD.x * 0.5, tail), Vector2(middle.x + HEAD.x * 0.5, tail)]
	)
	var ink := Color.WHITE if arrow.is_hovered() else INK
	arrow.draw_colored_polygon(points, ink)


func _draw_dots() -> void:
	var x := _dots.size.x * 0.5
	for i: int in pages:
		var y := DOT * 0.5 + i * (DOT + DOT_GAP)
		_dots.draw_circle(Vector2(x, y), DOT * 0.5, Palette.CHIP_GOLD if i == page else FAINT)
