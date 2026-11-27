class_name NitroBottle
extends Range
## The nitro tank of a corner block, GAME.md 8.3 and 8.1a: the nitro bottle bent round the foot of
## the speed dial it shares its middle with, so dial and tank read as one gauge, as a car's fuel
## gauge sits under its speedometer. Dark glass rounded at its foot, filling from the left in the
## player's own color with the shadow side of the house print, marked off in tenths, a glint along
## it; it narrows over its shoulder into a neck, and a gas cylinder's valve stands straight off
## that, its outlet turned to the dial as if it fed it and its red hand wheel across its end. Amber
## while the bottle burns, as the dial's fill is, see [SpeedDial].
##
## Laid over the dial's box and drawn past its foot, into the room the block leaves under it, see
## [HudBlock]. Its shapes are worked out once for a size, so a frame of driving draws them only.

## The bottle round the dial's middle, in shares of half the dial's side: from how far out to how
## far out, and in degrees clockwise from east with y down, where its foot is, where its shoulder
## starts and where its neck ends.
const INNER := 1.068
const OUTER := 1.241
const FOOT := 151.0
const SHOULDER := 51.0
const NECK := 45.0
## How much thinner the glass is inside than out, and the neck's half width, in the dial's pixels
## at its own size, see [constant SpeedDial.RING].
const GLASS := 1.3
const NECK_HALF := 2.1
const TENTHS := 10
const STEPS := 36
const EMPTY := Color(0.0, 0.0, 0.0, 0.5)
const CUT := Color(0.0, 0.0, 0.0, 0.6)
## How much darker the shadow side of the fill is, and of the valve's foil and its wheel's red.
const SHADE := 0.72
const WHEEL := Color(0.8, 0.17, 0.14)
## The size the valve is drawn at, the dial's own pixels for a dial [constant SIZE] across.
const SIZE := 88.0

## The player's own color, the fill's, see [HudBlock].
var ink := Color.WHITE:
	set = _set_ink
## Whether the nitro is lit, which turns the fill [constant SpeedDial.NITRO].
var lit := false:
	set = _set_lit

## The shapes for [member _for]: the glass, inside it, the fill's reach and the shadow side's.
var _for := Vector2.ZERO
var _glass := PackedVector2Array()
var _inside := PackedVector2Array()


func _init() -> void:
	min_value = 0.0
	max_value = 100.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	value_changed.connect(func(_to: float) -> void: queue_redraw())


func _draw() -> void:
	var half := minf(size.x, size.y) * 0.5
	var middle := size * 0.5
	if _for != size:
		_for = size
		var k := half * 2.0 / SIZE
		_glass = _outline(middle, half * INNER, half * OUTER, NECK_HALF * k)
		_inside = _outline(
			middle, half * INNER + GLASS * k, half * OUTER - GLASS * k, (NECK_HALF - 1.0) * k
		)
	var k := half * 2.0 / SIZE
	draw_colored_polygon(_glass, EMPTY)
	var share := clampf((value - min_value) / maxf(max_value - min_value, 0.001), 0.0, 1.0)
	var base := SpeedDial.NITRO if lit else ink
	if share > 0.004:
		var to := lerpf(FOOT, NECK, share)
		var reach := _band(middle, half * INNER - 3.0, half * OUTER + 3.0, FOOT + 6.0, to)
		var shaded := _band(
			middle, half * (INNER + OUTER) * 0.5, half * OUTER + 3.0, FOOT + 6.0, to
		)
		for part: PackedVector2Array in Geometry2D.intersect_polygons(_inside, reach):
			draw_colored_polygon(part, base)
		for part: PackedVector2Array in Geometry2D.intersect_polygons(_inside, shaded):
			draw_colored_polygon(part, Color(base * SHADE, base.a))
	var rim := _glass.duplicate()
	rim.append(_glass[0])
	draw_polyline(rim, Color(HouseTheme.PAPER, 0.18), 0.9 * k, true)
	# The tenths, cut across the glass; and the glint along its top, where the light comes from.
	for i: int in range(1, TENTHS):
		var toward := Vector2.from_angle(deg_to_rad(lerpf(FOOT, NECK, float(i) / TENTHS)))
		draw_line(
			middle + toward * (half * INNER + 0.6 * k),
			middle + toward * (half * OUTER - 0.6 * k),
			CUT,
			1.1 * k,
			true
		)
	draw_arc(
		middle,
		half * INNER + 0.9 * k,
		deg_to_rad(FOOT - 5.0),
		deg_to_rad(FOOT - 40.0),
		12,
		Color(HouseTheme.PAPER, 0.55),
		0.9 * k,
		true
	)
	var neck := middle + Vector2.from_angle(deg_to_rad(NECK)) * half * (INNER + OUTER) * 0.5
	draw_set_transform(neck, deg_to_rad(NECK - 90.0), Vector2.ONE * k)
	_draw_valve()
	draw_set_transform(Vector2.ZERO)


