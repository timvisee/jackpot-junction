class_name DemoSeats
extends RefCounted
## Who has sat down at the demo for a booth, GAME.md 9.8: the demo's seats held by a device, the
## bots' karts taken over past them once every seat is held, and how long each device has been
## quiet. A device quiet for [constant IDLE] seconds gets up, and the bot drives on. What it holds
## outlasts the map and the run, so somebody playing plays on from one map to the next. Sitting
## down and getting up are both said where nobody can miss them: the seat's name and what became of
## it under the middle of the screen, flares going up round its kart, and a sound for sitting down.

## How long a device may sit quiet before its seat goes back to its bot, in seconds.
const IDLE := 60.0
## What the call under the middle of the screen says as somebody sits down, and as the seat goes
## back to its bot, and how long it holds.
const TAKEN := "YOU'RE IN"
const GIVEN_BACK := "BACK TO THE BOT"
const SAID_FOR := 3.0
## How many flares go up round a kart taken over, and how far apart, in seconds.
const FLARES := 3
const FLARE_GAP := 0.35

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
			_say(match_node, slot, true)
		return true
	if match_node == null or match_node.slots.is_empty():
		return false
	var taken := match_node.join_human(device)
	if taken == null:
		return false
	joined.append(device)
	quiet[device] = 0.0
	_say(match_node, taken, true)
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
		_drive_as_it_comes(seat)
		var slot := slot_of(match_node, seat)
		if slot != null:
			(slot.input as DemoInput).let_go()
			_refresh(match_node, slot)
			_say(match_node, slot, false)
	if device in joined:
		joined.erase(device)
		if match_node != null:
			for slot: PlayerSlot in match_node.slots:
				if slot.plays_on(device):
					_drive_as_it_comes((slot.input as PlayerInput).seat)
					match_node.leave_human(slot)
					_say(match_node, slot, false)


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


## [param seat] back to the simple way with Auto throttle on, for whoever sits down next, whatever
## the one who got up switched it to.
static func _drive_as_it_comes(seat: int) -> void:
	Game.settings.set_drive_mode(seat, Settings.DRIVE_SIMPLE)
	Game.settings.set_auto_throttle(seat, true)


## Says that somebody sat down at [param slot] of [param match_node], with [param taken], or that it
## went back to its bot: its name and what became of it under the middle of the screen, in its
## color, and flares round its kart, one for getting up and a run of them and a sound for sitting
## down, so whoever pressed knows which kart is theirs.
static func _say(match_node: Match, slot: PlayerSlot, taken: bool) -> void:
	if match_node.hud != null:
		var call := match_node.hud.get_node_or_null("Call") as CallBanner
		if call != null:
			var said := TAKEN if taken else GIVEN_BACK
			call.show_call(slot.display_name(), said, slot.color(), false, SAID_FOR)
	if not match_node.is_inside_tree():
		return
	for i: int in FLARES if taken else 1:
		var after := match_node.get_tree().create_timer(FLARE_GAP * i, false)
		after.timeout.connect(func() -> void: _flare(match_node, slot))
	if taken:
		Audio.play_sfx(&"go", -4.0, 0.0)


## A flare round [param slot]'s kart, where it is now, see [SpawnRing].
static func _flare(match_node: Match, slot: PlayerSlot) -> void:
	if not is_instance_valid(match_node) or slot.kart == null or not is_instance_valid(slot.kart):
		return
	SpawnRing.spawn(match_node, slot.kart.global_position, slot.color())


## [param slot]'s corner of the HUD made again for whoever drives it now: the keys or the pad its
## hints are drawn for, and for somebody who has just sat down the hint over the kart.
static func _refresh(match_node: Match, slot: PlayerSlot) -> void:
	if match_node.hud == null:
		return
	match_node.hud.remove_block(slot)
	ControlHint.shown_to.erase(ControlHint.seat_of(match_node, slot))
	match_node.hud.add_block(slot)
