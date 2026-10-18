extends GdUnitTestSuite
## Profiles, GAME.md 8.5: who is playing at this machine, kept apart from how the machine is set up,
## each in a file of its own beside the settings, switched between from the settings' first page.

const PATH := "user://test_profiles.cfg"
const SETTINGS_SCENE := preload("res://scenes/ui/settings_screen.tscn")


func after_test() -> void:
	Settings.remove_files(PATH)


func _settings() -> Settings:
	var settings := Settings.new()
	settings.path = PATH
	settings.load_from_disk()
	return settings


## The person's things go to their profile's file and the machine's to the settings file, and both
## come back as they went.
func test_a_profile_is_kept_apart_from_the_machine() -> void:
	var settings := _settings()
	assert_str(settings.profile.id).is_equal("1")
	settings.player_names[0] = "Ann"
	settings.license_plate = "ANN-1"
	settings.profile.license_cones = 3
	settings.profile.test_time = 192.5
	settings.profile.test_best = 178.0
	settings.kart_styles[0] = PackedInt32Array([2, 1, 0, 3, 0, 0])
	settings.last_server = "games.example"
	settings.master_volume = 0.4
	assert_int(settings.save_to_disk()).is_equal(OK)
	var machine := ConfigFile.new()
	machine.load(PATH)
	(
		assert_bool(
			machine.has_section("lobby") and machine.has_section_key("lobby", "player_names")
		)
		. is_false()
	)
	assert_str(str(machine.get_value("profile", "active"))).is_equal("1")
	assert_bool(FileAccess.file_exists(settings.profiles_dir().path_join("1.cfg"))).is_true()
	var read := _settings()
	assert_str(read.player_names[0]).is_equal("Ann")
	assert_str(read.license_plate).is_equal("ANN-1")
	assert_int(read.profile.license_cones).is_equal(3)
	assert_float(read.profile.test_time).is_equal_approx(192.5, 0.001)
	assert_float(read.profile.test_best).is_equal_approx(178.0, 0.001)
	assert_array(Array(read.kart_styles[0])).is_equal([2, 1, 0, 3, 0, 0])
	assert_str(read.last_server).is_equal("games.example")
	assert_float(read.master_volume).is_equal_approx(0.4, 0.001)
	assert_str(read.profile.display_name()).is_equal("Ann")


## A settings file from before profiles is not carried over: its names and license start afresh.
func test_an_old_file_starts_a_fresh_profile() -> void:
	var old := ConfigFile.new()
	old.set_value("lobby", "player_names", ["Bo", "", "", ""])
	old.set_value("progress", "license_number", "JJ-1")
	old.set_value("audio", "master", 0.3)
	old.save(PATH)
	var settings := _settings()
	assert_str(settings.player_names[0]).is_empty()
	assert_str(settings.license_number).is_empty()
	assert_float(settings.master_volume).is_equal_approx(0.3, 0.001)
	assert_str(settings.profile.display_name()).is_equal("Player 1")


## Made, switched to and thrown away: a new one starts blank, the old one is as it was left, the
## one playing cannot be thrown away, and a machine keeps no more than eight.
func test_profiles_are_made_switched_and_thrown_away() -> void:
	var settings := _settings()
	settings.player_names[0] = "Ann"
	settings.save_to_disk()
	var made := settings.new_profile()
	assert_str(made.id).is_equal("2")
	settings.switch_profile("2")
	assert_str(settings.profile.id).is_equal("2")
	assert_str(settings.player_names[0]).is_empty()
	settings.player_names[0] = "Cy"
	settings.switch_profile("1")
	assert_str(settings.player_names[0]).is_equal("Ann")
	var names: Array[String] = []
	for each: Profile in settings.profiles():
		names.append(each.display_name())
	assert_array(names).is_equal(["Ann", "Cy"] as Array[String])
	assert_bool(settings.delete_profile("1")).is_false()
	assert_bool(settings.delete_profile("2")).is_true()
	assert_int(settings.profiles().size()).is_equal(1)
	for i: int in Profile.MOST - 1:
		assert_object(settings.new_profile()).is_not_null()
	assert_object(settings.new_profile()).is_null()
	# And the one playing is the one the settings file names, read again.
	settings.switch_profile("3")
	assert_str(_settings().profile.id).is_equal("3")


