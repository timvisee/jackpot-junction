class_name TutorialList
extends PanelContainer
## The tutorial's checklist, GAME.md 9.4a: in the top right corner, clear of the player's own
## corner on the left, the lesson's name and its tasks under it. A task done is ticked and grayed,
## the one being done is bright with a bar under it where it has one, and tasks not yet reached
## are not shown, so the list grows as the lesson goes. A finished lesson shrinks to one ticked
## line, and only the last few lessons stay listed. On a touch screen it hangs under the menu
## button.

## How many lessons stay listed, done ones included.
const KEEP := 3
const WIDTH := 300.0
const INK := Color(0.97, 0.97, 1.0)
const WAITING_INK := Color(0.8, 0.8, 0.86)
const DONE_INK := Color(0.55, 0.55, 0.6)
const MARK := Palette.NEON_CYAN
const MARK_SIDE := 18.0

## The lessons listed, oldest first: each its lesson, its rows and the box they are in.
var _listed: Array[Dictionary] = []
var _column: VBoxContainer


## The tick box in front of a line, drawn: a square, and a check in it once done.
class Mark:
	extends Control

	var done := false:
		set(value):
			done = value
			queue_redraw()

	func _init() -> void:
		custom_minimum_size = Vector2(MARK_SIDE, MARK_SIDE)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var box := Rect2(Vector2(1.0, 1.0), Vector2(MARK_SIDE - 2.0, MARK_SIDE - 2.0))
		draw_rect(box, Color(0.0, 0.0, 0.0, 0.4))
		draw_rect(box, MARK if done else DONE_INK, false, 2.0)
		if done:
			var s := MARK_SIDE
			var check := PackedVector2Array(
				[
					Vector2(s * 0.22, s * 0.52),
					Vector2(s * 0.43, s * 0.74),
					Vector2(s * 0.8, s * 0.28)
				]
			)
			draw_polyline(check, MARK, 2.6, true)


static func add_to(layer: CanvasLayer) -> TutorialList:
	var list := TutorialList.new()
	list.name = "TutorialList"
	layer.add_child(list)
	return list


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", HudBlock.scrim())
	custom_minimum_size = Vector2(WIDTH, 0.0)
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	offset_left = -16.0
	offset_right = -16.0
	var top := TouchControls.below_menu() if TouchInput.enabled else 16.0
	offset_top = top
	offset_bottom = top
	_column = VBoxContainer.new()
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_theme_constant_override("separation", 10)
	add_child(_column)


## Puts [param lesson] up, its name and nothing under it yet, dropping the oldest listed lesson
## once there are more than [constant KEEP].
func start_lesson(lesson: TutorialLesson) -> void:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 6)
	_column.add_child(box)
	var head := _line(lesson.title, true)
	box.add_child(head["row"])
	var rows := VBoxContainer.new()
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_theme_constant_override("separation", 5)
	box.add_child(rows)
	_listed.append({"lesson": lesson, "box": box, "head": head, "rows": rows, "tasks": []})
	while _listed.size() > KEEP:
		var oldest: Dictionary = _listed.pop_front()
		(oldest["box"] as Control).queue_free()


## Brings the rows of [param lesson] up to date: every task up to the one being done, with the
## bar of the one being done where it has one.
func refresh(lesson: TutorialLesson) -> void:
	var entry := _entry(lesson)
	if entry.is_empty():
		return
	var simple := lesson.simple()
	var rows: Array = entry["tasks"]
	var now := lesson.current()
	var shown := 0
	for task: TutorialTask in lesson.shown():
		if shown >= rows.size():
			var row := _line(task.label(simple), false)
			(entry["rows"] as VBoxContainer).add_child(row["row"])
			if task.bar:
				var bar := HudBlock.bar(Vector2(WIDTH - 60.0, 8.0), MARK)
				bar.value = 0.0
				(entry["rows"] as VBoxContainer).add_child(bar)
				row["bar"] = bar
			rows.append(row)
		var line: Dictionary = rows[shown]
		# Lit for a moment for each one of a count, as well as for good once it is done.
		(line["mark"] as Mark).done = task.done or task.just_ticked()
		var label: Label = line["label"]
		label.text = task.label(simple)
		# The one being done is bright, and in any order the others wait a shade dimmer.
		var ink := INK if task == now or lesson.ordered else WAITING_INK
		Type.ink(label, DONE_INK if task.done else ink)
		if line.has("bar"):
			var bar: ProgressBar = line["bar"]
			bar.visible = not task.done
			bar.value = task.progress * 100.0
		shown += 1


## [param lesson] is done: one ticked line, its tasks folded away under it.
func finish_lesson(lesson: TutorialLesson) -> void:
	var entry := _entry(lesson)
	if entry.is_empty():
		return
	((entry["head"] as Dictionary)["mark"] as Mark).done = true
	Type.ink((entry["head"] as Dictionary)["label"], DONE_INK)
	(entry["rows"] as Control).visible = false


## How many lessons are listed just now.
func listed() -> int:
	return _listed.size()


## The rows of [param lesson]'s tasks, for asking what the list says.
func task_rows(lesson: TutorialLesson) -> Array:
	var entry := _entry(lesson)
	return entry["tasks"] if not entry.is_empty() else []


func _entry(lesson: TutorialLesson) -> Dictionary:
	for entry: Dictionary in _listed:
		if entry["lesson"] == lesson:
			return entry
	return {}


## One line: a tick box and the words, the lesson's name heavier than its tasks.
func _line(text: String, heading: bool) -> Dictionary:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	var mark := Mark.new()
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(mark)
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if heading:
		Type.strong(label, Type.BODY, INK)
	else:
		Type.text(label, Type.LABEL, INK)
	HudText.shadowed(label)
	row.add_child(label)
	return {"row": row, "mark": mark, "label": label}
