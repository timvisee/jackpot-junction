extends GdUnitTestSuite
## Hints for a controller Steam Input reads, GAME.md 10.8: each action drawn on the button Steam has
## it on, as the game draws a pad's own, and Steam's own picture of what a pad has not got, a back
## button or a trackpad; drawn again as the layout changes in Steam or another pad is picked up.
## Against [FakeSteamInput]; nothing here talks to Steam.

## A controller's handle, and Steam's types for an Xbox One pad and a Steam Deck.
const HANDLE := 7
const XBOX := 3
const DECK := 14
## The pad the controller is.
const PAD := SteamPads.FIRST_DEVICE
## Steam's origins: an Xbox One pad's A, Y and right stick, and the Deck's upper back buttons and
## its right stick and trackpad, which Steam translates as the Xbox pad's grips and right stick.
const XBOX_A := 114
const XBOX_Y := 117
const XBOX_RIGHT_STICK := 132
const DECK_L4 := 373
const DECK_R4 := 375
const DECK_RIGHT_STICK := 366
const DECK_RIGHT_PAD := 349
const PICTURE := "res://assets/icons/touch_app.svg"

var _steam: FakeSteamInput
var _pads: SteamPads


func before_test() -> void:
	_steam = FakeSteamInput.new()
	var names: Array = []
	for action: StringName in SteamActions.BUTTONS:
		names.append(String(action))
	names.append_array(SteamActions.STICKS.keys())
	names.append_array(SteamActions.TRIGGERS.keys())
	_steam.know_actions(names)


func after_test() -> void:
	if is_instance_valid(_pads):
		_pads.free()
	InputActions.register_defaults()
	DeviceInput.recent.clear()
	PadFamily.reset()


## Steam Input started with a controller of Steam's [param type] plugged in.
func _start(type: int) -> void:
	_steam.plug(HANDLE, type)
	_pads = SteamPads.new(_steam)
	add_child(_pads)


## The hint for [param action] on the controller's pad.
func _glyph(action: StringName) -> InputGlyph:
	var glyph := InputGlyph.of_action(action, false, Color.WHITE, 15)
	glyph.pin(PAD)
	return auto_free(glyph)


func test_a_hint_draws_the_button_steam_has_the_action_on() -> void:
	_start(XBOX)
	_steam.origins["fire"] = [XBOX_Y]
	var glyph := _glyph(InputActions.FIRE)
	assert_int(glyph.kind).is_equal(InputGlyph.Kind.FACE)
	assert_int(glyph.face).is_equal(JOY_BUTTON_Y)
	# Of a button in front and one behind, the one in front.
	_steam.origins["use_item"] = [DECK_R4, XBOX_A]
	assert_int(_glyph(InputActions.USE_ITEM).face).is_equal(JOY_BUTTON_A)


func test_a_stick_moved_in_steam_is_drawn_moved() -> void:
	_start(XBOX)
	_steam.origins["steer_stick"] = [XBOX_RIGHT_STICK]
	var glyph := _glyph(InputActions.STEER_LEFT)
	assert_int(glyph.kind).is_equal(InputGlyph.Kind.STICK)
	assert_str(glyph.caption).is_equal("R")
	assert_vector(glyph.along).is_equal(Vector2.LEFT)


func test_a_back_button_is_steams_own_picture() -> void:
	_start(DECK)
	_steam.xbox_of = {DECK_R4: 146, DECK_L4: 144}
	_steam.origins["use_item"] = [DECK_R4]
	_steam.pictures[DECK_R4] = ProjectSettings.globalize_path(PICTURE)
	_steam.words[DECK_R4] = "R4"
	var glyph := _glyph(InputActions.USE_ITEM)
	assert_int(glyph.kind).is_equal(InputGlyph.Kind.PICTURE)
	assert_str(glyph.caption).is_equal("R4")
	assert_float(glyph.custom_minimum_size.x).is_greater(0.0)
	# Where Steam has no picture, its name for the button, on a pill.
	_steam.origins["joker_menu"] = [DECK_L4]
	_steam.words[DECK_L4] = "L4"
	var named := _glyph(InputActions.JOKER_MENU)
	assert_int(named.kind).is_equal(InputGlyph.Kind.SHOULDER)
	assert_str(named.caption).is_equal("L4")