## The valve along +x from the end of the neck, +y its shadow side, away from the dial: the neck,
## the valve's block with its outlet turned to the dial, a stem, and the hand wheel on its end seen
## edge on, red, as a bar across.
func _draw_valve() -> void:
	var foil := HouseTheme.FOIL
	var dark := Color(foil * SHADE, 1.0)
	draw_rect(Rect2(0.0, -2.0, 2.8, 4.0), dark)
	draw_rect(Rect2(2.6, -3.3, 6.4, 6.6), foil)
	draw_rect(Rect2(2.6, 0.3, 6.4, 3.0), dark)
	draw_rect(Rect2(4.6, -5.5, 2.6, 2.4), foil)
	draw_rect(Rect2(8.8, -1.0, 1.9, 2.0), dark)
	draw_rect(Rect2(10.5, -5.4, 2.4, 10.8), WHEEL)
	draw_rect(Rect2(10.5, 0.6, 2.4, 4.8), Color(WHEEL * SHADE, 1.0))
	draw_line(Vector2(11.7, -4.2), Vector2(11.7, -1.2), Color(HouseTheme.PAPER, 0.75), 0.8, true)


## The bottle's outline round [param middle] between [param inner] and [param outer]: rounded at
## its foot, narrowing over its shoulder into a neck [param neck] either side of its middle.
static func _outline(
	middle: Vector2, inner: float, outer: float, neck: float
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in STEPS + 1:
		points.append(_at(middle, outer, lerpf(FOOT, SHOULDER, float(i) / STEPS)))
	var halfway := (inner + outer) * 0.5
	var bend := NECK + 1.2
	var shoulder := _at(middle, outer, SHOULDER)
	for i: int in range(1, 7):
		var to := _at(middle, halfway + neck, NECK)
		points.append(_curve(shoulder, _at(middle, outer, bend), to, i / 6.0))
	var from := _at(middle, halfway - neck, NECK)
	for i: int in 7:
		var to := _at(middle, inner, SHOULDER)
		points.append(_curve(from, _at(middle, inner, bend), to, i / 6.0))
	for i: int in range(1, STEPS + 1):
		points.append(_at(middle, inner, lerpf(SHOULDER, FOOT, float(i) / STEPS)))
	# The foot, half a round beyond its end.
	var foot := deg_to_rad(FOOT)
	var out := Vector2.from_angle(foot)
	var on := Vector2(-sin(foot), cos(foot))
	var round_middle := _at(middle, halfway, FOOT)
	var radius := (outer - inner) * 0.5
	for i: int in range(1, 12):
		var turn := PI * (1.0 - i / 12.0)
		points.append(round_middle + (out * cos(turn) + on * sin(turn)) * radius)
	return points


## The point [param radius] out from [param middle] at [param degrees].
static func _at(middle: Vector2, radius: float, degrees: float) -> Vector2:
	return middle + Vector2.from_angle(deg_to_rad(degrees)) * radius


## A band round [param middle] between two radii, from [param from] down to [param to] degrees, to
## cut the fill out of the glass with.
static func _band(
	middle: Vector2, inner: float, outer: float, from: float, to: float
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in STEPS + 1:
		points.append(_at(middle, outer, lerpf(from, to, float(i) / STEPS)))
	for i: int in STEPS + 1:
		points.append(_at(middle, inner, lerpf(to, from, float(i) / STEPS)))
	return points


static func _curve(from: Vector2, bend: Vector2, to: Vector2, t: float) -> Vector2:
	return from.lerp(bend, t).lerp(bend.lerp(to, t), t)


func _set_ink(value: Color) -> void:
	if value == ink:
		return
	ink = value
	queue_redraw()


func _set_lit(value: bool) -> void:
	if value == lit:
		return
	lit = value
	queue_redraw()
