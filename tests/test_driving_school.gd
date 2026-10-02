extends GdUnitTestSuite
## The driving school, GAME.md 9.4a: the enrollment that names the license, the book that reads
## itself and shuts, the quiz nobody fails, and the way on to the driving test at the end.

const SCENE := preload("res://scenes/tutorial/school/driving_school.tscn")

var _runner: GdUnitSceneRunner
var _was_path := ""
var _was_names: Array[String] = []


func before_test() -> void:
	# Enrolling saves the settings: never the real file.
	_was_path = Game.settings.path
	_was_names = Game.settings.player_names.duplicate()
	Game.settings.path = "user://school_test.cfg"


func after_test() -> void:
	DirAccess.remove_absolute(Game.settings.path)
	Game.settings.path = _was_path
	Game.settings.player_names = _was_names


func _open() -> DrivingSchool:
	var school: DrivingSchool = auto_free(SCENE.instantiate())
	_runner = scene_runner(school)
	await _runner.simulate_frames(1, 16)
	return school


## Enrolling under a name makes it the first seat's, cleaned, and opens the book; a box emptied
## enrolls under the name it started with, which is a seat's own or one off the funny list.
func test_enrolling_names_the_first_seat_and_opens_the_book() -> void:
	Game.settings.player_names[0] = ""
	var school := await _open()
	assert_int(school.page).is_equal(DrivingSchool.Page.ENROLL)
	assert_object(school.enrollment).is_not_null()
	var offered := school.enrollment.field.text
	assert_bool(offered in PlayerNames.NAMES).is_true()
	# The box takes no more than a name may be, and what it takes is cleaned.
	school.enrollment.field.text = " Tail [L.] Tim "
	school.enrollment.enroll.pressed.emit()
	await await_idle_frame()
	assert_str(Game.settings.player_names[0]).is_equal("Tail L. Tim")
	assert_int(school.page).is_equal(DrivingSchool.Page.THEORY)
	assert_object(school.theory).is_not_null()
	assert_bool(school.theory.is_asking()).is_false()
	assert_bool(FileAccess.file_exists(Game.settings.path)).is_true()
	var again := await _open()
	assert_str(again.enrollment.field.text).is_equal("Tail L. Tim")
	again.enrollment.field.text = "   "
	again.enrollment.enroll.pressed.emit()
	await await_idle_frame()
	assert_str(Game.settings.player_names[0]).is_equal("Tail L. Tim")


## The book reads faster as it goes, shuts when its time is up, and either answer to "Got that?"
## goes on to the quiz.
func test_the_book_reads_faster_shuts_and_asks() -> void:
	var school := await _open()
	school.enrollment.enroll.pressed.emit()
	await await_idle_frame()
	var theory := school.theory
	var runner := _runner
	await runner.simulate_frames(10, 16)
	var early := theory._offset
	assert_float(early).is_greater(0.0)
	await runner.simulate_frames(10, 16)
	var pace_early := theory._offset - early
	theory.elapsed = SchoolTheory.READ_FOR * 0.7
	var late := theory._offset
	await runner.simulate_frames(10, 16)
	assert_float(theory._offset - late).is_greater(pace_early * 4.0)
	assert_str(theory._pace.text).contains("unreasonable")
	assert_bool(theory.is_asking()).is_false()
	theory.elapsed = SchoolTheory.READ_FOR
	await runner.simulate_frames(2, 16)
	await await_millis(400)
	assert_bool(theory.is_asking()).is_true()
	assert_str(theory._counter.text).contains("212 of 212")
	assert_int(theory.answers.size()).is_equal(2)
	theory.answers[1].pressed.emit()
	await await_idle_frame()
	assert_int(school.page).is_equal(DrivingSchool.Page.QUIZ)
	assert_object(school.quiz).is_not_null()


## The quiz: a right answer is said to be; a wrong one is shaken off and the right one presses
## itself; three down, the theory is passed and the one button goes on to the driving test.
func test_the_quiz_corrects_a_wrong_answer_and_goes_on_to_the_test() -> void:
	var school := await _open()
	var went := [0]
	school.then = func() -> void: went[0] += 1
	school._turn_to(DrivingSchool.Page.QUIZ)
	await await_idle_frame()
	var quiz := school.quiz
	assert_int(quiz.index).is_equal(0)
	assert_int(quiz.answers.size()).is_equal(3)
	assert_str(quiz._question.text).is_equal(SchoolQuiz.QUESTIONS[0][0])
	var right: int = SchoolQuiz.QUESTIONS[0][2]
	var wrong := (right + 1) % 3
	quiz.answer(wrong)
	assert_bool(quiz.answers[wrong].disabled).is_true()
	assert_bool(quiz.answers[right].button_pressed).is_false()
	assert_str(quiz._quip.text.strip_edges()).is_equal("")
	await await_millis(int(SchoolQuiz.THINK * 1000.0) + 150)
	assert_bool(quiz.answers[right].button_pressed).is_true()
	assert_str(quiz._quip.text).is_equal(SchoolQuiz.WRONG_QUIPS[0])
	# Another answer while the question is settled changes nothing.
	quiz.answer(right)
	assert_int(quiz.right).is_equal(0)
	await await_millis(int(SchoolQuiz.LINGER * 1000.0) + 150)
	assert_int(quiz.index).is_equal(1)
	quiz.answer(SchoolQuiz.QUESTIONS[1][2])
	assert_int(quiz.right).is_equal(1)
	assert_str(quiz._quip.text).is_equal(SchoolQuiz.RIGHT_QUIPS[1])
	await await_millis(int(SchoolQuiz.LINGER * 1000.0) + 150)
	assert_int(quiz.index).is_equal(2)
	quiz.answer(SchoolQuiz.QUESTIONS[2][2])
	await await_millis(int(SchoolQuiz.LINGER * 1000.0) + 150)
	assert_object(quiz.on).is_not_null()
	assert_int(went[0]).is_equal(0)
	quiz.on.pressed.emit()
	await await_idle_frame()
	assert_int(went[0]).is_equal(1)
	assert_int(school.page).is_equal(DrivingSchool.Page.DONE)


## The title's Tutorial goes to the school, and the school's end to the driving test.
func test_the_school_stands_before_the_driving_test() -> void:
	assert_str(Game.DRIVING_SCHOOL_SCENE).contains("driving_school")
	assert_str(Game.TUTORIAL_SCENE).contains("tutorial.tscn")
	var school := await _open()
	assert_bool(school.then.is_valid()).is_true()
	assert_str(school.then.get_method()).is_equal("go_to_driving_test")
