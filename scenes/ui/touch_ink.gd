class_name TouchInk
extends RefCounted
## The color the touch controls are cut in, GAME.md 4.2: the player's own, as their corner of the
## HUD and their nitro cells are, so the buttons under the thumbs say whose they are; the house's
## gold until there is a player. A touch screen has one player, so one color serves all of it,
## put on by [TouchControls] each frame. And the notches round a round button's rim, a chip's.

static var accent := Palette.CHIP_GOLD


## The rim of a button, its notches, the stick and the slider, in [member accent].
static func rim() -> Color:
	return Color(accent, TouchControls.RIM)


## A button under a finger, lit in [member accent].
static func fill_down() -> Color:
	return Color(accent, TouchControls.FILL_DOWN)


## The nitro tank, in [member accent].
static func tank() -> Color:
	return Color(accent, TouchControls.TANK)


## The notches round the rim of a round button, the way a chip's are, onto [param canvas].
static func notch(canvas: CanvasItem, at: Vector2, radius: float, strength: float) -> void:
	var ink := Color(rim(), TouchControls.RIM * TouchControls.NOTCH_SHOWS * strength)
	var half := radius * TouchControls.NOTCH * 0.5
	var count := TouchControls.NOTCHES
	for i: int in count:
		var toward := Vector2.from_angle(float(i) * TAU / float(count) + TAU / float(count * 2))
		var across := toward.orthogonal() * half
		var out := at + toward * (radius - TouchControls.RIM_WIDTH * 0.5)
		var inn := at + toward * (radius - radius * TouchControls.NOTCH * 1.6)
		canvas.draw_colored_polygon(
			PackedVector2Array([out + across, out - across, inn - across, inn + across]), ink
		)
