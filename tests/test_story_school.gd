extends GdUnitTestSuite
## The driving school as the story goes, STORY.md 6.7: the terms under Enroll, the Highway Code's
## edition and the lines it revises, the book still turning to its last page, and after the ending
## the examiner's signature and somebody at the booth's window.


func after_test() -> void:
	Story.override = -1


## Under Enroll, always, the terms enrolling accepts.
func test_enrolling_accepts_the_terms() -> void:
	var holder: Control = auto_free(Control.new())
	add_child(holder)
	var page := SchoolEnrollment.add_to(holder)
	var terms: Label = page.find_child("Terms", true, false)
	assert_str(terms.text).is_equal("Enrolling accepts the terms of the Dept. of Karts.")
	assert_object(terms.get_parent()).is_same(page.enroll.get_parent())


## A new edition each stage, approved by its reader after the ending, and each revised line as it
## reads before its stage and from it.
func test_the_code_reads_as_the_story_has_come() -> void:
	Story.override = Story.Stage.CUSTOMER
	assert_str(TheoryText.new().edition()).is_equal("212th edition, abridged for karts")
	assert_str(TheoryText.edition_mark()).is_equal("212TH EDITION")
	Story.override = Story.Stage.CANDIDATE
	assert_str(TheoryText.new().edition()).is_equal("216th edition, abridged for karts")
	# The running heads, the front cover and the back's blurb say the same edition; the price
	# stays what it was.
	assert_str(TheoryText.edition_mark()).is_equal("216TH EDITION")
	assert_str(TheoryText.blurb()).contains("Revised for the 216th time")
	assert_str(TheoryText.PRICE).is_equal("212 CHIPS")
	Story.override = Story.Stage.OPERATOR
	var name := StoryFill.written_name(Game.settings.profile)
	assert_str(TheoryText.new().edition()).is_equal("217th edition, approved by " + name)
	for line: Array in StoryLines.CODE_LINES:
		Story.override = int(line[1]) - 1
		var before := _whole(TheoryText.new())
		assert_str(before).contains(str(line[0]))
		assert_str(before).not_contains(str(line[2]))
		Story.override = int(line[1])
		assert_str(_whole(TheoryText.new())).contains(str(line[2]))


## The book cuts the revised text into pages as it cut the first: no chapter's heading left at a
## page's foot, and the read still ends on its last page.
func test_the_book_still_turns_to_its_last_page() -> void:
	Story.override = Story.Stage.OPERATOR
	var holder: Control = auto_free(Control.new())
	holder.size = Vector2(1920.0, 1080.0)
	add_child(holder)
	var theory := SchoolTheory.add_to(holder)
	for i: int in 4:
		await await_idle_frame()
	assert_int(theory._page_count()).is_greater(10)
	for page: int in range(1, theory._page_first.size() - 1):
		var foot: Dictionary = theory._text.items[theory._page_first[page] - 1]
		assert_str(str(foot["kind"])).is_not_equal("chapter")
	var folios := theory._plan.folio
	assert_int(folios[folios.size() - 1]).is_equal(SchoolTheory.PAGES - 1)


## After the ending the holder signs as examiner, and somebody stands at the booth's window.
func test_after_the_ending_the_reviewing_is_the_players() -> void:
	var earned: Dictionary[String, bool] = {}
	Story.override = Story.Stage.CANDIDATE
	var before: LicenseCard = auto_free(LicenseCard.create("Ada", "JJ-1", "", 0, null, earned))
	assert_str(before.examiner).is_equal(LicenseCard.EXAMINER)
	assert_object(_booth().find_child("Watcher", false, false)).is_null()
	Story.override = Story.Stage.OPERATOR
	var after: LicenseCard = auto_free(LicenseCard.create("Ada", "JJ-1", "", 0, null, earned))
	assert_str(after.examiner).is_equal("Ada")
	assert_object(_booth().find_child("Watcher", false, false)).is_not_null()


## Every line of [param text] the book prints, its figures' captions and the colophon among them.
func _whole(text: TheoryText) -> String:
	var whole := ""
	for item: Dictionary in text.items:
		whole += text.words(item, 0) + "\n"
	var end: Control = auto_free(text.build({"kind": &"end"}, 0))
	for label: Node in end.find_children("*", "Label", true, false):
		whole += (label as Label).text + "\n"
	return whole


## The examiner's booth on its own, built at the stage there is.
func _booth() -> SchoolProps:
	var props: SchoolProps = auto_free(SchoolProps.new())
	props.surfaces = Surfaces.new(null)
	props._booth(Vector3.ZERO, props.surfaces.painted(SchoolProps.STEEL))
	return props


