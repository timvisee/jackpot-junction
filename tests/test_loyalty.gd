extends GdUnitTestSuite
## The loyalty program of GAME.md 8.9: what a profile keeps of it, when a landmark is open, and
## settling, which wins whatever is open and met, see [LoyaltyState] and [Loyalty].


## A small map of every kind of landmark: the slip road onto a Strip of two, a Department of two
## and a keystone both lead to, and two landmarks off the books, the second with a pencil road to
## the Strip's second.
func _map() -> LoyaltyMap:
	var drawn := LoyaltyMap.new()
	drawn.landmarks = [
		_landmark(&"slip", LoyaltyLandmark.District.SLIP, LoyaltyLandmark.Kind.CARD, &"", 0, true),
		_landmark(&"a", LoyaltyLandmark.District.STRIP, LoyaltyLandmark.Kind.STAT, &"banks", 2),
		_landmark(&"b", LoyaltyLandmark.District.STRIP, LoyaltyLandmark.Kind.STAT, &"driven", 100),
		_landmark(&"c", LoyaltyLandmark.District.DEPARTMENT, LoyaltyLandmark.Kind.FEAT, &"clean"),
		_landmark(&"f", LoyaltyLandmark.District.DEPARTMENT, LoyaltyLandmark.Kind.FIND),
		_landmark(&"k", LoyaltyLandmark.District.STRIP, LoyaltyLandmark.Kind.STAT, &"maps", 1),
		_landmark(
			&"one", LoyaltyLandmark.District.OFF_THE_BOOKS, LoyaltyLandmark.Kind.NOTES, &"", 1, true
		),
		_landmark(
			&"two", LoyaltyLandmark.District.OFF_THE_BOOKS, LoyaltyLandmark.Kind.FEAT, &"strange"
		),
	]
	drawn.landmark(&"k").keystone = true
	for road: Array in [
		[&"slip", &"a"],
		[&"a", &"b"],
		[&"slip", &"c"],
		[&"c", &"f"],
		[&"b", &"k"],
		[&"c", &"k"],
		[&"one", &"two"],
		[&"two", &"b"],
	]:
		drawn.join(road[0], road[1])
	return drawn


func _landmark(
	id: StringName,
	district: LoyaltyLandmark.District,
	kind: LoyaltyLandmark.Kind,
	stat: StringName = &"",
	count: float = 1.0,
	entry := false
) -> LoyaltyLandmark:
	var landmark := LoyaltyLandmark.new()
	landmark.id = id
	landmark.district = district
	landmark.kind = kind
	landmark.stat = stat
	landmark.count = count
	landmark.entry = entry
	return landmark


