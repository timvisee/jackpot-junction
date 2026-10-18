class_name DrivingSchool
extends Control
## The driving school, GAME.md 9.4a: what the title's Tutorial button opens on, over the title's
## own turning background. Three pages before the driving test, which is the tutorial's rooms:
## the enrollment, where the player gives the name that goes on their license, see
## [SchoolEnrollment]; the theory, a book that reads itself faster than anybody could, see
## [SchoolTheory]; and the pop quiz, three questions nobody fails, see [SchoolQuiz]. Then the
## driving test. Escape or B on any page, Start on a pad, or the menu button in the top right
## corner, which every device has here, opens the school's menu, the page held still under it:
## Resume, Settings, and Skip driving school, which asks first and is back to the title, see
## [method PauseMenu.for_the_school].

signal page_turned(page: int)

enum Page { ENROLL, THEORY, QUIZ, DONE }

## The menu button, where the school stands: in the top right corner, the round button with three
## bars that every room has there on a touch screen, GAME.md 4.2, and here on every device, so a
## player new to the game finds the settings without knowing Escape.
const MENU_RADIUS := 34.0
const MENU_INSET := Vector2(64.0, 62.0)
const MENU_INK := Palette.CHIP_WHITE


## The round menu button, drawn the way the rooms draw theirs.
class CornerMenu:
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
## Whether the school was come to straight from the invitation, whose stub promises a free lesson,
## STORY.md 6.1a: the enrollment says so. Set by the title, for this visit only.
static var free_lesson := false

var page := Page.ENROLL
## What the end goes on to: the driving test, unless a test of the school's own says otherwise;
## and what skipping the school goes back to, the title.
var then: Callable
var leave: Callable
var enrollment: SchoolEnrollment
var theory: SchoolTheory
var quiz: SchoolQuiz
## The school's menu, see [method PauseMenu.for_the_school].
var menu: PauseMenu

## What last had the cursor on the page, for it to have again once the menu is put away.
var _was_focused: Control
## The menu button, kept over every page put up after it.
var _menu: CornerMenu


func _init() -> void:
	then = Game.go_to_driving_test
	leave = Game.go_to_title


func _ready() -> void:
	underway = true
	MenuTheme.background(self)
	TitleBackground.add_to(self)
	_menu = CornerMenu.new()
	_menu.name = "Menu"
	ScreenReader.name(_menu, "Menu")
	_menu.pressed.connect(open_menu)
	add_child(_menu)
	_turn_to(Page.ENROLL)
	menu = PauseMenu.add_to(self)
	menu.for_the_school(_leave)
	menu.resumed.connect(_on_resumed)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)


func _exit_tree() -> void:
	underway = false
	free_lesson = false


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
	# B on a pad opens the menu too, GAME.md 4.2: the menu itself answers Escape and Start, and B
	# only once it is open, where it backs out.
	if page != Page.DONE and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		open_menu()


## Opens the school's menu over the page, which stands still under it: the book stops reading.
func open_menu() -> void:
	if page == Page.DONE or menu.is_open():
		return
	menu.set_paused(true)


## The menu put away: the page goes on as it was, with the cursor where it was.
func _on_resumed() -> void:
	if _was_focused != null and is_instance_valid(_was_focused):
		_was_focused.grab_focus()


func _on_focus_changed(control: Control) -> void:
	if control != null and not menu.is_ancestor_of(control):
		_was_focused = control


## Whether the school's menu, or the settings from it, are up.
func is_menu_open() -> bool:
	return menu != null and menu.is_open()


## Out of the school, to the title.
func _leave() -> void:
	page = Page.DONE
	MenuTheme.back_sound()
	if leave.is_valid():
		leave.call()
