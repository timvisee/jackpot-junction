class_name PadRepeat
extends Node
## A pad's stick or D-pad held over a way walks the cursor on and on, as a key held down does,
## GAME.md 4.2: once as it is pushed, which the engine sees to, then after a moment again and again,
## quickly, until it is let go. Each pad on its own, and only the way it pushed last.
##
## A repeat is the way's action as an event of its own, sent into the window as a press would be,
## with the pad's id: the cursor walks on it, and a slider steps, a list scrolls or a page turns on
## it, wherever the way would. Nothing goes while no control has the cursor, so a match being
## driven never hears one.

## The ways that go on while held.
const WAYS: Array[StringName] = [&"ui_left", &"ui_right", &"ui_up", &"ui_down"]
## Seconds a way is held before it goes on, and then between one step and the next.
const DELAY := 0.4
const EVERY := 0.08

## The way each pad is going on with, and how long it has been held.
var _way: Dictionary[int, StringName] = {}
var _held: Dictionary[int, float] = {}
## The ways each pad held the frame before, to tell a new push from one still held.
var _was: Dictionary[int, Array] = {}


func _ready() -> void:
	# The pause menu stops the tree, and its cursor walks all the same.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	var pads := Input.get_connected_joypads()
	for pad: int in _was.keys():
		if pad not in pads:
			hold(pad, [], delta)
	for pad: int in pads:
		hold(pad, held_ways(pad), delta)


## The ways [param pad] holds over now, of [constant WAYS].
static func held_ways(pad: int) -> Array[StringName]:
	var ways: Array[StringName] = []
	for way: StringName in WAYS:
		if DeviceInput.pad_strength(way, pad) > 0.0:
			ways.append(way)
	return ways


## [param pad] holding [param ways] for [param delta] seconds more: a way pushed anew is the one it
## goes on with, and once that has been held [constant DELAY] it steps every [constant EVERY].
## Letting it go stops it, even with another way still held, as a key does.
func hold(pad: int, ways: Array[StringName], delta: float) -> void:
	var was: Array = _was.get(pad, [])
	_was[pad] = ways
	if ways.is_empty():
		_was.erase(pad)
	for way: StringName in ways:
		if way not in was:
			_way[pad] = way
			_held[pad] = 0.0
	if not _way.has(pad):
		return
	if _way[pad] not in ways:
		_way.erase(pad)
		_held.erase(pad)
		return
	_held[pad] += delta
	if _held[pad] < DELAY:
		return
	# One step a frame at most, however long a frame took.
	_held[pad] = maxf(_held[pad] - EVERY, DELAY - EVERY)
	var focus := get_viewport().gui_get_focus_owner()
	if focus != null and focus.is_visible_in_tree():
		step(_way[pad], pad)


## The window hears [param way] pushed once more on [param pad].
func step(way: StringName, pad: int) -> void:
	var again := InputEventAction.new()
	again.action = way
	again.pressed = true
	again.strength = 1.0
	again.device = pad
	get_viewport().push_input(again)