## The Profiles page: a row for each, the one playing marked and kept, Edit renaming one in a
## dialog, New naming one and going to it, and nothing done to any of them from inside a room.
func test_the_profiles_page_lists_renames_and_makes_them() -> void:
	var settings := _settings()
	settings.player_names[0] = "Ann"
	settings.save_to_disk()
	settings.new_profile()
	var switched: Array[String] = []
	var page: ProfilesTab = auto_free(
		ProfilesTab.make(settings, true, func(id: String) -> void: switched.append(id))
	)
	add_child(page)
	await await_idle_frame()
	assert_int(page.rows.size()).is_equal(2)
	# Before a license a profile shows the learner's L itself, not a plate reading L.
	var learner: Node = (page.rows["2"]["row"] as Node).find_child("Learner", true, false)
	assert_object(learner).is_not_null()
	assert_object((page.rows["2"]["row"] as Node).find_child("Plate", true, false)).is_null()
	var mine: Dictionary = page.rows["1"]
	assert_bool((mine["switch"] as Button).disabled).is_true()
	assert_bool((mine["delete"] as Button).disabled).is_true()
	assert_str((mine["name"] as Label).text).is_equal("Ann")
	# Edit asks for the name in a dialog, the one it has in the box; going ahead renames it.
	var other: Dictionary = page.rows["2"]
	(other["edit"] as Button).pressed.emit()
	var dialog := page.dialog
	assert_object(dialog).is_not_null()
	assert_str(dialog.field.text).is_empty()
	assert_bool(dialog.ok_button.disabled).is_true()
	dialog.field.text = "Dee"
	dialog.field.text_changed.emit(dialog.field.text)
	assert_bool(dialog.ok_button.disabled).is_false()
	dialog.ok_button.pressed.emit()
	await await_idle_frame()
	assert_object(page.dialog).is_null()
	assert_str((other["name"] as Label).text).is_equal("Dee")
	assert_str(Profile.at(settings.profiles_dir(), "2").display_name()).is_equal("Dee")
	# Canceled, nothing changes.
	(other["edit"] as Button).pressed.emit()
	page.dialog.field.text = "Nope"
	page.dialog.cancel_button.pressed.emit()
	await await_idle_frame()
	assert_str(Profile.at(settings.profiles_dir(), "2").display_name()).is_equal("Dee")
	(other["switch"] as Button).pressed.emit()
	assert_array(switched).is_equal(["2"] as Array[String])
	assert_str(settings.profile.id).is_equal("2")
	# New asks for a name and makes the profile under it: Make, which Enter presses, leaves the one
	# playing as it is, and Make and switch goes to the new one.
	page.new_button.pressed.emit()
	page.dialog.field.text = "Eve"
	page.dialog.field.text_submitted.emit(page.dialog.field.text)
	await await_idle_frame()
	assert_str(settings.profile.id).is_equal("2")
	assert_str(Profile.at(settings.profiles_dir(), "3").display_name()).is_equal("Eve")
	assert_array(switched).is_equal(["2", "2"] as Array[String])
	page.new_button.pressed.emit()
	page.dialog.field.text = "Fay"
	page.dialog.field.text_changed.emit(page.dialog.field.text)
	page.dialog.also_button.pressed.emit()
	await await_idle_frame()
	assert_str(settings.profile.id).is_equal("4")
	assert_str(settings.player_names[0]).is_equal("Fay")
	assert_array(switched).is_equal(["2", "2", "4"] as Array[String])
	# Inside a room the profiles are only listed: nothing is made, changed, switched or thrown away
	# there. Making one there once froze the game.
	var in_room: ProfilesTab = auto_free(ProfilesTab.make(settings, false, Callable()))
	add_child(in_room)
	await await_idle_frame()
	for id: String in in_room.rows:
		for each: String in ["edit", "switch", "delete"]:
			assert_bool((in_room.rows[id][each] as Button).disabled).is_true()
	assert_bool(in_room.new_button.disabled).is_true()
	in_room._new()
	in_room._edit(settings.profile)
	assert_object(in_room.dialog).is_null()
	assert_int(settings.profiles().size()).is_equal(4)


