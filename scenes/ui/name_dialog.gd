class_name NameDialog
extends Control
## A name asked for over the whole screen, GAME.md 8.5: a title, a box to type it in, and a button
## each for going ahead and for not, on the pane every panel in the game is cut from, over a shade.
## Enter in the box goes ahead and Back does not. Going ahead wants a name, so its button is off
## while the box is empty. While it is up the keys are the box's, not a kart's, and the screen
## under it hears nothing: no tab of the settings switches.

## The name typed, cleaned, once the player went ahead with it.
signal named(name: String)
## Up no longer, whichever way it went.
signal put_away

const CANCEL := "Cancel"
## How wide the box is.
const WIDE := 420.0

var field: LineEdit
var ok_button: Button
var cancel_button: Button

## The pane and the shade, for putting away, and whether it is on its way.
var _pane: PanelContainer
var _shade: ColorRect
var _closing := false


## Puts the question [param title] up over the whole screen [param from] is on, the box holding
## [param text], and [param ok] on the button that goes ahead.
static func open(from: Control, title: String, text: String, ok: String) -> NameDialog:
	var top: Control = from
	while top.get_parent() is Control:
		top = top.get_parent() as Control
	var dialog := NameDialog.new()
	dialog.name = "NameDialog"
	# Over the screen it is on; a page on its own has the window, under whatever holds it.
	(top if top != from else from.get_parent()).add_child(dialog)
	dialog._build(title, text, ok)
	return dialog


func _build(title: String, text: String, ok: String) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(middle)
	var pane := PanelContainer.new()
	pane.add_theme_stylebox_override("panel", MenuTheme.pane_style())
	middle.add_child(pane)
	MenuTheme.deal(pane)
	_pane = pane
	_shade = shade
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	pane.add_child(column)
	column.add_child(MenuTheme.title(title, Type.TITLE))
	column.add_child(MenuTheme.perforation())
	field = MenuTheme.field(text, PlayerNames.PLACEHOLDER, PlayerNames.MAX_LENGTH)
	field.custom_minimum_size.x = WIDE
	field.text_changed.connect(func(_typed: String) -> void: _say_ok())
	field.text_submitted.connect(func(_typed: String) -> void: _go_ahead())
	column.add_child(field)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	column.add_child(buttons)
	ok_button = MenuTheme.primary(MenuTheme.button(ok, Type.BODY))
	ok_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok_button.pressed.connect(_go_ahead)
	buttons.add_child(ok_button)
	cancel_button = MenuTheme.button(CANCEL, Type.BODY)
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_button.pressed.connect(close)
	buttons.add_child(cancel_button)
	_confine()
	_say_ok()
	PlayerInput.typing = true
	field.grab_focus.call_deferred()
	field.select_all.call_deferred()


## The cursor stays on the box and the two buttons, rather than walking off them onto the page
## under them.
func _confine() -> void:
	var order: Array[Control] = [field, ok_button, cancel_button]
	for i: int in order.size():
		var each := order[i]
		var here := each.get_path()
		each.focus_next = order[(i + 1) % order.size()].get_path()
		each.focus_previous = order[i - 1].get_path()
		each.focus_neighbor_left = here
		each.focus_neighbor_right = here
		each.focus_neighbor_top = here
		each.focus_neighbor_bottom = ok_button.get_path() if each == field else here
	ok_button.focus_neighbor_right = cancel_button.get_path()
	cancel_button.focus_neighbor_left = ok_button.get_path()
	ok_button.focus_neighbor_top = field.get_path()
	cancel_button.focus_neighbor_top = field.get_path()


func _say_ok() -> void:
	ok_button.disabled = PlayerNames.clean(field.text).is_empty()


func _go_ahead() -> void:
	var typed := PlayerNames.clean(field.text)
	if typed.is_empty():
		return
	close()
	named.emit(typed)


## Down, without a name: said at once, and gone the way it came, see [method MenuTheme.put_away].
func close() -> void:
	if is_queued_for_deletion() or _closing:
		return
	_closing = true
	PlayerInput.typing = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shades: Array[CanvasItem] = [_shade]
	MenuTheme.put_away(_pane, queue_free, shades)
	put_away.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
	elif event is InputEventKey or event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()
