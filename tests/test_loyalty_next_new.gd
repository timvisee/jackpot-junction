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
	# Left at the slip road, which the map opens at, the order counted from there.
	LoyaltyDialog.stood_at = &"slip_road"
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


## Next new, GAME.md 8.9: how many landmarks drawn wear NEW over its corner, and pressed, the kart
## dashing to the next of them after the one the pane says, in the map's order, the House's sheet
## and then Kit's, or set down there turned to its sheet, rings to ping out from it, and the pane
## saying it at once, which takes the tag off, its sheet's tab's too, kept as the dialog goes; gone
## once none is new.
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
		_assert_dashing(dialog)
		var ping := dialog.map_view.get_node_or_null("Ping") as LandmarkPing
		assert_str(String(ping.id)).is_equal(String(fresh[i]))
		dialog.cursor.finish()
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


## Pressed while the kart drives, it dashes on from where the kart is, never waiting on the drive;
## from a landmark after the last new one it goes round to the first; and its bind, N or a pad's
## View, presses it, but not while the card in full is up over the map.
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
	_assert_dashing(dialog)
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


## Once the kart is at the landmark Next new took it to, rings ping out from its sign and fade, and
## then the ping is gone; one for a landmark the kart has been sent on from goes at once.
func test_rings_ping_out_once_the_kart_is_there() -> void:
	var profile := Game.settings.profile
	profile.loyalty.win(&"rare_cards")
	profile.loyalty.win(&"chip_trail")
	var dialog := await _open()
	dialog.next_new.button.pressed.emit()
	var ping := dialog.map_view.get_node("Ping") as LandmarkPing
	await get_tree().process_frame
	assert_float(ping.since).is_less(0.0)
	dialog.cursor.finish()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_float(ping.since).is_greater(0.0)
	# The sign comes up as a landing does, see [LandingCue].
	assert_float(dialog.map_view.sign_pop).is_greater(1.0)
	# Pressed again, the kart sent on: the ping for where it was goes, one for where it goes comes.
	dialog.next_new.button.pressed.emit()
	await get_tree().process_frame
	assert_bool(is_instance_valid(ping) and not ping.is_queued_for_deletion()).is_false()
	ping = dialog.map_view.get_node("Ping") as LandmarkPing
	assert_str(String(ping.id)).is_equal(String(dialog.cursor.at))
	dialog.cursor.finish()
	var ends := Time.get_ticks_msec() + 3000
	while is_instance_valid(ping) and Time.get_ticks_msec() < ends:
		await get_tree().process_frame
	assert_bool(is_instance_valid(ping)).is_false()
	assert_float(dialog.map_view.sign_pop).is_equal(1.0)


## The kart on its way in a dash, half a second at the most, or already there.
func _assert_dashing(dialog: LoyaltyDialog) -> void:
	var cursor := dialog.cursor
	if cursor.is_driving():
		var takes := (cursor._lengths[-1] - cursor._along) / cursor._speed
		assert_float(takes).is_less_equal(LoyaltyCursor.DASH + 0.001)
