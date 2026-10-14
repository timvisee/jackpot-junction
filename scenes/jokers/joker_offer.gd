class_name JokerOffer
extends RefCounted
## The choice a player makes while dead: take one of the offered jokers or skip. A player holding
## five must first pick a held joker to destroy. Humans steer it with their device; bots and
## tests call the methods directly. Respawn waits until [method is_done]. Once a pick, a card may
## be dealt again for [constant REROLL_COST] banked points, GAME.md 3.7, see [method reroll].

enum Stage { CHOOSING, REPLACING, DONE }

## How far a stick has to be pushed to count as a step to the next card.
const STEER_STEP := 0.6
## How long the cards stand there before they can be answered, GAME.md 3.7. A player is killed
## with a thumb on the fire button and the pick opens under that same thumb, so without a moment
## first the card under the cursor is claimed before anybody has read a word of it.
const SETTLE := 0.5
## How long a pick answered at a client stays answered there while the host has not yet heard,
## GAME.md 10.3: the snapshots made before the answer reached it still carry the pick, and they
## are not to put it back on the screen. Past this the answer is taken to be lost on the way, and
## the host's pick is the one to answer again.
const ANSWER_HOLD := 1.0
## What dealing a card again costs, in banked points, and how many times a pick may, GAME.md 3.7.
const REROLL_COST := 50
const REROLLS := 1
## How often a card of the pick is said in the hand of cards to keep a card dealt again from coming
## back as itself: more than any stack goes.
const NOT_AGAIN := 8

var choices: Array[Joker] = []
var stage := Stage.CHOOSING
var selected := 0
var chosen: Joker
var taken: Joker
## The moment the cards may first be answered, on the engine's clock. Moving the cursor is
## allowed from the first frame: which card somebody is looking at was never the problem. Set to
## zero to open a pick that answers at once.
var answer_at := 0.0
## When this pick was answered on this machine, or below zero while it is open, see
## [constant ANSWER_HOLD].
var answered_at := -1.0
## A pick of which of last map's jokers to keep, see [JokerKeep], rather than of a new one. It
## cannot be skipped, and it runs out: [member keep_left] seconds are left to answer it.
var keeping := false
var keep_left := 0.0
## The match that dealt the pick, which deals a card again at the host; a client's pick is the
## host's to deal again, asked by name, see [member reroll_asked].
var table: Match
var rerolls_left := REROLLS
## At a client: the card its player asked to be dealt again, for [ClientSeat] to tell the host.
var reroll_asked := &""

var _kart: Kart
## The held card a replacement took the place of, for [method answer].
var _replaced := &""
var _was_down: Dictionary[StringName, bool] = {}
## Which way a remote player's stick was held last tick, so holding it only steps once, and
## whether its nitro was, which deals a card again.
var _steer_was := 0
var _nitro_was := false


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


## Takes nothing: a respawn's pick turned down, or none of last map's jokers kept, GAME.md 9.7.
func skip() -> void:
	if stage != Stage.CHOOSING:
		return
	stage = Stage.DONE
	answered_at = _now()
	if not keeping:
		Events.joker_answered.emit(_kart.slot, &"")


## Whether this pick was answered on this machine so lately that the host may not have heard yet.
func answered_lately() -> bool:
	return is_done() and answered_at >= 0.0 and _now() - answered_at < ANSWER_HOLD


## Destroys the held joker at [param held_index] and takes the chosen one in its place.
func replace(held_index: int) -> void:
	if stage != Stage.REPLACING or held_index < 0 or held_index >= _kart.jokers.count():
		return
	_replaced = _kart.jokers.ids()[held_index]
	# Gone from the hand by the player's own choice, which its card says, GAME.md 8.3.
	if not _kart.puppet:
		Events.joker_used_up.emit(_kart.slot, _replaced, "REPLACED")
	_kart.jokers.remove_at(held_index)
	Events.joker_destroyed.emit(_kart.slot, _replaced)
	_finish()


