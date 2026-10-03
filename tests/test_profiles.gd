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
	settings.kart_styles[0] = PackedInt32Array([2, 1, 0, 3])
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
	assert_array(Array(read.kart_styles[0])).is_equal([2, 1, 0, 3])
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


## The Profiles page: a row for each, the one playing marked and kept, a name typed over renamed,
## and no switching from inside a room.
func test_the_profiles_page_lists_and_renames_them() -> void:
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
	var mine: Dictionary = page.rows["1"]
	assert_bool((mine["switch"] as Button).disabled).is_true()
	assert_bool((mine["delete"] as Button).disabled).is_true()
	var other: Dictionary = page.rows["2"]
	var field: LineEdit = other["name"]
	field.text = "Dee"
	field.focus_exited.emit()
	assert_str(Profile.at(settings.profiles_dir(), "2").display_name()).is_equal("Dee")
	(other["switch"] as Button).pressed.emit()
	assert_array(switched).is_equal(["2"] as Array[String])
	assert_str(settings.profile.id).is_equal("2")
	var in_room: ProfilesTab = auto_free(ProfilesTab.make(settings, false, Callable()))
	add_child(in_room)
	await await_idle_frame()
	assert_bool((in_room.rows["1"]["switch"] as Button).disabled).is_true()


## The settings' pages run License, Players, Controls, Audio, Video, Accessibility, Profiles and
## About, and after a switch they come up again on Profiles.
func test_the_pages_are_in_order_and_a_switch_comes_back_to_profiles() -> void:
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	await await_idle_frame()
	var names: Array[String] = []
	for i: int in screen.tabs.get_tab_count():
		names.append(String(screen.tabs.get_tab_control(i).name))
	assert_array(names).is_equal(
		(
			[
				"License",
				"Players",
				"Controls",
				"Audio",
				"Video",
				"Accessibility",
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
