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
## both. While the kart cannot be driven, on the grid for the countdown or waiting to come back,
## the stick and every driving button are grayed out and press nothing: a thumb resting on fire
## after a death would otherwise take a card of the respawn pick it has not read. Held through the
## last lamp, the gas takes the kart away on the green.
##
## A finger held on one of the jokers in the hand opens it on that card, with what it does over
## it, for as long as it stays there, and sliding it along the hand reads the others, GAME.md
## 3.7. A quick tap keeps the card open instead, with a button each on its pane for dropping and
## destroying it, until it is tapped again or the finger comes down on nothing. There is no button
## to open the hand with. The respawn pick is read the same way, except that a quick tap on one of
## its cards answers it with that card, and its own button under the pane skips it or goes back.

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
## How long a finger can be on a card of the respawn pick and still have tapped it rather than
## held it, in seconds. Longer is reading it, and letting go after reading takes nothing.
const TAP_SECONDS := 0.3
## The nitro tank round the rim of its button.
const TANK := Color(1.0, 0.75, 0.3, 0.95)
const TANK_WIDTH := 6.0
## How strongly the stick and the driving buttons are drawn while the kart cannot be driven, and
## the gray their words go.
const GRAYED := 0.35
const GRAY_INK := Color(0.62, 0.62, 0.66, 0.7)
## The item button is always there, and this faint while there is nothing in hand to play, so a
## thumb knows where it is before it is needed. With an item it wears the item's own picture, and
## while a box is still opening the pictures flick past as they do in the corner, GAME.md 8.3.
const FAINT := 0.3
const ITEM_ART := 0.62
## Something an item started and has still to finish, a shield up or shots loaded, keeps its
## picture on the button after the item has gone from the hand, with a bar inside counting it down
## the way the one in the corner does. The picture moves up to make room.
const RUNNING_BAR := Vector2(1.1, 7.0)
const RUNNING_BACK := Color(0.0, 0.0, 0.0, 0.55)
const RUNNING_LIFT := 0.14


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
## The finger resting on a card in the hand, or -1, the card it is on, since when, and whether it
## has been along to another since, which is reading rather than tapping.
var _inspect_finger := -1
var _inspect_card := -1
var _inspect_since := 0.0
var _inspect_moved := false
## The card of the hand tapped to keep it open, or -1, and which joker it was, so a hand that
## changes under it closes it rather than leaving another card open in its place.
var _pinned := -1
var _pinned_id := &""
## The finger on the drop or destroy button of an open card's pane, or -1, and which of the two.
var _pane_finger := -1
var _pane_action := &""
## The finger on a card of the respawn pick, or -1, which card it went down on, when, and whether
## it has been along to another since, which is reading rather than tapping.
var _pick_finger := -1
var _pick_card := -1
var _pick_since := 0.0
var _pick_moved := false
## The finger on the pick's skip or back button, or -1.
var _back_finger := -1


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


## Whether the kart here can be driven right now: not on the grid waiting for the lamps, not down,
## not falling and not rolling out the end of the match.
func can_drive() -> bool:
	var kart := _kart()
	return kart != null and kart.is_active() and driving()


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


## The respawn pick the HUD keeps for the player here, while it is up.
func _picker() -> JokerPicker:
	var slot := _slot()
	if slot == null or get_parent() == null:
		return null
	var picker := get_parent().get_node_or_null("Picker%d" % slot.index) as JokerPicker
	return picker if picker != null and picker.is_visible_in_tree() else null


## The card of [param hand] under [param at], a point in these controls' own coordinates.
func _card_in(hand: Control, at: Vector2) -> int:
	var point := hand.get_global_transform_with_canvas().affine_inverse() * _screen(at)
	var picker := hand as JokerPicker
	return picker.card_at(point) if picker != null else (hand as JokerHand).card_at(point)


## Whether [param at] is on the pick's skip or back button.
func _on_back(picker: JokerPicker, at: Vector2) -> bool:
	var button := picker.touch_button() if picker != null else null
	return button != null and button.get_global_rect().has_point(_screen(at))


static func _now() -> float:
	return Time.get_ticks_msec() * 0.001


## Which of the open card's pane buttons is under [param at], or an empty name.
func _pane_button_at(at: Vector2) -> StringName:
	var hand := _hand()
	if hand == null or _pinned < 0:
		return &""
	var buttons := hand.touch_buttons()
	for id: StringName in buttons:
		if buttons[id].get_global_rect().has_point(_screen(at)):
			return id
	return &""


