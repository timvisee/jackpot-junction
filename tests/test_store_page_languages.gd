extends GdUnitTestSuite
## The Steam store page in every language the game speaks, GAME.md 10.9: its words written for each
## in docs/steam, the description's headings drawn in each by `make steam-art`, and the trailer's
## words in the languages it is recorded in.

const GAME_ART := "res://scenes/dev/steam_art_export.gd"
const PACK_ART := "res://scenes/dev/supporter_art_export.gd"
const TRAILER_WORDS := "res://scenes/dev/trailer_caption.gd"


func test_every_language_has_its_store_page() -> void:
	var game: Dictionary = load(GAME_ART).get_script_constant_map()
	var pack: Dictionary = load(PACK_ART).get_script_constant_map()
	var steam := Lang.on_steam()
	for language: String in steam:
		var locale := steam[language]
		# A language only just started, with no words yet, has no store page yet either: its store
		# words come with its translation.
		if locale == Lang.ENGLISH or not _has_words(locale):
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


## The trailer's words in another language are each for a word the trailer prints: a caption
## `tools/trailer` gives a shot, a feature or a big word of the run, or the end card's; so one
## changed in English leaves no stale translation behind, see [constant TRAILER_WORDS].
func test_the_trailers_words_are_its_own() -> void:
	var caption: Dictionary = load(TRAILER_WORDS).get_script_constant_map()
	var printed: Array[String] = []
	printed.append_array(caption["FEATURES"])
	printed.append_array(caption["BIG_WORDS"])
	var tool := FileAccess.get_file_as_string("res://tools/trailer")
	var captions := RegEx.create_from_string(r'--captions=([^"\s]+)')
	for found: RegExMatch in captions.search_all(tool):
		for one: String in found.get_string(1).split(";"):
			printed.append(one.get_slice("|", 1).replace("_", " "))
	var posed := FileAccess.get_file_as_string("res://scenes/dev/trailer_posed.gd")
	for found: RegExMatch in RegEx.create_from_string(r'CAPTION\.said\("([^"]+)"\)').search_all(
		posed
	):
		printed.append(found.get_string(1))
	assert_array(printed).contains(["Drift. Shoot.", "Open source", "fun", "PLAY FREE ON STEAM"])
	var words_in: Dictionary = caption["WORDS_IN"]
	assert_array(words_in.keys()).contains(["nl"])
	for locale: String in words_in:
		assert_array(Lang.spoken()).contains([locale])
		for english: String in words_in[locale]:
			assert_array(printed).override_failure_message("%s: %s" % [locale, english]).contains(
				[english]
			)


## Whether [param locale]'s file has any of its words translated yet.
func _has_words(locale: String) -> bool:
	var translation := TranslationServer.get_translation_object(locale)
	for said: String in translation.get_translated_message_list():
		if not said.is_empty():
			return true
	return false
