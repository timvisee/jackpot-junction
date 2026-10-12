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
##
## It runs on a phone as well, so it is kept cheap, GAME.md 10.7: the rig asks a few times a second
## rather than every frame; the panels come in as one flat run of numbers, made once each time the
## HUD says what it covers, see [method flat]; whatever does not change with the slide is worked
## out once a call, and each point left with only the panels it could ever come out under; and a
## look for a better slide tries the one in use, the middle, the eight a step off it and one of the
## others in turn, not all of them.

## How far round a kart's middle is kept clear, in meters: a kart and a little air round it. A kart
## on the move is given more, see [method CameraRig._rooms], so the camera is clear of where it is
## going by the time it has eased there.
const KART_ROOM := 1.1
## The most the rig is let go back for this, as a share of how far back the whole arena is framed
## from: past that a kart is left under a panel rather than every kart shrunk to a speck.
const FURTHEST := 1.6
## The slides of the aim, across and up, are whole steps of [constant STEP] of the screen's half
## width and height, up to [constant REACH] steps either way; the slide in use moves a step at a
## look toward a better one, so the aim glides from one to the next rather than jumping across the
## room as the karts move.
const STEP := 0.2
const REACH := 2
## How many of the slides further than a step off the one in use a look tries besides the middle
## and its eight neighbors, a different one at each, so a better one out there is still found
## within a few looks.
const FAR_PROBES := 1
## How much closer another slide has to bring the rig before it is taken over the one already in
## use, so the aim does not hop between two that are nearly as good; and what a slide costs as a
## share of the distance for each whole screen's half it slides, so the aim stays in the middle
## unless sliding it really is worth it.
const STICKY := 0.03
const SLIDE_COST := 0.08
## How many slides [method solve] tries at a go, which is all of them.
const _ALL := 64
## Numbers per panel in [method flat]'s run: left, right, bottom and top, in the camera's -1 to 1.
const PER_COVER := 4

## The answer: how far back the rig sits, how far the aim slides up past the lift it already has
## and across, in meters, the slide tried in shares of the screen, and how many of the points are
## under a panel all the same.
var distance := 0.0
var lift := 0.0
var across := 0.0
var slide := Vector2.ZERO
var covered := 0

## What one call works out once, for every slide it tries: the points as fractions of the view's
## half tangents across and up, and their depths; each point with each panel it could come out under
## at any slide and any distance, the panel's edges grown by the point's room on the screen; the
## corners as fractions of the half tangents they are fitted in, with their depths; and the rest of
## the question. A point with a panel it could never be under is left out of every slide's sums.
var _points := PackedFloat32Array()
var _pairs := PackedInt32Array()
var _edges := PackedFloat32Array()
var _corners := PackedFloat32Array()
var _near := 0.0
var _raised := 0.0
var _closest := 0.0
var _limit := 0.0
var _over := 0.0
var _view := Vector2.ONE
var _fit := Vector2.ONE
## A look in steps, see [method start]: the slide in use, its answer, the best found so far, and
## the slides still to try.
var _at := Vector2i.ZERO
var _held: ClearView
var _best: ClearView
var _todo: Array[Vector2i] = []


## [param covers], panels in shares of the screen (x right, y down), as one run of
## [constant PER_COVER] numbers each in the camera's own -1 to 1, y up: what [method solve] takes.
static func flat(covers: Array[Rect2]) -> PackedFloat32Array:
	var run := PackedFloat32Array()
	for cover: Rect2 in covers:
		if cover.size.x <= 0.0 or cover.size.y <= 0.0:
			continue
		run.append(cover.position.x * 2.0 - 1.0)
		run.append(cover.end.x * 2.0 - 1.0)
		run.append(1.0 - cover.end.y * 2.0)
		run.append(1.0 - cover.position.y * 2.0)
	return run


## The answer for [param covers], panels as [method flat] gives them, over [param points] that
## must not be under them, with [param corners] that must stay on the screen; both as
## [method CameraRig._in_view] gives them, from the aim at a distance of zero. The whole of a look
## at once: [method start] takes it a few slides at a time instead.
##
## [param near] is how far back the rig would sit for the corners alone and [param raised] the lift
## of its aim there; [param closest] and [param furthest] are the most it may come in and go back
## for the corners, and the panels may take it on to [constant FURTHEST] of [param furthest].
## [param fit] is the tangents of half the view the corners are fitted in, across and up, and
## [param view] those of the whole screen. [param kept] is the slide in use, tried first, and the
## only one tried unless [param search]: the others are looked for a few times a second, and the
## one found held between. [param probe] says which of the far slides this look tries, and
## [param rooms] how far round each point is kept clear, [constant KART_ROOM] for any it leaves out.
static func solve(
	covers: PackedFloat32Array,
	points: Array[Vector3],
	corners: Array[Vector3],
	near: float,
	raised: float,
	closest: float,
	furthest: float,
	fit: Vector2,
	view: Vector2,
	kept: Vector2,
	search: bool,
	probe := 0,
	rooms := PackedFloat32Array()
) -> ClearView:
	var look := start(
		covers, points, corners, near, raised, closest, furthest, fit, view, kept, probe, rooms
	)
	if not search:
		return look.held()
	while not look.step(_ALL):
		pass
	return look.answer()


