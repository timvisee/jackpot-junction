class_name InputGlyph
extends Control
## One binding drawn rather than written, GAME.md 8.3: a key as a key cap with the key on it, a
## gamepad face button as a round button in its own colour, a shoulder or a trigger as a pill,
## a stick as a stick and the D-pad as a D-pad.
##
## "Shift drift   Ctrl nitro" is a sentence to be read. The same line with the two keys drawn as
## keys is a picture to be recognised, which is what a hint glanced at mid-corner has to be. The
## shapes are drawn rather than loaded, because the bindings belong to the player: any key on the
## keyboard can end up in one of these, and no set of pictures can cover that in advance.

enum Kind { KEY, FACE, SHOULDER, STICK, DPAD }

## How tall a glyph is by default and how much air sits either side of the caption inside one.
const HEIGHT := 22.0
const SIDE_PAD := 6.0
## The caption is a size down from the line it sits in, since it is inside a box with edges, and
## never smaller than this or the cap says nothing.
const CAPTION_DROP := 3
const MIN_CAPTION := 11
## The face buttons in the colours everybody's pad has on them, so A reads as A before it is read.
const FACE_COLORS: Dictionary[String, Color] = {
	"A": Color("#5FBF5F"),
	"B": Color("#D9534F"),
	"X": Color("#4A7FD4"),
	"Y": Color("#E8C33D"),
}
## The chip every glyph is drawn on. Solid and dark, with a soft black edge around it and a
## rim in the colour of the line it sits in: dark against the felt, the crowd and a light wall,
## rimmed against the night sky of a menu. It started out as a 16% wash of the text colour, which
## is a chip you have to find before you can read it, and a hint you have to find has already
## cost the corner you were reading it in.
const CHIP := Color(0.05, 0.05, 0.07, 0.92)
const CHIP_EDGE := Color(0.0, 0.0, 0.0, 0.55)
const CHIP_SHADOW := 3
const EDGE_ALPHA := 0.92
const EDGE_WIDTH := 1.6
## How dark the letter on a gamepad's own coloured button is, which is how it is on the pad.
const FACE_INK := Color(0.06, 0.06, 0.08)
## How much wider than tall a stick is drawn. The letter goes inside the ring, so the ring has to
## hold a letter, and the arrows still have to fit outside it: in a square chip the two fight and
## the arrows lose, coming out as nicks in the border.
const STICK_WIDE := 1.55

var kind := Kind.KEY
## What is written on the glyph: the key, the button, or the stick's side.
var caption := ""
## The colour of the line the glyph sits in, which everything but a face button is drawn in.
var ink := Color.WHITE
var font_size := 15
## Which way a stick is moved or a D-pad is pressed, as a unit vector on the screen.
var along := Vector2.RIGHT
## Whether this is a stick that moves both ways along its axis. One binding is half a stick and
## is drawn pushed that way; a pair of them, GAME.md 8.3, is the whole stick and is drawn centred.
var both_ways := false


## The first binding of [param action] for one device kind, as a glyph. Null when nothing is
## bound to it there, which is what a hint should leave out rather than write a dash for.
static func of_action(action: StringName, keyboard: bool, ink: Color, font_size: int) -> InputGlyph:
	var event := InputActions.first_event(action, keyboard)
	return null if event == null else of_event(event, ink, font_size)


static func of_event(event: InputEvent, ink: Color, font_size: int) -> InputGlyph:
	var glyph := InputGlyph.new()
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.ink = ink
	glyph.font_size = font_size
	glyph.kind = _kind_of(event)
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
		# and a colour everybody knows. Start, Back and the stick clicks carry a word, and a word
		# squeezed into a circle is a smudge, so they take the same pill the shoulders do.
		if button.button_index in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y]:
			return Kind.FACE
		return Kind.SHOULDER
	var motion := event as InputEventJoypadMotion
	if motion != null:
		var trigger := motion.axis in [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]
		return Kind.SHOULDER if trigger else Kind.STICK
	return Kind.KEY