## The code opens on Oversight, whatever the stage and with the story off: § 1 and, under it, the
## clause kept word for word since the first edition, STORY.md 6.7.
func test_the_code_opens_on_oversight() -> void:
	for stage: int in [Story.Stage.CUSTOMER, Story.Stage.OPERATOR]:
		Story.override = stage
		var text := TheoryText.new()
		assert_str(text.words(text.items[1], 0)).is_equal("Chapter I  ·  Oversight")
		assert_str(text.words(text.items[2], 0)).is_equal("§ 1. Every table is watched.")
		assert_str(text.words(text.items[3], 0)).is_equal(
			"§ 1.1. No table shall open without human oversight."
		)


## With the story told, the quiz's fourth question is the House's, headed four of three, STORY.md
## 6.7: it stands as the others do, the cursor on its first answer, until something is picked.
## Picked from the keys or a pad with the cursor on the House's own, Yes, it lights in gold at once,
## held down, and is said; then the theory is passed, the House's question not scored.
func test_the_house_waits_and_answers_for_you() -> void:
	var quiz := _quiz()
	assert_bool(quiz.asked_by_house).is_true()
	for i: int in SchoolQuiz.QUESTIONS.size():
		quiz.answer(SchoolQuiz.QUESTIONS[i][2])
		await await_millis(int(SchoolQuiz.LINGER * 1000.0) + 150)
	assert_int(quiz.index).is_equal(SchoolQuiz.QUESTIONS.size())
	assert_str(quiz._caption.text).ends_with("4 of 3")
	assert_str(quiz._question.text).is_equal(SchoolQuiz.HOUSE_QUESTION[0])
	assert_bool(quiz.answers[0].has_focus()).is_true()
	await await_millis(int((SchoolQuiz.HOUSE_BEAT + SchoolQuiz.SWAP) * 1000.0) + 600)
	for button: Button in quiz.answers:
		assert_bool(button.disabled).is_false()
		assert_bool(button.button_pressed).is_false()
	assert_str(quiz._quip.text).is_equal(" ")
	assert_object(quiz.on).is_null()
	_send(&"ui_accept")
	var house := quiz.answers[SchoolQuiz.HOUSE_QUESTION[2]]
	assert_str(house.text).is_equal("Yes")
	assert_bool(house.button_pressed).is_true()
	assert_str(quiz._quip.text).is_equal(SchoolQuiz.HOUSE_QUIP)
	assert_str(ScreenReader.said(quiz)).is_equal("Yes " + SchoolQuiz.HOUSE_QUIP)
	for button: Button in quiz.answers:
		assert_bool(button.disabled).is_true()
	await await_millis(int(SchoolQuiz.HOUSE_LINGER * 1000.0) + 150)
	assert_object(quiz.on).is_not_null()
	assert_int(quiz.right).is_equal(SchoolQuiz.QUESTIONS.size())


## Another answer picked from the keys or a pad, No, is held down a beat, a second press doing
## nothing, and then trades places with the House's: Yes stands where No was pressed, lit in gold
## and held, No where Yes was, let go, nothing left with the cursor, and the theory passed after.
func test_the_house_trades_places_with_another_pick() -> void:
	var quiz := await _at_the_house()
	_send(&"ui_down")
	assert_bool(quiz.answers[1].has_focus()).is_true()
	var spot := quiz.answers[1].position
	_send(&"ui_accept")
	assert_str(quiz.answers[1].text).is_equal("No")
	assert_bool(quiz.answers[1].button_pressed).is_true()
	assert_str(quiz._quip.text).is_equal(" ")
	quiz.answer(2)
	assert_str(quiz.answers[2].text).is_equal("Depends")
	await await_millis(int((SchoolQuiz.HOUSE_BEAT + SchoolQuiz.SWAP) * 1000.0) + 150)
	_assert_answered(quiz, 1, spot)
	assert_str(quiz.answers[0].text).is_equal("No")
	assert_bool(quiz.answers[0].button_pressed).is_false()
	assert_bool(quiz.answers[0].has_theme_stylebox_override("disabled")).is_false()
	assert_str(quiz.answers[2].text).is_equal("Depends")
	assert_object(get_viewport().gui_get_focus_owner()).is_null()
	await await_millis(int(SchoolQuiz.HOUSE_LINGER * 1000.0) + 150)
	assert_object(quiz.on).is_not_null()
	assert_int(quiz.right).is_equal(0)


## Depends clicked with the mouse: Yes comes down past No to where the click was and lights there,
## under the mouse, and Depends goes up to the top.
func test_a_click_on_another_answer_is_answered_yes_under_the_mouse() -> void:
	var quiz := await _at_the_house()
	var spot := quiz.answers[2].position
	var at := quiz.answers[2].get_global_rect().get_center()
	_click(at)
	await await_millis(int((SchoolQuiz.HOUSE_BEAT + SchoolQuiz.SWAP) * 1000.0) + 150)
	_assert_answered(quiz, 2, spot)
	assert_bool(quiz.answers[2].get_global_rect().has_point(at)).is_true()
	assert_str(quiz.answers[0].text).is_equal("Depends")
	assert_str(quiz.answers[1].text).is_equal("No")
	# The mouse off the screen again, so a test after this one does not find it over its own.
	_point(Vector2(-100.0, -100.0))


