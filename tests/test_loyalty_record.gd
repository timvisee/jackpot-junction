extends GdUnitTestSuite
## The feats of the loyalty program of GAME.md 8.9 as they are done at this machine: in a moment, a
## cash-out, a burned card, a full hand, a pot driven off the Junction; and over a whole map, as it
## is written down; into whose profile, and off the books only with the story on, see
## [LoyaltyRecord].

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/waiting_room.tres")
const RULES: MatchRules = preload("res://data/match/waiting_room.tres")
const JOKERS: JokerCatalog = preload("res://data/jokers/catalog.tres")
const PATH := "user://test_loyalty_record.cfg"

var _runner: GdUnitSceneRunner
var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	Game.settings.player_names[0] = "Ann"
	Game.settings.save_to_disk()


func after_test() -> void:
	LoyaltyRecord.anywhere = false
	MatchRecord.anywhere = false
	Settings.remove_files(PATH)
	Game.settings = _settings_were


## A room of [param inputs], or a player here and three bots, with a record of the loyalty program's
## feats in it that keeps them.
func _room(inputs: Array[KartInput] = []) -> Match:
	if inputs.is_empty():
		inputs = [PlayerInput.new(DeviceInput.KEYBOARD, 0), BotInput.new(), BotInput.new()]
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = RULES
	match_node.arena_layout = LAYOUT
	match_node.joker_catalog = JOKERS
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start(inputs, inputs.size())
	LoyaltyRecord.add_to(match_node)
	LoyaltyRecord.anywhere = true
	return match_node


func _has(profile: Profile, id: StringName) -> bool:
	return profile.loyalty.has_feat(id)


## A cash-out at ×10 mult or more, and one of a pot of exactly seven chips, are feats the moment the
## Junction pays them.
func test_a_cash_out_counts_its_mult_and_its_chips() -> void:
	_room()
	await _runner.simulate_frames(2, 17)
	var ann := Game.settings.profile
	Events.bank_completed.emit(0, 30, 9.5, 285)
	assert_bool(_has(ann, &"cursed_cards")).is_false()
	assert_bool(_has(ann, &"patchwork")).is_false()
	Events.bank_completed.emit(0, 7, 10.0, 70)
	assert_bool(_has(ann, &"cursed_cards")).is_true()
	assert_bool(_has(ann, &"patchwork")).is_true()


## Off the books counts only with the story on, STORY.md 10; the house's feats count either way.
func test_off_the_books_counts_only_with_the_story_on() -> void:
	_room()
	await _runner.simulate_frames(2, 17)
	var ann := Game.settings.profile
	ann.story.on = false
	Events.bank_completed.emit(0, 7, 12.0, 84)
	assert_bool(_has(ann, &"cursed_cards")).is_true()
	assert_bool(_has(ann, &"patchwork")).is_false()


## A rare card burned out of the hand, from the joker menu or given up at a full pick, is a feat; a
## card of any other rarity is not.
func test_a_rare_card_burned_is_a_feat() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	var ann := Game.settings.profile
	var kart := match_node.slots[0].kart
	kart.jokers.add(JOKERS.by_id(&"payday"))
	kart.destroy_joker(0)
	assert_bool(_has(ann, &"torn_up")).is_false()
	kart.jokers.add(JOKERS.by_id(&"wild_card"))
	kart.destroy_joker(0)
	assert_bool(_has(ann, &"torn_up")).is_true()


## Eight jokers held at once is a feat, Crazy Eights; a hand full at fewer slots is not.
func test_eight_jokers_held_is_a_feat() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	var kart := match_node.slots[0].kart
	var ids: Array[StringName] = [
		&"payday",
		&"vulture",
		&"odometer",
		&"tailslide",
		&"comeback",
		&"lucky_seven",
		&"hot_streak",
		&"aimbot",
	]
	for i: int in ids.size():
		kart.jokers.add(JOKERS.by_id(ids[i]))
		await _runner.simulate_frames(1, 17)
		var crazy := _has(Game.settings.profile, &"services")
		assert_bool(crazy).is_equal(i + 1 >= 8)


## A kart that starts a cash-out and is off every Junction alive with two hundred chips or more
## still in the pot has driven off with them; fewer, or killed, it has not.
func test_driving_off_the_junction_with_the_pot() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	var ann := Game.settings.profile
	var kart := match_node.slots[0].kart
	var record := match_node.get_node("LoyaltyRecord") as LoyaltyRecord
	var pad := match_node.arena.junctions[0]
	kart.global_position = pad.global_position
	assert_bool(record._on_a_junction(kart)).is_true()
	kart.global_position = pad.global_position + Vector3(pad.radius + 3.0, 0.0, 0.0)
	assert_bool(record._on_a_junction(kart)).is_false()
	kart.pot.add_coins(150)
	Events.bank_started.emit(0)
	await _runner.simulate_frames(2, 17)
	assert_bool(_has(ann, &"walk_away")).is_false()
	kart.pot.add_coins(100)
	Events.bank_started.emit(0)
	Events.kart_killed.emit(0, 1, &"bullet")
	await _runner.simulate_frames(2, 17)
	assert_bool(_has(ann, &"walk_away")).is_false()
	Events.bank_started.emit(0)
	await _runner.simulate_frames(2, 17)
	assert_bool(_has(ann, &"walk_away")).is_true()


