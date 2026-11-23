class_name SteamKeyboard
extends Node
## Steam's keyboard on the screen, GAME.md 10.8: in a Steam build on a Steam Deck, a Steam Machine
## or with Steam in Big Picture, a box starting to be typed into brings up Steam's floating keyboard
## beside it, the way a phone's keyboard comes up, see [KeyboardBar]. Steam's keyboard types into
## the box as keys do, so everything that listens to the box hears it the way it always has, Enter
## and all. Every box the game has, or comes to have, is given it as it comes into the tree, as
## [PointerHand] gives the hand. It comes up only for a box the player pressed: A on it with a pad,
## the cursor at the end of what it reads, or a click or a tap; not for a box a screen handed the
## cursor, nor one a pad only walked onto, which brought it up as the settings' pages were paged
## through. A box low on the screen, which the keyboard would come up over, is typed into in a
## dialog of its own instead, see [constant IN_DIALOG]. Steam is told where the box is once it stays
## put, see [constant STILL]. Never for a player with a keyboard in hand, see [member keys_in_hand].
## The keyboard goes with the box, once it is done with or gone, and the box is left as the player
## left it. Made by [Game] from its path with Steam on, so nothing it names is compiled with the
## autoloads.

## Steam's word that the player put its floating keyboard away, by its own close or by Enter.
const DISMISSED := &"floating_gamepad_text_input_dismissed"
## What a box is marked with, as a meta: one whose keyboard comes up as soon as it starts being
## typed into, it being in a dialog put up for nothing else, see [NameDialog] and [PasswordPane];
## and one low on the screen, typed into in such a dialog where the keyboard would come up over it,
## see [method NameDialog.retype], the mark holding the dialog's title.
const AT_ONCE := &"keyboard_at_once"
const IN_DIALOG := &"keyboard_in_dialog"
## Steam's floating keyboard's kinds, GodotSteam's `FloatingGamepadTextInputMode`: for a line of
## words, for an email address, and for digits.
const SINGLE_LINE := 0
const EMAIL := 2
const NUMERIC := 3
## The kind each box gets, by the keyboard a phone would give it, its
## [member LineEdit.virtual_keyboard_type]; any other box gets the one for a line of words.
const KINDS: Dictionary[int, int] = {
	LineEdit.KEYBOARD_TYPE_NUMBER: NUMERIC,
	LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL: NUMERIC,
	LineEdit.KEYBOARD_TYPE_PHONE: NUMERIC,
	LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS: EMAIL,
}
## How many frames running a box stays put, drawn whole, before Steam is told where it is, and how
## long that is waited for at most, in seconds. Steam keeps its keyboard clear of where it is told
## the box is, and a box is not always there yet as it starts being typed into: a box handed the
## cursor as its pane is made has not been laid out, and a pane dealt in rises into place, faded
## in, see [method MenuTheme.deal].
const STILL := 2
const LONGEST := 0.6
## How far a pad's stick is pushed before it counts as the pad picked up, as [Game] has it.
const PUSHED := 0.5

## Whether the last thing touched was a key of a keyboard rather than a pad or the screen, so that
## Steam's keyboard stays down for a player who has a keyboard of their own. A key Steam's keyboard
## typed does not count, and the mouse counts for neither, since a Steam Deck's screen and
## trackpads may be one.
var keys_in_hand := false
## The box Steam's keyboard was put up for, until it is done with; null for none.
var field: LineEdit
## Whether Steam's keyboard is up, as far as Steam has said.
var shown := false

## The box Steam's keyboard is to come up for once it stays put, see [constant STILL]; null for
## none. Where it was the frame before, how many frames running it has been there drawn whole, and
## how long it has waited, in seconds.
var _waiting: LineEdit
var _seen := Rect2i()
var _still := 0
var _waited := 0.0
## The box clicked or tapped, whose keyboard comes up as it starts being typed into; null for none.
var _pointed: LineEdit


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_added)
	for each: Node in get_tree().root.find_children("*", "LineEdit", true, false):
		_on_added(each)
	if Store.on() and Store.steam.api.has_signal(DISMISSED):
		Store.steam.api.connect(DISMISSED, _on_dismissed)


## Watches every event, without taking any, for whether a keyboard is in hand.
func _input(event: InputEvent) -> void:
	keys_in_hand = in_hand_after(event, keys_in_hand, shown)


## Whether a keyboard is in hand after [param event], from [param before]: a key pressed says it
## is, unless [param steams], Steam's keyboard being up to have typed it; a pad's button, a real
## push of its stick or a touch of the screen says it is not; anything else, the mouse among them,
## leaves it as it was.
static func in_hand_after(event: InputEvent, before: bool, steams: bool) -> bool:
	if event is InputEventKey:
		return true if event.is_pressed() and not steams else before
	if event is InputEventJoypadButton or event is InputEventScreenTouch:
		return false if event.is_pressed() else before
	var stick := event as InputEventJoypadMotion
	if stick != null and absf(stick.axis_value) > PUSHED:
		return false
	return before


## Whether Steam's keyboard comes up for [param box]: a box that can be typed into, with Steam where
## its keyboard is the way to type, see [method SteamStore.keyboard_here], and no keyboard in hand.
func wanted(box: LineEdit) -> bool:
	if keys_in_hand or not Store.on() or not box.editable or not box.is_visible_in_tree():
		return false
	return Store.steam.keyboard_here()


