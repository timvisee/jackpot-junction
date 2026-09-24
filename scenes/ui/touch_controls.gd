class_name TouchControls
extends Control
## The controls on a touch screen, GAME.md 4.2, drawn over the room for the player at this screen.
##
## Answered here finger by finger, from the touches themselves rather than from the mouse the
## engine makes out of the first of them: a player steering with one thumb and pressing with the
## other is two fingers at once, and a mouse is only ever one of them. What the fingers hold goes
## into [TouchInput], which the player's controls read alongside the keyboard and the pads.
##
## The left thumb steers with a stick that comes to wherever it goes down in the lower left of the
## screen. The right thumb has the pedals and the buttons in an arc round the bottom right corner:
## throttle the biggest and nearest the corner, fire beside it, brake beyond that, and drift and
## nitro above, with the item button further in. A thumb sliding from one to another lets go of
## the first and presses the second, and one resting on the seam between throttle and fire presses
## both.
##
## A finger held on one of the jokers in the hand opens it on that card, with what it does over
## it, for as long as it stays there, and sliding it along the hand reads the others, GAME.md
## 3.7. The hand is only read this way: there is no button to open it with.

## The round buttons: a dark disc with a light rim, lit up while a finger is on it.
const FILL := Color(0.05, 0.05, 0.07, 0.45)
const FILL_DOWN := Color(1.0, 1.0, 1.0, 0.3)
const RIM := Color(1.0, 1.0, 1.0, 0.55)
const INK := Color(1.0, 1.0, 1.0, 0.92)
const RIM_WIDTH := 3.0
const LABEL_SIZE := 22
## A finger a little off the edge of a button is still on it: a thumb is not a point.
const REACH := 1.15
## The menu button in the top right corner, which opens the room's menu: the way back to the title
## and out of the game for a player with no Escape key, GAME.md 3.8.
const MENU := &"menu"
const MENU_RADIUS := 34.0
const MENU_INSET := Vector2(64.0, 62.0)
## The driving buttons, each with its size and where its middle is from the bottom right corner.
const THROTTLE := &"throttle"
const FIRE := &"fire"
const BRAKE := &"brake"
const DRIFT := &"drift"
const NITRO := &"nitro"
const ITEM := &"item"
const DRIVING: Dictionary[StringName, Array] = {
	THROTTLE: [86.0, Vector2(-160.0, -168.0), "GAS"],
	FIRE: [74.0, Vector2(-322.0, -118.0), "FIRE"],
	BRAKE: [60.0, Vector2(-470.0, -92.0), "BRAKE"],
	DRIFT: [56.0, Vector2(-340.0, -306.0), "DRIFT"],
	NITRO: [56.0, Vector2(-150.0, -370.0), "NITRO"],
	ITEM: [58.0, Vector2(-500.0, -262.0), ""],
}
## The stick: how big its ring is, where it waits from the bottom left corner, how far its knob
## goes to reach full lock, and how far from the middle a thumb has to be before it steers at all.
## It comes to wherever a thumb goes down inside [constant STICK_ZONE], the share of the screen
## from the left and from the bottom, so nobody has to find it by looking.
const STICK_RADIUS := 120.0
const STICK_KNOB := 52.0
const STICK_HOME := Vector2(230.0, -230.0)
const STICK_ZONE := Vector2(0.42, 0.62)
const STICK_DEAD := 0.1
## The nitro tank round the rim of its button.
const TANK := Color(1.0, 0.75, 0.3, 0.95)
const TANK_WIDTH := 6.0
## The item button is always there, and this faint while there is nothing in hand to play, so a
## thumb knows where it is before it is needed. With an item it wears the item's own picture, and
## while a box is still opening the pictures flick past as they do in the corner, GAME.md 8.3.
const FAINT := 0.3
const ITEM_ART := 0.62


## One round button.
class Pad:
	var id: StringName
	var label := ""
	var center := Vector2.ZERO
	var radius := 0.0
	## How many fingers are on it.
	var held := 0

	func _init(pad_id: StringName, pad_radius: float, pad_label := "") -> void:
		id = pad_id
		radius = pad_radius
		label = pad_label

	func reaches(point: Vector2) -> bool:
		return point.distance_to(center) <= radius * REACH


