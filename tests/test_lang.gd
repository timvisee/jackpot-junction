extends GdUnitTestSuite
## The languages the game speaks, GAME.md 10.9: which one is spoken, and numbers and lists as the
## language spoken writes them.

const DUTCH := "nl"

var _was := ""
var _words: Translation


func before_test() -> void:
	_was = Lang.current
	# A few words of Dutch of the tests' own, whatever the game's own file holds yet.
	_words = Translation.new()
	_words.locale = DUTCH
	_words.add_message(",", ".", &"thousands")
	_words.add_message(".", ",", &"decimal")
	_words.add_message(", ", ", ", &"list")
	_words.add_message("{some} and {last}", "{some} en {last}")
	_words.add_plural_message("%d chip", PackedStringArray(["%d fiche", "%d fiches"]))
	_words.add_message("{name} paid {chips}", "{name} betaalde {chips}")
	_words.add_message("{who} said: {what}", "{who} zei: {what}")
	_words.add_message("Bye", "Doei")
	_words.add_plural_message(
		"{count} table left", PackedStringArray(["{count} tafel over", "{count} tafels over"])
	)
	for english: String in ["%dST", "%dND", "%dRD", "%dTH"]:
		_words.add_message(english, "%dE", &"ordinal")
	TranslationServer.add_translation(_words)


func after_test() -> void:
	TranslationServer.remove_translation(_words)
	Lang.apply(_was)


func test_a_chosen_language_is_spoken_if_there_is_a_translation_into_it() -> void:
	var known: Array[String] = [Lang.ENGLISH, DUTCH]
	assert_str(Lang.resolve(DUTCH, "english", "en_US", known)).is_equal(DUTCH)
	assert_str(Lang.resolve(Lang.ENGLISH, "dutch", "nl_NL", known)).is_equal(Lang.ENGLISH)
	assert_str(Lang.resolve("zh_CN", "", "", known)).is_equal(Lang.ENGLISH)


func test_automatic_is_steams_language_then_the_systems_then_english() -> void:
	var known: Array[String] = [Lang.ENGLISH, DUTCH, "zh_CN"]
	assert_str(Lang.resolve("", "dutch", "en_US.UTF-8", known)).is_equal(DUTCH)
	assert_str(Lang.resolve("", "german", "nl_BE.UTF-8", known)).is_equal(DUTCH)
	assert_str(Lang.resolve("", "", "nl", known)).is_equal(DUTCH)
	assert_str(Lang.resolve("", "", "fr_FR", known)).is_equal(Lang.ENGLISH)
	assert_str(Lang.resolve("", "", "", known)).is_equal(Lang.ENGLISH)


func test_chinese_is_matched_by_script() -> void:
	var known: Array[String] = [Lang.ENGLISH, "zh_CN"]
	assert_str(Lang.resolve("", "schinese", "", known)).is_equal("zh_CN")
	assert_str(Lang.resolve("", "", "zh_SG", known)).is_equal("zh_CN")
	assert_str(Lang.resolve("", "", "zh_Hans_CN", known)).is_equal("zh_CN")
	assert_str(Lang.resolve("", "", "zh_TW", known)).is_equal(Lang.ENGLISH)
	assert_str(Lang.resolve("", "", "zh_Hant_HK", known)).is_equal(Lang.ENGLISH)


## The game's own translations are offered, English first, with Dutch's and Chinese's files in the
## project.
func test_english_is_spoken_first_and_each_translation_after() -> void:
	assert_array(Lang.spoken()).contains_exactly([Lang.ENGLISH, DUTCH, "zh_CN"])


