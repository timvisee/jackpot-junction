class_name TouchControls
extends Control
## The controls on a touch screen, GAME.md 4.2, drawn over the room for the player at this screen.
##
## Answered here finger by finger, from the touches themselves rather than from the mouse the
## engine makes out of the first of them: a player steering with one thumb and pressing with the
## other is two fingers at once, and a mouse is only ever one of them. What the fingers hold goes
## into [TouchInput], which the player's controls read alongside the keyboard and the pads.
##
## The left thumb steers with a stick that comes to wherever it goes down in the lower left of
## the screen. The right thumb has a slider in the bottom right corner, one tall pill with nitro,
## gas, brake and drift down it, top to bottom: a thumb goes down anywhere on it and slides
## between them, and belongs to it until it comes up, however far off the side it strays. Fire is
## beside it at the height of the gas, and a thumb rolled across off the slider onto fire fires
## as well as driving; the item button is under fire. While the kart cannot be driven, on the
## grid for the countdown or waiting to come back, the stick and every driving button are grayed
## out and press nothing: a thumb resting on fire after a death would otherwise take a card of
## the respawn pick it has not read. Held through the last lamp, the gas takes the kart away on
## the green. In simple driving the stick points the way and works the pedals, and the right thumb
## has only nitro and drift.
##
## A finger held on one of the jokers in the hand opens it on that card, with what it does over
## it, for as long as it stays there, and sliding it along the hand reads the others, GAME.md
## 3.7. A quick tap keeps the card open instead, with a button each on its pane for dropping and
## destroying it, until it is tapped again or the finger comes down on nothing. There is no button
## to open the hand with. The respawn pick is read the same way, except that a quick tap on one of
## its cards answers it with that card, and its own button under the pane skips it or goes back.
## Whichever of the two was touched last is drawn over the other, so the pane being read is never
## under the cards of the other: on a small screen the two meet. And only one of them has a card
## picked out at a time: going to the hand leaves the pick with none and no pane, and going to the
## pick closes the hand.

