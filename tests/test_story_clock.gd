extends GdUnitTestSuite
## The story's clock and its stages, STORY.md 5: a profile moves through the story by the time it
## spends on maps once it has a license, its screens show the stage it has reached unless its story
## is switched off, and none of it is written headless.

const PATH := "user://test_story_clock.cfg"


func after_test() -> void:
	Story.override = -1
	Story.final_hand_now = false
	Settings.remove_files(PATH)


func _settings() -> Settings:
	var settings := Settings.new()
	settings.path = PATH
	settings.load_from_disk()
	return settings


func _licensed() -> Profile:
	var profile := Profile.new()
	profile.license_number = "JJ-123456"
	return profile


## Every stage begins where 5.1 says, and nothing moves before the license.
func test_the_stages_begin_at_their_minutes() -> void:
	var learner := Profile.new()
	learner.story.seconds = 99999.0
	assert_int(Story.stage_of(learner)).is_equal(Story.Stage.CUSTOMER)
	var profile := _licensed()
	var expected := {
		0.0: Story.Stage.CUSTOMER,
		599.0: Story.Stage.CUSTOMER,
		600.0: Story.Stage.PLAYER,
		2399.0: Story.Stage.PLAYER,
		2400.0: Story.Stage.PARTICIPANT,
		4500.0: Story.Stage.NUMBER,
		6600.0: Story.Stage.CANDIDATE,
		9600.0: Story.Stage.CANDIDATE,
	}
	for seconds: float in expected:
		profile.story.seconds = seconds
		assert_int(Story.stage_of(profile)).override_failure_message(str(seconds)).is_equal(
			expected[seconds]
		)
	assert_bool(Story.final_hand_due(profile)).is_true()
	profile.story.final_hand = "2026-10-07"
	assert_int(Story.stage_of(profile)).is_equal(Story.Stage.OPERATOR)
	assert_bool(Story.final_hand_due(profile)).is_false()


## A map of a minute moves the clock a fifth as far as a map of five, and only maps count deaths,
## jokers and quick matches; a profile with no license, or its story off, moves not at all.
func test_maps_run_the_clock_by_their_own_time() -> void:
	var profile := _licensed()
	var slot := PlayerSlot.new(0, KartInput.new())
	slot.stats.add(&"deaths", 3.0)
	slot.stats.add(&"jokers", 2.0)
	Story.count(profile, slot, 60.0, {}, true, true)
	assert_float(profile.story.seconds).is_equal(60.0)
	Story.count(profile, slot, 300.0, {}, true, false)
	assert_float(profile.story.seconds).is_equal(360.0)
	assert_int(profile.story.maps).is_equal(2)
	assert_int(profile.story.quick_matches).is_equal(1)
	assert_int(profile.story.deaths).is_equal(6)
	assert_int(profile.story.jokers).is_equal(4)
	# Left early: the time counts, the map does not, and only what came after the last count.
	var since := LifetimeStats.share_of(slot, 100.0)
	slot.stats.add(&"deaths", 1.0)
	Story.count(profile, slot, 130.0, since, false, true)
	assert_float(profile.story.seconds).is_equal(390.0)
	assert_int(profile.story.maps).is_equal(2)
	assert_int(profile.story.deaths).is_equal(7)
	profile.story.on = false
	Story.count(profile, slot, 600.0, {}, true, true)
	assert_float(profile.story.seconds).is_equal(390.0)
	var learner := Profile.new()
	Story.count(learner, slot, 600.0, {}, true, true)
	assert_float(learner.story.seconds).is_equal(0.0)


## After the ending, every map played to the whistle is a shift.
func test_maps_after_the_ending_are_shifts() -> void:
	var profile := _licensed()
	var slot := PlayerSlot.new(0, KartInput.new())
	Story.count(profile, slot, 300.0, {}, true, true)
	assert_int(profile.story.shifts).is_equal(0)
	profile.story.final_hand = "2026-10-07"
	Story.count(profile, slot, 300.0, {}, true, false)
	Story.count(profile, slot, 50.0, {}, false, true)
	assert_int(profile.story.shifts).is_equal(1)


## The stage a screen shows: the profile playing's, the first with its story off, the first
## headless unless a test or a debug build asks for another.
func test_the_screen_shows_the_stage_unless_switched_off() -> void:
	var profile := _licensed()
	profile.story.seconds = 5000.0
	assert_int(Story.shown_of(profile)).is_equal(Story.Stage.NUMBER)
	profile.story.on = false
	assert_int(Story.shown_of(profile)).is_equal(Story.Stage.CUSTOMER)
	assert_bool(Story.final_hand_due(profile)).is_false()
	# These tests run headless, where nothing is shown of the story but what is asked for.
	assert_int(Story.stage_here()).is_equal(Story.Stage.CUSTOMER)
	assert_bool(Story.on_here()).is_false()
	Story.override = Story.Stage.CANDIDATE
	assert_int(Story.stage_here()).is_equal(Story.Stage.CANDIDATE)
	assert_bool(Story.on_here()).is_true()


