class_name DrivingSchool
extends Control
## The driving school, GAME.md 9.4a: what the title's Tutorial button opens on, over the title's
## own turning background. Three pages before the driving test, which is the tutorial's rooms:
## the enrollment, where the player gives the name that goes on their license, see
## [SchoolEnrollment]; the theory, a book that reads itself faster than anybody could, see
## [SchoolTheory]; and the pop quiz, three questions nobody fails, see [SchoolQuiz]. Then the
## driving test. Back on any page, Escape or B, is back to the title, and on a touch screen the
## menu button in the top right corner is, GAME.md 4.2.

signal page_turned(page: int)

enum Page { ENROLL, THEORY, QUIZ, DONE }

## The menu button of a touch screen, where the school stands: in the top right corner, the
## round button with three bars that every room has there, GAME.md 4.2, and here it is the way
## out.
const MENU_RADIUS := 34.0
const MENU_INSET := Vector2(64.0, 62.0)
const MENU_INK := Palette.CHIP_WHITE


## The round menu button of a touch screen, drawn the way the rooms draw theirs.
class LeaveButton:
	extends Button

	func _ready() -> void:
		var side := MENU_RADIUS * 2.0 + 16.0
		custom_minimum_size = Vector2(side, side)
		size = custom_minimum_size
		set_anchors_preset(Control.PRESET_TOP_RIGHT)
		position = Vector2(-MENU_INSET.x - side * 0.5, MENU_INSET.y - side * 0.5)
		anchor_left = 1.0
		anchor_right = 1.0
		offset_left = -MENU_INSET.x - side * 0.5
		offset_right = -MENU_INSET.x + side * 0.5
		offset_top = MENU_INSET.y - side * 0.5
		offset_bottom = MENU_INSET.y + side * 0.5
		focus_mode = Control.FOCUS_NONE
		for state: String in ["normal", "hover", "pressed", "focus"]:
			add_theme_stylebox_override(state, StyleBoxEmpty.new())

	func _draw() -> void:
		var middle := size * 0.5
		draw_circle(middle, MENU_RADIUS, Color(0.0, 0.0, 0.0, 0.5))
		draw_arc(middle, MENU_RADIUS - 1.0, 0.0, TAU, 48, MENU_INK, 2.0, true)
		for i: int in 3:
			var y := middle.y - 12.0 + 12.0 * float(i)
			draw_rect(Rect2(Vector2(middle.x - 14.0, y - 2.0), Vector2(28.0, 4.0)), MENU_INK)


var page := Page.ENROLL
## What the end goes on to: the driving test, unless a test of the school's own says otherwise;
## and what leaving goes back to, the title.
var then: Callable
var leave: Callable
var enrollment: SchoolEnrollment
var theory: SchoolTheory
var quiz: SchoolQuiz


func _init() -> void:
	then = Game.go_to_driving_test
	leave = Game.go_to_title


func _ready() -> void:
	MenuTheme.background(self)
	TitleBackground.add_to(self)
	_turn_to(Page.ENROLL)
	if TouchInput.enabled:
		var menu := LeaveButton.new()
		menu.name = "Menu"
		menu.pressed.connect(_leave)
		add_child(menu)


## Puts up the page [param to], in place of whatever was up.
func _turn_to(to: Page) -> void:
	page = to
	for old: Node in [enrollment, theory, quiz]:
		if old != null and is_instance_valid(old):
			old.queue_free()
	enrollment = null
	theory = null
	quiz = null
	match to:
		Page.ENROLL:
			enrollment = SchoolEnrollment.add_to(self)
			enrollment.enrolled.connect(_on_enrolled)
		Page.THEORY:
			theory = SchoolTheory.add_to(self)
			theory.finished.connect(_on_theory_done)
		Page.QUIZ:
			quiz = SchoolQuiz.add_to(self)
			quiz.passed.connect(_on_quiz_done)
		Page.DONE:
			pass
	page_turned.emit(to)


## Enrolled, under the name on the field, which is the first seat's from here on, GAME.md 4.4.
func _on_enrolled(holder_name: String) -> void:
	Game.settings.player_names[0] = holder_name
	Game.settings.save_to_disk()
	_turn_to(Page.THEORY)


func _on_theory_done() -> void:
	_turn_to(Page.QUIZ)


func _on_quiz_done() -> void:
	_turn_to(Page.DONE)
	if then.is_valid():
		then.call()


func _unhandled_input(event: InputEvent) -> void:
	# Back out of any page is back to the title: B on a pad, or Escape, GAME.md 4.2.
	if page != Page.DONE and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_leave()


## Out of the school, to the title.
func _leave() -> void:
	page = Page.DONE
	Audio.play_sfx(&"ui_back", MenuTheme.CLICK_DB, 0.0)
	if leave.is_valid():
		leave.call()