func _ids(won: Array[LoyaltyLandmark]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for each: LoyaltyLandmark in won:
		ids.append(each.id)
	return ids


## What a profile keeps reads back as it was written, and ids this version does not know are kept
## for one that does. Only a landmark won can be new, and whatever else a file holds is no id.
func test_the_section_reads_back_and_keeps_unknown_ids() -> void:
	var file := ConfigFile.new()
	var state := LoyaltyState.new()
	state.welcomed = true
	state.member = "4892 6955"
	assert_bool(state.win(&"a")).is_true()
	assert_bool(state.win(&"a")).is_false()
	state.win(&"from_the_future")
	state.look_at(&"a")
	assert_bool(state.do_feat(&"clean")).is_true()
	assert_bool(state.do_feat(&"clean")).is_false()
	assert_bool(state.find(&"f")).is_true()
	assert_bool(state.find(&"")).is_false()
	state.write(file)
	var read := LoyaltyState.new()
	read.read(file)
	assert_bool(read.welcomed).is_true()
	assert_str(read.member).is_equal("4892 6955")
	assert_bool(read.has_won(&"a")).is_true()
	assert_bool(read.has_won(&"from_the_future")).is_true()
	assert_bool(read.is_fresh(&"a")).is_false()
	assert_bool(read.is_fresh(&"from_the_future")).is_true()
	assert_bool(read.has_feat(&"clean")).is_true()
	assert_bool(read.has_found(&"f")).is_true()
	file.set_value(LoyaltyState.SECTION, "won", ["b", 3, "", "b"])
	file.set_value(LoyaltyState.SECTION, "fresh", ["a", "b"])
	file.set_value(LoyaltyState.SECTION, "feats", "clean")
	read.read(file)
	assert_array(Array(read.won)).contains_exactly(["b"])
	assert_array(Array(read.fresh)).contains_exactly(["b"])
	assert_array(Array(read.feats)).is_empty()


## Nothing is open before the house has welcomed the profile, however much it has played: every road
## starts at the slip road, and its landmark is the card.
func test_nothing_is_won_before_the_card() -> void:
	var profile := Profile.new()
	profile.stats = {&"banks": 50.0, &"driven": 5000.0, &"maps": 9.0}
	assert_array(Loyalty.settle(profile, _map())).is_empty()
	assert_array(Array(profile.loyalty.won)).is_empty()


## A profile from before the program has what its statistics already hold counted for it the moment
## the card opens the roads, and whatever that wins opens more in the same settling.
func test_the_card_counts_what_the_statistics_already_hold() -> void:
	var profile := Profile.new()
	profile.stats = {&"banks": 5.0, &"driven": 500.0, &"maps": 3.0}
	profile.loyalty.welcomed = true
	var won := _ids(Loyalty.settle(profile, _map()))
	assert_array(won).contains_exactly([&"slip", &"a", &"b"])
	assert_bool(profile.loyalty.is_fresh(&"b")).is_true()
	# Settled again, nothing more is won.
	assert_array(Loyalty.settle(profile, _map())).is_empty()


## A statistic reaching its count wins an open landmark and not a closed one; a closed one already
## met is won the moment a road into it is.
func test_a_closed_bet_already_met_is_won_as_its_road_is() -> void:
	var drawn := _map()
	var profile := Profile.new()
	profile.stats = {&"banks": 1.0, &"driven": 500.0}
	profile.loyalty.welcomed = true
	assert_array(_ids(Loyalty.settle(profile, drawn))).contains_exactly([&"slip"])
	assert_bool(Loyalty.is_open(profile, drawn.landmark(&"a"), drawn)).is_true()
	assert_bool(Loyalty.is_open(profile, drawn.landmark(&"b"), drawn)).is_false()
	assert_bool(Loyalty.is_met(profile, drawn.landmark(&"b"))).is_true()
	profile.stats[&"banks"] = 2.0
	assert_array(_ids(Loyalty.settle(profile, drawn))).contains_exactly([&"a", &"b"])


## A keystone opens only once every road into it is won, then asks its own bet.
func test_a_keystone_needs_every_road_in() -> void:
	var drawn := _map()
	var profile := Profile.new()
	profile.stats = {&"banks": 2.0, &"driven": 100.0, &"maps": 1.0}
	profile.loyalty.welcomed = true
	Loyalty.settle(profile, drawn)
	assert_bool(profile.loyalty.has_won(&"b")).is_true()
	assert_bool(Loyalty.is_open(profile, drawn.landmark(&"k"), drawn)).is_false()
	assert_bool(profile.loyalty.has_won(&"k")).is_false()
	profile.loyalty.do_feat(&"clean")
	assert_array(_ids(Loyalty.settle(profile, drawn))).contains_exactly([&"c", &"k"])


## A thing of Lost Property found wins its landmark once that is open.
func test_a_find_is_won_once_open() -> void:
	var drawn := _map()
	var profile := Profile.new()
	profile.loyalty.welcomed = true
	profile.loyalty.find(&"f")
	assert_array(_ids(Loyalty.settle(profile, drawn))).contains_exactly([&"slip"])
	profile.loyalty.do_feat(&"clean")
	assert_array(_ids(Loyalty.settle(profile, drawn))).contains_exactly([&"c", &"f"])


## Off the books is on the map only with the story on and a note found: its first landmark opens
## with that note, and its pencil roads open the house's landmarks as any road does.
func test_off_the_books_opens_with_the_first_note() -> void:
	var drawn := _map()
	var profile := Profile.new()
	profile.stats = {&"driven": 100.0}
	profile.loyalty.welcomed = true
	profile.loyalty.do_feat(&"strange")
	assert_array(_ids(Loyalty.settle(profile, drawn))).contains_exactly([&"slip"])
	assert_bool(Loyalty.is_open(profile, drawn.landmark(&"one"), drawn)).is_false()
	profile.story.notes = PackedInt32Array([1])
	assert_array(_ids(Loyalty.settle(profile, drawn))).contains_exactly([&"one", &"two", &"b"])


## With the story off, off the books is gone: its bets do not count, and its roads open nothing,
## though what it won stays won.
func test_the_story_off_takes_off_the_books_away() -> void:
	var drawn := _map()
	var profile := Profile.new()
	profile.stats = {&"driven": 100.0}
	profile.loyalty.welcomed = true
	profile.loyalty.win(&"slip")
	profile.loyalty.win(&"one")
	profile.loyalty.win(&"two")
	profile.story.notes = PackedInt32Array([1, 2])
	profile.story.on = false
	assert_bool(Loyalty.district_open(profile, LoyaltyLandmark.District.OFF_THE_BOOKS)).is_false()
	assert_bool(Loyalty.is_open(profile, drawn.landmark(&"b"), drawn)).is_false()
	assert_bool(Loyalty.is_met(profile, drawn.landmark(&"one"))).is_false()
	assert_array(Loyalty.settle(profile, drawn)).is_empty()
	assert_bool(profile.loyalty.has_won(&"two")).is_true()
	profile.story.on = true
	assert_array(_ids(Loyalty.settle(profile, drawn))).contains_exactly([&"b"])


## The profile keeps its program in its file, beside the catalog.
func test_the_profile_keeps_it() -> void:
	var path := "user://test_loyalty_profile/1.cfg"
	var profile := Profile.at(path.get_base_dir(), "1")
	profile.loyalty.welcomed = true
	profile.loyalty.win(&"a")
	profile.save_to_disk()
	var read := Profile.at(path.get_base_dir(), "1")
	assert_bool(read.loyalty.welcomed).is_true()
	assert_bool(read.loyalty.has_won(&"a")).is_true()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
