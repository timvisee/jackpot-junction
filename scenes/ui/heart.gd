class_name Heart
extends Control
## A heart, for the lives under each player's name, GAME.md 8.3.
##
## Drawn rather than loaded, like everything else on this HUD: it takes the player's colour for
## free, it is sharp at any size, and it weighs nothing. The outline is the usual heart curve
## rather than two circles over a triangle, which gives it the dip at the top and the point at
## the bottom that make the shape read at eighteen pixels.

## How many points the curve is walked in. Enough that the shoulders are round rather than
## faceted at the size a pip is drawn.
const POINTS := 56

## The curve normalised into the unit box, worked out once and shared: every heart on the screen
## is the same shape at a different size.
static var _unit: PackedVector2Array = []

var color := Color.WHITE:
	set(value):
		color = value
		queue_redraw()


func _draw() -> void:
	var side := minf(size.x, size.y)
	var at := (size - Vector2(side, side)) * 0.5
	var points := PackedVector2Array()
	for step: Vector2 in unit_shape():
		points.append(at + step * side)
	draw_colored_polygon(points, color)


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
