class_name SupporterBacks
extends RefCounted
## The supporter pack's card backs, GAME.md 10.8, drawn as the game's other backs are, see
## [CardBack], on the same board and rim, with the engraving of [Engraving]: Beacon, a lighthouse
## on its rock over an engraved sea, its beam across a night of stars and rings of light round its
## lamp; Constellation, the house's lattice drawn as a star chart round a bright star in engraved
## rings; and Aurora, the engraved waves every back has, lit as curtains of teal and violet light
## under a few stars. Each drawn in a card's own measures, [constant JokerCard.SIZE].

## The backs in [constant CardBack.STYLES] order, from where the pack's begin.
const NAMES: Array[String] = ["Beacon", "Constellation", "Aurora"]  # NO_TRANSLATE
## The cream the engraving and the stars are in, the starlight of the chart, the lamp's warm light,
## the lighthouse's red, its rock and its iron, and the aurora's two colors.
const CREAM := Color(0.95, 0.9, 0.78)
const STARLIGHT := Color(0.85, 0.88, 1.0)
const LAMP := Color(1.0, 0.88, 0.6)
const BEAM := Color(1.0, 0.9, 0.65)
const RED := Color(0.76, 0.22, 0.2)
const ROCK := Color(0.16, 0.17, 0.22)
const IRON := Color(0.15, 0.15, 0.18)
const TEAL := Color(0.35, 0.95, 0.75)
const VIOLET := Color(0.65, 0.45, 1.0)


