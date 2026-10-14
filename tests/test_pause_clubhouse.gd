extends GdUnitTestSuite
## The Clubhouse in a room's pause menu, GAME.md 3.8: what of the title's can be had in a room, the
## loyalty program, the catalog and the achievements, behind one button, and the NEW tags it wears,
## see [PauseMenu].

const PATH := "user://test_pause_clubhouse.cfg"

var _settings_were: Settings
var _holder: Control


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	Game.settings.profile.story.on = false
	var state := Game.settings.profile.loyalty
	state.welcomed = true
	state.win(&"slip_road")
	state.look_at(&"slip_road")
	_holder = Control.new()
	_holder.size = Vector2(1600.0, 900.0)
	add_child(_holder)


func after_test() -> void:
	Story.override = -1
	LoyaltyDialog.listed = false
	LoyaltyDialog.stood_at = &""
	get_tree().paused = false
	if is_instance_valid(_holder):
		remove_child(_holder)
		_holder.free()
	Settings.remove_files(PATH)
	Game.settings = _settings_were


## A room's pause menu has the Clubhouse, GAME.md 3.8: its button puts the program's button up in
## place of the menu's own, the cursor on it, once the profile playing is welcomed, then the
## catalog's, the achievements' and Back, and none of the Garage or the Driving School. Each opens
## over the menu. Back, or B, is the menu's own buttons again with the cursor on the Clubhouse, and
## the menu opens on its own buttons whatever it was put away on. The Operator's is the Staff Room.
func test_the_pause_menus_clubhouse_opens_it() -> void:
	var menu := PauseMenu.add_to(_holder)
	# Up as it comes up, without stopping the tree, which would stop the test with it.
	menu._panel.visible = true
	await get_tree().process_frame
	var clubhouse := menu.find_child("ClubhouseButton", true, false) as Button
	assert_str(clubhouse.text).is_equal("Clubhouse")
	assert_bool(menu.in_clubhouse()).is_false()
	assert_array(_names(menu._club_buttons())).is_equal(
		["Loyalty", "Catalog", "Achievements", "ClubhouseBack"]
	)
	for room: String in ["Garage", "DrivingSchool"]:
		assert_object(menu.find_child(room, true, false)).is_null()
	clubhouse.pressed.emit()
	assert_bool(menu.in_clubhouse()).is_true()
	assert_bool(menu._resume.is_visible_in_tree()).is_false()
	var program := menu._club_buttons()[0]
	assert_str(program.text).is_equal("Loyalty Program")
	assert_bool(program.has_focus()).is_true()
	program.pressed.emit()
	await get_tree().process_frame
	assert_object(menu.find_child("Loyalty", false, false)).is_instanceof(LoyaltyDialog)
	menu._loyalty.close()
	(menu.find_child("Catalog", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	assert_object(menu.find_child("Catalog", false, false)).is_instanceof(CatalogDialog)
	menu._catalog.close()
	for frame: int in 30:
		await get_tree().process_frame
	var back := InputEventAction.new()
	back.action = &"ui_cancel"
	back.pressed = true
	menu._unhandled_input(back)
	assert_bool(menu.in_clubhouse()).is_false()
	assert_bool(menu._resume.is_visible_in_tree()).is_true()
	assert_bool(clubhouse.has_focus()).is_true()
	clubhouse.pressed.emit()
	menu._panel.visible = false
	menu.set_paused(true)
	get_tree().paused = false
	assert_bool(menu.in_clubhouse()).is_false()
	assert_bool(menu._resume.has_focus()).is_true()
	menu.free()
	# Not welcomed yet: no program's button. The Operator's is the Staff Room, STORY.md 8.6.
	Game.settings.profile.loyalty.welcomed = false
	Story.override = Story.Stage.OPERATOR
	menu = PauseMenu.add_to(_holder)
	await get_tree().process_frame
	assert_array(_names(menu._club_buttons())).is_equal(
		["Catalog", "Achievements", "ClubhouseBack"]
	)
	var staff := menu.find_child("ClubhouseButton", true, false) as Button
	assert_str(staff.text).is_equal(StoryLines.STAFF_ROOM)
	menu.free()


## The pause menu's Clubhouse wears the NEW tag as the title's does, GAME.md 3.8, and so does each
## button in it with something unseen behind it; put away, what was seen takes its tag off.
func test_the_pause_menus_clubhouse_is_tagged_new() -> void:
	var profile := Game.settings.profile
	profile.catalog.fresh = PackedStringArray(["payday"])
	var menu := PauseMenu.add_to(_holder)
	await get_tree().process_frame
	var clubhouse := menu.find_child("ClubhouseButton", true, false) as Button
	var cards := menu.find_child("Catalog", true, false) as Button
	var program := menu.find_child("Loyalty", true, false) as Button
	assert_object(clubhouse.get_node_or_null("New")).is_not_null()
	assert_object(cards.get_node_or_null("New")).is_not_null()
	assert_object(program.get_node_or_null("New")).is_null()
	profile.catalog.fresh = PackedStringArray()
	profile.loyalty.owed = 1
	menu.open_catalog()
	menu._catalog.close()
	for frame: int in 30:
		await get_tree().process_frame
	assert_object(menu._catalog).is_null()
	assert_object(cards.get_node_or_null("New")).is_null()
	assert_object(program.get_node_or_null("New")).is_not_null()
	assert_object(clubhouse.get_node_or_null("New")).is_not_null()
	profile.loyalty.owed = 0
	menu._tag_fresh()
	assert_object(clubhouse.get_node_or_null("New")).is_null()
	menu.free()


func _names(buttons: Array[Button]) -> Array[String]:
	var names: Array[String] = []
	for button: Button in buttons:
		names.append(String(button.name))
	return names
