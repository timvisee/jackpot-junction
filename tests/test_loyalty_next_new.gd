extends GdUnitTestSuite
## Next new on the loyalty program's map, GAME.md 8.8 and 8.9: the cursor set down at once at each
## landmark won and not yet looked at, in the map's order, the House's sheet and then Kit's, round
## past the last; never waiting on the kart's drive; from the list; by its bind; and the head with
## it in on the screen, see [LoyaltyNextNew] and [NextNew].

const PATH := "user://test_loyalty_next_new.cfg"

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
	LoyaltyDialog.listed = false
	LoyaltyDialog.stood_at = &""
	# Gone before the scratch files are: a dialog going keeps the NEW tags it cleared.
	if is_instance_valid(_holder):
		remove_child(_holder)
		_holder.free()
	Settings.remove_files(PATH)
	Game.settings = _settings_were


func _open() -> LoyaltyDialog:
	var dialog := LoyaltyDialog.open(_holder)
	await get_tree().process_frame
	await get_tree().process_frame
	return dialog


## Next new, GAME.md 8.9: how many landmarks drawn wear NEW over its corner, and pressed, the
## cursor set down at once at the next of them after the one the pane says, in the map's order, the
## House's sheet and then Kit's, turned to its sheet, which takes the tag off, its sheet's tab's
## too, kept as the dialog goes; gone once none is new.
func test_next_new_sets_the_cursor_down_at_each_new_landmark() -> void:
	var profile := Game.settings.profile
	profile.story.on = true
	profile.story.notes = PackedInt32Array([1])
	var fresh: Array[StringName] = [&"dealers_visor", &"racing_stripes", &"pencil_trail"]
	for id: StringName in fresh:
		profile.loyalty.win(id)
	assert_array(LoyaltyNextNew.order(profile)).contains(fresh)
	assert_int(LoyaltyNextNew.order(profile).find(&"pencil_trail")).is_greater(
		LoyaltyNextNew.order(profile).find(&"racing_stripes")
	)
	var dialog := await _open()
	var next := dialog.next_new
	assert_bool(next.visible).is_true()
	assert_str(next.count.text).is_equal("3")
	assert_int(next.button.focus_mode).is_equal(Control.FOCUS_NONE)
	assert_int(next.button.mouse_default_cursor_shape).is_equal(Control.CURSOR_POINTING_HAND)
	for i: int in fresh.size():
		next.button.pressed.emit()
		assert_str(String(dialog.cursor.at)).is_equal(String(fresh[i]))
		assert_str(String(dialog.pane.shown)).is_equal(String(fresh[i]))
		assert_bool(dialog.cursor.is_driving()).is_false()
		assert_bool(profile.loyalty.is_fresh(fresh[i])).is_false()
		assert_str(next.count.text).is_equal(str(fresh.size() - 1 - i))
		# Said as the cursor coming to it by hand says it.
		assert_str(ScreenReader.said(dialog.map_view)).contains(dialog.pane._name.text)
	assert_int(dialog.map_view.sheet).is_equal(LoyaltyMapLayout.Sheet.KIT)
	assert_int(dialog.sheet_tabs.current_tab).is_equal(LoyaltyMapLayout.Sheet.KIT)
	assert_object(dialog.sheet_tabs.tags.of(LoyaltyMapLayout.Sheet.HOUSE)).is_null()
	assert_object(dialog.sheet_tabs.tags.of(LoyaltyMapLayout.Sheet.KIT)).is_null()
	assert_bool(next.visible).is_false()
	dialog.close()
	await get_tree().process_frame
	var kept := Settings.new()
	kept.path = PATH
	kept.load_from_disk()
	for id: StringName in fresh:
		assert_bool(kept.profile.loyalty.is_fresh(id)).is_false()


## Pressed while the kart drives, it is set down at once, never waiting on the drive; from a
## landmark after the last new one it goes round to the first; and its bind, N or a pad's View,
## presses it, but not while the card in full is up over the map.
func test_next_new_skips_the_drive_goes_round_and_has_its_bind() -> void:
	var profile := Game.settings.profile
	profile.loyalty.win(&"rare_cards")
	profile.loyalty.win(&"chip_trail")
	var dialog := await _open()
	dialog.map_view.drive_to(&"racing_stripes")
	assert_bool(dialog.cursor.is_driving()).is_true()
	var press := InputEventKey.new()
	press.physical_keycode = KEY_N
	press.keycode = KEY_N
	press.pressed = true
	dialog._input(press)
	assert_bool(dialog.cursor.is_driving()).is_false()
	assert_str(String(dialog.cursor.at)).is_equal("rare_cards")
	assert_vector(dialog.cursor.point).is_not_equal(Vector2.ZERO)
	dialog.show_card()
	var view := InputEventJoypadButton.new()
	view.button_index = JOY_BUTTON_BACK
	view.pressed = true
	dialog._input(view)
	LoyaltyNextNew.jump(dialog)
	assert_str(String(dialog.cursor.at)).is_equal("rare_cards")
	# Put away, said at once, the dialog hears its keys again.
	dialog.card_view.close()
	assert_object(dialog.card_view).is_null()
	dialog._input(view)
	assert_str(String(dialog.cursor.at)).is_equal("chip_trail")
	assert_bool(dialog.next_new.visible).is_false()


## From the list of open bets, which never holds a landmark won, Next new puts the map back, the
## cursor at the next new landmark on it.
func test_next_new_from_the_list() -> void:
	Game.settings.profile.loyalty.win(&"dealers_visor")
	LoyaltyDialog.listed = true
	var dialog := await _open()
	await get_tree().process_frame
	assert_bool(dialog.list.visible).is_true()
	dialog.next_new.button.pressed.emit()
	assert_bool(LoyaltyDialog.listed).is_false()
	assert_bool(dialog.list.visible).is_false()
	assert_bool(dialog.map_view.visible).is_true()
	assert_str(String(dialog.cursor.at)).is_equal("dealers_visor")
	assert_bool(dialog.map_view.has_focus()).is_true()


## At 200% on a screen 1920 by 1080, keys in hand and a landmark new, the head with Next new in it
## stays on the screen, the switch and Back with it.
func test_the_head_keeps_next_new_in_the_room() -> void:
	Game.settings.profile.loyalty.win(&"dealers_visor")
	var screen := get_tree().root
	var scale_was := screen.content_scale_factor
	var size_was := screen.size
	screen.size = Vector2i(1920, 1080)
	screen.content_scale_factor = 2.0
	var dialog := await _open()
	dialog._keyboard = true
	dialog._pointer = false
	dialog._show_binds()
	await get_tree().process_frame
	await get_tree().process_frame
	var room := screen.get_visible_rect().grow(1.0)
	var held: Array[bool] = [
		dialog.next_new.visible,
		room.encloses(dialog._pane.get_global_rect()),
		room.encloses(dialog.next_new.get_global_rect()),
		room.encloses(dialog.list_switch.get_global_rect()),
		room.encloses(dialog.back.get_global_rect()),
	]
	screen.content_scale_factor = scale_was
	screen.size = size_was
	assert_array(held).not_contains([false])
