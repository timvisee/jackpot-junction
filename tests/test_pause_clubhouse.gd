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


## On a touch screen a finger on a dialog opened over the menu is the dialog's, GAME.md 4.2: the
## menu's list under it, worked by finger, neither scrolls nor presses the button under the finger,
## see [method TouchInput.keep_touches]. Each of the Clubhouse's dialogs in turn.
func test_a_finger_on_a_dialog_is_not_the_menus() -> void:
	var was_touch := TouchInput.enabled
	TouchInput.enabled = true
	var menu := PauseMenu.add_to(_holder)
	menu._panel.visible = true
	await get_tree().process_frame
	(menu.find_child("ClubhouseButton", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	var pressed: Array[String] = []
	var buttons := menu._club_buttons()
	for button: Button in buttons:
		button.pressed.connect(func() -> void: pressed.append(button.name))
	# On a button of the menu's, not in the gap between two.
	var middle := buttons[1].get_global_rect().get_center()
	for named: String in ["_loyalty", "_catalog", "_achievements"]:
		match named:
			"_loyalty":
				menu.open_loyalty()
			"_catalog":
				menu.open_catalog()
			_:
				menu.open_achievements()
		for i: int in 4:
			await get_tree().process_frame
		var dialog := menu.get(named) as CanvasLayer
		assert_object(dialog).override_failure_message("no %s" % named).is_not_null()
		_phone_tap(middle)
		await get_tree().process_frame
		assert_array(pressed).override_failure_message("through %s" % named).is_empty()
		assert_object(menu.get(named)).override_failure_message("%s shut" % named).is_same(dialog)
		dialog.call("close")
		for i: int in 30:
			await get_tree().process_frame
	TouchInput.enabled = was_touch


## A dialog keeps the touches from what is drawn under it alone: a menu on a higher layer, the
## pause menu opened over the host's match settings say, keeps its own, and a dialog put away or
## hidden keeps nothing.
func test_a_dialog_keeps_touches_from_what_is_under_it() -> void:
	var menu := PauseMenu.add_to(_holder)
	var list: Node = menu._list
	var lower := CanvasLayer.new()
	lower.layer = PauseMenu.LAYER - 2
	_holder.add_child(lower)
	TouchInput.keep_touches(lower)
	assert_bool(TouchInput.kept_from(list)).is_false()
	var upper := CanvasLayer.new()
	upper.layer = PauseMenu.LAYER + 5
	_holder.add_child(upper)
	TouchInput.keep_touches(upper)
	assert_bool(TouchInput.kept_from(list)).is_true()
	assert_bool(TouchInput.kept_from(upper)).is_false()
	upper.visible = false
	assert_bool(TouchInput.kept_from(list)).is_false()
	upper.visible = true
	upper.queue_free()
	await get_tree().process_frame
	assert_bool(TouchInput.kept_from(list)).is_false()


## A tap at [param at] as a phone tells it: the mouse it makes of the finger first, then the finger.
func _phone_tap(at: Vector2) -> void:
	var viewport := get_viewport()
	for down: bool in [true, false]:
		var mouse := InputEventMouseButton.new()
		mouse.device = InputEvent.DEVICE_ID_EMULATION
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.pressed = down
		mouse.position = at
		viewport.push_input(mouse, true)
		var touch := InputEventScreenTouch.new()
		touch.position = at
		touch.pressed = down
		viewport.push_input(touch, true)
	var away := InputEventMouseMotion.new()
	away.position = Vector2(-100.0, -100.0)
	viewport.push_input(away, true)