func _pin(card: int) -> void:
	var kart := _kart()
	if kart == null or card < 0 or card >= kart.jokers.count():
		return
	_pinned = card
	_pinned_id = kart.jokers.jokers[card].id


func _unpin() -> void:
	_pinned = -1
	_pinned_id = &""


## The hand shows the card kept open, if there is one and no finger is on another.
func _show_pinned() -> void:
	if _inspect_finger >= 0:
		return
	TouchInput.joker_inspect = _pinned
	TouchInput.joker_pinned = _pinned >= 0


## A card kept open closes when the hand changes under it, and when the respawn pick comes up
## over it, which has the middle of the screen and the player's attention.
func _check_pinned() -> void:
	if _pinned < 0:
		return
	var kart := _kart()
	var gone := kart == null or _pinned >= kart.jokers.count()
	if not gone and kart.jokers.jokers[_pinned].id != _pinned_id:
		gone = true
	if gone or _picker() != null:
		_unpin()
		_show_pinned()


func _screen(at: Vector2) -> Vector2:
	return get_global_transform_with_canvas() * at


func _process(_delta: float) -> void:
	# The room's menu takes the screen while it is up, and a finger that was down when it opened
	# has let go of everything as far as the room is concerned.
	var shut := PauseMenu.is_open_in(get_tree()) or not driving()
	var held := _stick_finger >= 0 or _inspect_finger >= 0 or _pick_finger >= 0
	held = held or _back_finger >= 0 or _pane_finger >= 0 or _pinned >= 0
	if shut and (not _fingers.is_empty() or held):
		_let_go()
	_check_pinned()
	# Again every frame, not only as fingers move: the lamps going green under a thumb already on
	# the gas is the kart setting off.
	_publish()


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
	var taken := false
	if pad(MENU).reaches(at):
		_hold(finger, [MENU])
		taken = true
	elif driving():
		taken = (
			_down_on_pick(finger, at)
			or _down_on_pane(finger, at)
			or _down_on_hand(finger, at)
			or _down_on_pads(finger, at)
			or _down_on_stick(finger, at)
		)
		# Down on nothing at all: a card kept open closes. The stick and the buttons leave it be,
		# so the kart can be driven while it is read.
		if not taken and _pinned >= 0:
			_unpin()
			_show_pinned()
	if taken:
		get_viewport().set_input_as_handled()


## A card of the respawn pick, which is read while it is held, or the pick's own button.
func _down_on_pick(finger: int, at: Vector2) -> bool:
	var picker := _picker()
	if picker == null:
		return false
	var picked := _card_in(picker, at) if _pick_finger < 0 else -1
	if picked >= 0:
		_pick_finger = finger
		_pick_card = picked
		_pick_since = _now()
		_pick_moved = false
		TouchInput.joker_inspect = picked
		return true
	if _back_finger < 0 and _on_back(picker, at):
		_back_finger = finger
		return true
	return false


## The drop or destroy button on the pane of a card kept open.
func _down_on_pane(finger: int, at: Vector2) -> bool:
	var action := _pane_button_at(at) if _pane_finger < 0 else &""
	if action == &"":
		return false
	_pane_finger = finger
	_pane_action = action
	return true


## A card in the hand, which is read while it is held and kept open by a quick tap.
func _down_on_hand(finger: int, at: Vector2) -> bool:
	var hand := _hand()
	var card := _card_in(hand, at) if hand != null and _inspect_finger < 0 else -1
	if card < 0:
		return false
	_inspect_finger = finger
	_inspect_card = card
	_inspect_since = _now()
	_inspect_moved = false
	TouchInput.joker_inspect = card
	TouchInput.joker_pinned = false
	return true


func _down_on_pads(finger: int, at: Vector2) -> bool:
	var on := _driving_pads_at(at)
	if on.is_empty():
		return false
	_hold(finger, on)
	return true


## The stick comes to the thumb, anywhere in its corner of the screen.
func _down_on_stick(finger: int, at: Vector2) -> bool:
	var inside := at.x < size.x * STICK_ZONE.x and at.y > size.y * (1.0 - STICK_ZONE.y)
	if _stick_finger >= 0 or not inside:
		return false
	_stick_finger = finger
	# Kept far enough in from the edges that the whole ring is on the screen.
	var margin := Vector2(STICK_RADIUS, STICK_RADIUS)
	_stick_at = at.clamp(margin, size - margin)
	_knob_at = at
	_publish()
	return true


