class_name LedClock
extends Node3D
## The match clock on a hoarding over the crowd, GAME.md 8.1: four seven-segment digits and a
## colon on a dark board, the way a scoreboard in a real hall keeps time. The HUD has the same
## clock in the corner, but a room with a clock in it is a room, and a player watching the table
## rather than the corner still knows how long is left.
##
## Scenery: it reads the match and decides nothing. A room with no clock to keep, such as the
## garage, has no board.

## The digits and the gap between them, in metres.
const DIGIT := Vector2(0.5, 0.96)
const SEGMENT := 0.11
const SPACING := 0.69
## The extra gap the colon is given, between the minutes and the seconds.
const COLON := 0.28
## Amber while the match runs and red during Last Call, GAME.md 8.3, with the unlit segments
## showing faintly so the display reads as a board with segments rather than as floating bars.
const LIT := Color(1.0, 0.72, 0.18)
const LIT_LAST_CALL := Color(1.0, 0.27, 0.27)
const DARK := Color(0.14, 0.12, 0.1)
## How far out past the far wall the board stands, and how far along that edge from the middle:
## off to one side, since the middle of that edge is the DJ booth's and the other side is where
## the tanks of 8.1 stand.
const STANDOFF := 3.2
const OFFSET := 0.3

## Which segments each numeral lights, named the way a datasheet names them: a across the top,
## then round clockwise to f, and g across the middle.
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

var match_node: Match

## One entry per digit: segment name to the mesh that draws it.
var _digits: Array[Dictionary] = []
var _board: Billboard
var _colon: Array[MeshInstance3D] = []
var _shown := ""


## Hangs a clock off [param for_match], to be kept by its own clock.
static func add_to(for_match: Match) -> LedClock:
	var clock := LedClock.new()
	clock.name = "LedClock"
	clock.match_node = for_match
	for_match.add_child(clock)
	return clock


## Whether this room has a clock worth putting on a wall.
func wanted() -> bool:
	return match_node != null and match_node.rules != null and match_node.rules.timed


func _process(_delta: float) -> void:
	visible = wanted()
	if not visible:
		return
	if _board == null:
		_build()
	_show(_clock_text(), _last_call())


## The time left as mm:ss, which is what the four digits have room for.
func _clock_text() -> String:
	var left := maxi(int(ceil(match_node.time_left)), 0)
	return "%02d%02d" % [mini(left / 60, 99), left % 60]


func _last_call() -> bool:
	return match_node.state == Match.State.LAST_CALL


## Lights the segments the numerals want and leaves the rest showing dark.
func _show(text: String, urgent: bool) -> void:
	var color := LIT_LAST_CALL if urgent else LIT
	if text == _shown and not urgent:
		return
	_shown = text
	for i: int in _digits.size():
		var on: String = NUMERALS.get(text.substr(i, 1), "") as String
		for name: String in _digits[i]:
			var segment: MeshInstance3D = _digits[i][name]
			var material := segment.material_override as StandardMaterial3D
			var lit := on.contains(name)
			material.albedo_color = color if lit else DARK
			material.emission = color
			material.emission_energy_multiplier = 1.6 if lit else 0.0
	for dot: MeshInstance3D in _colon:
		var material := dot.material_override as StandardMaterial3D
		material.albedo_color = color
		material.emission = color


## The board, its legs and the display on it. Built once the match is running, since where it
## stands comes from how big the table is.
func _build() -> void:
	var size := match_node.arena.world_size() if match_node.arena != null else Vector2(40.0, 22.5)
	var along := size.x * OFFSET * 0.5
	var at := Vector3(along, 0.0, -(size.y * 0.5 + STANDOFF))
	_board = Billboard.add_to(self, at, Vector3.ZERO)
	_board.name = "ClockBoard"
	var run := SPACING * 4.0 + COLON
	var left := -run * 0.5 + SPACING * 0.5
	for i: int in 4:
		var x := left + i * SPACING + (COLON if i >= 2 else 0.0)
		_digits.append(_digit(Vector2(x, -0.18)))
	for high: bool in [true, false]:
		var dot := _bar(Vector2(SEGMENT, SEGMENT))
		dot.position = Vector3(
			left + SPACING * 1.5 + COLON * 0.5, -0.18 + (0.24 if high else -0.24), 0.04
		)
		_board.face.add_child(dot)
		_colon.append(dot)
	_board.words("TIME", Vector2(0.0, 0.74), 0.34, Color(0.75, 0.78, 0.85))
	# Nobody stands in front of a board put up to be read.
	if match_node.arena != null and match_node.arena.crowd != null:
		var keep := Rect2(at.x - Billboard.WIDTH * 0.5, at.z - 1.6, Billboard.WIDTH, 3.2)
		match_node.arena.crowd.keep_clear(keep)


## One numeral: seven bars laid out the way a segment display lays them out.
func _digit(at: Vector2) -> Dictionary:
	var half := Vector2(DIGIT.x * 0.5, DIGIT.y * 0.5)
	var across := Vector2(DIGIT.x - SEGMENT, SEGMENT)
	var upright := Vector2(SEGMENT, DIGIT.y * 0.5 - SEGMENT)
	var places: Dictionary[String, Array] = {
		"a": [Vector2(0.0, half.y), across],
		"b": [Vector2(half.x, half.y * 0.5), upright],
		"c": [Vector2(half.x, -half.y * 0.5), upright],
		"d": [Vector2(0.0, -half.y), across],
		"e": [Vector2(-half.x, -half.y * 0.5), upright],
		"f": [Vector2(-half.x, half.y * 0.5), upright],
		"g": [Vector2(0.0, 0.0), across],
	}
	var segments: Dictionary[String, MeshInstance3D] = {}
	for name: String in places:
		var place: Array = places[name]
		var bar := _bar(place[1] as Vector2)
		bar.position = Vector3(at.x + (place[0] as Vector2).x, at.y + (place[0] as Vector2).y, 0.04)
		_board.face.add_child(bar)
		segments[name] = bar
	return segments


## One segment: a flat bar on the face, dark until it is lit.
func _bar(size: Vector2) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, size.y, 0.05)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = DARK
	material.emission_enabled = true
	material.emission = LIT
	material.emission_energy_multiplier = 0.0
	node.material_override = material
	return node