## The story goes into the profile's file and comes back as it went; a profile with nothing kept
## starts at the beginning, switched on.
func test_the_story_is_kept_in_the_profile() -> void:
	var settings := _settings()
	var story := settings.profile.story
	assert_bool(story.on).is_true()
	assert_float(story.seconds).is_equal(0.0)
	assert_int(story.notes.size()).is_equal(0)
	story.on = false
	story.seconds = 1234.5
	story.maps = 7
	story.notes = PackedInt32Array([1, 2, 3])
	story.notes_read = PackedInt32Array([1])
	story.final_hand = "2026-10-07"
	story.evaluation = {"place": 3}
	settings.save_to_disk()
	var read := _settings().profile.story
	assert_bool(read.on).is_false()
	assert_float(read.seconds).is_equal(1234.5)
	assert_int(read.maps).is_equal(7)
	assert_array(Array(read.notes)).is_equal([1, 2, 3])
	assert_bool(read.is_new(2)).is_true()
	assert_bool(read.is_new(1)).is_false()
	assert_bool(read.is_new(9)).is_false()
	assert_bool(read.any_new()).is_true()
	assert_bool(read.ended()).is_true()
	assert_int(int(read.evaluation.get("place", 0))).is_equal(3)


## The License tab carries the story's switch, Story Progression, with a license or without one,
## and the switch is the profile playing's; it asks before it goes off, and Keep on keeps it on.
func test_the_license_tab_switches_the_story() -> void:
	var settings := _settings()
	var page: LicenseTab = auto_free(LicenseTab.make(settings))
	add_child(page)
	await await_idle_frame()
	assert_object(page.story_switch).is_not_null()
	assert_bool(page.story_switch.button_pressed).is_true()
	page.story_switch.button_pressed = false
	assert_object(page.question).is_not_null()
	assert_str(page.question.said()).contains("turn it back on at any time")
	assert_bool(settings.profile.story.on).is_true()
	assert_bool(page.story_switch.button_pressed).is_true()
	page.question.no_button().pressed.emit()
	assert_bool(settings.profile.story.on).is_true()
	page.story_switch.button_pressed = false
	page.question.yes_button().pressed.emit()
	assert_bool(settings.profile.story.on).is_false()
	assert_bool(page.story_switch.button_pressed).is_false()
	settings.profile.license_number = "JJ-111111"
	var licensed: LicenseTab = auto_free(LicenseTab.make(settings))
	add_child(licensed)
	await await_idle_frame()
	assert_bool(licensed.story_switch.button_pressed).is_false()
	licensed.story_switch.button_pressed = true
	assert_bool(settings.profile.story.on).is_true()


## A map played to the whistle at this machine runs the story's clock of the profile playing, and a
## room that is no map runs none.
func test_a_map_runs_the_profile_playing_clock() -> void:
	var settings := _settings()
	settings.profile.license_number = "JJ-654321"
	var real := Game.settings
	Game.settings = settings
	var match_node: Match = auto_free(preload("res://scenes/match/match.tscn").instantiate())
	match_node.with_hud = false
	var runner := scene_runner(match_node)
	match_node.start(
		[PlayerInput.new(DeviceInput.KEYBOARD, 0), KartInput.new()] as Array[KartInput], 3
	)
	await runner.simulate_frames(2, 17)
	match_node.slots[0].stats.add(&"jokers", 2.0)
	var record := MatchRecord.add_to(match_node)
	record.seconds = 180.0
	record.record()
	var story := settings.profile.story
	assert_float(story.seconds).is_equal(180.0)
	assert_int(story.maps).is_equal(1)
	assert_int(story.quick_matches).is_equal(1)
	assert_int(story.jokers).is_equal(2)
	# The lobby and the school are no maps.
	var lobby := MatchRecord.new()
	lobby.match_node = match_node
	lobby.maps = false
	lobby.seconds = 500.0
	lobby.record()
	assert_float(story.seconds).is_equal(180.0)
	lobby.free()
	Game.settings = real


## `++ --story-license` in a debug build licenses a new profile at once and keeps it, in its first
## seat's name or in one picked for it; a profile already licensed keeps the license it has.
func test_the_story_license_argument_licenses_a_new_profile() -> void:
	var settings := _settings()
	assert_bool(Story.licensed(settings.profile)).is_false()
	Story.read_arguments(PackedStringArray(["--story-license"]), settings)
	var read := _settings()
	assert_bool(Story.licensed(read.profile)).is_true()
	assert_bool(read.tutorial_done).is_true()
	assert_str(read.license_holder).is_not_empty()
	assert_str(read.seat_name(0)).is_equal(read.license_holder)
	assert_str(read.license_date).is_equal(LicenseCard.today())
	assert_str(read.license_plate).is_not_empty()
	var number := read.license_number
	Story.hand_license(read)
	assert_str(read.license_number).is_equal(number)
	Settings.remove_files(PATH)
	var named := _settings()
	named.set_seat_name(0, "Ada")
	Story.hand_license(named)
	assert_str(_settings().license_holder).is_equal("Ada")


## `++ --story-notes` hands a new profile its license and every note, kept, the ones it had not
## found new and the ones it had read still read.
func test_the_story_notes_argument_hands_every_note() -> void:
	var settings := _settings()
	settings.profile.story.notes = PackedInt32Array([3])
	settings.profile.story.notes_read = PackedInt32Array([3])
	Story.read_arguments(PackedStringArray(["--story-notes"]), settings)
	var read := _settings()
	assert_bool(Story.licensed(read.profile)).is_true()
	var story := read.profile.story
	assert_int(story.notes.size()).is_equal(Story.NOTE_COUNT)
	assert_array(Array(NotesFolder.in_order(story))).is_equal(range(1, Story.NOTE_COUNT + 1))
	assert_bool(story.is_new(3)).is_false()
	assert_bool(story.is_new(1)).is_true()
	assert_bool(story.is_new(Story.NOTE_COUNT)).is_true()
