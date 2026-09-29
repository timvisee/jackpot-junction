class_name InputGlyph
extends Control
## One binding drawn rather than written, GAME.md 8.3: a key as a key cap with the key on it, a
## gamepad face button as a round button in its own color, a shoulder or a trigger as a pill,
## a stick as a stick, the D-pad as a D-pad and a mouse button as a mouse with that button lit.
##
## "Shift drift   Ctrl nitro" is a sentence to be read. The same line with the two keys drawn as
## keys is a picture to be recognized, which is what a hint glanced at mid-corner has to be. The
## shapes are drawn rather than loaded, because the bindings belong to the player: any key on the
## keyboard can end up in one of these, and no set of pictures can cover that in advance.

enum Kind { KEY, FACE, SHOULDER, STICK, DPAD, MOUSE }

## How tall a glyph is by default and how much air sits either side of the caption inside one.
const HEIGHT := 22.0
const SIDE_PAD := 6.0
## The caption is a size down from the line it sits in, since it is inside a box with edges, and
## never smaller than this or the cap says nothing.
const CAPTION_DROP := 3
const MIN_CAPTION := 11
## The face buttons in the colors everybody's pad has on them, so A reads as A before it is read.
const FACE_COLORS: Dictionary[String, Color] = {
	"A": Color("#5FBF5F"),
	"B": Color("#D9534F"),
	"X": Color("#4A7FD4"),
	"Y": Color("#E8C33D"),
}
## The chip every glyph is drawn on. Solid and dark, with a soft black edge around it and a
## rim in the color of the line it sits in: dark against the felt, the crowd and a light wall,
## rimmed against the night sky of a menu. It started out as a 16% wash of the text color, which
## is a chip you have to find before you can read it, and a hint you have to find has already
## cost the corner you were reading it in.
const CHIP := Color(0.05, 0.05, 0.07, 0.92)
const CHIP_EDGE := Color(0.0, 0.0, 0.0, 0.55)
const CHIP_SHADOW := 3
const EDGE_ALPHA := 0.92
const EDGE_WIDTH := 1.6
## How dark the letter on a gamepad's own colored button is, which is how it is on the pad.
const FACE_INK := Color(0.06, 0.06, 0.08)
## How much wider than tall a stick is drawn. The letter goes inside the ring, so the ring has to
## hold a letter, and the arrows still have to fit outside it: in a square chip the two fight and
## the arrows lose, coming out as nicks in the border.
const STICK_WIDE := 1.55
## How wide a mouse is for how tall it is, and how much room the mark of a double click takes
## beside it.
const MOUSE_WIDE := 0.66
const DOUBLE_MARK := "\u00d72"
## The three buttons a mouse is drawn for; any other is written on a key cap.
const MOUSE_BUTTONS: Array[MouseButton] = [
	MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE
]
## What a touch screen's own buttons are called on them, GAME.md 4.2, for the hint that names one:
## a pill with the word on it, the way the screen has it. Steering is the stick under the left
## thumb, drawn as a stick with nothing written in it.
const TOUCH_WORDS: Dictionary[StringName, String] = {
	InputActions.THROTTLE: "GAS",
	InputActions.BRAKE: "BRAKE",
	InputActions.NITRO: "NITRO",
	InputActions.HANDBRAKE: "DRIFT",
	InputActions.FIRE: "FIRE",
	InputActions.USE_ITEM: "ITEM",
}

