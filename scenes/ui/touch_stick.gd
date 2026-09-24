class_name TouchStick
extends RefCounted
## The stick under the left thumb on a touch screen, GAME.md 4.2. It comes to wherever a thumb goes
## down in the lower left of the screen and waits in that corner while nobody has a thumb on it.
## [TouchControls] hands it the finger on it; this says how far it is pushed, and draws it. It only
## steers, side to side, unless it is [member free], for simple driving, where it points the way.

## How big its ring is, where it waits from the bottom left corner, how far its knob goes to reach
## full lock, and how far from the middle a thumb has to be before it steers at all. It comes to
## wherever a thumb goes down inside [constant ZONE], the share of the screen from the left and
## from the bottom, so nobody has to find it by looking.
const RADIUS := 120.0
const KNOB := 52.0
const HOME := Vector2(230.0, -230.0)
const ZONE := Vector2(0.42, 0.62)
const DEAD := 0.1

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


## The ring where it is and the knob where the thumb is onto [param canvas] at [param strength],
## the knob kept inside the ring, and on its level while the stick only steers.
func draw(canvas: CanvasItem, strength: float) -> void:
	var rim := Color(TouchControls.RIM, TouchControls.RIM.a * strength)
	var fill := TouchControls.FILL
	canvas.draw_circle(center, RADIUS, Color(fill, fill.a * strength))
	canvas.draw_arc(center, RADIUS, 0.0, TAU, 64, rim, TouchControls.RIM_WIDTH, true)
	var reach := (knob - center).limit_length(RADIUS)
	if not free:
		reach = Vector2(clampf(knob.x - center.x, -RADIUS, RADIUS), 0.0)
	var at := center + reach
	var lit := TouchControls.FILL_DOWN if finger >= 0 else Color(1.0, 1.0, 1.0, 0.16)
	canvas.draw_circle(at, KNOB, Color(lit, lit.a * strength))
	canvas.draw_arc(at, KNOB, 0.0, TAU, 40, rim, TouchControls.RIM_WIDTH, true)
