class_name GameModeArt
extends RefCounted
## A picture for each of the two kinds of game, GAME.md 9.7, drawn as the other pictures of 8.3a
## are: a Grand Prix is a trophy, since it is played for one over several maps, and a quick match a
## stopwatch with a sliver of its face gone, since it is one map and over. On a button, so printed
## flat in one ink, the button showing through it.


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
	IconPress.draw(
		on,
		box,
		&"mode_grand_prix" if grand_prix else &"mode_quick_match",
		ink,
		IconPress.Ground.PAPER
	)
