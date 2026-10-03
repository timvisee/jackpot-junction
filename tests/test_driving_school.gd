extends GdUnitTestSuite
## The driving school, GAME.md 9.4a: the enrollment that names the license, the book that reads
## itself and shuts, the quiz nobody fails, and the way on to the driving test at the end.

const SCENE := preload("res://scenes/tutorial/school/driving_school.tscn")
const TITLE_SCENE := preload("res://scenes/ui/title.tscn")

var _runner: GdUnitSceneRunner
var _was_path := ""
var _was_names: Array[String] = []
var _was_modes: Array[String] = []
var _was_license: Array = []


func before_test() -> void:
	# Enrolling saves the settings: never the real file.
	_was_path = Game.settings.path
	_was_names = Game.settings.player_names.duplicate()
	_was_modes = Game.settings.drive_modes.duplicate()
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
	Settings.remove_files(Game.settings.path)
	Game.settings.path = _was_path
	Game.settings.player_names = _was_names
	Game.settings.drive_modes = _was_modes
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
	# It comes up shut on the right and waits, the control that opens it on its corner and the
	# reading not started; a click on it opens it onto the left: the front cover lifts off it
	# toward the spine and comes down on the other side, which is the side it does not shut onto.
	await runner.simulate_frames(20, 16)
	assert_bool(theory.is_waiting()).is_true()
	assert_bool(theory.is_opening()).is_false()
	assert_float(theory.elapsed).is_equal(0.0)
	var mark: Control = theory._book.find_child("OpenMark", true, false)
	assert_object(mark).is_not_null()
	assert_int(mark.find_children("*", "InputGlyph", true, false).size()).is_equal(1)
	# The half it has yet to open onto says to read it carefully, and goes as it opens.
	var warning: Control = theory._book.find_child("Warning", true, false)
	assert_object(warning).is_not_null()
	assert_bool(warning.visible).is_true()
	assert_float(warning.position.x + warning.size.x).is_less_equal(SchoolTheory.half_width())
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	theory._front.gui_input.emit(click)
	assert_bool(theory.is_waiting()).is_false()
	assert_bool(theory.is_opening()).is_true()
	assert_bool(theory.is_closed()).is_true()
	assert_bool(theory._front.visible).is_true()
	assert_float(theory._front.position.x).is_equal_approx(SchoolTheory.half_width(), 0.5)
	assert_bool(theory._lid.visible).is_false()
	assert_float(theory._halves[0].scale.x).is_equal_approx(0.0, 0.001)
	assert_float(theory._halves[1].scale.x).is_equal_approx(1.0, 0.001)
	await await_millis(int(SchoolTheory.OPEN_FOR * 1000.0) + 200)
	(
		assert_bool(is_instance_valid(warning))
		. override_failure_message("the warning stayed")
		. is_false()
	)
	assert_bool(theory.is_opening()).is_false()
	assert_bool(theory.is_closed()).is_false()
	assert_bool(theory._front.visible).is_false()
	assert_float(theory._halves[0].scale.x).is_equal_approx(1.0, 0.001)
	# The title page, still, on the left, with the first rule across from it, the text cut into
	# pages with nothing cut across two.
	await runner.simulate_frames(10, 16)
	assert_int(theory.turns).is_equal(0)
	assert_int(theory.page_shown).is_equal(1)
	assert_str(theory._folios[0].text).is_equal("1")
	assert_str(theory._folios[1].text).is_equal("2")
	assert_object(theory._columns[0].get_child(0).find_child("*", true, false)).is_not_null()
	assert_int(theory._page_count()).is_greater(10)
	# Long enough that a whole read never comes round to the start again.
	assert_int(theory._page_count()).is_greater(2 * SchoolTheory.planned_turns() + 2)
	assert_int(theory._columns[SchoolTheory.RIGHT].get_child_count()).is_greater(0)
	for page: int in theory._page_count():
		assert_float(theory._page_tall[page]).is_less_equal(SchoolTheory.leaf_height())
	# The numbers only go up, through the chapters and sections, the clauses under each section
	# and the figures, and on up past the end of the text as the book comes round again; and the
	# figures do not fall on a beat.
	var last := {&"chapter": 0, &"section": 0, &"clause": 0, &"figure": 0}
	var gaps: Array[int] = []
	var since := 0
	for lap: int in 3:
		for item: Dictionary in theory._text.items:
			var words: String = theory._text.words(item, lap)
			match item["kind"]:
				&"rule":
					var section := int(words.trim_prefix("§ ").get_slice(".", 0))
					assert_int(section).is_equal(last[&"section"] + 1)
					last[&"section"] = section
					last[&"clause"] = 0
					since += 1
				&"clause":
					var numbers := words.trim_prefix("§ ").get_slice(" ", 0).split(".")
					assert_int(int(numbers[0])).is_equal(last[&"section"])
					assert_int(int(numbers[1])).is_equal(last[&"clause"] + 1)
					last[&"clause"] = int(numbers[1])
					since += 1
				&"figure":
					var number := int(words.trim_prefix("Fig. ").get_slice(".", 0))
					assert_int(number).is_equal(last[&"figure"] + 1)
					last[&"figure"] = number
					gaps.append(since)
					since = 0
				&"chapter":
					last[&"chapter"] += 1
					assert_str(words).starts_with("Chapter " + TheoryText.roman(last[&"chapter"]))
	assert_int(gaps.size()).is_greater(5)
	assert_int(gaps.max()).is_greater(gaps.min())
	# The first leaf turns a while into the reading, over onto the left, which it becomes.
	theory.elapsed = SchoolTheory.HOLD + SchoolTheory.TURN_FIRST
	await runner.simulate_frames(3, 16)
	assert_int(theory.turns).is_equal(1)
	assert_bool(theory.is_turning()).is_true()
	assert_bool(theory._leaf.visible).is_true()
	await await_millis(int(SchoolTheory.TURN_SLOWEST * 1000.0) + 200)
	assert_bool(theory.is_turning()).is_false()
	assert_bool(theory._leaf.visible).is_false()
	assert_int(theory.page_shown).is_greater(1)
	assert_str(theory._folios[0].text).is_equal(str(theory.page_shown))
	assert_str(theory._folios[1].text).is_equal(str(theory.page_shown + 1))
	var early: float = theory._interval
	assert_float(early).is_less(SchoolTheory.TURN_FIRST)
	# Later on, the leaves come many times faster.
	theory.elapsed = SchoolTheory.HOLD + SchoolTheory.LAST_TURN * 0.75
	await runner.simulate_frames(30, 16)
	assert_int(theory.turns).is_greater(5)
	assert_float(theory._interval).is_less(early / 4.0)
	assert_bool(theory.is_asking()).is_false()
	# Then the riffle slows, and the last leaf lands on the end: the last page of a lap of the
	# text on the left, numbered 211, and the end on the right, 212, numbered on from it.
	assert_bool(theory.is_ended()).is_false()
	# The plan: no leaf runs over into the next, the page numbers only go up, and the slowing
	# counts on a spread a leaf to the end's.
	for i: int in theory._plan.at.size() - 1:
		var lands: float = theory._plan.at[i] + theory._plan.lasting[i]
		assert_float(lands).is_less_equal(theory._plan.at[i + 1] + 0.0001)
		assert_int(theory._plan.folio[i + 1]).is_greater_equal(theory._plan.folio[i] + 2)
	assert_int(theory._plan.folio[theory._plan.folio.size() - 1]).is_equal(SchoolTheory.PAGES - 1)
	# The first leaves, slow enough to read, go on a spread at a time.
	for i: int in 3:
		assert_int(theory._plan.folio[i]).is_equal(3 + i * 2)
	theory.elapsed = SchoolTheory.HOLD + SchoolTheory.LAST_TURN
	for i: int in 120:
		await runner.simulate_frames(1, 16)
		if theory.is_ended():
			break
	assert_bool(theory.is_ended()).is_true()
	await await_millis(int(SchoolTheory.TURN_SLOWEST * 1000.0) + 200)
	assert_bool(theory.is_turning()).is_false()
	assert_str(theory._folios[0].text).is_equal(str(SchoolTheory.PAGES - 1))
	assert_str(theory._folios[1].text).is_equal(str(SchoolTheory.PAGES))
	var end_words := _words_in(theory._columns[SchoolTheory.RIGHT])
	assert_str(end_words).contains(TheoryText.CLOSING_RULE)
	assert_str(end_words).contains(TheoryText.THE_END.to_upper())
	var left_words := _words_in(theory._columns[SchoolTheory.LEFT])
	var end_section := int(end_words.get_slice("§ ", 1).get_slice(".", 0))
	var left_section := int(left_words.get_slice("§ ", left_words.count("§ ")).get_slice(".", 0))
	assert_int(end_section).is_equal(left_section + 1)
	# Nothing skipped on the way: the page across from the end is the one after the last.
	assert_int(theory._final_left).is_equal(theory._text_page(theory._spread))
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
	# The podium's karts wear what they wore in the match: the player's plate, the bot's, and
	# nothing for a kart with none.
	var podium := ResultsPodium.create()
	add_child(podium)
	podium.show_top([without.slots[0], without.slots[2], without.slots[1]])
	assert_int(podium._karts.size()).is_equal(3)
	var on_step := podium._karts[0].find_child("Plate", true, false)
	assert_object(on_step).is_not_null()
	assert_str(on_step.get_meta(&"plate")).is_equal("TLT-123")
	var bots_step := podium._karts[1].find_child("Plate", true, false)
	assert_object(bots_step).is_not_null()
	assert_str(bots_step.get_meta(&"plate")).is_equal(worn)
	assert_object(podium._karts[2].find_child("Plate", true, false)).is_null()
	podium.queue_free()
	(
		assert_int(
			without.slots[0].kart.get_node("Body").find_children("Plate", "", false, false).size()
		)
		. is_equal(1)
	)
	# The settings' tab: the card as the settings keep it, and the plate typed cleaned.
	var room: Control = auto_free(Control.new())
	room.size = Vector2(1280.0, 720.0)
	add_child(room)
	var tab := LicenseTab.make(Game.settings)
	room.add_child(tab)
	await await_idle_frame()
	var card: LicenseCard = tab.find_child("LicenseCard", true, false)
	assert_object(card).is_not_null()
	assert_object(tab.retake).is_not_null()
	assert_str(card.holder_name).is_equal("Tail Light Tim")
	assert_bool(card.stamped).is_true()
	assert_bool(card.endorsements["KO"]).is_true()
	assert_bool(card.endorsements["ITEMS"]).is_false()
	tab.field.text = "my kart!!"
	tab.field.text_changed.emit(tab.field.text)
	assert_str(Game.settings.license_plate).is_equal("MY KART")
	assert_str(tab.field.text).is_equal("MY KART")
	# A space typed at the end stands while the plate is typed into, and goes once it is left.
	tab.field.text = "MY KART "
	tab.field.text_changed.emit(tab.field.text)
	assert_str(tab.field.text).is_equal("MY KART ")
	assert_str(Game.settings.license_plate).is_equal("MY KART")
	tab.field.focus_exited.emit()
	assert_str(tab.field.text).is_equal("MY KART")
	# A click on the card shows it in full over the screen the tab is on, as the title does, with
	# the hand's button drawn under the card; Back puts it away, and the hand's button shows it too.
	var look: Control = tab.find_child("Look", true, false)
	assert_object(look).is_not_null()
	assert_object(look.get_parent()).is_same(card.get_parent())
	var corner := LicenseCard.SIZE.x * LicenseTab.CARD_SCALE + LicenseTab.LOOK_AT.x
	assert_float(look.position.x).is_equal_approx(corner, 1.0)
	var mark: Control = look.get_child(0)
	assert_float(mark.position.x + mark.size.x * 0.5).is_equal_approx(0.0, 0.5)
	assert_float(mark.position.y + mark.size.y * 0.5).is_equal_approx(0.0, 0.5)
	assert_int(look.find_children("*", "InputGlyph", true, false).size()).is_equal(1)
	assert_str(_words_in(look).strip_edges()).is_empty()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	card.gui_input.emit(click)
	await await_idle_frame()
	assert_object(tab.view).is_not_null()
	assert_object(tab.view.get_parent()).is_same(room)
	var back := InputEventAction.new()
	back.action = &"ui_cancel"
	back.pressed = true
	tab.view._unhandled_input(back)
	await await_idle_frame()
	assert_object(tab.view).is_null()
	var hand := InputEventAction.new()
	hand.action = InputActions.JOKER_MENU
	hand.pressed = true
	tab._input(hand)
	assert_object(tab.view).is_not_null()
	tab.view.close()
	await await_idle_frame()
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
## the cursor; with none there is nothing to peek. Its button is drawn for the device last
## touched anywhere, a pad's when a pad was.
func test_the_title_peeks_the_license_earned() -> void:
	var was_keyboard := Game.last_input_keyboard
	Game.last_input_keyboard = false
	Game.settings.license_number = ""
	var bare: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(bare)
	await await_idle_frame()
	await await_idle_frame()
	assert_object(bare.find_child("LicensePeek", true, false)).is_null()
	# With none, the flyer for the school stands in its place, beside the Driving School button
	# and pointing at it, its headline blinking.
	var ad: SchoolAd = bare.find_child("SchoolAd", true, false)
	assert_object(ad).is_not_null()
	var school_button: Button = bare.find_child("DrivingSchool", true, false)
	if ad.pointing:
		assert_float(ad.position.x).is_greater(school_button.get_global_rect().end.x - 1.0)
		var middle := ad.position.y + ad.size.y * 0.5
		assert_float(middle).is_equal_approx(school_button.get_global_rect().get_center().y, 2.0)
	var first_blink := ad.headline.modulate.a
	await await_millis(300)
	assert_float(ad.headline.modulate.a).is_not_equal(first_blink)
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
	# The license earned, the flyer for the school is gone.
	assert_object(title.find_child("SchoolAd", true, false)).is_null()
	var screen := title.size
	var hidden_middle := peek.position + LicenseCard.SIZE * 0.5
	assert_float(hidden_middle.x).is_greater(screen.x - LicenseCard.SIZE.x * 0.5)
	assert_float(peek.rotation).is_less(-0.1)
	# Dimmed while it peeks, so it does not take the eye; as it is once out under the cursor.
	assert_float(peek.modulate.a).is_less(1.0)
	assert_float(peek.modulate.r).is_less(1.0)
	title._slide_license(true)
	await await_millis(int(title.LICENSE_SLIDE * 1000.0) + 150)
	assert_float(peek.modulate.a).is_equal_approx(1.0, 0.01)
	assert_float(peek.modulate.r).is_equal_approx(1.0, 0.01)
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
	# The mouse press a touch screen makes of the tap lands on the view a moment later, and does
	# not put it away.
	var made_of_the_tap := InputEventMouseButton.new()
	made_of_the_tap.button_index = MOUSE_BUTTON_LEFT
	made_of_the_tap.pressed = true
	view.gui_input.emit(made_of_the_tap)
	await await_idle_frame()
	assert_object(title.find_child("LicenseView", true, false)).is_not_null()
	var full: LicenseCard = view.find_child("LicenseFull", true, false)
	assert_object(full).is_not_null()
	# Held up on a stand the size of the card and the room round it, and no button says there is
	# a back.
	var stand: TiltedCard = view.find_child("LicenseStand", true, false)
	assert_object(stand).is_not_null()
	var picture := LicenseCard.SIZE + Vector2.ONE * TiltedCard.PAD * 2.0
	assert_float(stand.size.x).is_equal_approx(picture.x * LicenseView.FULL, 2.0)
	assert_object(view.find_child("Flip", true, false)).is_null()
	# The line under it names the pad's button, a pad being in hand, and not a click.
	var away_words := _words_in((view as LicenseView).away_line)
	assert_str(away_words).contains("to put it away")
	assert_bool(away_words.contains("Click")).is_false()
	# The card lies flat until something moves: the mouse turns it toward where it goes, the
	# right stick pushed wins over the mouse, and let go, the card settles back.
	assert_float(stand.turned().length()).is_less(0.01)
	var motion := InputEventMouseMotion.new()
	motion.global_position = stand.global_position + stand.size * Vector2(0.5, 1.0)
	stand._input(motion)
	await await_millis(400)
	assert_float(stand.turned().y).is_greater(0.8)
	assert_float(absf(stand.turned().x)).is_less(0.1)
	Input.action_press(InputActions.AIM_RIGHT, 1.0)
	await await_millis(400)
	assert_float(stand.turned().x).is_greater(0.5)
	Input.action_release(InputActions.AIM_RIGHT)
	motion.global_position = stand.global_position + stand.size * 0.5
	stand._input(motion)
	await await_millis(600)
	assert_float(stand.turned().length()).is_less(0.15)
	# Turned over on the hand's button, the back is up, the photo gone with the front; turned
	# again on a click on it, the front.
	assert_bool(full.flipped).is_false()
	var hand := InputEventAction.new()
	hand.action = InputActions.JOKER_MENU
	hand.pressed = true
	(view as LicenseView)._input(hand)
	assert_bool(stand.is_turning()).is_true()
	await await_millis(int(TiltedCard.TURN_OVER * 1000.0) + 250)
	assert_bool(stand.is_turning()).is_false()
	assert_bool(full.flipped).is_true()
	assert_bool(full._photo.visible).is_false()
	assert_object(title.find_child("LicenseView", true, false)).is_not_null()
	# The hologram on the back has the game's name round its ring.
	var seal: SealWords = full.find_child("Seal", true, false)
	assert_object(seal).is_not_null()
	assert_str(seal.top + " " + seal.bottom).is_equal("JACKPOT JUNCTION")
	var click_card := InputEventMouseButton.new()
	click_card.button_index = MOUSE_BUTTON_LEFT
	click_card.pressed = true
	stand._on_input(click_card)
	await await_millis(int(TiltedCard.TURN_OVER * 1000.0) + 250)
	assert_bool(full.flipped).is_false()
	assert_bool(full._photo.visible).is_true()
	var back := InputEventAction.new()
	back.action = &"ui_cancel"
	back.pressed = true
	title._unhandled_input(back)
	await await_idle_frame()
	assert_object(title.find_child("LicenseView", true, false)).is_null()
	# The hand's button shows it too, its glyph in the bottom right corner, and Back puts it away.
	var glyph: Control = title.find_child("LicenseGlyph", true, false)
	assert_object(glyph).is_not_null()
	assert_object(glyph.get_parent()).is_same(title)
	assert_int((glyph.get_child(0) as InputGlyph).kind).is_not_equal(InputGlyph.Kind.KEY)
	Game.last_input_keyboard = was_keyboard
	title._input(hand)
	await await_idle_frame()
	assert_object(title.find_child("LicenseView", true, false)).is_not_null()
	title._unhandled_input(back)
	await await_idle_frame()
	assert_object(title.find_child("LicenseView", true, false)).is_null()
	# Without a license, the Garage asks for one like the ways in to playing do, and Back puts
	# the question away with the cursor back on the button that asked.
	Game.settings.license_number = ""
	var garage: Button = title.find_child("Garage", true, false)
	garage.grab_focus()
	garage.pressed.emit()
	assert_object(title.find_child("LicenseOffer", true, false)).is_not_null()
	title._unhandled_input(back)
	await await_idle_frame()
	assert_object(title.find_child("LicenseOffer", true, false)).is_null()
	assert_object(title.get_viewport().gui_get_focus_owner()).is_same(garage)
	# Drive anyway, with the question of how to drive after it: that question put away leaves
	# the cursor on a button of the title, not on nothing.
	Game.settings.drive_modes = ["", "", "", ""]
	garage.pressed.emit()
	var asked := [0]
	var offer: ConfirmPane = title.find_child("LicenseOffer", true, false)
	offer.no_button().pressed.emit()
	await await_idle_frame()
	var choice: DriveChoice = title.find_child("DriveChoice", true, false)
	if choice == null:
		choice = DriveChoice.ask(title, func() -> void: asked[0] += 1)
		await await_idle_frame()
	choice._unhandled_input(back)
	await await_idle_frame()
	var focused := title.get_viewport().gui_get_focus_owner()
	assert_object(focused).is_not_null()
	assert_bool(focused is Button).is_true()
	assert_int(asked[0]).is_equal(0)


