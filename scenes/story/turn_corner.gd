class_name TurnCorner
extends Control
## A page's bottom corner folded up in Kit's folder, STORY.md 7.2, where there is a leaf to turn
## that way: the corner of the page turned over onto it, the next page showing under the fold, and
## on the fold the button that turns the page, a pad's shoulder button or an arrow key, for the
## device in hand. Nothing on it for a touch screen, where the page itself is tapped.

## How big the fold is, and how big the button drawn on it.
const SIZE := 52.0
const BIND_SIZE := 12

## Which page's corner: [constant SIDE_LEFT], the left page's bottom left, turning back, or
## [constant SIDE_RIGHT], the right page's bottom right, turning on.
var side := SIDE_RIGHT

var _bind: Control


## The fold for the [param on] page's corner.
static func make(on: Side) -> TurnCorner:
	var corner := TurnCorner.new()
	corner.name = "TurnBack" if on == SIDE_LEFT else "TurnOn"
	corner.side = on
	corner.size = Vector2.ONE * SIZE
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return corner


## The button that turns the page this way drawn on the fold, for a keyboard or for a pad as
## [param keyboard] says.
func show_bind(keyboard: bool) -> void:
	if _bind != null and is_instance_valid(_bind):
		remove_child(_bind)
		_bind.queue_free()
	_bind = null
	if TouchInput.enabled:
		return
	var press: InputEvent
	if keyboard:
		var key := InputEventKey.new()
		key.keycode = KEY_LEFT if side == SIDE_LEFT else KEY_RIGHT
		press = key
	else:
		var button := InputEventJoypadButton.new()
		button.button_index = (
			JOY_BUTTON_LEFT_SHOULDER if side == SIDE_LEFT else JOY_BUTTON_RIGHT_SHOULDER
		)
		press = button
	_bind = InputGlyph.of_event(press, NotePage.PENCIL, BIND_SIZE)
	add_child(_bind)
	# On the fold, in the middle of the triangle it makes.
	var middle := Vector2(SIZE / 3.0 if side == SIDE_RIGHT else SIZE * 2.0 / 3.0, SIZE / 3.0)
	_bind.position = middle - _bind.custom_minimum_size * 0.5


func _draw() -> void:
	# Drawn for the right page's corner and mirrored for the left: the corner at the bottom right,
	# folded up along the diagonal onto the page.
	var flip := side == SIDE_LEFT
	var at := func(point: Vector2) -> Vector2:
		return Vector2(SIZE - point.x, point.y) if flip else point
	var under := PackedVector2Array(
		[at.call(Vector2(0.0, SIZE)), at.call(Vector2.ONE * SIZE), at.call(Vector2(SIZE, 0.0))]
	)
	var fold := PackedVector2Array(
		[at.call(Vector2(0.0, SIZE)), at.call(Vector2(SIZE, 0.0)), at.call(Vector2.ZERO)]
	)
	# The next page, shadowed under the fold.
	draw_colored_polygon(under, NotePage.LEAF.darkened(0.18))
	# The fold's shadow on the page past its outer edges, and the fold itself: the back of the
	# page, lit toward its tip and shaded toward the crease.
	var shadow := PackedVector2Array()
	for point: Vector2 in fold:
		shadow.append(point + at.call(Vector2(-2.0, -2.0)) - at.call(Vector2.ZERO))
	draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.1))
	var crease := NotePage.LEAF.darkened(0.09)
	draw_polygon(fold, PackedColorArray([crease, crease, NotePage.LEAF.lightened(0.03)]))
	draw_polyline(
		PackedVector2Array([fold[0], fold[2], fold[1]]), Color(NotePage.LEAF_EDGE, 0.5), 1.0, true
	)
	draw_line(fold[0], fold[1], NotePage.LEAF_EDGE.darkened(0.1), 1.0, true)
