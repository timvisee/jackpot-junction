class_name KeptInView
extends RefCounted
## The karts driven here are never off the screen, GAME.md 8.2. Whatever else the camera does to
## the picture, coming in closer than the whole field fits, balancing the floor above and below,
## easing after a kart going flat out, each kart somebody here is driving stays on the screen with
## a little floor round it. A rival may go off the edge, pointed at from there; a player's own kart
## never does.
##
## Coming in closer than the karts it follows fit, as Auto does on a handheld, the rig balanced the
## floor it left out above and below over all of them, so a rival near the bottom of the picture
## took the player's own kart off the top of it.

## How much floor round a kart driven here is always on the screen, in meters each way, and how high
## over the floor: the kart itself and a little of the road round it, not just its middle. And how
## much the framing aims to keep, more, so the camera, easing after it, has it on the screen as a
## move of its own and only a kart that outruns the ease is held there by the last word, see
## [method CameraRig._keep_mine].
const ROOM := 2.0
const AIMED := 3.5
const HIGH := 1.5


## The points that have to be on the screen for karts at [param places]: a box of floor round each,
## [param room] each way and [constant HIGH] tall.
static func around(places: PackedVector3Array, room := ROOM) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for at: Vector3 in places:
		for x: float in [-room, room]:
			for z: float in [-room, room]:
				points.append(Vector3(at.x + x, 0.0, at.z + z))
				points.append(Vector3(at.x + x, HIGH, at.z + z))
	return points


## How far the aim of a camera [param distance] back has to slide across and up the screen, from
## [param now], for every one of [param seen] to be on the screen: the least it can, [param now]
## itself where they already are. [param seen] are in the camera's own terms, looking at the aim
## from a distance of zero, see [method CameraRig._in_view]; [param view] is the tangents of half
## its view across and down. Where they cannot all be on the screen at once, halfway between the
## two that are furthest apart, so each misses by as little.
static func slide(
	seen: Array[Vector3], view: Vector2, distance: float, now := Vector2.ZERO
) -> Vector2:
	var low := Vector2(-INF, -INF)
	var high := Vector2(INF, INF)
	for local: Vector3 in seen:
		var reach := view * maxf(distance - local.z, 0.0)
		low = Vector2(maxf(low.x, local.x - reach.x), maxf(low.y, local.y - reach.y))
		high = Vector2(minf(high.x, local.x + reach.x), minf(high.y, local.y + reach.y))
	return Vector2(_within(now.x, low.x, high.x), _within(now.y, low.y, high.y))


## [param value] kept between [param low] and [param high]; halfway between them where they cross.
static func _within(value: float, low: float, high: float) -> float:
	if low > high:
		return (low + high) * 0.5
	return clampf(value, low, high)
