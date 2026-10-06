class_name HudReveal
extends Node
## The match HUD arriving a piece at a time, GAME.md 9.4a: at the start of the tutorial only the
## player's name is in their corner, and each piece comes with the lesson it is for, with a pointer
## beside it saying what it is until the lesson's first task is done. Under the HUD as a child, so
## it runs after the HUD has put everything up for the frame and takes back what is not yet shown.
## The corner's own control hints stay off throughout: the line over the kart is saying it.
##
## The pointer is read, not glimpsed: its line sits on a card of the house's stock cut to an arrow
## at the piece, GAME.md 8.1a, corner brackets pulse round the piece the way an inspector frames
## what is being looked at, and as the card first appears a ring as wide as the screen shrinks onto
## it and away to nothing, twice over, which is what pulls the eye to it wherever it was looking.

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
## The card's point, how long it is and the room round its words, and how long the brackets'
## arms are against the piece's shorter side, kept between the two lengths given.
const POINT := 14.0
const CARD_ROOM := Vector2(14.0, 10.0)
const ARMS := 0.3
const ARM_LENGTHS := Vector2(10.0, 26.0)
## The ring that shrinks onto the pointer's card as it appears: how long one pass takes, in
## seconds, how many passes, and how far out it starts, as a share of the screen's diagonal.
const RING_SECONDS := 1.1
const RING_PASSES := 2
const RING_FROM := 0.42

var hud: MatchHud
## Whose corner, and which.
var slot: PlayerSlot
var index := 0
var shown: Dictionary[StringName, bool] = {}

var _pointer: PanelContainer
var _look: ArrowStyle
var _row: HBoxContainer
## The pointer's line, words with the control drawn in where it names one, see [InputHint].
var _line: Control
var _frame: Frame
## A second frame and a second card, for a pointer that is about two pieces at once, the pot and
## the bank.
var _also_frame: Frame
var _also_pointer: PanelContainer
var _also_row: HBoxContainer
var _also_line: Control
var _also := &""
var _ring: Ring
var _pointing := &""
var _time := 0.0
var _ring_left := 0.0
var _ring_passes := 0


## The frame round the piece pointed at, drawn: a bracket at each corner, pulsing with the pointer.
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
		var ink := Color(INK, 0.45 + 0.55 * strength)
		var arm := clampf(minf(box.size.x, box.size.y) * ARMS, ARM_LENGTHS.x, ARM_LENGTHS.y)
		for corner: Vector2 in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
			var at := box.position + box.size * corner
			var across := Vector2(1.0 - corner.x * 2.0, 0.0) * arm
			var down := Vector2(0.0, 1.0 - corner.y * 2.0) * arm
			draw_polyline(PackedVector2Array([at + across, at, at + down]), ink, 3.0, true)


## A padlock, drawn: shut for the bank, which is safe, open for the pot, which is not. The body
## is a rounded block with a keyhole, the shackle an arc over it, swung up and aside when open.
class Lock:
	extends Control

	const SIDE := 30.0
	const SHUT := Color(0.36, 0.9, 0.46)
	const OPEN := Color(0.98, 0.45, 0.35)

	var open := false

	func _init(is_open: bool) -> void:
		open = is_open
		custom_minimum_size = Vector2(SIDE, SIDE)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var ink := OPEN if open else SHUT
		var body := StyleBoxFlat.new()
		body.bg_color = ink
		body.set_corner_radius_all(3)
		draw_style_box(body, Rect2(Vector2(6.0, 14.0), Vector2(18.0, 13.0)))
		draw_circle(Vector2(15.0, 19.5), 2.2, Color(0.05, 0.05, 0.07))
		draw_rect(Rect2(Vector2(14.2, 19.5), Vector2(1.6, 4.0)), Color(0.05, 0.05, 0.07))
		if open:
			# Swung open: the shackle stands up off the right side, its free end in the air.
			draw_arc(Vector2(21.0, 9.5), 6.0, PI, TAU, 20, ink, 3.0, true)
			draw_line(Vector2(27.0, 9.5), Vector2(27.0, 14.0), ink, 3.0, true)
			draw_line(Vector2(15.0, 9.5), Vector2(15.0, 11.5), ink, 3.0, true)
		else:
			draw_arc(Vector2(15.0, 10.0), 6.0, PI, TAU, 20, ink, 3.0, true)
			draw_line(Vector2(9.0, 10.0), Vector2(9.0, 14.0), ink, 3.0, true)
			draw_line(Vector2(21.0, 10.0), Vector2(21.0, 14.0), ink, 3.0, true)


