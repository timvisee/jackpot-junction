extends GdUnitTestSuite
## The settings' pages in groups under headings, GAME.md 8.5, see [SettingsColumns]: on a 1080p
## screen at the UI's own size each stands in two columns, its widest row fitting half the page.

const SETTINGS_SCENE := preload("res://scenes/ui/settings_screen.tscn")
const GROUPED: Array[String] = ["Controls", "Video", "Accessibility"]

var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_settings_columns.cfg"


func after_test() -> void:
	Settings.remove_files(Game.settings.path)
	Game.settings = _settings_were


func test_the_grouped_pages_take_two_columns_on_a_1080p_screen() -> void:
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	screen.size = Vector2(1920.0, 1080.0)
	for page_name: String in GROUPED:
		screen.tabs.current_tab = screen.tabs.get_node(page_name).get_index()
		await await_idle_frame()
		await await_idle_frame()
		var groups := screen.tabs.get_node(page_name + "/Groups") as SettingsColumns
		assert_bool(groups.two_columns(groups.size.x)).override_failure_message(page_name).is_true()
