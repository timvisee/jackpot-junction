extends GdUnitTestSuite
## A profile's table, GAME.md 3.17 and 8.9a: the House opening a card a map, the cards opened early
## or turned face down, and the table a match is told, from the profile, a host's say or a server.

const PATH := "user://test_table_state.cfg"


func after_test() -> void:
	Settings.remove_files(PATH)


func _settings() -> Settings:
	var settings := Settings.new()
	settings.path = PATH
	settings.load_from_disk()
	return settings


## A new profile plays power-ups alone, and each map played opens the next card.
func test_the_house_opens_a_card_a_map() -> void:
	var profile := _settings().profile
	assert_int(profile.table_opened()).is_equal(TableCards.FIRST)
	assert_int(profile.table_set()).is_equal(TableCards.FIRST)
	profile.stats[&"maps"] = 2.0
	assert_int(profile.table_opened()).is_equal(TableCards.opened_by(2))
	# Told of the two the maps opened, once, and fresh until played.
	assert_int(profile.table.tell(profile.maps_played())).is_equal(TableCards.opened_by(2) & ~1)
	assert_int(profile.table.tell(profile.maps_played())).is_equal(0)
	assert_bool(TableCards.has(profile.table.fresh, TableCards.Card.JOKERS)).is_true()
	profile.table.played(TableCards.FIRST | TableCards.bit(TableCards.Card.JOKERS))
	assert_bool(TableCards.has(profile.table.fresh, TableCards.Card.JOKERS)).is_false()
	assert_bool(TableCards.has(profile.table.fresh, TableCards.Card.JACKPOT)).is_true()


## A card turned face down stays down, and one the House opens after comes face up, unless every
## card is down, as the Penny table has them.
func test_a_card_turned_down_stays_down() -> void:
	var profile := _settings().profile
	profile.stats[&"maps"] = 2.0
	profile.table.off = TableCards.bit(TableCards.Card.JACKPOT)
	assert_bool(TableCards.has(profile.table_set(), TableCards.Card.JACKPOT)).is_false()
	profile.stats[&"maps"] = 3.0
	assert_bool(TableCards.has(profile.table_set(), TableCards.Card.FLUSH)).is_true()
	profile.table.off = TableCards.ALL & ~TableCards.FIRST
	profile.stats[&"maps"] = 5.0
	assert_int(profile.table_set()).is_equal(TableCards.FIRST)


## Opened early, a card is opened, face up and never on a coupon.
func test_a_card_opened_early() -> void:
	var profile := _settings().profile
	profile.table.off = TableCards.bit(TableCards.Card.SLOTS)
	profile.table.open_early(TableCards.Card.SLOTS)
	assert_bool(TableCards.has(profile.table_set(), TableCards.Card.SLOTS)).is_true()
	profile.stats[&"maps"] = 5.0
	var told := profile.table.tell(profile.maps_played())
	assert_bool(TableCards.has(told, TableCards.Card.SLOTS)).is_false()
	assert_bool(TableCards.has(told, TableCards.Card.TRICKS)).is_true()


## The table is kept with the profile, and a profile from before it has been told of what its maps
## opened, so its next slip carries no coupon for them.
func test_the_table_is_kept_and_a_profile_from_before_was_told() -> void:
	var settings := _settings()
	settings.profile.stats[&"maps"] = 1.0
	settings.profile.table.off = TableCards.bit(TableCards.Card.JACKPOT)
	settings.profile.table.roulette = true
	settings.profile.table.open_early(TableCards.Card.BOUNTY)
	assert_int(settings.save_to_disk()).is_equal(OK)
	var again := _settings().profile
	assert_int(again.table.off).is_equal(TableCards.bit(TableCards.Card.JACKPOT))
	assert_bool(again.table.roulette).is_true()
	assert_bool(TableCards.has(again.table_opened(), TableCards.Card.BOUNTY)).is_true()
	var file := ConfigFile.new()
	file.load(again.path)
	file.erase_section(TableState.SECTION)
	file.set_value("stats", "maps", 4.0)
	file.save(again.path)
	var old := _settings().profile
	assert_int(old.table_opened()).is_equal(TableCards.opened_by(4))
	assert_int(old.table.tell(old.maps_played())).is_equal(0)