## What is written on the glyph. A stick carries which of the two it is and nothing else: the
## ring and the arrows say the rest, and "Left Stick X-Axis +" is a description of an input map
## rather than of anything a player does. The D-pad carries nothing, being one of a kind.
static func _caption_of(event: InputEvent, kind: Kind) -> String:
	if kind == Kind.DPAD:
		return ""
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
		return Vector2(tall * STICK_WIDE, tall)
	if kind == Kind.FACE or kind == Kind.DPAD:
		return Vector2(tall, tall)
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


## A face button: the round one under the thumb, solid, in the colour it is on the pad and with
## the letter on it in the dark the pad prints it in. Its own dark rim rather than the chip, so
## the colour is the whole of the picture.
func _draw_face(box: Rect2) -> void:
	var tone: Color = FACE_COLORS.get(caption, ink)
	var centre := box.size * 0.5
	var radius := minf(box.size.x, box.size.y) * 0.5 - 1.0
	draw_circle(centre, radius + 1.5, CHIP_EDGE)
	draw_circle(centre, radius, Color(tone.r, tone.g, tone.b, 0.95))
	draw_arc(centre, radius, 0.0, TAU, 28, CHIP, EDGE_WIDTH)
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
	var centre := box.size * 0.5
	# The same circle a face button is, so the two sit together in a line without one of them
	# looking like the small one.
	var radius := box.size.y * 0.5 - EDGE_WIDTH
	draw_circle(centre, radius + EDGE_WIDTH, CHIP_EDGE)
	draw_circle(centre, radius, CHIP)
	draw_arc(centre, radius, 0.0, TAU, 28, edge, EDGE_WIDTH)
	# Built rather than written as a conditional literal: an untyped array assigned to a typed
	# one throws, and a throw halfway through a draw is a glyph with its gate and nothing in it.
	var ways: Array[float] = [1.0]
	if both_ways:
		ways.append(-1.0)
	var span := radius * 0.5
	for way: float in ways:
		var at := centre + along * (radius * way * 1.35)
		_draw_head(at, along * way, span + EDGE_WIDTH * 1.6, CHIP_EDGE)
		_draw_head(at, along * way, span, edge)
	# Cut to the gate rather than to the line the glyph sits in: a letter that overflows the ring
	# it is written in reads as a letter with a circle drawn through it.
	_draw_caption(box, edge, mini(_caption_size(), roundi(box.size.y * 0.55)))


## The cross, with the arm this binding presses filled in. Its own dark rim rather than a chip
## behind it, the way a face button carries one, since the cross is already a shape.
func _draw_dpad(box: Rect2) -> void:
	var edge := Color(ink.r, ink.g, ink.b, EDGE_ALPHA)
	var faint := Color(ink.r, ink.g, ink.b, 0.30)
	var centre := box.size * 0.5
	var reach := minf(box.size.x, box.size.y) * 0.44
	var thick := reach * 0.62
	# A dark rim first, as one cross slightly larger than the other, so it reads over felt with
	# nothing behind it.
	var rim := EDGE_WIDTH
	draw_rect(
		Rect2(
			centre - Vector2(thick * 0.5 + rim, reach + rim),
			Vector2(thick + rim * 2.0, reach * 2.0 + rim * 2.0)
		),
		CHIP_EDGE
	)
	draw_rect(
		Rect2(
			centre - Vector2(reach + rim, thick * 0.5 + rim),
			Vector2(reach * 2.0 + rim * 2.0, thick + rim * 2.0)
		),
		CHIP_EDGE
	)
	draw_rect(Rect2(centre - Vector2(thick * 0.5, reach), Vector2(thick, reach * 2.0)), faint)
	draw_rect(Rect2(centre - Vector2(reach, thick * 0.5), Vector2(reach * 2.0, thick)), faint)
	var arm := Rect2(centre - Vector2(thick, thick) * 0.5, Vector2(thick, thick))
	draw_rect(
		arm.merge(Rect2(centre + along * reach - Vector2(thick, thick) * 0.5, arm.size)), edge
	)


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
