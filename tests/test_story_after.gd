extends GdUnitTestSuite
## After the ending, STORY.md 8.6 and 9: the license the Operator's, on its face and its back and
## after a retake; the title's Clock in, its green line and its seal; and the story's switch putting
## all of it back as the Department had it.

const TITLE_SCENE := preload("res://scenes/ui/title.tscn")

var _was_story := StoryState.new()
var _was_number := ""
var _was_settings_number := ""


func before_test() -> void:
	var profile := Game.settings.profile
	_was_story = profile.story
	_was_number = profile.license_number
	_was_settings_number = Game.settings.license_number
	profile.story = StoryState.new()
	profile.story.final_hand = "2026-10-07"
	profile.story.shifts = 12
	profile.license_number = "JJ-212212"
	Game.settings.license_number = "JJ-212212"


func after_test() -> void:
	var profile := Game.settings.profile
	profile.story = _was_story
	profile.license_number = _was_number
	Game.settings.license_number = _was_settings_number
	Story.override = -1


## The Operator's license: the House's stamp dated the day it came down, the holder as examiner,
## and the same on a card issued again at a retake; before the ending, the Department's.
func test_the_license_is_the_operators() -> void:
	Story.override = Story.Stage.OPERATOR
	var earned: Dictionary[String, bool] = {}
	var card: LicenseCard = auto_free(
		LicenseCard.create("Ada", "JJ-1", "2026-01-01", 0, null, earned)
	)
	assert_str(card.approved).is_equal("2026-10-07")
	assert_str(card.examiner).is_equal("Ada")
	var held: LicenseCard = auto_free(LicenseCard.from_settings())
	assert_str(held.approved).is_equal("2026-10-07")
	Story.override = Story.Stage.CANDIDATE
	var before: LicenseCard = auto_free(
		LicenseCard.create("Ada", "JJ-1", "2026-01-01", 0, null, earned)
	)
	assert_str(before.approved).is_empty()
	assert_str(before.examiner).is_equal(LicenseCard.EXAMINER)


## The Operator's title: Clock in where Play was, the green line along the foot, and the seal's new
## fine print; Play and none of the rest with the story switched off.
func test_the_title_is_the_operators_until_switched_off() -> void:
	Story.override = Story.Stage.OPERATOR
	var title: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(title)
	await await_idle_frame()
	var play: Button = title.get("play_button")
	assert_str(play.text).is_equal("Clock in")
	assert_bool(play.pressed.get_connections().is_empty()).is_false()
	var line: HBoxContainer = title.find_child("StatusLine", true, false)
	assert_object(line).is_not_null()
	var said := (line.get_child(0) as Label).text
	assert_str(said).is_equal("OPERATOR JJ-212212 · SHIFT 12 · STATUS NORMAL")
	# In the tagline's place under the name, and its cursor fades rather than going, so the line
	# holds still as it blinks.
	assert_object(line.get_parent()).is_same(play.get_parent())
	var cursor := line.get_node("Cursor") as Control
	await get_tree().create_timer(0.7).timeout
	assert_bool(cursor.visible).is_true()
	assert_float(cursor.self_modulate.a).is_equal(0.0)
	var mark: LogoArt = title.find_children("*", "LogoArt", true, false)[0]
	assert_str(mark.fine_print).is_equal(StoryLines.SEAL_AFTER)
	assert_object(title.find_child("HouseAd", true, false)).is_null()
	# Switched off: the casino of stage 0, after the ending too.
	Story.override = -1
	Game.settings.profile.story.on = false
	var off: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(off)
	await await_idle_frame()
	assert_str((off.get("play_button") as Button).text).is_equal("Play")
	assert_object(off.find_child("StatusLine", true, false)).is_null()
	assert_object(off.find_child("FolderPeek", true, false)).is_null()
	var plain: LicenseCard = auto_free(LicenseCard.from_settings())
	assert_str(plain.approved).is_empty()
