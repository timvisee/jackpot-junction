class_name PinballPrints
extends Control
## The Arcade's two prints, GAME.md 8.1c, drawn once from the map's grid: the playfield's art, in
## a pinball artist's hand under the House's layout, and the backglass of the machine's head.
##
## The playfield is what a restored machine of the sixties wears rather than a new one: a plum
## ground, a sunburst at a whisper behind the Junction on a teal medallion, a teal band round the
## field, an ochre starburst behind each Jackpot, a few sparkles in the open, and the warm pool
## the bulb under each insert throws on the coat. The House's layout is laid over it as the
## floor's detail, so none of this says anything the layout says; it is the paper it is printed
## on. The picture covers the arena from corner to corner, as [LayoutPrint]'s does.
##
## The backglass is the machine's head, painted on the back of its glass and lit from behind: the
## name arched over a wheel, a score window in each seat's color, and the windows a machine lights
## between games, GAME OVER, SAME PLAYER SHOOTS AGAIN and TILT, all dark.

enum Print { FIELD, GLASS }

## How many pixels a cell of the playfield is drawn at: soft fields need fewer than the layout's
## fine lines do.
const CELL_PIXELS := 32
## The backglass's picture.
const GLASS_PIXELS := Vector2i(1024, 576)
const FONT := preload("res://assets/fonts/BarlowCondensed-Black.ttf")
const GROUND := Color("#2A2137")
const RAYS := Color("#3A2D4C")
const TEAL := Color("#1F414E")
const OCHRE := Color("#C4943F")
const CREAM := Color("#E7DABA")
const INK := Color("#141017")
## The pool of light round an insert: a coin's blue, an item's warm white.
const COIN_POOL := Color("#5C8FD6")
const ITEM_POOL := Color("#F0C77A")
## The windows of the backglass in the seats' colors, the first four.
const SEATS: Array[Color] = [Color("#E23D3D"), Color("#3D6FE2"), Color("#F2D23D"), Color("#43C463")]

var print_kind := Print.FIELD
var grid: ArenaGrid


## The playfield's art for [param on].
static func field(on: ArenaGrid) -> PinballPrints:
	var art := PinballPrints.new()
	art.grid = on
	art.print_kind = Print.FIELD
	return art


static func glass() -> PinballPrints:
	var art := PinballPrints.new()
	art.print_kind = Print.GLASS
	return art


## The size of the playfield's picture for [param on].
static func field_pixels(on: ArenaGrid) -> Vector2i:
	return Vector2i(on.width * CELL_PIXELS, on.height * CELL_PIXELS)


func _draw() -> void:
	if print_kind == Print.GLASS:
		_glass()
	elif grid != null:
		_field()


# --- the playfield ---------------------------------------------------------------


func _field() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), GROUND)
	var middle := size * 0.5
	var radius := CELL_PIXELS * 2.0
	if not grid.junctions.is_empty():
		var rect: Rect2i = grid.junctions[0]
		middle = (Vector2(rect.position) + Vector2(rect.size) * 0.5) * CELL_PIXELS
		radius = rect.size.x * 0.5 * CELL_PIXELS
	_sunburst(middle, radius * 1.4, minf(size.x, size.y) * 0.62)
	_band()
	for rect: Rect2i in grid.jackpots:
		var at := (Vector2(rect.position) + Vector2(rect.size) * 0.5) * CELL_PIXELS
		_starburst(at, rect.size.x * 0.75 * CELL_PIXELS, rect.size.x * 1.05 * CELL_PIXELS)
	# The medallion the Junction stands in, under the House's terms round it.
	var medallion := radius + CELL_PIXELS * 1.3
	draw_circle(middle, medallion + 3.0, INK)
	draw_circle(middle, medallion, TEAL)
	draw_arc(middle, medallion - 5.0, 0.0, TAU, 96, Color(OCHRE, 0.7), 2.0, true)
	_sparkles()
	for cell: Vector2i in grid.coin_pads:
		_pool(_at(cell), CELL_PIXELS * 1.1, COIN_POOL, 0.22)
	for cell: Vector2i in grid.power_pads:
		_pool(_at(cell), CELL_PIXELS * 1.4, ITEM_POOL, 0.2)


## Rays fanning out from the Junction, a shade off the ground and fading as they go.
func _sunburst(at: Vector2, from: float, reach: float) -> void:
	var rays := 36
	for i: int in rays:
		if i % 2 == 1:
			continue
		var a := TAU * float(i) / float(rays)
		var b := TAU * float(i + 1) / float(rays)
		var points := PackedVector2Array(
			[
				at + Vector2.from_angle(a) * from,
				at + Vector2.from_angle(a) * reach,
				at + Vector2.from_angle(b) * reach,
				at + Vector2.from_angle(b) * from,
			]
		)
		var colors := PackedColorArray([RAYS, Color(RAYS, 0.0), Color(RAYS, 0.0), RAYS])
		draw_polygon(points, colors)