## A click on the flyer for the school is a choice of it, as the button is.
func test_a_click_on_the_school_flyer_chooses_it() -> void:
	var ad: SchoolAd = auto_free(SchoolAd.new())
	add_child(ad)
	await await_idle_frame()
	var chose := [0]
	ad.chosen.connect(func() -> void: chose[0] += 1)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	ad._on_input(click)
	assert_int(chose[0]).is_equal(1)
	assert_float(ad.size.x).is_greater(SchoolAd.POINTER)
	# Fitted to the room beside the button: as it is with room to spare, its words wrapped in less,
	# the L with its pointer alone in less still, and nothing in none.
	assert_bool(ad.fit_into(1000.0)).is_true()
	var natural := ad.size.x
	assert_bool(ad._words.visible).is_true()
	assert_bool(ad.fit_into(natural - 60.0)).is_true()
	await await_idle_frame()
	assert_bool(ad._words.visible).is_true()
	assert_float(ad.size.x).is_less_equal(natural - 59.0)
	assert_bool(ad.fit_into(120.0)).is_true()
	await await_idle_frame()
	assert_bool(ad._words.visible).is_false()
	assert_float(ad.size.x).is_less_equal(120.0)
	assert_bool(ad.fit_into(40.0)).is_false()


## The accept button opens the shut book too, as a click on it does.
func test_the_accept_button_opens_the_book() -> void:
	var school := await _open()
	school.enrollment.enroll.pressed.emit()
	await await_idle_frame()
	var theory := school.theory
	assert_bool(theory.is_waiting()).is_true()
	var accept := InputEventAction.new()
	accept.action = &"ui_accept"
	accept.pressed = true
	theory._unhandled_input(accept)
	assert_bool(theory.is_waiting()).is_false()
	assert_bool(theory.is_opening()).is_true()


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
	# The pause button asks first, as Back does, the book held still under the question; Back
	# again is Stay.
	var pause := InputEventAction.new()
	pause.action = InputActions.PAUSE
	pause.pressed = true
	school._unhandled_input(pause)
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


