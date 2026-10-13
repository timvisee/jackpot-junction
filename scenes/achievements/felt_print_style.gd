class_name FeltPrintStyle
extends StyleBox
## A button printed on the felt, GAME.md 8.10, as a craps table's PASS LINE is: its words in a box,
## a heavy line and a fine one inside it, in the cream the table's layout is printed in; under the
## cursor the print turns gold and the box is washed with it, and held down, washed deeper with its
## words a little lower.

enum State { REST, LIT, HELD }

## How round the box's corners are, how far in its fine line is, how strongly the gold washes it
## lit and held, and the room round the words.
const ROUND := 8.0
const INSET := 5.0
const WASH_LIT := 0.12
const WASH_HELD := 0.24
const ACROSS := 22.0
const DOWN := 10.0

var state := State.REST


## The looks of a printed button for each of a button's states.
static func looks() -> Dictionary[StringName, StyleBox]:
	var made: Dictionary[StringName, StyleBox] = {}
	for pair: Array in [
		[State.REST, [&"normal", &"disabled"]],
		[State.LIT, [&"hover", &"focus"]],
		[State.HELD, [&"pressed", &"hover_pressed"]],
	]:
		var style := FeltPrintStyle.new()
		style.state = pair[0]
		var lower := 2.0 if pair[0] == State.HELD else 0.0
		style.content_margin_left = ACROSS
		style.content_margin_right = ACROSS
		style.content_margin_top = DOWN + lower
		style.content_margin_bottom = DOWN - lower
		for name: StringName in pair[1]:
			made[name] = style
	return made


## Prints [param button] on the felt: its looks, and its words in the print's cream, gold under
## the cursor.
static func dress(button: Button) -> void:
	var made := looks()
	for state_name: StringName in made:
		button.add_theme_stylebox_override(state_name, made[state_name])
	button.add_theme_color_override(&"font_color", Color(FeltArt.PRINT, 1.0))
	for state_name: StringName in [
		&"font_hover_color", &"font_focus_color", &"font_pressed_color", &"font_hover_pressed_color"
	]:
		button.add_theme_color_override(state_name, HouseTheme.FOIL)


func _draw(item: RID, rect: Rect2) -> void:
	var ink := FeltArt.PRINT if state == State.REST else HouseTheme.FOIL
	if state != State.REST:
		var wash := Color(HouseTheme.FOIL, WASH_LIT if state == State.LIT else WASH_HELD)
		RenderingServer.canvas_item_add_polygon(
			item, FeltArt.rounded(rect, ROUND), PackedColorArray([wash])
		)
	_ring(item, FeltArt.rounded(rect.grow(-1.0), ROUND), ink, 2.0)
	_ring(item, FeltArt.rounded(rect.grow(-INSET), ROUND - 4.0), Color(ink, ink.a * 0.75), 1.0)


func _ring(item: RID, outline: PackedVector2Array, ink: Color, width: float) -> void:
	var closed := outline.duplicate()
	closed.append(outline[0])
	RenderingServer.canvas_item_add_polyline(item, closed, PackedColorArray([ink]), width, true)
