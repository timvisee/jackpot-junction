extends GdUnitTestSuite
## The House's letters, STORY.md 6.11: one at the title as stages 2, 3 and 4 begin and the duties
## after the ending, the last owed shown and the rest filed with it, each filed in Kit's folder
## before the first note of its stage, filled in for the profile, the profile notice with the class
## its whole record comes closest to.


func after_test() -> void:
	StoryLetters.again = false


func _licensed(seconds := 0.0) -> Profile:
	var profile := Profile.new()
	profile.license_number = "JJ-212212"
	profile.story.seconds = seconds
	return profile


## Owed by the stages reached, none before the second, with the story off or before the license;
## the last owed is the one shown, and putting it away files them all.
func test_a_letter_as_each_stage_begins() -> void:
	var profile := _licensed(Story.STAGE_STARTS[Story.Stage.PLAYER])
	assert_array(StoryLetters.owed(profile)).is_empty()
	profile.story.seconds = Story.STAGE_STARTS[Story.Stage.PARTICIPANT]
	assert_array(StoryLetters.owed(profile)).is_equal([&"statement"])
	# Headless, nothing is shown unless a test asks.
	assert_str(String(StoryLetters.due(profile))).is_empty()
	StoryLetters.again = true
	assert_str(String(StoryLetters.due(profile))).is_equal("statement")
	profile.story.seconds = Story.STAGE_STARTS[Story.Stage.CANDIDATE]
	assert_array(StoryLetters.owed(profile)).is_equal(
		[&"statement", &"profile_notice", &"your_table"]
	)
	assert_str(String(StoryLetters.due(profile))).is_equal("your_table")
	StoryLetters.file_owed(profile)
	assert_array(StoryLetters.owed(profile)).is_empty()
	profile.story.final_hand = "2026-10-16"
	assert_array(StoryLetters.owed(profile)).is_equal([&"duties"])
	profile.story.on = false
	assert_array(StoryLetters.owed(profile)).is_empty()
	var learner := Profile.new()
	learner.story.seconds = 99999.0
	assert_array(StoryLetters.owed(learner)).is_empty()


## Kept in the profile's file by key.
func test_the_letters_are_kept() -> void:
	var profile := _licensed(Story.STAGE_STARTS[Story.Stage.NUMBER])
	StoryLetters.file_owed(profile)
	profile.story.declined = 4
	var file := ConfigFile.new()
	profile.story.write(file)
	var read := StoryState.new()
	read.read(file)
	assert_array(Array(read.letters)).is_equal(["statement", "profile_notice"])
	assert_int(read.declined).is_equal(4)


## Filled in for the profile: the statement's counts, the House's count of terms answering the
## stub's, and the profile notice's class, its share and its line.
func test_the_letters_are_filled_in() -> void:
	var profile := _licensed()
	profile.story.invited = true
	profile.story.maps = 3
	profile.story.jokers = 5
	profile.story.declined = 2
	var said := StoryLetters.read_out(&"statement", profile)
	assert_str(said.to_upper()).contains("JJ-212212")
	# The invitation, the enrollment, three maps' seats and five jokers.
	assert_int(StoryFill.accepted_of(profile)).is_equal(10)
	assert_str(said).contains("10")
	assert_str(said.to_lower()).contains("keeps count")
	profile.stats[&"kills"] = 400.0
	profile.stats[&"seconds"] = 3600.0
	var classed := StorySlip.classify_record(profile)
	assert_str(str(classed[0])).is_equal("HUNTER")
	assert_int(int(classed[1])).is_between(34, 91)
	var notice := StoryLetters.lines_for(&"profile_notice", profile)
	var whole := ""
	for line: PackedStringArray in notice:
		whole += " ".join(line) + "\n"
	assert_str(whole).contains("HUNTER, %d%%" % int(classed[1]))
	assert_str(whole).contains(str(StoryLines.CLASS_LINES["HUNTER"]))
	assert_str(str(StorySlip.classify_record(Profile.new())[0])).is_equal(StorySlip.BALANCED)


## In the folder, each before the first note of the stage it came at, titled in Kit's pencil, and
## read out with its words.
func test_filed_among_the_notes() -> void:
	var profile := _licensed(Story.STAGE_STARTS[Story.Stage.NUMBER])
	for number: int in range(1, 9):
		StoryNotes.file(profile, number)
	StoryLetters.file_owed(profile)
	var statement := int(StoryLetters.PAGES[&"statement"])
	var notice := int(StoryLetters.PAGES[&"profile_notice"])
	assert_array(Array(NotesFolder.in_order(profile.story))).is_equal(
		[1, 2, 3, 4, 5, statement, 6, 7, 8, notice]
	)
	assert_str(StoryNotes.title_of(statement)).is_equal("Their count")
	assert_str(StoryNotes.read_out(statement, profile)).contains("Their count")


## Each letter draws, face up and face down, as the folder and the title show it.
func test_every_letter_draws() -> void:
	var profile := _licensed()
	for key: StringName in StoryLetters.KEYS:
		for down: bool in [false, true]:
			var letter: HouseLetter = auto_free(HouseLetter.of(key, profile))
			letter.face_down = down
			add_child(letter)
			await await_idle_frame()
			assert_object(letter).is_not_null()
	assert_bool(HouseLetter.is_card(&"duties")).is_true()
	assert_bool(HouseLetter.is_card(&"statement")).is_false()


## The ceremony: up over the title, nothing but its one button, and put away it files the letter
## and goes.
func test_put_away_files_the_letter() -> void:
	StoryLetters.again = true
	var profile := _licensed(Story.STAGE_STARTS[Story.Stage.PARTICIPANT])
	var holder: Control = auto_free(Control.new())
	holder.size = Vector2(1920.0, 1080.0)
	add_child(holder)
	var mail := HouseMail.over(holder, profile)
	assert_object(mail).is_not_null()
	assert_str(String(mail.key)).is_equal("statement")
	var went := [false]
	mail.put_away.connect(func() -> void: went[0] = true)
	mail.start()
	mail.come_on_now()
	assert_bool(mail.is_up()).is_true()
	mail.away.pressed.emit()
	assert_array(Array(profile.story.letters)).is_equal(["statement"])
	await await_millis(int((HouseMail.DROP + 0.6) * 1000.0))
	assert_bool(went[0]).is_true()
	# Nothing more owed, nothing more shown.
	assert_object(HouseMail.over(holder, profile)).is_null()