## The round buttons: a dark disc with a light rim, lit up while a finger is on it. See-through, so
## the arena under a thumb is still there to be seen.
const FILL := Color(0.05, 0.05, 0.07, 0.3)
const FILL_DOWN := Color(1.0, 1.0, 1.0, 0.3)
const RIM := Color(1.0, 1.0, 1.0, 0.45)
const INK := Color(1.0, 1.0, 1.0, 0.92)
const RIM_WIDTH := 3.0
const LABEL_SIZE := 22
## How much narrower than a button the word on it must be.
const LABEL_ROOM := 16.0
## A finger a little off the edge of a button is still on it: a thumb is not a point.
const REACH := 1.15
## The menu button in the top right corner, which opens the room's menu: the way back to the title
## and out of the game for a player with no Escape key, GAME.md 3.8.
const MENU := &"menu"
const MENU_RADIUS := 34.0
const MENU_INSET := Vector2(64.0, 62.0)
## The round driving buttons of each of the two ways a touch screen drives, GAME.md 4.2, each with
## its size and where its middle is from the bottom right corner. With the slider, fire stands
## beside it at the height of its gas, and the item button under fire, far enough under that a
## thumb between the two presses one of them and not both. Without it, the slider's four are a
## button each in an arc round the corner with fire, the gas the biggest and nearest the corner, a
## thumb on the seam between gas and fire pressing both; the item button is further in, fire
## being at the bottom edge already.
const FIRE := &"fire"
const ITEM := &"item"
const SLIDER_BUTTONS: Dictionary[StringName, Array] = {
	FIRE: [76.0, Vector2(-248.0, -260.0), "FIRE"],
	ITEM: [58.0, Vector2(-248.0, -100.0), ""],
}
## In simple driving, GAME.md 4.2, the stick works the pedals, and without the slider the corner is
## fire's, the button pressed most, with drift beside it along the bottom, nitro over it and the
## item between the two.
const SIMPLE_BUTTONS: Dictionary[StringName, Array] = {
	FIRE: [82.0, Vector2(-160.0, -168.0), "FIRE"],
	TouchSlider.DRIFT: [60.0, Vector2(-345.0, -110.0), "DRIFT"],
	TouchSlider.NITRO: [60.0, Vector2(-150.0, -365.0), "NITRO"],
	ITEM: [58.0, Vector2(-320.0, -290.0), ""],
}
const ROUND_BUTTONS: Dictionary[StringName, Array] = {
	TouchSlider.GAS: [86.0, Vector2(-160.0, -168.0), "GAS"],
	FIRE: [74.0, Vector2(-322.0, -118.0), "FIRE"],
	TouchSlider.BRAKE: [60.0, Vector2(-470.0, -92.0), "BRAKE"],
	TouchSlider.DRIFT: [56.0, Vector2(-340.0, -306.0), "DRIFT"],
	TouchSlider.NITRO: [56.0, Vector2(-150.0, -370.0), "NITRO"],
	ITEM: [58.0, Vector2(-500.0, -262.0), ""],
}
## The click a thumb feels going down on the slider, crossing from one zone of it into the next,
## rolling across onto fire, or going down on a joker and along from one to the next: the
## shortest, lightest buzz the phone makes, so a wrong zone or a new card is felt rather than seen.
## The rumble setting of GAME.md 8.5 turns it off with the rest.
const CLICK_MS := 10
const CLICK_STRENGTH := 0.3
## What the pick or the hand in front is lifted to, past anything either stacks inside itself: the
## lifted card of a full hand, the pick's title over its cards.
const FRONT := 20
const HAND := &"hand"
const PICK := &"pick"
## How long a finger can be on a card of the respawn pick and still have tapped it rather than
## held it, in seconds. Longer is reading it, and letting go after reading takes nothing.
const TAP_SECONDS := 0.3
## The nitro tank, a bar across the bottom of the slider's nitro, and the ring an item counts down
## in round the rim of its button.
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
## picture on the button after the item has gone from the hand, with a ring round the inside of
## the rim counting it down, in the item's color, the way the nitro button's tank does.


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
## How many clicks the slider has given, for asking whether it did.
var clicks := 0
## The slider under the right thumb, and the stick under the left, each with the finger on it.
var slider := TouchSlider.new()
var stick := TouchStick.new()

## Which of the two ways to drive the buttons were last put up for, see [method uses_slider], and
## whether for simple driving, see [method simple].
var _layout_name := ""
var _simple_built := false

var _pads: Array[Pad] = []
## Which pads each finger is on, by the finger's index. The stick's finger is not among them.
var _fingers: Dictionary[int, Array] = {}
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
## The buttons those two fingers went down on, lit up while the finger is still on them.
var _back_button: Button
var _pane_button: Button
## Which of the pick and the hand was touched last, and whether the pick was up last frame: a pick
## coming up comes up in front, being the thing on the screen that wants reading.
var _front := PICK
var _was_picking := false
## Whether the pick has been left with no card picked out, for the hand, see
## [member JokerPicker.quiet].
var _pick_quiet := false
## The finger on a card of the respawn pick, or -1, which card it went down on, when, and whether
## it has been along to another since, which is reading rather than tapping.
var _pick_finger := -1
var _pick_card := -1
var _pick_since := 0.0
var _pick_moved := false
## The finger on the pick's skip or back button, or -1.
var _back_finger := -1
## The finger pointing a freely aimed cannon at the floor, or -1, see [member TouchInput.aim_point].
var _aim_finger := -1


## Where the top right corner is clear from, under the menu button, for the board and the feed
## that hang from it on a touch screen.
static func below_menu() -> float:
	return MENU_INSET.y + MENU_RADIUS + 18.0


## Where the kill feed starts on a touch screen: under the board, which is under the menu button.
static func feed_top(board: Control) -> float:
	if board == null or not board.visible:
		return below_menu()
	return board.get_global_rect().end.y + 12.0


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
	resized.connect(_layout)
	_build_pads()


