extends GdUnitTestSuite
## The Steam store page in every language the game speaks, GAME.md 10.9: its words written for each
## in docs/steam, and the description's headings drawn in each by `make steam-art`.

const GAME_ART := "res://scenes/dev/steam_art_export.gd"
const PACK_ART := "res://scenes/dev/supporter_art_export.gd"


func test_every_language_has_its_store_page() -> void:
	var game: Dictionary = load(GAME_ART).get_script_constant_map()
	var pack: Dictionary = load(PACK_ART).get_script_constant_map()
	var steam := Lang.on_steam()
	for language: String in steam:
		var locale := steam[language]
		if locale == Lang.ENGLISH:
			continue
		var words := "res://docs/steam/store_%s.md" % language
		assert_bool(FileAccess.file_exists(words)).override_failure_message(words).is_true()
		var headings: Dictionary = game["HEADINGS_IN"].get(locale, {})
		assert_array(headings.keys()).contains_exactly(game["HEADINGS"].keys())
		var pack_headings: Dictionary = pack["PACK_HEADINGS_IN"].get(locale, {})
		assert_array(pack_headings.keys()).contains_exactly(pack["PACK_HEADINGS"].keys())
		# And the pictures drawn in it, which the store page's words name.
		var page := FileAccess.get_file_as_string(words)
		for heading: String in headings:
			var file := "%s_%s.png" % [heading, language]
			var drawn := "res://docs/description/%s/%s" % [language, file]
			assert_bool(FileAccess.file_exists(drawn)).override_failure_message(drawn).is_true()
			assert_str(page).contains(file)
		for heading: String in pack_headings:
			var file := "%s_%s.png" % [heading, language]
			var drawn := "res://docs/description/supporter/%s/%s" % [language, file]
			assert_bool(FileAccess.file_exists(drawn)).override_failure_message(drawn).is_true()
			assert_str(page).contains(file)
