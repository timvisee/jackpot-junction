class_name CatalogRecord
extends Node
## Writes every joker the players at this machine take, every power-up they use and every time one
## of their jokers goes off by itself into their profiles, for the catalog of GAME.md 8.8, see
## [CatalogState]: a power-up counts once it is used, by its button or spent by Guardian Angel,
## never as it is picked up. The first seat's go into the
## profile playing, a seat another profile sits in into that one, and a guest's, a bot's or a
## player's elsewhere into none, found as [MatchRecord] finds them. Every machine hears its own
## seats' takes and uses anyway, a client from its host, so nothing of it goes over the wire. Kept
## in the profiles as it happens and written as the room is left, in [constant MatchRecord.GROUP],
## so going to the title writes it before every seat is a guest again. Only the room the game is in
## keeps anything, and never headless.

## For a test: takes are kept wherever the room is, headless or not.
static var anywhere := false

var match_node: Match

## Whether anything was kept since the profiles were last written.
var _kept := false
## The hands watched for the stacks they grow to, by slot: the hand and what it calls, see
## [method _watch].
var _hands: Dictionary[int, Array] = {}


static func add_to(in_match: Match) -> CatalogRecord:
	var record := CatalogRecord.new()
	record.name = "CatalogRecord"
	record.match_node = in_match
	in_match.add_child(record)
	return record


func _ready() -> void:
	add_to_group(MatchRecord.GROUP)
	Events.joker_taken.connect(_on_joker_taken)
	Events.item_used.connect(_on_item_used)
	Events.joker_went_off.connect(_on_joker_went_off)


func _exit_tree() -> void:
	if Events.joker_taken.is_connected(_on_joker_taken):
		Events.joker_taken.disconnect(_on_joker_taken)
	if Events.item_used.is_connected(_on_item_used):
		Events.item_used.disconnect(_on_item_used)
	if Events.joker_went_off.is_connected(_on_joker_went_off):
		Events.joker_went_off.disconnect(_on_joker_went_off)
	for watched: Array in _hands.values():
		var hand: JokerHolder = watched[0]
		if hand.changed.is_connected(watched[1]):
			hand.changed.disconnect(watched[1])
	_hands.clear()
	leave()


## The room is being left: whatever was taken in it is written down, once.
func leave() -> void:
	if _kept:
		_kept = false
		Game.settings.save_to_disk()


func _on_joker_taken(slot: int, joker: StringName) -> void:
	var catalog := _catalog_of(slot)
	if catalog != null:
		catalog.take_joker(joker)
		_kept = true
		_watch(slot)
		_note_stacks(slot)


## The hand at [param slot] watched from now on, so the biggest stack it holds is kept, GAME.md
## 8.8, however late the card comes into it: a client's hand hears of a card off the floor a moment
## after the word that it was taken.
func _watch(slot: int) -> void:
	var kart := match_node.slots[slot].kart
	if kart == null or kart.jokers == null:
		return
	var watched: Array = _hands.get(slot, [])
	if not watched.is_empty() and watched[0] == kart.jokers:
		return
	if not watched.is_empty() and (watched[0] as JokerHolder).changed.is_connected(watched[1]):
		(watched[0] as JokerHolder).changed.disconnect(watched[1])
	var noting := _note_stacks.bind(slot)
	kart.jokers.changed.connect(noting)
	_hands[slot] = [kart.jokers, noting]


## Every stack the hand at [param slot] holds now, kept where it is the biggest of its joker yet.
func _note_stacks(slot: int) -> void:
	var catalog := _catalog_of(slot)
	var kart := match_node.slots[slot].kart if catalog != null else null
	if kart == null or kart.jokers == null:
		return
	for held: Joker in kart.jokers.jokers:
		if catalog.hold(held.id, held.held):
			_kept = true


func _on_item_used(slot: int, item: StringName) -> void:
	var catalog := _catalog_of(slot)
	if catalog != null:
		catalog.use_item(item)
		_kept = true


func _on_joker_went_off(slot: int, joker: StringName, _word: String) -> void:
	var catalog := _catalog_of(slot)
	if catalog != null:
		catalog.go_off(joker)
		_kept = true


## The catalog [param slot]'s takes go into, or null for nobody's or a room that keeps nothing.
func _catalog_of(slot: int) -> CatalogState:
	if not _keeps() or slot < 0 or slot >= match_node.slots.size():
		return null
	var profile := MatchRecord.profile_of(match_node.slots[slot])
	return profile.catalog if profile != null else null


## Whether this room keeps what is taken in it: the room the game is in, never headless.
func _keeps() -> bool:
	if not is_instance_valid(match_node) or not is_inside_tree():
		return false
	var scene := get_tree().current_scene
	var here := scene != null and scene.is_ancestor_of(self) and not Game.is_headless()
	return here or anywhere
