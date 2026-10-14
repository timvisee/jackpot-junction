class_name DemoPicker
extends RefCounted
## Works a pick of the demo's seats the way a player would, GAME.md 9.8, so everybody watching sees
## it worked rather than answered: the respawn pick of 3.7 and the pick of a joker to keep, 9.7. The
## cursor steps from card to card, now and then a card past the one it settles on and back, stops
## on one drawn at random and takes it a moment later; a full hand then gives up a card the same
## way. Two to four seconds a pick.

## How long the cards are read before the cursor first moves, and between its steps, in seconds.
const READ := Vector2(0.5, 0.9)
const STEP := Vector2(0.45, 0.75)
## How long the cursor rests on the card before taking it.
const REST := Vector2(0.4, 0.7)
## The chance the cursor goes one card past the one it settles on, and comes back.
const OVERSHOOT := 0.3
## The longest a pick is worked: past it, the card under the cursor is taken.
const LONGEST := 4.0

var rng := RandomNumberGenerator.new()

## The pick being worked, and which of its stages, so a new one or a full hand starts afresh.
var _offer: JokerOffer
var _stage := -1
## The steps still to take, each -1 or 1, and how long until the next thing is done.
var _steps: Array[int] = []
var _wait := 0.0
var _worked := 0.0


func _init() -> void:
	rng.randomize()


## Steps [param offer], or nothing for none, [param delta] seconds on, by [param input]'s cursor and
## fire, which polling the pick reads next. A step is a push held one tick, so the pick sees each
## one go down.
func work(input: KartInput, offer: JokerOffer, delta: float) -> void:
	input.cursor = 0.0
	if offer == null:
		_offer = null
		return
	input.fire_pressed = false
	input.use_item_pressed = false
	if offer != _offer or offer.stage != _stage:
		_plan(offer)
	_worked += delta
	_wait -= delta
	if _wait > 0.0 and _worked < LONGEST:
		return
	if _steps.is_empty() or _worked >= LONGEST:
		input.fire_pressed = offer.is_settled()
		_wait = REST.x
		return
	input.cursor = float(_steps.pop_front())
	_wait = rng.randf_range(STEP.x, STEP.y)
	if _steps.is_empty():
		_wait = rng.randf_range(REST.x, REST.y)


## The steps from where the cursor is to a card drawn at random, by the shorter way round, with
## now and then one card too far and back.
func _plan(offer: JokerOffer) -> void:
	_offer = offer
	_stage = offer.stage
	_steps.clear()
	_worked = 0.0
	_wait = rng.randf_range(READ.x, READ.y)
	var count := offer.card_count()
	if count <= 1:
		return
	var aim := rng.randi_range(0, count - 1)
	var ahead := posmod(aim - offer.selected, count)
	var behind := count - ahead
	var way := 1 if ahead <= behind else -1
	var steps := ahead if way > 0 else behind
	if steps == 0 and rng.randf() < 0.5:
		# Settled on the card it started on, after a look at the next.
		_steps.append_array([way, -way])
		return
	for _step: int in steps:
		_steps.append(way)
	if steps > 0 and rng.randf() < OVERSHOOT:
		_steps.append_array([way, -way])
