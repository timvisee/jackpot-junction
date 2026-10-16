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


## With the story told, the quiz's fourth question is the House's, headed four of three: nothing
## can be pressed, and its answer lights in gold and presses itself, not scored, STORY.md 6.7.
func test_the_house_answers_its_own_question() -> void:
	Story.override = Story.Stage.CUSTOMER
	var holder: Control = auto_free(Control.new())
	holder.size = Vector2(1920.0, 1080.0)
	add_child(holder)
	var quiz := SchoolQuiz.add_to(holder)
	assert_bool(quiz.asked_by_house).is_true()
	for i: int in SchoolQuiz.QUESTIONS.size():
		quiz.answer(SchoolQuiz.QUESTIONS[i][2])
		await await_millis(int(SchoolQuiz.LINGER * 1000.0) + 150)
	assert_int(quiz.index).is_equal(SchoolQuiz.QUESTIONS.size())
	assert_str(quiz._caption.text).ends_with("4 of 3")
	assert_str(quiz._question.text).is_equal(SchoolQuiz.HOUSE_QUESTION[0])
	quiz.answer(1)
	for button: Button in quiz.answers:
		assert_bool(button.disabled).is_true()
	assert_str(quiz._quip.text).is_equal(" ")
	await await_millis(int(SchoolQuiz.HOUSE_THINK * 1000.0) + 150)
	assert_str(quiz._quip.text).is_equal(SchoolQuiz.HOUSE_QUIP)
	await await_millis(int(SchoolQuiz.LINGER * 1000.0) + 150)
	assert_object(quiz.on).is_not_null()
	assert_int(quiz.right).is_equal(SchoolQuiz.QUESTIONS.size())


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
