class_name ConfirmPane
extends PanelContainer
## A question with two answers, GAME.md 3.8, on the pane every panel in the game is cut from: what
## is about to happen, with a road sign before it, 8.1a, then the perforation, a line saying more,
## and a button each for going ahead and for not. The sign is the yellow warning diamond when going
## ahead loses something, and the cursor starts on not, since the question is mostly asked before
## something that cannot be undone; the round blue sign marks one that is only a question.

## The player answered: [param yes] to go ahead.
signal answered(yes: bool)

## How wide the line under the question wraps at.
const WIDTH := 560.0

var _title: Label
var _sign: RoadSign
var _message: Label
var _yes: Button
var _no: Button


## What holds a question put over a whole screen, see [method over_screen]: Back answers no.
class Question:
	extends Control

	var pane: ConfirmPane

	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed(&"ui_cancel") and pane != null:
			get_viewport().set_input_as_handled()
			pane.answered.emit(false)


## A question put over the whole screen [param from] is on, shaded under it, in a [Question] named
## [param named], whose Back answers no: answered, it goes, [param answer] is told whether it was
## yes, once however often it was answered, and the cursor is back on [param from]. Returns the
## pane, for [method ask].
static func over_screen(from: Control, named: String, answer: Callable) -> ConfirmPane:
	var top: Control = from
	while top.get_parent() is Control:
		top = top.get_parent() as Control
	var holder := Question.new()
	holder.name = named
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_STOP
	top.add_child(holder)
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(shade)
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(middle)
	var pane := ConfirmPane.new()
	holder.pane = pane
	middle.add_child(pane)
	pane.answered.connect(
		func(yes: bool) -> void:
			if holder.is_queued_for_deletion():
				return
			holder.queue_free()
			answer.call(yes)
			if is_instance_valid(from) and from.is_inside_tree():
				from.grab_focus()
	)
	return pane


func _ready() -> void:
	add_theme_stylebox_override("panel", MenuTheme.pane_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	add_child(column)
	_title = MenuTheme.title("", Type.TITLE)
	var heading := MenuTheme.signed(_title, RoadSign.Kind.WARNING)
	_sign = heading.get_child(0) as RoadSign
	column.add_child(heading)
	column.add_child(MenuTheme.perforation())
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
	_confine()


func _notification(what: int) -> void:
	ScreenReader.dialog(self, what)


## The cursor stays on the two answers while the question is up, rather than walking off them
## onto whatever the question was asked over, the title's buttons say.
func _confine() -> void:
	for each: Button in [_yes, _no]:
		var other := _no if each == _yes else _yes
		var here := each.get_path()
		each.focus_neighbor_left = here
		each.focus_neighbor_right = here
		each.focus_neighbor_top = other.get_path()
		each.focus_neighbor_bottom = other.get_path()
		each.focus_next = other.get_path()
		each.focus_previous = other.get_path()


## Puts [param question] up, with [param message] under it, [param yes] on the button that goes
## ahead and [param no] on the one that does not, which has the cursor, and a sign of [param kind]
## before the question.
func ask(
	question: String, message: String, yes: String, no := "Stay", kind := RoadSign.Kind.WARNING
) -> void:
	_sign.kind = kind
	_title.text = question
	_message.text = message
	_yes.text = yes
	_no.text = no
	# Read as a dialog of the question as the cursor comes into it, see [ScreenReader].
	ScreenReader.name(self, question, message)
	visible = true
	MenuTheme.deal(self)
	_no.grab_focus()


## What the question says just now, for asking what was asked.
func said() -> String:
	return "%s %s" % [_title.text, _message.text]


func yes_button() -> Button:
	return _yes


func no_button() -> Button:
	return _no
