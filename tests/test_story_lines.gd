extends GdUnitTestSuite
## The story's lines, STORY.md 6 and 8: every table answers for every stage from the one it begins
## at, every placeholder in every line fills in, the House never mentions a note, and every joker in
## the game has its term.

## The tables keyed by stage, and the stage each begins at.
const STAGED := {
	"ads": [StoryLines.ADS, Story.Stage.PLAYER],
	"posters": [StoryLines.POSTERS, Story.Stage.CUSTOMER],
	"road": [StoryLines.ROAD, Story.Stage.CUSTOMER],
	"small print": [StoryLines.SMALL_PRINT, Story.Stage.CUSTOMER],
	"bulletins": [StoryLines.BULLETINS, Story.Stage.PARTICIPANT],
	"pick": [StoryLines.PICK, Story.Stage.PLAYER],
	"hud": [StoryLines.MICRO_HUD, Story.Stage.CUSTOMER],
	"title": [StoryLines.MICRO_TITLE, Story.Stage.CUSTOMER],
	"loading": [StoryLines.LOADING, Story.Stage.CUSTOMER],
	"stats": [StoryLines.STATS_LINE, Story.Stage.PARTICIPANT],
	"edition": [StoryLines.EDITION, Story.Stage.CUSTOMER],
	"yard": [StoryLines.YARD_SIGN, Story.Stage.CUSTOMER],
}


func _profile() -> Profile:
	var profile := Profile.new()
	profile.license_number = "JJ-123456"
	profile.license_holder = "Ann"
	profile.story.seconds = 7260.0
	profile.story.maps = 40
	profile.story.deaths = 120
	profile.story.jokers = 90
	profile.story.shifts = 3
	profile.stats[&"deaths"] = 1234.0
	profile.stats[&"coins_lost"] = 1204388.0
	profile.stats[&"drifted"] = 12345.0
	return profile


## Every string any of the tables holds, wherever it is.
func _every_line() -> Array[String]:
	var lines: Array[String] = []
	for name: String in STAGED:
		for stage: Variant in STAGED[name][0]:
			_gather(STAGED[name][0][stage], lines)
	_gather(StoryLines.FINAL_HAND_ADS, lines)
	_gather(StoryLines.EVALUATION, lines)
	_gather(StoryLines.LAST_LINE, lines)
	_gather(StoryLines.APPROVAL_RECORD, lines)
	_gather(StoryLines.TERMS.values(), lines)
	_gather(StoryLines.CLASS_LINES.values(), lines)
	for key: StringName in StoryLetters.KEYS:
		_gather(StoryLines.HOUSE_LETTERS[key]["lines"], lines)
		lines.append(str(StoryLines.HOUSE_LETTERS[key]["heading"]))
	for constant: String in [
		StoryLines.CLASSIFIED,
		StoryLines.STATUS_LINE,
		StoryLines.BACK_MICRO_AFTER,
		StoryLines.ABOUT,
		StoryLines.ENROLL,
	]:
		lines.append(constant)
	return lines


func _gather(value: Variant, into: Array[String]) -> void:
	if value is String:
		into.append(value)
	elif value is Array:
		for item: Variant in value:
			_gather(item, into)


## A line holds until a later stage changes it, and a table with nothing yet answers the default.
func test_a_line_holds_until_a_later_stage_changes_it() -> void:
	for name: String in STAGED:
		var table: Dictionary = STAGED[name][0]
		var first: int = STAGED[name][1]
		for stage: int in range(Story.Stage.CUSTOMER, Story.Stage.OPERATOR + 1):
			var line: Variant = StoryLines.at(table, stage, null)
			if stage < first:
				assert_that(line).override_failure_message("%s %d" % [name, stage]).is_null()
			else:
				assert_that(line).override_failure_message("%s %d" % [name, stage]).is_not_null()
	assert_str(StoryLines.at(StoryLines.ROAD, Story.Stage.PLAYER)).is_equal("KEEP CLEAR")
	assert_str(StoryLines.at(StoryLines.ROAD, Story.Stage.NUMBER)).is_equal("KEEP PLAYING")
	assert_str(StoryLines.at(StoryLines.PICK, Story.Stage.CUSTOMER)).is_equal("")


