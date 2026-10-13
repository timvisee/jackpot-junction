extends GdUnitTestSuite
## The achievements of GAME.md 8.10: the list, what a profile keeps of them, earning one, and
## settling, which earns whatever the profile's records already show, see [AchievementState] and
## [Achievements].

var _heard: Array[Array] = []


func before_test() -> void:
	_heard.clear()
	Events.achievement_earned.connect(_on_earned)


func after_test() -> void:
	Events.achievement_earned.disconnect(_on_earned)


func _on_earned(profile_id: String, id: StringName, slot: int) -> void:
	_heard.append([profile_id, id, slot])


## A profile with nothing done, kept nowhere.
func _profile() -> Profile:
	var profile := Profile.new()
	profile.id = "7"
	return profile


func _ids(earned: Array[Achievement]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for each: Achievement in earned:
		ids.append(each.id)
	return ids


## The list of GAME.md 8.10: thirty-nine, every id and name once, every group in it, the story's
## four the only hidden ones and the only pins.
func test_the_list_is_whole() -> void:
	var listed := Achievements.all()
	assert_int(listed.size()).is_equal(39)
	var ids: Array[StringName] = []
	var titles: Array[String] = []
	var groups := {}
	for each: Achievement in listed:
		assert_str(each.title).is_not_empty()
		assert_str(each.objective).is_not_empty()
		assert_bool(each.id in ids).is_false()
		assert_bool(each.title in titles).is_false()
		ids.append(each.id)
		titles.append(each.title)
		groups[each.group] = true
		assert_bool(each.hidden).is_equal(each.id in Achievements.STORY_FOUR)
		assert_bool(each.is_pin()).is_equal(each.id in Achievements.STORY_FOUR)
		assert_str(each.store_name()).is_equal(String(each.id).to_upper())
	assert_int(groups.size()).is_equal(Achievement.Group.size())


## The list keeps its groups together, in the groups' order.
func test_the_list_is_in_its_groups_order() -> void:
	var last := 0
	for each: Achievement in Achievements.all():
		assert_int(each.group).is_greater_equal(last)
		last = each.group


## The counts the rules keep by hand agree with the game's own.
func test_the_counts_agree_with_the_game() -> void:
	assert_int(Achievements.ENDORSEMENTS).is_equal(TutorialFight.ENDORSEMENTS.size())
	assert_int(Achievements.DRESS_PARTS).is_equal(KartStyle.CHOICES.size() + 1)
	assert_int(Achievements.joker_ids().size()).is_equal(35)
	assert_int(Achievements.item_ids().size()).is_equal(11)
	assert_int(Achievements.house_landmarks().size()).is_equal(30)


## The section reads back as it was written, and keeps ids this version does not know.
func test_the_section_reads_back_and_keeps_unknown_ids() -> void:
	var state := AchievementState.new()
	state.earn(&"bank_shot", 1700000000)
	state.earn(&"from_the_future", 1700000100)
	state.look_at(&"from_the_future")
	state.credited = true
	var file := ConfigFile.new()
	state.write(file)
	var read := AchievementState.new()
	read.read(file)
	assert_int(read.when(&"bank_shot")).is_equal(1700000000)
	assert_bool(read.has(&"from_the_future")).is_true()
	assert_bool(read.is_fresh(&"bank_shot")).is_true()
	assert_bool(read.is_fresh(&"from_the_future")).is_false()
	assert_bool(read.credited).is_true()


## An achievement is earned once: new, said once with the seat, and never again.
func test_one_is_earned_once() -> void:
	var profile := _profile()
	assert_bool(Achievements.earn(profile, &"bank_shot", 2)).is_true()
	assert_bool(Achievements.earn(profile, &"bank_shot", 2)).is_false()
	assert_bool(profile.achievements.has(&"bank_shot")).is_true()
	assert_bool(profile.achievements.is_fresh(&"bank_shot")).is_true()
	assert_int(profile.achievements.when(&"bank_shot")).is_greater(0)
	assert_array(_heard).is_equal([["7", &"bank_shot", 2]])
	assert_bool(profile.achievements.look_at(&"bank_shot")).is_true()
	assert_bool(Achievements.has_fresh(profile)).is_false()


## Earned quietly, nothing is said; and one this version does not have is not earned at all.
func test_quiet_and_unknown() -> void:
	var profile := _profile()
	assert_bool(Achievements.earn(profile, &"parry", -1, true)).is_true()
	assert_bool(Achievements.earn(profile, &"no_such_thing")).is_false()
	assert_array(_heard).is_empty()


## The license earns Street Legal, and Honor Roll only with all seven endorsements on it.
func test_the_license() -> void:
	var profile := _profile()
	assert_array(_ids(Achievements.settle(profile))).is_empty()
	profile.license_number = "JJ-123456"
	profile.license_endorsements = PackedStringArray(["KO", "MULT 4", "JACKPOT"])
	assert_array(_ids(Achievements.settle(profile))).contains_exactly([&"street_legal"])
	profile.license_endorsements = PackedStringArray(TutorialFight.ENDORSEMENTS)
	assert_array(_ids(Achievements.settle(profile))).contains_exactly([&"honor_roll"])


## Full Deck and Toybox read the catalog, with a bar of how many have been found.
func test_the_catalog() -> void:
	var profile := _profile()
	var deck := Achievements.find(&"full_deck")
	for i: int in 34:
		profile.catalog.take_joker(Achievements.joker_ids()[i])
	assert_that(Achievements.progress(profile, deck)).is_equal(Vector2i(34, 35))
	assert_bool(Achievements.met(profile, deck)).is_false()
	profile.catalog.take_joker(Achievements.joker_ids()[34])
	for item: StringName in Achievements.item_ids():
		profile.catalog.use_item(item)
	assert_array(_ids(Achievements.settle(profile))).contains_exactly([&"full_deck", &"toybox"])


## Dressed to the Nines wants all seven parts, none plain and none None, the card back among them.
func test_the_dress() -> void:
	var profile := _profile()
	var dressed := Achievements.find(&"dressed_to_the_nines")
	# Stripes, a cap, a pennant, no trail at all, the gold plate and chalk marks.
	profile.kart_styles[0] = PackedInt32Array([1, 1, 1, 3, 1, 1])
	assert_that(Achievements.progress(profile, dressed)).is_equal(Vector2i(5, 7))
	profile.kart_styles[0] = PackedInt32Array([1, 1, 1, 1, 1, 1])
	assert_that(Achievements.progress(profile, dressed)).is_equal(Vector2i(6, 7))
	assert_bool(Achievements.met(profile, dressed)).is_false()
	profile.loyalty.card_back = 1
	assert_bool(Achievements.met(profile, dressed)).is_true()


## The loyalty program: a district won whole, the House's map won whole, and a lap.
func test_the_program() -> void:
	var profile := _profile()
	var street := Achievements.find(&"know_every_street")
	for each: LoyaltyLandmark in Achievements.landmarks_of([LoyaltyLandmark.District.DEPARTMENT]):
		profile.loyalty.win(each.id)
	assert_that(Achievements.progress(profile, street)).is_equal(Vector2i(14, 14))
	assert_array(_ids(Achievements.settle(profile))).contains_exactly([&"know_every_street"])
	for each: LoyaltyLandmark in Achievements.house_landmarks():
		profile.loyalty.win(each.id)
	assert_array(_ids(Achievements.settle(profile))).contains_exactly([&"most_valued_member"])
	profile.loyalty.laps = 1
	assert_array(_ids(Achievements.settle(profile))).contains_exactly([&"lap_of_luxury"])


## Kit's district counts toward Know Every Street only with the story on.
func test_kits_district_only_with_the_story() -> void:
	var profile := _profile()
	for each: LoyaltyLandmark in Achievements.landmarks_of(
		[LoyaltyLandmark.District.OFF_THE_BOOKS]
	):
		profile.loyalty.win(each.id)
	profile.story.on = false
	assert_bool(Achievements.met(profile, Achievements.find(&"know_every_street"))).is_false()
	profile.story.on = true
	assert_bool(Achievements.met(profile, Achievements.find(&"know_every_street"))).is_true()


## The story's four, from its records, only with the story on, and earned as it comes back on.
func test_the_story_four() -> void:
	var profile := _profile()
	profile.story.on = false
	profile.story.notes = PackedInt32Array(range(1, Story.NOTE_COUNT + 1))
	profile.story.final_hand = "2026-10-13"
	profile.story.shifts = 1
	assert_array(_ids(Achievements.settle(profile))).is_empty()
	profile.story.on = true
	assert_array(_ids(Achievements.settle(profile))).contains_exactly(
		[&"off_the_books", &"terms_accepted", &"employee_of_the_month", &"a_fresh_start"]
	)


## The loose notes of the program are no part of A Fresh Start.
func test_a_fresh_start_is_the_storys_notes() -> void:
	var profile := _profile()
	profile.story.notes = PackedInt32Array(range(1, Story.NOTE_COUNT))
	profile.story.notes.append_array(PackedInt32Array([101, 102, 103]))
	assert_bool(Achievements.met(profile, Achievements.find(&"a_fresh_start"))).is_false()
	assert_bool(Achievements.met(profile, Achievements.find(&"off_the_books"))).is_true()


## A moment of a map is never read off the records.
func test_a_moment_is_not_a_record() -> void:
	var profile := _profile()
	profile.stats[&"maps_won"] = 100.0
	profile.stats[&"pit_deaths"] = 100.0
	for id: StringName in [&"flawless", &"a_pit_do_not", &"bank_shot"]:
		assert_bool(Achievements.met(profile, Achievements.find(id))).is_false()


## The profile keeps its achievements in its file, beside its program.
func test_the_profile_keeps_them() -> void:
	var path := "user://test_achievements_profile/1.cfg"
	var profile := Profile.at(path.get_base_dir(), "1")
	profile.achievements.earn(&"long_shot", 1700000000)
	profile.save_to_disk()
	var read := Profile.at(path.get_base_dir(), "1")
	assert_int(read.achievements.when(&"long_shot")).is_equal(1700000000)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path.get_base_dir()))


