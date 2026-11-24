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


## Player color [param index] as Steam is told to light a pad in it, eight bits a channel.
func _lit(index: int) -> Color:
	var led := DeviceInput.led(Palette.player_color(index))
	return Color8(led.r8, led.g8, led.b8)


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
	assert_object(_steam.lights[HANDLE]).is_equal(_lit(2))
	assert_object(_steam.lights[OTHER]).is_equal(_lit(5))


## A color picked in the pause menu lights the pad at once, the game paused or not.
func test_a_new_color_lights_the_pad_while_paused() -> void:
	var slot := _seat(PAD, 2)
	_lights.light()
	assert_int(_lights.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)
	slot.color_index = 6
	_lights._process(PadLights.EVERY)
	assert_object(_steam.lights[HANDLE]).is_equal(_lit(6))


func test_a_seat_left_gives_the_pad_its_own_light_back() -> void:
	_seat(PAD, 2)
	_seat(PAD + 1, 5)
	_lights.light()
	_match.slots.pop_back()
	_lights.light()
	assert_object(_steam.lights[OTHER]).is_null()
	assert_object(_steam.lights[HANDLE]).is_equal(_lit(2))
	# The match over, every pad its own.
	_match.free()
	assert_object(_steam.lights[HANDLE]).is_null()


func test_a_player_on_every_device_lights_every_pad_left() -> void:
	_seat(PAD + 1, 5)
	_seat(DeviceInput.ANY, 1)
	_lights.light()
	assert_object(_steam.lights[HANDLE]).is_equal(_lit(1))
	assert_object(_steam.lights[OTHER]).is_equal(_lit(5))


func test_steam_input_turned_off_gives_every_light_back() -> void:
	_seat(PAD, 2)
	_lights.light()
	_pads.free()
	assert_object(_steam.lights[HANDLE]).is_null()


## A pad is lit in its color with no white in it, which made every light bar glow nearly white:
## each player color, in every palette, at full strength with its weakest channel off and near its
## own hue, and the karts' own eight far apart. A gray, as deuteranopia's white, stays as it is.
func test_the_light_has_no_white_in_it() -> void:
	var palettes: Array = [Palette.PLAYER_COLORS]
	palettes.append_array(Palette.VISION_COLORS.values())
	for colors: Array in palettes:
		for color: Color in colors:
			var led := DeviceInput.led(color)
			if color.s < DeviceInput.LED_GRAY:
				assert_object(led).is_equal(color)
				continue
			assert_float(maxf(led.r, maxf(led.g, led.b))).is_equal_approx(1.0, 0.001)
			assert_float(minf(led.r, minf(led.g, led.b))).is_equal_approx(0.0, 0.001)
			var off := absf(led.h - color.h)
			assert_float(minf(off, 1.0 - off)).is_less(0.05)
	var lit: Array[Vector3] = []
	for color: Color in Palette.PLAYER_COLORS:
		var led := DeviceInput.led(color)
		var here := Vector3(led.r, led.g, led.b)
		for other: Vector3 in lit:
			assert_float(here.distance_to(other)).is_greater(0.2)
		lit.append(here)
