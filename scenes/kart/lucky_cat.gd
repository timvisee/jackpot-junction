class_name LuckyCat
extends DressMoments
## The supporter pack's Lucky cat, GAME.md 10.8: a beckoning cat sat on the helmet, its raised paw
## waving, quicker for a moment after chips are picked up; both paws up while its kart cashes out;
## its paws over its eyes while its kart is dead. On a kart only to look at, in the kart dialog or
## on the podium, it waves and now and then bows.

## How far the waving paw swings either way about where it is raised, in radians, and how fast,
## and how fast for a while after chips are picked up, and how long that while is.
const WAVE := 0.35
const WAVE_RATE := 6.0
const EAGER_RATE := 14.0
const EAGER := 1.5
## How the paws are held: the waving one raised, the one with the coin held down in front, both up
## for a cash-out, and both over the eyes, each a turn about the shoulder's z and its x.
const RAISED := Vector2(-0.45, 0.0)
const HOLDING := Vector2(0.0, 0.0)
const CHEER := Vector2(-2.3, 0.0)
const OVER_EYES := Vector2(-1.2, -1.1)
## How quickly the paws come round to how they are held.
const EASE := 10.0
## How often a cat only to look at bows, in seconds, how far, and how long a bow takes.
const BOW_EVERY := 6.0
const BOW := 0.35
const BOW_TAKES := 0.8

## The cat, which bows, and its two paws: the waving one on its right and the one with the coin.
var cat: Node3D
var waving: Node3D
var holding: Node3D
var _eager := 0.0
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
	var rate := EAGER_RATE if _eager > 0.0 else WAVE_RATE
	var wave := sin(clock * rate) * WAVE if alive and not cashing else 0.0
	if waving != null:
		waving.rotation = Vector3(_right.y, 0.0, _right.x + wave)
	if holding != null:
		holding.rotation = Vector3(_left.y, 0.0, _left.x)
	if cat != null:
		var bowing := 0.0
		if pot < 0.0:
			var into := fmod(clock, BOW_EVERY)
			if into < BOW_TAKES:
				bowing = sin(into / BOW_TAKES * PI) * BOW
		cat.rotation.x = -bowing
