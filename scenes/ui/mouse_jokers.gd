class_name MouseJokers
extends Control
## The jokers by mouse, GAME.md 3.7, for the player on the keyboard at a screen with no touch: what
## a finger does to them on a touch screen, GAME.md 4.2, the pointer does here. Over a card of the
## respawn pick the pick's cursor goes to it, its pane saying what it does, and a click takes it.
## Over a card of the hand that card opens, pane and all; a click keeps it open, with a button on
## the pane for dropping it and one for destroying it, and a click on it again, or anywhere else,
## closes it, as does the pause key, before it would pause the match. It feeds the same state the
## touch controls do, see [TouchInput], so the hand answers a mouse as it answers a finger, and a
## client's does online as well.
##
## Only a mouse that has moved in the match points at anything: one left lying over the bottom of
## the screen by somebody who plays on the keys alone is not a player reading their hand, and a
## hand held open by it would keep them from playing their item.

## The player the mouse is for, or null: [PlayerInput] takes the pointer's picks and cards for that
## player alone. And whether the pointer has a card of the hand open just now, for the hand to say
## how to keep it or close it rather than naming the keys.
static var player: PlayerInput
static var pointing := false

var match_node: Match

## The card of the hand kept open by a click, and which joker it was, so a hand that changes under
## it lets go rather than showing somebody else's card.
var _pinned := -1
var _pinned_id := &""
## The card of the pick the pointer was last over, so the keys can still walk the cursor off it
## while the pointer rests there.
var _over_pick := -1
## Whether the mouse has moved since the match was put up.
var _moved := false


static func attach(hud: MatchHud) -> MouseJokers:
	var mouse := MouseJokers.new()
	mouse.name = "MouseJokers"
	mouse.match_node = hud.match_node
	hud.add_child(mouse)
	return mouse


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _exit_tree() -> void:
	player = null
	pointing = false
	TouchInput.joker_inspect = -1
	TouchInput.joker_pinned = false


## The player at this screen on the keyboard, whose the mouse is, or null.
func _slot() -> PlayerSlot:
	for slot: PlayerSlot in match_node.slots:
		var here := slot.input as PlayerInput
		if here != null and here.device in [DeviceInput.KEYBOARD, DeviceInput.ANY]:
			return slot if slot.kart != null else null
	return null


func _process(_delta: float) -> void:
	var slot := _slot()
	var shut := slot == null or PauseMenu.is_open_in(get_tree())
	player = null if shut else slot.input as PlayerInput
	if player == null:
		_unpin()
		_over_pick = -1
		pointing = false
		TouchInput.joker_inspect = -1
		TouchInput.joker_pinned = false
		return
	_check_pinned(slot)
	point(slot, get_viewport().get_mouse_position())


## The pointer at [param at] on the screen, for [param slot]'s player: a card of the pick under it
## is the pick's cursor, and a card of the hand under it is open, or else the one kept open is.
func point(slot: PlayerSlot, at: Vector2) -> void:
	if not _moved:
		at = -Vector2.ONE
	var over_pick := _card_in(_picker(slot), at)
	if over_pick != _over_pick and over_pick >= 0 and slot.offer != null:
		# The pick's own cursor, moved as the pointer comes onto a card: the keys, and the fire
		# button, go on answering it, where a finger resting on a card holds it still.
		slot.offer.selected = over_pick
	_over_pick = over_pick
	var over_hand := _card_in(_hand(slot), at) if over_pick < 0 else -1
	TouchInput.joker_inspect = over_hand if over_hand >= 0 else _pinned
	TouchInput.joker_pinned = _pinned >= 0 and TouchInput.joker_inspect == _pinned
	pointing = TouchInput.joker_inspect >= 0


# A click on a card, or on the pane of one kept open, is the mouse's; anywhere else it goes on to
# whatever else it was for, and closes a card that was kept open.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_moved = true
	# The pause key puts a card kept open away first, the way Back leaves a pane before it leaves
	# the screen: the card is what the player is looking at. Only the keyboard's, whose player the
	# mouse is for; Start on a pad at the same screen still pauses.
	if (
		player != null
		and _pinned >= 0
		and event is InputEventKey
		and event.is_action_pressed(InputActions.PAUSE)
	):
		_unpin()
		get_viewport().set_input_as_handled()
		return
	var click := event as InputEventMouseButton
	if player == null or click == null or not click.pressed:
		return
	if click.button_index != MOUSE_BUTTON_LEFT:
		return
	var slot := _slot()
	var picked := _card_in(_picker(slot), click.position)
	if picked >= 0:
		TouchInput.tap(picked)
		get_viewport().set_input_as_handled()
		return
	var action := _pane_button_at(slot, click.position)
	if action != &"":
		if action == &"drop":
			TouchInput.drop(_pinned)
		else:
			TouchInput.destroy(_pinned)
		_unpin()
		get_viewport().set_input_as_handled()
		return
	var card := _card_in(_hand(slot), click.position)
	if card >= 0:
		if card == _pinned:
			_unpin()
		else:
			_pin(slot, card)
		get_viewport().set_input_as_handled()
		return
	_unpin()


## The hand and the pick of each seat, as the HUD this hangs over keeps them, see [method
## MatchHud.hand_of]: while they are on the screen.
func _hand(slot: PlayerSlot) -> JokerHand:
	var hud := get_parent() as MatchHud
	var hand := hud.hand_of(slot.index) if hud != null else null
	return hand if hand != null and hand.is_visible_in_tree() else null


func _picker(slot: PlayerSlot) -> JokerPicker:
	var hud := get_parent() as MatchHud
	var picker := hud.picker_of(slot.index) if hud != null else null
	return picker if picker != null and picker.is_visible_in_tree() else null


## The card of [param cards], a hand or a pick, under [param at] on the screen, or -1.
static func _card_in(cards: Control, at: Vector2) -> int:
	if cards == null:
		return -1
	var point := cards.get_global_transform_with_canvas().affine_inverse() * at
	var picker := cards as JokerPicker
	return picker.card_at(point) if picker != null else (cards as JokerHand).card_at(point)


## The drop or destroy button under [param at] on the pane of the card kept open, or empty.
func _pane_button_at(slot: PlayerSlot, at: Vector2) -> StringName:
	var hand := _hand(slot)
	if hand == null or _pinned < 0:
		return &""
	var buttons := hand.touch_buttons()
	for id: StringName in buttons:
		if buttons[id].get_global_rect().has_point(at):
			return id
	return &""


func _pin(slot: PlayerSlot, card: int) -> void:
	if card < 0 or card >= slot.kart.jokers.count():
		return
	_pinned = card
	_pinned_id = slot.kart.jokers.jokers[card].id


func _unpin() -> void:
	_pinned = -1
	_pinned_id = &""


## A card kept open that is no longer there, or is somebody else's now, lets go.
func _check_pinned(slot: PlayerSlot) -> void:
	if _pinned < 0:
		return
	var jokers := slot.kart.jokers
	if _pinned >= jokers.count() or jokers.jokers[_pinned].id != _pinned_id:
		_unpin()
