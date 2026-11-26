class_name BaySchool
extends Node
## The learner's way from the kart dialog to the driving school, GAME.md 4.4a: the plate's hook,
## waiting for a license while the kart wears the learner's L, see
## [method PartHook.wait_for_license], pressed asks over the bay whether to earn one now, Earn it
## now going to the school, 9.4a, out of whatever room the dialog was opened over, as the License
## tab's does. For a profile nobody here is playing as, whose license the school would not earn, it
## only says how one is had. Kept out of [KartDialog] as [BayNew] is.

## What it asks, and the line under it: out of a room, in one, where going leaves it, and for a
## profile nobody is playing as, by its name.
const QUESTION := "Missing license"
const LINE := (
	"Your kart wears the learner's L until you pass the driving test."
	+ " Earn your license for a plate of your own."
)
const LINE_ROOM := LINE + " This leaves the room."
const LINE_OTHER := "%s has no license yet. Play as %s and pass the driving test to earn one."
const EARN := "Earn it now"
const NOT_NOW := "Not now"
const OK := "OK"

var dialog: KartDialog
## The question up over the bay, or null.
var question: ConfirmPane
## Where Earn it now goes once out of any room: the driving school. A test puts something else here.
var to_school := Game.go_to_tutorial

## What the question is laid over, the bay shaded behind it, while it is up.
var _holder: Control
## The hook that asked, which has the cursor back once the question is put away.
var _from: Control


## The way to the school of [param on].
static func add_to(on: KartDialog) -> BaySchool:
	var made := BaySchool.new()
	made.name = "BaySchool"
	made.dialog = on
	on.add_child(made)
	return made


## Whether the question is up, for the dialog's keys to leave it be.
func is_asking() -> bool:
	return question != null


## Asks over the bay, for [param hook] pressed: whether to earn the license now, the cursor on Earn
## it now, as the title's question has it, but in a room, which going leaves, on Not now under the
## warning sign; for a profile nobody is playing as, only how one is had.
func ask(hook: Control) -> void:
	if question != null:
		return
	_from = hook
	_holder = Control.new()
	_holder.name = "LicenseQuestion"
	_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_holder.mouse_filter = Control.MOUSE_FILTER_STOP
	dialog._root.add_child(_holder)
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_holder.add_child(shade)
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_holder.add_child(middle)
	question = ConfirmPane.new()
	question.name = "Question"
	middle.add_child(question)
	question.answered.connect(_on_answered)
	var owner_now := dialog.kart_owner()
	if owner_now.profile != Game.settings.profile:
		var named := owner_now.display_name()
		question.ask(QUESTION, LINE_OTHER % [named, named], "", OK, RoadSign.Kind.QUESTION)
		question.yes_button().visible = false
	elif dialog._room != null:
		question.ask(QUESTION, LINE_ROOM, EARN, NOT_NOW)
	else:
		question.ask(QUESTION, LINE, EARN, NOT_NOW, RoadSign.Kind.QUESTION)
		question.yes_button().grab_focus()
	Audio.play_sfx(&"ui_click", -6.0, 0.05)


## Puts the question away, as Not now does, for Back pressed while it is up.
func put_away() -> void:
	if question != null:
		MenuTheme.back_sound()
		_on_answered(false)


func _on_answered(yes: bool) -> void:
	_holder.queue_free()
	_holder = null
	question = null
	if yes:
		Net.close()
		to_school.call()
	elif is_instance_valid(_from) and _from.is_inside_tree():
		_from.grab_focus()
