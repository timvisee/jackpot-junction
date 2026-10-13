class_name AtlasTicketStyle
extends StyleBox
## A button laid on the loyalty program's atlas cover, GAME.md 8.9, as the map's own tickets are:
## a stub of the House's cream paper with a bite out of either end, its words in ink, a faint ink
## hairline inside its edge and its shadow on the cloth. Under the cursor the hairline turns gold
## and the paper lifts a little further off the cloth; held down, the paper is pressed to it,
## darker, its words a little lower. The map's sheets' tabs are index tabs of the same paper, the
## one showing joined to the map's top edge, the rest a shade darker behind; and the List switch a
## pill of the paper, its knob a ring of faint ink off and the stamp's red on.

enum State { REST, LIT, HELD }
enum Shape { TICKET, TAB_SHOWING, TAB_OTHER, TAB_LIT }

## The paper, darker toward its foot by this much, and held down or behind.
const SHADE := 0.08
const BEHIND := 0.18
## How far a bite goes into either end at the most, as a share of the ticket's height at the
## most, how far in the hairline runs, and how strong it is at rest.
const BITE := 7.0
const BITE_SHARE := 0.2
const HAIRLINE_IN := 4.0
const HAIRLINE := 0.35
## How far the shadow falls at rest, lit and held.
const LIFT := Vector2(1.5, 3.0)
const LIFT_LIT := Vector2(2.0, 5.0)
const LIFT_HELD := Vector2(0.5, 1.0)
## The room round a ticket's words, and how much lower they sit held down.
const ACROSS := 22.0
const DOWN := 8.0
const PRESSED := 2.0
## A tab's room round its words, how round its top corners are, and how much lower a tab stands
## that is not showing, and one under the cursor.
const TAB_ACROSS := 24.0
const TAB_ROUND := 5.0
const TAB_LOWER := 4.0
const TAB_LIT_LOWER := 2.0

var state := State.REST
var shape := Shape.TICKET


## Dresses [param button] as a ticket on the cover: its looks, and its words in ink.
static func dress(button: Button) -> void:
	for pair: Array in [
		[State.REST, [&"normal", &"disabled"]],
		[State.LIT, [&"hover", &"focus"]],
		[State.HELD, [&"pressed", &"hover_pressed"]],
	]:
		var look := AtlasTicketStyle.new()
		look.state = pair[0]
		var lower := PRESSED if pair[0] == State.HELD else 0.0
		look.content_margin_left = ACROSS
		look.content_margin_right = ACROSS
		look.content_margin_top = DOWN + lower
		look.content_margin_bottom = DOWN - lower
		for state_name: StringName in pair[1]:
			button.add_theme_stylebox_override(state_name, look)
	for state_name: StringName in [
		&"font_color",
		&"font_hover_color",
		&"font_focus_color",
		&"font_pressed_color",
		&"font_hover_pressed_color",
	]:
		button.add_theme_color_override(state_name, HouseTheme.INK)
	button.add_theme_color_override(&"font_disabled_color", Color(HouseTheme.INK, 0.4))


## Dresses [param bar]'s tabs as index tabs of the paper, [param down] of room over and under
## their words, as the House's tabs have.
static func dress_tabs(bar: TabBar, down: float) -> void:
	for pair: Array in [
		[&"tab_selected", Shape.TAB_SHOWING, 0.0],
		[&"tab_unselected", Shape.TAB_OTHER, TAB_LOWER],
		[&"tab_hovered", Shape.TAB_LIT, TAB_LIT_LOWER],
		[&"tab_disabled", Shape.TAB_OTHER, TAB_LOWER],
	]:
		var look := AtlasTicketStyle.new()
		look.shape = pair[1]
		look.content_margin_left = TAB_ACROSS
		look.content_margin_right = TAB_ACROSS
		look.content_margin_top = down + (pair[2] as float)
		look.content_margin_bottom = down
		bar.add_theme_stylebox_override(pair[0], look)
	bar.add_theme_stylebox_override(&"tab_focus", StyleBoxEmpty.new())
	bar.add_theme_color_override(&"font_selected_color", HouseTheme.INK)
	bar.add_theme_color_override(&"font_hovered_color", HouseTheme.INK)
	bar.add_theme_color_override(&"font_unselected_color", Color(HouseTheme.INK, 0.7))
	bar.add_theme_color_override(&"font_disabled_color", Color(HouseTheme.INK, 0.35))


## Dresses [param switch] as a pill of the paper, off and on.
static func dress_switch(switch: CheckButton) -> void:
	for pair: Array in [
		[["unchecked", "unchecked_mirrored", "unchecked_disabled"], false],
		[["checked", "checked_mirrored", "checked_disabled"], true],
	]:
		var picture := Switch.new()
		picture.on = pair[1]
		for state_name: String in pair[0]:
			switch.add_theme_icon_override(state_name, picture)