## A look, as [method solve] takes the same question, its slide in use tried at once, see
## [method held], and the others left to [method step], a few a frame, so a phone's frame is
## never the one that carries the whole of it, GAME.md 10.7.
static func start(
	covers: PackedFloat32Array,
	points: Array[Vector3],
	corners: Array[Vector3],
	near: float,
	raised: float,
	closest: float,
	furthest: float,
	fit: Vector2,
	view: Vector2,
	kept: Vector2,
	probe := 0,
	rooms := PackedFloat32Array()
) -> ClearView:
	var look := ClearView.new()
	look.distance = near
	look._best = look
	look._held = look
	if covers.is_empty() or points.is_empty():
		return look
	look._prepare(covers, points, corners, near, raised, closest, furthest, fit, view, rooms)
	look._at = Vector2i((kept / STEP).round()).clampi(-REACH, REACH)
	look._held = look._try(look._at)
	look._best = look._held
	# Nothing under anything with the aim in the middle: the common case, and nothing to look for.
	var settled := (
		look._at == Vector2i.ZERO
		and look._held.covered == 0
		and look._held.distance <= near * 1.001
	)
	if not settled:
		for other: Vector2i in _candidates(look._at, probe):
			if other != look._at and other not in look._todo:
				look._todo.append(other)
	return look


## The answer for the slide in use, as soon as the look starts.
func held() -> ClearView:
	return _held


## Tries up to [param count] more of the look's slides; true once it has tried them all.
func step(count: int) -> bool:
	for i: int in mini(count, _todo.size()):
		var answer := _try(_todo.pop_back())
		if _better(answer, _best):
			_best = answer
	return _todo.is_empty()


## The answer the look came to, the slide in use moved a step toward the best it found.
func answer() -> ClearView:
	if _best == _held:
		return _held
	var best_at := Vector2i((_best.slide / STEP).round())
	var toward := _at + (best_at - _at).clampi(-1, 1)
	return _best if toward == best_at else _try(toward)


## The slides a look tries besides [param at], the one in use: the middle, the eight a step off it,
## and [constant FAR_PROBES] of the rest, which ones turning on with [param probe].
static func _candidates(at: Vector2i, probe: int) -> Array[Vector2i]:
	var near: Array[Vector2i] = [Vector2i.ZERO]
	var far: Array[Vector2i] = []
	for x: int in range(-REACH, REACH + 1):
		for y: int in range(-REACH, REACH + 1):
			var each := Vector2i(x, y)
			var off := (each - at).abs()
			if maxi(off.x, off.y) == 1:
				near.append(each)
			elif off != Vector2i.ZERO:
				far.append(each)
	for i: int in FAR_PROBES:
		if not far.is_empty():
			near.append(far[(probe * FAR_PROBES + i) % far.size()])
	return near


## Whether [param other] beats [param best]: fewer points under a panel, or as few and the rig
## closer by more than [constant STICKY], a slide counted against it, see [constant SLIDE_COST].
static func _better(other: ClearView, best: ClearView) -> bool:
	if other.covered != best.covered:
		return other.covered < best.covered
	var cost := other.distance * (1.0 + SLIDE_COST * other.slide.length())
	return cost < best.distance * (1.0 + SLIDE_COST * best.slide.length()) * (1.0 - STICKY)