## Back [param kind] of [constant NAMES] drawn on [param on] in a card's measures, its lines as
## strong as [param lines] says, as the other backs' are, see [member CardBack.Face.lines].
static func draw(on: CanvasItem, kind: int, lines: float) -> void:
	var inset := JokerCard.INSET + 1.0
	var inner := Rect2(Vector2.ONE * inset, JokerCard.SIZE - Vector2.ONE * inset * 2.0)
	var box := CardBack.inside_outline()
	# The other backs' lines are a whisper; these are pictures, a little stronger, and stronger
	# again where the backs are drawn for the table, far off.
	var strength := clampf(lines / CardBack.ENGRAVED, 1.0, 3.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21 + kind
	match kind:
		0:
			_beacon(on, inner, box, strength, rng)
		1:
			_constellation(on, inner, box, strength, rng)
		2:
			_aurora(on, inner, box, strength, rng)


## A four-pointed twinkle at [param at], [param reach] out, in [param ink].
static func star(on: CanvasItem, at: Vector2, reach: float, ink: Color) -> void:
	on.draw_line(at - Vector2(reach, 0.0), at + Vector2(reach, 0.0), ink, 0.5, true)
	on.draw_line(at - Vector2(0.0, reach), at + Vector2(0.0, reach), ink, 0.5, true)
	on.draw_circle(at, reach * 0.28, ink)


static func _beacon(
	on: CanvasItem,
	inner: Rect2,
	box: PackedVector2Array,
	strength: float,
	rng: RandomNumberGenerator
) -> void:
	var middle := JokerCard.SIZE.x * 0.5
	for i: int in 26:
		var at := Vector2(
			rng.randf_range(inner.position.x + 3.0, inner.end.x - 3.0),
			rng.randf_range(inner.position.y + 3.0, 100.0)
		)
		var big := rng.randf() < 0.2
		star(
			on, at, 2.2 if big else 1.1, Color(CREAM, minf((0.75 if big else 0.45) * strength, 1.0))
		)
	# The lamp in the middle of its room, under the roof; its two beams out either side of it, level
	# and alike, from behind the lamp room.
	var lamp := Vector2(middle, 68.0)
	var rings := Engraving.inside(Engraving.rings(lamp, 22.0, 2.5, 10, 8, 160), box)
	Engraving.draw_on(on, rings, Color(LAMP, minf(0.3 * strength, 1.0)), 0.7)
	var far := Color(BEAM, 0.0)
	for edge: float in [inner.position.x, inner.end.x]:
		on.draw_polygon(
			PackedVector2Array([lamp, Vector2(edge, lamp.y - 10.0), Vector2(edge, lamp.y + 8.0)]),
			PackedColorArray([Color(BEAM, 0.45), far, far])
		)
	var sea := Rect2(inner.position.x, 118.0, inner.size.x, inner.end.y - 118.0)
	var waves := Engraving.inside(Engraving.waves(sea, 3.6, 1.6, 26.0, 0.6, 3.0), box)
	Engraving.draw_on(on, waves, Color(CREAM, minf(0.42 * strength, 1.0)), 0.7)
	on.draw_colored_polygon(
		PackedVector2Array(
			[Vector2(38.0, 128.0), Vector2(46.0, 118.0), Vector2(74.0, 117.0), Vector2(84.0, 128.0)]
		),
		ROCK
	)
	var bands := 4
	for band: int in bands:
		var foot := 118.0 - band * 11.0
		var wide_foot := lerpf(9.0, 6.0, float(band) / bands)
		var wide_head := lerpf(9.0, 6.0, float(band + 1) / bands)
		(
			on
			. draw_colored_polygon(
				PackedVector2Array(
					[
						Vector2(middle - wide_foot, foot),
						Vector2(middle + wide_foot, foot),
						Vector2(middle + wide_head, foot - 11.0),
						Vector2(middle - wide_head, foot - 11.0),
					]
				),
				RED if band % 2 == 0 else CREAM
			)
		)
	on.draw_rect(Rect2(middle - 8.0, 72.0, 16.0, 2.5), IRON)
	on.draw_rect(Rect2(middle - 5.0, 64.0, 10.0, 8.0), LAMP)
	on.draw_circle(lamp, 7.0, Color(LAMP, 0.25))
	on.draw_colored_polygon(
		PackedVector2Array(
			[Vector2(middle - 6.5, 64.0), Vector2(middle + 6.5, 64.0), Vector2(middle, 56.0)]
		),
		RED
	)
	on.draw_circle(Vector2(middle, 55.5), 1.2, IRON)


static func _constellation(
	on: CanvasItem,
	inner: Rect2,
	box: PackedVector2Array,
	strength: float,
	rng: RandomNumberGenerator
) -> void:
	var lattice: Array[PackedVector2Array] = []
	var gap := 17.0
	for i: int in range(-12, 14):
		var x := inner.position.x + i * gap
		lattice.append(
			PackedVector2Array(
				[Vector2(x, inner.position.y), Vector2(x + inner.size.y * 0.75, inner.end.y)]
			)
		)
		lattice.append(
			PackedVector2Array(
				[Vector2(x, inner.position.y), Vector2(x - inner.size.y * 0.75, inner.end.y)]
			)
		)
	Engraving.draw_on(
		on, Engraving.inside(lattice, box), Color(STARLIGHT, minf(0.16 * strength, 1.0)), 0.6
	)
	var down := gap / 1.5 * 0.75
	var row := 0
	var y := inner.position.y + gap / 3.0
	while y < inner.end.y:
		var x := inner.position.x + (gap * 0.5 if row % 2 == 1 else 0.0)
		while x < inner.end.x:
			if Geometry2D.is_point_in_polygon(Vector2(x, y), box):
				if rng.randf() < 0.18:
					star(on, Vector2(x, y), 2.4, Color(STARLIGHT, 0.85))
				else:
					on.draw_circle(Vector2(x, y), 0.7, Color(STARLIGHT, 0.5))
			x += gap
		y += down
		row += 1
	var middle := JokerCard.SIZE * 0.5
	on.draw_circle(middle, 25.0, CardBack.BOARDS[CardBack.STYLES.find(NAMES[1])])
	var rings := Engraving.rings(middle, 20.0, 3.0, 12, 10, 200)
	Engraving.draw_on(on, rings, Color(STARLIGHT, minf(0.42 * strength, 1.0)), 0.7)
	star(on, middle, 9.0, Color(1.0, 0.97, 0.9, 0.95))
	on.draw_circle(middle, 5.0, Color(1.0, 0.95, 0.85, 0.25))


static func _aurora(
	on: CanvasItem,
	inner: Rect2,
	box: PackedVector2Array,
	strength: float,
	rng: RandomNumberGenerator
) -> void:
	var waves := Engraving.inside(Engraving.waves(inner, 3.2, 2.4, 40.0, 0.35, 2.5), box)
	for line: PackedVector2Array in waves:
		var inks := PackedColorArray()
		for point: Vector2 in line:
			var down := clampf((point.y - inner.position.y) / inner.size.y, 0.0, 1.0)
			var curtain := 0.5 + 0.5 * sin(point.x * 0.11 + sin(point.y * 0.05) * 2.0)
			var band := smoothstep(0.1, 0.35, down) * (1.0 - smoothstep(0.7, 0.95, down))
			var light := minf(((0.12 + 0.55 * curtain) * band + 0.05) * strength, 1.0)
			inks.append(Color(TEAL.lerp(VIOLET, down), light))
		on.draw_polyline_colors(line, inks, 0.7, true)
	for i: int in 18:
		var at := Vector2(
			rng.randf_range(inner.position.x + 3.0, inner.end.x - 3.0),
			rng.randf_range(inner.position.y + 3.0, 50.0)
		)
		var big := rng.randf() < 0.2
		star(on, at, 2.0 if big else 1.0, Color(CREAM, 0.7 if big else 0.4))
	var rings := Engraving.rings(JokerCard.SIZE * 0.5, 16.0, 2.0, 10, 8, 160)
	Engraving.draw_on(on, rings, Color(CREAM, minf(0.35 * strength, 1.0)), 0.6)
