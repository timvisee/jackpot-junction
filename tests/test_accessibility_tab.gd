extends GdUnitTestSuite
## The Accessibility page of the settings, GAME.md 8.5: its rows in groups under headings, in two
## columns on a 1080p screen as the Video page's are.

const SETTINGS_SCENE := preload("res://scenes/ui/settings_screen.tscn")

var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_accessibility_tab.cfg"


func after_test() -> void:
	Settings.remove_files(Game.settings.path)
	Game.settings = _settings_were


## The names of the rows under the heading [param group] on [param page].
static func _rows(page: Control, group: String) -> Array[String]:
	var names: Array[String] = []
	for row: Node in page.get_node("Groups/" + group).get_children():
		var label := row.get_child(0) as Label
		if row.name != "Heading" and label != null:
			names.append(label.text)
	return names


func test_the_rows_stand_in_groups_under_headings() -> void:
	var page: AccessibilityTab = auto_free(AccessibilityTab.make(Game.settings))
	add_child(page)
	var headings: Array[String] = []
	for each: Node in page._groups.get_children():
		headings.append((each.get_node("Heading/Title") as Label).text)
	var groups: Array[String] = [
		AccessibilityTab.SEEING,
		AccessibilityTab.MOTION,
		AccessibilityTab.AIMING,
		AccessibilityTab.HINTS
	]
	assert_array(headings).is_equal(groups)
	assert_int(page._groups.split).is_equal(2)
	assert_array(_rows(page, AccessibilityTab.SEEING)).contains_exactly(
		["Color blindness", "Kart rings", "Marker over my kart", "See-through HUD", "Speed in"]
	)
	var motion: Array[String] = [
		"Screen shake",
		"Rumble",
		"Fixed camera",
		"Cursor glide",
		"Reduce flashing",
		"Disco lights",
		"Crowd",
	]
	assert_array(_rows(page, AccessibilityTab.MOTION)).contains_exactly(motion)
	assert_array(_rows(page, AccessibilityTab.AIMING)).contains_exactly(
		["Aim assist strength", "Aim guide"]
	)
	assert_object(page.get_node("Groups/%s/AimGuideRows" % AccessibilityTab.AIMING)).is_not_null()
	assert_array(_rows(page, AccessibilityTab.HINTS)).contains_exactly(
		["Control hints", "Always show drive hints"]
	)


## On a 1080p screen at the UI's own size both grouped pages stand in two columns: the widest of
## their rows, the color blindness choice with its swatches and the aim guide's preview, fit half
## the page.
func test_both_grouped_pages_take_two_columns_on_a_1080p_screen() -> void:
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	screen.size = Vector2(1920.0, 1080.0)
	for page_name: String in ["Video", "Accessibility"]:
		screen.tabs.current_tab = screen.tabs.get_node(page_name).get_index()
		await await_idle_frame()
		await await_idle_frame()
		var groups := screen.tabs.get_node(page_name + "/Groups") as SettingsColumns
		assert_bool(groups.two_columns(groups.size.x)).override_failure_message(page_name).is_true()
