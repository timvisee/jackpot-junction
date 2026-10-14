extends GdUnitTestSuite
## How the speedometer counts, GAME.md 8.3 and 8.5: kilometers or miles an hour, as the player chose
## or as the country of the system's locale says, see [SpeedUnits].

const PATH := "user://test_speed_units.cfg"


func after_test() -> void:
	Settings.remove_files(PATH)


## Miles an hour only where the roads are signed in them, by the locale's country; a locale with no
## country, English on its own, is kilometers, as is anything that cannot be read.
func test_the_locale_says_where_nothing_is_chosen() -> void:
	for mph: String in ["en_US", "en-GB", "en_US.UTF-8", "en_GB@euro", "es_US", "en_LR", "en_BS"]:
		assert_bool(SpeedUnits.locale_uses_mph(mph)).override_failure_message(mph).is_true()
	for kmh: String in ["en", "en_AU", "en_IE", "en_CA", "nl_NL", "de", "es_419", "zh_Hans_CN", ""]:
		assert_bool(SpeedUnits.locale_uses_mph(kmh)).override_failure_message(kmh).is_false()
	assert_str(SpeedUnits.resolve("", "en_GB")).is_equal(SpeedUnits.MPH)
	assert_str(SpeedUnits.resolve("", "en")).is_equal(SpeedUnits.KMH)
	# A choice made stands, wherever the machine is.
	assert_str(SpeedUnits.resolve(SpeedUnits.KMH, "en_US")).is_equal(SpeedUnits.KMH)
	assert_str(SpeedUnits.resolve(SpeedUnits.MPH, "nl_NL")).is_equal(SpeedUnits.MPH)
	assert_float(SpeedUnits.from_kmh(100.0, SpeedUnits.MPH)).is_equal_approx(62.14, 0.01)
	assert_float(SpeedUnits.from_kmh(100.0, SpeedUnits.KMH)).is_equal(100.0)
	assert_str(SpeedUnits.word(SpeedUnits.MPH)).is_equal("MPH")


## A choice is kept with the machine's settings, and none is kept until one is made, so the locale
## goes on deciding for a player who never chose.
func test_a_choice_is_kept_and_none_is_until_made() -> void:
	var settings := Settings.new()
	settings.path = PATH
	settings.save_to_disk()
	var file := ConfigFile.new()
	file.load(PATH)
	assert_bool(file.has_section_key("accessibility", "speed_unit")).is_false()
	settings.speed_unit_chosen = SpeedUnits.MPH
	settings.save_to_disk()
	var read := Settings.new()
	read.path = PATH
	read.load_from_disk()
	assert_str(read.speed_unit_chosen).is_equal(SpeedUnits.MPH)
	assert_str(read.speed_unit()).is_equal(SpeedUnits.MPH)
	file.load(PATH)
	file.set_value("accessibility", "speed_unit", "furlongs")
	file.save(PATH)
	read.load_from_disk()
	assert_str(read.speed_unit_chosen).is_empty()
