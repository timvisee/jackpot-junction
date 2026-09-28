class_name PeerSeats
extends RefCounted
## On the host, the seats its clients hold, GAME.md 10.3: by client, and within each client by that
## client's own number for each of its players, the first 0. A client with two players at it holds
## two, each asked for, seated, driven and emptied on its own. Kept apart from [NetSession] so that
## file stays about the connection.

## The slot each player of each client sits in, peer to its numbers to slots.
var held: Dictionary[int, Dictionary] = {}
## The players each client has asked to have seated, by its numbers, which it is seated in again in
## the next room.
var asked: Dictionary[int, Array] = {}
## The color and the name each of each client's players had in the room being left, so they can be
## seated in that color and under that name on the other side.
var kept: Dictionary[int, Dictionary] = {}


func has(peer: int) -> bool:
	return held.has(peer)


func is_empty() -> bool:
	return held.is_empty()


func peers() -> Array[int]:
	var found: Array[int] = []
	found.assign(held.keys())
	return found


## The slot [param peer]'s player [param number] sits in, or -1.
func slot_of(peer: int, number: int) -> int:
	return int((held.get(peer, {}) as Dictionary).get(number, -1))


## Every seat held, client by client and player by player: the order they are seated in again.
func all_slots() -> Array[int]:
	var slots: Array[int] = []
	for peer: int in held:
		for number: int in held[peer]:
			slots.append(held[peer][number])
	return slots


## [param peer]'s player [param number] in [param index]. Returns whether it is the first of that
## client's players to sit down in this room, which is the one told the rules.
func put(peer: int, number: int, index: int) -> bool:
	var first := not held.has(peer)
	if first:
		held[peer] = {}
	held[peer][number] = index
	return first


## Takes [param peer]'s player [param number] out of their seat, and returns the slot, or -1.
func take(peer: int, number: int) -> int:
	var seats: Dictionary = held.get(peer, {})
	if not seats.has(number):
		return -1
	var index: int = seats[number]
	seats.erase(number)
	(asked.get(peer, []) as Array).erase(number)
	return index


## Every seat [param peer] held, which it holds no longer, by number.
func take_all(peer: int) -> Dictionary:
	var seats: Dictionary = held.get(peer, {})
	held.erase(peer)
	asked.erase(peer)
	return seats


## What [param peer] asked for: its first player, and whoever sat down beside them since.
func asked_of(peer: int) -> Array:
	return asked.get(peer, [0])


func ask(peer: int, numbers: Array) -> void:
	asked[peer] = numbers if not numbers.is_empty() else [0]


func ask_one_more(peer: int, number: int) -> void:
	var numbers := asked_of(peer).duplicate()
	if number not in numbers:
		numbers.append(number)
	asked[peer] = numbers


## Notes who everybody is in [param match_node] as the host leaves it, see [member kept].
func keep_room(match_node: Match) -> void:
	kept.clear()
	if match_node == null:
		return
	for peer: int in held:
		var theirs: Dictionary[int, Dictionary] = {}
		for number: int in held[peer]:
			var index: int = held[peer][number]
			if index < match_node.slots.size():
				var slot := match_node.slots[index]
				theirs[number] = {"color": slot.color_index, "name": slot.player_name}
		kept[peer] = theirs


func kept_for(peer: int, number: int) -> Dictionary:
	return (kept.get(peer, {}) as Dictionary).get(number, {})


## Empties the seat in [param index] of [param match_node] of whoever sat in it from another
## machine. In the waiting room the seat is emptied rather than handed to a bot, GAME.md 9.6: a
## room with no end has no score for one to keep, and the bots come in with the match.
static func vacate(match_node: Match, index: int) -> void:
	if match_node == null or index < 0 or index >= match_node.slots.size():
		return
	if match_node.rules.timed:
		match_node.leave_human(match_node.slots[index])
	else:
		VacantSeat.leave(match_node, match_node.slots[index])
