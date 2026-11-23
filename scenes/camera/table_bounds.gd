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
## And the points round the arena the rig fits it by and keeps clear of the HUD, see
## [method corners] and [method rim].

## How much of the screen at each edge may show what is past the arena, as a share of it; and the
## most it grows to at a desk with the UI drawn small, see [method edge_now], with how fast.
const EDGE := 0.1
const EDGE_MOST := 0.2
const EDGE_PER_SCALE := 0.4
## How high the room past the near wall rises toward the camera, in meters: the stands and the
## crowd on them, which a near edge counted on the floor would let fill the bottom of the screen.
const NEAR_HEIGHT := 1.2
## Every how far along the walls [method rim] puts a point, in meters.
const RIM_STEP := 5.0


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


## The corners of an arena [param size] across about [param center], [param out] meters out past
## its walls, in for less than none: on the floor and [param height] over it, the tops of its walls.
static func corners(center: Vector3, size: Vector2, out: float, height: float) -> Array[Vector3]:
	var half := size * 0.5 + Vector2.ONE * out
	var points: Array[Vector3] = []
	for x: int in [-1, 1]:
		for z: int in [-1, 1]:
			points.append(center + Vector3(x * half.x, 0.0, z * half.y))
			points.append(center + Vector3(x * half.x, height, z * half.y))
	return points


## Points round an arena [param size] across about [param center], [param out] meters out past its
## walls, in for less than none, [param middle] over the floor: its corners and the points between
## them every [constant RIM_STEP] meters or so, which is what the fixed camera keeps clear of the
## HUD at a kart's middle.
static func rim(center: Vector3, size: Vector2, out: float, middle: float) -> Array[Vector3]:
	var half := size * 0.5 + Vector2.ONE * out
	var points: Array[Vector3] = []
	var steps := Vector2i(ceili(half.x / RIM_STEP), ceili(half.y / RIM_STEP))
	for i: int in range(-steps.x, steps.x + 1):
		var x := half.x * float(i) / float(steps.x)
		points.append(center + Vector3(x, middle, -half.y))
		points.append(center + Vector3(x, middle, half.y))
	for j: int in range(-steps.y + 1, steps.y):
		var z := half.y * float(j) / float(steps.y)
		points.append(center + Vector3(-half.x, middle, z))
		points.append(center + Vector3(half.x, middle, z))
	return points
