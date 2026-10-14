class_name PageBinds
extends HBoxContainer
## The page keys beside a row of tabs, GAME.md 8.5, as [method DialogBinds.pages] draws them, kept
## to whatever is in hand: Q and E while keys are, a pad's shoulders otherwise while a gamepad is
## plugged in, and none for the mouse alone or on a touch screen.

## What they are drawn for now, "keys" or "pad", or nothing while they are not drawn.
var drawn_for := ""

var _keyboard := true
var _pointer := false


func _ready() -> void:
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_keyboard = Game.last_input_keyboard
	_pointer = Game.last_input_pointer
	Input.joy_connection_changed.connect(_on_pad_plugged)
	_show()


func _exit_tree() -> void:
	if Input.joy_connection_changed.is_connected(_on_pad_plugged):
		Input.joy_connection_changed.disconnect(_on_pad_plugged)


func _input(event: InputEvent) -> void:
	var keyboard := LicenseView.keyboard_after(event, _keyboard)
	var pointer := ButtonBinds.pointer_after(event, _pointer)
	if keyboard != _keyboard or pointer != _pointer:
		_keyboard = keyboard
		_pointer = pointer
		_show()


func _on_pad_plugged(_device: int, _connected: bool) -> void:
	_show()


func _show() -> void:
	var keys := _keyboard and not _pointer
	var wanted := "keys" if keys else ("pad" if SettingsScreen.pad_plugged_in() else "")
	if TouchInput.enabled:
		wanted = ""
	visible = not wanted.is_empty()
	if wanted.is_empty() or wanted == drawn_for:
		return
	drawn_for = wanted
	for child: Node in get_children():
		(child as Control).hide()
		child.queue_free()
	add_child(DialogBinds.pages(keys, SettingsScreen.TAB_HINT_INK, SettingsScreen.TAB_HINT_SIZE))