## On a touch screen the license peeking in does not slide under a finger, there being no hover:
## the tap shows it in full on the spot.
func test_on_a_touch_screen_the_tap_shows_the_license_and_nothing_slides() -> void:
	var was_touch := TouchInput.enabled
	TouchInput.enabled = true
	Game.settings.license_number = "JJ-224123"
	Game.settings.license_date = "2026-10-02"
	Game.settings.license_holder = "Tail Light Tim"
	var title: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(title)
	await await_idle_frame()
	TouchInput.enabled = was_touch
	var peek: LicenseCard = title.find_child("LicensePeek", true, false)
	assert_object(peek).is_not_null()
	assert_int(peek.mouse_entered.get_connections().size()).is_equal(0)
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	title._on_license_input(tap)
	await await_idle_frame()
	assert_object(title.find_child("LicenseView", true, false)).is_not_null()


## A phone turns the card the way it is tilted from how it was held as the card came up, GAME.md
## 3.8: the right side dipping brings the right edge forward, the bottom dipping the bottom edge,
## all the way at half of gravity; held still, or with no sensor to read, the card lies flat.
func test_a_phone_tilted_turns_the_card() -> void:
	var held := Vector3(0.0, -6.9, -6.9)
	assert_bool(TiltedCard.tilt_of_phone(held, held).is_zero_approx()).is_true()
	assert_bool(TiltedCard.tilt_of_phone(Vector3.ZERO, Vector3.ZERO).is_zero_approx()).is_true()
	var right_down := TiltedCard.tilt_of_phone(held + Vector3(2.45, 0.0, 0.0), held)
	assert_float(right_down.x).is_equal_approx(0.5, 0.01)
	assert_float(right_down.y).is_equal_approx(0.0, 0.01)
	var bottom_down := TiltedCard.tilt_of_phone(held + Vector3(0.0, -4.9, 0.0), held)
	assert_float(bottom_down.y).is_equal_approx(1.0, 0.01)
	var far := TiltedCard.tilt_of_phone(held + Vector3(-20.0, 0.0, 0.0), held)
	assert_float(far.x).is_equal_approx(-1.0, 0.01)