## The teal band round the field, inside the House's rail, its inside corners rounded as a
## printer's mask is and keylined in ink, with a run of ochre stars along its top and its foot.
func _band() -> void:
	var outer := Rect2(Vector2.ONE * CELL_PIXELS, size - Vector2.ONE * CELL_PIXELS * 2.0)
	var inner := outer.grow(-CELL_PIXELS * 0.95)
	var corner := CELL_PIXELS * 0.9
	draw_rect(outer, TEAL)
	draw_rect(inner, GROUND)
	var a := inner.position
	var b := inner.end
	for line: Array in [
		[Vector2(a.x + corner, a.y), Vector2(b.x - corner, a.y)],
		[Vector2(a.x + corner, b.y), Vector2(b.x - corner, b.y)],
		[Vector2(a.x, a.y + corner), Vector2(a.x, b.y - corner)],
		[Vector2(b.x, a.y + corner), Vector2(b.x, b.y - corner)],
	]:
		draw_line(line[0], line[1], INK, 3.0, true)
	for i: int in 4:
		var at := Vector2(a.x if i % 2 == 0 else b.x, a.y if i < 2 else b.y)
		var toward := Vector2(1.0 if i % 2 == 0 else -1.0, 1.0 if i < 2 else -1.0)
		var square := Rect2(at, Vector2.ZERO).expand(at + toward * corner)
		draw_rect(square, TEAL)
		var middle := at + toward * corner
		draw_circle(middle, corner, GROUND)
		var facing := (-toward).angle()
		draw_arc(middle, corner, facing - PI * 0.25, facing + PI * 0.25, 10, INK, 3.0, true)
	for k: int in 40:
		var x := lerpf(outer.position.x, outer.end.x, (float(k) + 0.5) / 40.0)
		_star(Vector2(x, outer.position.y + CELL_PIXELS * 0.45), 3.0, Color(OCHRE, 0.55))
		_star(Vector2(x, outer.end.y - CELL_PIXELS * 0.45), 3.0, Color(OCHRE, 0.55))


## An ochre starburst behind a Jackpot, spikes out from [param inner] to [param outer].
func _starburst(at: Vector2, inner: float, outer: float) -> void:
	var spikes := 16
	var points := PackedVector2Array()
	for i: int in spikes * 2:
		var reach := outer if i % 2 == 0 else inner
		points.append(at + Vector2.from_angle(TAU * float(i) / float(spikes * 2)) * reach)
	draw_colored_polygon(points, Color(OCHRE, 0.3))


## Sparkles in the open floor, a few to a quarter of the field, where nothing else is.
func _sparkles() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = grid.width * 131 + grid.height
	var count := grid.width * grid.height / 30
	for i: int in count:
		var cell := Vector2i(
			rng.randi_range(2, grid.width - 3), rng.randi_range(2, grid.height - 3)
		)
		if not _clear(cell):
			continue
		var at := (
			_at(cell)
			+ Vector2(rng.randf_range(-0.3, 0.3), rng.randf_range(-0.3, 0.3)) * CELL_PIXELS
		)
		var ink := OCHRE if rng.randf() < 0.65 else CREAM
		_star(at, rng.randf_range(3.0, 6.0), Color(ink, 0.5))


## Whether [param cell] and the cells round it are open floor, for a sparkle to sit in.
func _clear(cell: Vector2i) -> bool:
	for dx: int in range(-1, 2):
		for dy: int in range(-1, 2):
			if grid.glyph(cell + Vector2i(dx, dy)) != ArenaGrid.FLOOR:
				return false
	return true


## A four-pointed sparkle.
func _star(at: Vector2, reach: float, ink: Color) -> void:
	var points := PackedVector2Array()
	for i: int in 8:
		var r := reach if i % 2 == 0 else reach * 0.3
		points.append(at + Vector2.from_angle(PI * 0.25 * float(i) - PI * 0.5) * r)
	draw_colored_polygon(points, ink)


## The warm pool an insert's bulb throws on the coat round it, soft at its edge.
func _pool(at: Vector2, reach: float, light: Color, strength: float) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var sides := 32
	points.append(at)
	colors.append(Color(light, strength))
	for i: int in sides + 1:
		points.append(at + Vector2.from_angle(TAU * float(i) / float(sides)) * reach)
		colors.append(Color(light, 0.0))
	for i: int in sides:
		draw_polygon(
			PackedVector2Array([points[0], points[i + 1], points[i + 2]]),
			PackedColorArray([colors[0], colors[i + 1], colors[i + 2]])
		)


func _at(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2.ONE * 0.5) * CELL_PIXELS


# --- the backglass ---------------------------------------------------------------


