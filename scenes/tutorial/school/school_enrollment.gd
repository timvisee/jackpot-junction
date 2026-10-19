class_name SchoolEnrollment
extends Control
## The driving school's first page, GAME.md 9.4a: the game's mark and name with DRIVING SCHOOL
## under them, a line on why anybody is here, the box for the name that goes on the license, the
## course in three steps, and one big button, Enroll, with the Department's terms under it, and,
## while the story is told, a box over the button that ticks itself, STORY.md 6.7. It opens the way
## the title does, see [TitleIntro]: the mark large in the middle, up into its place, then the name
## and the pane rising in one after another, and any press goes to the end of it. The name box
## starts with the first seat's name, or with one off the funny list for a seat that never gave
## one, so there is always a name to enroll under; Enter in the box enrolls too.

## The player enrolled, under [param holder_name].
signal enrolled(holder_name: String)

const MARK_SIDE := 110.0
const WHY := "Nobody drives the Junction without a license. Earn yours."
## Over it, come straight from the invitation: the stub's own promise, STORY.md 6.1a.
const FREE_LESSON := "Free lesson included."
const STEPS: Array[String] = ["Driving theory", "Driving test", "Your license"]
const STEP_LINES: Array[String] = [
	"Read the Highway Code of the Junction. All of it.",
	"Five lessons on one lot, then the final exam.",
	"Stamped, signed and yours to keep.",
]
const NUMBER_SIDE := 34.0
const DONE := Color(0.36, 0.9, 0.46)
const PENDING_INK := Color(0.62, 0.62, 0.68)
const PENDING_LINE := Color(0.48, 0.48, 0.54)
const BUTTON := Vector2(420.0, 60.0)
const FIELD_WIDTH := 360.0
## The box over the button: how big, how long after the page is up it ticks itself, and the room
## between it and the button; and the room over the terms, under the buttons.
const TICK_SIDE := 22.0
const ANSWER_AFTER := 1.2
const BOX_AIR := 12.0
const TERMS_AIR := 6.0
## The question asked before the exam alone, GAME.md 9.4a, and its two answers: the theory and the
## lessons are skipped, and a press meant for Enroll is not to cost a new player them.
const EXAM_ASKS := "Straight to the exam?"
const EXAM_SAYS := "No theory and no lessons: the final exam starts right away."
const EXAM_YES := "To the exam"
const EXAM_NO := "Take the course"

var field: LineEdit
var enroll: Button
## The smaller way in, for a player who can drive already: the exam alone, asked first, see
## [method ask_exam], and whether it was the way taken.
var exam: Button
var straight := false
## The question asked before the exam alone while it is up, over the page and shading it.
var question: ConfirmPane
## The box that ticks itself, while the story is told, and the words beside it once it has.
var house_tick: HouseTick
## The opening, while it plays.
var intro: TitleIntro
var _answered: Label


## The box over the terms that ticks itself, STORY.md 6.7: empty as the page comes up, then
## ticked in the House's gold. It is drawn, not a button: no part of enrolling, nothing presses it.
class HouseTick:
	extends Control

	var ticked := false

	func _init() -> void:
		custom_minimum_size = Vector2(TICK_SIDE, TICK_SIDE)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_rect(Rect2(Vector2(1.0, 1.0), size - Vector2(2.0, 2.0)), PENDING_INK, false, 2.0)
		if not ticked:
			return
		var middle := size * 0.5
		var stroke := PackedVector2Array(
			[
				middle + Vector2(-6.0, 0.0),
				middle + Vector2(-1.5, 5.0),
				middle + Vector2(9.0, -9.0),
			]
		)
		draw_polyline(stroke, HouseTheme.FOIL, 3.5, true)


## The numbered disc in front of a step of the course, in the house's gold, or a green disc with
## a check in it for a step done.
class Number:
	extends Control

	var number := 1
	var done := false

	func _init(of: int, is_done := false) -> void:
		number = of
		done = is_done
		custom_minimum_size = Vector2(NUMBER_SIDE, NUMBER_SIDE)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var middle := size * 0.5
		if done:
			draw_circle(middle, NUMBER_SIDE * 0.5, DONE)
			var stroke := PackedVector2Array(
				[
					middle + Vector2(-8.0, 0.0),
					middle + Vector2(-2.5, 6.0),
					middle + Vector2(8.0, -6.0)
				]
			)
			draw_polyline(stroke, Color.WHITE, 3.0, true)
			return
		draw_circle(middle, NUMBER_SIDE * 0.5, Palette.CHIP_GOLD)
		var font := Type.display_font()
		var font_size := 19
		var baseline := middle.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
		draw_string(
			font,
			Vector2(0.0, baseline),
			str(number),
			HORIZONTAL_ALIGNMENT_CENTER,
			size.x,
			font_size,
			MenuTheme.BACKGROUND
		)