## The ring shrinking onto the card, drawn about the middle of this control, which is as wide as
## the ring starts.
class Ring:
	extends Control

	## How far along it is, 0 at the start out wide to 1 gone.
	var progress := 0.0:
		set(value):
			progress = value
			queue_redraw()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var eased := progress * progress * (3.0 - 2.0 * progress)
		var radius := size.x * 0.5 * (1.0 - eased)
		if radius < 1.0:
			return
		var width := 3.0 + 5.0 * eased
		draw_arc(size * 0.5, radius, 0.0, TAU, 96, Color(INK, 0.3 + 0.6 * eased), width, true)


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
	_pointer = PanelContainer.new()
	_pointer.name = "Pointer"
	_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_look = _card()
	_pointer.add_theme_stylebox_override("panel", _look)
	_row = HBoxContainer.new()
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_theme_constant_override("separation", 8)
	_pointer.add_child(_row)
	_pointer.visible = false
	hud.add_child(_pointer)
	_frame = Frame.new()
	_frame.name = "Frame"
	_frame.visible = false
	hud.add_child(_frame)
	_also_frame = Frame.new()
	_also_frame.name = "AlsoFrame"
	_also_frame.visible = false
	hud.add_child(_also_frame)
	_also_pointer = PanelContainer.new()
	_also_pointer.name = "AlsoPointer"
	_also_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_also_pointer.add_theme_stylebox_override("panel", _card())
	_also_row = HBoxContainer.new()
	_also_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_also_row.add_theme_constant_override("separation", 8)
	_also_pointer.add_child(_also_row)
	_also_pointer.visible = false
	hud.add_child(_also_pointer)
	_ring = Ring.new()
	_ring.name = "Ring"
	_ring.visible = false
	hud.add_child(_ring)


## A lesson's card, GAME.md 8.1a: the house's stock cut to an arrow at the piece it is about, the
## lesson's cyan in a hairline inside its edge, laminated as a pane is.
static func _card() -> ArrowStyle:
	var card := ArrowStyle.cut(
		Color(HouseTheme.STOCK, 0.9), ArrowStyle.Way.LEFT, POINT, CARD_ROOM.x, CARD_ROOM.y
	)
	card.edge = Color(INK, 0.55)
	card.finish = "pane"
	card.shadow = 8.0
	return card


## Brings [param piece] in, with [param line] on a pointer beside it until [method pointer_done],
## each gap in the line filled with the control of [param actions] for the device in hand, or
## with a mark where the action is one, "icon:safe" a shut padlock and "icon:risk" an open one,
## and a frame round [param also] as well where the line is about two pieces, with a card of its
## own saying [param also_line], its gaps filled from [param also_actions], where there is one. A
## piece that is a part of another, the mult pill of the pot, is pointed at without being brought
## in.
func show_piece(
	piece: StringName,
	line: String,
	actions: Array[StringName] = [],
	also: StringName = &"",
	also_line: String = "",
	also_actions: Array[StringName] = []
) -> void:
	if piece in PIECES:
		shown[piece] = true
	if line.is_empty():
		return
	_pointing = piece
	var keyboard := DeviceInput.uses_keyboard(slot.device()) if slot != null else true
	_also = also
	_also_frame.visible = also != &""
	if _also_line != null:
		_also_row.remove_child(_also_line)
		_also_line.queue_free()
		_also_line = null
	_also_pointer.visible = also != &"" and not also_line.is_empty()
	if _also_pointer.visible:
		var also_parts: Array = []
		for action: StringName in also_actions:
			also_parts.append(_part(action, keyboard))
		_also_line = InputHint.row(also_line, also_parts, INK, Type.LARGE)
		_also_row.add_child(_also_line)
		_also_pointer.reset_size()

	# The old line out of the card before the new one goes in and the card is sized: a freed
	# child is still in the card's size until the end of the frame.
	if _line != null:
		_row.remove_child(_line)
		_line.queue_free()
	var parts: Array = []
	for action: StringName in actions:
		parts.append(_part(action, keyboard))
	_line = InputHint.row(line, parts, INK, Type.LARGE)
	_row.add_child(_line)
	# A card that said something longer before keeps that width unless told to let it go.
	_pointer.reset_size()
	_look.point(ArrowStyle.Way.DOWN if piece == &"hand" else ArrowStyle.Way.LEFT)
	_pointer.visible = true
	_frame.visible = true
	_ring_left = RING_SECONDS
	_ring_passes = RING_PASSES
	_ring.visible = true


## The control for [param action] on the device in hand, or the mark an "icon:" action names.
func _part(action: StringName, keyboard: bool) -> Control:
	if action == &"icon:safe":
		return Lock.new(false)
	if action == &"icon:risk":
		return Lock.new(true)
	return InputHint.glyph(action, keyboard, INK, Type.LARGE)