## The settings' pages run License, Players, Controls, Audio, Video, Accessibility, Profiles and
## About, and Debug last in a debug build, and after a switch they come up again on Profiles.
func test_the_pages_are_in_order_and_a_switch_comes_back_to_profiles() -> void:
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	await await_idle_frame()
	var names: Array[String] = []
	for i: int in screen.tabs.get_tab_count():
		names.append(String(screen.tabs.get_tab_control(i).name))
	# The debug page, of the story and the loyalty program, is a debug build's alone, last.
	if OS.is_debug_build():
		assert_str(names.pop_back()).is_equal("Debug")
	assert_array(names).is_equal(
		(
			[
				"License",
				"Seats",
				"Controls",
				"Audio",
				"Video",
				"Accessibility",
				"Statistics",
				"Profiles",
				"About"
			]
			as Array[String]
		)
	)
	SettingsScreen.opening_on = ProfilesTab.TITLE
	var again: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(again)
	await await_idle_frame()
	assert_str(String(again.tabs.get_current_tab_control().name)).is_equal("Profiles")
	assert_str(SettingsScreen.opening_on).is_empty()


## A match played to the whistle goes into the profile of the first seat at this machine, GAME.md
## 8.5: its counts added up, its bests kept, the map and a Grand Prix's last map counted, won or
## not; the Statistics page reads them.
func test_a_match_played_to_the_end_goes_into_the_profile() -> void:
	var settings := _settings()
	var real := Game.settings
	Game.settings = settings
	var match_node: Match = auto_free(preload("res://scenes/match/match.tscn").instantiate())
	match_node.with_hud = false
	var runner := scene_runner(match_node)
	match_node.start(
		[PlayerInput.new(DeviceInput.KEYBOARD, 0), KartInput.new()] as Array[KartInput], 3
	)
	await runner.simulate_frames(2, 17)
	var mine := match_node.slots[0]
	assert_object(MatchRecord.profile_of(mine)).is_same(settings.profile)
	assert_object(MatchRecord.profile_of(match_node.slots[1])).is_null()
	mine.stats.add(&"driven", 1500.0)
	mine.stats.add(&"bullets", 20.0)
	mine.stats.add(&"hits", 5.0)
	mine.stats.peak(&"max_mult", 4.0)
	mine.kills = 3
	mine.banked = 900
	var record := MatchRecord.add_to(match_node)
	record.seconds = 125.0
	record.record()
	record.record()
	var profile := settings.profile
	assert_float(LifetimeStats.value_of(profile, &"maps")).is_equal(1.0)
	assert_float(LifetimeStats.value_of(profile, &"maps_won")).is_equal(1.0)
	assert_float(LifetimeStats.value_of(profile, &"kills")).is_equal(3.0)
	assert_float(LifetimeStats.value_of(profile, &"best_banked")).is_equal(900.0)
	assert_str(LifetimeStats.shown(profile, &"driven")).is_equal("1.5 km")
	assert_str(LifetimeStats.shown(profile, &"accuracy")).is_equal("25%")
	assert_str(LifetimeStats.shown(profile, &"seconds")).is_equal("2 min")
	# A second map, lost, with a lower mult: added up, the best kept.
	LifetimeStats.add_map(profile, match_node.slots[1], false, 60.0)
	assert_float(LifetimeStats.value_of(profile, &"maps")).is_equal(2.0)
	assert_float(LifetimeStats.value_of(profile, &"maps_won")).is_equal(1.0)
	assert_float(LifetimeStats.value_of(profile, &"max_mult")).is_equal(4.0)
	LifetimeStats.add_grand_prix(profile, true)
	assert_float(LifetimeStats.value_of(profile, &"grand_prix_won")).is_equal(1.0)
	# Kept, and on the page.
	var read := _settings()
	assert_float(LifetimeStats.value_of(read.profile, &"kills")).is_equal(3.0)
	var page: StatsTab = auto_free(StatsTab.make(read))
	add_child(page)
	await await_idle_frame()
	assert_str(page.values[&"maps"].text).is_equal("1")
	assert_str(page.values[&"driven"].text).is_equal("1.5 km")
	Game.settings = real