func _finger_moved(finger: int, at: Vector2) -> void:
	if finger == _pick_finger:
		var card := _along(_picker(), at, _pick_card)
		if card >= 0:
			_pick_card = card
			_pick_moved = true
			TouchInput.joker_inspect = card
	elif finger == _inspect_finger:
		var card := _along(_hand(), at, _inspect_card)
		if card >= 0:
			_inspect_card = card
			_inspect_moved = true
			TouchInput.joker_inspect = card
	elif finger == _stick_finger:
		_knob_at = at
		_publish()
	elif _fingers.has(finger):
		_slide(finger, at)
	elif finger != _back_finger and finger != _pane_finger:
		return
	get_viewport().set_input_as_handled()


## The card of [param board] a finger has moved on to from [param card], or -1 for the same one
## or none: along a row reads the next card, and off the end of it keeps the last one read.
func _along(board: Control, at: Vector2, card: int) -> int:
	var now := _card_in(board, at) if board != null else -1
	return now if now != card else -1


## A thumb sliding across the driving buttons lets go of what it has left and presses what it
## is on now. The menu is a tap: a finger that went down on it answers to it alone.
func _slide(finger: int, at: Vector2) -> void:
	var on: Array = _fingers[finger]
	if on.has(MENU):
		return
	_release(on)
	var now := _driving_pads_at(at)
	_press(now)
	_fingers[finger] = now
	_publish()


func _finger_up(finger: int, at: Vector2) -> void:
	if finger == _pick_finger:
		_up_from_pick(at)
	elif finger == _back_finger:
		_back_finger = -1
		if _on_back(_picker(), at):
			TouchInput.press_back()
	elif finger == _inspect_finger:
		_up_from_hand(at)
	elif finger == _pane_finger:
		_up_from_pane(at)
	elif finger == _stick_finger:
		_stick_finger = -1
		_stick_at = stick_home()
		_knob_at = _stick_at
		_publish()
	elif _fingers.has(finger):
		_up_from_pads(finger, at)
	else:
		return
	get_viewport().set_input_as_handled()


## A quick tap on the one card of the pick, still on it as it comes up, answers the pick with it.
func _up_from_pick(at: Vector2) -> void:
	_pick_finger = -1
	TouchInput.joker_inspect = -1
	var picker := _picker()
	var quick := _now() - _pick_since <= TAP_SECONDS and not _pick_moved
	if quick and picker != null and _card_in(picker, at) == _pick_card:
		TouchInput.tap(_pick_card)


## A quick tap on the one card of the hand keeps it open, or closes it if it already was.
func _up_from_hand(at: Vector2) -> void:
	_inspect_finger = -1
	var hand := _hand()
	var quick := _now() - _inspect_since <= TAP_SECONDS and not _inspect_moved
	if quick and hand != null and _card_in(hand, at) == _inspect_card:
		if _pinned == _inspect_card:
			_unpin()
		else:
			_pin(_inspect_card)
	_show_pinned()


## Still on the button it went down on as it comes up: the open card is dropped or destroyed, and
## the pane goes with it.
func _up_from_pane(at: Vector2) -> void:
	_pane_finger = -1
	if _pane_button_at(at) != _pane_action or _pinned < 0:
		return
	if _pane_action == &"drop":
		TouchInput.drop(_pinned)
	else:
		TouchInput.destroy(_pinned)
	_unpin()
	_show_pinned()


## A button that does something once does it as the finger comes up, and only if it comes up still
## on it: sliding off is how a thumb changes its mind.
func _up_from_pads(finger: int, at: Vector2) -> void:
	var on: Array = _fingers[finger]
	_fingers.erase(finger)
	_release(on)
	if on.has(MENU) and pad(MENU).reaches(at):
		PauseMenu.open_in(get_tree())
	_publish()


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
	_pick_finger = -1
	_back_finger = -1
	_pane_finger = -1
	_unpin()
	TouchInput.joker_inspect = -1
	TouchInput.joker_pinned = false
	_publish()


