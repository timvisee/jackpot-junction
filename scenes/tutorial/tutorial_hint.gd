class_name TutorialHint
extends Node
## The tutorial's line over the kart, GAME.md 9.4a: the task being done, in a few words, with the
## control for it drawn in for the device in hand, a key, a pad button or the touch screen's
## button, the way the drive and fire line of 3.8 is drawn. Checked every quarter second against
## what it should say, so a pad picked up or a switch of driving mode shows at once.

const RECHECK := 0.25
const INK := Palette.CHIP_WHITE
## How much bigger than the drive and fire line of 3.8 it is drawn: a line that is missed teaches
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


## What the line says just now, for asking.
func words() -> String:
	return _shown.get_slice("|", 0)


func _process(delta: float) -> void:
	_recheck -= delta
	if _recheck <= 0.0:
		_recheck = RECHECK
		_rebuild()


func _rebuild() -> void:
	var kart := slot.kart if slot != null else null
	if _task == null or kart == null or not is_instance_valid(kart) or _task.hint.is_empty():
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
	var row := InputHint.row(template, parts, INK, size)
	# The same sprite over the kart, redrawn, rather than a new one for every task.
	if _row != null and is_instance_valid(_row) and _row.get_parent() == kart:
		_row.replace(row)
	else:
		_drop()
		_row = ScreenHint.hang(kart, row, "TutorialHint")


func _drop() -> void:
	if _row != null and is_instance_valid(_row):
		_row.queue_free()
	_row = null
	_shown = ""