## On a touch screen the menu button in the corner asks whether to leave on every page: the book
## and the quiz are put up after it, and would take its touches were it left under them.
func test_the_touch_menu_button_stays_over_the_book_and_the_quiz() -> void:
	var was_touch := TouchInput.enabled
	TouchInput.enabled = true
	var school := await _open()
	TouchInput.enabled = was_touch
	var menu: Button = school.get_node_or_null("Menu")
	assert_object(menu).is_not_null()
	school.enrollment.enroll.pressed.emit()
	await await_idle_frame()
	assert_int(school.page).is_equal(DrivingSchool.Page.THEORY)
	assert_int(menu.get_index()).is_greater(school.theory.get_index())
	menu.pressed.emit()
	assert_bool(school.is_asking_to_leave()).is_true()
	school.stay()
	school._on_theory_done()
	await await_idle_frame()
	assert_int(school.page).is_equal(DrivingSchool.Page.QUIZ)
	assert_int(menu.get_index()).is_greater(school.quiz.get_index())
	menu.pressed.emit()
	assert_bool(school.is_asking_to_leave()).is_true()


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


## The words of every label under [param node], run together.
static func _words_in(node: Node) -> String:
	var words: Array[String] = []
	if node is Label:
		words.append((node as Label).text)
	for child: Node in node.get_children():
		words.append(_words_in(child))
	return " ".join(words)


