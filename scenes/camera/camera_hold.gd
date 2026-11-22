class_name CameraHold
extends RefCounted
## How far back [CameraRig] holds itself while it follows, GAME.md 8.2: it goes back as soon as
## the karts need it to, and comes in again only once they have stayed close for a moment, so the
## camera stands still while the field shifts about rather than breathing in and out with it.
##
## Followed straight, the distance chased the spread of the field every frame. The karts close up
## and spread out all the time, so the camera crept in for seconds and then pulled out in half of
## one, over and over: in a minute and a half of bots driving it changed direction about thirty-six
## times a minute and zoomed at fifteen percent a second on average. A camera that comes in only on
## a settled field, and goes out with a little room to spare, moves a few times a minute instead.

## How much further back than it needs it goes when it has to go back, as a share: room for the
## field to spread a little further before it has to move again.
const SPARE := 0.06
## How much closer the field has to let it come, as a share, and for how long, in seconds, before
## it comes in: a field that closes up for a moment, as two karts pass, does not bring it in.
const ROOM := 0.15
const SETTLED := 1.5
## How far the aim may stay off where the framing would put it before it moves, as a share of the
## screen across and down, see [method hold_aim]; and how many halvings find how far it can.
const STILL := 0.05
const STEPS := 10

## The distance it holds, in meters; zero before it is first asked.
var distance := 0.0
## Where it holds the aim, an offset across the floor from the middle, see [method hold_aim].
var aim := Vector3.ZERO
## Whether it is on its way in, following the field as it closes up, and since when on the rig's
## clock the field has left it room to come in.
var _coming_in := false
var _room_since := INF


## Forgets what it held: the next distance asked for is taken as it is.
func reset() -> void:
	distance = 0.0
	aim = Vector3.ZERO
	_coming_in = false
	_room_since = INF


## The distance to hold for a field that needs [param wanted], at [param now] on the rig's clock,
## in seconds, never closer than [param least] nor further than [param most]. The room to spare
## is worked out from what the field wants rather than from the nearest the rig may come, so a
## field already well inside the closest shot is held at the closest shot, not a little behind it.
## Not [param settled], a kart is still gliding into the framing or one driven here is down, and
## it does not come in: the field is about to need more room, not less. Whether it comes in, and
## how far, goes by [param ideal] where it is given, the distance with the aim where the framing
## would put it rather than where it is held, see [method CameraRig._still]: an aim held off to one
## side needs a little more room, and that is the aim's cost, not a reason to stay out.
func hold(
	wanted: float, now: float, least: float, most: float, settled := true, ideal := -1.0
) -> float:
	var needed := clampf(wanted, least, most)
	var roomy := clampf(wanted * (1.0 + SPARE), least, most)
	if distance <= 0.0 or needed > distance:
		# Back at once, with a little to spare. The rig eases the move; this only says where to.
		distance = roomy
		_coming_in = false
		_room_since = INF
		return distance
	if not settled:
		_coming_in = false
		_room_since = INF
		return distance
	# Never in past what the field needs from where the camera really aims.
	var inward := (
		maxf(clampf(ideal * (1.0 + SPARE), least, most), needed) if ideal >= 0.0 else roomy
	)
	if _coming_in:
		# Following the field in while it closes up, and stopping as soon as it stops: a field that
		# opens out again a little is held, not followed back out.
		if inward >= distance:
			_coming_in = false
			_room_since = INF
		else:
			distance = inward
		return distance
	if inward < distance * (1.0 - ROOM):
		if _room_since == INF:
			_room_since = now
		elif now - _room_since >= SETTLED:
			_coming_in = true
			distance = inward
	else:
		_room_since = INF
	return distance


## [param wanted], the aim the framing would put the camera at, held where the camera already aims
## while it is within [constant STILL] of the screen's [param span] of floor across and down, at the
## distance held: a field shifting about a little leaves the picture standing still rather than
## drifting after it, GAME.md 8.2, and it moves only once the field has moved on. Only as far as
## every kart still fits from it, which [param fits] says of an aim; past that it lets go of just
## enough of it for them to, found by halving.
func hold_aim(wanted: Vector3, span: Vector2, fits: Callable) -> Vector3:
	var reach := span * STILL
	var off := aim - wanted
	off = Vector3(clampf(off.x, -reach.x, reach.x), 0.0, clampf(off.z, -reach.y, reach.y))
	if not fits.call(wanted + off):
		var low := 0.0
		var high := 1.0
		for i: int in STEPS:
			var mid := (low + high) * 0.5
			if fits.call(wanted + off * mid):
				low = mid
			else:
				high = mid
		off *= low
	aim = wanted + off
	return aim