## The match is told the profile's table, a host's say sends its own, and a server sets out what it
## was started with until somebody chooses.
func test_the_table_a_match_is_told() -> void:
	var settings := _settings()
	settings.profile.stats[&"maps"] = 3.0
	settings.profile.table.roulette = true
	var config := MatchConfig.from_settings(settings)
	assert_int(config.table).is_equal(TableCards.opened_by(3))
	assert_bool(config.roulette).is_true()
	var server := MatchConfig.new()
	MatchOptions.from_wire(server, MatchOptions.to_wire(config))
	assert_int(server.table).is_equal(config.table)
	assert_bool(server.roulette).is_true()
	assert_str(ServerArgs.read([]).table).is_equal("standard")
	assert_str(ServerArgs.read(["--table=Penny"]).table).is_equal("penny")
	assert_str(ServerArgs.read([], {"JJ_TABLE": "roulette"}).table).is_equal("roulette")
	assert_str(ServerArgs.read(["--table=chaos"]).problem()).contains("--table")


## A map played to the whistle opens the next card for the profile playing, told on the payout
## slip's coupon, and new until it is played; the cards the map played are no longer new.
func test_a_map_played_opens_a_card_on_the_slip() -> void:
	var settings_were := Game.settings
	Game.settings = _settings()
	var match_node: Match = auto_free(load("res://scenes/match/match.tscn").instantiate())
	match_node.rules = load("res://data/match/waiting_room.tres")
	match_node.arena_layout = load("res://data/maps/waiting_room.tres")
	match_node.with_hud = false
	match_node.offer_size = 0
	var runner := scene_runner(match_node)
	match_node.start(
		[PlayerInput.new(DeviceInput.KEYBOARD, 0), BotInput.new()] as Array[KartInput], 2
	)
	await runner.simulate_frames(2, 17)
	var record := MatchRecord.add_to(match_node)
	MatchRecord.anywhere = true
	record.seconds = 60.0
	record.record(true)
	MatchRecord.anywhere = false
	var profile := Game.settings.profile
	var jackpot := TableCards.bit(TableCards.Card.JACKPOT)
	assert_float(profile.maps_played()).is_equal(1.0)
	assert_int(int(match_node.get_meta(MatchRecord.TABLE_NEWS, 0))).is_equal(jackpot)
	assert_int(profile.table.fresh).is_equal(jackpot)
	var page := CouponPage.create()
	auto_free(page)
	assert_bool(page.fill(jackpot)).is_true()
	assert_int(page.rows.get_child_count()).is_equal(1)
	assert_str(page.heading.text).is_equal("Compliments of the House")
	assert_bool(page.fill(0)).is_false()
	Game.settings = settings_were


## A match's loading screen deals the table, GAME.md 8.6: a card for each card on it, face down,
## turned up as the room goes up, the one new to the player slid out and named under the bar.
func test_the_loading_screen_deals_the_table() -> void:
	var settings_were := Game.settings
	Game.settings = _settings()
	Game.settings.profile.table.fresh = TableCards.bit(TableCards.Card.FLUSH)
	var screen := LoadingScreen.new()
	screen.table = TableCards.opened_by(3)
	LoadingScreen.add_to(self, "Lucky Crossing", null, screen)
	assert_int(screen._cards.size()).is_equal(4)
	assert_int(screen._new_card).is_equal(TableCards.Card.FLUSH)
	assert_object(screen._new_tag).is_not_null()
	assert_bool(screen._faces[0].visible).is_false()
	screen._turn_up(1.0)
	await get_tree().create_timer(LoadingScreen.LINGER * 2.0).timeout
	for face: Control in screen._faces:
		assert_bool(face.visible).is_true()
	var plain := LoadingScreen.add_to(self, "Garage")
	assert_int(plain._cards.size()).is_equal(LoadingScreen.FAN)
	assert_object(plain._new_tag).is_null()
	screen.free()
	plain.free()
	Game.settings = settings_were