static func add_to(parent: Control) -> SchoolEnrollment:
	var page := SchoolEnrollment.new()
	page.name = "Enrollment"
	parent.add_child(page)
	return page


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# In the middle, and shrunk where a big UI scale on a short screen leaves it too tall, GAME.md
	# 8.5, so the way in to the school under all of it is still in sight.
	var center := FitScale.filling(self)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	center.add_child(column)
	var mark := LogoArt.new()
	mark.plate = false
	mark.custom_minimum_size = Vector2(MARK_SIDE, MARK_SIDE)
	var centered := CenterContainer.new()
	centered.add_child(mark)
	column.add_child(centered)
	var named := MenuTheme.title("Jackpot Junction", Type.TITLE)
	column.add_child(named)
	var school := Label.new()
	school.text = "DRIVING SCHOOL"
	school.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Type.display(school, Type.LARGE, Palette.CHIP_WHITE)
	school.add_theme_constant_override("line_spacing", 0)
	column.add_child(school)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, 10.0)
	column.add_child(gap)
	var pane := MenuTheme.pane()
	column.add_child(pane)
	var inside := VBoxContainer.new()
	inside.add_theme_constant_override("separation", 18)
	pane.add_child(inside)
	if DrivingSchool.free_lesson:
		var free := Label.new()
		free.name = "FreeLesson"
		free.text = FREE_LESSON
		free.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Type.strong(free, Type.HEADING, Palette.CHIP_GOLD)
		inside.add_child(free)
	inside.add_child(MenuTheme.subtitle(WHY, Type.BODY))
	field = MenuTheme.field(_starting_name(), PlayerNames.PLACEHOLDER, PlayerNames.MAX_LENGTH)
	field.name = "Name"
	field.custom_minimum_size = Vector2(FIELD_WIDTH, MenuTheme.box_height())
	field.text_submitted.connect(func(_text: String) -> void: _enroll())
	inside.add_child(MenuTheme.row("Your name on the license", field))
	inside.add_child(course(0))
	# The way into the school, in foil, GAME.md 8.1a.
	enroll = MenuTheme.primary(MenuTheme.button("Enroll", Type.HEADING))
	enroll.name = "Enroll"
	enroll.custom_minimum_size = BUTTON
	enroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	enroll.pressed.connect(_enroll)
	exam = MenuTheme.button("Straight to the exam")
	exam.name = "StraightToExam"
	exam.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	exam.pressed.connect(ask_exam)
	# The box answered for the player over the button, with a little air under it, and the
	# Department's terms under them all, always, STORY.md 6.7.
	var signing := VBoxContainer.new()
	signing.add_theme_constant_override("separation", 6)
	if Story.told_here():
		signing.add_child(_come_back())
		var air := Control.new()
		air.custom_minimum_size = Vector2(0.0, BOX_AIR)
		signing.add_child(air)
	signing.add_child(enroll)
	signing.add_child(exam)
	var over_terms := Control.new()
	over_terms.custom_minimum_size = Vector2(0.0, TERMS_AIR)
	signing.add_child(over_terms)
	var terms := Label.new()
	terms.name = "Terms"
	terms.text = StoryLines.ENROLL
	terms.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Type.text(terms, Type.SMALL, PENDING_LINE)
	signing.add_child(terms)
	inside.add_child(signing)
	if TitleIntro.wanted(false):
		_open(mark, column, [named, school, pane], inside)
	else:
		_opened()


## The page opening the way the title does, see [TitleIntro]: the mark large in the middle and up
## into its place, then [param parts] of [param column] rising in, and the rows of [param rows]
## after them, one after another; settled once it is over.
func _open(mark: Control, column: Container, parts: Array, rows: Container) -> void:
	intro = TitleIntro.over(self, mark, column)
	intro.counts = false
	var at := 0.95
	for part: Control in parts:
		intro.add(at, at + 0.4, intro.rise.bind(part))
		at += 0.15
	# The rows sit in the pane, laid out again every frame before any of them is moved.
	intro.add(
		0.0,
		TitleIntro.LENGTH,
		func(_by: float) -> void: rows.notification(Container.NOTIFICATION_SORT_CHILDREN)
	)
	for row: Node in rows.get_children():
		intro.add(at, at + 0.35, intro.rise.bind(row))
		at += 0.08
	intro.finished.connect(_opened)
	intro.start()


## Opened: the cursor on the way in, and the box ticked for the player a moment later.
func _opened() -> void:
	intro = null
	enroll.grab_focus()
	if house_tick == null:
		return
	var wait := create_tween()
	wait.tween_interval(ANSWER_AFTER)
	wait.tween_callback(_answer_for_you)


## The box over the button, STORY.md 6.7, and its line; a moment after the page has opened it
## ticks itself in gold, with "Answered for you." beside it.
func _come_back() -> Control:
	var row := HBoxContainer.new()
	row.name = "ComeBack"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	house_tick = HouseTick.new()
	house_tick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(house_tick)
	var line := Label.new()
	line.text = StoryLines.COME_BACK
	Type.text(line, Type.LABEL, PENDING_INK)
	row.add_child(line)
	_answered = Label.new()
	_answered.name = "Answered"
	_answered.text = StoryLines.ANSWERED_FOR_YOU
	Type.strong(_answered, Type.LABEL, HouseTheme.FOIL)
	_answered.modulate.a = 0.0
	row.add_child(_answered)
	return row


