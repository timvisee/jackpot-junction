class_name BotLed
extends RefCounted
## A model led along a person's own line at the Final Hand's last quarter, STORY.md 8.2, see
## [HouseForecast]: it drives the line the person drove, as recorded, a set time behind them,
## rather than finding its own way to a point on it. Where it is on the line is the nearest point of
## it, looked for near where it was last; it steers for a point a little further along, further
## the faster it goes, and goes as fast as the person went there, a little quicker when it has
## fallen behind its time and a little slower when it has crept up. It keeps its distance from
## whoever is in front of it, the person or the model before it, and gets out of the person's way
## when they come at it, so a model never rams anybody. Off the line, knocked off it or put down
## somewhere else, it lets its [BotBrain] find the way back. Stepped by the brain while it is on.

## How far off the line a kart may be before it is no longer on it, and how near it has to come
## again to be back on it, in meters.
const OFF_LINE := 3.0
const ON_LINE := 1.8
## How far along the line from the nearest point of it a kart off it heads for, in meters.
const REJOIN := 3.0
## How far ahead along the line it steers for: this many seconds of its own speed, within these
## many meters.
const LOOK_TIME := 0.4
const LOOK_LEAST := 1.6
const LOOK_MOST := 4.0
## How much quicker or slower than the person it goes for each second off its time, and at most.
const CATCH := 0.6
const CATCH_MOST := 0.5
const EASE_MOST := 0.7
## Further behind its time than this, it goes flat out.
const FAR_BEHIND := 1.5
## How near it lets the kart in front of it come before it eases off, and before it stops.
const KEEP := 3.6
const KEEP_HARD := 2.4
## How far round its nose a kart counts as in front of it.
const IN_FRONT := 0.45
## Getting out of the person's way: how near they have to come within how long.
const WAY_CLEAR := 1.8
const WAY_HORIZON := 0.9
const WAY_NEAR := 7.0
## How many of the line's points it looks over, back and ahead, for where it is.
const LOOK_BACK := 8
const LOOK_AHEAD := 24

var brain: BotBrain
## The person's line, oldest point first, a point every [member every] seconds; how far behind
## them it drives, in seconds; and their kart.
var line := PackedVector3Array()
var every := 0.1
var behind := 1.0
var person: Kart

## Where it is on the line, in seconds behind the person; below 0 when it is off it and it has to
## be looked for along the whole of it. And the nearest point of the line, as for [method _point].
var _back := -1.0
var _nearest := 0.0
var _holding := false


func _init(owner: BotBrain) -> void:
	brain = owner


## Led along [param person_line], recorded every [param step] seconds, [param lag] seconds
## behind [param leader].
func follow(person_line: PackedVector3Array, step: float, lag: float, leader: Kart) -> void:
	line = person_line
	every = step
	behind = lag
	person = leader


## No longer led.
func let_go() -> void:
	line = PackedVector3Array()
	person = null
	_back = -1.0
	_holding = false


func is_on() -> bool:
	return line.size() >= 2 and person != null and is_instance_valid(person)


## Whether it is waiting on purpose, behind somebody stopped in front of it.
func holding() -> bool:
	return _holding


## Where to get back onto the line from off it: a little along from the nearest point of it, so
## that it comes in going the person's way, but never nearer the person than its time behind them.
func back_to() -> Vector3:
	var on_time := clampf(float(line.size() - 1) - behind / every, 0.0, float(line.size() - 1))
	return _point(minf(_on_by(_nearest, REJOIN), on_time))


## The driving for this tick, into its brain's input, never firing and never on nitro; false when
## it is off the line, for the brain to steer it back.
func drive(delta: float) -> bool:
	var kart := brain.kart
	var input := brain.input
	input.fire = false
	input.nitro = false
	var at := Vector3(kart.global_position.x, 0.0, kart.global_position.z)
	var found := _find(at, delta)
	if found < 0.0:
		_holding = false
		return false
	var forward := kart.motor.forward_vector()
	var speed := kart.motor.forward_speed
	var look := clampf(absf(speed) * LOOK_TIME, LOOK_LEAST, LOOK_MOST)
	var to := _point(_on_by(found, look)) - at
	var angle := forward.signed_angle_to(to, Vector3.UP) if not to.is_zero_approx() else 0.0
	input.steer = -clampf(angle * BotBrain.STEER_GAIN, -1.0, 1.0)
	input.handbrake = false
	var wanted := _speed_on(found)
	var late := _back - behind
	if late > FAR_BEHIND:
		wanted = kart.motor.max_speed()
	else:
		wanted *= 1.0 + clampf(late * CATCH, -EASE_MOST, CATCH_MOST)
	if absf(angle) > 1.0:
		wanted *= 0.5
	wanted = minf(wanted, _room(at, forward, wanted))
	_holding = wanted < 0.3
	_out_of_the_way(at, forward)
	var top := maxf(kart.motor.max_speed(), 0.1)
	input.throttle = clampf(wanted / top, 0.0, 1.0)
	input.brake = clampf((speed - wanted - 1.0) / 4.0, 0.0, 1.0)
	if input.brake > 0.0 or _holding:
		input.throttle = 0.0
	brain.stuck.step(delta)
	return true