var kind := Kind.KEY
## What is written on the glyph: the key, the button, or the stick's side.
var caption := ""
## The color of the line the glyph sits in, which everything but a face button is drawn in.
var ink := Color.WHITE
var font_size := 15
## Which way a stick is moved or a D-pad is pressed, as a unit vector on the screen.
var along := Vector2.RIGHT
## Whether this is a stick that moves both ways along its axis. One binding is half a stick and
## is drawn pushed that way; a pair of them, GAME.md 8.3, is the whole stick and is drawn centered.
var both_ways := false
## Whether this is a stick pushed every way at once, a head on each of its four sides: the way to
## go in simple driving, GAME.md 4.2, rather than one axis of it. Square, being as tall as wide.
## For a mouse: which of its buttons is pressed, and whether twice.
var mouse_button := MOUSE_BUTTON_LEFT
var double_click := false
var every_way := false:
	set(value):
		every_way = value
		custom_minimum_size = _wanted()
		queue_redraw()


## The first binding of [param action] for one device kind, as a glyph. Null when nothing is
## bound to it there, which is what a hint should leave out rather than write a dash for.
static func of_action(action: StringName, keyboard: bool, ink: Color, font_size: int) -> InputGlyph:
	var event := InputActions.first_event(action, keyboard)
	return null if event == null else of_event(event, ink, font_size)


## [param action] as the touch screen has it: a pill with the word on its button, or the stick for
## steering, both ways at once. Null for an action the screen has no button for.
static func of_touch(action: StringName, ink: Color, font_size: int) -> InputGlyph:
	var steering := action in [InputActions.STEER_LEFT, InputActions.STEER_RIGHT]
	if not steering and not TOUCH_WORDS.has(action):
		return null
	var glyph := InputGlyph.new()
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.ink = ink
	glyph.font_size = font_size
	glyph.kind = Kind.STICK if steering else Kind.SHOULDER
	glyph.caption = "" if steering else TOUCH_WORDS[action]
	glyph.both_ways = steering
	glyph.along = Vector2.RIGHT
	glyph.custom_minimum_size = glyph._wanted()
	return glyph


static func of_event(event: InputEvent, ink: Color, font_size: int) -> InputGlyph:
	var glyph := InputGlyph.new()
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.ink = ink
	glyph.font_size = font_size
	glyph.kind = _kind_of(event)
	var click := event as InputEventMouseButton
	if glyph.kind == Kind.MOUSE:
		glyph.mouse_button = click.button_index
		glyph.double_click = click.double_click
	glyph.caption = _caption_of(event, glyph.kind)
	glyph.along = _along(event)
	glyph.custom_minimum_size = glyph._wanted()
	return glyph


static func _kind_of(event: InputEvent) -> Kind:
	var button := event as InputEventJoypadButton
	if button != null:
		if (
			button.button_index
			in [
				JOY_BUTTON_DPAD_LEFT,
				JOY_BUTTON_DPAD_RIGHT,
				JOY_BUTTON_DPAD_UP,
				JOY_BUTTON_DPAD_DOWN,
			]
		):
			return Kind.DPAD
		# Only the four under the thumb are round: they are the ones with a single letter on them
		# and a color everybody knows. Start, Back and the stick clicks carry a word, and a word
		# squeezed into a circle is a smudge, so they take the same pill the shoulders do.
		if button.button_index in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y]:
			return Kind.FACE
		return Kind.SHOULDER
	var motion := event as InputEventJoypadMotion
	if motion != null:
		var trigger := motion.axis in [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]
		return Kind.SHOULDER if trigger else Kind.STICK
	var click := event as InputEventMouseButton
	if click != null and click.button_index in MOUSE_BUTTONS:
		return Kind.MOUSE
	return Kind.KEY


## What is written on the glyph. A stick carries which of the two it is and nothing else: the
## ring and the arrows say the rest, and "Left Stick X-Axis +" is a description of an input map
## rather than of anything a player does. The D-pad carries nothing, being one of a kind.
static func _caption_of(event: InputEvent, kind: Kind) -> String:
	if kind == Kind.DPAD:
		return ""
	if kind == Kind.MOUSE:
		var click := event as InputEventMouseButton
		return DOUBLE_MARK if click.double_click else ""
	if kind == Kind.STICK:
		var motion := event as InputEventJoypadMotion
		var right := motion != null and motion.axis in [JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y]
		return "R" if right else "L"
	return InputActions.event_text(event)


