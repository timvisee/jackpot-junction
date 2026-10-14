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
## The tag hung under the board, see [member under]: how far under its foot, and how tall.
const TAG_DROP := 6.0
const TAG_TALL := 30.0
## The group a clock waiting on its pictures is in, see [KeptPictures].
const KEPT := &"clock_board_kept"

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
## A tag hung under the board on a cord, saying what kind of time this is, or empty for none: a
## showdown's, GAME.md 9.7a.
var under := "":
	set = _set_under


func _init() -> void:
	custom_minimum_size = Vector2(TOP, TALL)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group(KEPT)


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


func _set_under(value: String) -> void:
	if value == under:
		return
	under = value
	queue_redraw()


func _draw() -> void:
	var middle := size.x * 0.5
	var lit := RED if hot else AMBER
	if _is_time(text) and under.is_empty() and _draw_kept(middle, lit):
		_glass()
		return
	_draw_board(self, middle)
	if not under.is_empty():
		_tag(middle, lit)
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
	var at := _digits_at(middle, text)
	_digits(self, at, _unlit(text), Color(lit, UNLIT), false)
	_digits(self, at, text, lit, true)
	_glass()


## The time from pictures, GAME.md 10.7: the board with its unlit segments, kept for how the time
## is laid out and in which ink, and over it each lit digit, kept for what it is and its ink. Drawn
## as themselves, segment by segment, they are about a hundred draw calls a frame. False while the
## pictures are still being drawn, for the time to be drawn as itself meanwhile.
func _draw_kept(middle: float, lit: Color) -> bool:
	var scale := KeptPictures.scale_of(self)
	var plate := Vector2(TOP, TALL)
	var unlit := _unlit(text)
	var board_pixels := Vector2i((plate * scale).ceil())
	var board_key := "clock_board|%s|%s" % [unlit, hot]
	var make := _board_picture.bind(board_pixels, unlit, lit)
	var board := KeptPictures.of(self, board_key, board_pixels, make, KEPT)
	if board == null:
		return false
	var at := _digits_at(middle, text)
	var room := Vector2(GLOW * 2.0 + 1.0 + DIGIT * LEAN, GLOW * 2.0 + 1.0)
	var pictures: Array[Texture2D] = []
	for each: String in text:
		var cell := Vector2(_advance(each), DIGIT) + room * 2.0
		var pixels := Vector2i((cell * scale).ceil())
		var key := "clock_digit|%s|%s" % [each, hot]
		var made := _digit_picture.bind(pixels, cell, room, each, lit)
		var picture := KeptPictures.of(self, key, pixels, made, KEPT)
		if picture == null:
			return false
		pictures.append(picture)
	draw_texture_rect(board, Rect2(Vector2(middle - TOP * 0.5, 0.0), plate), false)
	var x := 0.0
	for i: int in text.length():
		var cell := Vector2(_advance(text[i]), DIGIT) + room * 2.0
		draw_texture_rect(pictures[i], Rect2(at + Vector2(x, 0.0) - room, cell), false)
		x += _advance(text[i])
	return true


## The board and [param unlit], its segments all faintly there, at [param pixels], for its picture.
func _board_picture(pixels: Vector2i, unlit: String, lit: Color) -> Control:
	var drawn := Control.new()
	drawn.size = Vector2(pixels)
	var scaled := Transform2D.IDENTITY.scaled(Vector2.ONE * float(pixels.x) / TOP)
	drawn.draw.connect(
		func() -> void:
			drawn.draw_set_transform_matrix(scaled)
			_draw_board(drawn, TOP * 0.5)
			var at := _digits_at(TOP * 0.5, unlit)
			_digits(drawn, at, unlit, Color(lit, UNLIT), false, scaled)
	)
	return drawn


## The lit [param each] in a cell [param cell] across, [param room] round it for its lean and its
## glow, at [param pixels], for its picture.
static func _digit_picture(
	pixels: Vector2i, cell: Vector2, room: Vector2, each: String, lit: Color
) -> Control:
	var drawn := Control.new()
	drawn.size = Vector2(pixels)
	var scaled := Transform2D.IDENTITY.scaled(Vector2.ONE * float(pixels.x) / cell.x)
	drawn.draw.connect(func() -> void: _digits(drawn, room, each, lit, true, scaled))
	return drawn


