class_name NitroBottle
extends Range
## The nitro tank of a corner block, GAME.md 8.3 and 8.1a: the nitro bottle bent round the foot of
## the speed dial it shares its middle with, so dial and tank read as one gauge, as a car's fuel
## gauge sits under its speedometer. Dark glass rounded at its foot, filling from the left in the
## player's own color with the shadow side of the house print, marked off in tenths, a glint along
## it; it narrows over its shoulder into a neck, and a gas cylinder's valve stands straight off
## that, its red hand wheel across its end and its outlet piped into the dial's rim through a
## collar laid against the rim's edge, curved as the rim is. Amber while the bottle burns, as the
## dial's fill is, see [SpeedDial]; and red while what is left is too little to start it again, so
## a player sees the last drop will not light before they press for it.
##
## Laid in the dial's box under the dial, whose rim takes the collar's inner edge, and drawn past
## its foot, into the room the block leaves under it, see [HudBlock]. Its shapes are worked out
## once for a size, so a frame of driving draws them only.

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
## The fill while too little is left to start the nitro, see [member start_at].
const LOW := HouseTheme.STAMP_RED
## The size the valve is drawn at, the dial's own pixels for a dial [constant SIZE] across.
const SIZE := 88.0
## Along the valve, as [method _draw_valve] has it: the outlet, from the valve's block up to the
## collar, and the middle of its end, where the collar is laid.
const OUTLET := Rect2(4.6, -6.0, 2.6, 2.9)
const OUTLET_END := Vector2(5.9, -6.0)
## The collar the outlet goes into the dial's rim through: how far out from the rim's middle it
## reaches and how wide it is along the rim, in the dial's pixels at its own size. It starts on
## the rim's middle, see [constant SpeedDial.RIM], under the rim's foil, so it lies flush against
## the rim however thin the rim is drawn at a scale.
const COLLAR_DEEP := 2.3
const COLLAR_WIDE := 4.6

## The player's own color, the fill's, see [HudBlock].
var ink := Color.WHITE:
	set = _set_ink
## Whether the nitro is lit, which turns the fill [constant SpeedDial.NITRO].
var lit := false:
	set = _set_lit
## The share of a full bottle the nitro needs to be started, see [member KartStats.nitro_min_start]:
## while it is not lit and holds less, the fill is [constant LOW].
var start_at := 0.0:
	set = _set_start_at

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
	var share := _share()
	var base := fill()
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
	var turn := deg_to_rad(NECK - 90.0)
	draw_set_transform(neck, turn, Vector2.ONE * k)
	_draw_valve()
	draw_set_transform(Vector2.ZERO)
	# The collar, round the dial's middle rather than along the valve, so it lies flush against the
	# rim where the outlet meets it; its far half in the foil's shadow.
	var at := rad_to_deg((neck + OUTLET_END.rotated(turn) * k - middle).angle())
	var edge := half * SpeedDial.RIM
	var spread := rad_to_deg(COLLAR_WIDE * 0.5 * k / edge)
	var foil := HouseTheme.FOIL
	draw_colored_polygon(
		_band(middle, edge, edge + COLLAR_DEEP * k, at - spread, at + spread), foil
	)
	draw_colored_polygon(
		_band(middle, edge, edge + COLLAR_DEEP * k, at, at + spread), Color(foil * SHADE, 1.0)
	)


## The valve along +x from the end of the neck, +y its shadow side, away from the dial: the neck,
## the valve's block with its outlet turned to the dial and running up to the dial's rim, a stem,
## and the hand wheel on its end seen edge on, red, as a bar across.
func _draw_valve() -> void:
	var foil := HouseTheme.FOIL
	var dark := Color(foil * SHADE, 1.0)
	draw_rect(Rect2(0.0, -2.0, 2.8, 4.0), dark)
	draw_rect(Rect2(2.6, -3.3, 6.4, 6.6), foil)
	draw_rect(Rect2(2.6, 0.3, 6.4, 3.0), dark)
	draw_rect(OUTLET, foil)
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


func _set_start_at(value: float) -> void:
	if value == start_at:
		return
	start_at = value
	queue_redraw()


## What the fill is drawn in: amber while lit, red while too little is left to start it, and the
## player's own color otherwise.
func fill() -> Color:
	if lit:
		return SpeedDial.NITRO
	return LOW if _share() < start_at else ink


func _share() -> float:
	return clampf((value - min_value) / maxf(max_value - min_value, 0.001), 0.0, 1.0)
