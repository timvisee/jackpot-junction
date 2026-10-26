class_name LastLines
extends CanvasLayer
## The last lines, STORY.md 8.5: the slip put away for the House's dark stock with nothing on it
## and the music under, as at a death, and staying there. A board of the clock's kind drops in on
## its two bolts, HUMAN OVERSIGHT over one nixie tube glowing 0; a second later it clicks over
## to 1 with the stamp's thud; OPERATIONS: NORMAL under it; two seconds; it fades. Then the line
## alone in the middle, in the condensed capitals and the House's foil, until a press; it fades; a
## breath; and the House's approval record feeds up off its roll, the decisions approved in the
## player's name counting from the stamp, see [ApprovalRecord], until a press. Nothing says to
## press. A press counts once what is up has stood a second, and only a press made since. Then the
## license in full over the stock, as after the driving test, and put away, the title; or online,
## back to the slip, through, while the others finish theirs, 8.6, see [FinalHandRoll].

## Online, the license put away: this screen through, see [member back_to_the_room].
signal finished

## Over everything: the slip, the HUD, the pause menu.
const LAYER := 40
const BOARD := Vector2(400.0, 250.0)
## How many nixie tubes stand in the row: a counter that could read into the thousands for a tally
## that never passes one, the House's idea of oversight.
const TUBES := 5
const DROP := 0.55
const CLICK_AFTER := 1.0
const NORMAL_AFTER := 0.5
const HOLD := 2.0
const FADE := 0.45
const BREATH := 0.7
## The digit's click from 0 to 1: how long the segments take to settle, and how long the amber surge
## that lights them takes to die back down, both in seconds.
const CLICK_TIME := 0.3
const GLOW_TIME := 0.5
## How long a line stands before a press counts.
const STEADY := 1.0
const LIT := Color(1.0, 0.72, 0.25)
## The neon glow of a lit nixie cathode, a deeper orange than the foil, and the dim wire of an unlit
## one stacked behind it.
const NEON := Color(1.0, 0.58, 0.2)
const CATHODE := Color(0.4, 0.36, 0.32, 0.14)
## What the toasts of GAME.md 8.10 hold back for: the ending's lines have the screen to themselves.
const GROUP := &"last_lines"

var board: Control
var line: Label
var record: ApprovalRecord
var digit := 0
## What is up: the line, 0, the record, 1, and -1 between.
var showing := -1
## Whether it has gone on to the license.
var done := false
## Online: the license put away goes back to the slip, the room going back to its lobby once
## everybody in it is through, rather than to the title, STORY.md 8.6.
var back_to_the_room := false

## The click, 0 while the digit reads 0 and 1 once it has settled on 1, and the amber surge that
## lights it, 1 at the stamp and fading to 0, both read by the board's drawing.
var _flip := 0.0
var _glow := 0.0
## The tubes' own cut of the display font, made once: slimmer than the headings, nearer a nixie's
## fine cathode wire than a printed numeral.
var _digit_font: FontVariation
## How long the line up has stood, in the game's own time.
var _stood := 0.0
var _stock: ColorRect
var _holder: Control
var _normal: Label


## The last lines over [param parent], the match's scene, and [param online] back to the slip
## after them, see [member back_to_the_room].
static func begin(parent: Node, online := false) -> LastLines:
	var lines := LastLines.new()
	lines.name = "LastLines"
	lines.back_to_the_room = online
	parent.add_child(lines)
	return lines


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(GROUP)
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
	# So the warm pool of light behind the digit stays on the panel rather than spilling on the stock.
	board.clip_contents = true
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
	steps.tween_callback(_show_line)


## The units tube goes from 0 to 1, with the stamp's thud and, under it, a faint electric strike as
## the cathode lights: the 0's glow dies back as the 1 comes up, the glass guttering as it strikes
## before it settles.
func _click_over() -> void:
	digit = 1
	Audio.play_sfx(&"stamp", -2.0, 0.0)
	# The nixie's own voice, kept well under the thud: a short high crackle as the tube strikes.
	Audio.play_sfx(&"zap", -18.0, 0.1, 1.6)
	var click := create_tween()
	click.tween_method(_flip_to, 0.0, 1.0, CLICK_TIME).set_ease(Tween.EASE_OUT).set_trans(
		Tween.TRANS_CUBIC
	)
	# The glow strikes, gutters once, and settles — the tube's flicker as the gas catches.
	var surge := create_tween()
	surge.tween_method(_glow_to, 0.3, 1.0, 0.03)
	surge.tween_method(_glow_to, 1.0, 0.4, 0.05)
	surge.tween_method(_glow_to, 0.4, 0.9, 0.04)
	surge.tween_method(_glow_to, 0.9, 0.0, GLOW_TIME).set_ease(Tween.EASE_OUT).set_trans(
		Tween.TRANS_QUAD
	)


