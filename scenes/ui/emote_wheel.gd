class_name EmoteWheel
extends Control
## The four emotes round a player's kart, GAME.md 3.8, so they can see what there is to put up and
## which way is which: while the right stick is pushed toward one, with that one picked out, and
## for a few seconds after the wheel's key, V, with the key for each way beside it. Only while one
## is being chosen: once it is asked for, it is up over the kart, and the wheel saying so again
## would be saying it twice. One for each player at this screen, round their own kart, in their
## own color; and for somebody watching, who has no kart, one in gray at the bottom of the screen,
## where theirs float up from, see [WatcherEmotes].

## How far out from the middle of the kart each emote sits, and how big it is, in pixels at a UI
## scale of 100%.
const REACH := 80.0
const SIDE := 54.0
## How much bigger the picked one is drawn, and how faint the others go beside it.
const PICKED := 1.3
const FAINT := 0.5
## How high over the kart the middle of the wheel is, in meters, and how the keys are drawn.
const LIFT := 0.6
const KEY_SIZE := 16
const KEY_INK := Color(0.93, 0.93, 0.95)
## Where each of the four sits, up, right, down and left, in [constant EmoteArt.EMOTES] order.
const WAYS: Array[Vector2] = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
## How far up from the bottom of the screen the middle of a watcher's wheel is, past its reach.
const WATCHER_LIFT := 60.0
## The key a watcher's wheel is kept under, which no slot has.
const WATCHER := -1

var match_node: Match

## Slot to its wheel, or [constant WATCHER]: the node, its four pictures and its keys.
var _wheels: Dictionary[int, Dictionary] = {}


static func add_to(hud: CanvasLayer, in_match: Match) -> EmoteWheel:
	var wheel := EmoteWheel.new()
	wheel.name = "EmoteWheel"
	wheel.match_node = in_match
	hud.add_child(wheel)
	return wheel


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	var session := Net.session if Net.online() else null
	if session != null and session.watching:
		var watcher := session.local_input as PlayerInput
		var wheel := _wheel_for(WATCHER, WatcherEmotes.INK)
		var root: Control = wheel["root"]
		root.visible = watcher != null and (watcher.wheel_by_keys or watcher.wheel_pointing >= 0)
		if root.visible:
			root.position = Vector2(size.x * 0.5, size.y - REACH - SIDE - WATCHER_LIFT)
			_show(wheel, watcher.wheel_pointing, watcher.wheel_by_keys)
	for slot: PlayerSlot in match_node.slots:
		var player := slot.input as PlayerInput
		if player == null:
			continue
		var wheel := _wheel_for(slot.index, slot.color())
		var root: Control = wheel["root"]
		var kart := slot.kart
		var up := player.wheel_by_keys or player.wheel_pointing >= 0
		if kart == null or not kart.alive or camera == null or not up:
			root.visible = false
			continue
		var over := kart.global_position + Vector3.UP * LIFT
		if camera.is_position_behind(over):
			root.visible = false
			continue
		root.visible = true
		root.position = camera.unproject_position(over)
		_show(wheel, player.wheel_pointing, player.wheel_by_keys)


## Four emotes round the middle, each with the key for its way beside it, hidden unless it was the
## key that opened the wheel. The wheel kept under [param kept_as], rimmed in [param ink], and
## made again if that changes.
func _wheel_for(kept_as: int, ink: Color) -> Dictionary:
	var wheel: Dictionary = _wheels.get(kept_as, {})
	if not wheel.is_empty() and wheel["color"] == ink:
		return wheel
	if not wheel.is_empty():
		(wheel["root"] as Control).queue_free()
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var pictures: Array[Control] = []
	var keys: Array[Control] = []
	for i: int in WAYS.size():
		var picture := EmoteArt.picture(i, ink, SIDE)
		picture.position = WAYS[i] * REACH - picture.size * 0.5
		picture.pivot_offset = picture.size * 0.5
		root.add_child(picture)
		pictures.append(picture)
		var key := InputHint.glyph(InputActions.WHEEL_WAYS[i], true, KEY_INK, KEY_SIZE)
		if key == null:
			key = Control.new()
		key.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(key)
		key.size = key.get_combined_minimum_size()
		key.position = WAYS[i] * (REACH + SIDE * 0.5 + 16.0) - key.size * 0.5
		keys.append(key)
	wheel = {
		"root": root,
		"pictures": pictures,
		"keys": keys,
		"color": ink,
	}
	_wheels[kept_as] = wheel
	return wheel


func _show(wheel: Dictionary, picked: int, keys: bool) -> void:
	var pictures: Array[Control] = wheel["pictures"]
	for i: int in pictures.size():
		var on := picked < 0 or picked == i
		pictures[i].scale = Vector2.ONE * (PICKED if picked == i else 1.0)
		pictures[i].modulate.a = 1.0 if on else FAINT
	for key: Control in wheel["keys"]:
		key.visible = keys