## Where the digits of [param shown] start, the board's middle at [param middle].
static func _digits_at(middle: float, shown: String) -> Vector2:
	var wide := digits_width(shown)
	return Vector2(middle - wide * 0.5 + DIGIT * LEAN * 0.5, (TALL - DIGIT) * 0.5 - 2.0)


## The board on [param on], its middle at [param middle]: its black, its hairline and its bolts.
static func _draw_board(on: CanvasItem, middle: float) -> void:
	var board := PackedVector2Array(
		[
			Vector2(middle - TOP * 0.5, 0.0),
			Vector2(middle + TOP * 0.5, 0.0),
			Vector2(middle + FOOT * 0.5, TALL),
			Vector2(middle - FOOT * 0.5, TALL),
		]
	)
	on.draw_colored_polygon(board, BOARD)
	var rim := PackedVector2Array(
		[
			Vector2(middle - TOP * 0.5 + 12.0, 0.0),
			Vector2(middle - FOOT * 0.5 + 8.0, TALL - 6.0),
			Vector2(middle + FOOT * 0.5 - 8.0, TALL - 6.0),
			Vector2(middle + TOP * 0.5 - 12.0, 0.0),
		]
	)
	on.draw_polyline(rim, RIM, 1.0, true)
	for side: float in [-1.0, 1.0]:
		var bolt := Vector2(middle + side * (FOOT * 0.5 - 18.0), TALL - 15.0)
		on.draw_circle(bolt, 3.0, BOLT, true, -1.0, true)
		on.draw_circle(bolt - Vector2(0.8, 0.8), 1.2, BOLT_SHINE, true, -1.0, true)


## The tag under the board: a strip of the board's black on two cords from its foot, its words in
## the board's own ink, smaller.
func _tag(middle: float, lit: Color) -> void:
	var font := Type.display_font()
	var font_size := 17
	var wide := font.get_string_size(under, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var box := Rect2(middle - wide * 0.5 - 14.0, TALL + TAG_DROP, wide + 28.0, TAG_TALL)
	for side: float in [-1.0, 1.0]:
		var x := middle + side * (box.size.x * 0.5 - 10.0)
		draw_line(Vector2(x, TALL - 4.0), Vector2(x, box.position.y), BOLT_SHINE, 1.5, true)
	draw_rect(box, BOARD)
	draw_rect(box.grow(-3.0), RIM, false, 1.0)
	var baseline := box.position.y + TAG_TALL * 0.5 + font_size * 0.35
	draw_string(
		font,
		Vector2(middle - wide * 0.5, baseline),
		under,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		lit
	)


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


## [param shown] at [param at] on [param on], leaning, under [param base], the scale a picture of
## it is drawn at.
static func _digits(
	on: CanvasItem,
	at: Vector2,
	shown: String,
	ink: Color,
	glowing: bool,
	base := Transform2D.IDENTITY
) -> void:
	var lean := Transform2D(Vector2(1.0, 0.0), Vector2(-LEAN, 1.0), at)
	on.draw_set_transform_matrix(base * lean)
	var x := 0.0
	var w := DIGIT * 0.54
	var t := DIGIT * 0.13
	for each: String in shown:
		if each == ":":
			for y: float in [0.3, 0.7]:
				_segment_box(on, Rect2(x + DIGIT * 0.09, DIGIT * y - t * 0.5, t, t), ink, glowing)
			x += _advance(each)
			continue
		for segment: String in SEGMENTS.get(each, ""):
			_segment(on, x, w, t, segment, ink, glowing)
		x += _advance(each)
	on.draw_set_transform_matrix(Transform2D.IDENTITY)


## One segment of a digit whose left edge is [param x]: a long hexagon, its ends pointed so the
## segments meet at their corners the way a lit display's do.
static func _segment(
	on: CanvasItem, x: float, w: float, t: float, which: String, ink: Color, glowing: bool
) -> void:
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
		on.draw_polyline(_closed(hexagon), Color(ink, 0.25), GLOW * 2.0, true)
	on.draw_colored_polygon(hexagon, ink)


static func _segment_box(on: CanvasItem, box: Rect2, ink: Color, glowing: bool) -> void:
	if glowing:
		on.draw_rect(box.grow(GLOW * 0.6), Color(ink, 0.25))
	on.draw_rect(box, ink)


static func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var closed := points.duplicate()
	closed.append(points[0])
	return closed
