class_name JokerHolder
extends RefCounted
## The jokers a kart holds, as many as the match's [member MatchRules.joker_slots] unless one of
## them says otherwise. Adding duplicates the resource so state stays with the holder; every change
## asks the kart to rebuild its stats.

signal changed

## The hand's room with no rules to say otherwise, a kart on its own in a test say.
const MAX_JOKERS := 5

var jokers: Array[Joker] = []

var _kart: Kart


func _init(kart: Kart) -> void:
	_kart = kart


func count() -> int:
	return jokers.size()


## How many jokers may be held at once: the match's number, which the hand itself can widen,
## GAME.md 3.7 and 7.3.
func capacity() -> int:
	var room := MAX_JOKERS
	if _kart != null and _kart.rules != null:
		room = _kart.rules.joker_slots
	for joker: Joker in jokers:
		room = joker.modify_joker_slots(room)
	return room


func is_full() -> bool:
	return jokers.size() >= capacity()


func has(id: StringName) -> bool:
	for joker: Joker in jokers:
		if joker.id == id:
			return true
	return false


func ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for joker: Joker in jokers:
		result.append(joker.id)
	return result


## Attaches a copy of [param joker] and returns that copy.
func add(joker: Joker) -> Joker:
	var instance: Joker = joker.duplicate()
	jokers.append(instance)
	instance.on_attach(_kart)
	changed.emit()
	return instance


func remove(instance: Joker) -> void:
	if not jokers.has(instance):
		return
	jokers.erase(instance)
	instance.on_detach(_kart)
	changed.emit()


func remove_at(index: int) -> Joker:
	var instance := jokers[index]
	remove(instance)
	return instance
