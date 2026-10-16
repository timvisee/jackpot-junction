extends GdUnitTestSuite
## The achievements' dialog, GAME.md 8.10: a row each in the order the switch says, the hidden ones
## last, the count with its tick, the NEW tags, and Back.

const PATH := "user://test_achievements_dialog.cfg"

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
	# Gone before the scratch files are: a dialog going keeps the NEW tags it cleared.
	if is_instance_valid(_holder):
		remove_child(_holder)
		_holder.free()
	Settings.remove_files(PATH)
	Game.settings = _settings_were


func _open() -> AchievementsDialog:
	var dialog := AchievementsDialog.open(_holder)
	await get_tree().process_frame
	await get_tree().process_frame
	return dialog


func _ids(shown: Array[Achievement]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for each: Achievement in shown:
		ids.append(each.id)
	return ids


## In order is the list's own; the hidden ones not earned yet are last in it as in every order.
func test_in_order() -> void:
	var profile := Game.settings.profile
	var shown := _ids(AchievementsDialog.ordered(profile, AchievementsDialog.Order.IN_ORDER))
	assert_array(shown).is_equal(_ids(Achievements.all()))
	profile.achievements.earn(&"terms_accepted", 100)
	for order: AchievementsDialog.Order in [
		AchievementsDialog.Order.IN_ORDER,
		AchievementsDialog.Order.EARNED,
		AchievementsDialog.Order.TO_DO,
	]:
		var last := _ids(AchievementsDialog.ordered(profile, order)).slice(-4)
		assert_array(last).contains_exactly_in_any_order(
			[&"off_the_books", &"not_this_time", &"employee_of_the_month", &"a_fresh_start"]
		)


## Earned puts those earned first, the latest first; To do those not earned yet first, the nearest
## done at the top, and the earned ones after them.
func test_earned_and_to_do() -> void:
	var profile := Game.settings.profile
	profile.achievements.earn(&"bank_shot", 100)
	profile.achievements.earn(&"parry", 200)
	var earned := _ids(AchievementsDialog.ordered(profile, AchievementsDialog.Order.EARNED))
	assert_array(earned.slice(0, 2)).is_equal([&"parry", &"bank_shot"])
	for i: int in 30:
		profile.catalog.take_joker(Achievements.joker_ids()[i])
	var to_do := _ids(AchievementsDialog.ordered(profile, AchievementsDialog.Order.TO_DO))
	assert_str(String(to_do[0])).is_equal("full_deck")
	assert_int(to_do.find(&"parry")).is_greater(to_do.find(&"long_shot"))


## Every achievement has its row, under its group's heading in order; the count says how many are
## earned; a hidden one says only that it is.
func test_every_row_is_there() -> void:
	Game.settings.profile.achievements.earn(&"street_legal", 100)
	var dialog := await _open()
	var rows := dialog.rows()
	assert_int(rows.size()).is_equal(Achievements.all().size())
	assert_str(dialog.count.text).is_equal("1 / %d" % Achievements.all().size())
	assert_int(dialog.list.find_children("Heading", "Label", true, false).size()).is_equal(
		AchievementsDialog.HEADINGS.size()
	)
	assert_int(rows[0].look).is_equal(AchievementArt.Look.EARNED)
	assert_int(rows[-1].look).is_equal(AchievementArt.Look.HIDDEN)
	assert_bool(rows[0].has_focus()).is_true()


## A row earned since the list last showed it wears the NEW tag until the cursor has been on it,
## and gone, it stays gone.
func test_new_goes_once_looked_at() -> void:
	var profile := Game.settings.profile
	profile.achievements.earn(&"honor_roll", 100)
	var dialog := await _open()
	var row := dialog.list.find_child("honor_roll", true, false) as AchievementRow
	assert_bool(row.is_fresh()).is_true()
	row.grab_focus()
	assert_bool(row.is_fresh()).is_false()
	assert_bool(profile.achievements.is_fresh(&"honor_roll")).is_false()


## The switch steps the order round, remembered by the machine; Back puts the dialog away.
func test_sort_and_back() -> void:
	var dialog := await _open()
	assert_str(dialog.sort.text).is_equal(AchievementsDialog.SORT % "In order")
	dialog.step_order()
	assert_int(Game.settings.achievement_order).is_equal(AchievementsDialog.Order.EARNED)
	assert_str(dialog.sort.text).is_equal(AchievementsDialog.SORT % "Earned")
	assert_int(dialog.list.find_children("Heading", "Label", true, false).size()).is_equal(0)
	dialog.close()
	await get_tree().create_timer(1.0).timeout
	assert_bool(is_instance_valid(dialog)).is_false()


## Hide earned leaves out every row earned, and the headings of groups with nothing left, and is
## remembered by the machine; with everything earned the list says so, the cursor on Back.
func test_hide_earned() -> void:
	var profile := Game.settings.profile
	profile.achievements.earn(&"street_legal", 100)
	profile.achievements.earn(&"honor_roll", 100)
	var dialog := await _open()
	dialog.hide_earned.button_pressed = true
	await get_tree().process_frame
	assert_bool(Game.settings.achievements_hide_earned).is_true()
	assert_int(dialog.rows().size()).is_equal(Achievements.all().size() - 2)
	assert_object(dialog.list.find_child("street_legal", true, false)).is_null()
	assert_int(dialog.list.find_children("Heading", "Label", true, false).size()).is_equal(
		AchievementsDialog.HEADINGS.size() - 1
	)
	for each: Achievement in Achievements.all():
		profile.achievements.earn(each.id, 100)
	dialog.set_hide_earned(true)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_int(dialog.rows().size()).is_equal(0)
	assert_object(dialog.list.find_child("AllEarned", true, false)).is_not_null()
	assert_bool(dialog.back.has_focus()).is_true()


## Opened at an achievement, as a toast clicked opens it, the cursor is on its row, shown even with
## the earned ones left out; asked for another while up, the cursor goes to that one's, and the
## first is left out again.
func test_opened_at_an_achievement() -> void:
	var profile := Game.settings.profile
	profile.achievements.earn(&"untouchable", 100)
	Game.settings.achievements_hide_earned = true
	var dialog := AchievementsDialog.open(_holder, &"untouchable")
	for i: int in 3:
		await get_tree().process_frame
	var row := dialog.list.find_child("untouchable", true, false) as AchievementRow
	assert_object(row).is_not_null()
	assert_bool(row.has_focus()).is_true()
	dialog.show_achievement(&"parry")
	for i: int in 3:
		await get_tree().process_frame
	(
		assert_bool((dialog.list.find_child("parry", true, false) as AchievementRow).has_focus())
		. is_true()
	)
	assert_object(dialog.list.find_child("untouchable", true, false)).is_null()


## A toast clicked with the mouse puts a room's menu up, pausing the match as Escape does, and
## opens the achievements over it on the toast's; another clicked meanwhile moves the cursor in the
## same dialog; put away, the menu is still up. A finger's tap, which a phone hands on as a click
## too, does nothing.
func test_a_clicked_toast_shows_its_achievement_over_the_menu() -> void:
	var menu := PauseMenu.add_to(_holder)
	await get_tree().process_frame
	var toast := AchievementToast.of(Achievements.find(&"parry"))
	_holder.add_child(toast)
	await get_tree().process_frame
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	tap.device = InputEvent.DEVICE_ID_EMULATION
	toast._gui_input(tap)
	assert_bool(menu.is_open()).is_false()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	toast._gui_input(click)
	assert_bool(menu.is_open()).is_true()
	assert_bool(get_tree().paused).is_true()
	var dialog := menu._achievements as AchievementsDialog
	assert_object(dialog).is_not_null()
	for i: int in 3:
		await get_tree().process_frame
	(
		assert_bool((dialog.list.find_child("parry", true, false) as AchievementRow).has_focus())
		. is_true()
	)
	var other := AchievementToast.of(Achievements.find(&"untouchable"))
	_holder.add_child(other)
	await get_tree().process_frame
	other._gui_input(click)
	assert_object(menu._achievements).is_same(dialog)
	for i: int in 3:
		await get_tree().process_frame
	var row := dialog.list.find_child("untouchable", true, false) as AchievementRow
	assert_bool(row.has_focus()).is_true()
	dialog.close()
	for i: int in 30:
		await get_tree().process_frame
	assert_bool(menu.is_open()).is_true()
	menu.set_paused(false)
	get_tree().paused = false
