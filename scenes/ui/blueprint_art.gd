class_name BlueprintArt
extends RefCounted
## The blueprint the gamepad is drawn on, GAME.md 8.3b, see [PadLeaflet]: a sheet of the Dept. of
## Karts' engineers, mottled blue with its grid, its border and its folds, the drafting marks round
## it, and the tabs cut from its top edge; drawn as shapes onto whatever asks.

## The sheet's blue, and the white its lines are drawn in and the white of what is said quietly on
## it; the red pencil a note in the margin is written in.
const BLUE := Color("#1f4f8e")
const INK := Color(0.9, 0.95, 1.0)
const FAINT := Color(0.7, 0.8, 0.94)
const PENCIL := Color("#ffb19c")
## How far in the border runs, how far apart the grid's lines are, every how many a heavier one,
## and how many folds the sheet was folded along, across and down.
const BORDER := 26.0
const GRID := 24.0
const HEAVY := 5
const FOLDS := Vector2i(3, 1)
## How the tabs lean in at their tops, and how far down the ones behind stand.
const TAB_LEAN := 14.0
const TAB_BEHIND := 8.0


## The sheet over [param rect] on [param on]: the blue, mottled and grained, its grid and its double
## border inside its edge, and its edges a little darker, as a print is.
static func sheet(on: CanvasItem, rect: Rect2) -> void:
	on.draw_rect(rect, BLUE)
	on.draw_texture_rect(FeltArt.patches(), rect, true, Color(0.0, 0.05, 0.15, 0.24))
	on.draw_texture_rect(FeltArt.grain(), rect, true, Color(1.0, 1.0, 1.0, 0.05))
	var inside := rect.grow(-BORDER)
	var lines := PackedVector2Array()
	var heavy := PackedVector2Array()
	var across := int(inside.size.x / GRID)
	for i: int in range(1, across + 1):
		var x := inside.position.x + i * GRID
		var into := heavy if i % HEAVY == 0 else lines
		into.append(Vector2(x, inside.position.y))
		into.append(Vector2(x, inside.end.y))
	var down := int(inside.size.y / GRID)
	for i: int in range(1, down + 1):
		var y := inside.position.y + i * GRID
		var into := heavy if i % HEAVY == 0 else lines
		into.append(Vector2(inside.position.x, y))
		into.append(Vector2(inside.end.x, y))
	on.draw_multiline(lines, Color(1.0, 1.0, 1.0, 0.035), 1.0)
	on.draw_multiline(heavy, Color(1.0, 1.0, 1.0, 0.08), 1.0)
	on.draw_rect(inside, Color(INK, 0.75), false, 2.0)
	on.draw_rect(inside.grow(-6.0), Color(INK, 0.35), false, 1.0)
	for i: int in 16:
		var dark := 0.16 * pow(1.0 - i / 16.0, 2.0)
		on.draw_rect(rect.grow(-i), Color(0.0, 0.0, 0.05, dark), false, 1.0)


## The folds it was folded along, see [constant FOLDS]: a crease each, a little shadow on one side
## of it and a pale edge on the other.
static func folds(on: CanvasItem, rect: Rect2) -> void:
	for i: int in range(1, FOLDS.x + 1):
		var x := rect.position.x + rect.size.x * i / (FOLDS.x + 1.0)
		for j: int in 12:
			var shade := Color(0.0, 0.0, 0.0, 0.05 * (1.0 - j / 12.0))
			on.draw_line(Vector2(x - j, rect.position.y), Vector2(x - j, rect.end.y), shade, 1.0)
		_crease(on, Vector2(x, rect.position.y), Vector2(x, rect.end.y), Vector2(1.5, 0.0))
	for i: int in range(1, FOLDS.y + 1):
		var y := rect.position.y + rect.size.y * i / (FOLDS.y + 1.0)
		_crease(on, Vector2(rect.position.x, y), Vector2(rect.end.x, y), Vector2(0.0, 1.5))


