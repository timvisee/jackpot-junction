class_name ProofStyle
extends StyleBox
## A button laid on the catalog's cutting mat, GAME.md 8.8: a slip printed on the proof's own card
## stock and trimmed, a ruled box in ink inside its edge and its crop marks still standing out off
## its corners on the mat. Under the cursor the ruled box turns gold and the slip lifts a little
## further off the mat; held down, it is pressed to it, darker, its words a little lower. The pages'
## tabs are the tabs of their sheets: the page showing in front, its tab of the same stock as its
## sheet and joined to it, the other a shade darker, the sheet's under it.

enum State { REST, LIT, HELD }
enum Shape { SLIP, TAB_FRONT, TAB_UNDER, TAB_LIT }

## How far in the slip's paper is from the button's edge, how far in from that its ruled box, and
## how strong the box is at rest.
const TRIM := 4.0
const RULED := 6.0
const RULED_INK := 0.7
## The crop marks off the slip's corners: how far they stand off it and how long they are, and their
## ink, the mat's own.
const CROP_OFF := 4.0
const CROP_LONG := 10.0
const CROP_INK := Color(0.88, 0.9, 0.84, 0.7)
## How far the shadow falls at rest, lit and held.
const LIFT := Vector2(3.0, 5.0)
const LIFT_LIT := Vector2(3.0, 7.0)
const LIFT_HELD := Vector2(1.0, 2.0)
## The room round a slip's words, and how much lower they sit held down.
const ACROSS := 22.0
const DOWN := 8.0
const PRESSED := 2.0
## A tab's room round its words, how round its top corners are, how far in its top leans on its far
## side, how much lower a tab stands that is not showing and one under the pointer, and how much
## darker the sheet under is, the one [ProofArt] draws.
const TAB_ACROSS := 24.0
const TAB_ROUND := 7.0
const TAB_LEAN := 6.0
const TAB_LOWER := 4.0
const TAB_LIT_LOWER := 2.0

var state := State.REST
var shape := Shape.SLIP


## Dresses [param button] as a slip on the mat: its looks, and its words in ink.
static func dress(button: Button) -> void:
	for pair: Array in [
		[State.REST, [&"normal", &"disabled"]],
		[State.LIT, [&"hover", &"focus"]],
		[State.HELD, [&"pressed", &"hover_pressed"]],
	]:
		var look := ProofStyle.new()
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


## Dresses [param bar]'s tabs as the sheets' tabs, [param down] of room over and under their words,
## as the House's tabs have.
static func dress_tabs(bar: TabBar, down: float) -> void:
	for pair: Array in [
		[&"tab_selected", Shape.TAB_FRONT, 0.0],
		[&"tab_unselected", Shape.TAB_UNDER, TAB_LOWER],
		[&"tab_hovered", Shape.TAB_LIT, TAB_LIT_LOWER],
		[&"tab_disabled", Shape.TAB_UNDER, TAB_LOWER],
	]:
		var look := ProofStyle.new()
		look.shape = pair[1]
		look.content_margin_left = TAB_ACROSS
		look.content_margin_right = TAB_ACROSS
		look.content_margin_top = down + (pair[2] as float)
		look.content_margin_bottom = down
		bar.add_theme_stylebox_override(pair[0], look)
	bar.add_theme_stylebox_override(&"tab_focus", StyleBoxEmpty.new())
	bar.add_theme_color_override(&"font_selected_color", HouseTheme.INK)
	bar.add_theme_color_override(&"font_hovered_color", HouseTheme.INK)
	bar.add_theme_color_override(&"font_unselected_color", Color(HouseTheme.INK, 0.6))
	bar.add_theme_color_override(&"font_disabled_color", Color(HouseTheme.INK, 0.35))


func _draw(item: RID, rect: Rect2) -> void:
	if shape == Shape.SLIP:
		_slip(item, rect)
	else:
		_tab(item, rect)