func _flip_to(amount: float) -> void:
	_flip = amount
	board.queue_redraw()


func _glow_to(amount: float) -> void:
	_glow = amount
	board.queue_redraw()


func _show_line() -> void:
	showing = 0
	line.text = StoryLines.LAST_LINE
	_stood = 0.0
	create_tween().tween_property(line, "modulate:a", 1.0, FADE)


## The House's approval record, fed up off its roll, counting from when the stamp came down here,
## or from now for a stamp that kept nothing.
func _show_record() -> void:
	showing = 1
	_stood = 0.0
	var story := Game.settings.profile.story
	var since := story.stamped_at if story.ended() and story.stamped_at > 0.0 else 0.0
	if since <= 0.0:
		since = Time.get_unix_time_from_system()
	record = ApprovalRecord.feed(_holder, Game.settings.profile, since)


func _process(delta: float) -> void:
	# The record stands from when its last line is up.
	if showing == 0 or (showing == 1 and record != null and record.is_fed()):
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
	if was == 0:
		away.tween_property(line, "modulate:a", 0.0, FADE)
		away.tween_interval(BREATH)
		away.tween_callback(_show_record)
	else:
		away.tween_property(record, "modulate:a", 0.0, FADE)
		away.tween_callback(_the_license)


## The license in full over the stock, as after the driving test, made the Operator's as it is
## looked at, see [OperatorStamping]; put away, the title.
func _the_license() -> void:
	done = true
	var view := LicenseView.open(_holder, Game.last_input_keyboard)
	OperatorStamping.on(view)
	view.put_away.connect(_home)


func _home() -> void:
	Audio.hush_music(false)
	if back_to_the_room:
		finished.emit()
		queue_free()
		return
	# The title the Operator comes home to opens as it did when the game started, STORY.md 8.6.
	TitleIntro.played = false
	Game.go_to_title()


## The board: dark, hung on two bolts, HUMAN OVERSIGHT over one nixie tube glowing from within, the
## panel warming and its caption catching the light as the stamp comes down, see [member _glow].
func _draw_board() -> void:
	var flash := _glow
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.05, 0.05, 0.06).lerp(Color(0.12, 0.1, 0.07), flash)
	back.set_corner_radius_all(10)
	back.set_border_width_all(4)
	back.border_color = Color(0.2, 0.2, 0.23).lerp(LIT, flash * 0.5)
	board.draw_style_box(back, Rect2(Vector2.ZERO, BOARD))
	# A faint sheen down the top, so the panel reads as glass over the digit rather than flat paint.
	board.draw_rect(Rect2(6.0, 6.0, BOARD.x - 12.0, 46.0), Color(1.0, 1.0, 1.0, 0.016))
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
		LIT.lerp(Color.WHITE, flash * 0.3)
	)
	_draw_tubes(_flip, flash)


## The row of [constant TUBES] nixie tubes across the board: all reading 0 but the units tube on the
## right, which clicks from 0 to 1 at [param flip] and takes the stamp's [param flash]; the leading
## tubes are steady zeros, catching only a little of the surge, a counter dressed for numbers the
## tally never reaches.
func _draw_tubes(flip: float, flash: float) -> void:
	var tube := Vector2(54.0, 140.0)
	var gap := 10.0
	var row := TUBES * tube.x + (TUBES - 1) * gap
	var left := (BOARD.x - row) * 0.5
	for i: int in TUBES:
		var box := Rect2(Vector2(left + float(i) * (tube.x + gap), 80.0), tube)
		if i == TUBES - 1:
			_draw_tube(box, "0", "1", flip, flash)
		else:
			_draw_tube(box, "0", "0", 0.0, flash * 0.3)


