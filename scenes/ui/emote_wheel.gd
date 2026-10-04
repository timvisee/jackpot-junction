class_name EmoteWheel
extends Control
## The four emotes round a player's kart, GAME.md 3.8, so they can see what there is to put up and
## which way is which: while the right stick is pushed toward one, with that one picked out, a
## ring round it filling for as long as the stick is held at the edge on it, and once it is full
## picked out further and beating, since letting go will ask for it, see [PlayerInput]; and
## for a few seconds after the wheel's key, V, with the key for each way beside it. Only while one
## is being chosen: once it is asked for, it is up over the kart, and the wheel saying so again
## would be saying it twice. One for each player at this screen, round their own kart, in their
## own color; and for somebody watching, who has no kart, one in gray at the bottom of the screen,
## where theirs float up from, see [WatcherEmotes].

## How far out from the middle of the kart each emote sits, and how big it is, in pixels at a UI
## scale of 100%.
const REACH := 80.0
const SIDE := 54.0
## How much bigger the picked one is drawn, and bigger again once letting go will ask for it, and
## how faint the others go beside it.
const PICKED := 1.3
const ARMED := 1.55
const FAINT := 0.5
## How wide the ring is drawn round the picked one, past its edge, and how fast and how far an
## armed one beats.
const RING_OUT := 7.0
const RING_WIDTH := 4.0
const BEAT_RATE := 9.0
const BEAT := 0.06
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


## The ring round the picked emote, filling clockwise from the top as the stick is held on it.
class Ring:
	extends Control

	var charge := 0.0
	var ink := Color.WHITE

	func _draw() -> void:
		var middle := size * 0.5
		var radius := minf(size.x, size.y) * 0.5
		draw_arc(middle, radius, 0.0, TAU, 48, Color(ink, 0.25), RING_WIDTH, true)
		if charge > 0.0:
			var start := -PI * 0.5
			draw_arc(middle, radius, start, start + TAU * charge, 48, ink, RING_WIDTH, true)


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
			_show(wheel, watcher)
	for slot: PlayerSlot in match_node.slots:
		var player := slot.input as PlayerInput
		if player == null:
			continue
		var wheel := _wheel_for(slot.index, slot.color())
		var root: Control = wheel["root"]
		var kart := slot.kart
		var up := player.wheel_by_keys or player.wheel_pointing >= 0
		if kart == null or camera == null or not up:
			root.visible = false
			continue
		# Dead, a player has no kart to hold the wheel over, and it comes up where a watcher's
		# does, at the bottom, which is where the emote floats up from too.
		if not kart.alive:
			root.visible = true
			root.position = Vector2(size.x * 0.5, size.y - REACH - SIDE - WATCHER_LIFT)
			_show(wheel, player)
			continue
		var over := kart.global_position + Vector3.UP * LIFT
		if camera.is_position_behind(over):
			root.visible = false
			continue
		root.visible = true
		root.position = camera.unproject_position(over)
		_show(wheel, player)


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
	var ring := Ring.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.ink = ink
	ring.size = Vector2.ONE * (SIDE * ARMED + RING_OUT * 2.0)
	ring.visible = false
	root.add_child(ring)
	wheel = {
		"root": root,
		"pictures": pictures,
		"keys": keys,
		"ring": ring,
		"color": ink,
	}
	_wheels[kept_as] = wheel
	return wheel


## [param wheel] as [param player] has it: the one they point at picked out, with the ring round
## it as far as it is charged, beating once armed; the keys beside the ways when the key opened it.
func _show(wheel: Dictionary, player: PlayerInput) -> void:
	var picked := player.wheel_pointing
	var armed := player.wheel_armed
	var pictures: Array[Control] = wheel["pictures"]
	var beat := 1.0 + BEAT * sin(Time.get_ticks_msec() * 0.001 * BEAT_RATE) if armed else 1.0
	for i: int in pictures.size():
		var on := picked < 0 or picked == i
		var grown := (ARMED * beat if armed else PICKED) if picked == i else 1.0
		pictures[i].scale = Vector2.ONE * grown
		pictures[i].modulate.a = 1.0 if on else FAINT
	for key: Control in wheel["keys"]:
		key.visible = player.wheel_by_keys
	var ring: Ring = wheel["ring"]
	ring.visible = picked >= 0 and not player.wheel_by_keys
	if ring.visible:
		ring.position = WAYS[picked] * REACH - ring.size * 0.5
		ring.charge = 1.0 if armed else player.wheel_charge
		ring.queue_redraw()
