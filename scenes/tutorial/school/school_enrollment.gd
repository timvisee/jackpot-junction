class_name SchoolEnrollment
extends Control
## The driving school's first page, GAME.md 9.4a: the game's mark and name with DRIVING SCHOOL
## under them, a line on why anybody is here, the box for the name that goes on the license, the
## course in three steps, and one big button, Enroll. The name box starts with the first seat's
## name, or with one off the funny list for a seat that never gave one, so there is always a name
## to enroll under; Enter in the box enrolls too.

## The player enrolled, under [param holder_name].
signal enrolled(holder_name: String)

const MARK_SIDE := 110.0
const WHY := "Nobody drives the Junction without a license. Earn yours."
const STEPS: Array[String] = ["Driving theory", "Driving test", "Your license"]
const STEP_LINES: Array[String] = [
	"Read the Highway Code of the Junction. All of it.",
	"Eleven lessons in a row of rooms, then the final exam.",
	"Stamped, signed and yours to keep.",
]
const NUMBER_SIDE := 34.0
const DONE := Color(0.36, 0.9, 0.46)
const PENDING_INK := Color(0.62, 0.62, 0.68)
const PENDING_LINE := Color(0.48, 0.48, 0.54)
const BUTTON := Vector2(420.0, 60.0)
const FIELD_WIDTH := 360.0

var field: LineEdit
var enroll: Button


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
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	center.add_child(column)
	var mark := LogoArt.new()
	mark.plate = false
	mark.custom_minimum_size = Vector2(MARK_SIDE, MARK_SIDE)
	var centered := CenterContainer.new()
	centered.add_child(mark)
	column.add_child(centered)
	column.add_child(MenuTheme.title("Jackpot Junction", Type.TITLE))
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
	inside.add_child(enroll)
	enroll.grab_focus()


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


## Enrolled under what is in the box, or under the name it started with for a box emptied.
func _enroll() -> void:
	var holder_name := PlayerNames.clean(field.text)
	if holder_name.is_empty():
		holder_name = _starting_name()
	enrolled.emit(holder_name)