## Whether the screen drives by the slider, or by a button each for its four, GAME.md 4.2: the
## player's own choice in the settings, which can be changed with a match under way. What is up is
## what answers until the next frame puts the other up, see [method _process].
func uses_slider() -> bool:
	return _layout_name != Settings.TOUCH_BUTTONS


## The round driving buttons of the way the screen drives now.
func driving_buttons() -> Dictionary[StringName, Array]:
	if uses_slider():
		return SLIDER_BUTTONS
	return SIMPLE_BUTTONS if _simple_built else ROUND_BUTTONS


## Whether the player here drives the simple way, GAME.md 4.2: the stick points the way, and the
## pedals are the stick's rather than the right thumb's. Their own choice, which can be changed
## with a match under way, and is put up the next frame the way the layout is.
func simple() -> bool:
	var slot := _slot()
	var player := slot.input as PlayerInput if slot != null else null
	return player != null and player.simple()


func _build_pads() -> void:
	_layout_name = Game.settings.touch_layout
	_simple_built = simple()
	slider.go_simple(_simple_built)
	stick.free = _simple_built
	_pads.clear()
	_pads.append(Pad.new(MENU, MENU_RADIUS))
	var buttons := driving_buttons()
	for id: StringName in buttons:
		_pads.append(Pad.new(id, buttons[id][0], buttons[id][2]))
	_layout()


func _exit_tree() -> void:
	TouchInput.release()


## The pad called [param id], for asking where it is and whether it is held.
func pad(id: StringName) -> Pad:
	for each: Pad in _pads:
		if each.id == id:
			return each
	return null


func _layout() -> void:
	pad(MENU).center = Vector2(size.x - MENU_INSET.x, MENU_INSET.y)
	var buttons := driving_buttons()
	for id: StringName in buttons:
		pad(id).center = size + (buttons[id][1] as Vector2)
	slider.place(size)
	if stick.finger < 0:
		stick.rest(size)
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


## Which of the four the fire button changes rather than firing, GAME.md 4.4: what the stall the
## kart here is standing on is for, or -1 off the stalls, where it fires.
func fire_dresses() -> int:
	return StyleStalls.part_under(match_node, _kart())


## Whether a finger on the arena points this player's cannon: a freely aimed one, GAME.md 4.2.
func _aims() -> bool:
	var kart := _kart()
	return kart != null and kart.alive and KartAim.free_aim(kart)


func _aim(at: Vector2) -> void:
	var on := KartAim.floor_point(get_viewport(), _screen(at))
	if on.is_finite():
		TouchInput.aim_point = on


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
	var hud := _hud()
	var hand := hud.hand_of(slot.index) if slot != null and hud != null else null
	return hand if hand != null and hand.is_visible_in_tree() else null


## The respawn pick the HUD keeps for the player here, while it is up.
func _picker() -> JokerPicker:
	var slot := _slot()
	var hud := _hud()
	var picker := hud.picker_of(slot.index) if slot != null and hud != null else null
	return picker if picker != null and picker.is_visible_in_tree() else null


## The HUD these hang over, which keeps the pieces they work with, see [method MatchHud.hand_of].
func _hud() -> MatchHud:
	return get_parent() as MatchHud


## The card of [param hand] under [param at], a point in these controls' own coordinates.
func _card_in(hand: Control, at: Vector2) -> int:
	var point := hand.get_global_transform_with_canvas().affine_inverse() * _screen(at)
	var picker := hand as JokerPicker
	return picker.card_at(point) if picker != null else (hand as JokerHand).card_at(point)


## Whether [param at] is on the pick's skip or back button.
func _on_back(picker: JokerPicker, at: Vector2) -> bool:
	var button := picker.skip_button() if picker != null else null
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


## A finger gone to the pick: it comes in front, and the hand closes, card, pane and all, even
## under a finger still resting on it.
func _to_the_pick() -> void:
	_front = PICK
	_pick_quiet = false
	_inspect_finger = -1
	_unpin()
	_show_pinned()


