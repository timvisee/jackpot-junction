class_name ClearView
extends RefCounted
## Keeping the karts out from under the HUD, GAME.md 8.2: the panels round the edge of the screen,
## the hands of jokers and the respawn pick are drawn over the room, and a kart driven under one is
## a kart nobody can see. [CameraRig] frames the karts on the whole screen first and then asks this
## how far further back to sit, and how far to slide its aim across and up, so that none of them is
## under anything. The screen's own edges stay the frame's business; this only answers for what is
## laid over it.
##
## Worked in the rig's own terms, see [method CameraRig._in_view]: a point a sideways x and an
## upward y off the aim in the camera's coordinates, at depth d - z with the rig d back, shows at
## x / (d - z) over the tangent of half the view across, and the same for y up. Sliding the rig back
## moves every point straight in toward the middle of the screen, so a point is under a panel for
## one stretch of distances at most, which is solved for rather than searched; only the slide of
## the aim is tried, a handful of ways, and the cheapest kept.

## How far round a kart's middle is kept clear, in meters: a kart and a little air round it.
const KART_ROOM := 1.1
## The most the rig is let go back for this, as a share of how far back the whole arena is framed
## from: past that a kart is left under a panel rather than every kart shrunk to a speck.
const FURTHEST := 1.6
## The slides of the aim tried, across and up, as shares of the screen's half width and height,
## and the most the slide in use moves toward a better one at each look, so the aim glides from
## one to the next rather than jumping across the room as the karts move.
const SLIDES: Array[float] = [-0.4, -0.2, 0.0, 0.2, 0.4]
const STEP := 0.2
## How much closer another slide has to bring the rig before it is taken over the one already in
## use, so the aim does not hop between two that are nearly as good; and what a slide costs as a
## share of the distance for each whole screen's half it slides, so the aim stays in the middle
## unless sliding it really is worth it.
const STICKY := 0.03
const SLIDE_COST := 0.08

## The answer: how far back the rig sits, how far the aim slides up past the lift it already has
## and across, in meters, the slide tried in shares of the screen, and how many of the points are
## under a panel all the same.
var distance := 0.0
var lift := 0.0
var across := 0.0
var slide := Vector2.ZERO
var covered := 0


## The answer for [param covers], panels in shares of the screen (x right, y down), over
## [param points] that must not be under them, with [param corners] that must stay on the screen;
## both as [method CameraRig._in_view] gives them, from the aim at a distance of zero.
##
## [param near] is how far back the rig would sit for the corners alone and [param raised] the lift
## of its aim there; [param closest] and [param furthest] are the most it may come in and go back
## for the corners, and the panels may take it on to [constant FURTHEST] of [param furthest].
## [param fit] is the tangents of half the view the corners are fitted in, across and up, and
## [param view] those of the whole screen. [param kept] is the slide in use, tried first, and the
## only one tried unless [param search]: the others are looked for a few times a second, and the
## one found held between.
static func solve(
	covers: Array[Rect2],
	points: Array[Vector3],
	corners: Array[Vector3],
	near: float,
	raised: float,
	closest: float,
	furthest: float,
	fit: Vector2,
	view: Vector2,
	kept: Vector2,
	search: bool
) -> ClearView:
	var plain := ClearView.new()
	plain.distance = near
	var ndc := _in_ndc(covers)
	if ndc.is_empty() or points.is_empty():
		return plain
	var limit := furthest * FURTHEST
	var best := _try(ndc, points, corners, near, raised, closest, furthest, limit, fit, view, kept)
	# Nothing under anything with the aim in the middle: the common case, and nothing to look for.
	var settled := kept == Vector2.ZERO and best.covered == 0 and best.distance <= near * 1.001
	if settled or not search:
		return best
	for x: float in SLIDES:
		for y: float in SLIDES:
			var tried := Vector2(x, y)
			if tried == kept:
				continue
			var other := _try(
				ndc, points, corners, near, raised, closest, furthest, limit, fit, view, tried
			)
			if _better(other, best):
				best = other
	var toward := kept + (best.slide - kept).clampf(-STEP, STEP)
	if toward != best.slide:
		best = _try(ndc, points, corners, near, raised, closest, furthest, limit, fit, view, toward)
	return best


## Whether [param other] beats [param best]: fewer points under a panel, or as few and the rig
## closer by more than [constant STICKY], a slide counted against it, see [constant SLIDE_COST].
static func _better(other: ClearView, best: ClearView) -> bool:
	if other.covered != best.covered:
		return other.covered < best.covered
	var cost := other.distance * (1.0 + SLIDE_COST * other.slide.length())
	return cost < best.distance * (1.0 + SLIDE_COST * best.slide.length()) * (1.0 - STICKY)


