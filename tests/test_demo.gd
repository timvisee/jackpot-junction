extends GdUnitTestSuite
## The demo for a booth, GAME.md 9.8: its switch, its settings, its profile, and nothing it plays
## recorded anywhere.

const PATH := "user://test_demo.cfg"
const PLAYERS := "user://test_demo_players.cfg"
const MATCH_SCENE := "res://scenes/match/match_scene.tscn"

var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings


func after_test() -> void:
	Demo.on = false
	Demo.away = false
	Demo.seats = Demo.SEATS
	Demo.bots = Demo.BOTS
	Demo.map_seconds = Demo.MAP_SECONDS
	Game.settings = _settings_were
	Game.grand_prix = null
	Game.pending_config = null
	Settings.remove_files(PATH)
	Settings.remove_files(PLAYERS)


## `--demo` plays on settings of its own, unless a file is named; a test or a tool on the shared
## ones, as ever, and the player's game without it on theirs.
func test_the_demo_plays_on_its_own_settings() -> void:
	var demo := PackedStringArray(["--demo"])
	var game := PackedStringArray(["--path", "."])
	var script := PackedStringArray(["-s", "res://tools/check.gd"])
	assert_str(Game.settings_path_for(demo, game, "")).is_equal(Demo.SETTINGS)
	assert_str(Game.settings_path_for(PackedStringArray(), game, "")).is_empty()
	var named := PackedStringArray(["--demo", "--settings=booth.cfg"])
	assert_str(Game.settings_path_for(named, game, "")).is_equal("user://booth.cfg")
	assert_str(Game.settings_path_for(demo, game, "tests.cfg")).is_equal(Game.TEST_SETTINGS)
	assert_str(Game.settings_path_for(demo, script, "")).is_equal(Game.TEST_SETTINGS)


## Two seats and two bots unless the arguments say otherwise, a machine's four seats at most and a
## room of eight karts in all.
func test_the_arguments_set_the_table() -> void:
	Demo.read_arguments(PackedStringArray(["--path"]))
	assert_bool(Demo.on).is_false()
	Demo.read_arguments(PackedStringArray(["--demo"]))
	assert_bool(Demo.on).is_true()
	assert_int(Demo.seats).is_equal(2)
	assert_int(Demo.bots).is_equal(2)
	Demo.read_arguments(PackedStringArray(["--demo", "--demo-seats=9", "--demo-bots=7"]))
	assert_int(Demo.seats).is_equal(4)
	assert_int(Demo.bots).is_equal(4)
	Demo.read_arguments(PackedStringArray(["--demo", "--demo-seats=1", "--demo-bots=0"]))
	assert_int(Demo.seats).is_equal(1)
	assert_int(Demo.bots).is_equal(0)
	Demo.read_arguments(PackedStringArray(["--demo", "--demo-map-seconds=2"]))
	assert_int(Demo.map_seconds).is_equal(10)


## The demo's profile has the whole program won, so the table deals every card and item and a kart
## can wear anything; its story is off, and every seat drives the simple way by itself.
func test_the_demos_profile_has_everything() -> void:
	var made := Demo.profile()
	assert_bool(made.transient).is_true()
	assert_str(made.id).is_equal(Demo.PROFILE_ID)
	assert_bool(made.story.on).is_false()
	assert_bool(made.tutorial_done).is_true()
	assert_bool(made.loyalty.welcomed).is_true()
	for each: LoyaltyLandmark in Loyalty.map().landmarks:
		assert_bool(made.loyalty.has_won(each.id)).is_true()
	for seat: int in made.drive_modes.size():
		assert_str(made.drive_modes[seat]).is_equal(Settings.DRIVE_SIMPLE)
		assert_bool(made.auto_throttle[seat]).is_true()
	var unlocks := Loyalty.unlocks_of(made)
	for id: StringName in Loyalty.later_ids():
		assert_array(unlocks["items"]).contains([String(id)])
	var catalog: JokerCatalog = load("res://data/jokers/catalog.tres")
	var deck := Loyalty.deck_from(unlocks, catalog)
	for joker: Joker in catalog.jokers:
		assert_array(deck).contains([joker.id])


