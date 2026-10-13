class_name ClockBoard
extends Control
## The match clock, GAME.md 8.3 and 8.1a: amber seven-segment digits on a board hung from the top
## edge on two bolts, the same digits the clock on the hoarding of 8.1 is lit in, with every segment
## that is off still faintly there the way an unlit one is. Red through Last Call and overtime.
## What is not a time, OVERTIME, is set in the display cut on the same board.

## How big the board is: wide at the top where it hangs, narrower at the foot, and tall.
const TOP := 236.0
const FOOT := 196.0
const TALL := 64.0
## How tall the digits are, how far they lean, and how much of a lit segment glows round it.
const DIGIT := 40.0
const LEAN := 0.14
const GLOW := 2.2
## The board, its foil hairline and its bolts.
const BOARD := Color(0.055, 0.05, 0.07, 0.94)
const RIM := Color(HouseTheme.FOIL, 0.38)
const BOLT := Color(0.17, 0.165, 0.2)
const BOLT_SHINE := Color(0.36, 0.35, 0.4)
## The lit ink, and the red it turns while the clock is hot.
const AMBER := Color("#ffb23d")
const RED := Color("#ff4a3d")
## How faintly a segment that is off still shows.
const UNLIT := 0.08

## Which segments light for each digit, a to g the usual way round.
const SEGMENTS: Dictionary[String, String] = {
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

## What the board says, and whether it says it in red.
var text := "":
	set = _set_text
var hot := false:
	set = _set_hot


func _init() -> void:
	custom_minimum_size = Vector2(TOP, TALL)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Says how long [param match_node] has left: the time, red through Last Call, and OVERTIME once
## there is nothing left to count. Gone in a room with no clock, such as the Garage, which has
## nothing to count down to.
func show_time(match_node: Match) -> void:
	if not match_node.rules.timed:
		visible = false
		return
	var overtime := match_node.state == Match.State.OVERTIME
	if overtime:
		# There is nothing left to count: the clock has run out and the match is still on.
		text = "OVERTIME"
	else:
		var seconds := ceili(match_node.time_left)
		text = "%d:%02d" % [seconds / 60, seconds % 60]
	hot = overtime or match_node.state == Match.State.LAST_CALL


func _set_text(value: String) -> void:
	if value == text:
		return
	text = value
	queue_redraw()


func _set_hot(value: bool) -> void:
	if value == hot:
		return
	hot = value
	queue_redraw()


func _draw() -> void:
	var middle := size.x * 0.5
	var board := PackedVector2Array(
		[
			Vector2(middle - TOP * 0.5, 0.0),
			Vector2(middle + TOP * 0.5, 0.0),
			Vector2(middle + FOOT * 0.5, TALL),
			Vector2(middle - FOOT * 0.5, TALL),
		]
	)
	draw_colored_polygon(board, BOARD)
	var rim := PackedVector2Array(
		[
			Vector2(middle - TOP * 0.5 + 12.0, 0.0),
			Vector2(middle - FOOT * 0.5 + 8.0, TALL - 6.0),
			Vector2(middle + FOOT * 0.5 - 8.0, TALL - 6.0),
			Vector2(middle + TOP * 0.5 - 12.0, 0.0),
		]
	)
	draw_polyline(rim, RIM, 1.0, true)
	for side: float in [-1.0, 1.0]:
		var bolt := Vector2(middle + side * (FOOT * 0.5 - 18.0), TALL - 15.0)
		draw_circle(bolt, 3.0, BOLT, true, -1.0, true)
		draw_circle(bolt - Vector2(0.8, 0.8), 1.2, BOLT_SHINE, true, -1.0, true)
	var lit := RED if hot else AMBER
	if not _is_time(text):
		var font := Type.display_font()
		var font_size := 30
		var wide := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(
			font,
			Vector2(middle - wide * 0.5, TALL * 0.5 + font_size * 0.35 - 2.0),
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			lit
		)
		_glass()
		return
	var wide := digits_width(text)
	var at := Vector2(middle - wide * 0.5 + DIGIT * LEAN * 0.5, (TALL - DIGIT) * 0.5 - 2.0)
	_digits(at, _unlit(text), Color(lit, UNLIT), false)
	_digits(at, text, lit, true)
	_glass()


## The glass over the board, GAME.md 8.1a: a gloss down from its top edge, a line of light along
## that edge and a streak across it, as strong as [method Surface.finish] says.
func _glass() -> void:
	var strength := float(Surface.finish("clock")[2])
	if strength <= 0.0:
		return
	var middle := size.x * 0.5
	var low := TALL * 0.48
	var across_low := TOP + (FOOT - TOP) * low / TALL
	var gloss := PackedVector2Array(
		[
			Vector2(middle - TOP * 0.5, 0.0),
			Vector2(middle + TOP * 0.5, 0.0),
			Vector2(middle + across_low * 0.5, low),
			Vector2(middle - across_low * 0.5, low),
		]
	)
	var shine := Color(1.0, 1.0, 1.0, strength)
	var clear := Color(1.0, 1.0, 1.0, 0.0)
	draw_polygon(gloss, [shine, shine, clear, clear])
	# A sheet of glass catches a line of light along its top edge, and a streak across it.
	draw_line(
		Vector2(middle - TOP * 0.5 + 6.0, 1.5),
		Vector2(middle + TOP * 0.5 - 6.0, 1.5),
		Color(1.0, 1.0, 1.0, strength * 1.6),
		1.0,
		true
	)
	var streak := PackedVector2Array(
		[
			Vector2(middle + 30.0, 0.0),
			Vector2(middle + 62.0, 0.0),
			Vector2(middle + 30.0, TALL),
			Vector2(middle - 2.0, TALL),
		]
	)
	draw_colored_polygon(streak, Color(1.0, 1.0, 1.0, strength * 0.5))


## How wide [param shown] is drawn in the board's digits.
static func digits_width(shown: String) -> float:
	var wide := 0.0
	for each: String in shown:
		wide += _advance(each)
	return wide - DIGIT * 0.14


static func _advance(character: String) -> float:
	return DIGIT * 0.3 if character == ":" else DIGIT * 0.54 + DIGIT * 0.14


## [param shown] with every digit an eight, which is every segment there is.
static func _unlit(shown: String) -> String:
	var all := ""
	for each: String in shown:
		all += "8" if SEGMENTS.has(each) else each
	return all


static func _is_time(shown: String) -> bool:
	if shown.is_empty():
		return false
	for each: String in shown:
		if not SEGMENTS.has(each) and each != ":":
			return false
	return true


func _digits(at: Vector2, shown: String, ink: Color, glowing: bool) -> void:
	var lean := Transform2D(Vector2(1.0, 0.0), Vector2(-LEAN, 1.0), at)
	draw_set_transform_matrix(lean)
	var x := 0.0
	var w := DIGIT * 0.54
	var t := DIGIT * 0.13
	for each: String in shown:
		if each == ":":
			for y: float in [0.3, 0.7]:
				_segment_box(Rect2(x + DIGIT * 0.09, DIGIT * y - t * 0.5, t, t), ink, glowing)
			x += _advance(each)
			continue
		for segment: String in SEGMENTS.get(each, ""):
			_segment(x, w, t, segment, ink, glowing)
		x += _advance(each)
	draw_set_transform_matrix(Transform2D.IDENTITY)


## One segment of a digit whose left edge is [param x]: a long hexagon, its ends pointed so the
## segments meet at their corners the way a lit display's do.
func _segment(x: float, w: float, t: float, which: String, ink: Color, glowing: bool) -> void:
	var gap := t * 0.22
	var left := x + t * 0.5
	var right := x + w - t * 0.5
	var top := t * 0.5
	var mid := DIGIT * 0.5
	var foot := DIGIT - t * 0.5
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	match which:
		"a":
			from = Vector2(left, top)
			to = Vector2(right, top)
		"g":
			from = Vector2(left, mid)
			to = Vector2(right, mid)
		"d":
			from = Vector2(left, foot)
			to = Vector2(right, foot)
		"f":
			from = Vector2(left, top)
			to = Vector2(left, mid)
		"b":
			from = Vector2(right, top)
			to = Vector2(right, mid)
		"e":
			from = Vector2(left, mid)
			to = Vector2(left, foot)
		"c":
			from = Vector2(right, mid)
			to = Vector2(right, foot)
	var along := (to - from).normalized()
	from += along * gap
	to -= along * gap
	var across := along.orthogonal() * t * 0.5
	var hexagon := PackedVector2Array(
		[
			from,
			from + along * t * 0.5 + across,
			to - along * t * 0.5 + across,
			to,
			to - along * t * 0.5 - across,
			from + along * t * 0.5 - across,
		]
	)
	if glowing:
		draw_polyline(_closed(hexagon), Color(ink, 0.25), GLOW * 2.0, true)
	draw_colored_polygon(hexagon, ink)


func _segment_box(box: Rect2, ink: Color, glowing: bool) -> void:
	if glowing:
		draw_rect(box.grow(GLOW * 0.6), Color(ink, 0.25))
	draw_rect(box, ink)


static func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var closed := points.duplicate()
	closed.append(points[0])
	return closed
