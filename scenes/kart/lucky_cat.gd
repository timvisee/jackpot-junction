class_name LuckyCat
extends DressMoments
## The supporter pack's Lucky cat, GAME.md 10.8: a beckoning cat sat on the helmet, its raised paw
## beckoning, bent forward and back again as a maneki-neko's is, quicker for a moment after chips
## are picked up; both paws up while its kart cashes out; its paws over its eyes while its kart is
## dead.

## How far forward the raised paw beckons from upright, in radians, how many times a second, how
## many for a while after chips are picked up, and how long that while is.
const BECKON := 0.6
const WAVE_RATE := 1.1
const EAGER_RATE := 2.4
const EAGER := 1.5
## How the paws are held: the waving one raised, the one with the coin held down in front, both up
## for a cash-out, and both over the eyes, each a turn about the shoulder's z and its x.
const RAISED := Vector2(-0.45, 0.0)
const HOLDING := Vector2(0.0, 0.0)
const CHEER := Vector2(-2.3, 0.0)
const OVER_EYES := Vector2(-1.2, -1.1)
## How quickly the paws come round to how they are held.
const EASE := 10.0

## The cat and its two paws: the beckoning one on its right and the one with the coin.
var cat: Node3D
var waving: Node3D
var holding: Node3D
var _eager := 0.0
## How far through its beckon the paw is, in turns, so it keeps its place when it quickens.
var _beat := 0.0
var _left := Vector2.ZERO
var _right := Vector2.ZERO


func _picked(_count: int) -> void:
	_eager = EAGER


func tick(delta: float) -> void:
	_eager = maxf(0.0, _eager - delta)
	var right := RAISED
	var left := HOLDING
	if not alive:
		right = OVER_EYES
		left = Vector2(OVER_EYES.x, -OVER_EYES.y)
	elif cashing:
		right = CHEER
		left = Vector2(-CHEER.x, 0.0)
	var follow := 1.0 - exp(-EASE * delta)
	_right = _right.lerp(right, follow)
	_left = _left.lerp(left, follow)
	_beat = fmod(_beat + (EAGER_RATE if _eager > 0.0 else WAVE_RATE) * delta, 1.0)
	# Forward, toward the cat's face, and back to upright: never behind it.
	var beckon := -(0.5 - 0.5 * cos(_beat * TAU)) * BECKON if alive and not cashing else 0.0
	if waving != null:
		waving.rotation = Vector3(_right.y + beckon, 0.0, _right.x)
	if holding != null:
		holding.rotation = Vector3(_left.y, 0.0, _left.x)
