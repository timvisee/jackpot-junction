class_name SegmentDigits
extends RefCounted
## Seven-segment numerals on a board, GAME.md 8.1 and 10.7: every bar of every digit is one
## instance of one [MultiMesh], placed, sized and colored per instance, with whether it is lit in
## its custom data, and drawn by led_segment.gdshader with the unlit bars showing faintly. One thing
## to draw however many digits a board has, and lighting a digit is a few small writes rather than
## materials changed. The match clock's board is built of them, see [LedClock], and so is the
## Garage's test bench, see [TestBench].

## Which segments each numeral lights, named the way a datasheet names them: a across the top,
## then round clockwise to f, and g across the middle. Anything else, a space say, lights nothing.
const NUMERALS: Dictionary[String, String] = {
	"0": "abcdef",
	"1": "bc",
	"2": "abged",
	"3": "abgcd",
	"4": "fgbc",
	"5": "afgcd",
	"6": "afgedc",
	"7": "abc",
	"8": "abcdefg",
	"9": "abcdfg",
}
const SHADER: Shader = preload("res://scenes/arena/led_segment.gdshader")
## How far in front of the face the bars stand.
const OUT := 0.04


## A [MultiMesh] of [param count] bars, all of them dark until placed and lit.
static func bars(count: int) -> MultiMesh:
	var made := MultiMesh.new()
	made.transform_format = MultiMesh.TRANSFORM_3D
	made.use_colors = true
	made.use_custom_data = true
	made.instance_count = count
	var bar := BoxMesh.new()
	bar.size = Vector3(1.0, 1.0, 0.05)
	made.mesh = bar
	return made


## The look the bars are drawn in, an unlit one showing in [param dark].
static func look(dark: Color) -> ShaderMaterial:
	var made := ShaderMaterial.new()
	made.shader = SHADER
	made.set_shader_parameter(&"dark", dark)
	return made


## One numeral [param size] across and high, its bars [param thick], laid out the way a segment
## display lays them out round [param at] on the face: seven instances of [param on] from
## [param first] on, each named for its segment.
static func digit(
	on: MultiMesh, first: int, at: Vector2, size: Vector2, thick: float, ink: Color
) -> Dictionary[String, int]:
	var half := size * 0.5
	var across := Vector2(size.x - thick, thick)
	var upright := Vector2(thick, half.y - thick)
	var places: Dictionary[String, Array] = {
		"a": [Vector2(0.0, half.y), across],
		"b": [Vector2(half.x, half.y * 0.5), upright],
		"c": [Vector2(half.x, -half.y * 0.5), upright],
		"d": [Vector2(0.0, -half.y), across],
		"e": [Vector2(-half.x, -half.y * 0.5), upright],
		"f": [Vector2(-half.x, half.y * 0.5), upright],
		"g": [Vector2(0.0, 0.0), across],
	}
	var segments: Dictionary[String, int] = {}
	var index := first
	for name: String in places:
		var place: Array = places[name]
		bar(on, index, at + (place[0] as Vector2), place[1] as Vector2, ink)
		segments[name] = index
		index += 1
	return segments


## One bar, instance [param index] of [param on], at [param at] on the face and [param size]
## across, dark until it is lit.
static func bar(on: MultiMesh, index: int, at: Vector2, size: Vector2, ink: Color) -> void:
	var flat := Basis.from_scale(Vector3(size.x, size.y, 1.0))
	on.set_instance_transform(index, Transform3D(flat, Vector3(at.x, at.y, OUT)))
	# Instance colors are stored linear, where a material's own albedo is written in sRGB.
	on.set_instance_color(index, ink.srgb_to_linear())
	on.set_instance_custom_data(index, Color(0.0, 0.0, 0.0))


## Lights [param digits] of [param on] to read [param text], a character a digit, in [param ink],
## and leaves the rest of their bars showing dark.
static func show(on: MultiMesh, digits: Array[Dictionary], text: String, ink: Color) -> void:
	var linear := ink.srgb_to_linear()
	for i: int in digits.size():
		var lit: String = NUMERALS.get(text.substr(i, 1), "") as String
		for name: String in digits[i]:
			var index: int = digits[i][name]
			on.set_instance_color(index, linear)
			on.set_instance_custom_data(index, Color(1.0 if lit.contains(name) else 0.0, 0, 0))
