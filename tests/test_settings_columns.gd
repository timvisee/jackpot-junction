extends GdUnitTestSuite
## The settings' pages in groups under headings, GAME.md 8.5, see [SettingsColumns]: on a 1080p
## screen at the UI's own size each stands in two columns, its widest row fitting half the page.

const SETTINGS_SCENE := preload("res://scenes/ui/settings_screen.tscn")
const GROUPED: Array[String] = ["Controls", "Audio", "Video", "Accessibility"]

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


## The Audio page: how loud each part of the sound is down the left, how the music behaves down
## the right.
func test_the_audio_page_has_volume_and_music() -> void:
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	var groups := screen.tabs.get_node("Audio/Groups") as SettingsColumns
	var rows: Dictionary[String, Array] = {}
	for each: Node in groups.get_children():
		var names: Array[String] = []
		for row: Node in each.get_children():
			if row.name != "Heading":
				names.append((row.get_child(0) as Label).text)
		rows[(each.get_node("Heading/Title") as Label).text] = names
	assert_array(rows.keys()).is_equal([SettingsScreen.VOLUME, SettingsScreen.MUSIC])
	assert_int(groups.split).is_equal(1)
	assert_array(rows[SettingsScreen.VOLUME]).is_equal(["Master", "Music", "Effects", "Karts"])
	var music: Array[String] = ["Intense music", "Music muted", "Muffle music on death"]
	assert_array(rows[SettingsScreen.MUSIC]).is_equal(music)


## The Statistics page's groups and the sections under the license head themselves as the grouped
## pages do, a title in capitals with a dotted rule after it, see [method SettingsColumns.group].
func test_the_statistics_and_license_sections_wear_the_headings() -> void:
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	for page_name: String in ["Statistics", "License"]:
		screen.tabs.current_tab = screen.tabs.get_node(page_name).get_index()
		await await_idle_frame()
		var page := screen.tabs.get_node(page_name)
		var headed := 0
		for node: Node in page.find_children("Heading", "HBoxContainer", true, false):
			var title := node.get_node_or_null("Title") as Label
			if title != null and title.uppercase:
				headed += 1
		assert_int(headed).override_failure_message(page_name).is_greater_equal(4)


## In one column, as under a big UI scale on a television, the cursor walks down each grouped page
## through every group to its foot: the engine looked for the next control only in the part of the
## page that showed, so down from the foot of Driving found nothing past Fighting's heading.
func test_the_cursor_walks_down_every_group_in_one_column() -> void:
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	screen.size = Vector2(900.0, 520.0)
	for page_name: String in GROUPED:
		screen.tabs.current_tab = screen.tabs.get_node(page_name).get_index()
		await await_idle_frame()
		await await_idle_frame()
		var groups := screen.tabs.get_node(page_name + "/Groups") as SettingsColumns
		(
			assert_bool(groups.two_columns(groups.size.x))
			. override_failure_message(page_name)
			. is_false()
		)
		var wanted: Array[String] = []
		for group: Node in groups.get_children():
			if not SettingsColumns._takers([group as Control]).is_empty():
				wanted.append(str(group.name))
		var reached: Array[String] = []
		var at := screen._first_focusable(screen.tabs.get_current_tab_control())
		var steps := 0
		while at != null and steps < 200:
			steps += 1
			for group: Node in groups.get_children():
				if group.is_ancestor_of(at) and not reached.has(str(group.name)):
					reached.append(str(group.name))
			at = at.find_valid_focus_neighbor(SIDE_BOTTOM)
		assert_array(reached).override_failure_message(page_name).is_equal(wanted)
