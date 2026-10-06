class_name TutorialList
extends PanelContainer
## The tutorial's checklist, GAME.md 9.4a: in the top right corner, clear of the player's own
## corner on the left, the lesson's name and its tasks under it, one lesson at a time. A task done
## is ticked and grayed, the one being done is bright with a bar under it where it has one, and
## tasks not yet reached are not shown, so the list grows as the lesson goes; a lesson done in any
## order shows all of its tasks, its stations set apart by a line. A lesson done is stamped PASSED
## in place of its tasks for a second, under its name, and then the next lesson, or nothing until
## it starts. On a touch screen it hangs under the menu button.
##
## The examiner's clipboard, GAME.md 8.1a: a board covered in the table's green felt with a foil
## rim, a gold clip at its head riveted with a poker chip, and clipped to it a sheet of the
## school's cream paper, the form printed on it in ink and the tasks ticked off in red pen, the
## way an examiner marks a test.

const WIDTH := 300.0
## The ink on the sheet: for the task being done, one waiting, and one done.
const INK := HouseTheme.INK
const WAITING_INK := Color(HouseTheme.INK, 0.72)
const DONE_INK := Color(HouseTheme.INK, 0.42)
## The examiner's red pen the ticks and the bars are in.
const MARK := HouseTheme.STAMP_RED
const MARK_SIDE := 17.0
## What the form is headed, over the lesson's name, which says the rest.
const FORM := "DEPT. OF KARTS  ·  DRIVING TEST"
const HEADING := "%s"
## The board: its felt, how far it shows round the sheet, and the room over the sheet for the clip.
const BOARD := Color("#0f3d2b")
const BORDER := 8.0
const CLIP_ROOM := 16.0
## The sheet: how much room it leaves round the form.
const SHEET_ROOM := Vector2(14.0, 12.0)
## The clip: how wide its plate is and how tall, and how far over the board's head it stands.
const CLIP := Vector2(96.0, 24.0)
const CLIP_OVER := 7.0
## A lesson done is stamped PASSED with the driving test's rubber stamp, GAME.md 8.1a: in what
## green, how big, how far askew, and for how long, in seconds.
const DONE := Color(0.13, 0.55, 0.27)
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
## The sheet's textures, worked out for its size, and the board's.
var _sheet_kept := {}
var _board_kept := {}
var _rows: VBoxContainer
## The rows of the lesson's tasks, in order, each its row, its mark, its label and its bar.
var _tasks: Array = []
var _check: Mark
var _check_left := 0.0


## The tick box in front of a line, printed on the form: a box in ink, notched at its corners as
## the house's tickets are, GAME.md 8.1a, ticked in red pen once done, the tick running past the
## box the way a quick hand's does; or, for a lesson done, the driving test's rubber stamp saying
## PASSED, see [StampArt].
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
		var line := outline.duplicate()
		line.append(outline[0])
		draw_polyline(line, Color(HouseTheme.INK, 0.75), 1.3, true)
		if done:
			var check := PackedVector2Array(
				[
					Vector2(s * 0.18, s * 0.5),
					Vector2(s * 0.42, s * 0.78),
					Vector2(s * 1.02, s * 0.02)
				]
			)
			draw_polyline(check, ink, maxf(2.2, s * 0.13), true)


static func add_to(layer: CanvasLayer) -> TutorialList:
	var list := TutorialList.new()
	list.name = "TutorialList"
	layer.add_child(list)
	return list


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The board and the sheet are drawn here, see [method _draw]; the form stands on the sheet.
	var room := StyleBoxEmpty.new()
	room.content_margin_left = BORDER + SHEET_ROOM.x
	room.content_margin_right = BORDER + SHEET_ROOM.x
	room.content_margin_top = CLIP_ROOM + SHEET_ROOM.y + 4.0
	room.content_margin_bottom = BORDER + SHEET_ROOM.y
	add_theme_stylebox_override("panel", room)
	custom_minimum_size = Vector2(WIDTH, 0.0)
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	offset_left = -16.0
	offset_right = -16.0
	# Clear of the top edge by the height of the clip standing over the board.
	var top := (TouchControls.below_menu() if TouchInput.enabled else 16.0) + CLIP_OVER
	offset_top = top
	offset_bottom = top
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	var form := Label.new()
	form.text = FORM
	form.mouse_filter = Control.MOUSE_FILTER_IGNORE
	form.add_theme_font_override("font", Type.micro_font())
	form.add_theme_font_size_override("font_size", 10)
	form.add_theme_color_override("font_color", Color(HouseTheme.INK, 0.55))
	column.add_child(form)
	_title = Label.new()
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Type.strong(_title, Type.BODY, INK)
	column.add_child(_title)
	var rule := ColorRect.new()
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.color = Color(HouseTheme.INK, 0.6)
	rule.custom_minimum_size = Vector2(0.0, 1.5)
	column.add_child(rule)
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
				var bar := HudBlock.bar(Vector2(WIDTH - 70.0, 8.0), MARK) as NitroCells
				bar.empty = Color(HouseTheme.INK, 0.12)
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
		var words := Terms.bbcode(task.label(simple), not task.done, true)
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
	rule.color = Color(HouseTheme.INK, 0.25)
	rule.custom_minimum_size = Vector2(0.0, 1.0)
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
	label.text = Terms.bbcode(text, true, true)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("bold_font", Type.STRONG)
	label.add_theme_font_size_override("normal_font_size", Type.LABEL)
	label.add_theme_font_size_override("bold_font_size", Type.LABEL)
	label.add_theme_color_override("default_color", INK)
	row.add_child(label)
	return {"row": row, "mark": mark, "label": label}


