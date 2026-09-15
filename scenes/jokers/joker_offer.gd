class_name JokerOffer
extends RefCounted
## The choice a player makes while dead: take one of the offered jokers or skip. A player holding
## five must first pick a held joker to destroy. Humans steer it with their device; bots and
## tests call the methods directly. Respawn waits until [method is_done].

enum Stage { CHOOSING, REPLACING, DONE }

var choices: Array[Joker] = []
var stage := Stage.CHOOSING
var selected := 0
var chosen: Joker
var taken: Joker

var _kart: Kart
var _was_down: Dictionary[StringName, bool] = {}


func _init(kart: Kart, offered: Array[Joker]) -> void:
	_kart = kart
	choices = offered
	if choices.is_empty():
		stage = Stage.DONE


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
	if stage == Stage.CHOOSING:
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


## Reads the player's device: number keys pick directly, prev and next move the cursor, the item
## button confirms, the destroy button skips or cancels.
func poll(device: int) -> void:
	if stage == Stage.DONE:
		return
	var options := choices.size() if stage == Stage.CHOOSING else _kart.jokers.count()
	if _pressed(InputActions.JOKER_NEXT, device):
		selected = (selected + 1) % options
	if _pressed(InputActions.JOKER_PREV, device):
		selected = posmod(selected - 1, options)
	var selects: Array[StringName] = [
		InputActions.JOKER_SELECT_1,
		InputActions.JOKER_SELECT_2,
		InputActions.JOKER_SELECT_3,
		InputActions.JOKER_SELECT_4,
		InputActions.JOKER_SELECT_5,
	]
	for i: int in selects.size():
		if _pressed(selects[i], device) and i < options:
			_confirm(i)
			return
	if _pressed(InputActions.USE_ITEM, device):
		_confirm(selected)
		return
	if _pressed(InputActions.JOKER_DESTROY, device):
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
