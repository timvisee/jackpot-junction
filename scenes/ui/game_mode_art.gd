class_name GameModeArt
extends RefCounted
## A picture for each of the two kinds of game, GAME.md 9.7, drawn from the same shapes as the
## other pictures of 8.3a: a Grand Prix is a trophy, since it is played for one over several maps,
## and a quick match a stopwatch with a sliver of its face gone, since it is one map and over.


## A control that draws one kind of game's picture, square and centered in whatever room it is
## given.
class Picture:
	extends Control

	var grand_prix := true:
		set(value):
			grand_prix = value
			queue_redraw()
	var ink := Color.WHITE:
		set(value):
			ink = value
			queue_redraw()

	func _draw() -> void:
		var side := minf(size.x, size.y)
		var box := Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side))
		GameModeArt.draw_into(self, box, grand_prix, ink)


## The picture of a Grand Prix or of a quick match as a node, [param side] across.
static func picture(grand_prix: bool, ink: Color, side: float) -> Picture:
	var drawn := Picture.new()
	drawn.grand_prix = grand_prix
	drawn.ink = ink
	drawn.custom_minimum_size = Vector2(side, side)
	drawn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return drawn


static func draw_into(on: CanvasItem, box: Rect2, grand_prix: bool, ink: Color) -> void:
	if grand_prix:
		_trophy(on, box, ink)
	else:
		_stopwatch(on, box, ink)


## A cup on a stem and a plinth, a handle each side and the house's star on the front of it.
static func _trophy(on: CanvasItem, box: Rect2, ink: Color) -> void:
	var thick := IconShapes.span(box, 0.07)
	for side: Array in [[0.3, 90.0, 270.0], [0.7, -90.0, 90.0]]:
		var middle := IconShapes.at(box, side[0], 0.3)
		var reach := IconShapes.span(box, 0.12)
		on.draw_arc(middle, reach, deg_to_rad(side[1]), deg_to_rad(side[2]), 24, ink, thick, true)
	# The bowl: the lower half of an oval hung from its rim.
	var bowl := PackedVector2Array()
	var rim := IconShapes.at(box, 0.5, 0.14)
	var wide := box.size * Vector2(0.24, 0.38)
	for i: int in 17:
		var angle := PI * i / 16.0
		bowl.append(rim + Vector2(cos(angle) * wide.x, sin(angle) * wide.y))
	on.draw_colored_polygon(bowl, ink)
	IconShapes.bar(on, box, 0.46, 0.5, 0.08, 0.2, ink)
	IconShapes.bar(on, box, 0.34, 0.68, 0.32, 0.1, ink)
	IconShapes.bar(on, box, 0.28, 0.8, 0.44, 0.09, ink)
	IconShapes.star(on, box, 0.5, 0.29, 0.2, Color(0.0, 0.0, 0.0, 0.35 * ink.a))


## A stopwatch: the case, the button on top, and the hand with the time it has gone round filled.
static func _stopwatch(on: CanvasItem, box: Rect2, ink: Color) -> void:
	var middle := IconShapes.at(box, 0.5, 0.57)
	var reach := IconShapes.span(box, 0.34)
	var thick := IconShapes.span(box, 0.08)
	# The time gone, from the top round to where the hand is.
	var gone := PackedVector2Array([middle])
	for i: int in 13:
		var angle := deg_to_rad(-90.0 + 70.0 * i / 12.0)
		gone.append(middle + Vector2(cos(angle), sin(angle)) * (reach - thick * 0.5))
	on.draw_colored_polygon(gone, IconShapes.behind(ink))
	on.draw_arc(middle, reach, 0.0, TAU, 48, ink, thick, true)
	IconShapes.bar(on, box, 0.46, 0.13, 0.08, 0.1, ink)
	IconShapes.bar(on, box, 0.39, 0.06, 0.22, 0.08, ink)
	var hand := deg_to_rad(-20.0)
	on.draw_line(
		middle, middle + Vector2(cos(hand), sin(hand)) * reach * 0.72, ink, thick * 0.8, true
	)
	on.draw_circle(middle, IconShapes.span(box, 0.07), ink)
