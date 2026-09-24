class_name DriveArt
extends RefCounted
## A picture for each of the two ways to drive, GAME.md 4.2, drawn from the same shapes as the
## joker and power-up pictures of 8.3a: simple is a kart with an arrow each way round it, since
## the way pushed is the way it goes, and advanced a steering wheel, since that is what it is.


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
	if mode == Settings.DRIVE_SIMPLE:
		_simple(on, box, ink)
	else:
		_advanced(on, box, ink)


## A kart from above, nose up, with an arrow each way round it.
static func _simple(on: CanvasItem, box: Rect2, ink: Color) -> void:
	var faint := IconShapes.behind(ink)
	# The wheels first, a pair each side, so the body sits over their inner edges.
	for x: float in [0.29, 0.61]:
		for y: float in [0.35, 0.57]:
			IconShapes.bar(on, box, x, y, 0.1, 0.13, faint)
	IconShapes.bar(on, box, 0.37, 0.32, 0.26, 0.42, ink)
	IconShapes.bar(on, box, 0.33, 0.29, 0.34, 0.07, ink)
	# The driver, a shade darker than the kart whatever it is drawn on.
	IconShapes.disc(on, box, 0.5, 0.56, 0.07, Color(0.0, 0.0, 0.0, 0.35 * ink.a))
	for arrow: Array in [
		[0.5, 0.11, 0.0], [0.89, 0.5, 90.0], [0.5, 0.89, 180.0], [0.11, 0.5, 270.0]
	]:
		IconShapes.tri(on, box, arrow[0], arrow[1], 0.22, arrow[2], ink)


## A steering wheel: the rim, three spokes and the hub.
static func _advanced(on: CanvasItem, box: Rect2, ink: Color) -> void:
	var center := IconShapes.at(box, 0.5, 0.5)
	var thick := IconShapes.span(box, 0.1)
	var rim := IconShapes.span(box, 0.4) - thick * 0.5
	on.draw_arc(center, rim, 0.0, TAU, 48, ink, thick, true)
	var spoke := IconShapes.span(box, 0.08)
	for angle: float in [0.0, PI * 0.5, PI]:
		var out := Vector2(cos(angle), sin(angle))
		on.draw_line(center, center + out * rim, ink, spoke, true)
	on.draw_circle(center, IconShapes.span(box, 0.12), ink)
