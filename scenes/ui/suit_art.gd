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
##
## The outline is a ring of its own round the shape rather than a thick line along its edge: the
## shape grown outward, round at the corners, with the shape taken out of it. A line along the edge
## stood out in a spike past every sharp point, and the half of it inside the shape showed through
## a see-through fill as a second, grayer rim.

enum Suit { SPADE, HEART, DIAMOND, CLUB }

const OUTLINE := Color(0.05, 0.05, 0.06)
## How many points go round a heart's curve, and a spade's, which is a heart turned over, and
## round each of a club's balls.
const CURVE_POINTS := 64
const BALL_POINTS := 40
## How big a unit square is made while a suit is grown into its ring: the corners are rounded only
## to a quarter of a unit, which in a unit square is no rounding at all.
const WORK_SCALE := 100.0
## How wide the line that softens the ring's edges is, in pixels.
const SOFT_EDGE := 1.0

## Each suit's single outline in a unit square, worked out the first time it is drawn, and its
## grown outline and ring for each width it has been drawn at.
static var _outlines: Dictionary[int, PackedVector2Array] = {}
static var _grown: Dictionary[Vector2i, PackedVector2Array] = {}
static var _rings: Dictionary[Vector2i, Array] = {}


## Draws [param suit] into [param box] on [param on] in [param ink], outlined [param edge] wide in
## [constant OUTLINE], or with no outline at 0. Any number is a suit: the fifth is a spade again.
static func draw_into(on: CanvasItem, box: Rect2, suit: int, ink: Color, edge := 0.0) -> void:
	suit %= Suit.size()
	var shape := _placed(outline(suit), box)
	on.draw_colored_polygon(shape, ink)
	if edge <= 0.0:
		return
	var width := edge / box.size.x
	for piece: PackedVector2Array in ring(suit, width):
		on.draw_colored_polygon(_placed(piece, box), OUTLINE)
	# A filled polygon has a hard, stepped edge, which at the size of a suit under the clock is
	# most of what there is to see of it: a thin line down both edges of the ring softens them.
	for edge_line: PackedVector2Array in [shape, _placed(grown(suit, width), box)]:
		var closed := edge_line.duplicate()
		closed.append(edge_line[0])
		on.draw_polyline(closed, OUTLINE, SOFT_EDGE, true)


## [param suit]'s outline grown outward by [param width] of a unit square, round at the corners.
static func grown(suit: int, width: float) -> PackedVector2Array:
	var key := Vector2i(suit, roundi(width * 100000.0))
	if not _grown.has(key):
		var work := _scaled(outline(suit), WORK_SCALE)
		var out := Geometry2D.offset_polygon(
			work, width * WORK_SCALE, Geometry2D.PolyJoinType.JOIN_ROUND
		)
		_grown[key] = _scaled(_largest(out), 1.0 / WORK_SCALE)
	return _grown[key]


## The ring round [param suit], [param width] of a unit square wide, as the pieces it is drawn in:
## cut down the middle, so that each half, with the suit taken out of it, has no hole in it,
## which is all a polygon can be drawn as.
static func ring(suit: int, width: float) -> Array:
	var key := Vector2i(suit, roundi(width * 100000.0))
	if _rings.has(key):
		return _rings[key]
	var inner := _scaled(outline(suit), WORK_SCALE)
	var outer := _scaled(grown(suit, width), WORK_SCALE)
	var middle := WORK_SCALE * 0.5
	var far := WORK_SCALE * 2.0
	var pieces: Array[PackedVector2Array] = []
	for half: Rect2 in [
		Rect2(-far, -far, middle + far, far * 2.0 + WORK_SCALE),
		Rect2(middle, -far, middle + far, far * 2.0 + WORK_SCALE),
	]:
		var cut := PackedVector2Array(
			[
				half.position,
				Vector2(half.end.x, half.position.y),
				half.end,
				Vector2(half.position.x, half.end.y)
			]
		)
		for part: PackedVector2Array in Geometry2D.intersect_polygons(outer, cut):
			for piece: PackedVector2Array in Geometry2D.clip_polygons(part, inner):
				pieces.append(_scaled(piece, 1.0 / WORK_SCALE))
	_rings[key] = pieces
	return pieces


static func _scaled(polygon: PackedVector2Array, by: float) -> PackedVector2Array:
	var scaled := PackedVector2Array()
	for point: Vector2 in polygon:
		scaled.append(point * by)
	return scaled


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
