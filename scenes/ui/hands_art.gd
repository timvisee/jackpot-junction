class_name HandsArt
extends RefCounted
## The hands of GAME.md 7.3 drawn: a little fanned row of playing cards for each, as the pay tables
## show them, in the hand's HUD, on the catalog's page of hands and on its ticket, 8.3 and 8.8.


## A little card of [param suit] round [param middle], [param size] big and turned [param tilt],
## under the transform [param base].
static func card(
	on: CanvasItem, middle: Vector2, suit: int, size: Vector2, tilt: float, base := Transform2D()
) -> void:
	on.draw_set_transform_matrix(base * Transform2D(tilt, middle))
	var face := StyleBoxFlat.new()
	face.set_corner_radius_all(maxi(2, roundi(size.x * 0.13)))
	face.anti_aliasing = true
	face.bg_color = HouseTheme.PAPER
	face.set_border_width_all(1)
	face.border_color = Color(0.0, 0.0, 0.0, 0.5)
	on.draw_style_box(face, Rect2(-size * 0.5, size))
	var side := size.x * 0.66
	var box := Rect2(-Vector2.ONE * side * 0.5, Vector2.ONE * side)
	SuitArt.draw_into(on, box, suit, JokerSuits.color_of(suit, true))
	on.draw_set_transform_matrix(base)


## [param suits] fanned from [param left], their middles on its height, each [param size] big;
## how far across the fan reaches.
static func fan(
	on: CanvasItem, left: Vector2, suits: Array, size: Vector2, base := Transform2D()
) -> float:
	var step := size.x * 0.62
	for i: int in suits.size():
		var tilt := 0.07 * (float(i) - float(suits.size() - 1) * 0.5)
		card(on, left + Vector2(size.x * 0.5 + i * step, 0.0), suits[i], size, tilt, base)
	return size.x + step * maxi(suits.size() - 1, 0)
