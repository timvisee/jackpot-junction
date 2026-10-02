extends GdUnitTestSuite
## The driving school, GAME.md 9.4a: the enrollment that names the license, the book that reads
## itself and shuts, the quiz nobody fails, and the way on to the driving test at the end.

const SCENE := preload("res://scenes/tutorial/school/driving_school.tscn")
const TITLE_SCENE := preload("res://scenes/ui/title.tscn")

var _runner: GdUnitSceneRunner
var _was_path := ""
var _was_names: Array[String] = []
var _was_license: Array = []


func before_test() -> void:
	# Enrolling saves the settings: never the real file.
	_was_path = Game.settings.path
	_was_names = Game.settings.player_names.duplicate()
	var settings := Game.settings
	_was_license = [
		settings.license_number,
		settings.license_date,
		settings.license_holder,
		settings.license_plate,
		settings.license_endorsements.duplicate(),
	]
	Game.settings.path = "user://school_test.cfg"


func after_test() -> void:
	DirAccess.remove_absolute(Game.settings.path)
	Game.settings.path = _was_path
	Game.settings.player_names = _was_names
	Game.settings.license_number = _was_license[0]
	Game.settings.license_date = _was_license[1]
	Game.settings.license_holder = _was_license[2]
	Game.settings.license_plate = _was_license[3]
	Game.settings.license_endorsements = _was_license[4]


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


## The book opens on its title page and stands there, then reads faster as it goes, shuts when
## its time is up, and either answer to "Got that?" goes on to the quiz.
func test_the_book_reads_faster_shuts_and_asks() -> void:
	var school := await _open()
	school.enrollment.enroll.pressed.emit()
	await await_idle_frame()
	var theory := school.theory
	var runner := _runner
	# The title page, still, on the left, with the first rule across from it.
	await runner.simulate_frames(10, 16)
	assert_float(theory._offset).is_equal(0.0)
	assert_int(theory.page_shown).is_equal(1)
	assert_str(theory._folios[0].text).is_equal("1")
	assert_str(theory._folios[1].text).is_equal("2")
	assert_object(theory._columns[0].get_child(0).find_child("*", true, false)).is_not_null()
	theory.elapsed = SchoolTheory.HOLD
	await runner.simulate_frames(10, 16)
	var early := theory._offset
	assert_float(early).is_greater(0.0)
	await runner.simulate_frames(10, 16)
	var pace_early := theory._offset - early
	theory.elapsed = SchoolTheory.HOLD + (SchoolTheory.READ_FOR - SchoolTheory.HOLD) * 0.7
	var late := theory._offset
	await runner.simulate_frames(10, 16)
	assert_float(theory._offset - late).is_greater(pace_early * 4.0)
	assert_int(theory.page_shown).is_greater(1)
	assert_bool(theory.is_asking()).is_false()
	theory.elapsed = SchoolTheory.READ_FOR
	await runner.simulate_frames(2, 16)
	# The right half swings over, the cover comes down with the dust, and then the question.
	assert_bool(theory.is_closed()).is_false()
	var folding := SchoolTheory.BREATH + SchoolTheory.SWING + SchoolTheory.COVER_DOWN
	await await_millis(int(folding * 1000.0) + 200)
	assert_bool(theory.is_closed()).is_true()
	assert_float(theory._halves[1].scale.x).is_equal_approx(0.0, 0.001)
	assert_object(theory._book.get_node_or_null("Dust")).is_not_null()
	assert_bool(theory.is_asking()).is_false()
	await await_millis(int((SchoolTheory.SHUT_FOR + SchoolTheory.FADE) * 1000.0) + 300)
	assert_bool(theory.is_asking()).is_true()
	# Beside the shut book, which stays: where the right page was.
	assert_bool(theory._book.visible).is_true()
	assert_bool(theory.is_closed()).is_true()
	assert_float(theory._question.position.x).is_greater(SchoolTheory.half_width())
	assert_int(theory.page_shown).is_equal(SchoolTheory.PAGES - 1)
	assert_str(theory._folios[1].text).is_equal(str(SchoolTheory.PAGES))
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
	# The course under the word, its first step done and the other two still to come.
	var course := quiz._column.find_child("Course", true, false)
	assert_object(course).is_not_null()
	var numbers := course.find_children("*", "Control", true, false).filter(
		func(node: Node) -> bool: return node is SchoolEnrollment.Number
	)
	assert_int(numbers.size()).is_equal(3)
	assert_bool((numbers[0] as SchoolEnrollment.Number).done).is_true()
	assert_bool((numbers[1] as SchoolEnrollment.Number).done).is_false()
	assert_int(went[0]).is_equal(0)
	quiz.on.pressed.emit()
	await await_idle_frame()
	assert_int(went[0]).is_equal(1)
	assert_int(school.page).is_equal(DrivingSchool.Page.DONE)


