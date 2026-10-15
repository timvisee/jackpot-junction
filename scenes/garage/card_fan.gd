class_name CardFan
extends Control
## The card back held up as a hand of cards in the kart dialog, GAME.md 4.4a, over the kart while
## the card back is looked at: five cards in the back worn, or in the one the cursor is on in its
## rack, each the card as the game draws it, see [method CardBack.picture], fanned as the joker
## hand is, see [method JokerHand.fan_of]. Dealt up from below one card after another, swinging out
## into the fan, bobbing a little while it is held; a new back turns the cards over one after
## another, each showing it as it comes round; put down, the fan closes up and drops away.
##
## Laid out on the dialog's stage, see [BayArt]; one picture of a back drawn five times.

## How many cards, how much bigger than a joker card each is, how much more the fan's arc and tip
## are than the joker hand's, and the middle of the bottom of the hand on the stage.
const CARDS := 5
const SCALE := 1.35
const ARC_MORE := 1.6
const TILT_MORE := 1.8
const HELD_AT := Vector2(930.0, 770.0)
## How long dealing it up takes, how much later each card comes than the one before, how far below
## the hand a card comes up from, how long a card takes to turn over and how much later each turns
## than the one before, and how far the hand bobs as it is held, how fast.
const DEAL_TIME := 0.5
const STAGGER := 0.08
const DROP := 420.0
const FLIP_TIME := 0.26
const FLIP_STAGGER := 0.07
const BOB := 4.0
const BOB_SPEED := 1.8

## The back it shows, or is turning over to, one of [constant CardBack.STYLES], or -1 for none yet.
var style := -1

## The back each card shows now, which a card turning over only takes as it comes round; the
## pictures of the backs, as they are drawn; whether it is held up, how far dealt up it is, from
## 0 down to 1 up, and how far into turning the cards over, or -1.
var _shown: Array[int] = []
var _pictures: Dictionary[int, Texture2D] = {}
var _wanted := false
var _dealt := 0.0
var _clock := 0.0
var _flip := -1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = BayArt.STAGE
	_shown.resize(CARDS)
	_shown.fill(-1)
	visible = false


## Held up showing [param back]: dealt up in it if it was down, turned over to it if it showed
## another.
func hold(back: int) -> void:
	_fetch(back)
	if not _wanted and _dealt <= 0.0:
		style = back
		_shown.fill(back)
	elif back != style:
		style = back
		_flip = 0.0
	_wanted = true


## Put down: the fan closing up and dropping away.
func put_down() -> void:
	_wanted = false


## Whether it is up, or on its way up or down.
func is_held() -> bool:
	return _dealt > 0.0


## Where the card back's rope is tied on the stage: near the top of the middle card.
func anchor() -> Vector2:
	var pose := _pose(CARDS / 2)
	var card := JokerCard.SIZE * SCALE
	return pose[0] + Vector2(0.0, -card.y * 0.8).rotated(pose[1])


func _fetch(back: int) -> void:
	if _pictures.has(back):
		return
	CardBack.picture(
		back,
		self,
		func(texture: Texture2D) -> void:
			if is_instance_valid(self):
				_pictures[back] = texture
				queue_redraw()
	)


func _process(delta: float) -> void:
	_clock += delta
	_dealt = move_toward(_dealt, 1.0 if _wanted else 0.0, delta / DEAL_TIME)
	if _flip >= 0.0:
		_flip += delta
		for i: int in CARDS:
			if _flip >= i * FLIP_STAGGER + FLIP_TIME * 0.5:
				_shown[i] = style
		if _flip >= (CARDS - 1) * FLIP_STAGGER + FLIP_TIME:
			_flip = -1.0
	visible = _dealt > 0.0
	if visible:
		queue_redraw()


## Card [param i] as it is now, its bottom middle on the stage and how far it tips: out in the fan
## as far as it is dealt, up from below, bobbing.
func _pose(i: int) -> Array:
	var own := _own(i)
	var out := _overshoot(own)
	var card := JokerCard.SIZE * SCALE
	var step := card.x * (1.0 - JokerHand.OVERLAP)
	var place := JokerHand.fan_of(i, CARDS)
	var x := HELD_AT.x + place.x * step * (CARDS - 1) * 0.5 * out
	var arc := place.y * JokerHand.ARC * SCALE * ARC_MORE * out
	var y := HELD_AT.y - arc + (1.0 - own) * DROP + sin(_clock * BOB_SPEED + i * 0.8) * BOB
	var tilt := place.x * deg_to_rad(JokerHand.TILT_DEG) * TILT_MORE * out
	return [Vector2(x, y), tilt]


## How far card [param i] is dealt up, each a little after the one before.
func _own(i: int) -> float:
	var spread := float(CARDS - 1) * STAGGER / DEAL_TIME
	return clampf(_dealt * (1.0 + spread) - i * STAGGER / DEAL_TIME, 0.0, 1.0)


## [param t] eased out past where it goes and back, for a card swinging out into its place.
static func _overshoot(t: float) -> float:
	var back := t - 1.0
	return 1.0 + 2.6 * back * back * back + 1.6 * back * back


func _draw() -> void:
	var card := JokerCard.SIZE * SCALE
	var face := Rect2(Vector2(-card.x * 0.5, -card.y), card)
	for i: int in CARDS:
		var picture: Texture2D = _pictures.get(_shown[i])
		if picture == null:
			continue
		var pose := _pose(i)
		var turning := 1.0
		if _flip >= 0.0:
			var k := clampf((_flip - i * FLIP_STAGGER) / FLIP_TIME, 0.0, 1.0)
			turning = maxf(absf(cos(k * PI)), 0.02)
		var fade := clampf(_own(i) * 3.0, 0.0, 1.0)
		draw_set_transform(pose[0], pose[1], Vector2(turning, 1.0))
		draw_texture_rect(picture, face, false, Color(1, 1, 1, fade))
	draw_set_transform(Vector2.ZERO)
