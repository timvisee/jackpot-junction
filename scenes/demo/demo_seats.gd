class_name DemoSeats
extends RefCounted
## Who has sat down at the demo for a booth, GAME.md 9.8: the demo's seats held by a device, the
## bots' karts taken over past them once every seat is held, and how long each device has been
## quiet. A device quiet for [constant IDLE] seconds gets up, and the bot drives on. What it holds
## outlasts the map and the run, so somebody playing plays on from one map to the next.

## How long a device may sit quiet before its seat goes back to its bot, in seconds.
const IDLE := 60.0

## The device holding each of the demo's seats, by seat.
static var held: Dictionary[int, int] = {}
## The devices that took a bot's kart over, every one of the demo's seats being held.
static var joined: Array[int] = []
## How long each device sitting down has been quiet, in seconds, by device.
static var quiet: Dictionary[int, float] = {}


## Nobody sitting down.
static func clear() -> void:
	held.clear()
	joined.clear()
	quiet.clear()


## Whether [param device] is sitting down.
static func sits(device: int) -> bool:
	return device in held.values() or device in joined


## Whether a seat of the demo is still its bot's.
static func any_free() -> bool:
	return held.size() < Demo.seats


## [param device] sits down: at the first of the demo's seats nobody holds, in [param match_node]
## there and then, or with no map up yet when the next one starts; or past them at a bot's kart, as
## anybody joining a map does. Whether it did.
static func sit(device: int, match_node: Match) -> bool:
	if sits(device):
		return false
	for seat: int in Demo.seats:
		if held.has(seat):
			continue
		held[seat] = device
		quiet[device] = 0.0
		var slot := slot_of(match_node, seat)
		if slot != null:
			(slot.input as DemoInput).take(device)
			_refresh(match_node, slot)
		return true
	if match_node == null or match_node.slots.is_empty() or match_node.join_human(device) == null:
		return false
	joined.append(device)
	quiet[device] = 0.0
	return true


## Something heard from [param device]: it is not quiet.
static func heard_from(device: int) -> void:
	if quiet.has(device):
		quiet[device] = 0.0


## Everybody sitting down [param delta] seconds quieter, and whoever has been quiet long enough up
## and gone from [param match_node], if there is a map up.
static func step(match_node: Match, delta: float) -> void:
	for device: int in quiet.keys():
		quiet[device] += delta
		if quiet[device] >= IDLE:
			get_up(device, match_node)


## [param device] gets up: a seat of the demo's back to its bot, which drives on from where the
## kart is, and a bot's kart taken over back to a bot.
static func get_up(device: int, match_node: Match) -> void:
	quiet.erase(device)
	for seat: int in held.keys():
		if held[seat] != device:
			continue
		held.erase(seat)
		var slot := slot_of(match_node, seat)
		if slot != null:
			(slot.input as DemoInput).let_go()
			_refresh(match_node, slot)
	if device in joined:
		joined.erase(device)
		if match_node != null:
			for slot: PlayerSlot in match_node.slots:
				if slot.plays_on(device):
					match_node.leave_human(slot)


## Whoever took a bot's kart over at the map before, at a bot's kart of [param match_node] again;
## the demo's own seats come with the map, see [method DemoRun.inputs].
static func seat_again(match_node: Match) -> void:
	for device: int in joined:
		var seated := false
		for slot: PlayerSlot in match_node.slots:
			seated = seated or slot.plays_on(device)
		if not seated:
			match_node.join_human(device)


## The slot of the demo's seat [param seat] in [param match_node], or null.
static func slot_of(match_node: Match, seat: int) -> PlayerSlot:
	if match_node == null:
		return null
	for slot: PlayerSlot in match_node.slots:
		var input := slot.input as DemoInput
		if input != null and input.seat == seat:
			return slot
	return null


## [param slot]'s corner of the HUD made again for whoever drives it now: the keys or the pad its
## hints are drawn for, and for somebody who has just sat down the hint over the kart.
static func _refresh(match_node: Match, slot: PlayerSlot) -> void:
	if match_node.hud == null:
		return
	match_node.hud.remove_block(slot)
	ControlHint.shown_to.erase(ControlHint.seat_of(match_node, slot))
	match_node.hud.add_block(slot)