## A finger gone to the hand: it comes in front, and the pick is left with no card picked out
## and no pane. A finger still on a card of the pick lets go of it without taking it.
func _to_the_hand() -> void:
	_front = HAND
	_pick_quiet = true
	_pick_finger = -1
	TouchInput.pick_inspect = -1


## The pick and the hand in the order they were last touched, the last on top. Without a pick
## up there is nothing for the hand to be under, and both go back to where the HUD put them.
func _stack_the_jokers() -> void:
	var slot := _slot()
	var hud := _hud()
	if slot == null or hud == null:
		return
	var hand := hud.hand_of(slot.index)
	var picker := hud.picker_of(slot.index)
	if hand == null or picker == null:
		return
	var picking := picker.visible
	if picking and not _was_picking:
		_front = PICK
		_pick_quiet = false
		# A card of the hand left open closes as a pick comes up; one opened over it stays.
		if _pinned >= 0:
			_unpin()
			_show_pinned()
	_was_picking = picking
	var hand_first := picking and _front == HAND
	hand.z_index = FRONT if hand_first else 0
	picker.z_index = FRONT if picking and not hand_first else 0
	picker.quiet = picking and _pick_quiet
	# And the hand between the stick and the buttons rather than under either, with the pick
	# above it rather than over it, however big the UI scale makes them, GAME.md 8.5.
	hand.lane = TouchHud.hand_lane(self)
	# Tucked into the bottom edge until a card of it is being read, see [member JokerHand.tucked].
	hand.tucked = true
	picker.floor_y = hand.reach() - TouchHud.FLOOR_GAP
	var feed := hud.kill_feed()
	if feed != null:
		feed.room = maxf(
			TouchHud.buttons_top(self) - TouchHud.LANE_GAP - feed_top(hud.scoreboard()), 1.0
		)


## The click of the slider under the thumb, felt through the phone.
func _click() -> void:
	clicks += 1
	if Game.settings.rumble:
		Input.vibrate_handheld(CLICK_MS, CLICK_STRENGTH)


## Whether the slider's thumb has rolled across onto fire.
func _rolled_onto_fire() -> bool:
	var fire := pad(FIRE)
	return slider.finger >= 0 and fire.center.distance_to(slider.at) <= fire.radius


## Which of the pick and the hand is drawn over the other just now.
func front() -> StringName:
	return _front if _was_picking else &""


## A card kept open closes when the hand changes under it. The respawn pick coming up closes it
## too, see [method _stack_the_jokers].
func _check_pinned() -> void:
	if _pinned < 0:
		return
	var kart := _kart()
	var gone := kart == null or _pinned >= kart.jokers.count()
	if not gone and kart.jokers.jokers[_pinned].id != _pinned_id:
		gone = true
	if gone:
		_unpin()
		_show_pinned()


func _screen(at: Vector2) -> Vector2:
	return get_global_transform_with_canvas() * at


func _process(_delta: float) -> void:
	# The other way to drive, chosen in the settings over the room: put up at once.
	if Game.settings.touch_layout != _layout_name or simple() != _simple_built:
		_let_go()
		_build_pads()
	# The room's menu takes the screen while it is up, and a finger that was down when it opened
	# has let go of everything as far as the room is concerned. With nothing here to drive, a
	# finger on the menu button is still on it: somebody watching has the menu too.
	var shut := PauseMenu.is_open_in(get_tree()) or not driving()
	var held := stick.finger >= 0 or _inspect_finger >= 0 or _pick_finger >= 0
	held = held or _back_finger >= 0 or _pane_finger >= 0 or _pinned >= 0
	if shut and (_fingers.size() > _on_the_menu().size() or held):
		_let_go()
	# A cannon gone and another picked up later points down the nose until a finger says otherwise.
	if not _aims():
		_aim_finger = -1
		TouchInput.aim_point = Vector3.INF
	_check_pinned()
	_stack_the_jokers()
	TouchHud.compact(_hud(), _slot())
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
	if finger == slider.finger:
		slider.finger = -1
	if finger == stick.finger:
		stick.rest(size)
	if finger == _aim_finger:
		_aim_finger = -1
	var taken := false
	if pad(MENU).reaches(at):
		_hold(finger, [MENU])
		taken = true
	elif driving():
		taken = (
			_down_on_pick(finger, at)
			or _down_on_pane(finger, at)
			or _down_on_hand(finger, at)
			or _down_on_slider(finger, at)
			or _down_on_pads(finger, at)
			or _down_on_stick(finger, at)
		)
		# Down on nothing at all: a card kept open closes. The stick and the buttons leave it be,
		# so the kart can be driven while it is read.
		if not taken and _pinned >= 0:
			_unpin()
			_show_pinned()
		# And with a freely aimed cannon in hand, points it there, GAME.md 4.2, without firing it.
		if not taken and _aims():
			_aim_finger = finger
			_aim(at)
	if taken:
		get_viewport().set_input_as_handled()