var match_node: Match

var _pads: Array[Pad] = []
## Which pads each finger is on, by the finger's index. The stick's finger is not among them.
var _fingers: Dictionary[int, Array] = {}
## The finger on the stick, or -1, where the stick came to and where the finger is now.
var _stick_finger := -1
var _stick_at := Vector2.ZERO
var _knob_at := Vector2.ZERO
## The finger resting on a card in the hand, or -1.
var _inspect_finger := -1


## Hangs the controls over [param hud].
static func attach(hud: MatchHud) -> TouchControls:
	var controls := TouchControls.new()
	controls.name = "TouchControls"
	controls.match_node = hud.match_node
	hud.add_child(controls)
	return controls


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pads.append(Pad.new(MENU, MENU_RADIUS))
	for id: StringName in DRIVING:
		_pads.append(Pad.new(id, DRIVING[id][0], DRIVING[id][2]))
	resized.connect(_layout)
	_layout()


func _exit_tree() -> void:
	TouchInput.release()


## The pad called [param id], for asking where it is and whether it is held.
func pad(id: StringName) -> Pad:
	for each: Pad in _pads:
		if each.id == id:
			return each
	return null


## Where the stick waits when nobody has a thumb on it.
func stick_home() -> Vector2:
	return Vector2(STICK_HOME.x, size.y + STICK_HOME.y)


func _layout() -> void:
	pad(MENU).center = Vector2(size.x - MENU_INSET.x, MENU_INSET.y)
	for id: StringName in DRIVING:
		pad(id).center = size + (DRIVING[id][1] as Vector2)
	if _stick_finger < 0:
		_stick_at = stick_home()
		_knob_at = _stick_at
	queue_redraw()


## Whether there is a kart here to drive. The driving buttons go while the match is over, when
## they would sit over the podium's own buttons and do nothing.
func driving() -> bool:
	if match_node == null or match_node.state == Match.State.RESULTS:
		return false
	return _kart() != null


func _kart() -> Kart:
	var slot := _slot()
	return slot.kart if slot != null else null


func _slot() -> PlayerSlot:
	if match_node == null:
		return null
	for slot: PlayerSlot in match_node.slots:
		if slot.is_local_human() and slot.kart != null:
			return slot
	return null


## The hand of cards the HUD keeps for the player here, while it is on the screen.
func _hand() -> JokerHand:
	var slot := _slot()
	if slot == null or get_parent() == null:
		return null
	var hand := get_parent().get_node_or_null("Hand%d" % slot.index) as JokerHand
	return hand if hand != null and hand.is_visible_in_tree() else null


## The card of [param hand] under [param at], a point in these controls' own coordinates.
func _card_in(hand: Control, at: Vector2) -> int:
	var point := hand.get_global_transform_with_canvas().affine_inverse() * _screen(at)
	return (hand as JokerHand).card_at(point)


func _screen(at: Vector2) -> Vector2:
	return get_global_transform_with_canvas() * at


func _process(_delta: float) -> void:
	# The room's menu takes the screen while it is up, and a finger that was down when it opened
	# has let go of everything as far as the room is concerned.
	var shut := PauseMenu.is_open_in(get_tree()) or not driving()
	if shut and (not _fingers.is_empty() or _stick_finger >= 0 or _inspect_finger >= 0):
		_let_go()
	# The tank round the nitro button empties and fills as the kart's own does.
	queue_redraw()


func _input(event: InputEvent) -> void:
	if PauseMenu.is_open_in(get_tree()):
		return
	var touch := event as InputEventScreenTouch
	if touch != null:
		var at := _local(touch.position)
		if touch.pressed:
			_finger_down(touch.index, at)
		else:
			_finger_up(touch.index, at)
		return
	var drag := event as InputEventScreenDrag
	if drag != null:
		_finger_moved(drag.index, _local(drag.position))


