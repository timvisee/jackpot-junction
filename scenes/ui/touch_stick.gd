class_name TouchStick
extends RefCounted
## The stick under the left thumb on a touch screen, GAME.md 4.2. It comes to wherever a thumb goes
## down in the lower left of the screen and waits in that corner while nobody has a thumb on it.
## [TouchControls] hands it the finger on it; this says how far it is pushed, and draws it. It only
## steers, side to side, unless it is [member free], for simple driving, where it points the way.
##
## Steering only, it is drawn as a steering wheel, GAME.md 4.2, which turns as the thumb pushes it
## sideways, a quarter turn at full lock: a knob sliding along a line said nothing a wheel does not
## say better. It is still pushed sideways rather than turned round, which a thumb does without
## looking.

## How big its ring is, where it waits from the bottom left corner, how far its knob goes to reach
## full lock, and how far from the middle a thumb has to be before it steers at all. It comes to
## wherever a thumb goes down inside [constant ZONE], the share of the screen from the left and
## from the bottom, so nobody has to find it by looking.
const RADIUS := 120.0
const KNOB := 52.0
const HOME := Vector2(230.0, -230.0)
const ZONE := Vector2(0.42, 0.62)
const DEAD := 0.1
## The wheel: how far it turns at full lock, how thick its rim is, how far out its rim runs as a
## share of the ring, how big its hub is, how thick its three spokes are, and how long the band
## at its top that shows which way up it is, in radians of the rim.
const WHEEL_TURN := PI * 0.5
const WHEEL_RIM := 22.0
const WHEEL_REACH := 0.8
const WHEEL_HUB := 26.0
const WHEEL_SPOKE := 14.0
const WHEEL_MARK := 0.32

## Whether it goes every way rather than only side to side: simple driving, GAME.md 4.2, where the
## way it is pushed is the way on the screen the kart goes.
var free := false
## The finger on it, or -1, where it came to and where the finger is now.
var finger := -1
var center := Vector2.ZERO
var knob := Vector2.ZERO


## Where it waits on a screen [param screen] big when nobody has a thumb on it.
static func home(screen: Vector2) -> Vector2:
	return Vector2(HOME.x, screen.y + HOME.y)


## Back to its corner with no finger on it.
func rest(screen: Vector2) -> void:
	finger = -1
	center = home(screen)
	knob = center


## Whether a finger going down at [param point] on a screen [param screen] big takes it: anywhere
## in its corner, while nobody else has it.
func takes(point: Vector2, screen: Vector2) -> bool:
	var inside := point.x < screen.x * ZONE.x and point.y > screen.y * (1.0 - ZONE.y)
	return finger < 0 and inside


## Comes to [param point] under [param by], kept far enough in from the edges that the whole ring
## is on the screen.
func grab(by: int, point: Vector2, screen: Vector2) -> void:
	finger = by
	var margin := Vector2(RADIUS, RADIUS)
	center = point.clamp(margin, screen - margin)
	knob = point


## Which way it is pushed and how far, x right and y down, at most 1 long, past the dead middle all
## the way round. Side to side only, unless it is [member free].
func push() -> Vector2:
	if finger < 0:
		return Vector2.ZERO
	var offset := (knob - center) / RADIUS
	if not free:
		offset.y = 0.0
	var length := minf(offset.length(), 1.0)
	if length <= DEAD:
		return Vector2.ZERO
	return offset.normalized() * (length - DEAD) / (1.0 - DEAD)


## How far the wheel is turned, in radians, clockwise: with the thumb, all the way to
## [constant WHEEL_TURN] at the ring's edge, and straight with no thumb on it.
func turn() -> float:
	if finger < 0 or free:
		return 0.0
	return clampf((knob.x - center.x) / RADIUS, -1.0, 1.0) * WHEEL_TURN


## The ring where it is and the knob where the thumb is onto [param canvas] at [param strength],
## the knob kept inside the ring; or, steering only, the wheel turned as far as it is pushed.
func draw(canvas: CanvasItem, strength: float) -> void:
	var rim := Color(TouchInk.rim(), TouchControls.RIM * strength)
	var fill := TouchControls.FILL
	canvas.draw_circle(center, RADIUS, Color(fill, fill.a * strength))
	canvas.draw_arc(center, RADIUS, 0.0, TAU, 64, rim, TouchControls.RIM_WIDTH, true)
	TouchInk.notch(canvas, center, RADIUS, strength)
	var lit := TouchInk.fill_down() if finger >= 0 else Color(1.0, 1.0, 1.0, 0.16)
	lit = Color(lit, lit.a * strength)
	if not free:
		draw_wheel(canvas, center, RADIUS * WHEEL_REACH, turn(), lit, rim)
		return
	var at := center + (knob - center).limit_length(RADIUS)
	canvas.draw_circle(at, KNOB, lit)
	canvas.draw_arc(at, KNOB, 0.0, TAU, 40, rim, TouchControls.RIM_WIDTH, true)
	TouchInk.notch(canvas, at, KNOB, strength)


## A steering wheel seen from the driver's seat onto [param canvas], [param reach] out to the middle
## of its rim and turned [param turned] clockwise: the rim, a hub, a spoke to each side and one
## down, and a band on the rim at its top in [param edge], so a turn of it is seen. The see-through
## [param body] and the [param edge] of the other touch buttons, scaled down for a hint's picture.
static func draw_wheel(
	canvas: CanvasItem, at: Vector2, reach: float, turned: float, body: Color, edge: Color
) -> void:
	var scale := reach / (RADIUS * WHEEL_REACH)
	var thick := WHEEL_RIM * scale
	var line := maxf(TouchControls.RIM_WIDTH * scale, 1.0)
	canvas.draw_arc(at, reach, 0.0, TAU, 64, body, thick, true)
	canvas.draw_arc(at, reach + thick * 0.5, 0.0, TAU, 64, edge, line, true)
	canvas.draw_arc(at, reach - thick * 0.5, 0.0, TAU, 64, edge, line, true)
	var hub := WHEEL_HUB * scale
	for way: float in [0.0, PI * 0.5, PI]:
		var out := Vector2.from_angle(way + turned)
		canvas.draw_line(
			at + out * hub, at + out * (reach - thick * 0.5), body, WHEEL_SPOKE * scale
		)
	canvas.draw_circle(at, hub, body)
	canvas.draw_arc(at, hub, 0.0, TAU, 32, edge, line, true)
	var top := -PI * 0.5 + turned
	canvas.draw_arc(
		at, reach, top - WHEEL_MARK * 0.5, top + WHEEL_MARK * 0.5, 12, edge, thick, true
	)
