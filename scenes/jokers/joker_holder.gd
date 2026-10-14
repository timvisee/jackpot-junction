class_name JokerHolder
extends RefCounted
## The jokers a kart holds, as many as the match's [member MatchRules.joker_slots] unless one of
## them says otherwise. Adding duplicates the resource so state stays with the holder; every change
## asks the kart to rebuild its stats. What the hand does is [member in_play]: its cards, and the
## bonus of every suit it is Suited in, GAME.md 7.3.

signal changed

## The hand's room with no rules to say otherwise, a kart on its own in a test say.
const MAX_JOKERS := 5

var jokers: Array[Joker] = []
## What the hand does, GAME.md 7.3: its jokers and, after them, the bonus of every suit it is
## Suited in, see [SuitBonus]. The hooks are run over these; the cards in the hand are [member
## jokers].
var in_play: Array[Joker] = []
## The suits the hand is Suited in, by [enum Joker.Suit].
var suited: Array[int] = []

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


## Whether the hand has room for another copy of [param joker] as far as its stack goes, full or
## not: none held yet, or a stack short of its most, GAME.md 7.3.
func can_take(joker: Joker) -> bool:
	return joker.room_for(ids().count(joker.id))


## Attaches a copy of [param joker] and returns that copy.
func add(joker: Joker) -> Joker:
	var instance: Joker = joker.duplicate()
	jokers.append(instance)
	_restack()
	instance.on_attach(_kart)
	KartLives.follow(_kart, instance, true)
	changed.emit()
	return instance


func remove(instance: Joker) -> void:
	if not jokers.has(instance):
		return
	jokers.erase(instance)
	_restack()
	instance.on_detach(_kart)
	KartLives.follow(_kart, instance, false)
	changed.emit()


## The hand made [param wanted], as a client hears it from the host, GAME.md 10.3: copies of its
## own, so a stack's count is this kart's alone, made again only when the hand has changed. The
## host has already attached and detached them.
func deal(wanted: Array[Joker]) -> void:
	var named: Array[StringName] = []
	for joker: Joker in wanted:
		named.append(joker.id)
	if named == ids():
		return
	jokers.clear()
	for joker: Joker in wanted:
		jokers.append(joker.duplicate())
	_restack()
	changed.emit()


## Tells every joker how many copies of it are held and whether it is the first of them, and works
## out what the hand is Suited in.
func _restack() -> void:
	var copies: Dictionary[StringName, int] = {}
	for joker: Joker in jokers:
		copies[joker.id] = copies.get(joker.id, 0) + 1
	var seen: Dictionary[StringName, bool] = {}
	for joker: Joker in jokers:
		joker.held = copies[joker.id]
		joker.leads = not seen.has(joker.id)
		seen[joker.id] = true
	suited = JokerSuits.suited(jokers)
	in_play.assign(jokers)
	for suit: int in suited:
		in_play.append(SuitBonus.of(suit))


func remove_at(index: int) -> Joker:
	var instance := jokers[index]
	remove(instance)
	return instance