func _local(point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * point


func _finger_down(finger: int, at: Vector2) -> void:
	# The same finger down again without having been seen to come up: whatever it was on, it has
	# left, since it cannot be in two places.
	if _fingers.has(finger):
		_release(_fingers[finger])
		_fingers.erase(finger)
	if pad(MENU).reaches(at):
		_hold(finger, [MENU])
		return
	if not driving():
		return
	var hand := _hand()
	if hand != null and _inspect_finger < 0:
		var card := _card_in(hand, at)
		if card >= 0:
			_inspect_finger = finger
			TouchInput.joker_inspect = card
			get_viewport().set_input_as_handled()
			return
	var on := _driving_pads_at(at)
	if not on.is_empty():
		_hold(finger, on)
		return
	if _stick_finger < 0 and at.x < size.x * STICK_ZONE.x and at.y > size.y * (1.0 - STICK_ZONE.y):
		_stick_finger = finger
		# Kept far enough in from the edges that the whole ring is on the screen.
		var margin := Vector2(STICK_RADIUS, STICK_RADIUS)
		_stick_at = at.clamp(margin, size - margin)
		_knob_at = at
		_publish()
		get_viewport().set_input_as_handled()


func _finger_moved(finger: int, at: Vector2) -> void:
	if finger == _inspect_finger:
		# Along the hand to read the next card; off the end of it keeps the last one read.
		var hand := _hand()
		var card := _card_in(hand, at) if hand != null else -1
		if card >= 0:
			TouchInput.joker_inspect = card
		get_viewport().set_input_as_handled()
		return
	if finger == _stick_finger:
		_knob_at = at
		_publish()
		get_viewport().set_input_as_handled()
		return
	if not _fingers.has(finger):
		return
	var on: Array = _fingers[finger]
	# The menu is a tap: a finger that went down on it answers to it alone.
	if on.has(MENU):
		return
	_release(on)
	var now := _driving_pads_at(at)
	_press(now)
	_fingers[finger] = now
	_publish()
	get_viewport().set_input_as_handled()


func _finger_up(finger: int, at: Vector2) -> void:
	if finger == _inspect_finger:
		_inspect_finger = -1
		TouchInput.joker_inspect = -1
		get_viewport().set_input_as_handled()
		return
	if finger == _stick_finger:
		_stick_finger = -1
		_stick_at = stick_home()
		_knob_at = _stick_at
		_publish()
		get_viewport().set_input_as_handled()
		return
	if not _fingers.has(finger):
		return
	var on: Array = _fingers[finger]
	_fingers.erase(finger)
	_release(on)
	# A button that does something once does it as the finger comes up, and only if it comes up
	# still on it: sliding off is how a thumb changes its mind.
	if on.has(MENU) and pad(MENU).reaches(at):
		PauseMenu.open_in(get_tree())
	_publish()
	get_viewport().set_input_as_handled()


func _driving_pads_at(at: Vector2) -> Array[StringName]:
	var on: Array[StringName] = []
	for id: StringName in DRIVING:
		if pad(id).reaches(at):
			on.append(id)
	return on


func _hold(finger: int, on: Array[StringName]) -> void:
	_fingers[finger] = on
	_press(on)
	_publish()
	get_viewport().set_input_as_handled()


func _press(on: Array) -> void:
	for id: StringName in on:
		pad(id).held += 1


func _release(on: Array) -> void:
	for id: StringName in on:
		var each := pad(id)
		each.held = maxi(each.held - 1, 0)


## Every finger off everything.
func _let_go() -> void:
	_fingers.clear()
	for each: Pad in _pads:
		each.held = 0
	_stick_finger = -1
	_stick_at = stick_home()
	_knob_at = _stick_at
	_inspect_finger = -1
	TouchInput.joker_inspect = -1
	_publish()


## Hands what the fingers are holding to [TouchInput], for the player's controls to read.
func _publish() -> void:
	TouchInput.throttle = 1.0 if pad(THROTTLE).held > 0 else 0.0
	TouchInput.brake = 1.0 if pad(BRAKE).held > 0 else 0.0
	TouchInput.fire = pad(FIRE).held > 0
	TouchInput.handbrake = pad(DRIFT).held > 0
	TouchInput.nitro = pad(NITRO).held > 0
	TouchInput.use_item = pad(ITEM).held > 0
	TouchInput.steer = 0.0
	if _stick_finger >= 0:
		var push := clampf((_knob_at.x - _stick_at.x) / STICK_RADIUS, -1.0, 1.0)
		if absf(push) > STICK_DEAD:
			TouchInput.steer = signf(push) * (absf(push) - STICK_DEAD) / (1.0 - STICK_DEAD)
	queue_redraw()


func _draw() -> void:
	var menu := pad(MENU)
	_draw_disc(menu)
	# Three bars, the menu everybody already knows.
	var half := menu.radius * 0.42
	for row: int in 3:
		var y := menu.center.y + (float(row) - 1.0) * menu.radius * 0.3
		draw_line(Vector2(menu.center.x - half, y), Vector2(menu.center.x + half, y), INK, 4.0)
	if not driving():
		return
	var kart := _kart()
	for id: StringName in DRIVING:
		var each := pad(id)
		if id == ITEM:
			_draw_item(each, kart)
			continue
		_draw_disc(each)
		_draw_label(each)
	if kart != null:
		var nitro := pad(NITRO)
		var tank := TAU * clampf(kart.nitro_charge, 0.0, 1.0)
		var start := -PI * 0.5
		draw_arc(nitro.center, nitro.radius - TANK_WIDTH, start, start + tank, 40, TANK, TANK_WIDTH)
	_draw_stick()


func _draw_disc(each: Pad, strength := 1.0) -> void:
	var fill := FILL_DOWN if each.held > 0 else FILL
	draw_circle(each.center, each.radius, Color(fill, fill.a * strength))
	draw_arc(each.center, each.radius, 0.0, TAU, 48, Color(RIM, RIM.a * strength), RIM_WIDTH, true)


## Whether the kart has an item it can play right now.
func has_item() -> bool:
	var kart := _kart()
	return kart != null and kart.held_item != null and kart.item_reveal_left <= 0.0


func _draw_item(each: Pad, kart: Kart) -> void:
	var holding := kart != null and kart.held_item != null
	_draw_disc(each, 1.0 if has_item() else FAINT)
	if not holding:
		return
	var side := each.radius * 2.0 * ITEM_ART
	var box := Rect2(each.center - Vector2(side, side) * 0.5, Vector2(side, side))
	if kart.item_reveal_left > 0.0:
		var spin := PowerUpArt.known()
		var shown := spin[int(kart.item_reveal_left / ItemRow.SPIN) % spin.size()]
		PowerUpArt.draw_into(self, box, shown, Color(ItemRow.SPINNING, FAINT * 2.0))
		return
	PowerUpArt.draw_into(self, box, kart.held_item.id, kart.held_item.color)


func _draw_label(each: Pad) -> void:
	var font := Type.STRONG
	var width := font.get_string_size(each.label, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE).x
	var baseline := each.center + Vector2(-width * 0.5, LABEL_SIZE * 0.36)
	draw_string(font, baseline, each.label, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, INK)


## The ring where the stick is and the knob where the thumb is, the knob kept inside the ring and
## on its level: the stick only steers, so it only moves side to side.
func _draw_stick() -> void:
	var held := _stick_finger >= 0
	draw_circle(_stick_at, STICK_RADIUS, FILL)
	draw_arc(_stick_at, STICK_RADIUS, 0.0, TAU, 64, RIM, RIM_WIDTH, true)
	var reach := clampf(_knob_at.x - _stick_at.x, -STICK_RADIUS, STICK_RADIUS)
	var knob := _stick_at + Vector2(reach, 0.0)
	draw_circle(knob, STICK_KNOB, FILL_DOWN if held else Color(1.0, 1.0, 1.0, 0.16))
	draw_arc(knob, STICK_KNOB, 0.0, TAU, 40, RIM, RIM_WIDTH, true)
