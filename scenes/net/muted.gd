class_name Muted
extends RefCounted
## The players muted on this screen, GAME.md 10.8: from Players in the pause menu, for the rest of
## the game. A muted player's emotes are not shown here, over their kart, floating up from the
## foot of the screen or on the podium, and nobody else is told. A player is known by the machine
## they play at and their seat there, which stays theirs from room to room while the slot in the
## match changes; a watcher by their name. Forgotten with the game.

## The players muted, by [method key_of].
static var _keys: Dictionary[String, bool] = {}
## Which player each slot of the room is, by [method key_of], as the list of everybody last said.
static var _slots: Dictionary[int, String] = {}


## How [param guest], a row of the list of everybody, see [method HostControls.everybody], is known
## here: their machine and seat, or a watcher's name.
static func key_of(guest: Dictionary) -> String:
	if guest.has("color"):
		return "%d:%d" % [int(guest.get("peer", 0)), int(guest.get("seat", 0))]
	return "watcher:%s" % str(guest.get("name", ""))


## [param guest] muted, or heard again, [param on].
static func mute(guest: Dictionary, on: bool) -> void:
	if on:
		_keys[key_of(guest)] = true
	else:
		_keys.erase(key_of(guest))


## Whether [param guest] is muted.
static func is_muted(guest: Dictionary) -> bool:
	return _keys.has(key_of(guest))


## The list of everybody as it is now, [param everybody], for which slot is whom.
static func seen(everybody: Array[Dictionary]) -> void:
	_slots.clear()
	for guest: Dictionary in everybody:
		if guest.has("slot"):
			_slots[int(guest["slot"])] = key_of(guest)


## Whether the player in the slot [param index] of the room is muted.
static func slot(index: int) -> bool:
	return _keys.has(_slots.get(index, ""))


## Whether the watcher called [param named] is muted.
static func watcher(named: String) -> bool:
	return _keys.has("watcher:%s" % named)


## Who is muted, in words that change whenever it does, for a list to tell it has to be drawn again.
static func said() -> String:
	return str(_keys.keys())


## Everybody heard again, and the room forgotten: the game is over for this machine.
static func clear() -> void:
	_keys.clear()
	_slots.clear()