## Which way the stick is pushed or the pad pressed, on the screen: along X or along Y for a
## stick, in the direction the binding actually reads, and the direction itself for a D-pad.
static func _along(event: InputEvent) -> Vector2:
	var motion := event as InputEventJoypadMotion
	if motion != null:
		var way := -1.0 if motion.axis_value < 0.0 else 1.0
		var vertical := motion.axis in [JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_Y]
		return (Vector2.DOWN if vertical else Vector2.RIGHT) * way
	var button := event as InputEventJoypadButton
	if button != null:
		match button.button_index:
			JOY_BUTTON_DPAD_LEFT:
				return Vector2.LEFT
			JOY_BUTTON_DPAD_RIGHT:
				return Vector2.RIGHT
			JOY_BUTTON_DPAD_UP:
				return Vector2.UP
			JOY_BUTTON_DPAD_DOWN:
				return Vector2.DOWN
	return Vector2.RIGHT


## How big this glyph wants to be: square unless there is a word on it, which a key cap and a
## shoulder button widen to hold.
func _wanted() -> Vector2:
	var tall := HEIGHT * maxf(float(font_size) / 15.0, 1.0)
	if kind == Kind.STICK:
		return Vector2(tall * STICK_WIDE, tall * (STICK_WIDE if every_way else 1.0))
	if kind == Kind.FACE or kind == Kind.DPAD:
		return Vector2(tall, tall)
	if kind == Kind.MOUSE:
		var mark := 0.0
		if not caption.is_empty():
			mark = (
				_font().get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, _caption_size()).x
			)
			mark += SIDE_PAD * 0.5
		return Vector2(tall * MOUSE_WIDE + mark, tall)
	var run := _font().get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _caption_size()).x
	return Vector2(maxf(tall, run + SIDE_PAD * 2.0), tall)


func _caption_size() -> int:
	return maxi(font_size - CAPTION_DROP, MIN_CAPTION)


func _font() -> Font:
	var theme_font := get_theme_default_font()
	return ThemeDB.fallback_font if theme_font == null else theme_font


func _draw() -> void:
	var box := Rect2(Vector2.ZERO, size)
	# The three that are already a shape of their own go without the chip: a face button is a
	# round button, a stick is a round gate and the D-pad is a cross, and a box drawn round any of
	# them is a box drawn round a button. Everything else is a word, and a word needs something to
	# be written on.
	if kind == Kind.FACE:
		_draw_face(box)
		return
	if kind == Kind.STICK:
		_draw_stick(box)
		return
	if kind == Kind.DPAD:
		_draw_dpad(box)
		return
	if kind == Kind.MOUSE:
		_draw_mouse(box)
		return
	_draw_chip(box)
	_draw_caption(box, ink)


## The solid backing every glyph but a face button sits on: a key cap, or the same shape rounded
## off into a pill for a shoulder button and a trigger.
func _draw_chip(box: Rect2) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = CHIP
	style.border_color = Color(ink.r, ink.g, ink.b, EDGE_ALPHA)
	style.set_border_width_all(2)
	var radius := roundi(box.size.y * 0.5) if kind == Kind.SHOULDER else 5
	style.set_corner_radius_all(radius)
	style.shadow_color = CHIP_EDGE
	style.shadow_size = CHIP_SHADOW
	draw_style_box(style, box)


## A face button: the round one under the thumb, solid, in the color it is on the pad and with
## the letter on it in the dark the pad prints it in. Its own dark rim rather than the chip, so
## the color is the whole of the picture.
func _draw_face(box: Rect2) -> void:
	var tone: Color = FACE_COLORS.get(caption, ink)
	var center := box.size * 0.5
	var radius := minf(box.size.x, box.size.y) * 0.5 - 1.0
	draw_circle(center, radius + 1.5, CHIP_EDGE)
	draw_circle(center, radius, Color(tone.r, tone.g, tone.b, 0.95))
	draw_arc(center, radius, 0.0, TAU, 28, CHIP, EDGE_WIDTH)
	_draw_caption(box, FACE_INK)