## Steam's keyboard to come up for [param box], beside it, if it is wanted there, see
## [method wanted]: once the box stays put, see [constant STILL]. Says whether it is to come.
func ask(box: LineEdit) -> bool:
	if not wanted(box):
		return false
	_waiting = box
	_seen = window_rect(box)
	_still = 0
	_waited = 0.0
	return true


## The box waiting for Steam's keyboard followed until it has stayed put, drawn whole, when Steam is
## asked; given up on once the keyboard is not wanted for it any more.
func _process(delta: float) -> void:
	if not is_instance_valid(_waiting):
		_waiting = null
		return
	if not _waiting.is_editing() or not wanted(_waiting):
		_waiting = null
		_done_with()
		return
	var rect := window_rect(_waiting)
	_still = _still + 1 if rect == _seen and drawn_whole(_waiting) else 0
	_seen = rect
	_waited += delta
	if _still >= STILL or _waited >= LONGEST:
		_put_up(_waiting, rect)


## Steam asked for its keyboard for [param box], clear of [param rect]: put up for it, or else the
## one up for a box before it is put away.
func _put_up(box: LineEdit, rect: Rect2i) -> void:
	_waiting = null
	if not Store.steam.show_keyboard(kind_of(box), rect):
		_done_with()
		return
	shown = true
	field = box


## The kind of Steam's keyboard [param box] gets, see [constant KINDS].
static func kind_of(box: LineEdit) -> int:
	return KINDS.get(box.virtual_keyboard_type, SINGLE_LINE)


## Where [param box] is in the window, in its pixels, as Steam is told: through the layer it is
## drawn on and the stretch from the game's own size to the window's.
static func window_rect(box: Control) -> Rect2i:
	var drawn := box.get_viewport().get_final_transform() * box.get_global_transform_with_canvas()
	var rect := drawn * Rect2(Vector2.ZERO, box.size)
	return Rect2i(Vector2i(rect.position.round()), Vector2i(rect.size.round()))


## Whether [param item] is drawn whole, faded neither by itself nor by anything it is drawn on, as a
## pane being dealt in is.
static func drawn_whole(item: CanvasItem) -> bool:
	var on: Node = item
	while on is CanvasItem:
		if (on as CanvasItem).modulate.a < 1.0:
			return false
		on = on.get_parent()
	return item.self_modulate.a >= 1.0


## [param node], come into the tree, heard if it is a box: as it starts being typed into, and as a
## pad's A is pressed on it. Once, however often it comes and goes.
func _on_added(node: Node) -> void:
	var box := node as LineEdit
	if box == null or box.editing_toggled.is_connected(_on_editing):
		return
	box.editing_toggled.connect(_on_editing.bind(box))
	box.gui_input.connect(_on_box_input.bind(box))


## [param box] started being typed into, [param on], or stopped: by Enter, by the cursor going, or
## by going itself.
func _on_editing(on: bool, box: LineEdit) -> void:
	if on:
		if box.has_meta(AT_ONCE) or is_same(box, _pointed):
			ask(box)
		_pointed = null
	elif is_same(box, field) or is_same(box, _waiting):
		# Not put away at once: the cursor going from one box straight to another hands the
		# keyboard over rather than putting it away and up again.
		_done_with.call_deferred()


## A press on [param box]: a pad's A, which has the cursor on it, or a click or a tap. A box low on
## the screen is typed into in a dialog instead, see [constant IN_DIALOG]. A brings Steam's keyboard
## up, or back after it was put away, the cursor at the end of what the box reads: Enter or a click
## starts a box being typed into, and a pad has neither. Taken only when the keyboard or the dialog
## comes; otherwise A does what it did. A click or a tap brings it up as the box starts being typed
## into, or at once where it is being typed into already.
func _on_box_input(event: InputEvent, box: LineEdit) -> void:
	var pad := event is InputEventJoypadButton and event.is_action_pressed(&"ui_accept")
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	var pointed := (
		(click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT)
		or (touch != null and touch.pressed)
	)
	if not pad and not pointed:
		return
	if box.has_meta(IN_DIALOG) and wanted(box):
		box.accept_event()
		NameDialog.retype(box, str(box.get_meta(IN_DIALOG)))
		return
	if pointed:
		if box.is_editing():
			ask(box)
		else:
			_pointed = box
		return
	if (shown and is_same(box, field)) or is_same(box, _waiting) or not ask(box):
		return
	box.edit()
	box.deselect()
	box.caret_column = box.text.length()
	box.accept_event()


## The box the keyboard was put up for, or is to come up for, is done with: unless a box being typed
## into has the keyboard or is to have it, it is put away, if Steam has not put it away already.
func _done_with() -> void:
	if is_instance_valid(_waiting) and _waiting.is_editing():
		return
	_waiting = null
	if is_instance_valid(field) and field.is_editing():
		return
	field = null
	if shown and Store.on():
		Store.steam.hide_keyboard()
	shown = false


## Steam put its keyboard away, at the player's word: the box keeps the cursor and what was typed.
func _on_dismissed() -> void:
	shown = false
