extends GdUnitTestSuite
## A landmark pinned in the loyalty program, GAME.md 8.9: one at a time, kept in the profile, only
## while it is still to be had; pinned from its pane by a button or accept, first in the list, and
## said in words under the pause menu's button and on the strip under a match's clock.

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


## Under the pause menu's button, what is pinned and how far it has come; nothing with nothing.
func test_said_under_the_pause_menus_button() -> void:
	var line: Label = auto_free(Label.new())
	PauseMenu._say_pinned(line)
	assert_bool(line.visible).is_false()
	Game.settings.profile.loyalty.pinned = &"dealers_visor"
	PauseMenu._say_pinned(line)
	assert_bool(line.visible).is_true()
	assert_str(line.text).contains("The Cashier's Cage")
	assert_str(line.text).contains("0 / 25")