## The List switch's picture: the pill and its knob, at the size the House's switches are.
class Switch:
	extends Texture2D

	var on := false

	func _get_width() -> int:
		return int(MenuTheme.SWITCH.x)

	func _get_height() -> int:
		return int(MenuTheme.SWITCH.y)

	func _draw(item: RID, at: Vector2, _modulate: Color, _transpose: bool) -> void:
		_draw_rect(item, Rect2(at, MenuTheme.SWITCH), false, Color.WHITE, false)

	func _draw_rect(item: RID, rect: Rect2, _tile: bool, _modulate: Color, _turn: bool) -> void:
		var pill := Rect2(rect.position + Vector2(1.0, rect.size.y * 0.15), rect.size)
		pill.size -= Vector2(2.0, rect.size.y * 0.3)
		var round_by := pill.size.y * 0.5
		var track := FeltArt.rounded(pill, round_by)
		var fallen := PackedVector2Array()
		for point: Vector2 in track:
			fallen.append(point + LIFT)
		var shadow := PackedColorArray([Color(0.0, 0.0, 0.0, 0.4)])
		RenderingServer.canvas_item_add_polygon(item, fallen, shadow)
		var paper := PackedColorArray([HouseTheme.PAPER])
		RenderingServer.canvas_item_add_polygon(item, track, paper)
		var x := pill.end.x - round_by if on else pill.position.x + round_by
		var knob := Vector2(x, pill.get_center().y)
		var size := round_by - 3.0
		if on:
			RenderingServer.canvas_item_add_circle(item, knob, size, HouseTheme.STAMP_RED)
		else:
			RenderingServer.canvas_item_add_circle(item, knob, size, Color(HouseTheme.INK, 0.3))
			RenderingServer.canvas_item_add_circle(item, knob, size - 2.0, HouseTheme.PAPER)

	func _draw_rect_region(
		item: RID, rect: Rect2, _region: Rect2, modulate: Color, turn: bool, _clip: bool
	) -> void:
		_draw_rect(item, rect, false, modulate, turn)


func _draw(item: RID, rect: Rect2) -> void:
	if shape == Shape.TICKET:
		_ticket(item, rect.grow(-2.0))
	else:
		_tab(item, rect)


func _ticket(item: RID, rect: Rect2) -> void:
	var paper := HouseTheme.PAPER_LOW if state == State.HELD else HouseTheme.PAPER
	var lift := LIFT_HELD if state == State.HELD else (LIFT_LIT if state == State.LIT else LIFT)
	var bite := minf(BITE, rect.size.y * BITE_SHARE)
	var middle := rect.get_center().y
	var outline := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y)])
	for i: int in 9:
		outline.append(
			Vector2(rect.end.x, middle) + Vector2.from_angle(-PI * (0.5 + i / 8.0)) * bite
		)
	outline.append(rect.end)
	outline.append(Vector2(rect.position.x, rect.end.y))
	for i: int in 9:
		outline.append(
			Vector2(rect.position.x, middle) + Vector2.from_angle(PI * (0.5 - i / 8.0)) * bite
		)
	_paper(item, outline, rect, paper, lift)
	var hairline := FeltArt.rounded(rect.grow(-HAIRLINE_IN), 2.0)
	hairline.append(hairline[0])
	var lit := state == State.LIT
	var ink := HouseTheme.FOIL_LOW if lit else Color(HouseTheme.INK, HAIRLINE)
	var wide := PackedColorArray([ink])
	RenderingServer.canvas_item_add_polyline(item, hairline, wide, 2.0 if lit else 1.0, true)


## An index tab: round at its top, open at its foot where it meets the map.
func _tab(item: RID, rect: Rect2) -> void:
	var lower := TAB_LOWER if shape == Shape.TAB_OTHER else 0.0
	if shape == Shape.TAB_LIT:
		lower = TAB_LIT_LOWER
	var top := rect.position.y + lower
	var outline := PackedVector2Array([Vector2(rect.position.x, rect.end.y)])
	var corner := Vector2(rect.position.x + TAB_ROUND, top + TAB_ROUND)
	for i: int in 7:
		outline.append(corner + Vector2.from_angle(PI + PI * 0.5 * i / 6.0) * TAB_ROUND)
	corner = Vector2(rect.end.x - TAB_ROUND, top + TAB_ROUND)
	for i: int in 7:
		outline.append(corner + Vector2.from_angle(-PI * 0.5 + PI * 0.5 * i / 6.0) * TAB_ROUND)
	outline.append(rect.end)
	var paper := HouseTheme.PAPER
	if shape == Shape.TAB_OTHER:
		paper = HouseTheme.PAPER_LOW.darkened(BEHIND)
	elif shape == Shape.TAB_LIT:
		paper = HouseTheme.PAPER_LOW
	var colors := PackedColorArray()
	for point: Vector2 in outline:
		var t := clampf((point.y - top) / maxf(rect.end.y - top, 1.0), 0.0, 1.0)
		colors.append(paper.lerp(paper.darkened(SHADE * 0.5), t))
	RenderingServer.canvas_item_add_polygon(item, outline, colors)


## The paper over [param outline], darker toward the foot of [param rect], its shadow [param lift]
## under it on the cloth.
func _paper(
	item: RID, outline: PackedVector2Array, rect: Rect2, paper: Color, lift: Vector2
) -> void:
	var fallen := PackedVector2Array()
	for point: Vector2 in outline:
		fallen.append(point + lift)
	RenderingServer.canvas_item_add_polygon(
		item, fallen, PackedColorArray([Color(0.0, 0.0, 0.0, 0.4)])
	)
	var colors := PackedColorArray()
	for point: Vector2 in outline:
		var t := clampf((point.y - rect.position.y) / maxf(rect.size.y, 1.0), 0.0, 1.0)
		colors.append(paper.lerp(paper.darkened(SHADE), t))
	RenderingServer.canvas_item_add_polygon(item, outline, colors)
