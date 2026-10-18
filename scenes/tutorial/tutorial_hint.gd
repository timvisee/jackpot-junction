class_name TutorialHint
extends Node
## The tutorial's mark over the kart, GAME.md 9.4a: the control for the task being done and
## nothing else, drawn for the device in hand, a key, a pad button or the touch screen's button,
## the way the drive and fire line of 3.8 draws it; the words are the clipboard's. A task done in
## steps that come round again, a drift say, shows the control of the step it is on. Checked every
## quarter second against what it should show, so a pad picked up or a switch of driving mode
## shows at once.

const RECHECK := 0.25
const INK := Palette.CHIP_WHITE
## How much bigger than the drive and fire line of 3.8 it is drawn: a control that is missed teaches
## nothing.
const SCALE := 1.5

var slot: PlayerSlot

var _task: TutorialTask
var _lesson: TutorialLesson
var _row: ScreenHint
var _shown := ""
var _recheck := 0.0


## Says [param task] of [param lesson], or nothing for null.
func show_task(task: TutorialTask, lesson: TutorialLesson) -> void:
	_task = task
	_lesson = lesson
	_rebuild()


func clear() -> void:
	show_task(null, null)


## What the mark shows just now, for asking: whether it shows simple driving's way, its size and
## the controls drawn, as [method InputHint.stamp] has them; or nothing.
func shows() -> String:
	return _shown if _row != null and is_instance_valid(_row) else ""


func _process(delta: float) -> void:
	_recheck -= delta
	if _recheck <= 0.0:
		_recheck = RECHECK
		_rebuild()


func _rebuild() -> void:
	var kart := slot.kart if slot != null else null
	if _task == null or kart == null or not is_instance_valid(kart):
		_drop()
		return
	var simple := _lesson.simple()
	var actions := _task.actions
	if not _task.steps.is_empty():
		actions = []
		if _task.steps_done < _task.step_actions.size():
			actions.assign(_task.step_actions[_task.steps_done])
	var way := simple and _task.simple_way
	if actions.is_empty() and not way:
		_drop()
		return
	var keyboard := DeviceInput.uses_keyboard(slot.device())
	var size := roundi(ScreenHint.drawn_size(get_tree() if is_inside_tree() else null) * SCALE)
	var wanted := "%s|%d|%s" % [way, size, InputHint.stamp(actions, keyboard)]
	if wanted == _shown and _row != null and is_instance_valid(_row):
		return
	_shown = wanted
	var glyph: Control = null
	if way:
		glyph = InputHint.way(keyboard, INK, size)
	elif actions.size() >= 2:
		glyph = InputHint.pair(actions[0], actions[1], keyboard, INK, size)
	else:
		glyph = InputHint.glyph(actions[0], keyboard, INK, size)
	if glyph == null:
		_drop()
		return
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(glyph)
	_hang(kart, row)


## [param content] over [param kart]: the same sprite redrawn, rather than a new one for every
## task.
func _hang(kart: Kart, content: Control) -> void:
	if _row != null and is_instance_valid(_row) and _row.get_parent() == kart:
		_row.replace(content)
	else:
		_drop()
		_row = ScreenHint.hang(kart, content, "TutorialHint")


func _drop() -> void:
	if _row != null and is_instance_valid(_row):
		_row.queue_free()
	_row = null
	_shown = ""