## How this pick was answered on this machine, for the host, GAME.md 10.3: the card taken, or none
## for a skip, and the held card it took the place of, or none. Empty while it is open, and for a
## pick that had nothing to offer.
func answer() -> Array[StringName]:
	if not is_done() or answered_at < 0.0:
		return []
	return [chosen.id if taken != null else &"", _replaced]


## At the host: the pick as a client says it answered it, GAME.md 10.3, by the cards' names. The
## card has to be one this pick dealt, a skip one it may be, and a hand that is full has to name a
## card it holds to give up; anything else is no answer at all, and the pick stays open. True once
## it is answered.
func answer_with(taken_id: StringName, replaced_id: StringName) -> bool:
	if is_done() or not is_settled():
		return false
	cancel_replace()
	if taken_id == &"":
		skip()
		return is_done()
	var index := -1
	for i: int in choices.size():
		if choices[i].id == taken_id:
			index = i
	if index < 0:
		return false
	var held := _kart.jokers.ids().find(replaced_id)
	if _kart.jokers.is_full() and held < 0:
		return false
	take(index)
	replace(held)
	return is_done()


## Whether a card of this pick may be dealt again, GAME.md 3.7: still choosing, not keeping last
## map's, once a pick, and the banked points there to pay for it.
func can_reroll() -> bool:
	if stage != Stage.CHOOSING or keeping or rerolls_left <= 0 or table == null:
		return false
	var at := _kart.slot if _kart != null else -1
	return at >= 0 and at < table.slots.size() and table.slots[at].banked >= REROLL_COST


## Deals card [param index] again, GAME.md 3.7: at the host a card the pick does not show already,
## leaning to the hand's suit as a pick does, paid for out of the banked score; at a client the
## card is named for the host, whose next word shows the new one. True if it was done or asked.
func reroll(index: int) -> bool:
	if not can_reroll() or index < 0 or index >= choices.size():
		return false
	if table.puppet:
		reroll_asked = choices[index].id
		rerolls_left -= 1
		return true
	var held := _kart.jokers.ids()
	for card: Joker in choices:
		for i: int in NOT_AGAIN:
			held.append(card.id)
	var lean := JokerSuits.leading(_kart.jokers.jokers)
	var dealt := table.joker_catalog.offer(table.rng, 1, held, lean)
	if dealt.is_empty():
		return false
	table.slots[_kart.slot].banked -= REROLL_COST
	choices[index] = dealt[0]
	rerolls_left -= 1
	Events.joker_rerolled.emit(_kart.slot, index)
	return true


## At the host: a client says its player dealt the card [param id] again, see [JokerWire].
func reroll_card(id: StringName) -> bool:
	for i: int in choices.size():
		if choices[i].id == id:
			return reroll(i)
	return false


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
	var again := _pressed(InputActions.NITRO, device)
	if not is_settled():
		return
	if again and stage == Stage.CHOOSING:
		reroll(selected)
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
	# The hand of cards held open over the pick has the controls while it is, GAME.md 3.7: its
	# cursor walks and is read, and nothing here is picked, skipped or moved.
	var reading := input.joker_menu and _kart.jokers.count() > 0
	var again := input.nitro and not _nitro_was
	_nitro_was = input.nitro
	if not reading and (input.joker_next_pressed or (stepped and steer > 0)):
		selected = (selected + 1) % options
	if not reading and (input.joker_prev_pressed or (stepped and steer < 0)):
		selected = posmod(selected - 1, options)
	if reading or not is_settled():
		return
	if again and stage == Stage.CHOOSING:
		reroll(selected)
	elif input.joker_select >= 0 and input.joker_select < options:
		_confirm(input.joker_select)
	elif input.use_item_pressed or input.fire_pressed:
		_confirm(selected)
	elif input.joker_destroy_pressed:
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
	answered_at = _now()
	Events.joker_taken.emit(_kart.slot, chosen.id)
	if not keeping:
		Events.joker_answered.emit(_kart.slot, chosen.id)
