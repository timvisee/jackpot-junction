class_name TutorialHint
extends Node
## The tutorial's line over the kart, GAME.md 9.4a: the task being done, in a few words, with the
## control for it drawn in for the device in hand, a key, a pad button or the touch screen's
## button, the way the drive and fire line of 3.8 is drawn. A task done in steps that come round
## again, a drift say, is its steps instead, a line each with a tick box in front, a little
## smaller. Checked every quarter second against what it should say, so a pad picked up or a
## switch of driving mode shows at once.

const RECHECK := 0.25
const INK := Palette.CHIP_WHITE
const LATER_INK := Color(0.8, 0.8, 0.86)
const DONE_INK := Color(0.6, 0.6, 0.66)
## How much bigger than the drive and fire line of 3.8 it is drawn: a line that is missed teaches
## nothing. The steps, several lines, a little less so.
const SCALE := 1.5
const STEPS_SCALE := 1.15

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


## What the line says just now, for asking: the words, or "steps" for a task said in steps.
func words() -> String:
	return _shown.get_slice("|", 0)


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
	if not _task.steps.is_empty():
		_rebuild_steps(kart)
		return
	if _task.hint.is_empty():
		_drop()
		return
	var simple := _lesson.simple()
	var keyboard := DeviceInput.uses_keyboard(slot.device())
	var template := _task.hint_words(simple)
	var size := roundi(ScreenHint.drawn_size(get_tree() if is_inside_tree() else null) * SCALE)
	var wanted := (
		"%s|%s|%s|%d|%s"
		% [template, keyboard, simple, size, InputHint.stamp(_task.actions, keyboard)]
	)
	if wanted == _shown and _row != null and is_instance_valid(_row):
		return
	_shown = wanted
	var parts: Array = []
	if simple and _task.simple_way:
		parts.append(InputHint.way(keyboard, INK, size))
	elif _task.actions.size() >= 2:
		parts.append(InputHint.pair(_task.actions[0], _task.actions[1], keyboard, INK, size))
	elif _task.actions.size() == 1:
		parts.append(InputHint.glyph(_task.actions[0], keyboard, INK, size))
	_hang(kart, InputHint.row(template, parts, INK, size))


## The task's steps, a line each with a tick box: the ones done this time round ticked and
## grayed, the one to do bright, the rest a shade dimmer.
func _rebuild_steps(kart: Kart) -> void:
	var keyboard := DeviceInput.uses_keyboard(slot.device())
	var size := roundi(
		ScreenHint.drawn_size(get_tree() if is_inside_tree() else null) * STEPS_SCALE
	)
	var stamps: Array[String] = []
	for i: int in _task.steps.size():
		var actions: Array[StringName] = []
		if i < _task.step_actions.size():
			actions.assign(_task.step_actions[i])
		stamps.append(InputHint.stamp(actions, keyboard))
	var wanted := "steps|%d|%s|%d|%s" % [_task.steps_done, keyboard, size, "/".join(stamps)]
	if wanted == _shown and _row != null and is_instance_valid(_row):
		return
	_shown = wanted
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 4)
	for i: int in _task.steps.size():
		var done := i < _task.steps_done
		var ink := DONE_INK if done else (INK if i == _task.steps_done else LATER_INK)
		var line := HBoxContainer.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_theme_constant_override("separation", 8)
		var mark := TutorialList.Mark.new(size * 0.85)
		mark.done = done
		mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(mark)
		var parts: Array = []
		if i < _task.step_actions.size():
			for action: StringName in _task.step_actions[i]:
				parts.append(InputHint.glyph(action, keyboard, ink, size))
		line.add_child(InputHint.row(_task.steps[i], parts, ink, size))
		column.add_child(line)
	_hang(kart, column)


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