## Steam is handed words in every language the game speaks, each in its own whatever is spoken.
func test_words_for_steam_are_in_the_language_asked() -> void:
	assert_dict(Lang.on_steam()).is_equal(
		{"english": Lang.ENGLISH, "dutch": DUTCH, "schinese": "zh_CN"}
	)
	# A language of the test's own, so the game's Dutch file is not asked.
	var own := Translation.new()
	own.locale = "eo"
	own.add_message("Steer", "Stiri")
	own.add_message("Steer", "Direkti", &"boat")
	TranslationServer.add_translation(own)
	Lang.apply(Lang.ENGLISH)
	assert_str(Lang.t_in("eo", "Steer")).is_equal("Stiri")
	assert_str(Lang.t_in("eo", "Steer", &"boat")).is_equal("Direkti")
	assert_str(Lang.t_in("eo", "Brake")).is_equal("Brake")
	assert_str(Lang.t_in("fr", "Steer")).is_equal("Steer")
	assert_str(Lang.t_in(Lang.ENGLISH, "Steer")).is_equal("Steer")
	assert_str(Lang.t("Steer")).is_equal("Steer")
	TranslationServer.remove_translation(own)


func test_numbers_and_lists_are_written_as_the_language_writes_them() -> void:
	Lang.apply(Lang.ENGLISH)
	assert_str(Lang.number(1204388)).is_equal("1,204,388")
	assert_str(Lang.number(-1500)).is_equal("-1,500")
	assert_str(Lang.number(999)).is_equal("999")
	assert_str(Lang.decimal(1.25, 1)).is_equal("1.2")
	assert_str(Lang.listed(["Ann"])).is_equal("Ann")
	assert_str(Lang.listed(["Ann", "Bo", "Cy"])).is_equal("Ann, Bo and Cy")
	assert_str(Lang.tn("%d chip", "%d chips", 2) % 2).is_equal("2 chips")
	Lang.apply(DUTCH)
	assert_str(Lang.number(1204388)).is_equal("1.204.388")
	assert_str(Lang.decimal(1.5, 1)).is_equal("1,5")
	assert_str(Lang.listed(["Ann", "Bo", "Cy"])).is_equal("Ann, Bo en Cy")
	assert_str(Lang.tn("%d chip", "%d chips", 1) % 1).is_equal("1 fiche")
	assert_str(Lang.tn("%d chip", "%d chips", 3) % 3).is_equal("3 fiches")


## A word marked to be translated later comes back as it is.
func test_a_word_for_later_is_kept_in_english() -> void:
	Lang.apply(DUTCH)
	assert_str(Lang.later("{some} and {last}")).is_equal("{some} and {last}")
	assert_str(Lang.t("{some} and {last}")).is_equal("{some} en {last}")


## Words for another machine go in English with their values packed beside them, and come out in
## the language spoken where they arrive: its numbers, a name as it is, words packed among the
## values said in turn. Plain English marked for later is looked up as it is.
func test_words_from_another_machine_are_said_in_the_language_spoken_here() -> void:
	var paid := Lang.message("{name} paid {chips}", {"name": "Ann", "chips": 1500})
	var left := Lang.message_n("{count} table left", "{count} tables left", 3)
	var told := Lang.message("{who} said: {what}", {"who": "Bo", "what": Lang.message("Bye")})
	Lang.apply(Lang.ENGLISH)
	assert_str(Lang.said(paid)).is_equal("Ann paid 1,500")
	assert_str(Lang.said(left)).is_equal("3 tables left")
	assert_str(Lang.said(told)).is_equal("Bo said: Bye")
	Lang.apply(DUTCH)
	assert_str(Lang.said(paid)).is_equal("Ann betaalde 1.500")
	assert_str(Lang.said(left)).is_equal("3 tafels over")
	assert_str(Lang.said(Lang.message_n("{count} table left", "{count} tables left", 1))).is_equal(
		"1 tafel over"
	)
	assert_str(Lang.said(told)).is_equal("Bo zei: Doei")
	assert_str(Lang.said(Lang.message("+{mult} MULT", {"mult": 1.5}))).is_equal("+1,5 MULT")
	assert_str(Lang.said(Lang.message("+{mult} MULT", {"mult": 2}))).is_equal("+2 MULT")
	assert_str(Lang.said(Lang.later("Bye"))).is_equal("Doei")
	# Braces that are not packed words are words like any other.
	assert_str(Lang.said("{some} and {last}")).is_equal("{some} en {last}")
	assert_str(Lang.said("{nobody's words}")).is_equal("{nobody's words}")