## [param covers] from shares of the screen, y down, to the camera's own -1 to 1, y up.
static func _in_ndc(covers: Array[Rect2]) -> Array[Rect2]:
	var ndc: Array[Rect2] = []
	for cover: Rect2 in covers:
		if cover.size.x <= 0.0 or cover.size.y <= 0.0:
			continue
		var low := Vector2(cover.position.x * 2.0 - 1.0, 1.0 - cover.end.y * 2.0)
		ndc.append(Rect2(low, cover.size * 2.0))
	return ndc


## The answer with the aim slid by [param tried], in shares of the screen at [param near].
static func _try(
	ndc: Array[Rect2],
	points: Array[Vector3],
	corners: Array[Vector3],
	near: float,
	raised: float,
	closest: float,
	furthest: float,
	limit: float,
	fit: Vector2,
	view: Vector2,
	tried: Vector2
) -> ClearView:
	var answer := ClearView.new()
	answer.slide = tried
	answer.across = tried.x * near * view.x
	answer.lift = tried.y * near * view.y
	# Far enough back for every corner on the screen with the aim where it now is. Past the most the
	# rig goes back for the corners alone, held there, it has the arena on the screen; slid, it is
	# held as much short of what it would need.
	var over := maxf(_back(corners, Vector2(0.0, raised), fit) - maxf(furthest, near), 0.0)
	var aim := Vector2(answer.across, raised + answer.lift)
	var back := maxf(_back(corners, aim, fit) - over, closest)
	# Each point's stretch of distances under each panel: the rig has to be past all of them.
	var under: Array[Vector2] = []
	var whose: Array[int] = []
	for i: int in points.size():
		var point := points[i]
		var depth := maxf(back - point.z, 0.001)
		var room := Vector2(KART_ROOM / (depth * view.x), KART_ROOM / (depth * view.y))
		var a := (point.x - aim.x) / view.x
		var b := (point.y - aim.y) / view.y
		for cover: Rect2 in ndc:
			var span := _span(a, b, cover.grow_individual(room.x, room.y, room.x, room.y))
			if span.x <= span.y:
				under.append(Vector2(point.z + 1.0 / span.y, point.z + 1.0 / span.x))
				whose.append(i)
	var lost: Dictionary[int, bool] = {}
	var at := back
	for step: int in under.size() + 1:
		var moved := false
		for j: int in under.size():
			var stretch := under[j]
			if whose[j] in lost or at < stretch.x or at > stretch.y:
				continue
			if is_inf(stretch.y) or stretch.y > limit:
				# No distance takes it out from under this one: a panel over the middle, or one
				# too big for the rig to back away from. It is left there.
				lost[whose[j]] = true
				continue
			at = stretch.y + 0.01
			moved = true
		if not moved:
			break
	answer.distance = at
	answer.covered = lost.size()
	return answer


## How far back the rig has to be for every one of [param corners] to be on the screen of half
## tangents [param fit], with its aim at [param aim] across and up.
static func _back(corners: Array[Vector3], aim: Vector2, fit: Vector2) -> float:
	var back := 0.0
	for corner: Vector3 in corners:
		back = maxf(back, corner.z + absf(corner.x - aim.x) / fit.x)
		back = maxf(back, corner.z + absf(corner.y - aim.y) / fit.y)
	return back


## The stretch of w, one over a point's depth, over which a point at [param a] and [param b] times
## w on the screen is inside [param cover]: x past y for none. Infinite at the top for a point the
## panel holds however close the rig comes, and down to zero for one it holds however far back.
static func _span(a: float, b: float, cover: Rect2) -> Vector2:
	var x := _along(a, cover.position.x, cover.end.x)
	var y := _along(b, cover.position.y, cover.end.y)
	var low := maxf(x.x, y.x)
	var high := minf(x.y, y.y)
	return Vector2(low, high) if high > 0.0 else Vector2(1.0, 0.0)


## The stretch of w over which [param a] times w is between [param low] and [param high].
static func _along(a: float, low: float, high: float) -> Vector2:
	if is_zero_approx(a):
		return Vector2(0.0, INF) if low <= 0.0 and high >= 0.0 else Vector2(1.0, 0.0)
	var from := low / a
	var to := high / a
	if a < 0.0:
		var swap := from
		from = to
		to = swap
	return Vector2(maxf(from, 0.0), to)
