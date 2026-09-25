class_name PasswordPane
extends CanvasLayer
## The host's lobby wants a password, GAME.md 9.6, and asks for it here: over the room, on the
## loading screen's dark, since there is no room yet to stand over. A box to type it into, Join to
## knock again with it, and Back to the title. Asked again, it says the last one was wrong.

## Join, with what was typed.
signal entered(password: String)

const WIDTH := 520.0

var _box: LineEdit
var _join: Button


## A pane over [param parent], asking for the password, [param wrong] if the last one was not it.
static func add_to(parent: Node, wrong := false) -> PasswordPane:
	var pane := PasswordPane.new()
	pane.name = "Password"
	pane.layer = StatusPane.LAYER
	parent.add_child(pane)
	pane._build(wrong)
	return pane


func _build(wrong: bool) -> void:
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
	var line := MenuTheme.subtitle(
		"Wrong password, try again." if wrong else "This game needs a password.", Type.BODY
	)
	column.add_child(line)
	_box = MenuTheme.field("", "Password", 64)
	_box.secret = true
	_box.custom_minimum_size = Vector2(WIDTH, 48.0)
	_box.text_submitted.connect(func(_typed: String) -> void: _knock())
	column.add_child(_box)
	_join = MenuTheme.button("Join")
	_join.pressed.connect(_knock)
	column.add_child(_join)
	var back := MenuTheme.button("Back to title")
	back.pressed.connect(func() -> void: Game.go_to_title())
	column.add_child(back)
	_box.grab_focus()


func _knock() -> void:
	entered.emit(_box.text)
