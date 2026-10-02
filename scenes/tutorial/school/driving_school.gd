class_name DrivingSchool
extends Control
## The driving school, GAME.md 9.4a: what the title's Tutorial button opens on, over the title's
## own turning background. Three pages before the driving test, which is the tutorial's rooms:
## the enrollment, where the player gives the name that goes on their license, see
## [SchoolEnrollment]; the theory, a book that reads itself faster than anybody could, see
## [SchoolTheory]; and the pop quiz, three questions nobody fails, see [SchoolQuiz]. Then the
## driving test. Back on the enrollment is back to the title; past it there is no way back but
## the pause menu of the test, since the whole thing is twenty seconds.

signal page_turned(page: int)

enum Page { ENROLL, THEORY, QUIZ, DONE }

var page := Page.ENROLL
## What the end goes on to: the driving test, unless a test of the school's own says otherwise.
var then: Callable
var enrollment: SchoolEnrollment
var theory: SchoolTheory
var quiz: SchoolQuiz


func _init() -> void:
	then = Game.go_to_driving_test


func _ready() -> void:
	MenuTheme.background(self)
	TitleBackground.add_to(self)
	_turn_to(Page.ENROLL)


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
	# Back out of the enrollment is back to the title: B on a pad, or Escape, GAME.md 4.2.
	if page == Page.ENROLL and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		Audio.play_sfx(&"ui_back", MenuTheme.CLICK_DB, 0.0)
		Game.go_to_title()
