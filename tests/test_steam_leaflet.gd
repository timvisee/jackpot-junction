extends GdUnitTestSuite
## The blueprint of a controller Steam Input reads, GAME.md 8.3b and 10.8: each action drawn on the
## button Steam has it on, what a pad has not got said down its side with Steam's picture of it,
## asked of Steam again as the game comes back in front, and what was drawn kept where Steam cannot
## say. Against [FakeSteamInput]; nothing here talks to Steam.

## A controller's handle, and Steam's types for an Xbox One pad and a Steam Deck; the pad it is.
const HANDLE := 7
const PAD := SteamPads.FIRST_DEVICE
const XBOX := 3
const DECK := 14
## Steam's origins: an Xbox One pad's A and Y, and a Deck's upper back buttons.
const XBOX_A := 114
const XBOX_Y := 117
const DECK_L4 := 373
const DECK_R4 := 375
const PICTURE := "res://assets/icons/touch_app.svg"

var _steam: FakeSteamInput
var _pads: SteamPads
var _holder: Control


func before_test() -> void:
	PadFamily.reset()
	_steam = FakeSteamInput.new()
	var names: Array = []
	for action: StringName in SteamActions.BUTTONS:
		names.append(String(action))
	names.append_array(SteamActions.STICKS.keys())
	names.append_array(SteamActions.TRIGGERS.keys())
	_steam.know_actions(names)
	_holder = Control.new()
	_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_holder)


func after_test() -> void:
	if is_instance_valid(_holder):
		remove_child(_holder)
		_holder.free()
	if is_instance_valid(_pads):
		_pads.free()
	DeviceInput.recent.clear()
	PadFamily.reset()


## Steam Input started with a controller of Steam's [param type] plugged in, and the blueprint up
## on its tab, or on none with [param drawn] -1.
func _open(type: int, drawn := PAD) -> PadLeaflet:
	_steam.plug(HANDLE, type)
	_pads = SteamPads.new(_steam)
	add_child(_pads)
	return PadLeaflet.open(_holder, PadFamily.Family.XBOX, false, null, false, drawn)


## The words at each button of the driving sheet, as the blueprint draws them.
func _words(leaflet: PadLeaflet) -> Dictionary:
	var said := PadSheets.labels(0, false, leaflet.diagram, leaflet._bound)
	var words: Dictionary = {}
	for spot: StringName in said:
		var each: Array[String] = said[spot]["words"]
		words[spot] = PadSheets.joined(each)
	return words


func test_each_action_is_drawn_where_steam_has_it() -> void:
	_steam.origins["fire"] = [XBOX_Y]
	var leaflet := _open(XBOX)
	# Only what Steam has bound: the game's own buttons say nothing of it.
	assert_dict(_words(leaflet)).is_equal({&"north": "Fire"})
	var tab := leaflet.get_node("Around/Pane/Sheet/Tab0") as Button
	assert_str(tab.accessibility_description).is_equal("Fire: Y")


## A back button, which no pad has, is said down its own side of the pad, by Steam's picture of it;
## one on two actions once.
func test_a_back_button_is_said_down_its_side() -> void:
	_steam.xbox_of = {DECK_R4: 146, DECK_L4: 144}
	_steam.origins["use_item"] = [DECK_R4]
	_steam.origins["nitro"] = [DECK_R4]
	_steam.origins["joker_menu"] = [DECK_L4]
	_steam.origins["fire"] = [XBOX_A]
	_steam.pictures[DECK_R4] = ProjectSettings.globalize_path(PICTURE)
	_steam.words[DECK_R4] = "R4"
	_steam.words[DECK_L4] = "L4"
	var leaflet := _open(DECK)
	assert_dict(_words(leaflet)).is_equal({&"south": "Fire"})
	var found := PadSheets.behind(0, false, leaflet._bound)
	assert_int(found.size()).is_equal(2)
	assert_str(found[0]["word"]).is_equal("R4")
	assert_array(found[0]["words"]).is_equal(["Nitro", "Use item"])
	assert_int(found[0]["side"]).is_equal(1)
	assert_object(found[0]["picture"]).is_not_null()
	# Where Steam has no picture, its name alone.
	assert_str(found[1]["word"]).is_equal("L4")
	assert_int(found[1]["side"]).is_equal(-1)
	assert_object(found[1]["picture"]).is_null()
	var tab := leaflet.get_node("Around/Pane/Sheet/Tab0") as Button
	assert_str(tab.accessibility_description).is_equal(
		"Fire: A. Nitro  ·  use item: R4. Joker hand: L4"
	)


## A layout changed in Steam's settings, which are in Steam or its overlay, is drawn as the game
## comes back in front, or as Steam loads it.
func test_steam_is_asked_again_as_the_game_comes_back() -> void:
	_steam.origins["fire"] = [XBOX_A]
	var leaflet := _open(XBOX)
	assert_dict(_words(leaflet)).is_equal({&"south": "Fire"})
	_steam.origins["fire"] = [XBOX_Y]
	assert_dict(_words(leaflet)).is_equal({&"south": "Fire"})
	_pads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_dict(_words(leaflet)).is_equal({&"north": "Fire"})
	_steam.origins["fire"] = [XBOX_A]
	_steam.overlay_toggled.emit(true, true, 0)
	assert_dict(_words(leaflet)).is_equal({&"north": "Fire"})
	_steam.overlay_toggled.emit(false, true, 0)
	assert_dict(_words(leaflet)).is_equal({&"south": "Fire"})
	_steam.origins["fire"] = [XBOX_Y]
	_steam.input_configuration_loaded.emit(0, HANDLE, {})
	assert_dict(_words(leaflet)).is_equal({&"north": "Fire"})


func test_what_steam_cannot_say_leaves_the_drawing_as_it_was() -> void:
	_steam.origins["fire"] = [XBOX_Y]
	var leaflet := _open(XBOX)
	# Steam saying nothing is bound at all.
	_steam.origins.clear()
	_pads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_dict(_words(leaflet)).is_equal({&"north": "Fire"})
	# Steam without the manifest.
	_steam.action_handles.clear()
	_steam.input_configuration_loaded.emit(0, HANDLE, {})
	assert_dict(_words(leaflet)).is_equal({&"north": "Fire"})
	# Steam Input gone.
	_pads.free()
	assert_dict(_words(leaflet)).is_equal({&"north": "Fire"})


## Steam's bindings are the controller's own: up for no pad, the game's; turned to the controller's
## tab, Steam's.
func test_steam_is_asked_as_the_blueprint_turns_to_its_controller() -> void:
	_steam.origins["fire"] = [XBOX_Y]
	var leaflet := _open(XBOX, -1)
	assert_dict(leaflet._bound).is_empty()
	assert_str(_words(leaflet)[&"south"]).contains("Fire")
	leaflet.show_pad(PAD)
	assert_dict(_words(leaflet)).is_equal({&"north": "Fire"})
