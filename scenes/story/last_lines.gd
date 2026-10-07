class_name LastLines
extends CanvasLayer
## The last lines, STORY.md 8.5: the slip put away for the House's dark stock with nothing on it
## and the music under, as at a death, and staying there. A board of the clock's kind drops in on
## its two bolts, HUMAN OVERSIGHT over one seven-segment digit, 0; a second later it clicks over
## to 1 with the stamp's thud; OPERATIONS: NORMAL under it; two seconds; it fades. Then the first
## line alone in the middle, in the condensed capitals and the House's foil, until a press; it
## fades; a breath; the second, until a press. Nothing says to press. A press counts once its line
## has stood a second, and only a press made since. Then the license in full over the stock, as
## after the driving test, and put away, the title.

## Over everything: the slip, the HUD, the pause menu.
const LAYER := 40
const BOARD := Vector2(360.0, 250.0)
const DROP := 0.55
const CLICK_AFTER := 1.0
const NORMAL_AFTER := 0.5
const HOLD := 2.0
const FADE := 0.45
const BREATH := 0.7
## How long a line stands before a press counts.
const STEADY := 1.0
const LIT := Color(1.0, 0.72, 0.25)
const UNLIT := Color(1.0, 0.72, 0.25, 0.08)

var board: Control
var line: Label
var digit := 0
## Which line is up, 0 or 1, and -1 between.
var showing := -1
## Whether it has gone on to the license.
var done := false

## How long the line up has stood, in the game's own time.
var _stood := 0.0
var _stock: ColorRect
var _holder: Control
var _normal: Label


## The last lines over [param parent], the match's scene.
static func begin(parent: Node) -> LastLines:
	var lines := LastLines.new()
	lines.name = "LastLines"
	parent.add_child(lines)
	return lines


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	Audio.hush_music(true)
	_holder = Control.new()
	_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_holder.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_holder)
	_stock = ColorRect.new()
	_stock.color = HouseTheme.STOCK
	_stock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_holder.add_child(_stock)
	board = Control.new()
	board.name = "Board"
	board.size = BOARD
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.draw.connect(_draw_board)
	_holder.add_child(board)
	_normal = _words(StoryLines.OPERATIONS, Type.STRONG, Type.LABEL, HouseTheme.QUIET)
	_normal.modulate.a = 0.0
	_holder.add_child(_normal)
	line = _words("", Type.display_font(), Type.TITLE, HouseTheme.FOIL)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.modulate.a = 0.0
	_holder.add_child(line)
	_holder.resized.connect(_place)
	_place()
	_play()