## What every slide tried shares, worked out once: see the members it fills.
func _prepare(
	covers: PackedFloat32Array,
	points: Array[Vector3],
	corners: Array[Vector3],
	near: float,
	raised: float,
	closest: float,
	furthest: float,
	fit: Vector2,
	view: Vector2,
	rooms: PackedFloat32Array
) -> void:
	_near = near
	_raised = raised
	_closest = closest
	_limit = furthest * FURTHEST
	_view = view
	_fit = fit
	_points.resize(points.size() * 3)
	_pairs.clear()
	_edges.clear()
	# However far the aim slides, and however close the rig comes.
	var slid := REACH * STEP * near
	var raise := raised / view.y
	var i := 0
	var index := 0
	for point: Vector3 in points:
		var a := point.x / view.x
		var b := point.y / view.y
		_points[i] = a
		_points[i + 1] = b
		_points[i + 2] = point.z
		# How big the room round it is on the screen, at the depth the corners alone would put it
		# at: going back only shrinks it.
		var depth := maxf(near - point.z, 0.001)
		var room := rooms[index] if index < rooms.size() else KART_ROOM
		var room_x := room / (depth * view.x)
		var room_y := room / (depth * view.y)
		# Everywhere on the screen it could be: between the middle and as far out as the slides
		# and the nearest the rig comes take it.
		var most := 1.0 / maxf(closest - point.z, 0.001)
		var reach_left := minf(0.0, (a - slid) * most)
		var reach_right := maxf(0.0, (a + slid) * most)
		var reach_bottom := minf(0.0, (b - raise - slid) * most)
		var reach_top := maxf(0.0, (b - raise + slid) * most)
		var c := 0
		while c < covers.size():
			var left := covers[c] - room_x
			var right := covers[c + 1] + room_x
			var bottom := covers[c + 2] - room_y
			var top := covers[c + 3] + room_y
			c += PER_COVER
			if right < reach_left or left > reach_right or top < reach_bottom or bottom > reach_top:
				continue
			_pairs.append(index)
			_edges.append(left)
			_edges.append(right)
			_edges.append(bottom)
			_edges.append(top)
		i += 3
		index += 1
	_corners.resize(corners.size() * 3)
	i = 0
	for corner: Vector3 in corners:
		_corners[i] = corner.x / fit.x
		_corners[i + 1] = corner.y / fit.y
		_corners[i + 2] = corner.z
		i += 3
	# Past the most the rig goes back for the corners alone, held there, it has the arena on the
	# screen; slid, it is held as much short of what it would need.
	_over = maxf(_back(0.0, raised / fit.y) - maxf(furthest, near), 0.0)


## How far back the rig has to be for every corner to be on the screen, its aim [param across] and
## [param up] off the middle in fractions of the half tangents the corners are fitted in.
func _back(across_fit: float, up_fit: float) -> float:
	var back := 0.0
	var i := 0
	while i < _corners.size():
		var z := _corners[i + 2]
		back = maxf(back, z + absf(_corners[i] - across_fit))
		back = maxf(back, z + absf(_corners[i + 1] - up_fit))
		i += 3
	return back


## The answer with the aim slid [param at] steps, see [constant STEP].
func _try(at: Vector2i) -> ClearView:
	var answer := ClearView.new()
	answer.slide = Vector2(at) * STEP
	answer.across = answer.slide.x * _near * _view.x
	answer.lift = answer.slide.y * _near * _view.y
	var aim_x := answer.across
	var aim_y := _raised + answer.lift
	var back := maxf(_back(aim_x / _fit.x, aim_y / _fit.y) - _over, _closest)
	var shift_x := aim_x / _view.x
	var shift_y := aim_y / _view.y
	# Each point's stretch of distances under each panel that reaches past where the rig is: it has
	# to be past all of them. Written out rather than called, for it is the inner loop.
	var lows := PackedFloat32Array()
	var highs := PackedFloat32Array()
	var whose := PackedInt32Array()
	# Locals rather than members in here: each member read is a lookup, and this is read a lot.
	var points := _points
	var pairs := _pairs
	var edges := _edges
	var e := 0
	for which: int in pairs:
		var p := which * 3
		var a := points[p] - shift_x
		var b := points[p + 1] - shift_y
		var left := edges[e]
		var right := edges[e + 1]
		var bottom := edges[e + 2]
		var top := edges[e + 3]
		e += 4
		# The stretch of w, one over the depth, over which a * w and b * w are inside.
		var from := 0.0
		var to := INF
		if a > 0.000001:
			from = maxf(from, left / a)
			to = minf(to, right / a)
		elif a < -0.000001:
			from = maxf(from, right / a)
			to = minf(to, left / a)
		elif left > 0.0 or right < 0.0:
			continue
		if b > 0.000001:
			from = maxf(from, bottom / b)
			to = minf(to, top / b)
		elif b < -0.000001:
			from = maxf(from, top / b)
			to = minf(to, bottom / b)
		elif bottom > 0.0 or top < 0.0:
			continue
		if to <= from:
			continue
		var z := points[p + 2]
		var furthest := z + 1.0 / from if from > 0.0 else INF
		if furthest < back:
			continue
		lows.append(z + 1.0 / to)
		highs.append(furthest)
		whose.append(which)
	# Past every stretch the rig is in, nearest first; a stretch no distance gets out of leaves its
	# point under the panel, and the rig goes nowhere for it.
	var lost := 0
	var distance_at := back
	var moved := true
	while moved:
		moved = false
		for j: int in lows.size():
			var bit := 1 << mini(whose[j], 62)
			if lost & bit or distance_at < lows[j] or distance_at > highs[j]:
				continue
			if highs[j] > _limit:
				# A panel over the middle, or one too big for the rig to back away from.
				lost |= bit
				continue
			distance_at = highs[j] + 0.01
			moved = true
	answer.distance = distance_at
	while lost:
		answer.covered += lost & 1
		lost >>= 1
	return answer
