class_name DrivingSchool
extends Control
## The driving school, GAME.md 9.4a: what the title's Tutorial button opens on, over the title's
## own turning background. Three pages before the driving test, which is the tutorial's rooms:
## the enrollment, where the player gives the name that goes on their license, see
## [SchoolEnrollment]; the theory, a book that reads itself faster than anybody could, see
## [SchoolTheory]; and the pop quiz, three questions nobody fails, see [SchoolQuiz]. Then the
## driving test. Back on any page, Escape or B, the pause button of a room, Start on a pad, or
## the menu button a touch screen has in the top right corner, GAME.md 4.2, asks whether to
## leave, the page held still under the question, and leaving is back to the title.

signal page_turned(page: int)

enum Page { ENROLL, THEORY, QUIZ, DONE }

## The menu button of a touch screen, where the school stands: in the top right corner, the
## round button with three bars that every room has there, GAME.md 4.2, and here it is the way
## out.
const MENU_RADIUS := 34.0
const MENU_INSET := Vector2(64.0, 62.0)
const MENU_INK := Palette.CHIP_WHITE
## What leaving asks.
const LEAVE_QUESTION := "Leave the driving school?"
const LEAVE_LINE := (
	"Progress will be lost. " + "Retake your driving test any time from the title screen."
)


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


## Whether somebody is in the driving school or its test right now, the school's pages or the
## test's rooms, for the License page of the settings to say so, GAME.md 8.5.
static var underway := false

var page := Page.ENROLL
## What the end goes on to: the driving test, unless a test of the school's own says otherwise;
## and what leaving goes back to, the title.
var then: Callable
var leave: Callable
var enrollment: SchoolEnrollment
var theory: SchoolTheory
var quiz: SchoolQuiz

## The question whether to leave, while it is up, and what had the cursor before it.
var _question: Control
var _was_focused: Control
## The touch screen's menu button, kept over every page put up after it.
var _menu: LeaveButton


func _init() -> void:
	then = Game.go_to_driving_test
	leave = Game.go_to_title


func _ready() -> void:
	underway = true
	MenuTheme.background(self)
	TitleBackground.add_to(self)
	_turn_to(Page.ENROLL)
	if TouchInput.enabled:
		_menu = LeaveButton.new()
		_menu.name = "Menu"
		_menu.pressed.connect(ask_to_leave)
		add_child(_menu)


func _exit_tree() -> void:
	underway = false


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
	# A page put up over the menu button would take its touches: the button stays on top.
	if _menu != null and is_instance_valid(_menu):
		_menu.move_to_front()
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
	# Back on any page asks whether to leave, and Back on the question is Stay: B on a pad, or
	# Escape, GAME.md 4.2, and the pause button of a room, Start on a pad, the same.
	var asked := (
		event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(InputActions.PAUSE)
	)
	if page != Page.DONE and asked:
		get_viewport().set_input_as_handled()
		if _question != null:
			stay()
		else:
			ask_to_leave()


## Asks whether to leave, over the page, which stands still under the question: the book stops
## reading. Leave is the title; Stay, which has the cursor, is back to where the page was.
func ask_to_leave() -> void:
	if _question != null or page == Page.DONE:
		return
	_was_focused = get_viewport().gui_get_focus_owner()
	var holder := Control.new()
	holder.name = "LeaveQuestion"
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(holder)
	_question = holder
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(shade)
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(middle)
	var pane := ConfirmPane.new()
	pane.name = "LeavePane"
	middle.add_child(pane)
	pane.answered.connect(
		func(yes: bool) -> void:
			if yes:
				_leave()
			else:
				stay()
	)
	pane.ask(LEAVE_QUESTION, LEAVE_LINE, "Leave", "Stay")
	var shown := _shown_page()
	if shown != null:
		shown.process_mode = Node.PROCESS_MODE_DISABLED


## The question put away, and the page going on as it was.
func stay() -> void:
	if _question == null:
		return
	_question.queue_free()
	_question = null
	var shown := _shown_page()
	if shown != null:
		shown.process_mode = Node.PROCESS_MODE_INHERIT
	if _was_focused != null and is_instance_valid(_was_focused):
		_was_focused.grab_focus()


## Whether the question whether to leave is up.
func is_asking_to_leave() -> bool:
	return _question != null


## The page up just now, or null.
func _shown_page() -> Control:
	match page:
		Page.ENROLL:
			return enrollment
		Page.THEORY:
			return theory
		Page.QUIZ:
			return quiz
	return null


## Out of the school, to the title.
func _leave() -> void:
	page = Page.DONE
	Audio.play_sfx(&"ui_back", MenuTheme.CLICK_DB, 0.0)
	if leave.is_valid():
		leave.call()