## The license is good for an unreasonable while, and a plate is up to eight of what a plate may
## hold, suggested from the holder's initials and the number.
func test_the_license_expires_in_centuries_and_a_plate_is_eight_characters() -> void:
	assert_str(LicenseCard.expiry("2026-10-02")).is_equal("2446-10-02")
	assert_str(LicenseCard.expiry("")).is_equal("NEVER")
	assert_str(LicensePlate.clean("tail light tim")).is_equal("TAIL LIG")
	assert_str(LicensePlate.clean("  jj-01 [x] !! ")).is_equal("JJ-01 X")
	assert_str(LicensePlate.clean("a   b")).is_equal("A B")
	assert_str(LicensePlate.suggest("Tail Light Tim", "JJ-224123")).is_equal("TLT-123")
	assert_str(LicensePlate.suggest("Zed", "JJ-000007")).is_equal("ZED-007")
	assert_str(LicensePlate.suggest("", "")).is_equal("JJ")


## A kart of this machine's wears the learner's L until the license is earned, and the plate
## chosen after; the settings have a tab for the license, with the plate to change on it.
func test_a_kart_wears_its_plate_and_the_settings_show_the_license() -> void:
	var plate_scene: PackedScene = load("res://scenes/match/match.tscn")
	Game.settings.license_number = ""
	var without: Match = auto_free(plate_scene.instantiate())
	without.rules = load("res://data/match/default.tres").duplicate()
	without.offer_size = 0
	var runner := scene_runner(without)
	without.bot_difficulty = load("res://data/ai/easy.tres")
	var inputs: Array[KartInput] = [
		PlayerInput.new(DeviceInput.ANY, 0), KartInput.new(), BotInput.new()
	]
	without.start(inputs, 17, [], [], [])
	await runner.simulate_frames(1, 16)
	var plate := without.slots[0].kart.get_node_or_null("Body/Plate")
	assert_object(plate).is_not_null()
	assert_str(plate.get_meta(&"plate")).is_equal("L")
	assert_object(without.slots[1].kart.get_node_or_null("Body/Plate")).is_null()
	# The easy bot is a learner; made normal, it holds a license, with a plate from its name.
	var bot := without.slots[2]
	assert_str(bot.kart.get_node("Body/Plate").get_meta(&"plate")).is_equal("L")
	var brain := bot.kart.get_node("Brain") as BotBrain
	brain.setup(bot.kart, without, brain.bot_trait, load("res://data/ai/normal.tres"), without.rng)
	without.plate_kart(bot)
	var worn: String = bot.kart.get_node("Body/Plate").get_meta(&"plate")
	assert_str(worn).is_not_equal("L")
	assert_bool(worn.contains("-")).is_true()
	assert_str(worn).is_equal(LicensePlate.clean(worn))
	Game.settings.license_number = "JJ-224123"
	Game.settings.license_date = "2026-10-02"
	Game.settings.license_holder = "Tail Light Tim"
	Game.settings.license_plate = "TLT-123"
	Game.settings.license_endorsements = PackedStringArray(["KO"])
	KartVisuals.plate_for_here(without.slots[0].kart)
	plate = without.slots[0].kart.get_node_or_null("Body/Plate")
	assert_str(plate.get_meta(&"plate")).is_equal("TLT-123")
	# The podium's karts wear theirs too, for the ones at this machine.
	var podium := ResultsPodium.create()
	add_child(podium)
	podium.show_top([without.slots[0], without.slots[1]], [true, false])
	assert_int(podium._karts.size()).is_equal(2)
	var on_step := podium._karts[0].find_child("Plate", true, false)
	assert_object(on_step).is_not_null()
	assert_str(on_step.get_meta(&"plate")).is_equal("TLT-123")
	assert_object(podium._karts[1].find_child("Plate", true, false)).is_null()
	podium.queue_free()
	(
		assert_int(
			without.slots[0].kart.get_node("Body").find_children("Plate", "", false, false).size()
		)
		. is_equal(1)
	)
	# The settings' tab: the card as the settings keep it, and the plate typed cleaned.
	var tab := LicenseTab.make(Game.settings)
	add_child(tab)
	await await_idle_frame()
	var card: LicenseCard = tab.find_child("LicenseCard", true, false)
	assert_object(card).is_not_null()
	assert_str(card.holder_name).is_equal("Tail Light Tim")
	assert_bool(card.stamped).is_true()
	assert_bool(card.endorsements["KO"]).is_true()
	assert_bool(card.endorsements["ITEMS"]).is_false()
	tab.field.text = "my kart!!"
	tab.field.text_changed.emit(tab.field.text)
	assert_str(Game.settings.license_plate).is_equal("MY KART")
	assert_str(tab.preview.text).is_equal("MY KART")
	tab.queue_free()
	Game.settings.license_number = ""
	var none := LicenseTab.make(Game.settings)
	add_child(none)
	await await_idle_frame()
	assert_object(none.find_child("LicenseCard", true, false)).is_null()
	assert_object(none.field).is_null()
	assert_object(none.earn).is_not_null()
	none.queue_free()


