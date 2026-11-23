class_name CameraFit
extends RefCounted
## The geometry [CameraRig] fits the karts by, GAME.md 8.2: how far back the camera has to be for
## points to be on the screen, and how far to slide its aim up for the floor left over to be split
## evenly above and below. Worked out from the camera's own geometry rather than asked of Godot,
## whose frustum queries only answer after a frame has rendered, and this has to answer at load and
## again every frame.
##
## In the rig's own terms, see [method CameraRig._in_view]: points as they land in the camera's own
## coordinates looking at the aim from a distance of zero. The camera only ever slides along one
## line, so sliding it back by d takes d off the z of every one of them and changes nothing else,
## which is what both are built on.

## How many halvings the aim is solved in, see [method lift]. Fourteen take it to a couple of
## millimeters over the whole arena, under a pixel on any screen anybody has, an 8K one included;
## it is worked out every frame, so it takes no more than it needs, GAME.md 10.7.
const AIM_STEPS := 14


## The smallest distance at which every one of [param seen] is on the screen of a camera with
## [param view] the tangents of half its view across and down, and never less than [param least].
##
## Sideways it is one inequality per point. Up and down it is a pair, because the aim slides too:
## a point is on screen while |y - L| <= tan_v * (d - z), so d has to be big enough that some L
## satisfies every point at once, which is where the two tightest of them meet.
static func needed(seen: Array[Vector3], view: Vector2, least: float) -> float:
	var far := least
	var highest := -INF
	var lowest := INF
	for local: Vector3 in seen:
		far = maxf(far, local.z + absf(local.x) / view.x)
		highest = maxf(highest, local.y + view.y * local.z)
		lowest = minf(lowest, local.y - view.y * local.z)
	if seen.is_empty():
		return far
	return maxf(far, (highest - lowest) / (2.0 * view.y))


## How far to slide the aim along the camera's up axis so that [param seen], from [param distance],
## sit as far below the middle of the screen as they do above it.
##
## The camera is tilted, so the floor does not project symmetrically: the near edge of a thing
## lands lower than the far edge lands high. Left alone, the fit puts whichever of them binds
## hard against its edge of the frame and piles all the slack on the other side, which is the
## empty band above the arena. Sliding the aim costs nothing and splits the slack in two.
##
## Solved by bisection rather than in closed form: which two points end up at the edges depends on
## the aim, since they sit at different depths and a slide is worth more to the near one. Each
## point's height and depth do not change with the aim, so they are worked out once, and each
## halving only asks how far the highest and lowest miss the middle by, added up: zero when they
## straddle it evenly.
static func lift(seen: Array[Vector3], distance: float) -> float:
	if seen.is_empty():
		return 0.0
	var heights := PackedFloat32Array()
	var nearness := PackedFloat32Array()
	var reach := 0.0
	for local: Vector3 in seen:
		heights.append(local.y)
		nearness.append(1.0 / maxf(distance - local.z, 0.001))
		reach = maxf(reach, absf(local.y))
	var count := heights.size()
	var low := -reach
	var high := reach
	for step: int in AIM_STEPS:
		var mid := (low + high) * 0.5
		var above := -INF
		var below := INF
		for i: int in count:
			var ratio := (heights[i] - mid) * nearness[i]
			above = maxf(above, ratio)
			below = minf(below, ratio)
		# Positive means more of it is above the middle than below, so the aim has to come up.
		if above + below > 0.0:
			low = mid
		else:
			high = mid
	return (low + high) * 0.5
