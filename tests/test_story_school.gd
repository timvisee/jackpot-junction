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
