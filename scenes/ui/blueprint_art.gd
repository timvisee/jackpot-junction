class_name BlueprintArt
extends RefCounted
## The blueprint the gamepad is drawn on, GAME.md 8.3b, see [PadLeaflet]: a sheet of the Dept. of
## Karts' engineers, mottled blue with its grid, its border and its folds, the drafting marks round
## it, and the tabs on its top edge, the page's cut from the sheet itself; drawn as shapes onto
## whatever asks.

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
## How the tabs lean in at their tops, how far down the ones behind stand, how round their top
## corners are, and how far the page's tab flares out at its foot into the sheet's top edge.
const TAB_LEAN := 14.0
const TAB_BEHIND := 8.0
const TAB_ROUND := 7.0
const TAB_FLARE := 10.0
## How far in from its edge the paper darkens, as a print's edges do, a step a pixel.
const EDGE_DARK := 16
## How many steps each rounded corner and flare is drawn in.
const CURVE := 6


## The sheet over [param rect] on [param on], the page's tab over [param front] cut from its top
## edge, the two one piece of paper: the blue, mottled and grained, the tab's feet flared into the
## edge, its grid and its double border inside its edge, and its edges a little darker all round,
## the tab's with them, as a print's are. The tab lit up where [param lit], as [method tab] is.
static func sheet(on: CanvasItem, rect: Rect2, front := Rect2(), lit := false) -> void:
	var paper := PackedVector2Array([Vector2(rect.position.x, rect.end.y), rect.position])
	var edge := PackedVector2Array()
	if front.has_area():
		edge = _tab_edge(front, rect.position.y, front.position.y)
		var last := edge.size() - 1
		var foot_left := edge[0]
		var foot_right := edge[last]
		var up_left := foot_left + (edge[1] - foot_left).normalized() * TAB_FLARE
		var up_right := foot_right + (edge[last - 1] - foot_right).normalized() * TAB_FLARE
		var out := Vector2(TAB_FLARE, 0.0)
		var flared := _curve(foot_left - out, foot_left, up_left)
		flared.append_array(edge.slice(1, last))
		flared.append_array(_curve(up_right, foot_right, foot_right + out))
		paper.append_array(flared)
		edge = flared
	paper.append(Vector2(rect.end.x, rect.position.y))
	paper.append(rect.end)
	_paper(on, paper, BLUE, rect.position, 0.24)
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
	for i: int in range(1, EDGE_DARK):
		var dark := 0.16 * pow(1.0 - float(i) / EDGE_DARK, 2.0)
		for ring: PackedVector2Array in Geometry2D.offset_polygon(paper, -i):
			ring.append(ring[0])
			on.draw_polyline(ring, Color(0.0, 0.0, 0.05, dark), 1.0)
	if lit and not edge.is_empty():
		_light(on, edge)


## A soft shadow on [param on] under a sheet over [param rect] lying over the screen, rather than
## filling it.
static func shadow(on: CanvasItem, rect: Rect2) -> void:
	for i: int in 12:
		var shade := Color(0.0, 0.0, 0.0, 0.045 * (1.0 - i / 12.0))
		on.draw_rect(Rect2(rect.position + Vector2(0.0, 6.0), rect.size).grow(2.0 + i * 2.0), shade)


## A tab behind the sheet over [param rect], whose foot is the sheet's top edge, drawn before the
## sheet: darker than it, standing a little lower than the page's, which is cut from the sheet
## itself, see [method sheet], and nearer the sheet's own blue where it is the [param current] one
## of a switch beside the pages. Its edges are drawn only [param lit], where the cursor or the
## mouse is on it: bright, with a glow along them and a little light over it, the cursor's marker
## in its own shape.
static func tab(on: CanvasItem, rect: Rect2, lit := false, current := false) -> void:
	var edge := _tab_edge(rect, rect.end.y + TAB_BEHIND, rect.position.y + TAB_BEHIND)
	_paper(on, edge, BLUE.darkened(0.1 if current else 0.3), rect.position, 0.2)
	if lit:
		_light(on, edge)


## A tab's edge over [param rect], from its foot at [param foot] on the left, up its slanted side to
## its top at [param top], round its corners and down the other side.
static func _tab_edge(rect: Rect2, foot: float, top: float) -> PackedVector2Array:
	var left := Vector2(rect.position.x, foot)
	var right := Vector2(rect.end.x, foot)
	var top_left := Vector2(rect.position.x + TAB_LEAN, top)
	var top_right := Vector2(rect.end.x - TAB_LEAN, top)
	var edge := PackedVector2Array([left])
	for corner: Array in [[left, top_left, top_right], [top_left, top_right, right]]:
		var at: Vector2 = corner[1]
		var into := at + ((corner[0] as Vector2) - at).normalized() * TAB_ROUND
		var out := at + ((corner[2] as Vector2) - at).normalized() * TAB_ROUND
		edge.append_array(_curve(into, at, out))
	edge.append(right)
	return edge


## A curve from [param from] to [param to], drawn towards [param pull].
static func _curve(from: Vector2, pull: Vector2, to: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in CURVE + 1:
		var t := float(i) / CURVE
		points.append(from.lerp(pull, t).lerp(pull.lerp(to, t), t))
	return points


## The paper inside [param shape] on [param on], in [param blue] mottled [param mottle] deep and
## grained, both laid from [param origin], so a tab cut from the sheet is the same paper as it.
static func _paper(
	on: CanvasItem, shape: PackedVector2Array, blue: Color, origin: Vector2, mottle: float
) -> void:
	on.draw_colored_polygon(shape, blue)
	var looks: Array[Array] = [
		[FeltArt.patches(), Color(0.0, 0.05, 0.15, mottle)],
		[FeltArt.grain(), Color(1.0, 1.0, 1.0, 0.05)],
	]
	for look: Array in looks:
		var texture: Texture2D = look[0]
		var uvs := PackedVector2Array()
		for point: Vector2 in shape:
			uvs.append((point - origin) / texture.get_size())
		on.draw_colored_polygon(shape, look[1], uvs, texture)


## A tab lit up along its [param edge] on [param on]: a little light over it, and the edge bright
## with a glow along it.
static func _light(on: CanvasItem, edge: PackedVector2Array) -> void:
	on.draw_colored_polygon(edge, Color(INK, 0.08))
	on.draw_polyline(edge, Color(INK, 0.16), 7.0, true)
	on.draw_polyline(edge, Color(INK, 0.95), 2.2, true)


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
		var row := "ABCDEFGH"[i]  # NO_TRANSLATE
		_centered(on, font, row, Vector2(inside.position.x - 14.0, y + 5.0), 13, quiet)
	for i: int in 12:
		var x := inside.position.x + (i + 0.5) * inside.size.x / 12.0
		_centered(on, font, str(i + 1), Vector2(x, inside.position.y - 8.0), 13, quiet)


## A scale bar from [param at], four blocks of it, and what it is the scale of, [param of], in
## [param font].
static func scale_bar(on: CanvasItem, at: Vector2, font: Font, of: String) -> void:
	for i: int in 4:
		var block := Rect2(at + Vector2(i * 50.0, 0.0), Vector2(50.0, 8.0))
		on.draw_rect(block, Color(INK, 0.8), i % 2 == 0, -1.0 if i % 2 == 0 else 1.2)
	_centered(on, font, "0", at + Vector2(0.0, 26.0), 13, FAINT)
	_centered(on, font, Lang.t("20 CM"), at + Vector2(200.0, 26.0), 13, FAINT)
	on.draw_string(
		font,
		at + Vector2(240.0, 9.0),
		Lang.t("SCALE 1:1  ·  %s") % of,
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
