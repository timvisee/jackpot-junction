class_name DemoPresses
extends RefCounted
## What sits somebody down at the demo for a booth, GAME.md 9.8, and what keeps them sitting: a key
## the game plays with, a pad's button, or a stick or a trigger pushed out from rest. The mouse
## never does: at a booth it is moved and clicked by whoever is showing the game, and to bring the
## window up, and a seat it took sat waiting on a keyboard nobody touched, its pick open for good.
## Nor does a key the game has no use for, the one that switches windows say, nor a stick that
## rests off its middle, nor a device that says it is a pad and only ever reports an axis held. Two
## presses or pushes on one device within [constant WITHIN] seconds sit somebody down, so a key
## brushed or a pad knocked on the table does not.

## How far a stick or a trigger has to go to be pushed, and how near the middle it has to have been
## since it was last pushed.
const PUSH := 0.6
const REST := 0.25
## How many presses sit somebody down, and within how long, in seconds.
const NEEDED := 2
const WITHIN := 2.0
## What a key has to be bound to for the keyboard to press: playing, and sitting down.
const PLAYING: Array[StringName] = [
	InputActions.STEER_LEFT,
	InputActions.STEER_RIGHT,
	InputActions.DRIVE_UP,
	InputActions.DRIVE_DOWN,
	InputActions.THROTTLE,
	InputActions.BRAKE,
	InputActions.FIRE,
	InputActions.HANDBRAKE,
	InputActions.NITRO,
	InputActions.USE_ITEM,
	InputActions.JOKER_MENU,
	InputActions.JOIN,
]

## Whether each stick and trigger has been at rest since it was last pushed, by pad and axis.
var _resting: Dictionary[Vector2i, bool] = {}
## When each device last pressed, in seconds, the ones still within [constant WITHIN].
var _times: Dictionary[int, Array] = {}


## Whether [param event] is a press or a push that means it, see the class.
func deliberate(event: InputEvent) -> bool:
	if event is InputEventKey:
		return _plays_with(event as InputEventKey)
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).pressed
	if event is InputEventJoypadMotion:
		return _pushed(event as InputEventJoypadMotion)
	return false


## Whether [param key] went down, and is one the game plays with.
static func _plays_with(key: InputEventKey) -> bool:
	if not key.pressed or key.echo:
		return false
	for action: StringName in PLAYING:
		if key.is_action(action, true):
			return true
	return false


## Whether [param motion] pushes its stick or trigger out from rest.
func _pushed(motion: InputEventJoypadMotion) -> bool:
	var axis := Vector2i(motion.device, motion.axis)
	var pushed := absf(motion.axis_value)
	if pushed <= REST:
		_resting[axis] = true
		return false
	if pushed < PUSH or not _resting.get(axis, false):
		return false
	_resting[axis] = false
	return true


## A press of [param device]'s at [param now] seconds; whether it is the one that sits them down.
func count(device: int, now: float) -> bool:
	var times: Array = _times.get(device, [])
	times.append(now)
	while not times.is_empty() and now - float(times[0]) > WITHIN:
		times.pop_front()
	_times[device] = times
	if times.size() < NEEDED:
		return false
	_times.erase(device)
	return true