## The title peeks the license in from the right edge once there is one, and slides it out under
## the cursor; with none there is nothing to peek.
func test_the_title_peeks_the_license_earned() -> void:
	Game.settings.license_number = ""
	var bare: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(bare)
	await await_idle_frame()
	assert_object(bare.find_child("LicensePeek", true, false)).is_null()
	bare.queue_free()
	Game.settings.license_number = "JJ-224123"
	Game.settings.license_date = "2026-10-02"
	Game.settings.license_holder = "Tail Light Tim"
	var title: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(title)
	await await_idle_frame()
	var peek: LicenseCard = title.find_child("LicensePeek", true, false)
	assert_object(peek).is_not_null()
	assert_bool(peek.stamped).is_true()
	var screen := title.size
	var hidden_middle := peek.position + LicenseCard.SIZE * 0.5
	assert_float(hidden_middle.x).is_greater(screen.x - LicenseCard.SIZE.x * 0.5)
	assert_float(peek.rotation).is_less(-0.1)
	title._slide_license(true)
	await await_millis(int(title.LICENSE_SLIDE * 1000.0) + 150)
	var out_middle := peek.position + LicenseCard.SIZE * 0.5
	assert_float(out_middle.x).is_less(hidden_middle.x)
	assert_float(out_middle.x + LicenseCard.SIZE.x * title.LICENSE_SCALE * 0.5).is_less(screen.x)
	assert_float(peek.rotation).is_greater(-0.1)
	# Peeking in, most of it shows; a click shows it in full, and Back puts it away.
	var drawn: float = LicenseCard.SIZE.x * title.LICENSE_SCALE
	var showing: float = screen.x - (hidden_middle.x - drawn * 0.5)
	assert_float(showing / drawn).is_greater(0.6)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	title._on_license_input(click)
	await await_idle_frame()
	var view := title.find_child("LicenseView", true, false)
	assert_object(view).is_not_null()
	var full: LicenseCard = view.find_child("LicenseFull", true, false)
	assert_object(full).is_not_null()
	assert_float(full.scale.x).is_equal_approx(title.LICENSE_FULL, 0.001)
	var back := InputEventAction.new()
	back.action = &"ui_cancel"
	back.pressed = true
	title._unhandled_input(back)
	await await_idle_frame()
	assert_object(title.find_child("LicenseView", true, false)).is_null()
	# The hand's button shows it too, and again puts it away, with its glyph riding on the card.
	assert_object(peek.find_child("LicenseGlyph", false, false)).is_not_null()
	var hand := InputEventAction.new()
	hand.action = InputActions.JOKER_MENU
	hand.pressed = true
	title._input(hand)
	await await_idle_frame()
	assert_object(title.find_child("LicenseView", true, false)).is_not_null()
	title._input(hand)
	await await_idle_frame()
	assert_object(title.find_child("LicenseView", true, false)).is_null()
	# Without a license, the Garage asks for one like the ways in to playing do.
	Game.settings.license_number = ""
	var garage: Button = title.find_child("Garage", true, false)
	garage.pressed.emit()
	assert_object(title.find_child("LicenseOffer", true, false)).is_not_null()