## A stick seen from above: the gate it moves inside, which side it is written in the middle of
## it, and a solid head each way along the axis this binding reads. Solid heads rather than
## outlined ones, because the whole picture is twenty pixels across and a two-pixel chevron in it
## is a smudge.
##
## Drawn as a button rather than on one: the gate has the dark face and the dark rim a face
## button has, and the heads carry their own rim, so it reads over a felt floor without a box
## around it. The letter is inside the gate rather than beside it; it sat in a corner of the chip
## once, at a size that fits a corner, which is a size nothing is legible at.
func _draw_stick(box: Rect2) -> void:
	var edge := Color(ink.r, ink.g, ink.b, EDGE_ALPHA)
	var center := box.size * 0.5
	# The same circle a face button is, so the two sit together in a line without one of them
	# looking like the small one.
	var radius := box.size.x / STICK_WIDE * 0.5 - EDGE_WIDTH
	draw_circle(center, radius + EDGE_WIDTH, CHIP_EDGE)
	draw_circle(center, radius, CHIP)
	draw_arc(center, radius, 0.0, TAU, 28, edge, EDGE_WIDTH)
	# Built rather than written as a conditional literal: an untyped array assigned to a typed
	# one throws, and a throw halfway through a draw is a glyph with its gate and nothing in it.
	var ways: Array[Vector2] = [along]
	if both_ways:
		ways.append(-along)
	if every_way:
		ways.assign([Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP])
	var span := radius * 0.5
	for way: Vector2 in ways:
		var at := center + way * (radius * 1.35)
		_draw_head(at, way, span + EDGE_WIDTH * 1.6, CHIP_EDGE)
		_draw_head(at, way, span, edge)
	# Cut to the gate rather than to the line the glyph sits in: a letter that overflows the ring
	# it is written in reads as a letter with a circle drawn through it.
	_draw_caption(box, edge, mini(_caption_size(), roundi(box.size.y * 0.55)))


## The cross, with the arm this binding presses filled in. Its own dark rim rather than a chip
## behind it, the way a face button carries one, since the cross is already a shape.
func _draw_dpad(box: Rect2) -> void:
	var edge := Color(ink.r, ink.g, ink.b, EDGE_ALPHA)
	var faint := Color(ink.r, ink.g, ink.b, 0.30)
	var center := box.size * 0.5
	var reach := minf(box.size.x, box.size.y) * 0.44
	var thick := reach * 0.62
	# A dark rim first, as one cross slightly larger than the other, so it reads over felt with
	# nothing behind it.
	var rim := EDGE_WIDTH
	draw_rect(
		Rect2(
			center - Vector2(thick * 0.5 + rim, reach + rim),
			Vector2(thick + rim * 2.0, reach * 2.0 + rim * 2.0)
		),
		CHIP_EDGE
	)
	draw_rect(
		Rect2(
			center - Vector2(reach + rim, thick * 0.5 + rim),
			Vector2(reach * 2.0 + rim * 2.0, thick + rim * 2.0)
		),
		CHIP_EDGE
	)
	draw_rect(Rect2(center - Vector2(thick * 0.5, reach), Vector2(thick, reach * 2.0)), faint)
	draw_rect(Rect2(center - Vector2(reach, thick * 0.5), Vector2(reach * 2.0, thick)), faint)
	var arm := Rect2(center - Vector2(thick, thick) * 0.5, Vector2(thick, thick))
	draw_rect(
		arm.merge(Rect2(center + along * reach - Vector2(thick, thick) * 0.5, arm.size)), edge
	)


