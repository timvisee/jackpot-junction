class_name FeltArt
extends RefCounted
## The green felt the achievements are kept on, GAME.md 8.10: a card table's cloth rather than a
## flat green, its nap mottled lighter and darker in soft patches, a fine grain over that, and short
## fibers lying every which way; and what is printed on it in cream, as a table's layout is: a line
## round the rows with the table's motto in its foot, and the buttons, see [FeltPrintStyle]. Drawn
## from two seamless noise textures made once a run and a scatter of fibers the same every time, so
## it costs a few draws however big it is, and only as it is laid out again.

## The felt, and the ink printed on it.
const CLOTH := Palette.FELT
const PRINT := Color(0.94, 0.89, 0.74, 0.72)
## How big the noise textures are, tiled over the cloth, and how strongly each shows: the patches
## darker, the grain lighter.
const TILE := 256
const PATCHES := 0.32
const GRAIN := 0.14
## How many fibers a square of cloth this many pixels on a side has, and how long they are.
const FIBER_SQUARE := 34.0
const FIBER_SHORTEST := 2.0
const FIBER_LONGEST := 6.0
## The printed line's two strokes, a heavy one and a fine one inside it: how far in each is, how
## round its corners are, how thick it is and how strong its ink; and the room either side of the
## words in its foot.
const LINES: Array[Array] = [[1.0, 14.0, 2.0, 1.0], [5.0, 10.0, 1.0, 0.75]]
const WORDS_ROOM := 14.0
## How many points each corner of a [method rounded] outline has.
const CORNER_STEPS := 12

static var _patches: Texture2D
static var _grain: Texture2D


## The soft patches of the nap, a seamless tile.
static func patches() -> Texture2D:
	if _patches == null:
		_patches = _noise(0.012, 3, 7)
	return _patches


## The fine grain over it, a seamless tile.
static func grain() -> Texture2D:
	if _grain == null:
		_grain = _noise(0.45, 1, 23)
	return _grain


static func _noise(frequency: float, octaves: int, seed_of: int) -> Texture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.fractal_octaves = octaves
	noise.seed = seed_of
	return ImageTexture.create_from_image(noise.get_seamless_image(TILE, TILE))


## Cloth of [param cloth] over [param rect] on [param on]: its nap, its grain and its fibers.
static func cloth(on: CanvasItem, rect: Rect2, cloth_ink: Color, seed_of := 1) -> void:
	on.draw_rect(rect, cloth_ink)
	on.draw_texture_rect(patches(), rect, true, Color(cloth_ink.darkened(0.55), PATCHES))
	on.draw_texture_rect(grain(), rect, true, Color(cloth_ink.lightened(0.45), GRAIN))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_of
	var fibers := int(rect.size.x * rect.size.y / (FIBER_SQUARE * FIBER_SQUARE))
	var light := PackedVector2Array()
	var dark := PackedVector2Array()
	for i: int in fibers:
		var at := rect.position + Vector2(rng.randf() * rect.size.x, rng.randf() * rect.size.y)
		var way := (
			Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(FIBER_SHORTEST, FIBER_LONGEST)
		)
		var into := light if i % 3 != 0 else dark
		into.append(at)
		into.append(at + way)
	on.draw_multiline(light, Color(cloth_ink.lightened(0.5), 0.18), 1.0)
	on.draw_multiline(dark, Color(cloth_ink.darkened(0.6), 0.22), 1.0)


## A line printed on the felt just inside [param rect], a heavy stroke and a fine one inside it, as
## a blackjack table's layout is, broken in its foot for [param words] printed between its ends in
## the [param size] of [constant Type.STRONG].
static func print_line(on: CanvasItem, rect: Rect2, words: String, size: int) -> void:
	var font := Type.STRONG
	var wide := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var middle := rect.get_center().x
	var gap := Vector2(middle - wide * 0.5 - WORDS_ROOM, middle + wide * 0.5 + WORDS_ROOM)
	for stroke: Array in LINES:
		var inside := rect.grow(-stroke[0])
		var outline := rounded(inside, stroke[1])
		# From the left end of the gap in the foot, round, to its right end: the foot runs from the
		# bottom right corner's last point to the bottom left's first.
		var first := (CORNER_STEPS + 1) * 2 - 1
		var open := PackedVector2Array([Vector2(gap.x, inside.end.y)])
		for i: int in outline.size():
			open.append(outline[(first + 1 + i) % outline.size()])
		open.append(Vector2(gap.y, inside.end.y))
		on.draw_polyline(open, Color(PRINT, PRINT.a * stroke[3]), stroke[2], true)
	# On the middle of the two strokes' feet.
	var along := rect.end.y - (LINES[0][0] + LINES[1][0]) * 0.5
	var baseline := along + (font.get_ascent(size) - font.get_descent(size)) * 0.5
	on.draw_string(
		font,
		Vector2(middle - wide * 0.5, baseline),
		words,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		size,
		PRINT
	)


## The points round [param rect] with corners [param radius] round, clockwise from the top of the
## top right corner, each corner [constant CORNER_STEPS] steps and the sides straight between them.
static func rounded(rect: Rect2, radius: float) -> PackedVector2Array:
	var round_by := clampf(radius, 0.0, minf(rect.size.x, rect.size.y) * 0.5)
	var centers: Array[Vector2] = [
		Vector2(rect.end.x - round_by, rect.position.y + round_by),
		Vector2(rect.end.x - round_by, rect.end.y - round_by),
		Vector2(rect.position.x + round_by, rect.end.y - round_by),
		Vector2(rect.position.x + round_by, rect.position.y + round_by),
	]
	var line := PackedVector2Array()
	for corner: int in 4:
		for step: int in CORNER_STEPS + 1:
			var i := corner * (CORNER_STEPS + 1) + step
			line.append(centers[corner] + Vector2.from_angle(facing(i)) * round_by)
	return line


## Which way the [param i]th point of a [method rounded] outline faces, outward, as an angle.
static func facing(i: int) -> float:
	var corner := floori(i / float(CORNER_STEPS + 1))
	var step := i % (CORNER_STEPS + 1)
	return -PI * 0.5 + corner * PI * 0.5 + step * PI * 0.5 / CORNER_STEPS
