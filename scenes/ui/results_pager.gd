class_name ResultsPager
extends VBoxContainer
## The pages of the payout slip, GAME.md 3.8 and 9.7, stood upright over the bill's left edge:
## an arrow up and an arrow down in foil, drawn rather than lettered, and between them a dot for
## each page on a pill of the house's dark, the page in view lit in gold. An arrow with no page that
## way is out of sight, keeping its room so the dots stay where they are. The cursor starts on the
## arrow down while there is a page under the one in view, see [ResultsScreen], so a press goes on
## down the bill. Up and down turn the pages too, on the keys, a pad's stick or its cross, and so do
## the shoulders and Page Up and Page Down; their binds hang on the arrows while keys or a pad are
## in hand, see [ButtonBinds].

const ARROW := Vector2(62.0, 62.0)
## The arrowhead drawn on each arrow's button, wide and tall.
const HEAD := Vector2(24.0, 14.0)
const DOT := 10.0
const DOT_GAP := 10.0
## The pill the dots are on, and how far it reaches past them.
const PILL := Color(HouseTheme.STOCK, 0.92)
const PILL_EDGE := Color(HouseTheme.FOIL, 0.45)
const PILL_ROOM := Vector2(9.0, 9.0)
const FAINT := Color(1.0, 1.0, 1.0, 0.3)
## The shoulders and the keys that turn the pages back and on, besides up and down.
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
	pager.add_theme_constant_override("separation", roundi(10.0 + ButtonBinds.ROOM))
	pager.back = pager._arrow(-1.0)
	pager.back.name = "Back"
	ButtonBinds.mark(pager.back, &"ui_up")
	pager.add_child(pager.back)
	pager._dots = Control.new()
	pager._dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pager._dots.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pager._dots.draw.connect(pager._draw_dots)
	pager.add_child(pager._dots)
	pager.on = pager._arrow(1.0)
	pager.on.name = "On"
	ButtonBinds.mark(pager.on, &"ui_down")
	pager.add_child(pager.on)
	pager.show_page(0, 2)
	return pager


## A press of a shoulder or Page Up or Page Down, which turns the page the way the arrow on its side
## does. Returns whether it did, which it does not with no page that way or while the pager is not
## up.
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
	_dots.custom_minimum_size = (
		Vector2(DOT, count * DOT + maxi(count - 1, 0) * DOT_GAP) + PILL_ROOM * 2.0
	)
	show_arrows(shown > 0, shown < count - 1)
	_dots.queue_redraw()


## The arrows up where [param back_there] and [param on_there] say there is somewhere that way, and
## out of sight but keeping their room where there is not.
func show_arrows(back_there: bool, on_there: bool) -> void:
	for arrow: Button in [back, on]:
		var there := back_there if arrow == back else on_there
		ButtonBinds.show_arrow(arrow, there)
		arrow.focus_mode = Control.FOCUS_ALL if there else Control.FOCUS_NONE
	_binds_for = -1
	back.queue_redraw()
	on.queue_redraw()


## A ticket in foil with an arrowhead on it pointing [param way], -1 for up and 1 for down. Drawn
## rather than typed, the way [RankArrow] is, so it does not depend on the font having an arrow in
## it.
func _arrow(way: float) -> Button:
	var arrow := MenuTheme.button("")
	arrow.theme_type_variation = HouseTheme.PRIMARY
	arrow.custom_minimum_size = ARROW
	arrow.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	arrow.draw.connect(_draw_head.bind(arrow, way))
	arrow.focus_entered.connect(arrow.queue_redraw)
	arrow.focus_exited.connect(arrow.queue_redraw)
	return arrow


## The head in the button's own ink, the dark of a foil ticket's words.
func _draw_head(arrow: Button, way: float) -> void:
	var middle := arrow.size * 0.5
	var tip := middle + Vector2(0.0, HEAD.y * 0.5 * way)
	var tail := middle.y - HEAD.y * 0.5 * way
	var points := PackedVector2Array(
		[tip, Vector2(middle.x - HEAD.x * 0.5, tail), Vector2(middle.x + HEAD.x * 0.5, tail)]
	)
	var lit := arrow.has_focus() or arrow.is_hovered()
	var ink := arrow.get_theme_color(&"font_hover_color" if lit else &"font_color")
	arrow.draw_colored_polygon(points, ink)


func _draw_dots() -> void:
	var pill := StyleBoxFlat.new()
	pill.bg_color = PILL
	pill.border_color = PILL_EDGE
	pill.set_border_width_all(1)
	pill.set_corner_radius_all(roundi(_dots.size.x * 0.5))
	pill.anti_aliasing = true
	_dots.draw_style_box(pill, Rect2(Vector2.ZERO, _dots.size))
	var x := _dots.size.x * 0.5
	for i: int in pages:
		var y := PILL_ROOM.y + DOT * 0.5 + i * (DOT + DOT_GAP)
		_dots.draw_circle(Vector2(x, y), DOT * 0.5, Palette.CHIP_GOLD if i == page else FAINT)