## One nixie tube in [param box]: a dark glass capsule over its warm backlight, the unlit numerals
## ghosted on their cathodes, the anode mesh across them, and the struck digit crossfading from
## [param from] to [param to] at [param flip], the stamp's [param flash] flaring its neon; and a
## sheen down the glass. A tube whose [param from] and [param to] are the same stands steady.
func _draw_tube(box: Rect2, from: String, to: String, flip: float, flash: float) -> void:
	var glass := StyleBoxFlat.new()
	glass.bg_color = Color(0.035, 0.03, 0.035)
	glass.set_corner_radius_all(roundi(box.size.x * 0.42))
	glass.set_border_width_all(2)
	glass.border_color = Color(0.16, 0.16, 0.19).lerp(NEON, flash * 0.5)
	board.draw_style_box(glass, box)
	_draw_backlight(box, flash)
	# The dim stack of unlit cathodes behind, an 8 standing for the numerals not struck.
	_numeral(box, "8", CATHODE, 1.0, 0.0)
	_draw_mesh(box)
	if from == to:
		_numeral(box, to, NEON, 1.0, flash)
	else:
		_numeral(box, from, NEON, 1.0 - flip, flash)
		_numeral(box, to, NEON, flip, flash)
	# A sheen down one side of the glass, so it reads as a tube rather than a hole.
	var sheen := Rect2(
		box.position + Vector2(box.size.x * 0.22, 8.0), Vector2(6.0, box.size.y - 16.0)
	)
	board.draw_rect(sheen, Color(1.0, 1.0, 1.0, 0.03))


## A warm pool of orange behind the numeral in [param box], soft rings fading outward, so the lit
## digit sits in a glow rather than on flat black; it swells with the stamp's [param flash].
func _draw_backlight(box: Rect2, flash: float) -> void:
	var middle := box.get_center()
	var base := 0.06 + flash * 0.13
	# Many faint rings from the middle out, so they read as one soft pool rather than banded circles.
	for ring: int in 12:
		var t := float(ring) / 11.0
		var reach := box.size.x * (0.4 + 0.13 * float(ring))
		board.draw_circle(middle, reach, Color(NEON.r, NEON.g, NEON.b, base * (1.0 - t) * 0.5))


## The anode mesh, faint vertical wires across the tube [param box], so the glass has a grille the
## digit glows through.
func _draw_mesh(box: Rect2) -> void:
	for i: int in range(1, 7):
		var x := box.position.x + box.size.x * float(i) / 7.0
		var top := box.position.y + 8.0
		board.draw_line(
			Vector2(x, top), Vector2(x, box.position.y + box.size.y - 8.0), CATHODE, 1.0
		)


## One numeral [param ch] in the tube [param box], centred, in [param tone] at brightness
## [param lit], a struck one haloed by a neon glow that the stamp's [param flash] fans wider; the
## tone's own alpha dims it, so an unlit cathode is drawn as a faint wire with no halo.
func _numeral(box: Rect2, ch: String, tone: Color, lit: float, flash: float) -> void:
	var bright := tone.a * lit
	if bright <= 0.01:
		return
	var font := _tube_font()
	var size := roundi(box.size.y * 0.62)
	var dims := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var at := box.get_center() + Vector2(-dims.x * 0.5, size * 0.35)
	if bright > 0.2:
		var halo := (0.35 * bright) + 0.5 * flash * lit
		for grow: int in [roundi(size * 0.14), roundi(size * 0.08)]:
			var fade := halo * (0.45 if grow == roundi(size * 0.14) else 0.75)
			board.draw_string_outline(
				font,
				at,
				ch,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				size,
				grow,
				Color(tone.r, tone.g, tone.b, fade)
			)
	board.draw_string(
		font, at, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(tone.r, tone.g, tone.b, bright)
	)


## The tubes' slimmer cut of the display font, made once: the semibold condensed with its weight
## eased back toward a nixie's fine cathode wire, see [member _digit_font].
func _tube_font() -> FontVariation:
	if _digit_font == null:
		_digit_font = FontVariation.new()
		_digit_font.base_font = Type.STRONG
		_digit_font.variation_embolden = -0.12
	return _digit_font