func _slip(item: RID, rect: Rect2) -> void:
	var slip := rect.grow(-TRIM)
	var lift := LIFT_HELD if state == State.HELD else (LIFT_LIT if state == State.LIT else LIFT)
	var paper := ProofArt.PAPER.darkened(ProofArt.UNDER) if state == State.HELD else ProofArt.PAPER
	var corners := PackedVector2Array(
		[
			slip.position,
			Vector2(slip.end.x, slip.position.y),
			slip.end,
			Vector2(slip.position.x, slip.end.y)
		]
	)
	var fallen := PackedVector2Array()
	for point: Vector2 in corners:
		fallen.append(point + lift)
	RenderingServer.canvas_item_add_polygon(item, fallen, PackedColorArray([ProofArt.FALLEN]))
	RenderingServer.canvas_item_add_polygon(item, corners, PackedColorArray([paper]))
	var lit := state == State.LIT
	var ruled := slip.grow(-RULED)
	var box := PackedVector2Array(
		[
			ruled.position,
			Vector2(ruled.end.x, ruled.position.y),
			ruled.end,
			Vector2(ruled.position.x, ruled.end.y)
		]
	)
	box.append(box[0])
	var ink := HouseTheme.FOIL_LOW if lit else Color(HouseTheme.INK, RULED_INK)
	RenderingServer.canvas_item_add_polyline(
		item, box, PackedColorArray([ink]), 2.0 if lit else 1.5
	)
	var marks := PackedVector2Array()
	for corner: Vector2 in corners:
		var out := (corner - slip.get_center()).sign()
		(
			marks
			. append_array(
				[
					corner + Vector2(out.x * CROP_OFF, 0.0),
					corner + Vector2(out.x * (CROP_OFF + CROP_LONG), 0.0),
					corner + Vector2(0.0, out.y * CROP_OFF),
					corner + Vector2(0.0, out.y * (CROP_OFF + CROP_LONG)),
				]
			)
		)
	RenderingServer.canvas_item_add_multiline(item, marks, PackedColorArray([CROP_INK]))


## A sheet's tab: round at its top, leaning in a little on its far side, open at its foot where it
## meets its sheet.
func _tab(item: RID, rect: Rect2) -> void:
	var lower := 0.0
	var paper := ProofArt.PAPER
	if shape == Shape.TAB_UNDER:
		lower = TAB_LOWER
		paper = ProofArt.PAPER.darkened(ProofArt.UNDER)
	elif shape == Shape.TAB_LIT:
		lower = TAB_LIT_LOWER
		paper = ProofArt.PAPER.darkened(ProofArt.UNDER * 0.5)
	var top := rect.position.y + lower
	var outline := PackedVector2Array([Vector2(rect.position.x, rect.end.y)])
	var corner := Vector2(rect.position.x + TAB_ROUND, top + TAB_ROUND)
	for i: int in 7:
		outline.append(corner + Vector2.from_angle(PI + PI * 0.5 * i / 6.0) * TAB_ROUND)
	corner = Vector2(rect.end.x - TAB_LEAN - TAB_ROUND, top + TAB_ROUND)
	for i: int in 7:
		outline.append(corner + Vector2.from_angle(-PI * 0.5 + PI * 0.5 * i / 6.0) * TAB_ROUND)
	outline.append(rect.end)
	RenderingServer.canvas_item_add_polygon(item, outline, PackedColorArray([paper]))
	if shape == Shape.TAB_FRONT:
		var shine := PackedVector2Array(
			[
				Vector2(rect.position.x + TAB_ROUND, top + 1.5),
				Vector2(rect.end.x - TAB_LEAN - TAB_ROUND, top + 1.5)
			]
		)
		RenderingServer.canvas_item_add_polyline(
			item, shine, PackedColorArray([Color(1.0, 1.0, 1.0, 0.5)]), 1.0
		)
