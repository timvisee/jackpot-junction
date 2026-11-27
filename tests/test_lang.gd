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


## The game's own translations are offered, English first, with Dutch's file in the project.
func test_english_is_spoken_first_and_each_translation_after() -> void:
	assert_array(Lang.spoken()).contains_exactly([Lang.ENGLISH, DUTCH])


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