## A card of the respawn pick, which is read while it is held, or the pick's own button.
func _down_on_pick(finger: int, at: Vector2) -> bool:
	var picker := _picker()
	if picker == null:
		return false
	var picked := _card_in(picker, at) if _pick_finger < 0 else -1
	if picked >= 0 or (_back_finger < 0 and _on_back(picker, at)):
		_to_the_pick()
	if picked >= 0:
		_pick_finger = finger
		_pick_card = picked
		_pick_since = _now()
		_pick_moved = false
		TouchInput.pick_inspect = picked
		_click()
		return true
	if _back_finger < 0 and _on_back(picker, at):
		_back_finger = finger
		_back_button = picker.skip_button()
		MenuTheme.hold(_back_button, true)
		return true
	return false


## The drop or destroy button on the pane of a card kept open.
func _down_on_pane(finger: int, at: Vector2) -> bool:
	var action := _pane_button_at(at) if _pane_finger < 0 else &""
	if action == &"":
		return false
	_to_the_hand()
	_pane_finger = finger
	_pane_action = action
	_pane_button = _hand().touch_buttons()[action]
	MenuTheme.hold(_pane_button, true)
	return true


## A card in the hand, which is read while it is held and kept open by a quick tap.
func _down_on_hand(finger: int, at: Vector2) -> bool:
	var hand := _hand()
	var card := _card_in(hand, at) if hand != null and _inspect_finger < 0 else -1
	if card < 0:
		return false
	_to_the_hand()
	_inspect_finger = finger
	_inspect_card = card
	_inspect_since = _now()
	_inspect_moved = false
	TouchInput.joker_inspect = card
	TouchInput.joker_pinned = false
	_click()
	return true


## The slider, anywhere on it or a little off either side.
func _down_on_slider(finger: int, at: Vector2) -> bool:
	if not uses_slider() or slider.finger >= 0 or not slider.takes(at):
		return false
	slider.finger = finger
	slider.at = at
	# Clicked on the way down as well as from zone to zone, so the thumb knows it has it.
	_click()
	_publish()
	return true


func _down_on_pads(finger: int, at: Vector2) -> bool:
	var on := _driving_pads_at(at)
	if on.is_empty():
		return false
	_hold(finger, on)
	return true


## The stick comes to the thumb, anywhere in its corner of the screen.
func _down_on_stick(finger: int, at: Vector2) -> bool:
	if not stick.takes(at, size):
		return false
	stick.grab(finger, at, size)
	_publish()
	return true