## Every achievement has a picture of its own, and every pin a shape of its own.
func test_every_one_has_its_picture() -> void:
	var drawn := AchievementIcons.known()
	for each: Achievement in Achievements.all():
		assert_bool(each.id in drawn).override_failure_message(String(each.id)).is_true()
	assert_int(drawn.size()).is_equal(Achievements.all().size())
	var shapes: Array[PackedVector2Array] = []
	for id: StringName in Achievements.STORY_FOUR:
		var shape := AchievementArt.pin_shape(id, Vector2.ZERO, 1.0)
		assert_bool(shape in shapes).is_false()
		shapes.append(shape)


## A profile from before achievements is credited quietly with what its records hold, once; after
## that what its records show is earned as ever, and said.
func test_a_profile_from_before_is_credited_quietly() -> void:
	var profile := _profile()
	profile.license_number = "JJ-123456"
	profile.story.notes = PackedInt32Array([1])
	var credited := Achievements.arrive(profile)
	assert_array(_ids(credited)).contains_exactly([&"street_legal", &"off_the_books"])
	assert_bool(profile.achievements.credited).is_true()
	assert_array(_heard).is_empty()
	assert_bool(profile.achievements.is_fresh(&"street_legal")).is_true()
	profile.license_endorsements = PackedStringArray(TutorialFight.ENDORSEMENTS)
	assert_array(_ids(Achievements.arrive(profile, 1))).contains_exactly([&"honor_roll"])
	assert_array(_heard).is_equal([["7", &"honor_roll", 1]])
