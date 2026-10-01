class_name HudReveal
extends Node
## The match HUD arriving a piece at a time, GAME.md 9.4a: at the start of the tutorial only the
## player's name is in their corner, and each piece comes with the lesson it is for, with a pointer
## beside it saying what it is until the lesson's first task is done. Under the HUD as a child, so
## it runs after the HUD has put everything up for the frame and takes back what is not yet shown.
## The corner's own control hints stay off throughout: the line over the kart is saying it.

## What can be shown: the nitro tank with the speedometer, the item slot, the hand of jokers, the
## lives, the pot, the banked score, the kills and deaths, and the kill feed.
const PIECES: Array[StringName] = [
	&"nitro", &"item", &"hand", &"lives", &"pot", &"bank", &"stats", &"feed"
]
const INK := Palette.NEON_CYAN
## How far the pointer bobs beside its piece, in pixels, and how fast, and how far the frame round
## the piece stands off it.
const BOB := 8.0
const BOB_RATE := 0.7
const GAP := 14.0
const FRAME_GROW := 6.0

var hud: MatchHud
## Whose corner, and which.
var slot: PlayerSlot
var index := 0
var shown: Dictionary[StringName, bool] = {}

var _pointer: HBoxContainer
var _tip: Tip
## The pointer's line, words with the control drawn in where it names one, see [InputHint].
var _line: Control
var _frame: Frame
var _pointing := &""
var _time := 0.0


## The frame round the piece pointed at, drawn: a rounded box that pulses with the pointer.
class Frame:
	extends Control

	var strength := 1.0:
		set(value):
			strength = value
			queue_redraw()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var box := Rect2(Vector2(1.5, 1.5), size - Vector2(3.0, 3.0))
		draw_rect(box, Color(INK, 0.45 + 0.55 * strength), false, 3.0)


## The triangle of the pointer, drawn, pointing left at the piece beside it or down at one under.
class Tip:
	extends Control

	var down := false

	func _init() -> void:
		custom_minimum_size = Vector2(16.0, 16.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var points := (
			PackedVector2Array([Vector2(1.0, 2.0), Vector2(15.0, 2.0), Vector2(8.0, 15.0)])
			if down
			else PackedVector2Array([Vector2(15.0, 1.0), Vector2(15.0, 15.0), Vector2(1.0, 8.0)])
		)
		draw_colored_polygon(points, INK)


static func add_to(on: MatchHud, of: PlayerSlot) -> HudReveal:
	var reveal := HudReveal.new()
	reveal.name = "HudReveal"
	reveal.hud = on
	reveal.slot = of
	reveal.index = of.index
	reveal.process_priority = 10
	on.add_child(reveal)
	return reveal


func _ready() -> void:
	for piece: StringName in PIECES:
		shown[piece] = false
	_pointer = HBoxContainer.new()
	_pointer.name = "Pointer"
	_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pointer.add_theme_constant_override("separation", 8)
	_tip = Tip.new()
	_tip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_pointer.add_child(_tip)
	_pointer.visible = false
	hud.add_child(_pointer)
	_frame = Frame.new()
	_frame.name = "Frame"
	_frame.visible = false
	hud.add_child(_frame)


## Brings [param piece] in, with [param line] on a pointer beside it until [method pointer_done],
## each gap in the line filled with the control of [param actions] for the device in hand.
func show_piece(piece: StringName, line: String, actions: Array[StringName] = []) -> void:
	shown[piece] = true
	if line.is_empty():
		return
	_pointing = piece
	if _line != null:
		_line.queue_free()
	var keyboard := DeviceInput.uses_keyboard(slot.device()) if slot != null else true
	var parts: Array = []
	for action: StringName in actions:
		parts.append(InputHint.glyph(action, keyboard, INK, Type.LARGE))
	_line = InputHint.row(line, parts, INK, Type.LARGE)
	_pointer.add_child(_line)
	_tip.down = piece == &"hand"
	_tip.queue_redraw()
	_pointer.visible = true
	_frame.visible = true


## What the pointer says, for asking.
func line() -> String:
	var words: PackedStringArray = []
	if _line != null:
		for part: Node in _line.get_children():
			if part is Label:
				words.append((part as Label).text)
	return " ".join(words)


## The pointer has said its piece.
func pointer_done() -> void:
	_pointing = &""
	_pointer.visible = false
	_frame.visible = false


func is_pointing() -> bool:
	return _pointer.visible


func _process(delta: float) -> void:
	_time += delta
	var parts := hud.block_parts(index)
	if parts.is_empty():
		return
	for part: Control in [parts["nitro"], parts["speed"], parts["speed_dial"]]:
		part.visible = shown[&"nitro"]
	(parts["item"] as Control).visible = shown[&"item"]
	for pip: Control in parts["lives"]:
		pip.visible = shown[&"lives"]
	(parts["pot"] as Control).visible = shown[&"pot"]
	(parts["banked"] as Control).visible = shown[&"bank"]
	(parts["stats"] as Control).visible = shown[&"stats"]
	(parts["hints"] as Control).visible = false
	var hand := hud.hand_of(index)
	if hand != null:
		hand.visible = shown[&"hand"]
	var feed := hud.kill_feed()
	if feed != null:
		feed.visible = shown[&"feed"]
	if _pointer.visible:
		_place(parts, hand)


## The pointer beside its piece: to the right of a piece of the corner, over the hand.
func _place(parts: Dictionary, hand: JokerHand) -> void:
	var pulse := 0.5 + 0.5 * sin(_time * TAU * BOB_RATE)
	var bob := (pulse * 2.0 - 1.0) * BOB
	var size := _pointer.get_combined_minimum_size()
	_frame.strength = pulse
	if _pointing == &"hand":
		if hand == null:
			return
		var top := hand.reach() if not hand.hangs() else hand.reach() + size.y
		_pointer.position = Vector2(hand.size.x * 0.5 - size.x * 0.5, top - size.y - GAP + bob)
		_frame.visible = false
		return
	var rect := _anchor(parts).get_global_rect()
	_pointer.position = Vector2(
		rect.end.x + GAP + bob, rect.position.y + rect.size.y * 0.5 - size.y * 0.5
	)
	var grown := rect.grow(FRAME_GROW)
	_frame.position = grown.position
	_frame.size = grown.size


func _anchor(parts: Dictionary) -> Control:
	if _pointing == &"lives":
		var pips: Array = parts["lives"]
		return (pips[0] as Control).get_parent() if not pips.is_empty() else parts["box"]
	var keyed: Dictionary[StringName, String] = {
		&"nitro": "nitro", &"item": "item", &"pot": "pot", &"bank": "banked", &"stats": "stats"
	}
	return parts[keyed.get(_pointing, "box")]