func _finger_moved(finger: int, at: Vector2) -> void:
	if finger == _aim_finger:
		_aim(at)
	elif finger == _pick_finger:
		var card := _along(_picker(), at, _pick_card)
		if card >= 0:
			_pick_card = card
			_pick_moved = true
			TouchInput.pick_inspect = card
			_click()
	elif finger == _inspect_finger:
		var card := _along(_hand(), at, _inspect_card)
		if card >= 0:
			_inspect_card = card
			_inspect_moved = true
			TouchInput.joker_inspect = card
			_click()
	elif finger == slider.finger:
		var was := slider.slid()
		var rolled := _rolled_onto_fire()
		slider.at = at
		if slider.slid() != was or (_rolled_onto_fire() and not rolled):
			_click()
		_publish()
	elif finger == stick.finger:
		stick.knob = at
		_publish()
	elif _fingers.has(finger):
		_slide(finger, at)
	elif finger == _back_finger:
		MenuTheme.hold(_back_button, _on_back(_picker(), at))
	elif finger == _pane_finger:
		MenuTheme.hold(_pane_button, _pane_button_at(at) == _pane_action)
	else:
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
	# On to one of the four from off it clicks, as the slider does from zone to zone.
	for id: StringName in now:
		if id in TouchSlider.ZONES and id not in on:
			_click()
			break
	_publish()


func _finger_up(finger: int, at: Vector2) -> void:
	if finger == _aim_finger:
		# The cannon stays on the spot it was let go over.
		_aim_finger = -1
	elif finger == _pick_finger:
		_up_from_pick(at)
	elif finger == _back_finger:
		_back_finger = -1
		MenuTheme.hold(_back_button, false)
		if _on_back(_picker(), at):
			TouchInput.press_back()
	elif finger == _inspect_finger:
		_up_from_hand(at)
	elif finger == _pane_finger:
		_up_from_pane(at)
	elif finger == slider.finger:
		slider.finger = -1
		_publish()
	elif finger == stick.finger:
		stick.rest(size)
		_publish()
	elif _fingers.has(finger):
		_up_from_pads(finger, at)
	else:
		return
	get_viewport().set_input_as_handled()


## A quick tap on the one card of the pick, still on it as it comes up, answers the pick with it.
func _up_from_pick(at: Vector2) -> void:
	_pick_finger = -1
	TouchInput.pick_inspect = -1
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
	MenuTheme.hold(_pane_button, false)
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


## The fingers on the menu button, kept by [method _let_go] while the room's menu is shut.
func _on_the_menu() -> Array[int]:
	var on: Array[int] = []
	if PauseMenu.is_open_in(get_tree()):
		return on
	for finger: int in _fingers:
		if (_fingers[finger] as Array).has(MENU):
			on.append(finger)
	return on


func _driving_pads_at(at: Vector2) -> Array[StringName]:
	var on: Array[StringName] = []
	for id: StringName in driving_buttons():
		if pad(id).reaches(at):
			on.append(id)
	return on


func _hold(finger: int, on: Array[StringName]) -> void:
	_fingers[finger] = on
	_press(on)
	for id: StringName in on:
		if id in TouchSlider.ZONES:
			_click()
			break
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
	var kept := _on_the_menu()
	_fingers.clear()
	for each: Pad in _pads:
		each.held = 0
	for finger: int in kept:
		_fingers[finger] = [MENU]
		pad(MENU).held += 1
	slider.finger = -1
	stick.rest(size)
	_inspect_finger = -1
	_pick_finger = -1
	_back_finger = -1
	_pane_finger = -1
	_aim_finger = -1
	MenuTheme.hold(_back_button, false)
	MenuTheme.hold(_pane_button, false)
	_unpin()
	TouchInput.joker_inspect = -1
	TouchInput.joker_pinned = false
	TouchInput.pick_inspect = -1
	_publish()


func _held(id: StringName) -> bool:
	var each := pad(id)
	return each != null and each.held > 0


