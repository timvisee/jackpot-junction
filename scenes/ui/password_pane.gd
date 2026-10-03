class_name PasswordPane
extends CanvasLayer
## The host's lobby wants a password, GAME.md 9.6, and asks for it here: over the room, on the
## loading screen's dark, since there is no room yet to stand over. A box to type it into, Join to
## knock again with it, and Back, or B, to give up on it and go back to LAN games.

## Join, with what was typed.
signal entered(password: String)
## Back: not this game after all.
signal left

const WIDTH := 520.0

var _box: LineEdit
var _join: Button
var _back: Button


## A pane over [param parent], asking for the password.
static func add_to(parent: Node) -> PasswordPane:
	var pane := PasswordPane.new()
	pane.name = "Password"
	pane.layer = StatusPane.LAYER
	parent.add_child(pane)
	pane._build()
	return pane


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = LoadingScreen.BACKDROP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(middle)
	var pane := MenuTheme.pane()
	middle.add_child(pane)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	pane.add_child(column)
	column.add_child(MenuTheme.title("Password", Type.TITLE))
	column.add_child(MenuTheme.subtitle("This game needs a password.", Type.BODY))
	_box = MenuTheme.field("", "Password", NetDoor.PASSWORD_LENGTH)
	_box.secret = true
	_box.custom_minimum_size = Vector2(WIDTH, 48.0)
	_box.text_submitted.connect(func(_typed: String) -> void: _knock())
	column.add_child(_box)
	_join = MenuTheme.button("Join")
	_join.pressed.connect(_knock)
	column.add_child(_join)
	_back = MenuTheme.button("Back")
	_back.pressed.connect(func() -> void: left.emit())
	column.add_child(_back)
	_box.grab_focus()


func _knock() -> void:
	entered.emit(_box.text)


## B on a pad, or Escape, is Back, caught before the room's pause menu hears it.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		left.emit()