## The feats of a whole map: none for a map lost with a death and a few shots, and every one a map
## makes for a map of three minutes won without a death, with a good share of shots landed, without
## ever taking a joker, from behind at Last Call, and the last of a run won in every room. A joker
## taken in the map, even one gone again by its end, is no map won without one.
func test_a_whole_map_makes_its_feats() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	var ann := Game.settings.profile
	var slot := match_node.slots[0]
	var record := match_node.get_node("LoyaltyRecord") as LoyaltyRecord
	slot.stats.add(&"deaths", 1.0)
	slot.stats.add(&"bullets", 10.0)
	LoyaltyRecord.map_played(match_node, slot, ann, 300.0, {}, false)
	for id: StringName in [&"clean_record", &"paper_hat", &"marksman", &"welding_goggles"]:
		assert_bool(_has(ann, id)).is_false()
	# Counted from where the seat came in: the death and the ten shots were before it.
	slot.stats.add(&"bullets", 30.0)
	slot.stats.add(&"hits", 18.0)
	var since := {&"deaths": 1.0, &"bullets": 10.0}
	record._last_call = true
	record._leading.append(1)
	ann.loyalty.run = PackedStringArray(["workbench", "after_hours", "the_yard"])
	Events.joker_taken.emit(0, &"payday")
	LoyaltyRecord.map_played(match_node, slot, ann, 179.0, since, true)
	assert_bool(_has(ann, &"clean_record")).is_false()
	assert_bool(_has(ann, &"welding_goggles")).is_false()
	record._had_jokers.erase(0)
	LoyaltyRecord.map_played(match_node, slot, ann, 180.0, since, true)
	for id: StringName in [
		&"clean_record", &"marksman", &"welding_goggles", &"gilt_back", &"showroom"
	]:
		assert_bool(_has(ann, id)).override_failure_message(String(id)).is_true()
	# Shots were fired, so it was no map without one.
	assert_bool(_has(ann, &"paper_hat")).is_false()


## The Showroom's run, GAME.md 8.9: maps won one after another, one in each of the three rooms. A
## map lost ends it, and so does one walked out of; a room won in again starts it over from there,
## and a map won in another room neither adds to it nor ends it.
func test_the_showroom_wants_a_map_won_in_each_room_in_a_row() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	var ann := Game.settings.profile
	var slot := match_node.slots[0]
	var showroom := Loyalty.map().landmark(&"showroom")
	var played := func(room: StringName, won: bool) -> void:
		match_node.arena.room = load("res://data/rooms/%s.tres" % room)
		LoyaltyRecord.map_played(match_node, slot, ann, 300.0, {}, won)
	played.call(&"workbench", true)
	played.call(&"after_hours", true)
	assert_str(Loyalty.progress_text(ann, showroom)).is_equal("2 / 3")
	played.call(&"the_yard", false)
	assert_array(Array(ann.loyalty.run)).is_empty()
	for room: StringName in [&"workbench", &"after_hours", &"workbench", &"garage"]:
		played.call(room, true)
	assert_array(Array(ann.loyalty.run)).contains_exactly(["after_hours", "workbench"])
	assert_bool(_has(ann, &"showroom")).is_false()
	# Walked out of with the clock going, the map ends the run as a map lost does.
	var record := MatchRecord.add_to(match_node)
	MatchRecord.anywhere = true
	record.seconds = 5.0
	record.leave()
	assert_array(Array(ann.loyalty.run)).is_empty()
	for room: StringName in [&"the_yard", &"workbench", &"after_hours"]:
		played.call(room, true)
	assert_bool(_has(ann, &"showroom")).is_true()


## Every respawn pick of a map turned down, three or more, is a feat; a card taken from one is not.
func test_every_pick_turned_down() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	var ann := Game.settings.profile
	var slot := match_node.slots[0]
	Events.joker_answered.emit(0, &"")
	Events.joker_answered.emit(0, &"")
	LoyaltyRecord.map_played(match_node, slot, ann, 300.0, {}, false)
	assert_bool(_has(ann, &"kits_rag")).is_false()
	Events.joker_answered.emit(0, &"payday")
	Events.joker_answered.emit(0, &"")
	LoyaltyRecord.map_played(match_node, slot, ann, 300.0, {}, false)
	assert_bool(_has(ann, &"kits_rag")).is_false()
	# Somebody new at the seat starts the count again.
	Events.player_joined.emit(0)
	for i: int in 3:
		Events.joker_answered.emit(0, &"")
	LoyaltyRecord.map_played(match_node, slot, ann, 300.0, {}, false)
	assert_bool(_has(ann, &"kits_rag")).is_true()