## Where it is on the line, as a point's index with the share of the way to the next, or below 0
## when it is off it; looked for near where it was the tick before, the line having moved on
## meanwhile, so a line that crosses itself does not throw it onto the other crossing.
func _find(at: Vector3, delta: float) -> float:
	var last := line.size() - 1
	var from := 0
	var to := last - 1
	if _back >= 0.0:
		var was := float(last) - (_back + delta) / every
		from = clampi(floori(was) - LOOK_BACK, 0, last - 1)
		to = clampi(floori(was) + LOOK_AHEAD, 0, last - 1)
	var best := INF
	var found := -1.0
	for i: int in range(from, to + 1):
		var a := line[i]
		var segment := line[i + 1] - a
		var length := segment.length_squared()
		var share := clampf((at - a).dot(segment) / length, 0.0, 1.0) if length > 1e-6 else 0.0
		var distance := at.distance_squared_to(a + segment * share)
		if distance < best:
			best = distance
			found = float(i) + share
	_nearest = maxf(found, 0.0)
	var reach := OFF_LINE if _back >= 0.0 else ON_LINE
	if found < 0.0 or best > reach * reach:
		_back = -1.0
		return -1.0
	_back = (float(last) - found) * every
	return found


## How far along the line [param meters] on from [param from] is, toward the person, as for
## [method _point].
func _on_by(from: float, meters: float) -> float:
	var left := meters
	var at := _point(from)
	var i := floori(from) + 1
	while i < line.size():
		var step := at.distance_to(line[i])
		if step >= left:
			return float(i - 1) + 1.0 - (step - left) / maxf(line[i - 1].distance_to(line[i]), 1e-4)
		left -= step
		at = line[i]
		i += 1
	return float(line.size() - 1)


## How fast the person went at [param on] along the line.
func _speed_on(on: float) -> float:
	var i := clampi(floori(on), 0, line.size() - 2)
	var a := line[maxi(i - 1, 0)]
	var b := line[mini(i + 2, line.size() - 1)]
	var steps := float(mini(i + 2, line.size() - 1) - maxi(i - 1, 0))
	return a.distance_to(b) / (every * maxf(steps, 1.0))


## How fast it may go with whoever is in front of it: no slower than [param wanted] with nobody
## near, easing off to a stop as they come within reach.
func _room(at: Vector3, forward: Vector3, wanted: float) -> float:
	var most := wanted
	for slot: PlayerSlot in brain.match_node.slots:
		var other := slot.kart
		if other == null or other == brain.kart or not other.is_active():
			continue
		var to := Vector3(other.global_position.x, 0.0, other.global_position.z) - at
		var distance := to.length()
		if distance >= KEEP or distance < 0.01 or forward.dot(to / distance) < IN_FRONT:
			continue
		var share := clampf((distance - KEEP_HARD) / (KEEP - KEEP_HARD), 0.0, 1.0)
		most = minf(most, wanted * share)
	return most


## Off to the side the kart is already on when the person comes at it, rather than meeting them.
func _out_of_the_way(at: Vector3, forward: Vector3) -> void:
	var from := Vector3(person.global_position.x, 0.0, person.global_position.z)
	var relative := at - from
	if relative.length() > WAY_NEAR:
		return
	var closing := person.motor.velocity - brain.kart.motor.velocity
	if BotBrain.closest_approach(relative, closing, WAY_HORIZON) >= WAY_CLEAR:
		return
	var going := Vector3(person.motor.velocity.x, 0.0, person.motor.velocity.z)
	if going.length() < 1.0:
		return
	var side := going.cross(Vector3.UP).normalized()
	if relative.dot(side) < 0.0:
		side = -side
	var angle := forward.signed_angle_to(side + forward * 0.5, Vector3.UP)
	brain.input.steer = -clampf(angle * 2.0, -1.0, 1.0)
	_holding = false


## The point at [param on] along the line, between two of its points.
func _point(on: float) -> Vector3:
	var i := clampi(floori(on), 0, line.size() - 1)
	var j := mini(i + 1, line.size() - 1)
	return line[i].lerp(line[j], on - float(i))
