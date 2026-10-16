class_name PointerHand
extends Node
## The pointing hand, GAME.md 8.1a: with a mouse, whatever a click acts on shows the hand while the
## mouse is over it, and nothing else does. Every one of the engine's controls a click acts on, a
## button or a switch, a slider, a scroll bar, a tab, the list a box drops, is given it as it comes
## into the tree, the buttons the game draws for itself among them, unless it has a cursor of its
## own already, as the grip a server is dragged by does; a button that cannot be pressed just now
## shows the arrow, and a row of tabs shows the hand over a tab and the arrow beside them. What the
## game draws for itself and hears its own clicks on, a peek on the title, a key on the kart
## dialog's rail, a page of Kit's folder, says where a click acts on it itself, see [method point].
## A touch screen has no cursor to show.

const HAND := Control.CURSOR_POINTING_HAND
const ARROW := Control.CURSOR_ARROW


func _ready() -> void:
	get_tree().node_added.connect(_on_added)


## [param control] showing the hand while the mouse is [param over] something a click on it acts
## on, and the arrow while it is not: for what the game draws for itself, which knows where.
static func point(control: Control, over: bool) -> void:
	control.mouse_default_cursor_shape = HAND if over else ARROW


## Whether [param control] is one of the engine's own that a click acts on: a button of any kind,
## a slider, a scroll bar, a box stepped by its arrows, a row of tabs, or the items of the list a
## box drops, which is a control of the engine's without a name of its own to the game.
static func clicked(control: Control) -> bool:
	return (
		control is BaseButton
		or control is Slider
		or control is ScrollBar
		or control is SpinBox
		or control is TabBar
		or control.is_class("PopupMenuItems")
	)


func _on_added(node: Node) -> void:
	var control := node as Control
	if control == null or control.mouse_default_cursor_shape != ARROW or not clicked(control):
		return
	control.mouse_default_cursor_shape = HAND
	# Told again as it comes back into the tree, the arrow on it for a button that cannot be pressed.
	if control is BaseButton and not control.draw.is_connected(_follow):
		control.draw.connect(_follow.bind(control))
	elif control is TabBar and not control.gui_input.is_connected(_over_tab):
		control.gui_input.connect(_over_tab.bind(control))


## [param button] drawn again, as it is whenever it can be pressed or not any more: the hand while
## it can and the arrow while not, unless it was given a cursor of its own since.
func _follow(button: BaseButton) -> void:
	if button.mouse_default_cursor_shape in [HAND, ARROW]:
		point(button, not button.disabled)


## The mouse moved over [param bar]: the hand over a tab that can be picked, the arrow elsewhere.
func _over_tab(event: InputEvent, bar: TabBar) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null and bar.mouse_default_cursor_shape in [HAND, ARROW]:
		var tab := bar.get_tab_idx_at_point(motion.position)
		point(bar, tab >= 0 and not bar.is_tab_disabled(tab))
