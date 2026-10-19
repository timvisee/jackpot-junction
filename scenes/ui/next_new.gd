class_name NextNew
extends HBoxContainer
## Next new, GAME.md 8.8: a button in the head of each large dialog, the catalog, the loyalty
## program of 8.9 and the achievements of 8.10, that takes the cursor at once to the next thing in
## the dialog wearing the NEW tag, after the one the cursor is on in the dialog's own order and
## round past the last, turning to its page or its sheet as it goes; the cursor coming to it takes
## the tag off as it always does, so pressed again and again it takes every tag off as fast as it is
## pressed. How many are left stands on a chip of the tags' own foil over its top right corner, as
## a card's tag is over the card's; it is there while one is and gone once none is.
##
## Its bind, the dialogs' own, N or a pad's View, see [constant InputActions.MENU_NEXT_NEW], hangs
## on the middle of its foot while keys or a pad are in hand, as How it works' does on the loyalty
## program's, see [ButtonBinds], and never on a touch screen; a click or a tap presses it, the
## pointing hand over it, see
## [PointerHand]. It never takes the cursor, which it moves. The dialog makes the button in its own
## look and says what is new and where to go, see [method after]; this keeps the rest, and puts its
## face on it, see [method face]: an arrow coming down onto a dot, rather than words, which only a
## screen reader is told. Where it lands draws the eye, see [LandingCue].

## Pressed, or its bind: the dialog takes the cursor to its next new thing.
signal asked

const WORDS := "Next new"
## How much wider than its face the button is, for the dialog's own edge round it.
const FACE_ROOM := 36.0
## How many are left, said to a screen reader after its words.
const LEFT := "%d left"
const ACTION := InputActions.MENU_NEXT_NEW

## The button, in the dialog's own look, with its face on it, see [method face].
var button: Button
## The chip over the button's top right corner saying how many are left, and its words.
var chip: PanelContainer
var count: Label

var _left := -1


## Next new as [param dressed], a button the dialog has made in its own look, its face put on it in
## place of any words, see [method face]; not there until something is new, see
## [method show_left].
static func around(dressed: Button) -> NextNew:
	var made := NextNew.new()
	made.name = "NextNew"
	made.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	made.button = dressed
	dressed.name = "Button"
	dressed.focus_mode = Control.FOCUS_NONE
	dressed.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dressed.pressed.connect(made.asked.emit)
	ButtonBinds.mark(dressed, ACTION)
	dressed.text = ""
	var shown := face(dressed)
	dressed.add_child(shown)
	# As wide as its face and the dialog's edge round it, the face being no words the button sees.
	var fit := func() -> void:
		dressed.custom_minimum_size.x = shown.get_combined_minimum_size().x + FACE_ROOM
	shown.minimum_size_changed.connect(fit)
	fit.call()
	made.add_child(dressed)
	made.chip = PanelContainer.new()
	made.chip.name = "Left"
	made.chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	made.chip.add_theme_stylebox_override("panel", CatalogCell.foil())
	made.count = Label.new()
	made.count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Type.strong(made.count, CatalogCell.NEW_SIZE, HouseTheme.ON_FOIL)
	made.chip.add_child(made.count)
	# Hung by its top right corner, as a NEW tag is, growing left and down from there.
	made.chip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	made.chip.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	made.chip.offset_left = CatalogCell.NEW_OUT.x
	made.chip.offset_right = CatalogCell.NEW_OUT.x
	made.chip.offset_top = CatalogCell.NEW_OUT.y
	made.chip.offset_bottom = CatalogCell.NEW_OUT.y
	dressed.add_child(made.chip)
	made.show_left(0)
	return made


## The face of [param dressed], GAME.md 8.8: an arrow coming down onto a dot, the cursor dropped
## onto the next thing new, in the button's own ink, in the middle of it, see [JumpIcon].
static func face(dressed: Button) -> Control:
	var middle := CenterContainer.new()
	middle.name = "Face"
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	middle.add_child(JumpIcon.on(dressed))
	return middle


## The first of [param order] after [param at] that [param fresh] says is new, round past its end
## and back to [param at] itself last, or from its start where [param at] is not in it; null with
## none new. What a dialog goes by to find its next new thing, its things in its own order.
static func after(order: Array, at: Variant, fresh: Callable) -> Variant:
	var from := order.find(at)
	for step: int in range(1, order.size() + 1):
		var each: Variant = order[posmod(from + step, order.size())]
		if fresh.call(each):
			return each
	return null


## There while [param left] things in the dialog are new, saying how many; gone with none.
func show_left(left: int) -> void:
	if left == _left:
		return
	_left = left
	visible = left > 0
	count.text = str(left)
	ScreenReader.name(button, WORDS, LEFT % left)


## How many it says are left.
func left() -> int:
	return maxi(_left, 0)


## Its bind while one is hung on it, see [method show_bind]; null while none is.
func bind() -> Control:
	return button.get_node_or_null("Bind") as Control


## Its bind hung on its foot, drawn for a [param keyboard] or a pad, or none while [param shown]
## is false or on a touch screen, where it is tapped, see [ButtonBinds].
func show_bind(keyboard: bool, shown: bool) -> void:
	ButtonBinds.show([button], keyboard, shown)


## Whether [param event] presses its bind while it is there, which presses it as a click does, its
## click heard and the cursor moved.
func heard(event: InputEvent) -> bool:
	if not visible or not event.is_action_pressed(ACTION):
		return false
	button.pressed.emit()
	return true
