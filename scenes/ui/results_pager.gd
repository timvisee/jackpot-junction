class_name ResultsPager
extends HBoxContainer
## The two pages of the screen after a map of a Grand Prix, GAME.md 9.7: the map's podium and the
## run's standings, turned with an arrow each way and a dot for each page, the page being looked
## at lit in gold. An arrow with no page that way is dimmed rather than taken away, so the arrows
## stay where they are and the dots stay between them.

const ARROW := Vector2(72.0, 56.0)
## The arrowhead drawn on each arrow's button, wide and tall.
const HEAD := Vector2(12.0, 20.0)
const DOT := 10.0
const DOT_GAP := 10.0
const FAINT := Color(1.0, 1.0, 1.0, 0.25)
const INK := Color(0.88, 0.88, 0.92)

## Back a page, and on a page.
var back: Button
var on: Button
var page := 0
var pages := 2
var _dots: Control


static func create() -> ResultsPager:
	var pager := ResultsPager.new()
	pager.alignment = BoxContainer.ALIGNMENT_CENTER
	pager.add_theme_constant_override("separation", 24)
	pager.back = pager._arrow(-1.0)
	pager.add_child(pager.back)
	pager._dots = Control.new()
	pager._dots.custom_minimum_size = Vector2(
		pager.pages * DOT + (pager.pages - 1) * DOT_GAP, ARROW.y
	)
	pager._dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pager._dots.draw.connect(pager._draw_dots)
	pager.add_child(pager._dots)
	pager.on = pager._arrow(1.0)
	pager.add_child(pager.on)
	return pager


## On [param shown], with the arrows that can go anywhere lit and the others dimmed.
func show_page(shown: int, can_back: bool, can_on: bool) -> void:
	page = shown
	# A dimmed arrow is passed over by a pad's cursor as well as by a click.
	for arrow: Button in [back, on]:
		arrow.disabled = not (can_back if arrow == back else can_on)
		arrow.focus_mode = Control.FOCUS_NONE if arrow.disabled else Control.FOCUS_ALL
	back.queue_redraw()
	on.queue_redraw()
	_dots.queue_redraw()


## A button with an arrowhead on it pointing [param way], -1 for back and 1 for on. Drawn rather
## than typed, the way [RankArrow] is, so it does not depend on the font having an arrow in it.
func _arrow(way: float) -> Button:
	var arrow := MenuTheme.button("")
	arrow.custom_minimum_size = ARROW
	var dim := MenuTheme.button_style(
		Color(MenuTheme.BUTTON_BG, 0.4), Color(MenuTheme.BUTTON_RIM, 0.05)
	)
	arrow.add_theme_stylebox_override("disabled", dim)
	arrow.draw.connect(_draw_head.bind(arrow, way))
	return arrow


func _draw_head(arrow: Button, way: float) -> void:
	var middle := arrow.size * 0.5
	var tip := middle + Vector2(HEAD.x * 0.5 * way, 0.0)
	var tail := middle.x - HEAD.x * 0.5 * way
	var points := PackedVector2Array(
		[tip, Vector2(tail, middle.y - HEAD.y * 0.5), Vector2(tail, middle.y + HEAD.y * 0.5)]
	)
	var lit := arrow.has_focus() or arrow.is_hovered()
	var ink := FAINT if arrow.disabled else (Color.WHITE if lit else INK)
	arrow.draw_colored_polygon(points, ink)


func _draw_dots() -> void:
	var y := _dots.size.y * 0.5
	for i: int in pages:
		var x := DOT * 0.5 + i * (DOT + DOT_GAP)
		_dots.draw_circle(Vector2(x, y), DOT * 0.5, Palette.CHIP_GOLD if i == page else FAINT)
