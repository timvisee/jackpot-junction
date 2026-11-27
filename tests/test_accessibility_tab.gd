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
		AccessibilityTab.HUD,
		AccessibilityTab.LANGUAGE,
	]
	assert_array(headings).is_equal(groups)
	assert_int(page._groups.split).is_equal(2)
	assert_array(_rows(page, AccessibilityTab.SEEING)).contains_exactly(
		["Color blindness", "", "Kart rings", "Marker over my kart", "Rival arrows"]
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
	assert_array(_rows(page, AccessibilityTab.LANGUAGE)).contains_exactly(["Language"])


## The Language row, GAME.md 10.9: Automatic first, then each language there is a translation
## into by its own name; from over a room it is changed from the title screen instead.
func test_the_language_row_offers_each_language_by_its_own_name() -> void:
	var page: AccessibilityTab = auto_free(AccessibilityTab.make(Game.settings))
	add_child(page)
	var choice := page.find_child("Languages", true, false) as OptionButton
	var words: Array[String] = []
	for index: int in choice.item_count:
		words.append(choice.get_item_text(index))
	assert_str(words[0]).starts_with("Automatic (")
	assert_array(words.slice(1)).contains_exactly(["English", "Nederlands", "简体中文"])
	assert_int(choice.selected).is_equal(0)
	assert_bool(choice.disabled).is_false()
	var over: AccessibilityTab = auto_free(AccessibilityTab.make(Game.settings, true))
	add_child(over)
	assert_bool((over.find_child("Languages", true, false) as OptionButton).disabled).is_true()


## Rumble switched on knocks every pad plugged in, so it is felt that it is; switched off, none.
func test_rumble_switched_on_knocks_every_pad() -> void:
	var knocked: Array[int] = []
	var was := DeviceInput.steam_rumble
	DeviceInput.steam_rumble = func(device: int, _weak: float, _strong: float, _for: float) -> void:
		knocked.append(device)
	DeviceInput.steam_pads[SteamPads.FIRST_DEVICE] = PadFamily.Family.PLAYSTATION_4
	DeviceInput.steam_pads[SteamPads.FIRST_DEVICE + 1] = PadFamily.Family.XBOX
	Game.settings.rumble = false
	var page: AccessibilityTab = auto_free(AccessibilityTab.make(Game.settings))
	add_child(page)
	var row: Node = null
	for each: Node in page.get_node("Groups/" + AccessibilityTab.MOTION).get_children():
		var label := each.get_child(0) as Label
		if label != null and label.text == "Rumble":
			row = each
	var switch := row.find_children("*", "CheckButton", true, false)[0] as CheckButton
	switch.button_pressed = true
	assert_bool(Game.settings.rumble).is_true()
	assert_array(knocked).contains([SteamPads.FIRST_DEVICE, SteamPads.FIRST_DEVICE + 1])
	var count := knocked.size()
	switch.button_pressed = false
	assert_int(knocked.size()).is_equal(count)
	DeviceInput.steam_pads.clear()
	DeviceInput.steam_rumble = was


## Every box to pick from on the page is as tall as the house's, Color blindness's among them.
func test_every_choice_is_as_tall_as_the_others() -> void:
	var page: AccessibilityTab = auto_free(AccessibilityTab.make(Game.settings))
	add_child(page)
	var boxes := page.find_children("*", "OptionButton", true, false)
	assert_int(boxes.size()).is_greater(4)
	for box: OptionButton in boxes:
		assert_float(box.get_combined_minimum_size().y).is_equal(MenuTheme.box_height())
