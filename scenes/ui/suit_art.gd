class_name SuitArt
extends RefCounted
## The four card suits, GAME.md 3.9: one on each Royal Flush pad, the four a flush collects. Drawn
## rather than taken from a font, so all four are the same size and weight, and each can carry an
## outline of its own to read on a pad in whatever color its holder has painted it.
##
## A spade is a heart turned over on a stem and a club is three balls on a foot, but each is drawn
## as one shape: the pieces are merged into a single outline first. Drawn see-through, as a suit
## nobody holds is under the clock, pieces drawn one over another showed the stem through the
## spade and every ball's edge through the club.

enum Suit { SPADE, HEART, DIAMOND, CLUB }

const OUTLINE := Color(0.05, 0.05, 0.06)
## How many points go round a heart's curve, and a spade's, which is a heart turned over, and
## round each of a club's balls.
const CURVE_POINTS := 64
const BALL_POINTS := 40

## Each suit's single outline in a unit square, worked out the first time it is drawn.
static var _outlines: Dictionary[int, PackedVector2Array] = {}


## Draws [param suit] into [param box] on [param on] in [param ink], outlined [param edge] wide in
## [constant OUTLINE], or with no outline at 0. Any number is a suit: the fifth is a spade again.
static func draw_into(on: CanvasItem, box: Rect2, suit: int, ink: Color, edge := 0.0) -> void:
	var placed := _placed(outline(suit % Suit.size()), box)
	if edge > 0.0:
		var closed := placed.duplicate()
		closed.append(placed[0])
		on.draw_polyline(closed, OUTLINE, edge * 2.0, true)
	on.draw_colored_polygon(placed, ink)


## [param suit]'s outline in a unit square: its pieces merged into the one shape.
static func outline(suit: int) -> PackedVector2Array:
	if _outlines.has(suit):
		return _outlines[suit]
	var shape := _shape(suit)
	var pieces: Array = shape[0].duplicate()
	for disc: Vector3 in shape[1]:
		pieces.append(_ball(disc))
	var whole: PackedVector2Array = pieces[0]
	for piece: PackedVector2Array in pieces.slice(1):
		whole = _largest(Geometry2D.merge_polygons(whole, piece))
	_outlines[suit] = whole
	return whole


## The biggest of [param polygons], which is the outside of a merge: anything else it gives back
## is a hole, and these suits have none worth drawing.
static func _largest(polygons: Array[PackedVector2Array]) -> PackedVector2Array:
	var best := PackedVector2Array()
	var most := -1.0
	for polygon: PackedVector2Array in polygons:
		var area := 0.0
		for i: int in polygon.size():
			area += polygon[i].cross(polygon[(i + 1) % polygon.size()])
		if absf(area) > most:
			most = absf(area)
			best = polygon
	return best


## A ball of [param disc], its center and radius, as a polygon.
static func _ball(disc: Vector3) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in BALL_POINTS:
		var angle := TAU * i / BALL_POINTS
		points.append(Vector2(disc.x, disc.y) + Vector2(cos(angle), sin(angle)) * disc.z)
	return points


## [param suit] in a unit square: the polygons it is made of, and its discs as a center and a
## radius.
static func _shape(suit: int) -> Array:
	match suit:
		Suit.SPADE:
			var stem := PackedVector2Array(
				[Vector2(0.5, 0.5), Vector2(0.34, 0.94), Vector2(0.66, 0.94)]
			)
			return [[stem, _heart(0.42, 0.38, true)], []]
		Suit.HEART:
			return [[_heart(0.44, 0.42, false)], []]
		Suit.DIAMOND:
			var points := [
				Vector2(0.5, 0.04), Vector2(0.84, 0.5), Vector2(0.5, 0.96), Vector2(0.16, 0.5)
			]
			return [[PackedVector2Array(points)], []]
	var foot := PackedVector2Array([Vector2(0.5, 0.45), Vector2(0.35, 0.94), Vector2(0.65, 0.94)])
	return [
		[foot],
		# And one in the middle, over the gap the three leave between them.
		[
			Vector3(0.5, 0.29, 0.2),
			Vector3(0.28, 0.57, 0.2),
			Vector3(0.72, 0.57, 0.2),
			Vector3(0.5, 0.5, 0.13),
		],
	]


## A heart in a unit square, its middle at [param middle] down and [param reach] of it tall either
## way, or, [param over], turned over into the body of a spade.
static func _heart(middle: float, reach: float, over: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in CURVE_POINTS:
		var t := TAU * i / CURVE_POINTS
		var x := 16.0 * pow(sin(t), 3)
		var y := 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		points.append(Vector2(0.5 + x / 16.0 * 0.46, middle + (y if over else -y) / 17.0 * reach))
	return points


static func _placed(polygon: PackedVector2Array, box: Rect2) -> PackedVector2Array:
	var placed := PackedVector2Array()
	for point: Vector2 in polygon:
		placed.append(_at(box, point.x, point.y))
	return placed


static func _at(box: Rect2, x: float, y: float) -> Vector2:
	return box.position + Vector2(x, y) * box.size
