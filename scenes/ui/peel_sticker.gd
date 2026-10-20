class_name PeelSticker
extends Control
## A room's sticker stuck on the loading screen, GAME.md 8.6, there from the moment the screen is:
## the room's emblem, see [RoomEmblem], printed on a white label with rounded corners, one corner
## of it peeled up and folded back on itself, its gray back showing over the shadow it throws, so
## it reads as a real sticker slapped down beside the hand rather than a picture.
##
## Drawn, not a picture of its own: the label and the fold are polygons, and the emblem is drawn
## onto the label cut to the same line, so the folded corner takes the print with it.

## How big it is, in pixels; how much of its width the folded corner takes and how far in from
## the label's edge the print sits; how round its corners are.
const SIDE := 124.0
const FOLD := 0.3
const INSET := 0.09
const ROUND := 12.0
## The label, its back where it is folded, and the shadows under it and under the fold.
const LABEL := Color("#F7F3EA")
const BACK := Color("#D8D2C4")
const BACK_DEEP := Color("#B9B2A2")
const SHADOW := Color(0.0, 0.0, 0.0, 0.38)
const SHADOW_OFF := Vector2(4.0, 6.0)

var emblem: Texture2D


func _init(texture: Texture2D = null) -> void:
	name = "PeelSticker"
	emblem = texture
	custom_minimum_size = Vector2.ONE * SIDE
	size = custom_minimum_size
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## The label's outline: a rounded square with the folded corner, its bottom right, cut off along
## the crease.
func outline() -> PackedVector2Array:
	var cut := Geometry2D.clip_polygons(_rounded(), _corner())
	return cut[0] if not cut.is_empty() else _rounded()


func _draw() -> void:
	var label := outline()
	var shadow := PackedVector2Array()
	for point: Vector2 in label:
		shadow.append(point + SHADOW_OFF)
	draw_colored_polygon(shadow, SHADOW)
	draw_colored_polygon(label, LABEL)
	if emblem != null:
		var inset := Rect2(Vector2.ONE * SIDE * INSET, Vector2.ONE * SIDE * (1.0 - INSET * 2.0))
		var box := PackedVector2Array(
			[
				inset.position,
				Vector2(inset.end.x, inset.position.y),
				inset.end,
				Vector2(inset.position.x, inset.end.y),
			]
		)
		for piece: PackedVector2Array in Geometry2D.intersect_polygons(box, label):
			var uvs := PackedVector2Array()
			for point: Vector2 in piece:
				uvs.append((point - inset.position) / inset.size)
			draw_polygon(piece, PackedColorArray([Color.WHITE]), uvs, emblem)
	# The corner folded back over the label: its shadow, then its back, lighter at the crease.
	var f := SIDE * FOLD
	var a := Vector2(SIDE - f, SIDE)
	var b := Vector2(SIDE, SIDE - f)
	var tip := Vector2(SIDE - f, SIDE - f)
	var flap_shadow := PackedVector2Array([a, b, tip + Vector2(-3.0, -2.0)])
	draw_colored_polygon(flap_shadow, Color(SHADOW, 0.22))
	draw_polygon(PackedVector2Array([a, b, tip]), PackedColorArray([BACK, BACK, BACK_DEEP]))
	draw_polyline(PackedVector2Array([a, b]), Color(1.0, 1.0, 1.0, 0.6), 1.5, true)


func _rounded() -> PackedVector2Array:
	var points := PackedVector2Array()
	var corners: Array[Vector2] = [
		Vector2(SIDE - ROUND, ROUND),
		Vector2(SIDE - ROUND, SIDE - ROUND),
		Vector2(ROUND, SIDE - ROUND),
		Vector2(ROUND, ROUND),
	]
	for i: int in corners.size():
		for step: int in 7:
			var angle := -PI * 0.5 + PI * 0.5 * (float(i) + float(step) / 6.0)
			points.append(corners[i] + Vector2(cos(angle), sin(angle)) * ROUND)
	return points


func _corner() -> PackedVector2Array:
	var f := SIDE * FOLD
	return PackedVector2Array(
		[Vector2(SIDE - f, SIDE), Vector2(SIDE, SIDE - f), Vector2(SIDE + 40.0, SIDE + 40.0)]
	)