## The clipboard under the form: the felt board with its foil rim, the sheet clipped to it, and the
## clip over the sheet's head. The board and the sheet before the form, which is drawn over them.
func _draw() -> void:
	var whole := Rect2(Vector2.ZERO, size)
	var board := TicketStyle.outline(size, 10.0)
	var shade := StyleBoxFlat.new()
	shade.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	shade.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	shade.shadow_size = 12
	shade.shadow_offset = Vector2(0.0, 4.0)
	shade.set_corner_radius_all(8)
	draw_style_box(shade, whole.grow(-4.0))
	draw_colored_polygon(board, BOARD)
	Surface.draw(get_canvas_item(), _board_kept, board, size, Surface.Kind.FELT, 0.22)
	var rim := board.duplicate()
	rim.append(board[0])
	draw_polyline(rim, Color(HouseTheme.FOIL, 0.75), 1.5, true)
	var inner := TicketStyle.outline(size - Vector2.ONE * 8.0, 7.0)
	for i: int in inner.size():
		inner[i] += Vector2.ONE * 4.0
	inner.append(inner[0])
	draw_polyline(inner, Color(HouseTheme.FOIL, 0.22), 1.0, true)
	# The sheet, a hair askew of nothing: square, with its shadow on the felt.
	var sheet := Rect2(
		Vector2(BORDER, CLIP_ROOM), Vector2(size.x - BORDER * 2.0, size.y - CLIP_ROOM - BORDER)
	)
	draw_rect(Rect2(sheet.position + Vector2(1.5, 2.5), sheet.size), Color(0.0, 0.0, 0.0, 0.35))
	draw_rect(sheet, HouseTheme.PAPER)
	var paper := PackedVector2Array(
		[
			sheet.position,
			Vector2(sheet.end.x, sheet.position.y),
			sheet.end,
			Vector2(sheet.position.x, sheet.end.y)
		]
	)
	var finish := Surface.finish("slip")
	draw_set_transform(sheet.position)
	var local := PackedVector2Array()
	for point: Vector2 in paper:
		local.append(point - sheet.position)
	Surface.draw(
		get_canvas_item(),
		_sheet_kept,
		local,
		sheet.size,
		finish[0] as Surface.Kind,
		float(finish[1])
	)
	draw_set_transform(Vector2.ZERO)
	_draw_clip(Vector2(size.x * 0.5, CLIP_ROOM))


## The clip at the head of the sheet, round [param at], the middle of the sheet's top edge: a gold
## plate over the sheet with a lever over the board, and a poker chip for its rivet.
func _draw_clip(at: Vector2) -> void:
	var plate := Rect2(at + Vector2(-CLIP.x * 0.5, -CLIP.y * 0.45), Vector2(CLIP.x, CLIP.y))
	var lever := Rect2(
		Vector2(at.x - CLIP.x * 0.32, -CLIP_OVER),
		Vector2(CLIP.x * 0.64, plate.position.y + CLIP_OVER + 6.0)
	)
	for part: Array in [[lever, HouseTheme.FOIL_LOW, 5], [plate, HouseTheme.FOIL, 7]]:
		var look := StyleBoxFlat.new()
		look.bg_color = part[1]
		look.set_corner_radius_all(int(part[2]))
		look.set_border_width_all(1)
		look.border_color = Color(HouseTheme.ON_FOIL, 0.55)
		look.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
		look.shadow_size = 3
		look.shadow_offset = Vector2(0.0, 2.0)
		look.anti_aliasing = true
		draw_style_box(look, part[0])
	# The plate catches the light along its top, and the lever has a hole to hang it by.
	var shine := Rect2(plate.position + Vector2(6.0, 3.0), Vector2(plate.size.x - 12.0, 3.0))
	draw_rect(shine, Color(HouseTheme.FOIL_HIGH, 0.8))
	draw_circle(
		Vector2(at.x, lever.position.y + 6.0), 3.2, Color(HouseTheme.ON_FOIL, 0.8), true, -1.0, true
	)
	ChipArt.chip(self, plate.get_center() + Vector2(0.0, 1.0), CLIP.y * 0.36, Palette.CHIP_RED)