## A feat goes into the profile of the seat it was done at, the linked profile's at another seat,
## and a guest's and a bot's nowhere; a test's room keeps nothing, and what a room kept is settled
## and written as it is left.
func test_a_feat_goes_into_the_profile_at_its_seat() -> void:
	var bob := Game.settings.new_profile()
	bob.player_names[0] = "Bob"
	bob.save_to_disk()
	Game.settings.link_seat(1, bob.id)
	var inputs: Array[KartInput] = [
		PlayerInput.new(DeviceInput.KEYBOARD, 0),
		PlayerInput.new(0, 1),
		PlayerInput.new(1, 2),
		BotInput.new(),
	]
	_room(inputs)
	LoyaltyRecord.anywhere = false
	await _runner.simulate_frames(2, 17)
	Events.bank_completed.emit(0, 7, 1.0, 7)
	assert_bool(_has(Game.settings.profile, &"patchwork")).is_false()
	LoyaltyRecord.anywhere = true
	Events.bank_completed.emit(1, 7, 1.0, 7)
	Events.bank_completed.emit(2, 30, 20.0, 600)
	Events.bank_completed.emit(3, 30, 20.0, 600)
	Events.bank_completed.emit(9, 30, 20.0, 600)
	var ann := Game.settings.profile
	assert_bool(_has(ann, &"patchwork")).is_false()
	assert_bool(_has(ann, &"cursed_cards")).is_false()
	assert_bool(_has(Game.settings.seat_profile(1), &"patchwork")).is_true()
	get_tree().call_group(MatchRecord.GROUP, &"leave")
	Game.settings.unlink_all()
	var kept := Profile.at(Game.settings.profiles_dir(), bob.id)
	assert_bool(kept.loyalty.has_feat(&"patchwork")).is_true()


## A map written down to its whistle keeps the feats it made, and settles them with the statistics.
func test_a_map_written_down_keeps_its_feats() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	var record := MatchRecord.add_to(match_node)
	MatchRecord.anywhere = true
	record.seconds = 200.0
	var ann := Game.settings.profile
	ann.loyalty.welcomed = true
	record.record(true)
	assert_bool(_has(ann, &"clean_record")).is_true()
	assert_bool(ann.loyalty.has_won(&"slip_road")).is_true()
	var kept := Profile.at(Game.settings.profiles_dir(), ann.id)
	assert_bool(kept.loyalty.has_feat(&"clean_record")).is_true()


## A room left headless writes nobody's settings: a test's room is freed after the settings the
## game started with are back, and must never write the player's own over them.
func test_a_room_left_headless_writes_no_settings() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	Events.bank_completed.emit(0, 30, 12.0, 360)
	assert_bool(_has(Game.settings.profile, &"cursed_cards")).is_true()
	var scratch := Game.settings
	var theirs := Settings.new()
	theirs.path = "user://test_loyalty_record_theirs.cfg"
	Game.settings = theirs
	LoyaltyRecord.anywhere = false
	match_node.get_parent().remove_child(match_node)
	Game.settings = scratch
	assert_bool(FileAccess.file_exists(theirs.path)).is_false()
	Settings.remove_files(theirs.path)


## Kit's three bets of one map: a full hand of jokers left on the floor, a cash-out of a thousand
## with nothing in hand, and a map won without picking up a power-up; none of them for a map that
## picked one up.
func test_kits_three_bets_of_a_map() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	var ann := Game.settings.profile
	var slot := match_node.slots[0]
	for i: int in JokerHolder.MAX_JOKERS:
		assert_bool(_has(ann, &"left_on_the_floor")).is_false()
		Events.joker_left.emit(0, &"payday")
	assert_bool(_has(ann, &"left_on_the_floor")).is_true()
	Events.bank_completed.emit(0, 100, 9.0, 900)
	assert_bool(_has(ann, &"house_money")).is_false()
	slot.kart.jokers.add(JOKERS.by_id(&"payday"))
	Events.bank_completed.emit(0, 100, 12.0, 1200)
	assert_bool(_has(ann, &"house_money")).is_false()
	slot.kart.jokers.jokers.clear()
	Events.bank_completed.emit(0, 100, 12.0, 1200)
	assert_bool(_has(ann, &"house_money")).is_true()
	Events.item_picked.emit(0, &"shield")
	LoyaltyRecord.map_played(match_node, slot, ann, 200.0, {}, true)
	assert_bool(_has(ann, &"no_strings")).is_false()
	Events.player_joined.emit(0)
	LoyaltyRecord.map_played(match_node, slot, ann, 200.0, {}, true)
	assert_bool(_has(ann, &"no_strings")).is_true()


## A pick turned down at this machine is a term of the House's declined, STORY.md 6.3, counted for
## the seat's profile while its story is on and it is licensed; a card taken is not.
func test_a_pick_turned_down_is_a_term_declined() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	var ann := Game.settings.profile
	Events.joker_answered.emit(0, &"")
	assert_int(ann.story.declined).is_equal(0)
	ann.license_number = "JJ-212212"
	Events.joker_answered.emit(0, &"")
	Events.joker_answered.emit(0, &"payday")
	assert_int(ann.story.declined).is_equal(1)
	assert_str(StoryFill.values_for(ann)["declined"]).is_equal("1")
	ann.story.on = false
	Events.joker_answered.emit(0, &"")
	assert_int(ann.story.declined).is_equal(1)
	assert_object(match_node).is_not_null()
