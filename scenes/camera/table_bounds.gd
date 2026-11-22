class_name TableBounds
extends RefCounted
## How far past the arena [CameraRig] lets the picture go while it follows the karts, GAME.md 8.2:
## a strip at each edge of the screen, so the walls and the room's own things just past them are
## seen, and no more. A camera following a kart along a wall used to aim at the kart, and half the
## screen was crowd.
##
## Counted on the screen rather than on the floor: a meter of floor past the near wall is close
## to the camera and fills far more of the screen than a meter past the far one, and the stands on
## the near side rise toward the camera and fill more again, so that side is counted at their
## height rather than at the floor's.

## How much of the screen at each edge may show what is past the arena, as a share of it; and the
## most it grows to at a desk with the UI drawn small, see [method edge_now], with how fast.
const EDGE := 0.1
const EDGE_MOST := 0.2
const EDGE_PER_SCALE := 0.4
## How high the room past the near wall rises toward the camera, in meters: the stands and the
## crowd on them, which a near edge counted on the floor would let fill the bottom of the screen.
const NEAR_HEIGHT := 1.2


## The strip at each edge of this screen that may show what is past the arena, GAME.md 8.2:
## [constant EDGE], and at a desk with the UI drawn smaller than it was laid out more, up to
## [constant EDGE_MOST] at 75%. The game stretches every window to the same picture, so how big a
## screen is cannot be told from it; turning the UI down is the player saying the karts are big
## enough to spare more of the screen for the room.
static func edge_now() -> float:
	if Game.settings.screen != ViewChoices.SCREEN_DESK or OS.has_feature("mobile"):
		return EDGE
	var spare := (1.0 - ViewChoices.ui_scale_now()) * EDGE_PER_SCALE
	return clampf(EDGE + spare, EDGE, EDGE_MOST)


## How far to slide a camera looking at [param look] from [param distance] back at [param pitch]
## degrees so that no more than [param edge] of the screen at any edge shows what is past an arena
## [param half] its size each way about [param center], [method edge_now] where it is not given;
## across or down, where the view is wider than the arena, so the arena is in its middle.
## [param view] holds the tangents of half the camera's view across and down.
static func shift(
	look: Vector3,
	center: Vector3,
	half: Vector2,
	distance: float,
	pitch: float,
	view: Vector2,
	edge := -1.0
) -> Vector3:
	var tilt := deg_to_rad(pitch)
	var back := Vector3(0.0, sin(tilt), cos(tilt))
	var up := Vector3(0.0, cos(tilt), -sin(tilt))
	var eye := look + back * distance
	var inner := view * (1.0 - (edge if edge >= 0.0 else edge_now()) * 2.0)
	var top := _under(eye, -back + up * inner.y, 0.0)
	var bottom := _under(eye, -back - up * inner.y, NEAR_HEIGHT)
	var left := _under(eye, -back - Vector3.RIGHT * inner.x, 0.0)
	var right := _under(eye, -back + Vector3.RIGHT * inner.x, 0.0)
	var across := _slide(left.x - center.x, right.x - center.x, half.x)
	var down := _slide(top.z - center.z, bottom.z - center.z, half.y)
	return Vector3(across, 0.0, down)


## Where a line from [param eye] [param way] comes down to [param height] over the floor.
static func _under(eye: Vector3, way: Vector3, height: float) -> Vector3:
	return eye + way * ((height - eye.y) / minf(way.y, -0.001))


## How far to slide a view from [param low] to [param high] about the arena's middle so it stays
## within [param limit] of it either way: to the middle, where it is wider than that.
static func _slide(low: float, high: float, limit: float) -> float:
	if high - low >= limit * 2.0:
		return -(low + high) * 0.5
	if high > limit:
		return limit - high
	if low < -limit:
		return -limit - low
	return 0.0
