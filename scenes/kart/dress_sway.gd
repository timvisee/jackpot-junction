class_name DressSway
extends Node
## Moves what flies from a kart's pole, GAME.md 4.4: a flag streams back from the way the kart is
## going, swings round the pole as it turns and beats to and fro round it the faster it goes, never
## rolling over on its edge, hanging when it stops; a windsock fills as it goes faster and droops
## when it stops, rising and falling with the wind; a tape runs out the faster it goes and winds
## back in when it stops; dice on strings hang back as the kart drives off, swing forward as it
## brakes and out as it turns, and swing back. The look alone: it is worked out on every screen
## from where the flag has been, and nothing in a match feels it.

## What it moves: cloth, a windsock, a tape run out, or things on strings.
enum Kind { CLOTH, SOCK, TAPE, DICE }

## How stiffly a flag comes round to the way the wind blows, and how quickly that settles.
const TURN_STIFFNESS := 70.0
const TURN_DAMPING := 9.0
## How far round a flag may stream from straight back, either way, in radians.
const MOST_TURN := 1.25
## How fast counts as flying straight out, in meters a second, and how fast is too slow to blow
## anything about.
const FULL_SPEED := 10.0
const STILL := 0.6
## How quickly a windsock fills as the kart picks up speed and empties as it slows, and the tape
## runs out and winds back in, one over the seconds it takes to come most of the way: the wind it
## catches, not the speed of the moment, so it rises and falls rather than twitching.
const FILL := 3.0
## How far cloth and a windsock hang at a standstill, in radians down from straight out.
const CLOTH_DROOP := 0.55
const SOCK_DROOP := 1.15
## How far the tape is run out at a standstill, of the whole of it run out at speed.
const TAPE_SHORT := 0.35
## How far cloth beats to and fro round its pole at speed, in radians, and how fast, its beat
## quickening with the speed.
const FLUTTER := 0.12
const FLUTTER_BEAT := 7.0
## A die's string, a pendulum: how stiffly it swings back, gravity over its length, how quickly a
## swing dies, how hard the kart's change of speed throws it, one over its length, and how far it
## may swing. Driven on, it hangs back for as long as the kart picks up speed; braking, it swings
## forward; turning, out to the side. The most change of speed a step is taken to have, so a kart
## put back on the floor at a respawn does not throw the dice round and round.
const SWING_STIFFNESS := 50.0
const SWING_DAMPING := 2.2
const SWING_THROW := 6.0
const MOST_SWING := 1.2
const MOST_JOLT := 1.0
## On top of the swing, a die judders the faster the kart goes, so a steady fast turn, which would
## otherwise hold it out to one side dead still, keeps it alive: how far in radians at full speed,
## and how fast, each die on its own beat so the two do not judder as one.
const DICE_JITTER := 0.09
const DICE_BEAT := 12.0
## The fastest a flag is taken to move, so a kart put back on the floor at a respawn does not
## throw everything round.
const MOST_SPEED := 30.0
## How quickly a flag settled at a standstill comes round to straight back, see [method settle].
const SETTLE_RATE := 3.0

var kind := Kind.CLOTH
## What swings: the pivots the cloth, the sock, the tape or each die and its string hang from.
var pivots: Array[Node3D] = []

var _primed := false
var _last := Vector3.ZERO
var _velocity := Vector3.ZERO
var _time := 0.0
var _turn := 0.0
var _turning := 0.0
## How full of wind it is, 0 hanging to 1 flying straight out, eased toward the speed.
var _blown := 0.0
## Each pivot's swing about its two axes across, and how fast it is swinging.
var _swing: Array[Vector2] = []
var _swinging: Array[Vector2] = []


## On the steps the kart moves on: worked out from where the flag has got to between two of them,
## its speed is the kart's own. Sampled every drawn frame, it was nothing on a frame between two
## steps and twice as much on the next, and the windsock jittered and the dice's throws cancelled.
func _physics_process(delta: float) -> void:
	var holder := get_parent() as Node3D
	if holder == null or delta <= 0.0 or not holder.is_inside_tree():
		return
	step(holder.global_position, holder.global_basis.orthonormalized(), delta)


## One step of [param delta] seconds, the flag's pole now at [param at] turned [param facing].
func step(at: Vector3, facing: Basis, delta: float) -> void:
	var velocity := Vector3.ZERO
	if _primed:
		velocity = ((at - _last) / delta).limit_length(MOST_SPEED)
	_primed = true
	_last = at
	var change := (velocity - _velocity).limit_length(MOST_JOLT)
	_velocity = velocity
	_time += delta
	# In the flag's own frame: its cloth flies out along +X, which is straight back off the kart.
	var local := facing.inverse() * velocity
	var speed := Vector2(local.x, local.z).length()
	match kind:
		Kind.DICE:
			_swing_dice(facing.inverse() * change, delta)
		_:
			_fly(local, speed, delta)