## Back on any page of the school is the way out, to the title; the quiz has a word for every
## score, and one for a show-off.
func test_back_leaves_the_school_and_the_quiz_has_a_word_for_every_score() -> void:
	var school := await _open()
	var left := [0]
	school.leave = func() -> void: left[0] += 1
	school.enrollment.enroll.pressed.emit()
	await await_idle_frame()
	assert_int(school.page).is_equal(DrivingSchool.Page.THEORY)
	var back := InputEventAction.new()
	back.action = &"ui_cancel"
	back.pressed = true
	# Back asks first, the book held still under the question; Back again is Stay.
	school._unhandled_input(back)
	assert_bool(school.is_asking_to_leave()).is_true()
	assert_int(left[0]).is_equal(0)
	assert_int(school.page).is_equal(DrivingSchool.Page.THEORY)
	assert_int(school.theory.process_mode).is_equal(Node.PROCESS_MODE_DISABLED)
	var pane: ConfirmPane = school.find_child("LeavePane", true, false)
	assert_object(pane).is_not_null()
	assert_str(pane.said()).contains("Leave the driving school?")
	school._unhandled_input(back)
	assert_bool(school.is_asking_to_leave()).is_false()
	assert_int(school.theory.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	await await_idle_frame()
	assert_object(school.find_child("LeavePane", true, false)).is_null()
	# Asked again and answered Leave, it leaves.
	school.ask_to_leave()
	(school.find_child("LeavePane", true, false) as ConfirmPane).yes_button().pressed.emit()
	assert_int(left[0]).is_equal(1)
	assert_int(school.page).is_equal(DrivingSchool.Page.DONE)
	assert_str(SchoolQuiz.score_words(0, 3)).is_equal(
		"0 of 3 right the first time. You'll get them, eventually."
	)
	assert_str(SchoolQuiz.score_words(1, 3)).is_equal(
		"1 of 3 right the first time. The other 2, eventually."
	)
	assert_str(SchoolQuiz.score_words(3, 3)).is_equal(
		"3 of 3 right the first time. Nobody likes a show-off."
	)


## The settings file can be named on the command line, GAME.md 10.2: a user path, an absolute
## one, or a bare name in the user directory; nothing named is the usual file.
func test_a_settings_file_can_be_named_on_the_command_line() -> void:
	assert_str(Game.settings_path_in(PackedStringArray(["--settings=user://fresh.cfg"]))).is_equal(
		"user://fresh.cfg"
	)
	(
		assert_str(Game.settings_path_in(PackedStringArray(["--frames=3", "--settings=fresh.cfg"])))
		. is_equal("user://fresh.cfg")
	)
	assert_str(Game.settings_path_in(PackedStringArray(["--settings=/tmp/a.cfg"]))).is_equal(
		"/tmp/a.cfg"
	)
	assert_str(Game.settings_path_in(PackedStringArray(["--settings="]))).is_equal("")
	assert_str(Game.settings_path_in(PackedStringArray(["--bench=10"]))).is_equal("")


## The title's Tutorial goes to the school, and the school's end to the driving test.
func test_the_school_stands_before_the_driving_test() -> void:
	assert_str(Game.DRIVING_SCHOOL_SCENE).contains("driving_school")
	assert_str(Game.TUTORIAL_SCENE).contains("tutorial.tscn")
	var school := await _open()
	assert_bool(school.then.is_valid()).is_true()
	assert_str(school.then.get_method()).is_equal("go_to_driving_test")