static func _crease(on: CanvasItem, from: Vector2, to: Vector2, pale: Vector2) -> void:
	on.draw_line(from, to, Color(0.0, 0.0, 0.1, 0.25), 1.4)
	on.draw_line(from + pale, to + pale, Color(1.0, 1.0, 1.0, 0.12), 1.0)


## The drafting marks round [param inside], the border: a registration mark at each corner, and the
## grid's references, letters down the left and numbers along the top, in [param font].
static func marks(on: CanvasItem, inside: Rect2, font: Font) -> void:
	var corners: Array[Vector2] = [
		inside.position,
		Vector2(inside.end.x, inside.position.y),
		Vector2(inside.position.x, inside.end.y),
		inside.end,
	]
	var ink := Color(INK, 0.6)
	for corner: Vector2 in corners:
		on.draw_arc(corner, 9.0, 0.0, TAU, 20, ink, 1.2, true)
		on.draw_line(corner - Vector2(16.0, 0.0), corner + Vector2(16.0, 0.0), ink, 1.0)
		on.draw_line(corner - Vector2(0.0, 16.0), corner + Vector2(0.0, 16.0), ink, 1.0)
	var quiet := Color(INK, 0.5)
	for i: int in 8:
		var y := inside.position.y + (i + 0.5) * inside.size.y / 8.0
		_centered(on, font, "ABCDEFGH"[i], Vector2(inside.position.x - 14.0, y + 5.0), 13, quiet)
	for i: int in 12:
		var x := inside.position.x + (i + 0.5) * inside.size.x / 12.0
		_centered(on, font, str(i + 1), Vector2(x, inside.position.y - 8.0), 13, quiet)


## A tab over [param rect], its foot on the sheet's top edge: [param front] for the page's, in the
## sheet's own blue and joined to it, drawn after the sheet; behind it a darker one, a little lower,
## drawn before. [param lit] where the cursor or the mouse is on it: its edges drawn bright and a
## glow along them, a little light over it, in its own shape rather than a box round it.
static func tab(on: CanvasItem, rect: Rect2, front: bool, lit := false) -> void:
	var top := rect.position.y + (0.0 if front else TAB_BEHIND)
	var shape := PackedVector2Array(
		[
			Vector2(rect.position.x, rect.end.y),
			Vector2(rect.position.x + TAB_LEAN, top),
			Vector2(rect.end.x - TAB_LEAN, top),
			Vector2(rect.end.x, rect.end.y),
		]
	)
	on.draw_colored_polygon(shape, BLUE if front else BLUE.darkened(0.3))
	var span := Rect2(rect.position.x, top, rect.size.x, rect.end.y - top)
	on.draw_texture_rect(FeltArt.patches(), span, true, Color(0.0, 0.05, 0.15, 0.2))
	if not lit:
		on.draw_polyline(shape, Color(INK if front else FAINT, 0.5), 1.5, true)
		return
	on.draw_colored_polygon(shape, Color(INK, 0.08))
	on.draw_polyline(shape, Color(INK, 0.16), 7.0, true)
	on.draw_polyline(shape, Color(INK, 0.95), 2.2, true)


## A scale bar from [param at], four blocks of it, and what it is the scale of, in [param font].
static func scale_bar(on: CanvasItem, at: Vector2, font: Font) -> void:
	for i: int in 4:
		var block := Rect2(at + Vector2(i * 50.0, 0.0), Vector2(50.0, 8.0))
		on.draw_rect(block, Color(INK, 0.8), i % 2 == 0, -1.0 if i % 2 == 0 else 1.2)
	_centered(on, font, "0", at + Vector2(0.0, 26.0), 13, FAINT)
	_centered(on, font, "20 CM", at + Vector2(200.0, 26.0), 13, FAINT)
	on.draw_string(
		font,
		at + Vector2(240.0, 9.0),
		"SCALE 1:1  ·  ONE PAD",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		13,
		FAINT
	)


static func _centered(
	on: CanvasItem, font: Font, words: String, at: Vector2, tall: int, ink: Color
) -> void:
	var wide := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, tall).x
	on.draw_string(
		font, at - Vector2(wide * 0.5, 0.0), words, HORIZONTAL_ALIGNMENT_LEFT, -1, tall, ink
	)
