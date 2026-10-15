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
	for joker: Joker in in_play:
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
	var before := _most_lives()
	var instance: Joker = joker.duplicate()
	jokers.append(instance)
	_restack()
	instance.on_attach(_kart)
	KartLives.follow(_kart, before)
	changed.emit()
	return instance


func remove(instance: Joker) -> void:
	if not jokers.has(instance):
		return
	var before := _most_lives()
	jokers.erase(instance)
	_restack()
	instance.on_detach(_kart)
	KartLives.follow(_kart, before)
	changed.emit()


func _most_lives() -> int:
	return KartLives.most(_kart) if _kart != null and _kart.rules != null else 0


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
## out what the hand does: the copy a Copy Cat stands in for, GAME.md 7.3, one more of the card
## just before it that is in play but never a card in the hand, and the suits it is Suited in.
func _restack() -> void:
	var copies: Dictionary[StringName, int] = {}
	var beyond: Dictionary[StringName, int] = {}
	var stand_ins: Array[Joker] = []
	for i: int in jokers.size():
		var joker := jokers[i]
		copies[joker.id] = copies.get(joker.id, 0) + 1
		var copied := joker.stands_in_for(jokers.slice(0, i))
		joker.in_hand = true
		joker.standing_for = copied
		if copied != null:
			copies[copied.id] = copies.get(copied.id, 0) + 1
			beyond[copied.id] = beyond.get(copied.id, 0) + 1
			var stand_in: Joker = copied.duplicate()
			stand_in.leads = false
			stand_ins.append(stand_in)
	var was := suited
	var seen: Dictionary[StringName, bool] = {}
	for joker: Joker in jokers:
		joker.held = copies[joker.id]
		joker.leads = not seen.has(joker.id)
		joker.beyond = beyond.get(joker.id, 0)
		seen[joker.id] = true
	for stand_in: Joker in stand_ins:
		stand_in.held = copies[stand_in.id]
	suited = JokerSuits.suited(jokers)
	if _kart != null and not _kart.puppet:
		for suit: int in suited:
			if suit not in was:
				Events.hand_suited.emit(_kart.slot, suit)
	in_play.assign(jokers)
	in_play.append_array(stand_ins)
	for suit: int in suited:
		in_play.append(SuitBonus.of(suit))


## Pays [param chips] chips into the pot for [param payer], one of the hand's jokers, GAME.md 7.3,
## and again for every Echo in the hand that echoes it.
func pay_chips(payer: Joker, chips: int) -> void:
	for i: int in 1 + echoes(payer):
		_kart.collect_coins(chips, null)


## Pays [param amount] mult for [param payer], for [param reason], and again for every Echo in the
## hand that echoes it, GAME.md 7.3.
func pay_mult(payer: Joker, amount: float, reason: StringName) -> void:
	for i: int in 1 + echoes(payer):
		_kart.gain_mult(amount, reason)


## How many of the hand's Echoes pay again what [param payer] has just paid, GAME.md 7.3: asked
## of the cards that answer it, Echo and a Copy Cat of it, rather than of every joker, which has
## hooks enough.
func echoes(payer: Joker) -> int:
	var again := 0
	for joker: Joker in in_play:
		if joker != payer and joker.has_method(&"echoes") and joker.call(&"echoes", _kart):
			again += 1
	return again


## [member in_play] with its cursed jokers first, GAME.md 7.3: a death applies the curses' terms
## before the rest, so their antidotes, Insurance Policy under High Roller say, have the last say
## whatever order the cards were taken in.
func cursed_first() -> Array[Joker]:
	var ordered: Array[Joker] = []
	for joker: Joker in in_play:
		if joker.kind == Joker.Kind.CURSED:
			ordered.append(joker)
	for joker: Joker in in_play:
		if joker.kind != Joker.Kind.CURSED:
			ordered.append(joker)
	return ordered


func remove_at(index: int) -> Joker:
	var instance := jokers[index]
	remove(instance)
	return instance
