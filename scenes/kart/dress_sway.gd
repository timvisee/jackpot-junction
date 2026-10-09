class_name DressSway
extends Node
## Moves what flies from a kart's pole, GAME.md 4.4: a flag streams back from the way the kart is
## going, swings round the pole as it turns and beats to and fro round it the faster it goes, never
## rolling over on its edge, hanging when it stops; a windsock fills as it goes faster and droops
## when it stops; dice on strings swing at every turn, bump and stop, and jiggle back. The look
## alone: it is worked out on every screen from where the flag has been, and nothing in a match
## feels it.

## What it moves: cloth, a windsock, or things on strings.
enum Kind { CLOTH, SOCK, DICE }

## How stiffly a flag comes round to the way the wind blows, and how quickly that settles.
const TURN_STIFFNESS := 70.0
const TURN_DAMPING := 9.0
## How far round a flag may stream from straight back, either way, in radians.
const MOST_TURN := 1.25
## How fast counts as flying straight out, in meters a second, and how fast is too slow to blow
## anything about.
const FULL_SPEED := 10.0
const STILL := 0.6
## How far cloth and a windsock hang at a standstill, in radians down from straight out.
const CLOTH_DROOP := 0.55
const SOCK_DROOP := 1.15
## How far cloth beats to and fro round its pole at speed, in radians, and how fast, its beat
## quickening with the speed.
const FLUTTER := 0.12
const FLUTTER_BEAT := 7.0
## A die's string, a pendulum: how stiffly it swings back, gravity over its length, how quickly a
## swing dies, how hard a change of the kart's speed throws it, one over its length, and how far it
## may swing. The most change of speed a frame is taken to have, so a kart put back on the floor
## at a respawn does not throw the dice round and round.
const SWING_STIFFNESS := 50.0
const SWING_DAMPING := 3.2
const SWING_THROW := 3.0
const MOST_SWING := 0.75
const MOST_JOLT := 3.0
## The fastest a flag is taken to move, so a kart put back on the floor at a respawn does not
## throw everything round.
const MOST_SPEED := 30.0

var kind := Kind.CLOTH
## What swings: the pivots the cloth, the sock or each die and its string hang from.
var pivots: Array[Node3D] = []

var _primed := false
var _last := Vector3.ZERO
var _velocity := Vector3.ZERO
var _time := 0.0
var _turn := 0.0
var _turning := 0.0
## Each pivot's swing about its two axes across, and how fast it is swinging.
var _swing: Array[Vector2] = []
var _swinging: Array[Vector2] = []


func _process(delta: float) -> void:
	var holder := get_parent() as Node3D
	if holder == null or delta <= 0.0 or not holder.is_inside_tree():
		return
	var at := holder.global_position
	var velocity := Vector3.ZERO
	if _primed:
		velocity = ((at - _last) / delta).limit_length(MOST_SPEED)
	_primed = true
	_last = at
	var change := (velocity - _velocity).limit_length(MOST_JOLT)
	_velocity = velocity
	_time += delta
	# In the flag's own frame: its cloth flies out along +X, which is straight back off the kart.
	var local := holder.global_basis.orthonormalized().inverse() * velocity
	var flat := Vector2(local.x, local.z)
	var speed := flat.length()
	match kind:
		Kind.DICE:
			_swing_dice(holder.global_basis.orthonormalized().inverse() * change, delta)
		_:
			_fly(local, speed, delta)


## Cloth or a windsock: round to the wind, which blows the other way to the kart, hanging the
## slower it goes and fluttering the faster.
func _fly(local: Vector3, speed: float, delta: float) -> void:
	if speed > STILL:
		var wind := clampf(atan2(local.z, -local.x), -MOST_TURN, MOST_TURN)
		_turning += (
			(angle_difference(_turn, wind) * TURN_STIFFNESS - _turning * TURN_DAMPING) * delta
		)
	else:
		_turning -= _turning * TURN_DAMPING * delta
	_turn = clampf(_turn + _turning * delta, -MOST_TURN, MOST_TURN)
	var blown := clampf(speed / FULL_SPEED, 0.0, 1.0)
	var droop := lerpf(SOCK_DROOP if kind == Kind.SOCK else CLOTH_DROOP, 0.04, blown)
	var flutter := sin(_time * (FLUTTER_BEAT + speed * 0.9)) * FLUTTER * (0.15 + 0.85 * blown)
	if kind == Kind.SOCK:
		flutter *= 0.3
	for pivot: Node3D in pivots:
		pivot.rotation = Vector3(0.0, _turn + flutter, -droop)


## Dice on strings: each a pendulum, thrown by the kart's change of speed and swinging back.
func _swing_dice(change: Vector3, delta: float) -> void:
	while _swing.size() < pivots.size():
		_swing.append(Vector2.ZERO)
		_swinging.append(Vector2.ZERO)
	for i: int in pivots.size():
		# A die swings the other way to the kart's change of speed, across both ways the string can
		# go, and a little more for the second, on a longer string.
		var thrown := Vector2(-change.z, change.x) * SWING_THROW * (1.0 + 0.3 * float(i))
		var pull := -_swing[i] * SWING_STIFFNESS - _swinging[i] * SWING_DAMPING
		_swinging[i] += pull * delta + thrown
		_swing[i] = (_swing[i] + _swinging[i] * delta).limit_length(MOST_SWING)
		pivots[i].rotation = Vector3(_swing[i].x, 0.0, _swing[i].y)