## The pop quiz with the story told, up in a holder the size of the screen.
func _quiz() -> SchoolQuiz:
	Story.override = Story.Stage.CUSTOMER
	var holder: Control = auto_free(Control.new())
	holder.size = Vector2(1920.0, 1080.0)
	add_child(holder)
	return SchoolQuiz.add_to(holder)


## The pop quiz with the story told, put straight on the House's question and laid out.
func _at_the_house() -> SchoolQuiz:
	var quiz := _quiz()
	quiz._show(SchoolQuiz.QUESTIONS.size())
	await await_idle_frame()
	await await_idle_frame()
	assert_str(quiz._question.text).is_equal(SchoolQuiz.HOUSE_QUESTION[0])
	return quiz


## The House's answer standing at [param j] of [param quiz]'s answers, at [param spot] where the
## player's pick was, in its place among them for good, lit, held down and said, unscored.
func _assert_answered(quiz: SchoolQuiz, j: int, spot: Vector2) -> void:
	var house := quiz.answers[j]
	assert_str(house.text).is_equal("Yes")
	assert_object(quiz._answers.get_child(j)).is_same(house)
	assert_vector(house.position).is_equal_approx(spot, Vector2.ONE * 0.5)
	assert_vector(house.scale).is_equal(Vector2.ONE)
	assert_bool(house.button_pressed).is_true()
	var lit := house.get_theme_stylebox("disabled") as TicketStyle
	assert_object(lit).is_same(house.get_theme_stylebox("pressed"))
	assert_bool(lit.border.is_equal_approx(HouseTheme.FOIL)).is_true()
	assert_str(quiz._quip.text).is_equal(SchoolQuiz.HOUSE_QUIP)
	assert_str(ScreenReader.said(quiz)).is_equal("Yes " + SchoolQuiz.HOUSE_QUIP)
	assert_int(quiz.right).is_equal(0)
	for button: Button in quiz.answers:
		assert_bool(button.disabled).is_true()


## [param action] pressed and let go, as a key or a pad's button gives it, to what has the cursor.
func _send(action: StringName) -> void:
	for down: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = down
		get_viewport().push_input(event)


## The mouse moved to [param at].
func _point(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	get_viewport().push_input(motion, true)


## The mouse moved to [param at] and clicked there.
func _click(at: Vector2) -> void:
	_point(at)
	for down: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		click.position = at
		get_viewport().push_input(click, true)


## The story's marks on the license, STORY.md 6.7: told, a line scratched into the stripe and the
## fine print ending HUMAN OVERSIGHT: 0; after the ending, 1; untold, neither.
func test_the_license_is_scratched_and_overseen_by_nobody() -> void:
	var earned: Dictionary[String, bool] = {}
	assert_bool(Story.told_here()).is_false()
	var plain: LicenseCard = auto_free(LicenseCard.create("Ada", "JJ-1", "", 0, null, earned))
	assert_bool(plain.scratched).is_false()
	Story.override = Story.Stage.CUSTOMER
	var marked: LicenseCard = auto_free(LicenseCard.create("Ada", "JJ-1", "", 0, null, earned))
	assert_bool(marked.scratched).is_true()
	assert_str(StoryLines.LICENSE_SCRATCH).is_equal(
		"They're watching how you drive. Stay strange. —K."
	)
	assert_str(StoryLines.BACK_MICRO_OVERSIGHT).ends_with("HUMAN OVERSIGHT: 0")
	assert_str(StoryLines.BACK_MICRO_AFTER).ends_with("HUMAN OVERSIGHT: 1")
	# Drawn on its back, the scratches and all.
	marked.flipped = true
	add_child(marked)
	await await_idle_frame()


## The first license a machine is issued turns over by itself once held up, and back again; a
## retake's does not, STORY.md 6.7.
func test_the_first_license_shows_its_back() -> void:
	Story.override = Story.Stage.CUSTOMER
	var layer: CanvasLayer = auto_free(CanvasLayer.new())
	add_child(layer)
	var earned: Dictionary[String, bool] = {}
	var screen := LicenseScreen.add_to(layer, "Ada", "JJ-1", "", 0, null, earned, Color.WHITE)
	screen.shows_back = true
	await await_idle_frame()
	screen._look_closer()
	assert_object(screen.view).is_not_null()
	assert_bool(screen.view.card.flipped).is_false()
	await await_millis(int((LicenseScreen.BACK_AFTER + 0.9) * 1000.0))
	assert_bool(screen.view.card.flipped).is_true()
	await await_millis(int((LicenseScreen.BACK_HOLD + 0.9) * 1000.0))
	assert_bool(screen.view.card.flipped).is_false()
