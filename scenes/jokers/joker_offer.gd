class_name JokerOffer
extends RefCounted
## The choice a player makes while dead: take one of the offered jokers or skip. A player holding
## five must first pick a held joker to destroy. Humans steer it with their device; bots and
## tests call the methods directly. Respawn waits until [method is_done].

enum Stage { CHOOSING, REPLACING, DONE }

## How far a stick has to be pushed to count as a step to the next card.
const STEER_STEP := 0.6
## How long the cards stand there before they can be answered, GAME.md 3.7. A player is killed
## with a thumb on the fire button and the pick opens under that same thumb, so without a moment
## first the card under the cursor is claimed before anybody has read a word of it.
const SETTLE := 0.5

var choices: Array[Joker] = []
var stage := Stage.CHOOSING
var selected := 0
var chosen: Joker
var taken: Joker
## The moment the cards may first be answered, on the engine's clock. Moving the cursor is
## allowed from the first frame: which card somebody is looking at was never the problem. Set to
## zero to open a pick that answers at once.
var answer_at := 0.0
## A pick of which of last map's jokers to keep, see [JokerKeep], rather than of a new one. It
## cannot be skipped, and it runs out: [member keep_left] seconds are left to answer it.
var keeping := false
var keep_left := 0.0

var _kart: Kart
var _was_down: Dictionary[StringName, bool] = {}
## Which way a remote player's stick was held last tick, so holding it only steps once.
var _steer_was := 0


func _init(kart: Kart, offered: Array[Joker]) -> void:
	_kart = kart
	choices = offered
	answer_at = _now() + SETTLE
	if choices.is_empty():
		stage = Stage.DONE


## Whether the cards have stood there long enough to be answered.
func is_settled() -> bool:
	return _now() >= answer_at


static func _now() -> float:
	return Time.get_ticks_msec() * 0.001


func is_done() -> bool:
	return stage == Stage.DONE


func take(index: int) -> void:
	if stage != Stage.CHOOSING or index < 0 or index >= choices.size():
		return
	chosen = choices[index]
	if _kart.jokers.is_full():
		stage = Stage.REPLACING
		selected = 0
	else:
		_finish()


func skip() -> void:
	if stage == Stage.CHOOSING and not keeping:
		stage = Stage.DONE


## Destroys the held joker at [param held_index] and takes the chosen one in its place.
func replace(held_index: int) -> void:
	if stage != Stage.REPLACING or held_index < 0 or held_index >= _kart.jokers.count():
		return
	_kart.jokers.remove_at(held_index)
	_finish()


func cancel_replace() -> void:
	if stage == Stage.REPLACING:
		stage = Stage.CHOOSING
		selected = choices.find(chosen)


## Reads the player's device: steering or the bracket keys move the cursor, number keys pick
## directly, the item or fire button confirms, the destroy button skips or cancels. Fire counts
## as well as the item button because a player sitting on a respawn pick has a thumb on it
## already, and pressing the obvious button to choose a card should choose the card.
##
## Which is also why nothing may be taken for the first [constant SETTLE] seconds: that thumb
## was on the trigger when the kart died. The cursor still moves throughout.
func poll(device: int) -> void:
	if stage == Stage.DONE:
		return
	var options := choices.size() if stage == Stage.CHOOSING else _kart.jokers.count()
	if _pressed(InputActions.JOKER_NEXT, device) or _pressed(InputActions.STEER_RIGHT, device):
		selected = (selected + 1) % options
	if _pressed(InputActions.JOKER_PREV, device) or _pressed(InputActions.STEER_LEFT, device):
		selected = posmod(selected - 1, options)
	# Every button is read whether or not it may be answered yet, so one held down through the
	# wait is not seen going down again the moment the wait is over, which is the press this is
	# here to stop.
	var direct := -1
	var selects := InputActions.JOKER_SELECTS
	for i: int in selects.size():
		if _pressed(selects[i], device) and i < options:
			direct = i
	var item := _pressed(InputActions.USE_ITEM, device)
	var fire := _pressed(InputActions.FIRE, device)
	var back := _pressed(InputActions.JOKER_DESTROY, device)
	if not is_settled():
		return
	if direct >= 0:
		_confirm(direct)
		return
	if item or fire:
		_confirm(selected)
		return
	if back:
		if stage == Stage.CHOOSING:
			skip()
		else:
			cancel_replace()


## Reads the one-tick fields of a polled input: steering or the cursor keys move, numbers pick,
## the item or fire button confirms, the destroy button skips or cancels. Used for remote players,
## whose steering arrives as an axis, so it is turned back into presses here.
func poll_input(input: KartInput) -> void:
	if stage == Stage.DONE:
		return
	var options := choices.size() if stage == Stage.CHOOSING else _kart.jokers.count()
	if options <= 0:
		return
	# A finger resting on a card, GAME.md 4.2, is reading it: the cursor goes there, and nothing is
	# answered until the finger comes up. A tap is a quick one, and arrives as the number key.
	if input.pick_inspect >= 0:
		selected = clampi(input.pick_inspect, 0, options - 1)
		_steer_was = 0
		return
	# The push rather than the wheel, which simple driving turns on its own, GAME.md 4.2.
	var steer := 0
	if absf(input.cursor) > STEER_STEP:
		steer = signi(roundi(input.cursor))
	var stepped := steer != 0 and steer != _steer_was
	_steer_was = steer
	if input.joker_next_pressed or (stepped and steer > 0):
		selected = (selected + 1) % options
	if input.joker_prev_pressed or (stepped and steer < 0):
		selected = posmod(selected - 1, options)
	if not is_settled():
		return
	if input.joker_select >= 0 and input.joker_select < options:
		_confirm(input.joker_select)
		return
	if input.use_item_pressed or input.fire_pressed:
		_confirm(selected)
		return
	if input.joker_destroy_pressed:
		if stage == Stage.CHOOSING:
			skip()
		else:
			cancel_replace()


func _confirm(index: int) -> void:
	if stage == Stage.CHOOSING:
		take(index)
	else:
		replace(index)


func _pressed(action: StringName, device: int) -> bool:
	var down := DeviceInput.pressed(action, device)
	var was: bool = _was_down.get(action, false)
	_was_down[action] = down
	return down and not was


func _finish() -> void:
	taken = _kart.jokers.add(chosen)
	stage = Stage.DONE
	Events.joker_taken.emit(_kart.slot, chosen.id)
