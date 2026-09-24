extends GdUnitTestSuite
## Player colors for color blindness, GAME.md 8.5: a palette for each kind the settings offer, in
## the same slots, and the eight kept apart under the kind they are for.

## The three kinds at full strength, Machado, Oliveira and Fernandes 2009, in linear RGB.
const MACHADO: Dictionary = {
	"protanopia":
	[
		[0.152286, 1.052583, -0.204868],
		[0.114503, 0.786281, 0.099216],
		[-0.003882, -0.048116, 1.051998]
	],
	"deuteranopia":
	[
		[0.367322, 0.860646, -0.227968],
		[0.280085, 0.672501, 0.047413],
		[-0.011820, 0.042940, 0.968881]
	],
	"tritanopia":
	[
		[1.255528, -0.076749, -0.178779],
		[-0.078411, 0.930809, 0.147602],
		[0.004733, 0.691367, 0.303900]
	],
}

var _was := ""


func before_test() -> void:
	_was = Palette.vision


func after_test() -> void:
	Palette.vision = _was


func test_each_kind_has_a_palette_of_the_same_size() -> void:
	for vision: String in Settings.VISIONS:
		if vision.is_empty():
			continue
		assert_int(Palette.VISION_COLORS[vision].size()).is_equal(Palette.PLAYER_COLORS.size())


## Every color has a name in every palette, and no two in one palette share it: the name is what
## the button a player changes color with says, GAME.md 4.4.
func test_every_color_of_every_palette_has_a_name_of_its_own() -> void:
	var palettes: Dictionary[String, Array] = {"": Palette.COLOR_NAMES}
	palettes.merge(Palette.VISION_NAMES)
	for vision: String in Settings.VISIONS:
		var names: Array = palettes[vision]
		assert_int(names.size()).is_equal(Palette.PLAYER_COLORS.size())
		var seen: Dictionary[String, bool] = {}
		for each: String in names:
			seen[each] = true
		assert_int(seen.size()).is_equal(names.size())
	Palette.vision = "deuteranopia"
	assert_str(Palette.color_name(5)).is_equal("White")
	Palette.vision = ""
	assert_str(Palette.color_name(5)).is_equal("Orange")


func test_the_karts_wear_the_palette_the_setting_says() -> void:
	Palette.vision = ""
	assert_object(Palette.player_color(1)).is_equal(Palette.PLAYER_COLORS[1])
	Palette.vision = "deuteranopia"
	assert_object(Palette.player_color(1)).is_equal(Palette.VISION_COLORS["deuteranopia"][1])
	assert_object(Palette.player_color(9)).is_equal(Palette.VISION_COLORS["deuteranopia"][1])


func test_the_setting_is_kept_and_put_into_effect() -> void:
	var settings := Settings.new()
	settings.path = "user://test_color_vision.cfg"
	settings.color_vision = "tritanopia"
	assert_int(settings.save_to_disk()).is_equal(OK)
	var read := Settings.new()
	read.path = settings.path
	read.load_from_disk()
	assert_str(read.color_vision).is_equal("tritanopia")
	read.apply_input()
	read.apply(get_tree())
	assert_str(Palette.vision).is_equal("tritanopia")
	DirAccess.remove_absolute(settings.path)


## No two colors of a palette are close for the eyes it is for. Simulated as the palettes were
## chosen, Machado 2009 at full strength, and measured in CIELAB.
func test_no_two_colors_of_a_palette_look_alike_to_the_eyes_it_is_for() -> void:
	for vision: String in Palette.VISION_COLORS:
		var seen: Array[Vector3] = []
		for color: Color in Palette.VISION_COLORS[vision]:
			seen.append(_lab(_simulate(color, vision)))
		for i: int in seen.size():
			for j: int in range(i + 1, seen.size()):
				(
					assert_float(seen[i].distance_to(seen[j]))
					. override_failure_message("%s: %d and %d look alike" % [vision, i, j])
					. is_greater(25.0)
				)


static func _simulate(color: Color, vision: String) -> Color:
	var linear := color.srgb_to_linear()
	var m: Array = MACHADO[vision]
	var rgb := [linear.r, linear.g, linear.b]
	var out := []
	for row: Array in m:
		out.append(clampf(row[0] * rgb[0] + row[1] * rgb[1] + row[2] * rgb[2], 0.0, 1.0))
	return Color(out[0], out[1], out[2]).linear_to_srgb()


static func _lab(color: Color) -> Vector3:
	var linear := color.srgb_to_linear()
	var x := (0.4124 * linear.r + 0.3576 * linear.g + 0.1805 * linear.b) / 0.95047
	var y := 0.2126 * linear.r + 0.7152 * linear.g + 0.0722 * linear.b
	var z := (0.0193 * linear.r + 0.1192 * linear.g + 0.9505 * linear.b) / 1.08883
	return Vector3(116.0 * _f(y) - 16.0, 500.0 * (_f(x) - _f(y)), 200.0 * (_f(y) - _f(z)))


static func _f(t: float) -> float:
	return pow(t, 1.0 / 3.0) if t > 0.008856 else 7.787 * t + 16.0 / 116.0