func _words(text: String, font: Font, font_size: int, ink: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(label, font, font_size)
	label.add_theme_color_override("font_color", ink)
	return label


func _place() -> void:
	var room := _holder.size
	board.position.x = (room.x - BOARD.x) * 0.5
	_normal.size = Vector2(room.x, 40.0)
	_normal.position = Vector2(0.0, room.y * 0.5 + BOARD.y * 0.5 + 16.0)
	line.size = Vector2(room.x * 0.8, room.y * 0.5)
	line.position = Vector2(room.x * 0.1, room.y * 0.25)


## The board's part, then the lines'.
func _play() -> void:
	var room := _holder.size
	board.position.y = -BOARD.y - 20.0
	var steps := create_tween()
	steps.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	steps.tween_property(board, "position:y", (room.y - BOARD.y) * 0.5, DROP)
	steps.tween_interval(CLICK_AFTER)
	steps.tween_callback(_click_over)
	steps.tween_interval(NORMAL_AFTER)
	steps.tween_property(_normal, "modulate:a", 1.0, 0.25)
	steps.tween_interval(HOLD)
	steps.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	steps.tween_property(board, "modulate:a", 0.0, FADE)
	steps.parallel().tween_property(_normal, "modulate:a", 0.0, FADE)
	steps.tween_callback(_show_line.bind(0))


## The digit goes from 0 to 1, with the stamp's thud.
func _click_over() -> void:
	digit = 1
	board.queue_redraw()
	Audio.play_sfx(&"stamp", -2.0, 0.0)


func _show_line(index: int) -> void:
	showing = index
	line.text = StoryLines.LAST_LINES[index]
	_stood = 0.0
	create_tween().tween_property(line, "modulate:a", 1.0, FADE)


func _process(delta: float) -> void:
	if showing >= 0:
		_stood += delta


## A press, any press, made since the line came up and once it has stood a second, takes it down.
func _input(event: InputEvent) -> void:
	if showing < 0 or done:
		return
	var pressed := (
		(event is InputEventKey and event.is_pressed() and not event.is_echo())
		or (event is InputEventMouseButton and event.is_pressed())
		or (event is InputEventJoypadButton and event.is_pressed())
		or (event is InputEventScreenTouch and event.is_pressed())
	)
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	if _stood < STEADY:
		return
	var was := showing
	showing = -1
	var away := create_tween()
	away.tween_property(line, "modulate:a", 0.0, FADE)
	if was == 0:
		away.tween_interval(BREATH)
		away.tween_callback(_show_line.bind(1))
	else:
		away.tween_callback(_the_license)


## The license in full over the stock, as after the driving test; put away, the title.
func _the_license() -> void:
	done = true
	var view := LicenseView.open(_holder, Game.last_input_keyboard)
	view.put_away.connect(_home)


func _home() -> void:
	Audio.hush_music(false)
	Game.go_to_title()


## The board: dark, hung on two bolts, HUMAN OVERSIGHT over one seven-segment digit.
func _draw_board() -> void:
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.05, 0.05, 0.06)
	back.set_corner_radius_all(10)
	back.set_border_width_all(4)
	back.border_color = Color(0.2, 0.2, 0.23)
	board.draw_style_box(back, Rect2(Vector2.ZERO, BOARD))
	for x: float in [BOARD.x * 0.18, BOARD.x * 0.82]:
		board.draw_circle(Vector2(x, 18.0), 7.0, Color(0.55, 0.57, 0.6))
		board.draw_circle(Vector2(x, 18.0), 3.0, Color(0.3, 0.31, 0.34))
	var font := Type.display_font()
	var caption := StoryLines.OVERSIGHT_BOARD
	var wide := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, Type.LABEL).x
	board.draw_string(
		font,
		Vector2((BOARD.x - wide) * 0.5, 58.0),
		caption,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		Type.LABEL,
		LIT
	)
	_draw_digit(Rect2(Vector2(BOARD.x * 0.5 - 48.0, 76.0), Vector2(96.0, 150.0)), digit)


## [param value] in seven segments in [param box], the segments it does not use faintly there.
func _draw_digit(box: Rect2, value: int) -> void:
	var lit_segments: Array = [
		[true, true, true, false, true, true, true],
		[false, false, true, false, false, true, false],
	]
	var on: Array = lit_segments[clampi(value, 0, 1)]
	var thick := box.size.x * 0.16
	var w := box.size.x
	var h := box.size.y * 0.5
	var spots: Array[Rect2] = [
		Rect2(box.position + Vector2(thick, 0.0), Vector2(w - thick * 2.0, thick)),
		Rect2(box.position + Vector2(0.0, thick), Vector2(thick, h - thick)),
		Rect2(box.position + Vector2(w - thick, thick), Vector2(thick, h - thick)),
		Rect2(box.position + Vector2(thick, h - thick * 0.5), Vector2(w - thick * 2.0, thick)),
		Rect2(box.position + Vector2(0.0, h + thick * 0.5), Vector2(thick, h - thick * 1.5)),
		Rect2(box.position + Vector2(w - thick, h + thick * 0.5), Vector2(thick, h - thick * 1.5)),
		Rect2(box.position + Vector2(thick, h * 2.0 - thick), Vector2(w - thick * 2.0, thick)),
	]
	for i: int in spots.size():
		board.draw_rect(spots[i], LIT if bool(on[i]) else UNLIT)
