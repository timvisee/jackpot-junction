class_name Heart
extends Control
## A heart, for the lives under each player's name, GAME.md 8.3.
##
## Drawn rather than loaded, like everything else on this HUD: it takes the player's color for
## free, it is sharp at any size, and it weighs nothing. The outline is the usual heart curve
## rather than two circles over a triangle, which gives it the dip at the top and the point at
## the bottom that make the shape read at eighteen pixels.

## How many points the curve is walked in. Enough that the shoulders are round rather than
## faceted at the size a pip is drawn.
const POINTS := 56
## The crack a broken one comes apart along, top to bottom in the unit box. It wanders either
## side of the middle because a straight cut reads as a notch rather than as a break.
const CRACK: Array[Vector2] = [
	Vector2(0.5, -0.2),
	Vector2(0.58, 0.14),
	Vector2(0.44, 0.33),
	Vector2(0.58, 0.52),
	Vector2(0.45, 0.7),
	Vector2(0.52, 1.2)
]
## How far each half is turned away from the break, where it turns about, and how far it slides.
const BREAK_DEGREES := 12.0
const HINGE := Vector2(0.5, 0.78)
const BREAK_GAP := 0.05

## The curve normalized into the unit box, worked out once and shared: every heart on the screen
## is the same shape at a different size.
static var _unit: PackedVector2Array = []

var color := Color.WHITE:
	set(value):
		if value == color:
			return
		color = value
		queue_redraw()


func _draw() -> void:
	var side := minf(size.x, size.y)
	var at := (size - Vector2(side, side)) * 0.5
	var points := PackedVector2Array()
	for step: Vector2 in unit_shape():
		points.append(at + step * side)
	draw_colored_polygon(points, color)


## The same heart in two halves tipped apart: a life lost. The break is jagged rather than a
## straight cut, which is the difference between a broken heart and a heart with a notch in it,
## and each half is turned away from it so the crack opens.
static func broken_shapes() -> Array[PackedVector2Array]:
	var whole := unit_shape()
	var halves: Array[PackedVector2Array] = []
	for side: float in [-1.0, 1.0]:
		var knife := PackedVector2Array(CRACK)
		# Everything on one side of the crack: the seam itself, then out past the edge and back.
		var far := 1.4 if side > 0.0 else -0.4
		knife.append(Vector2(far, 1.2))
		knife.append(Vector2(far, -0.2))
		for piece: PackedVector2Array in Geometry2D.intersect_polygons(whole, knife):
			halves.append(_tipped(piece, side))
	return halves


## One half turned away from the break and slid clear of it, about the point the two came apart.
static func _tipped(piece: PackedVector2Array, side: float) -> PackedVector2Array:
	var turned := PackedVector2Array()
	for point: Vector2 in piece:
		var spun := (point - HINGE).rotated(deg_to_rad(BREAK_DEGREES * side))
		turned.append(HINGE + spun + Vector2(BREAK_GAP * side, 0.0))
	return turned


## The heart in the unit box, with y downwards: (0, 0) its top left, (1, 1) its bottom right.
static func unit_shape() -> PackedVector2Array:
	if not _unit.is_empty():
		return _unit
	var raw := PackedVector2Array()
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for i: int in POINTS:
		var t := TAU * i / float(POINTS)
		# The classic heart curve. Its y runs upwards, so it is negated into screen space here.
		var x := 16.0 * pow(sin(t), 3.0)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		raw.append(Vector2(x, y))
		low = Vector2(minf(low.x, x), minf(low.y, y))
		high = Vector2(maxf(high.x, x), maxf(high.y, y))
	var span := high - low
	for point: Vector2 in raw:
		_unit.append((point - low) / Vector2(maxf(span.x, 0.001), maxf(span.y, 0.001)))
	return _unit
