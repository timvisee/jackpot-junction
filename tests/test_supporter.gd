extends GdUnitTestSuite
## The Steam supporter pack, GAME.md 10.8: owned or not as Steam said at the start, and offered
## only in a Steam build, a debug build pretending either way.

const PATH := "user://test_supporter.cfg"

var _settings_were: Settings
var _holder: Control


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	_holder = Control.new()
	add_child(_holder)


func after_test() -> void:
	Supporter.start(PackedStringArray(), false, false)
	if is_instance_valid(_holder):
		remove_child(_holder)
		_holder.free()
	Settings.remove_files(PATH)
	Game.settings = _settings_were


## A debug build reads `--supporter` as owned and `--supporter=locked` as offered and locked; with
## neither, and no Steam, the pack is neither owned nor offered.
func test_a_debug_build_pretends_either_way() -> void:
	Supporter.start(PackedStringArray(), false, false)
	assert_bool(Supporter.owned()).is_false()
	assert_bool(Supporter.offered()).is_false()
	Supporter.start(PackedStringArray(["--supporter"]), false, false)
	assert_bool(Supporter.owned()).is_true()
	assert_bool(Supporter.offered()).is_true()
	Supporter.start(PackedStringArray(["--supporter=locked"]), true, true)
	assert_bool(Supporter.owned()).is_false()
	assert_bool(Supporter.offered()).is_true()


## Without pretending, it is what Steam said at the start: a Steam build offers the pieces, owned or
## not, and a build from GitHub does not.
func test_otherwise_it_is_steams_word_at_the_start() -> void:
	Supporter.start(PackedStringArray(), true, true)
	assert_bool(Supporter.owned()).is_true()
	assert_bool(Supporter.offered()).is_true()
	Supporter.start(PackedStringArray(), false, true)
	assert_bool(Supporter.owned()).is_false()
	assert_bool(Supporter.offered()).is_true()
	Supporter.set_owned(true)
	assert_bool(Supporter.owned()).is_true()