## Delete asks first, over the screen, with the warning sign: Keep keeps the profile and puts the
## cursor back on the trash can, and Delete throws it away.
func test_deleting_a_profile_asks_first() -> void:
	var settings := _settings()
	settings.player_names[0] = "Ann"
	settings.save_to_disk()
	settings.new_profile()
	var page: ProfilesTab = auto_free(
		ProfilesTab.make(settings, true, func(_id: String) -> void: pass)
	)
	add_child(page)
	await await_idle_frame()
	var trash := page.rows["2"]["delete"] as Button
	assert_object(trash.get_node_or_null("Picture")).is_not_null()
	trash.pressed.emit()
	assert_object(page.question).is_not_null()
	assert_str(page.question.said()).contains(ProfilesTab.SURE)
	page.question.no_button().pressed.emit()
	await await_idle_frame()
	assert_object(page.question).is_null()
	assert_int(settings.profiles().size()).is_equal(2)
	trash.pressed.emit()
	page.question.yes_button().pressed.emit()
	await await_idle_frame()
	assert_int(settings.profiles().size()).is_equal(1)


## A test, a check or a bench plays on the settings they all share, never on the player's own on
## the same machine, GAME.md 10.2: a script run, as gdUnit's and every tool's are, unless the run
## names a file of its own, on the command line or in the environment. The player's game, started
## on the game rather than a script, plays on theirs.
func test_tests_never_play_on_the_players_settings() -> void:
	var none := PackedStringArray()
	var script := PackedStringArray(["--headless", "-s", "res://tools/check.gd"])
	assert_str(Game.settings_path_for(none, script, "")).is_equal(Game.TEST_SETTINGS)
	assert_str(Game.settings_path_for(none, PackedStringArray(["--path", "."]), "")).is_empty()
	var named := PackedStringArray(["--settings=mine.cfg"])
	assert_str(Game.settings_path_for(named, script, "")).is_equal("user://mine.cfg")
	assert_str(Game.settings_path_for(none, none, "tests.cfg")).is_equal(Game.TEST_SETTINGS)
	# This very run is one, and so is on them.
	assert_bool(Game.scripted_run(OS.get_cmdline_args())).is_true()
	assert_str(Game.settings_path_for(none, OS.get_cmdline_args(), "")).is_equal(Game.TEST_SETTINGS)


## The settings file can be named on the command line, GAME.md 10.2: a user path, an absolute
## one, or a bare name in the user directory; nothing named is the usual file.
func test_a_settings_file_can_be_named_on_the_command_line() -> void:
	assert_str(Game.settings_path_in(PackedStringArray(["--settings=user://fresh.cfg"]))).is_equal(
		"user://fresh.cfg"
	)
	(
		assert_str(Game.settings_path_in(PackedStringArray(["--frames=3", "--settings=fresh.cfg"])))
		. is_equal("user://fresh.cfg")
	)
	assert_str(Game.settings_path_in(PackedStringArray(["--settings=/tmp/a.cfg"]))).is_equal(
		"/tmp/a.cfg"
	)
	assert_str(Game.settings_path_in(PackedStringArray(["--settings="]))).is_equal("")
	assert_str(Game.settings_path_in(PackedStringArray(["--bench=10"]))).is_equal("")