## The title's Tutorial goes to the school, and the school's end to the driving test.
func test_the_school_stands_before_the_driving_test() -> void:
	assert_str(Game.DRIVING_SCHOOL_SCENE).contains("driving_school")
	assert_str(Game.TUTORIAL_SCENE).contains("tutorial.tscn")
	var school := await _open()
	assert_bool(school.then.is_valid()).is_true()
	assert_str(school.then.get_method()).is_equal("go_to_driving_test")


## On a touch screen the shut book's corner shows a finger tapping, GAME.md 8.3, and the mouse a
## phone makes out of every touch does not turn it into a mouse.
func test_on_a_touch_screen_the_book_shows_a_finger() -> void:
	var was_touch := TouchInput.enabled
	TouchInput.enabled = true
	var school := await _open()
	school.enrollment.enroll.pressed.emit()
	await await_idle_frame()
	TouchInput.enabled = was_touch
	var theory := school.theory
	var finger := func() -> bool:
		var glyphs := theory._open_mark.find_children("*", "InputGlyph", true, false)
		return glyphs.size() == 1 and (glyphs[0] as InputGlyph).kind == InputGlyph.Kind.FINGER
	assert_bool(finger.call()).is_true()
	var made := InputEventMouseMotion.new()
	made.device = InputEvent.DEVICE_ID_EMULATION
	theory._input(made)
	assert_bool(finger.call()).override_failure_message("a touch's mouse took over").is_true()
	theory._input(InputEventMouseMotion.new())
	assert_bool(finger.call()).override_failure_message("a real mouse did not").is_false()