## A mouse seen from above, GAME.md 8.3: a rounded body split into its two buttons with the wheel
## between them, and the one this binding is for filled in the ink, the left or the right half or
## the wheel. A shape of its own, like a face button, so no chip round it: the body is dark with a
## rim in the ink. A double click says so beside it, "×2", since a second picture of the same mouse
## would read as two bindings.
func _draw_mouse(box: Rect2) -> void:
	var body := Rect2(
		box.position + Vector2(1.0, 1.0), Vector2(box.size.y * MOUSE_WIDE - 2.0, box.size.y - 2.0)
	)
	var corner := roundi(body.size.x * 0.5)
	var shell := StyleBoxFlat.new()
	shell.bg_color = CHIP
	shell.set_corner_radius_all(corner)
	shell.shadow_color = CHIP_EDGE
	shell.shadow_size = CHIP_SHADOW
	draw_style_box(shell, body)
	var split := body.size.y * 0.44
	var half := body.size.x * 0.5
	var lit := StyleBoxFlat.new()
	lit.bg_color = Color(ink.r, ink.g, ink.b, 0.95)
	if mouse_button == MOUSE_BUTTON_LEFT:
		lit.corner_radius_top_left = corner
		draw_style_box(lit, Rect2(body.position, Vector2(half, split)))
	elif mouse_button == MOUSE_BUTTON_RIGHT:
		lit.corner_radius_top_right = corner
		draw_style_box(lit, Rect2(body.position + Vector2(half, 0.0), Vector2(half, split)))
	var edge := Color(ink.r, ink.g, ink.b, EDGE_ALPHA)
	var top := body.position
	draw_line(top + Vector2(half, 0.0), top + Vector2(half, split), edge, EDGE_WIDTH)
	draw_line(top + Vector2(0.0, split), top + Vector2(body.size.x, split), edge, EDGE_WIDTH)
	var wheel := Rect2(
		top + Vector2(half - body.size.x * 0.1, split * 0.22),
		Vector2(body.size.x * 0.2, split * 0.56)
	)
	var roller := StyleBoxFlat.new()
	roller.bg_color = lit.bg_color if mouse_button == MOUSE_BUTTON_MIDDLE else CHIP
	roller.border_color = edge
	roller.set_border_width_all(1)
	roller.set_corner_radius_all(roundi(wheel.size.x * 0.5))
	draw_style_box(roller, wheel)
	var rim := StyleBoxFlat.new()
	rim.draw_center = false
	rim.border_color = edge
	rim.set_border_width_all(2)
	rim.set_corner_radius_all(corner)
	draw_style_box(rim, body)
	if not caption.is_empty():
		var beside := body.end.x + SIDE_PAD * 0.5
		_draw_caption(Rect2(beside, box.position.y, box.end.x - beside, box.size.y), ink)


## A small solid arrowhead at [param at], pointing [param way]. Drawn twice by its caller, once
## oversized in the dark, so it has a rim of its own where there is no chip to sit on.
func _draw_head(at: Vector2, way: Vector2, span: float, color: Color) -> void:
	var side := Vector2(-way.y, way.x)
	draw_colored_polygon(
		PackedVector2Array(
			[
				at - way * span * 0.5 + side * span * 0.7,
				at + way * span * 0.5,
				at - way * span * 0.5 - side * span * 0.7,
			]
		),
		color
	)


func _draw_caption(box: Rect2, color: Color, size_override: int = 0) -> void:
	if caption.is_empty():
		return
	var text_size := _caption_size() if size_override <= 0 else size_override
	var font := _font()
	var ascent := font.get_ascent(text_size)
	var descent := font.get_descent(text_size)
	var baseline := box.position.y + (box.size.y + ascent - descent) * 0.5
	draw_string(
		font,
		Vector2(box.position.x, baseline),
		caption,
		HORIZONTAL_ALIGNMENT_CENTER,
		box.size.x,
		text_size,
		color
	)