## Every placeholder in every line fills in, from the profile and what a match knows.
func test_every_placeholder_fills_in() -> void:
	var profile := _profile()
	var table := {
		"trait": "HUNTER",
		"place": "4TH",
		"models": "3",
		"deviation": "23",
		"beaten": "5",
		"raised": "7",
		"prediction": "WILL STAMP",
		"approved": "4,118",
		"share": "61",
		"class_line": "YOU",
	}
	for line: String in _every_line():
		var filled := StoryFill.fill(line, profile, table)
		assert_bool(filled.contains("{")).override_failure_message(filled).is_false()
	var values := StoryFill.values_for(profile)
	assert_str(values["license"]).is_equal("JJ-123456")
	assert_str(values["minutes"]).is_equal("121")
	assert_str(values["hands"]).is_equal("160")
	# The maps', the jokers' and the comebacks' terms, and the enrollment's, the license held.
	assert_str(values["accepted"]).is_equal("251")
	assert_str(values["chips_lost"]).is_equal("1,204,388")
	assert_str(values["drifted_km"]).is_equal("12.3")
	assert_str(StoryFill.values_for(Profile.new())["license"]).is_equal("LEARNER")


## A line printed in capitals has the name in capitals; one in the game's own case has it as
## written.
func test_the_name_is_printed_the_way_its_line_is() -> void:
	var profile := _profile()
	assert_str(StoryFill.fill("WELCOME BACK {name}", profile)).is_equal("WELCOME BACK ANN")
	assert_str(StoryFill.fill("{name}", profile)).is_equal("ANN")
	assert_str(StoryFill.written_name(profile)).is_equal("Ann")
	assert_str(StoryFill.fill(StoryLines.EDITION[Story.Stage.OPERATOR], profile)).is_equal(
		"217th edition, approved by Ann"
	)


## The House never mentions a note, STORY.md 7.1: no line of its speaks of one, of a folder or of
## Kit. Taking notes, the way a House watches, is another thing.
func test_no_line_of_the_house_mentions_a_note() -> void:
	for line: String in _every_line():
		var upper := line.to_upper()
		for word: String in [" A NOTE", "THE NOTE", "YOUR NOTE", "NOTES FOUND", "FOLDER", "KIT"]:
			assert_bool(upper.contains(word)).override_failure_message(line).is_false()


## Every joker in the game has its term, so a joker added without one fails here, STORY.md 6.3.
func test_every_joker_has_a_term() -> void:
	var catalog: JokerCatalog = load("res://data/jokers/catalog.tres")
	# Every one the House printed: Kit's cards are no terms of its, STORY.md 6.3.
	assert_int(catalog.printed().size()).is_equal(StoryLines.TERMS.size())
	for joker: Joker in catalog.printed():
		assert_bool(StoryLines.TERMS.has(joker.id)).override_failure_message(joker.id).is_true()


## The Highway Code's lines are revised at their stages, and only then.
func test_the_code_darkens_with_the_stages() -> void:
	var text := "Bots drive like bots. Do not take it personally. A roundabout. Go round it."
	assert_str(StoryLines.revise_code(text, Story.Stage.PARTICIPANT)).is_equal(text)
	assert_str(StoryLines.revise_code(text, Story.Stage.NUMBER)).is_equal(
		"Bots drive like you. Do not take it personally. A roundabout. Go round it."
	)
	assert_str(StoryLines.revise_code(text, Story.Stage.CANDIDATE)).ends_with(
		"Go round it. And round it."
	)


## Counts set apart in thousands, and places as the House prints them.
func test_numbers_and_places_are_printed_the_house_way() -> void:
	assert_str(StoryFill.number(0)).is_equal("0")
	assert_str(StoryFill.number(999)).is_equal("999")
	assert_str(StoryFill.number(1000)).is_equal("1,000")
	assert_str(StoryFill.number(4118920113)).is_equal("4,118,920,113")
	assert_str(StoryFill.ordinal(1)).is_equal("1ST")
	assert_str(StoryFill.ordinal(2)).is_equal("2ND")
	assert_str(StoryFill.ordinal(3)).is_equal("3RD")
	assert_str(StoryFill.ordinal(4)).is_equal("4TH")
	assert_str(StoryFill.ordinal(11)).is_equal("11TH")
	assert_str(StoryFill.ordinal(22)).is_equal("22ND")