## Packed words are part of what goes over the wire, GAME.md 10.3: their fields keep the names they
## have, so words a later version sends are said by an earlier one, which leaves out a field it
## does not know, and a change to the words never needs a new protocol.
func test_packed_words_keep_their_fields() -> void:
	var json := JSON.new()
	assert_int(json.parse(Lang.message_n("{count} table left", "x", 2, {"a": 1}, &"b"))).is_zero()
	assert_dict(json.data).contains_keys(["words", "many", "count", "values", "context"])
	assert_str(json.data["words"]).is_equal("{count} table left")
	Lang.apply(DUTCH)
	var later := '{"words": "{name} paid {chips}", "values": {"name": "Cy", "chips": 7}, "new": 1}'
	assert_str(Lang.said(later)).is_equal("Cy betaalde 7")


## A script's run speaks English whatever the machine is set to, the tests' own among them.
func test_a_scripts_run_speaks_english() -> void:
	Game.speak()
	assert_str(Lang.current).is_equal(Lang.ENGLISH)


## A place as the House prints it, by the rule of the language spoken.
func test_a_place_is_written_as_the_language_writes_it() -> void:
	Lang.apply(Lang.ENGLISH)
	var english: Array[String] = []
	for place: int in [1, 2, 3, 4, 11, 12, 13, 21, 22, 101, 111]:
		english.append(Lang.ordinal(place))
	assert_array(english).is_equal(
		["1ST", "2ND", "3RD", "4TH", "11TH", "12TH", "13TH", "21ST", "22ND", "101ST", "111TH"]
	)
	assert_str(Timeline.ordinal(2)).is_equal("2nd")
	Lang.apply(DUTCH)
	assert_str(Lang.ordinal(1)).is_equal("1E")
	assert_str(Lang.ordinal(12)).is_equal("12E")
	assert_str(Timeline.ordinal(3)).is_equal("3e")


## A picture with words in it is the one drawn for the language spoken, where there is one, and the
## English otherwise, however often the language changes.
func test_a_picture_with_words_is_the_one_for_the_language_spoken() -> void:
	Lang.apply(DUTCH)
	assert_str(Lang.picture(HouseRail.PRINT).resource_path).ends_with("rail_print.nl.png")
	Lang.apply(Lang.ENGLISH)
	assert_str(Lang.picture(HouseRail.PRINT).resource_path).ends_with("rail_print.png")
	Lang.apply("zh_CN")
	assert_str(Lang.picture(WorkbenchStyle.SLATE).resource_path).ends_with(
		"kit_chalkboard.zh_CN.png"
	)
	# A language with no picture of its own drawn yet shows the English.
	Lang.current = "eo"
	assert_str(Lang.picture(WorkbenchStyle.SLATE).resource_path).ends_with("kit_chalkboard.png")


## An exported game breaks a line of Chinese only with the text server's data for it, which the
## editor carries built in and an export takes along only with this setting: without it a line
## breaks at its spaces alone, and Chinese has none.
func test_an_exported_game_carries_what_breaks_a_line_of_chinese() -> void:
	var setting := "internationalization/locale/include_text_server_data"  # NO_TRANSLATE
	assert_bool(ProjectSettings.get_setting(setting, false)).is_true()
	var server := TextServerManager.get_primary_interface()
	assert_bool(server.has_feature(TextServer.FEATURE_BREAK_ITERATORS)).is_true()
	assert_str(server.get_support_data_filename()).is_equal("icudt_godot.dat")


## Two sentences run on with a space between in English, and with none after a Chinese full stop,
## GAME.md 10.9.
func test_sentences_run_on_as_the_language_runs_them() -> void:
	assert_str(Lang.sentences("Stacks.", "Copying Big Tank.")).is_equal("Stacks. Copying Big Tank.")
	assert_str(Lang.sentences("可叠加。", "正在复制。")).is_equal("可叠加。正在复制。")  # NO_TRANSLATE
	assert_str(Lang.sentences("", "Stacks.")).is_equal("Stacks.")
	assert_str(Lang.sentences("Stacks.", "")).is_equal("Stacks.")
