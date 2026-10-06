class_name TutorialList
extends PanelContainer
## The tutorial's checklist, GAME.md 9.4a: in the top right corner, clear of the player's own
## corner on the left, the lesson's name and its tasks under it, one lesson at a time. A task done
## is ticked and grayed, the one being done is bright with a bar under it where it has one, and
## tasks not yet reached are not shown, so the list grows as the lesson goes; a lesson done in any
## order shows all of its tasks, its stations set apart by a line. A lesson done is a big green
## check in place of its tasks for a second, under its name, and then the next lesson, or nothing
## until it starts. On a touch screen it hangs under the menu button.

const WIDTH := 300.0
const INK := Color(0.97, 0.97, 1.0)
const WAITING_INK := Color(0.8, 0.8, 0.86)
const DONE_INK := Color(0.55, 0.55, 0.6)
const MARK := Palette.CHIP_GOLD
const MARK_SIDE := 18.0
## What the panel is headed, before the lesson's name.
const HEADING := "Driving test  ·  %s"
## A lesson done is stamped PASSED with the driving test's rubber stamp, GAME.md 8.1a: in what
## green, how big, how far askew, and for how long, in seconds.
const DONE := Color(0.36, 0.9, 0.46)
const CHECK_SIDE := 72.0
const CHECK_FOR := 1.0
const PASSED := "PASSED"
const STAMP_TURN := -0.2
## The notch of a tick box's corners.
const NOTCH := 4.0

## The lesson shown, and the one waiting for the check to clear.
var _lesson: TutorialLesson
var _pending: TutorialLesson
var _title: Label
var _rows: VBoxContainer
## The rows of the lesson's tasks, in order, each its row, its mark, its label and its bar.
var _tasks: Array = []
var _check: Mark
var _check_left := 0.0


## The tick box in front of a line, drawn as the house's tickets are, GAME.md 8.1a: notched at
## its corners with a foil hairline, and once done filled with foil and checked in ink; or, for a
## lesson done, the driving test's rubber stamp saying PASSED, see [StampArt].
class Mark:
	extends Control

	var done := false:
		set(value):
			done = value
			queue_redraw()
	var side := MARK_SIDE
	var ink := MARK
	var boxed := true

	func _init(of_side := MARK_SIDE, in_ink := MARK, with_box := true) -> void:
		side = of_side
		ink = in_ink
		boxed = with_box
		custom_minimum_size = Vector2(side, side)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var s := side
		if not boxed:
			if done:
				var day := LicenseCard.today()
				StampArt.stamp(
					self, size * 0.5, s * 0.5, PASSED, "DEPT. OF KARTS", day, STAMP_TURN, ink
				)
			return
		var outline := TicketStyle.outline(
			Vector2(s, s) - Vector2.ONE * 2.0, NOTCH, PackedFloat32Array(), 0.0, true, false
		)
		for i: int in outline.size():
			outline[i] += Vector2.ONE
		draw_colored_polygon(outline, ink if done else Color(0.0, 0.0, 0.0, 0.4))
		var line := outline.duplicate()
		line.append(outline[0])
		draw_polyline(line, ink if done else DONE_INK, 1.5, true)
		if done:
			var check := PackedVector2Array(
				[
					Vector2(s * 0.24, s * 0.52),
					Vector2(s * 0.43, s * 0.72),
					Vector2(s * 0.78, s * 0.3)
				]
			)
			draw_polyline(check, HouseTheme.ON_FOIL, maxf(2.4, s * 0.12), true)


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
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	_title = Label.new()
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Type.strong(_title, Type.BODY, INK)
	HudText.shadowed(_title)
	column.add_child(_title)
	_rows = VBoxContainer.new()
	_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rows.add_theme_constant_override("separation", 5)
	column.add_child(_rows)
	var middle := CenterContainer.new()
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	middle.custom_minimum_size = Vector2(0.0, CHECK_SIDE + 8.0)
	_check = Mark.new(CHECK_SIDE, DONE, false)
	_check.done = true
	middle.add_child(_check)
	middle.visible = false
	column.add_child(middle)
	visible = false


## Puts [param lesson] up, its name and nothing under it yet, once the check of the lesson before
## has had its second.
func start_lesson(lesson: TutorialLesson) -> void:
	if _check_left > 0.0:
		_pending = lesson
		return
	_show(lesson)


