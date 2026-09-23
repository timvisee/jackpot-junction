class_name RankArrow
extends Control
## An arrow beside a place on the Grand Prix podium, GAME.md 9.7: green and up for a player who
## climbed the standings on the last map, red and down for one who fell. Drawn rather than typed,
## so it does not depend on the font having an arrow in it.

const UP := Color(0.36, 0.86, 0.46)
const DOWN := Color(0.93, 0.33, 0.33)
const SIZE := Vector2(16.0, 14.0)

var up := true


static func create(going_up: bool) -> RankArrow:
	var arrow := RankArrow.new()
	arrow.up = going_up
	arrow.custom_minimum_size = SIZE
	arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return arrow


func _draw() -> void:
	var w := size.x
	var h := size.y
	var points := (
		PackedVector2Array([Vector2(w * 0.5, 0.0), Vector2(w, h), Vector2(0.0, h)])
		if up
		else PackedVector2Array([Vector2(0.0, 0.0), Vector2(w, 0.0), Vector2(w * 0.5, h)])
	)
	draw_colored_polygon(points, UP if up else DOWN)