## Cloth, a windsock or a tape: round to the wind, which blows the other way to the kart, hanging
## the slower it goes and fluttering the faster; the sock filling and the tape running out as the
## wind it catches rises.
func _fly(local: Vector3, speed: float, delta: float) -> void:
	if speed > STILL:
		var wind := clampf(atan2(local.z, -local.x), -MOST_TURN, MOST_TURN)
		_turning += (
			(angle_difference(_turn, wind) * TURN_STIFFNESS - _turning * TURN_DAMPING) * delta
		)
	else:
		_turning -= _turning * TURN_DAMPING * delta
	_turn = clampf(_turn + _turning * delta, -MOST_TURN, MOST_TURN)
	var wanted := clampf(speed / FULL_SPEED, 0.0, 1.0)
	_blown = lerpf(_blown, wanted, 1.0 - exp(-FILL * delta))
	var blown := _blown if kind != Kind.CLOTH else wanted
	var droop := lerpf(SOCK_DROOP if kind == Kind.SOCK else CLOTH_DROOP, 0.04, blown)
	var flutter := sin(_time * (FLUTTER_BEAT + speed * 0.9)) * FLUTTER * (0.15 + 0.85 * blown)
	if kind == Kind.SOCK:
		flutter *= 0.3
	for pivot: Node3D in pivots:
		pivot.rotation = Vector3(0.0, _turn + flutter, -droop)
		if kind == Kind.TAPE:
			pivot.scale = Vector3(lerpf(TAPE_SHORT, 1.0, blown), 1.0, 1.0)


## Brought to rest, a step of [param delta] seconds at a time, as on a kart standing still that is
## turned by hand rather than driven, the kart dialog's, see [KartStage]: round to straight back
## and hanging, dice swinging down to still, eased there rather than snapped. Being turned about
## its own middle is no wind, and a flag left swung round its pole by it showed its edge.
func settle(delta: float) -> void:
	_primed = false
	_velocity = Vector3.ZERO
	_turning = 0.0
	_turn = lerp_angle(_turn, 0.0, 1.0 - exp(-SETTLE_RATE * delta))
	_time += delta
	if kind == Kind.DICE:
		_swing_dice(Vector3.ZERO, delta)
	else:
		_fly(Vector3.ZERO, 0.0, delta)


## How full of wind it is now, 0 hanging to 1 flying straight out.
func blown() -> float:
	return _blown


## Dice on strings: each a pendulum, thrown by the kart's change of speed and swinging back.
func _swing_dice(change: Vector3, delta: float) -> void:
	while _swing.size() < pivots.size():
		_swing.append(Vector2.ZERO)
		_swinging.append(Vector2.ZERO)
	# The faster the kart, the more the dice judder on top of their swing, see [constant DICE_JITTER].
	var jitter := DICE_JITTER * clampf(_velocity.length() / FULL_SPEED, 0.0, 1.3)
	for i: int in pivots.size():
		# A die swings the other way to the kart's change of speed, as anything hung in a kart
		# does, across both ways the string can go, and a little more for the second, on a longer
		# string. Turned about its x, a die hanging down swings toward -z for a turn the right
		# way, and about its z toward +x.
		var thrown := Vector2(change.z, -change.x) * SWING_THROW * (1.0 + 0.3 * float(i))
		var pull := -_swing[i] * SWING_STIFFNESS - _swinging[i] * SWING_DAMPING
		_swinging[i] += pull * delta + thrown
		_swing[i] = (_swing[i] + _swinging[i] * delta).limit_length(MOST_SWING)
		# The judder laid over the swing rather than fed into it, so it shivers the dice without
		# building up: two beats a little apart, and a phase of its own for each die.
		var beat := _time * DICE_BEAT + float(i) * 2.1
		var shiver := (
			Vector2(sin(beat) + 0.5 * sin(beat * 1.7 + 1.1), cos(beat * 0.9 + 0.6)) * jitter
		)
		pivots[i].rotation = Vector3(_swing[i].x + shiver.x, 0.0, _swing[i].y + shiver.y)


## Where the die on the string of pivot [param i] hangs now, from where its string is tied, in the
## flag's own frame.
func hang_of(i: int) -> Vector3:
	return pivots[i].basis * Vector3.DOWN