## The House answers for the player: the box ticked in gold, a click, and the words beside it.
func _answer_for_you() -> void:
	if house_tick == null or house_tick.ticked:
		return
	house_tick.ticked = true
	house_tick.queue_redraw()
	Audio.play_sfx(&"ui_click", MenuTheme.CLICK_DB, 0.0)
	create_tween().tween_property(_answered, "modulate:a", 1.0, 0.2)
	ScreenReader.say(self, "%s %s" % [StoryLines.COME_BACK, StoryLines.ANSWERED_FOR_YOU])


## The three steps of the course, numbered, each with a line under it, the first [param done]
## of them ticked green and the rest, still to come, a shade dimmer.
static func course(done: int) -> Control:
	var card := PanelContainer.new()
	card.name = "Course"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.05)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(16.0)
	card.add_theme_stylebox_override("panel", style)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	card.add_child(rows)
	for i: int in STEPS.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var is_done := i < done
		var pending := done > 0 and not is_done
		var number := Number.new(i + 1, is_done)
		number.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(number)
		var words := VBoxContainer.new()
		words.add_theme_constant_override("separation", 0)
		var title := Label.new()
		title.text = STEPS[i] + ("  ·  done" if is_done else "")
		Type.strong(title, Type.BODY, PENDING_INK if pending else Color(0.92, 0.92, 0.95))
		words.add_child(title)
		var line := Label.new()
		line.text = STEP_LINES[i]
		Type.text(line, Type.LABEL, PENDING_LINE if pending else Color(0.66, 0.66, 0.72))
		words.add_child(line)
		row.add_child(words)
		rows.add_child(row)
	return card


## The course as a row of its steps, for the license screen, GAME.md 9.4a: each step's number,
## or a tick once it is done, with its name beside it, the first [param done] ticked.
static func course_row(done: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "CourseRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 26)
	for i: int in STEPS.size():
		var step := HBoxContainer.new()
		step.add_theme_constant_override("separation", 8)
		var number := Number.new(i + 1, i < done)
		number.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		step.add_child(number)
		var word := Label.new()
		word.text = STEPS[i]
		Type.strong(word, Type.LABEL, Color(0.92, 0.92, 0.95) if i < done else PENDING_INK)
		step.add_child(word)
		row.add_child(step)
	return row


## Ticks step [param index] of a row of [method course_row], the number giving way to the tick
## with a pop.
static func tick(row: Control, index: int) -> void:
	if row == null or not is_instance_valid(row) or index >= row.get_child_count():
		return
	var step := row.get_child(index)
	var number := step.get_child(0) as Number
	if number == null or number.done:
		return
	number.done = true
	number.queue_redraw()
	Type.strong(step.get_child(1) as Label, Type.LABEL, Color(0.92, 0.92, 0.95))
	number.pivot_offset = number.size * 0.5
	number.scale = Vector2.ONE * 1.4
	var pop := number.create_tween()
	pop.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	pop.tween_property(number, "scale", Vector2.ONE, 0.32)
	Audio.play_sfx(&"ready", -8.0, 0.0)


## Whether step [param index] of a row of [method course_row] is ticked.
static func is_ticked(row: Control, index: int) -> bool:
	var number := row.get_child(index).get_child(0) as Number
	return number != null and number.done


## What the box starts with: the first seat's name, or one off the list for a seat without one.
func _starting_name() -> String:
	var given: String = Game.settings.player_names[0]
	if not given.is_empty():
		return given
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return PlayerNames.pick(rng)


## Enrolled under what is in the box, or under the name it started with for a box emptied;
## [param for_the_exam] alone, by the smaller way in.
## Straight to the exam pressed: asked first, over the page shaded, the cursor on staying for the
## course; going ahead enrolls for the exam alone, see [method _enroll]. Back is staying.
func ask_exam() -> void:
	if question != null:
		return
	var holder := Control.new()
	holder.name = "Question"
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(holder)
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(shade)
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(middle)
	question = ConfirmPane.new()
	question.name = "ExamQuestion"
	middle.add_child(question)
	question.answered.connect(_on_exam_answered)
	question.ask(EXAM_ASKS, EXAM_SAYS, EXAM_YES, EXAM_NO)


func _on_exam_answered(yes: bool) -> void:
	if question == null:
		return
	question.get_parent().get_parent().queue_free()
	question = null
	if yes:
		_enroll(true)
	elif is_instance_valid(exam):
		exam.grab_focus()


# Back while the question is up is staying for the course, before the school's own Back opens its
# menu.
func _unhandled_input(event: InputEvent) -> void:
	if question != null and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_exam_answered(false)


func _enroll(for_the_exam := false) -> void:
	straight = for_the_exam
	var holder_name := PlayerNames.clean(field.text)
	if holder_name.is_empty():
		holder_name = _starting_name()
	enrolled.emit(holder_name)
