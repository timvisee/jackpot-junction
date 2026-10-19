class_name FramedSpots
extends RefCounted
## Where [CameraRig] takes each kart it follows to be, for its framing, GAME.md 8.2: where the kart
## is, except for a moment after it comes into the shot somewhere new. A kart that joins, or comes
## back across the room after going down, used to be in the framing all at once, and the camera
## jumped to take it in: from a close shot of a fight to the whole floor in a few frames, at a
## hundred and sixty meters a second. Now its place in the framing glides from where it was
## counted last to where it really is over [constant GLIDE] seconds, easing in and out, so the shot
## widens or swings over to it as one move. A kart new to the shot glides from the nearest edge of
## the box the others are in, where it changes nothing, and one with nobody else in the shot from
## where the camera is looking.
##
## Kept cheap, GAME.md 10.7: a kart's place is kept from frame to frame and only made once, as it
## comes into the shot; the places are worked out once a frame however often the rig asks, and
## written into one run of numbers rather than a new one each frame.

## How long a kart takes to come all the way into the framing, in seconds.
const GLIDE := 1.0
## How far a kart has to go in one frame to have come back somewhere else rather than driven
## there, in meters: further than any kart goes in a frame, however slow the frame.
const JUMP := 6.0


## One kart's place in the framing.
class Spot:
	## Where the kart really was when last asked, where its place glides from and since when on
	## the rig's clock, and where it is counted now.
	var last := Vector3.ZERO
	var from := Vector3.ZERO
	var since := -INF
	var at := Vector3.ZERO


## Where each kart counts for the framing, in the order of the karts last given to [method place].
var placed := PackedVector3Array()

## Each kart's place, by its instance id; whether the next karts are the first of a shot, which
## are taken where they are, as the shot opens on them; and the moment [method place] last worked
## them out.
var _spots: Dictionary[int, Spot] = {}
var _fresh := true
var _placed_at := -INF


## Forgets every kart: the next ones are the first of a new shot and are taken where they are.
func reset() -> void:
	_spots.clear()
	placed.clear()
	_fresh = true
	_placed_at = -INF


## Works out [member placed] for [param alive], the karts in the shot, at [param now] on the rig's
## clock, in seconds; [param aim], on the floor, is where the camera is looking. Asked again at the
## same moment for as many karts, as the rig asks more than once a frame, it keeps the answer it
## has.
func place(alive: Array[Node3D], now: float, aim: Vector3) -> void:
	if now == _placed_at and alive.size() == placed.size():
		return
	_placed_at = now
	placed.resize(alive.size())
	# The karts already in the shot first. Where a new one goes is left unknown for the moment.
	var known := 0
	for i: int in alive.size():
		var spot: Spot = _spots.get(alive[i].get_instance_id())
		if spot == null:
			placed[i] = Vector3.INF
			continue
		known += 1
		var real := alive[i].global_position
		if real.distance_squared_to(spot.last) > JUMP * JUMP:
			spot.from = spot.at
			spot.since = now
		spot.last = real
		spot.at = real if now - spot.since >= GLIDE else _glided(spot, real, now)
		placed[i] = spot.at
	if known < alive.size():
		_take_in(alive, now, aim)
	if not alive.is_empty():
		_fresh = false
	# More kept than there are karts: some have gone from the shot.
	if _spots.size() > alive.size():
		_forget_gone(alive)


## The karts of [param alive] new to the shot, as [method place] has them, put where they glide in
## from: the nearest edge of the box the others are in, or with nobody else in the shot, where the
## camera is looking, [param aim]; or, the first of a shot, where they are.
func _take_in(alive: Array[Node3D], now: float, aim: Vector3) -> void:
	var box := AABB()
	var boxed := false
	for at: Vector3 in placed:
		if at.is_finite():
			box = box.expand(at) if boxed else AABB(at, Vector3.ZERO)
			boxed = true
	for i: int in alive.size():
		if placed[i].is_finite():
			continue
		var real := alive[i].global_position
		var spot := Spot.new()
		spot.last = real
		if not _fresh:
			spot.from = real.clamp(box.position, box.end) if boxed else Vector3(aim.x, 0.0, aim.z)
			spot.since = now
		spot.at = _glided(spot, real, now)
		placed[i] = spot.at
		_spots[alive[i].get_instance_id()] = spot


## Where [param target] counts for the framing, as [method place] last worked it out: where it is,
## for one it has not seen.
func place_of(target: Node3D) -> Vector3:
	var spot: Spot = _spots.get(target.get_instance_id())
	return spot.at if spot != null else target.global_position


## [param spot]'s place for a kart really at [param real], [param now]: part way from where it
## glides from, easing in and out, see [constant GLIDE].
static func _glided(spot: Spot, real: Vector3, now: float) -> Vector3:
	var done := clampf((now - spot.since) / GLIDE, 0.0, 1.0)
	if done >= 1.0:
		return real
	return spot.from.lerp(real, done * done * (3.0 - 2.0 * done))


## Drops the karts kept that are not among [param alive]: gone from the shot. One that comes back
## into it glides in as a new one does.
func _forget_gone(alive: Array[Node3D]) -> void:
	var here: Dictionary[int, bool] = {}
	for target: Node3D in alive:
		here[target.get_instance_id()] = true
	for id: int in _spots.keys():
		if not here.has(id):
			_spots.erase(id)
