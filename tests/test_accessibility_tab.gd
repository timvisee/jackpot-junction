extends GdUnitTestSuite
## The Accessibility page of the settings, GAME.md 8.5: its rows in groups under headings, in two
## columns on a 1080p screen as the Video page's are, see test_settings_columns.gd.

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
		AccessibilityTab.HUD
	]
	assert_array(headings).is_equal(groups)
	assert_int(page._groups.split).is_equal(2)
	assert_array(_rows(page, AccessibilityTab.SEEING)).contains_exactly(
		["Color blindness", "", "Kart rings", "Marker over my kart"]
	)
	var preview := page.get_node("Groups/%s" % AccessibilityTab.SEEING).find_child(
		"KartMarksPreview", true, false
	)
	assert_object(preview).is_instanceof(KartMarksPreview)
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
	assert_array(_rows(page, AccessibilityTab.HUD)).contains_exactly(
		["See-through HUD", "Speed in", "Control hints", "Always show drive hints"]
	)
