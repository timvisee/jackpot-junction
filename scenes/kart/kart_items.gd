extends RefCounted
## The items a kart holds, GAME.md 7.1 and 7.3: the one in hand and any queued behind it with Pack
## Rat. Kept out of [Kart] and loaded at runtime the way [Blast] is, see [constant
## Kart.KART_ITEMS_SCRIPT], so the kart stays within its size. Every call takes the kart it works.


## How many items [param kart] may hold at once: one, and one more for each Pack Rat held, GAME.md
## 7.3. Read off the hand by id the way Guardian Angel is, rather than a joker hook of its own.
static func capacity(kart: Kart) -> int:
	return 1 + kart.jokers.ids().count(&"pack_rat")


## Whether [param kart] has room to take another item: under its [method capacity], and not a decoy,
## which holds none.
static func can_hold(kart: Kart) -> bool:
	var held := (1 if kart.held_item != null else 0) + kart.queued
	return not kart.is_decoy() and held < capacity(kart)


## [param kart] takes [param item] from a pad or the floor, unusable until revealed. With a Pack
## Rat's room to spare behind the held one it is queued, GAME.md 7.3, to come up when that is used;
## otherwise it is the one in hand. Pickups are gated by [method can_hold], so only a direct caller
## replaces a held item.
static func hold(kart: Kart, item: PowerUp, reveal_time: float) -> void:
	if kart.held_item != null and kart.queued < capacity(kart) - 1:
		kart._item_queue.append(item)
		kart._item_queue_reveal.append(reveal_time)
		kart.queued = kart._item_queue.size()
	else:
		kart.held_item = item
		kart.item_reveal_left = reveal_time
	kart.item_held.emit(item)
	Events.item_picked.emit(kart.slot, item.id)


## [param kart] uses the item in hand, GAME.md 7.1. Whatever it starts is named after it, so the HUD
## of 8.3 can say what is running on a kart without knowing what any one power-up does; a cannon
## power-up loads shots the same way. The next queued item then comes up in its place.
static func use(kart: Kart) -> void:
	if kart.held_item == null:
		return
	var item := kart.held_item
	kart.held_item = null
	var running := kart.effects.size()
	var loaded := kart.cannon.override_shots_left()
	item.activate(kart)
	for i: int in range(running, kart.effects.size()):
		kart.effects[i].display_name = item.display_name
		kart.effects[i].color = item.color
		kart.effects[i].item_id = item.id
	if kart.cannon.override_shots_left() > loaded:
		kart.cannon.override_name = item.display_name
		kart.cannon.override_color = item.color
		kart.cannon.override_item = item.id
	kart.item_used.emit(item)
	Events.item_used.emit(kart.slot, item.id)
	_reveal_next(kart)


## Brings [param kart]'s next queued item up as the held one, revealing it afresh; nothing if empty.
static func _reveal_next(kart: Kart) -> void:
	if kart._item_queue.is_empty():
		return
	kart.held_item = kart._item_queue.pop_front()
	kart.item_reveal_left = kart._item_queue_reveal.pop_front()
	kart.queued = kart._item_queue.size()


## Empties [param kart]'s queue of items behind the held one; the held item itself is the caller's
## to deal with, see [KartDeath].
static func clear(kart: Kart) -> void:
	kart._item_queue.clear()
	kart._item_queue_reveal.clear()
	kart.queued = 0
