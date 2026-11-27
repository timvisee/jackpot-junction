class_name DriveArt
extends RefCounted
## A picture for each of the two ways to drive, GAME.md 4.2, drawn as the pictures of 8.3a are:
## simple is a kart with an arrow each way round it, since the way pushed is the way it goes, and
## advanced a steering wheel, since that is what it is. And one for each of the two ways a touch
## screen drives: the slider, a tall pill cut into its zones with the gas under the thumb filled,
## and the buttons, a big round one in the corner with three round it. On buttons, so printed flat
## in one ink, the button showing through them.


## A control that draws one way to drive's picture, square and centered in whatever room it is
## given.
class Picture:
	extends Control

	var mode := Settings.DRIVE_SIMPLE:
		set(value):
			mode = value
			queue_redraw()
	var ink := Color.WHITE:
		set(value):
			ink = value
			queue_redraw()

	func _draw() -> void:
		var side := minf(size.x, size.y)
		var box := Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side))
		DriveArt.draw_into(self, box, mode, ink)


## The picture of [param mode] as a node, [param side] across, sized by whatever it is put in past
## that.
static func picture(mode: String, ink: Color, side: float) -> Picture:
	var drawn := Picture.new()
	drawn.mode = mode
	drawn.ink = ink
	drawn.custom_minimum_size = Vector2(side, side)
	drawn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return drawn


static func draw_into(on: CanvasItem, box: Rect2, mode: String, ink: Color) -> void:
	var drawing := &"drive_advanced"
	match mode:
		Settings.DRIVE_SIMPLE:
			drawing = &"drive_simple"
		Settings.TOUCH_SLIDER:
			drawing = &"drive_slider"
		Settings.TOUCH_BUTTONS:
			drawing = &"drive_buttons"
	IconPress.draw(on, box, drawing, ink, IconPress.Ground.PAPER)