## Hands what the fingers are holding to [TouchInput], for the player's controls to read.
func _publish() -> void:
	var live := can_drive()
	if uses_slider():
		var zone := slider.slid() if live else &""
		var gas := [TouchSlider.NITRO, TouchSlider.GAS, TouchSlider.DRIFT]
		TouchInput.throttle = 1.0 if zone in gas else 0.0
		TouchInput.brake = 1.0 if zone == TouchSlider.BRAKE else 0.0
		TouchInput.nitro = zone == TouchSlider.NITRO
		TouchInput.handbrake = zone == TouchSlider.DRIFT
	else:
		# A button each, each only itself, the way they always were.
		TouchInput.throttle = 1.0 if live and _held(TouchSlider.GAS) else 0.0
		TouchInput.brake = 1.0 if live and _held(TouchSlider.BRAKE) else 0.0
		TouchInput.nitro = live and _held(TouchSlider.NITRO)
		TouchInput.handbrake = live and _held(TouchSlider.DRIFT)
	TouchInput.fire = live and (pad(FIRE).held > 0 or _rolled_onto_fire())
	TouchInput.use_item = live and pad(ITEM).held > 0
	TouchInput.stick = stick.push() if live else Vector2.ZERO
	TouchInput.steer = TouchInput.stick.x
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
	for id: StringName in driving_buttons():
		var each := pad(id)
		if id == ITEM:
			_draw_item(each, kart)
			continue
		# One of the slider's four on a button of its own is grayed as it would be on the slider.
		var dim := strength if TouchSlider.zone_ready(id, kart) else strength * GRAYED
		_draw_disc(each, dim, id == FIRE and _rolled_onto_fire())
		if id in TouchSlider.ZONES:
			each.label = TouchSlider.word_for(id, kart, each.radius * 2.0 - LABEL_ROOM)
		# On a stall the button puts the next of that thing on rather than firing, GAME.md 4.4, and
		# shows which of the four rather than saying fire.
		var dressing := fire_dresses() if id == FIRE else -1
		if dressing >= 0:
			var side := Vector2.ONE * each.radius * DressArt.ON_BUTTON
			var box := Rect2(each.center - side * 0.5, side)
			DressArt.draw_into(self, box, dressing, INK if dim >= 1.0 else GRAY_INK)
		else:
			_draw_label(each, INK if dim >= 1.0 else GRAY_INK)
		if id == TouchSlider.NITRO and kart != null:
			var tank := TAU * clampf(kart.nitro_charge, 0.0, 1.0)
			var ink := Color(TANK, TANK.a * dim)
			var start := -PI * 0.5
			var ring := each.radius - TANK_WIDTH
			draw_arc(each.center, ring, start, start + tank, 40, ink, TANK_WIDTH)
	if uses_slider():
		slider.draw(self, strength, kart)
	stick.draw(self, strength)


func _draw_disc(each: Pad, strength := 1.0, lit := false) -> void:
	var fill := FILL_DOWN if each.held > 0 or lit else FILL
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
	if not going.is_empty():
		_draw_running(each, going)
	var box := Rect2(each.center - Vector2(side, side) * 0.5, Vector2(side, side))
	# The item in hand first, being the one the button plays; what is running is under it.
	if holding and kart.item_reveal_left > 0.0:
		var spin := PowerUpArt.known()
		var shown := spin[int(kart.item_reveal_left / ItemRow.SPIN) % spin.size()]
		PowerUpArt.draw_into(self, box, shown, Color(ItemRow.SPINNING, FAINT * 2.0))
	elif holding:
		PowerUpArt.draw_into(self, box, kart.held_item.id, kart.held_item.color)
	elif going.get("id", &"") != &"":
		PowerUpArt.draw_into(self, box, going["id"], going["color"])


## The ring counting down what is running, from the top round, as the nitro tank is drawn.
func _draw_running(each: Pad, going: Dictionary) -> void:
	var sweep := TAU * clampf(float(going["left"]), 0.0, 1.0)
	var start := -PI * 0.5
	var ink: Color = going["color"]
	draw_arc(each.center, each.radius - TANK_WIDTH, start, start + sweep, 40, ink, TANK_WIDTH)


func _draw_label(each: Pad, ink: Color) -> void:
	var font := Type.STRONG
	var width := font.get_string_size(each.label, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE).x
	var baseline := each.center + Vector2(-width * 0.5, LABEL_SIZE * 0.36)
	draw_string(font, baseline, each.label, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, ink)