## The pointer has said its piece.
func pointer_done() -> void:
	_pointing = &""
	_also = &""
	_pointer.visible = false
	_frame.visible = false
	_also_frame.visible = false
	_also_pointer.visible = false
	_ring.visible = false


## [param piece] in the corner from here on, with nothing said about it: for a lesson over that
## never got to point at it.
func ensure_shown(piece: StringName) -> void:
	if piece in PIECES:
		shown[piece] = true


func is_pointing() -> bool:
	return _pointing != &""


## Where the pointer's cards end, from the top of the screen, for what else hangs up there to
## keep clear of; nothing while no card is up, and nothing for the hand's card, which hangs at
## the bottom of the screen.
func card_bottom() -> float:
	if not _pointer.visible or _pointing == &"hand":
		return 0.0
	var bottom := _pointer.position.y + _pointer.get_combined_minimum_size().y
	if _also_pointer.visible:
		bottom = maxf(
			bottom, _also_pointer.position.y + _also_pointer.get_combined_minimum_size().y
		)
	return bottom


## What the pointer says, for asking.
func line() -> String:
	var words: PackedStringArray = []
	if _line != null:
		for part: Node in _line.get_children():
			if part is Label:
				words.append((part as Label).text)
			elif part is RichTextLabel:
				words.append((part as RichTextLabel).get_parsed_text())
	return " ".join(words)


func _process(delta: float) -> void:
	_time += delta
	var parts := hud.block_parts(index)
	if parts.is_empty():
		return
	# An item in hand is shown whatever the lessons did: a slot hidden with something in it is a
	# thing the player cannot see they have.
	var holder := slot.kart if slot != null else null
	if holder != null and is_instance_valid(holder) and holder.held_item != null:
		shown[&"item"] = true
	# The whole block waits for its first piece: a name alone in the corner said nothing.
	var any_shown := false
	for piece: StringName in PIECES:
		any_shown = any_shown or shown[piece]
	(parts["box"] as Control).visible = any_shown
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
	# The card at the hand steps aside while the hand is open: the cards say what is left to read.
	var kart := slot.kart if slot != null else null
	var hand_open := kart != null and is_instance_valid(kart) and kart.menu_open
	_pointer.visible = _pointing != &"" and not (_pointing == &"hand" and hand_open)
	if _pointer.visible:
		_place(parts, hand, delta)


## The pointer beside its piece: to the right of a piece of the corner, over the hand; the frame
## round the piece, and the ring closing in on the card.
func _place(parts: Dictionary, hand: JokerHand, delta: float) -> void:
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
	else:
		var rect := _anchor(_pointing, parts).get_global_rect()
		# The card stands clear of the whole pot row when it is about the mult pill in it.
		var beside := (
			_anchor(&"pot" if _pointing == &"mult" else _pointing, parts).get_global_rect()
		)
		_pointer.position = Vector2(
			beside.end.x + GAP + bob, rect.position.y + rect.size.y * 0.5 - size.y * 0.5
		)
		var grown := rect.grow(FRAME_GROW)
		_frame.position = grown.position
		_frame.size = grown.size
	if _also != &"":
		var other_rect := _anchor(_also, parts).get_global_rect()
		var other := other_rect.grow(FRAME_GROW)
		_also_frame.strength = pulse
		_also_frame.position = other.position
		_also_frame.size = other.size
		if _also_pointer.visible:
			var other_size := _also_pointer.get_combined_minimum_size()
			_also_pointer.position = Vector2(
				other_rect.end.x + GAP + bob,
				other_rect.position.y + other_rect.size.y * 0.5 - other_size.y * 0.5
			)
	if _ring.visible:
		_ring_left = maxf(_ring_left - delta, 0.0)
		var card := Rect2(_pointer.position, size)
		var reach := hud.get_viewport().get_visible_rect().size.length() * RING_FROM
		_ring.position = card.get_center() - Vector2(reach, reach)
		_ring.size = Vector2(reach, reach) * 2.0
		_ring.progress = 1.0 - _ring_left / RING_SECONDS
		if _ring_left <= 0.0:
			_ring_passes -= 1
			if _ring_passes > 0:
				_ring_left = RING_SECONDS
			else:
				_ring.visible = false


## The control [param piece] is on the screen: a part of the corner block, or the mult pill of
## its pot.
func _anchor(piece: StringName, parts: Dictionary) -> Control:
	if piece == &"lives":
		var pips: Array = parts["lives"]
		return (pips[0] as Control).get_parent() if not pips.is_empty() else parts["box"]
	if piece == &"mult":
		return (parts["pot"] as ScorePills).mult
	var keyed: Dictionary[StringName, String] = {
		&"nitro": "nitro", &"item": "item", &"pot": "pot", &"bank": "banked", &"stats": "stats"
	}
	return parts[keyed.get(piece, "box")]
