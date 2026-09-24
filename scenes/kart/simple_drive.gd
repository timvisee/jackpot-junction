class_name SimpleDrive
extends RefCounted
## Simple driving, GAME.md 4.2: the stick, or the arrow keys, say which way on the screen to go,
## and this works the wheel and the pedals to take the kart there. Pushing any way drives, letting
## go brakes, and the kart turns to the last way pushed even after it has been let go of, so a
## flick of the stick points the cannon. Free of scene nodes, like [KartMotor], so it can be driven
## against the motor in a test.

## How far the kart has to be off the way wanted for the wheel to be at full lock, in degrees. Less
## than this turns it by as much less, which is what stops it sawing either side of the way.
const FULL_LOCK_DEG := 25.0
## Within this of the way wanted the gas is down as far as the push; past [constant
## TURN_FIRST_DEG] the kart turns before it goes, and between the two the gas comes in as the nose
## comes round.
const DRIVE_DEG := 60.0
const TURN_FIRST_DEG := 120.0
## Slower than this, in meters a second, a kart let go of has stopped: the brake comes off rather
## than reversing it.
const STOPPED := 0.3
## Rolling backwards faster than this, the wheel works the other way round, and so it is turned the
## other way round: a kart only goes backwards here when something knocked it there.
const BACKWARDS := 1.0
## How long a way has to be held, in seconds, to take over from the way held before it as the one
## the kart turns to on letting go. Two keys held for a diagonal never come up together, and the
## one left down for the moment between is not the way anybody meant.
const SETTLE := 0.08
## How far a push can move from one tick to the next and still be the same one, in degrees: a
## thumb sweeping the stick round is one push, a key added or let go of is another.
const SAME_DEG := 12.0
## Let go of and within this of the way last pushed, in degrees, the kart has got there, and that
## is the end of it: a bump or a wall that turns it afterwards is not turned back against.
const ARRIVED_DEG := 1.0

## The way the kart is turning to, flat and of unit length on the floor, or zero before anybody
## has pushed anything.
var wanted := Vector3.ZERO

## The way being pushed right now, zero while nothing is, and how long it has been.
var _held := Vector3.ZERO
var _held_for := 0.0


## The floor's up and right as the camera sees them, for turning a push on the screen into a way
## on the floor: [code][up, right][/code]. Straight up the screen is away from the camera, and
## without one it is -Z, which is where the camera of 8.2 looks.
static func screen_axes(camera: Camera3D) -> Array[Vector3]:
	if camera == null:
		return [Vector3.FORWARD, Vector3.RIGHT]
	var basis := camera.global_basis
	var up := Vector3(-basis.z.x, 0.0, -basis.z.z)
	if up.length() < 0.01:
		# Looking straight down, where the camera's own up is the top of the screen.
		up = Vector3(basis.y.x, 0.0, basis.y.z)
	up = up.normalized()
	return [up, up.cross(Vector3.UP)]


## Fills in [param input]'s wheel and pedals for a [param push] on the screen, x right and y down,
## as long as 1 at most. [param motor] is the kart's, null for a kart not there yet, whose engine
## the push only revs.
func drive(
	input: KartInput, push: Vector2, axes: Array[Vector3], motor: KartMotor, delta: float
) -> void:
	var amount := minf(push.length(), 1.0)
	var holding := amount > 0.0
	var way := Vector3.ZERO
	if holding:
		way = (axes[1] * push.x - axes[0] * push.y).normalized()
		_remember(way, delta)
	else:
		_held = Vector3.ZERO
		_held_for = 0.0
	input.steer = 0.0
	input.throttle = amount
	input.brake = 0.0
	if motor == null:
		return
	var aim := way if holding else wanted
	if not aim.is_zero_approx():
		input.steer = _steer_to(aim, motor)
	if not holding and absf(input.steer) * FULL_LOCK_DEG < ARRIVED_DEG:
		wanted = Vector3.ZERO
		input.steer = 0.0
	if holding:
		var off := rad_to_deg(absf(motor.forward_vector().signed_angle_to(aim, Vector3.UP)))
		var gas := clampf((TURN_FIRST_DEG - off) / (TURN_FIRST_DEG - DRIVE_DEG), 0.0, 1.0)
		input.throttle = amount * gas
		return
	# Let go of: stop, unless the nitro is lit, which drives on by itself.
	input.throttle = 0.0
	if motor.forward_speed > STOPPED and not input.nitro:
		input.brake = 1.0


## How far over to put the wheel to turn toward [param aim]. What is turned toward it is where the
## kart is going: the nose, except in a slide, where the nose leads and aiming it at the way wanted
## would send the kart wide of it.
func _steer_to(aim: Vector3, motor: KartMotor) -> float:
	var going := motor.forward_vector()
	if motor.drifting and motor.velocity.length() > 1.0:
		going = motor.velocity.normalized()
	var off := going.signed_angle_to(aim, Vector3.UP)
	# Turning left is a positive angle and a negative wheel.
	var steer := -clampf(off / deg_to_rad(FULL_LOCK_DEG), -1.0, 1.0)
	return -steer if motor.forward_speed < -BACKWARDS else steer


## Keeps track of the way to turn to once let go. A push from nothing is taken at once, so a flick
## counts however quick it was; a push that changes while held takes over once held for [constant
## SETTLE], so the key let go of a moment before the other does not count.
func _remember(way: Vector3, delta: float) -> void:
	var fresh := _held.is_zero_approx()
	if fresh or rad_to_deg(_held.angle_to(way)) > SAME_DEG:
		_held_for = 0.0
	_held = way
	_held_for += delta
	if fresh or _held_for >= SETTLE or wanted.is_zero_approx():
		wanted = way
