extends GdUnitTestSuite
## Each pad's light in its seat's color, GAME.md 10.8: a controller Steam Input reads lit through
## Steam in the color of the kart it drives, and given the player's own back as its seat empties
## and as the match ends. Against [FakeSteamInput]; nothing here talks to Steam.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
## Two controllers' handles, and the pads they are.
const HANDLE := 7
const OTHER := 9
const PAD := SteamPads.FIRST_DEVICE

var _steam: FakeSteamInput
var _pads: SteamPads
var _match: Match
var _lights: PadLights


func before_test() -> void:
	_steam = FakeSteamInput.new()
	_steam.know_actions([])
	_steam.plug(HANDLE)
	_steam.plug(OTHER)
	_pads = SteamPads.new(_steam)
	add_child(_pads)
	_match = MATCH_SCENE.instantiate()
	_lights = PadLights.add_to(_match)


func after_test() -> void:
	if is_instance_valid(_match):
		_match.free()
	if is_instance_valid(_pads):
		_pads.free()
	PadFamily.reset()


## A player at this machine on [param device], in player color [param color].
func _seat(device: int, color: int) -> PlayerSlot:
	var slot := PlayerSlot.new(_match.slots.size(), PlayerInput.new(device), color)
	_match.slots.append(slot)
	return slot


func test_each_pad_is_lit_in_its_seats_color() -> void:
	_seat(PAD, 2)
	_seat(PAD + 1, 5)
	# A bot lights nothing.
	_match.slots.append(PlayerSlot.new(2, KartInput.new(), 3))
	_lights.light()
	assert_object(_steam.lights[HANDLE]).is_equal(Palette.player_color(2))
	assert_object(_steam.lights[OTHER]).is_equal(Palette.player_color(5))


func test_a_seat_left_gives_the_pad_its_own_light_back() -> void:
	_seat(PAD, 2)
	_seat(PAD + 1, 5)
	_lights.light()
	_match.slots.pop_back()
	_lights.light()
	assert_object(_steam.lights[OTHER]).is_null()
	assert_object(_steam.lights[HANDLE]).is_equal(Palette.player_color(2))
	# The match over, every pad its own.
	_match.free()
	assert_object(_steam.lights[HANDLE]).is_null()


func test_a_player_on_every_device_lights_every_pad_left() -> void:
	_seat(PAD + 1, 5)
	_seat(DeviceInput.ANY, 1)
	_lights.light()
	assert_object(_steam.lights[HANDLE]).is_equal(Palette.player_color(1))
	assert_object(_steam.lights[OTHER]).is_equal(Palette.player_color(5))


func test_steam_input_turned_off_gives_every_light_back() -> void:
	_seat(PAD, 2)
	_lights.light()
	_pads.free()
	assert_object(_steam.lights[HANDLE]).is_null()
