class_name PlaysetPrints
extends Control
## The Playroom's two prints, GAME.md 8.1c: the sticker sheet the floor is, drawn once from the
## map's grid, and the marquee on the lid of the case.
##
## The sheet is one big vinyl sticker laid in the molded tray: petrol teal, a margin of the plum
## tray showing between its die-cut edge and the House's rail, the four suits printed at a whisper
## across it, and its far right corner gone, peeled up off the tray, which shows through where it
## was. The House's layout is laid over it as the floor's detail. The picture covers the arena from
## corner to corner, as [LayoutPrint]'s does.
##
## The marquee is the sign at the middle of the lid's skyline: the name in cream on plum inside a
## ring of bulbs, and the line every playset of the House's carries under it.

enum Print { SHEET, MARQUEE }

const CELL_PIXELS := 32
const MARQUEE_PIXELS := Vector2i(1024, 384)
const FONT := preload("res://assets/fonts/BarlowCondensed-Black.ttf")
const SMALL := preload("res://assets/fonts/BarlowCondensed-ExtraBold.ttf")
const TRAY := Color("#2B2430")
const SHEET := Color("#22474D")
const WATERMARK := Color("#264D53")
const CREAM := Color("#E9DFC8")
const OCHRE := Color("#CF9A3E")
const PLUM := Color("#47304A")
## How far in from the arena's edge the sheet's die-cut edge is, in cells: just past the House's
## rail, which takes the first. And how far along each edge the corner that has lifted reaches, in
## meters.
const SHEET_IN := 1.15
const PEEL := 2.0

var print_kind := Print.SHEET
var grid: ArenaGrid


static func sheet(on: ArenaGrid) -> PlaysetPrints:
	var art := PlaysetPrints.new()
	art.grid = on
	return art


static func marquee() -> PlaysetPrints:
	var art := PlaysetPrints.new()
	art.print_kind = Print.MARQUEE
	return art


static func sheet_pixels(on: ArenaGrid) -> Vector2i:
	return Vector2i(on.width * CELL_PIXELS, on.height * CELL_PIXELS)


func _draw() -> void:
	if print_kind == Print.MARQUEE:
		_marquee()
	elif grid != null:
		_sheet()


func _sheet() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), TRAY)
	var inset := CELL_PIXELS * SHEET_IN
	var edge := Rect2(Vector2.ONE * inset, size - Vector2.ONE * inset * 2.0)
	var peel := PEEL / grid.cell_size * CELL_PIXELS
	var points := PackedVector2Array(
		[
			edge.position,
			Vector2(edge.end.x - peel, edge.position.y),
			Vector2(edge.end.x, edge.position.y + peel),
			edge.end,
			Vector2(edge.position.x, edge.end.y),
		]
	)
	draw_colored_polygon(points, SHEET)
	_watermark(edge)


## The four suits across the sheet at a whisper, on a grid with every other row stepped over.
func _watermark(edge: Rect2) -> void:
	var step := CELL_PIXELS * 3.0
	var row := 0
	var y := edge.position.y + step * 0.6
	while y < edge.end.y - step * 0.3:
		var x := edge.position.x + step * (0.6 if row % 2 == 0 else 1.1)
		var suit := row
		while x < edge.end.x - step * 0.3:
			_suit(Vector2(x, y), suit % 4, CELL_PIXELS * 0.32)
			x += step
			suit += 1
		y += step * 0.75
		row += 1


## One suit, drawn from circles and triangles: a heart, a diamond, a club or a spade.
func _suit(at: Vector2, which: int, reach: float) -> void:
	var ink := WATERMARK
	var r := reach * 0.5
	match which:
		0:
			draw_circle(at + Vector2(-r * 0.95, -r * 0.4), r, ink)
			draw_circle(at + Vector2(r * 0.95, -r * 0.4), r, ink)
			draw_colored_polygon(
				PackedVector2Array(
					[
						at + Vector2(-reach * 0.95, -r * 0.1),
						at + Vector2(reach * 0.95, -r * 0.1),
						at + Vector2(0.0, reach * 1.1)
					]
				),
				ink
			)
		1:
			draw_colored_polygon(
				PackedVector2Array(
					[
						at + Vector2(0.0, -reach),
						at + Vector2(reach * 0.7, 0.0),
						at + Vector2(0.0, reach),
						at + Vector2(-reach * 0.7, 0.0)
					]
				),
				ink
			)
		2:
			draw_circle(at + Vector2(0.0, -r * 0.9), r * 0.85, ink)
			draw_circle(at + Vector2(-r * 0.95, r * 0.35), r * 0.85, ink)
			draw_circle(at + Vector2(r * 0.95, r * 0.35), r * 0.85, ink)
			_stem(at, reach, ink)
		_:
			draw_circle(at + Vector2(-r * 0.95, r * 0.3), r, ink)
			draw_circle(at + Vector2(r * 0.95, r * 0.3), r, ink)
			draw_colored_polygon(
				PackedVector2Array(
					[
						at + Vector2(-reach * 0.95, r * 0.1),
						at + Vector2(reach * 0.95, r * 0.1),
						at + Vector2(0.0, -reach * 1.1)
					]
				),
				ink
			)
			_stem(at, reach, ink)


func _stem(at: Vector2, reach: float, ink: Color) -> void:
	draw_colored_polygon(
		PackedVector2Array(
			[
				at + Vector2(0.0, reach * 0.2),
				at + Vector2(reach * 0.4, reach * 1.1),
				at + Vector2(-reach * 0.4, reach * 1.1)
			]
		),
		ink
	)


# --- the marquee -----------------------------------------------------------------


func _marquee() -> void:
	var board := Rect2(Vector2.ZERO, size)
	draw_rect(board, OCHRE)
	var inner := board.grow(-size.y * 0.1)
	draw_rect(inner, PLUM)
	# The bulbs round it, every other one lit.
	var bulbs := 26
	var spacing := (board.size.x - size.y * 0.1) / float(bulbs)
	for i: int in bulbs:
		var x := size.y * 0.05 + spacing * (float(i) + 0.5)
		for y: float in [size.y * 0.05, size.y * 0.95]:
			draw_circle(Vector2(x, y), size.y * 0.032, CREAM if i % 2 == 0 else Color("#8E6A3A"))
	var down := 5
	for i: int in down:
		var y := size.y * 0.05 + (size.y * 0.9) * (float(i) + 0.5) / float(down)
		for x: float in [size.y * 0.05, size.x - size.y * 0.05]:
			draw_circle(Vector2(x, y), size.y * 0.032, CREAM if i % 2 == 0 else Color("#8E6A3A"))
	_centered("JACKPOT JUNCTION", FONT, int(size.y * 0.36), size.y * 0.52, CREAM)
	_centered(
		"A HOUSE PLAYSET  ·  COLLECT EVERY TABLE", SMALL, int(size.y * 0.1), size.y * 0.75, OCHRE
	)


func _centered(text: String, font: Font, font_size: int, baseline: float, ink: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(
		font,
		Vector2(size.x * 0.5 - width * 0.5, baseline),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		ink
	)