## The demo's profile is never written, wherever the settings are saved, and the file never names
## it as the profile playing.
func test_the_demos_profile_is_never_written() -> void:
	var settings := Settings.new()
	settings.path = PATH
	settings.load_from_disk()
	Demo.set_up(settings, false)
	settings.player_names[0] = "Booth"
	settings.profile.stats[&"maps"] = 3.0
	assert_int(settings.save_to_disk()).is_equal(OK)
	assert_bool(SafeFile.exists(PATH)).is_true()
	var folder := settings.profiles_dir()
	(
		assert_bool(
			DirAccess.dir_exists_absolute(folder) and not DirAccess.get_files_at(folder).is_empty()
		)
		. is_false()
	)
	var read := Settings.new()
	read.path = PATH
	read.load_from_disk()
	assert_str(read.profile.player_names[0]).is_empty()
	assert_float(float(read.profile.stats.get(&"maps", 0.0))).is_equal(0.0)


## The first start takes the machine's part of the player's own settings, and nothing of their
## profiles; the next start keeps what the demo's own file says.
func test_the_first_start_takes_after_the_players_machine() -> void:
	var players := Settings.new()
	players.path = PLAYERS
	players.load_from_disk()
	players.master_volume = 0.2
	players.ui_scale = 1.5
	players.player_names[0] = "Ann"
	players.save_to_disk()
	var settings := Settings.new()
	settings.path = PATH
	settings.load_from_disk()
	Demo.set_up(settings, true, PLAYERS)
	assert_float(settings.master_volume).is_equal(0.2)
	assert_float(settings.ui_scale).is_equal(1.5)
	assert_str(settings.player_names[0]).is_empty()
	assert_bool(SafeFile.exists(PATH)).is_true()
	settings.master_volume = 0.7
	settings.save_to_disk()
	var again := Settings.new()
	again.path = PATH
	again.load_from_disk()
	Demo.set_up(again, false, PLAYERS)
	assert_float(again.master_volume).is_equal(0.7)


## On a machine nobody has played on the demo starts on the booth's defaults: the game's own, in
## full screen.
func test_a_bare_machine_starts_the_booths_way() -> void:
	var settings := Settings.new()
	settings.path = PATH
	settings.load_from_disk()
	settings.fullscreen = false
	Demo.set_up(settings, true, PLAYERS)
	assert_bool(settings.fullscreen).is_true()
	assert_float(settings.master_volume).is_equal(Settings.new().master_volume)


## Nothing played in the demo counts for anybody: no statistics, catalog, bets or achievements,
## no notes and no bet pinned over the clock.
func test_nothing_the_demo_plays_is_recorded() -> void:
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Demo.on = true
	Demo.set_up(Game.settings, false)
	var config := MatchConfig.new()
	config.bot_count = 1
	Game.pending_config = config
	var scene: Node3D = auto_free(load(MATCH_SCENE).instantiate())
	add_child(scene)
	await assert_signal(scene).is_emitted("loaded")
	var match_node: Match = scene.get_node("Match")
	for named: String in [
		"MatchRecord",
		"CatalogRecord",
		"LoyaltyRecord",
		"AchievementRecord",
		"LostProperty",
		"PinnedStrip",
		"NoteDealer"
	]:
		(
			assert_object(match_node.find_child(named, true, false))
			. override_failure_message(named)
			. is_null()
		)


## And the same match outside the demo is, which is what the names above are worth.
func test_a_match_outside_the_demo_is_recorded() -> void:
	Game.settings = Settings.new()
	Game.settings.path = PATH
	var config := MatchConfig.new()
	config.bot_count = 1
	Game.pending_config = config
	var scene: Node3D = auto_free(load(MATCH_SCENE).instantiate())
	add_child(scene)
	await assert_signal(scene).is_emitted("loaded")
	var match_node: Match = scene.get_node("Match")
	for named: String in ["MatchRecord", "CatalogRecord", "LoyaltyRecord", "AchievementRecord"]:
		(
			assert_object(match_node.find_child(named, true, false))
			. override_failure_message(named)
			. is_not_null()
		)
