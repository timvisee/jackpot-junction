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
const POINTS := 60
## The deck's heart, as the suits draw it: where it starts, at its point, and its curves from there,
## each two handles and its end, in a box as wide as the heart and [constant SHAPE_TALL] of that
## tall.
const SHAPE_FROM := Vector2(0.5, 0.92)
const SHAPE: Array[Array] = [
	[Vector2(0.17, 0.68), Vector2(0.0, 0.5), Vector2(0.0, 0.29)],
	[Vector2(0.0, 0.12), Vector2(0.13, 0.0), Vector2(0.29, 0.0)],
	[Vector2(0.39, 0.0), Vector2(0.46, 0.05), Vector2(0.5, 0.13)],
	[Vector2(0.54, 0.05), Vector2(0.61, 0.0), Vector2(0.71, 0.0)],
	[Vector2(0.87, 0.0), Vector2(1.0, 0.12), Vector2(1.0, 0.29)],
	[Vector2(1.0, 0.5), Vector2(0.83, 0.68), Vector2(0.5, 0.92)],
]
const SHAPE_TALL := 0.92
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
	# The deck's heart, the suits' drawing of GAME.md 8.3a: its six curves walked a few points each,
	# as wide as the box and as tall as its shape is, in the middle of the box's height.
	var from := SHAPE_FROM
	var steps := POINTS / SHAPE.size()
	for curve: Array in SHAPE:
		for step: int in steps:
			var t := float(step) / steps
			var u := 1.0 - t
			var point: Vector2 = (
				from * u * u * u
				+ (curve[0] as Vector2) * 3.0 * u * u * t
				+ (curve[1] as Vector2) * 3.0 * u * t * t
				+ (curve[2] as Vector2) * t * t * t
			)
			_unit.append(point + Vector2(0.0, (1.0 - SHAPE_TALL) * 0.5))
		from = curve[2]
	return _unit
