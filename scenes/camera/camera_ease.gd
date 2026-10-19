class_name CameraEase
extends RefCounted
## How [CameraRig] eases toward what its framing asks for, GAME.md 8.2: where it looks, or how far
## back it sits with the lift and the slide of its aim, three numbers that move together. Eased in
## two steps, so that nothing the framing asks for, however sudden, moves the camera suddenly: an
## aim follows the framing the way the rig always eased, exponentially, quickly or slowly; and the
## camera follows the aim on a critically damped spring, which carries its speed from frame to
## frame, so a move starts and stops gently and a new aim bends a move rather than starting another.
##
## Eased by the aim alone, the camera set off at its fastest the very frame something new was asked
## of it: a kart appearing across the room took it from standing to a hundred and sixty meters a
## second in a frame, and the HUD's answers, which come in ten times a second, nudged it ten times a
## second. Together the two take as long to catch up with something moving steadily as the aim
## alone did, so the camera keeps up with fast driving as it always has.

## How long the spring takes, in seconds: a part of the time the rig takes to ease, the aim taking
## the rest. Short, so most of that time is still the aim's, and long enough to round off a start.
const SPRING := 0.2

## Where the camera is, how fast it is going there, and the aim the spring is pulling it toward.
var value := Vector3.ZERO
var speed := Vector3.ZERO
var aim := Vector3.ZERO


## Puts it straight at [param at], standing still: a cut rather than a move.
func place(at: Vector3) -> void:
	value = at
	aim = at
	speed = Vector3.ZERO


## Eases on [param delta] seconds toward [param target], taking about [param lag] seconds to catch
## up with something moving steadily: the aim the part of it the spring does not take, see
## [constant SPRING]. Worked out exactly for the time given rather than stepped, so it comes to the
## same however the frames fall.
func follow(target: Vector3, lag: float, delta: float) -> void:
	var spring := minf(lag, SPRING)
	var ahead := lag - spring
	aim = aim.lerp(target, 1.0 - exp(-delta / ahead)) if ahead > 0.001 else target
	var omega := 2.0 / maxf(spring, 0.001)
	var off := value - aim
	var push := speed + off * omega
	var fade := exp(-omega * delta)
	value = aim + (off + push * delta) * fade
	speed = (speed - push * (omega * delta)) * fade
