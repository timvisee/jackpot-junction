class_name ConfirmPane
extends PanelContainer
## A question with two answers, GAME.md 3.8, on the pane every panel in the game is cut from: what
## is about to happen, in a line under it, and a button each for going ahead and for not. The
## cursor starts on not, since the question is only asked before something that cannot be undone.

## The player answered: [param yes] to go ahead.
signal answered(yes: bool)

## How wide the line under the question wraps at.
const WIDTH := 560.0

var _title: Label
var _message: Label
var _yes: Button
var _no: Button


func _ready() -> void:
	add_theme_stylebox_override("panel", MenuTheme.pane_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	add_child(column)
	_title = MenuTheme.title("", Type.TITLE)
	column.add_child(_title)
	_message = MenuTheme.subtitle("", Type.BODY)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.custom_minimum_size = Vector2(WIDTH, 0.0)
	column.add_child(_message)
	_yes = MenuTheme.button("")
	_yes.pressed.connect(func() -> void: answered.emit(true))
	column.add_child(_yes)
	_no = MenuTheme.button("")
	_no.pressed.connect(func() -> void: answered.emit(false))
	column.add_child(_no)


## Puts [param question] up, with [param message] under it, [param yes] on the button that goes
## ahead and [param no] on the one that does not, which has the cursor.
func ask(question: String, message: String, yes: String, no := "Stay") -> void:
	_title.text = question
	_message.text = message
	_yes.text = yes
	_no.text = no
	visible = true
	_no.grab_focus()


## What the question says just now, for asking what was asked.
func said() -> String:
	return "%s %s" % [_title.text, _message.text]


func yes_button() -> Button:
	return _yes


func no_button() -> Button:
	return _no