## The Loyalty map's head has Steam's Y in a row with the stick pushed every way, which is taller:
## the row stretches the Y to that height, and the Y is drawn its own height in the middle of it,
## in the picture's own proportions.
func test_a_picture_in_a_taller_row_keeps_its_shape() -> void:
	_start(DECK)
	_steam.xbox_of = {DECK_R4: 146}
	_steam.origins["use_item"] = [DECK_R4]
	_steam.pictures[DECK_R4] = ProjectSettings.globalize_path(PICTURE)
	var glyph := InputGlyph.of_action(InputActions.USE_ITEM, false, Color.WHITE, 15)
	glyph.pin(PAD)
	assert_int(glyph.kind).is_equal(InputGlyph.Kind.PICTURE)
	var own := glyph.custom_minimum_size.y
	var taller := Control.new()
	taller.custom_minimum_size = Vector2(10.0, own * 1.6)
	var row: HBoxContainer = auto_free(InputHint.row("%s %s", [taller, glyph], Color.WHITE, 15))
	add_child(row)
	await get_tree().process_frame
	assert_float(glyph.size.y).is_greater(own * 1.5)
	var box := glyph.drawn_box()
	assert_float(box.size.y).is_equal_approx(own, 0.01)
	assert_float(box.get_center().y).is_equal_approx(glyph.size.y * 0.5, 1.0)
	# In a box of another shape, the picture drawn smaller rather than squashed.
	var picture := Vector2(load(PICTURE).get_size())
	for other: Vector2 in [Vector2(own * 3.0, own), Vector2(own, own * 3.0)]:
		var drawn := glyph.fitted(Rect2(Vector2.ZERO, other))
		assert_float(drawn.size.x / drawn.size.y).is_equal_approx(picture.x / picture.y, 0.01)
		assert_bool(Rect2(Vector2.ZERO, other).encloses(drawn)).is_true()


func test_a_trackpad_set_to_be_a_stick_is_not_drawn_as_the_stick() -> void:
	_start(DECK)
	_steam.xbox_of = {DECK_RIGHT_STICK: XBOX_RIGHT_STICK, DECK_RIGHT_PAD: XBOX_RIGHT_STICK}
	_steam.origins["aim_stick"] = [DECK_RIGHT_PAD]
	_steam.words[DECK_RIGHT_PAD] = "Right Trackpad"
	var glyph := _glyph(InputActions.AIM_LEFT)
	assert_str(glyph.caption).is_equal("Right Trackpad")
	# Steam tells of the layout loaded again: the stick it is now.
	_steam.origins["aim_stick"] = [DECK_RIGHT_STICK]
	_steam.input_configuration_loaded.emit(0, HANDLE, {})
	glyph._process(0.0)
	assert_int(glyph.kind).is_equal(InputGlyph.Kind.STICK)
	assert_str(glyph.caption).is_equal("R")


func test_a_layout_changed_in_steam_is_drawn_again() -> void:
	_start(XBOX)
	_steam.origins["fire"] = [XBOX_A]
	var glyph := _glyph(InputActions.FIRE)
	assert_int(glyph.face).is_equal(JOY_BUTTON_A)
	_steam.origins["fire"] = [XBOX_Y]
	_pads.look_again()
	glyph._process(0.0)
	assert_int(glyph.face).is_equal(JOY_BUTTON_Y)


func test_a_hint_for_everybody_follows_the_pad_picked_up() -> void:
	_start(XBOX)
	_steam.origins["fire"] = [XBOX_Y]
	var glyph := InputGlyph.of_action(InputActions.FIRE, false, Color.WHITE, 15)
	auto_free(glyph)
	# Before any pad is touched, the game's own A.
	assert_int(glyph.face).is_equal(JOY_BUTTON_A)
	DeviceInput.touched(PAD)
	glyph._process(0.0)
	assert_int(glyph.face).is_equal(JOY_BUTTON_Y)
	# Steam Input gone, the game's own again.
	_pads.free()
	glyph._process(0.0)
	assert_int(glyph.face).is_equal(JOY_BUTTON_A)


func test_the_controls_page_shows_steams_bindings_for_its_controller() -> void:
	_start(XBOX)
	_steam.origins["fire"] = [XBOX_Y]
	assert_int(SteamInputRow.pad()).is_equal(PAD)
	assert_str(SteamInputRow.head(SteamInputRow.PAD_HEAD)).is_equal(SteamInputRow.IN_STEAM)
	var row: HBoxContainer = auto_free(SettingsScreen._bound_glyphs(InputActions.FIRE, false))
	assert_int((row.get_child(0) as InputGlyph).face).is_equal(JOY_BUTTON_Y)
	assert_str(SteamInputRow.bound_text(InputActions.FIRE, false)).contains("Y")
	# One Steam has on nothing is not bound, whatever the game's own pad has.
	var none: HBoxContainer = auto_free(SettingsScreen._bound_glyphs(InputActions.NITRO, false))
	assert_str((none.get_child(0) as Label).text).is_equal(SettingsScreen.NOT_BOUND)
	# A binding asked to change opens Steam's settings for it.
	var status: Label = auto_free(Label.new())
	assert_bool(SteamInputRow.rebound_in_steam(status)).is_true()
	assert_array(_steam.calls).contains(["showBindingPanel %d" % HANDLE])
	assert_str(status.text).is_equal(SteamInputRow.OPENED)


func test_a_pad_of_the_engines_in_hand_shows_the_games_own_bindings() -> void:
	_start(XBOX)
	_steam.origins["fire"] = [XBOX_Y]
	DeviceInput.touched(0)
	assert_int(SteamInputRow.pad()).is_equal(-1)
	assert_str(SteamInputRow.head(SteamInputRow.PAD_HEAD)).is_equal(SteamInputRow.PAD_HEAD)
	var row: HBoxContainer = auto_free(SettingsScreen._bound_glyphs(InputActions.FIRE, false))
	assert_int((row.get_child(0) as InputGlyph).face).is_equal(JOY_BUTTON_A)
	assert_bool(SteamInputRow.rebound_in_steam(auto_free(Label.new()))).is_false()