## Hands what the fingers are holding to [TouchInput], for the player's controls to read.
func _publish() -> void:
	var live := can_drive()
	TouchInput.throttle = 1.0 if live and pad(THROTTLE).held > 0 else 0.0
	TouchInput.brake = 1.0 if live and pad(BRAKE).held > 0 else 0.0
	TouchInput.fire = live and pad(FIRE).held > 0
	TouchInput.handbrake = live and pad(DRIFT).held > 0
	TouchInput.nitro = live and pad(NITRO).held > 0
	TouchInput.use_item = live and pad(ITEM).held > 0
	TouchInput.steer = 0.0
	if live and _stick_finger >= 0:
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
	var strength := 1.0 if can_drive() else GRAYED
	for id: StringName in DRIVING:
		var each := pad(id)
		if id == ITEM:
			_draw_item(each, kart)
			continue
		_draw_disc(each, strength)
		_draw_label(each, INK if strength >= 1.0 else GRAY_INK)
	if kart != null:
		var nitro := pad(NITRO)
		var tank := TAU * clampf(kart.nitro_charge, 0.0, 1.0)
		var start := -PI * 0.5
		var ink := Color(TANK, TANK.a * strength)
		draw_arc(nitro.center, nitro.radius - TANK_WIDTH, start, start + tank, 40, ink, TANK_WIDTH)
	_draw_stick(strength)


func _draw_disc(each: Pad, strength := 1.0) -> void:
	var fill := FILL_DOWN if each.held > 0 else FILL
	draw_circle(each.center, each.radius, Color(fill, fill.a * strength))
	draw_arc(each.center, each.radius, 0.0, TAU, 48, Color(RIM, RIM.a * strength), RIM_WIDTH, true)


## What an item started and has still to finish on the kart here, as the corner shows it, or an
## empty dictionary: its name, the item's id, its color and how much of it is left, 0 to 1.
func running() -> Dictionary:
	var kart := _kart()
	var going := ItemRow.going_on(kart) if kart != null else []
	return going[0] if not going.is_empty() else {}


## Whether the kart has an item it can play right now.
func has_item() -> bool:
	var kart := _kart()
	return kart != null and kart.held_item != null and kart.item_reveal_left <= 0.0


func _draw_item(each: Pad, kart: Kart) -> void:
	var holding := kart != null and kart.held_item != null
	var going := running()
	_draw_disc(each, 1.0 if has_item() and can_drive() else FAINT)
	var side := each.radius * 2.0 * ITEM_ART
	var middle := each.center
	if not going.is_empty():
		middle.y -= each.radius * RUNNING_LIFT
		_draw_running(each, going)
	var box := Rect2(middle - Vector2(side, side) * 0.5, Vector2(side, side))
	# The item in hand first, being the one the button plays; what is running is under it.
	if holding and kart.item_reveal_left > 0.0:
		var spin := PowerUpArt.known()
		var shown := spin[int(kart.item_reveal_left / ItemRow.SPIN) % spin.size()]
		PowerUpArt.draw_into(self, box, shown, Color(ItemRow.SPINNING, FAINT * 2.0))
	elif holding:
		PowerUpArt.draw_into(self, box, kart.held_item.id, kart.held_item.color)
	elif going.get("id", &"") != &"":
		PowerUpArt.draw_into(self, box, going["id"], going["color"])


## The bar counting down what is running, across the lower part of the button.
func _draw_running(each: Pad, going: Dictionary) -> void:
	var width := each.radius * RUNNING_BAR.x
	var at := each.center + Vector2(-width * 0.5, each.radius * 0.5)
	draw_rect(Rect2(at, Vector2(width, RUNNING_BAR.y)), RUNNING_BACK)
	var left := clampf(float(going["left"]), 0.0, 1.0)
	draw_rect(Rect2(at, Vector2(width * left, RUNNING_BAR.y)), going["color"])


func _draw_label(each: Pad, ink: Color) -> void:
	var font := Type.STRONG
	var width := font.get_string_size(each.label, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE).x
	var baseline := each.center + Vector2(-width * 0.5, LABEL_SIZE * 0.36)
	draw_string(font, baseline, each.label, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, ink)


## The ring where the stick is and the knob where the thumb is, the knob kept inside the ring and
## on its level: the stick only steers, so it only moves side to side.
func _draw_stick(strength: float) -> void:
	var held := _stick_finger >= 0
	var rim := Color(RIM, RIM.a * strength)
	draw_circle(_stick_at, STICK_RADIUS, Color(FILL, FILL.a * strength))
	draw_arc(_stick_at, STICK_RADIUS, 0.0, TAU, 64, rim, RIM_WIDTH, true)
	var reach := clampf(_knob_at.x - _stick_at.x, -STICK_RADIUS, STICK_RADIUS)
	var knob := _stick_at + Vector2(reach, 0.0)
	var fill := FILL_DOWN if held else Color(1.0, 1.0, 1.0, 0.16)
	draw_circle(knob, STICK_KNOB, Color(fill, fill.a * strength))
	draw_arc(knob, STICK_KNOB, 0.0, TAU, 40, rim, RIM_WIDTH, true)
