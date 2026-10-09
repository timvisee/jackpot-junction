extends GdUnitTestSuite
## A landmark pinned in the loyalty program, GAME.md 8.9: one at a time, kept in the profile, only
## while it is still to be had; pinned from its pane by a button or accept, first in the list, and
## said on a note under the pause menu and on the strip by a match's clock.

const PATH := "user://test_loyalty_pin.cfg"

var _settings_were: Settings
var _holder: Control


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	var loyalty := Game.settings.profile.loyalty
	loyalty.welcomed = true
	loyalty.member = "1234 5678"
	loyalty.win(&"slip_road")
	_holder = Control.new()
	_holder.size = Vector2(1600.0, 900.0)
	add_child(_holder)


func after_test() -> void:
	LoyaltyDialog.stood_at = &""
	LoyaltyDialog.listed = false
	if is_instance_valid(_holder):
		remove_child(_holder)
		_holder.free()
	Settings.remove_files(PATH)
	Game.settings = _settings_were


## Only an open landmark, or the open roundabout, may be pinned; pinned, it is said in words, its
## progress counted; kept in the profile; and once its bet is won it is pinned no more.
func test_what_may_be_pinned() -> void:
	var profile := Game.settings.profile
	assert_bool(Loyalty.can_pin(profile, &"dealers_visor")).is_true()
	assert_bool(Loyalty.can_pin(profile, &"slip_road")).is_false()
	assert_bool(Loyalty.can_pin(profile, &"card_suits")).is_false()
	assert_bool(Loyalty.can_pin(profile, Loyalty.ROUNDABOUT)).is_false()
	profile.loyalty.pinned = &"dealers_visor"
	profile.stats[&"banks"] = 12.0
	var said := Loyalty.pinned_words(profile)
	assert_str(said[0]).is_equal("The Cashier's Cage")
	assert_str(said[1]).is_equal("12 / 25")
	var file := ConfigFile.new()
	profile.loyalty.write(file)
	var read := LoyaltyState.new()
	read.read(file)
	assert_str(String(read.pinned)).is_equal("dealers_visor")
	profile.stats[&"banks"] = 25.0
	Loyalty.settle(profile)
	assert_str(String(profile.loyalty.pinned)).is_empty()
	assert_array(Loyalty.pinned_words(profile)).is_empty()


## From the pane: its Pin button for an open landmark, pressed or accept pins it and again unpins;
## pinned, it comes first in the list.
func test_pinned_from_the_pane() -> void:
	var dialog := LoyaltyDialog.open(_holder)
	await get_tree().process_frame
	await get_tree().process_frame
	dialog.map_view.drive_to(&"dealers_visor")
	dialog.cursor.finish()
	assert_bool(dialog.pane.pin.visible).is_true()
	dialog.pane.pin.pressed.emit()
	assert_str(String(Game.settings.profile.loyalty.pinned)).is_equal("dealers_visor")
	assert_bool(dialog.pane.pin.button_pressed).is_true()
	var accept := InputEventAction.new()
	accept.action = LoyaltyPane.PIN_ACTION
	accept.pressed = true
	dialog._input(accept)
	assert_str(String(Game.settings.profile.loyalty.pinned)).is_empty()
	dialog.map_view.drive_to(&"racing_stripes")
	dialog.cursor.finish()
	dialog.toggle_pin()
	dialog.set_listed(true)
	var first := dialog.list.rows()[0]
	assert_str(String(first.id)).is_equal("racing_stripes")
	assert_bool(first.pinned).is_true()
	# The slip road is won: nothing to pin.
	dialog.set_listed(false)
	dialog.map_view.drive_to(&"slip_road")
	dialog.cursor.finish()
	assert_bool(dialog.pane.pin.visible).is_false()


## The strip hangs beside the clock on a screen wide enough, past Kit's scrap and short of the feed
## in the corner, and under it otherwise, lower again for the flush's tally.
func test_the_strip_hangs_beside_the_clock_where_there_is_room() -> void:
	var beside := PinnedStrip.placed(1920.0, PinnedStrip.UNDER_TALLY)
	var scrap_end := ClockBoard.TOP * 0.5 + NoteMark.GAP + NoteMark.SIZE.x
	assert_float(beside.position.x).is_greater(scrap_end)
	assert_float(beside.end.y).is_less_equal(ClockBoard.TALL)
	assert_float(960.0 + beside.end.x).is_less_equal(1920.0 - 420.0)
	var under := PinnedStrip.placed(1600.0, 0.0)
	assert_float(under.get_center().x).is_equal(0.0)
	assert_float(under.position.y).is_greater(ClockBoard.TALL)
	var lower := PinnedStrip.placed(1600.0, PinnedStrip.UNDER_TALLY)
	assert_float(lower.position.y).is_equal(under.position.y + PinnedStrip.UNDER_TALLY)


## Under the pause menu's pane, on a note of its own, what is pinned, its bet and how far it has
## come, going where the pane goes; beside it where the screen has no room under it, and nothing
## with nothing pinned.
func test_said_on_a_note_under_the_pause_menu() -> void:
	var pane: Control = Control.new()
	pane.position = Vector2(600.0, 200.0)
	pane.size = Vector2(400.0, 400.0)
	_holder.add_child(pane)
	var note := PinnedNote.new(pane)
	_holder.add_child(note)
	assert_bool(note.visible).is_false()
	Game.settings.profile.loyalty.pinned = &"dealers_visor"
	note.look()
	assert_bool(note.visible).is_true()
	assert_str(note.words[0]).is_equal("The Cashier's Cage")
	assert_str(note.words[1]).contains("0 / 25")
	assert_str(note.bet).is_not_empty()
	var under := pane.get_global_rect()
	assert_float(note.global_position.y).is_greater(under.end.y)
	assert_float(note.global_position.x + PinnedNote.SIZE.x * 0.5).is_equal_approx(
		under.get_center().x, 1.0
	)
	# No room under it: beside it.
	pane.position.y = note.get_viewport_rect().size.y - pane.size.y - 20.0
	note.look()
	assert_float(note.global_position.x).is_greater(pane.get_global_rect().end.x)
	pane.hide()
	note.look()
	assert_bool(note.visible).is_false()


## A click on the pause menu's note opens the program on the map at what is pinned, whether the
## list was up when it was last put away or the cursor stood somewhere else.
func test_the_note_opens_the_program_at_its_pin() -> void:
	Game.settings.profile.loyalty.pinned = &"dealers_visor"
	LoyaltyDialog.stood_at = &"slip_road"
	LoyaltyDialog.listed = true
	var menu := PauseMenu.add_to(_holder)
	await get_tree().process_frame
	var note := menu.find_child("PinnedNote", true, false) as PinnedNote
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	note._gui_input(click)
	var dialog := menu._loyalty
	assert_object(dialog).is_not_null()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_str(String(dialog.cursor.at)).is_equal("dealers_visor")
	assert_str(dialog.pane.shown).is_equal("dealers_visor")
	assert_bool(LoyaltyDialog.listed).is_false()
	assert_bool(dialog.map_view.visible).is_true()
	# Again while it is up: nothing more.
	note._gui_input(click)
	assert_object(menu._loyalty).is_same(dialog)
	dialog.close()