## Brings the rows of [param lesson] up to date: every task up to the one being done, with the bar
## of the one being done where it has one, and a line between the stations of a lesson done in
## any order.
func refresh(lesson: TutorialLesson) -> void:
	if lesson != _lesson or _check_left > 0.0:
		return
	var simple := lesson.simple()
	var now := lesson.current()
	var shown := 0
	for task: TutorialTask in lesson.shown():
		if shown >= _tasks.size():
			if shown > 0 and _starts_station(lesson, task):
				_rows.add_child(_rule())
			var row := _line(task.label(simple))
			_rows.add_child(row["row"])
			if task.bar:
				var bar := HudBlock.bar(Vector2(WIDTH - 60.0, 8.0), MARK)
				bar.value = 0.0
				_rows.add_child(bar)
				row["bar"] = bar
			_tasks.append(row)
		var line: Dictionary = _tasks[shown]
		(line["mark"] as Mark).done = task.done
		var label: RichTextLabel = line["label"]
		# The one being done is bright, and in any order, or under a goal, the others wait a
		# shade dimmer. The game's own words in it are in their colors while it is to be done,
		# see [Terms], and dimmed with the rest once it is.
		var waits := not lesson.ordered or lesson.show_all
		var ink := WAITING_INK if waits and task != now else INK
		var words := Terms.bbcode(task.label(simple), not task.done)
		if label.text != words:
			label.text = words
		label.add_theme_color_override("default_color", DONE_INK if task.done else ink)
		if line.has("bar"):
			var bar: Range = line["bar"]
			bar.visible = not task.done
			bar.value = task.progress * 100.0
		shown += 1


## [param lesson] is done: a big green check in place of its tasks, under its name, for a second.
func finish_lesson(lesson: TutorialLesson) -> void:
	if lesson != _lesson:
		return
	_check_left = CHECK_FOR
	_rows.visible = false
	_check.get_parent().visible = true
	visible = true


## Whether a lesson's name is up just now: one, or none between lessons.
func listed() -> int:
	return 1 if visible and _lesson != null else 0


## Whether the check of a lesson done is up.
func is_checking() -> bool:
	return _check_left > 0.0


## The rows of [param lesson]'s tasks, for asking what the list says.
func task_rows(lesson: TutorialLesson) -> Array:
	return _tasks if lesson == _lesson else []


func _process(delta: float) -> void:
	if _check_left <= 0.0:
		return
	_check_left -= delta
	if _check_left > 0.0:
		return
	_check.get_parent().visible = false
	if _pending != null:
		_show(_pending)
		_pending = null
	else:
		visible = false


func _show(lesson: TutorialLesson) -> void:
	_lesson = lesson
	for row: Node in _rows.get_children():
		row.queue_free()
	_tasks.clear()
	_title.text = HEADING % lesson.title
	_title.visible = true
	_rows.visible = true
	_check.get_parent().visible = false
	visible = true


## Whether [param task] is the first of one of [param lesson]'s stations.
func _starts_station(lesson: TutorialLesson, task: TutorialTask) -> bool:
	for station: Array in lesson.stations:
		if not station.is_empty() and station[0] == task:
			return true
	return false


## The line between two stations: a short rule in the marks' own cyan, with room round it.
func _rule() -> Control:
	var room := MarginContainer.new()
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room.add_theme_constant_override("margin_top", 7)
	room.add_theme_constant_override("margin_bottom", 7)
	room.add_theme_constant_override("margin_left", 14)
	room.add_theme_constant_override("margin_right", 14)
	var rule := ColorRect.new()
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.color = Color(MARK, 0.35)
	rule.custom_minimum_size = Vector2(0.0, 2.0)
	room.add_child(rule)
	return room


## One line: a tick box and the words.
func _line(text: String) -> Dictionary:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	var mark := Mark.new()
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(mark)
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.text = Terms.bbcode(text)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("bold_font", Type.STRONG)
	label.add_theme_font_size_override("normal_font_size", Type.LABEL)
	label.add_theme_font_size_override("bold_font_size", Type.LABEL)
	label.add_theme_color_override("default_color", INK)
	label.add_theme_color_override("font_shadow_color", HudText.SHADOW)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	row.add_child(label)
	return {"row": row, "mark": mark, "label": label}
