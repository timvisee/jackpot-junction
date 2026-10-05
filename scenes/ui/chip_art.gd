class_name ChipArt
extends RefCounted
## Anything round in the house's print is a chip, GAME.md 8.1a: a disc with notches round its rim,
## which say poker chip at any size the way the chips on the table do, and a darker ring inside
## them. And the mult's own picture beside it, the die the mult is picked up as. Drawn as shapes
## onto whatever asks, so a chip is sharp at any size.

## The cream of the notches, and how many of them a chip has.
const NOTCHES := Color(0.97, 0.95, 0.9)
const NOTCH_COUNT := 8
## The die: its face and its pips.
const DIE := Color(0.97, 0.95, 0.9)
const PIP := Color(0.09, 0.09, 0.1)


## A chip of [param face] round [param middle], [param radius] out, onto [param canvas].
static func chip(
	canvas: CanvasItem, middle: Vector2, radius: float, face: Color, notches := NOTCH_COUNT
) -> void:
	canvas.draw_circle(middle, radius, face, true, -1.0, true)
	var deep := radius * 0.25
	var half := radius * 0.15
	for i: int in notches:
		var toward := Vector2.from_angle(float(i) * TAU / float(notches))
		var across := toward.orthogonal()
		var out := middle + toward * (radius - 0.4)
		var inn := middle + toward * (radius - deep)
		canvas.draw_colored_polygon(
			PackedVector2Array(
				[out + across * half, out - across * half, inn - across * half, inn + across * half]
			),
			Color(NOTCHES, face.a)
		)
	canvas.draw_arc(
		middle, radius * 0.64, 0.0, TAU, 32, face.darkened(0.25), maxf(radius * 0.07, 1.0), true
	)


## A chip with [param text] on it, a place in the standings or on the payout slip: the number in
## the middle of the chip by the height of its figures rather than by the line it would sit on as
## a label, which put it low and to one side, in dark ink on a light chip and white on a dark one.
static func numbered(
	canvas: CanvasItem, middle: Vector2, radius: float, face: Color, text: String
) -> void:
	chip(canvas, middle, radius, face)
	var font := Type.numbers_font()
	var font_size := roundi(radius * 1.05)
	var wide := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline := middle.y + float(font_size) * Type.CAP_HEIGHT * 0.5
	canvas.draw_string(
		font,
		Vector2(middle.x - wide * 0.5, baseline),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		HouseTheme.INK if is_light(face) else Color.WHITE
	)


## The die the mult is picked up as, filling [param box]: white with three pips across it.
static func die(canvas: CanvasItem, box: Rect2) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = DIE
	style.set_corner_radius_all(roundi(box.size.x * 0.2))
	style.anti_aliasing = true
	canvas.draw_style_box(style, box)
	for at: float in [0.27, 0.5, 0.73]:
		canvas.draw_circle(box.position + box.size * at, box.size.x * 0.09, PIP, true, -1.0, true)


## Whether [param ink] is light enough that what is written on it wants dark ink rather than white.
static func is_light(ink: Color) -> bool:
	return ink.get_luminance() > 0.55