func _glass() -> void:
	var bands := 24
	for i: int in bands:
		var t := float(i) / float(bands - 1)
		var band := Rect2(
			0.0, size.y * float(i) / float(bands), size.x, size.y / float(bands) + 1.0
		)
		draw_rect(band, Color("#3A2140").lerp(Color("#140B18"), t))
	var wheel := Vector2(size.x * 0.5, size.y * 0.56)
	_sunburst_glass(wheel)
	_wheel(wheel, size.y * 0.2)
	_title(Vector2(size.x * 0.5, size.y * 0.25), size.x * 0.9)
	var windows := 4
	var wide := size.x * 0.16
	for i: int in windows:
		var x := size.x * (0.5 + (float(i) - 1.5) * 0.205)
		_score(Rect2(x - wide * 0.5, size.y * 0.86, wide, size.y * 0.09), SEATS[i], i)
	_lamp_window(Rect2(size.x * 0.05, size.y * 0.5, size.x * 0.17, size.y * 0.12), "GAME OVER")
	_lamp_window(Rect2(size.x * 0.78, size.y * 0.5, size.x * 0.17, size.y * 0.12), "TILT")
	var line := "SAME PLAYER SHOOTS AGAIN"
	var font_size := int(size.y * 0.04)
	var width := FONT.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var spot := Vector2(size.x * 0.5 - width * 0.5, size.y * 0.81)
	draw_string(FONT, spot, line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#6B3A3A"))
	var edge := Rect2(Vector2.ONE * 8.0, size - Vector2.ONE * 16.0)
	draw_rect(edge, Color(OCHRE, 0.8), false, 3.0)
	draw_rect(edge.grow(-8.0), Color(CREAM, 0.35), false, 1.5)


func _sunburst_glass(at: Vector2) -> void:
	var rays := 28
	for i: int in rays:
		if i % 2 == 1:
			continue
		var a := TAU * float(i) / float(rays)
		var b := TAU * float(i + 1) / float(rays)
		var reach := size.x * 0.7
		var points := PackedVector2Array(
			[at, at + Vector2.from_angle(a) * reach, at + Vector2.from_angle(b) * reach]
		)
		draw_polygon(
			points, PackedColorArray([Color(OCHRE, 0.28), Color(OCHRE, 0.0), Color(OCHRE, 0.0)])
		)


## The wheel under the name: a walnut rim, muted pockets and a brass middle.
func _wheel(at: Vector2, radius: float) -> void:
	draw_circle(at, radius + 6.0, INK)
	draw_circle(at, radius, Color("#5A3424"))
	var pockets := 24
	for i: int in pockets:
		var a := TAU * float(i) / float(pockets)
		var b := TAU * float(i + 1) / float(pockets)
		var ink := Color("#2F6B4E") if i == 0 else (Color("#9A3C34") if i % 2 == 1 else INK)
		var points := PackedVector2Array(
			[
				at + Vector2.from_angle(a) * radius * 0.62,
				at + Vector2.from_angle(a) * radius * 0.9,
				at + Vector2.from_angle(b) * radius * 0.9,
				at + Vector2.from_angle(b) * radius * 0.62,
			]
		)
		draw_colored_polygon(points, ink)
	draw_circle(at, radius * 0.6, Color("#3B2741"))
	for i: int in 4:
		var turn := PI * 0.25 + PI * 0.5 * float(i)
		draw_line(at, at + Vector2.from_angle(turn) * radius * 0.55, OCHRE, 5.0, true)
	draw_circle(at, radius * 0.12, OCHRE)


## JACKPOT JUNCTION arched over the wheel, its middle at [param top] on an arch [param arc]
## round, cream with an ink edge and an ochre shadow.
func _title(top: Vector2, arc: float) -> void:
	var text := "JACKPOT JUNCTION"
	var font_size := int(size.y * 0.15)
	var widths: Array[float] = []
	var total := 0.0
	for letter: String in text:
		var width := FONT.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		widths.append(width)
		total += width
	var wheel := top + Vector2(0.0, arc)
	var angle := -PI * 0.5 - total / arc * 0.5
	for i: int in text.length():
		var step := widths[i] / arc
		var at_angle := angle + step * 0.5
		var at := wheel + Vector2.from_angle(at_angle) * arc
		draw_set_transform(at, at_angle + PI * 0.5)
		var spot := Vector2(-widths[i] * 0.5, font_size * 0.35)
		draw_string_outline(FONT, spot + Vector2(3.0, 4.0), text[i], 0, -1, font_size, 8, OCHRE)
		draw_string_outline(FONT, spot, text[i], 0, -1, font_size, 8, INK)
		draw_string(FONT, spot, text[i], 0, -1, font_size, CREAM)
		draw_set_transform(Vector2.ZERO)
		angle += step


## A seat's score window: a dark window framed in its color with its score in it.
func _score(rect: Rect2, ink: Color, seat: int) -> void:
	draw_rect(rect.grow(4.0), INK)
	draw_rect(rect, Color("#0B080D"))
	draw_rect(rect, ink, false, 3.0)
	var font_size := int(rect.size.y * 0.78)
	var text := "%d %03d" % [seat + 1, (seat * 370 + 250) % 1000]
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var spot := rect.get_center() + Vector2(-width * 0.5, font_size * 0.36)
	draw_string(FONT, spot, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)


## A window the machine lights between games, dark.
func _lamp_window(rect: Rect2, words: String) -> void:
	draw_rect(rect.grow(3.0), INK)
	draw_rect(rect, Color("#24161F"))
	var font_size := int(rect.size.y * 0.5)
	var width := FONT.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var spot := rect.get_center() + Vector2(-width * 0.5, font_size * 0.36)
	draw_string(FONT, spot, words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#6B3A3A"))
