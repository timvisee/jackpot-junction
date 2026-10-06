class_name ArrowStyle
extends StyleBox
## A sign cut to an arrow, GAME.md 8.1a: a ticket, its back corners notched, whose front end comes
## to a point at what it is about, the way a direction sign at a junction does. The driving
## school's: the flyer on the title pointing at its button, and the cards of a lesson pointing at
## the piece of the HUD they are about. The point is part of the cut rather than a triangle laid
## beside it, and the content keeps clear of it.

enum Way { NONE, LEFT, DOWN }

## The stock it is cut from, and the hairline just inside its edge; clear for none.
@export var fill := Color(HouseTheme.STOCK, 0.9):
	set = _set_fill
@export var edge := Color(0.0, 0.0, 0.0, 0.0):
	set = _set_edge
## Which way its point goes, see [method point], and how long the point is.
@export var way := Way.NONE:
	set = _set_way
@export var tip := 14.0:
	set = _set_tip
## The notch of the back corners, and how far in the hairline runs.
@export var notch := 8.0:
	set = _set_notch
@export var inset := 4.0:
	set = _set_inset
## A soft shadow under it, how far it spreads, and what it is printed on, a part of the house print
## whose texture it wears, see [method Surface.finish]; empty for flat.
@export var shadow := 0.0:
	set = _set_shadow
@export var finish := "":
	set = _set_finish

var _kept: Dictionary[Vector2, Dictionary] = {}
var _shade: StyleBoxFlat


## A sign of [param stock] pointing [param toward], its point [param point] long, with room
## [param across] and [param down] round its content, the point's room besides.
static func cut(stock: Color, toward: Way, point: float, across: float, down: float) -> ArrowStyle:
	var style := ArrowStyle.new()
	style.fill = stock
	style.tip = point
	style.content_margin_left = across
	style.content_margin_right = across
	style.content_margin_top = down
	style.content_margin_bottom = down
	style.point(toward)
	return style


## Turns the point [param toward] a side, moving the room it takes round the content with it.
func point(toward: Way) -> void:
	_room(way, -1.0)
	way = toward
	_room(way, 1.0)


## The arrow's edge for a sign [param size] big, [param inward] in from the cut.
func outline(size: Vector2, inward: float) -> PackedVector2Array:
	var w := size.x - inward
	var h := size.y - inward
	var left := inward
	var top := inward
	var points := PackedVector2Array()
	match way:
		Way.LEFT:
			var body := tip + inward * 0.6
			(
				points
				. append_array(
					[
						Vector2(inward * 1.6, size.y * 0.5),
						Vector2(body, top),
						Vector2(w - notch, top),
						Vector2(w, top + notch),
						Vector2(w, h - notch),
						Vector2(w - notch, h),
						Vector2(body, h),
					]
				)
			)
		Way.DOWN:
			var foot := size.y - tip - inward * 0.6
			(
				points
				. append_array(
					[
						Vector2(left + notch, top),
						Vector2(w - notch, top),
						Vector2(w, top + notch),
						Vector2(w, foot),
						Vector2(size.x * 0.5 + tip, foot),
						Vector2(size.x * 0.5, size.y - inward * 1.6),
						Vector2(size.x * 0.5 - tip, foot),
						Vector2(left, foot),
						Vector2(left, top + notch),
					]
				)
			)
		_:
			(
				points
				. append_array(
					[
						Vector2(left + notch, top),
						Vector2(w - notch, top),
						Vector2(w, top + notch),
						Vector2(w, h - notch),
						Vector2(w - notch, h),
						Vector2(left + notch, h),
						Vector2(left, h - notch),
						Vector2(left, top + notch),
					]
				)
			)
	return points


func _get_draw_rect(rect: Rect2) -> Rect2:
	return rect


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if rect.size.x < 2.0 or rect.size.y < 2.0:
		return
	var made := _made(rect.size)
	if shadow > 0.0:
		if _shade == null:
			_shade = StyleBoxFlat.new()
			_shade.bg_color = Color(0.0, 0.0, 0.0, 0.0)
			_shade.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
			_shade.set_corner_radius_all(6)
		_shade.shadow_size = roundi(shadow)
		var body := _body(rect)
		_shade.draw(to_canvas_item, body)
	RenderingServer.canvas_item_add_set_transform(to_canvas_item, Transform2D(0.0, rect.position))
	var shape: PackedVector2Array = made["shape"]
	if fill.a > 0.0:
		RenderingServer.canvas_item_add_polygon(to_canvas_item, shape, [fill])
		RenderingServer.canvas_item_add_polyline(to_canvas_item, made["closed"], [fill], 1.0, true)
		if not finish.is_empty():
			var look := Surface.finish(finish)
			Surface.draw(
				to_canvas_item, made, shape, rect.size, look[0] as Surface.Kind, float(look[1])
			)
			Surface.light(to_canvas_item, shape, rect.size, float(look[2]))
	if edge.a > 0.0:
		RenderingServer.canvas_item_add_polyline(to_canvas_item, made["line"], [edge], 1.2, true)
	RenderingServer.canvas_item_add_set_transform(to_canvas_item, Transform2D.IDENTITY)


## The part of [param rect] that is not the point, which the shadow is cast from.
func _body(rect: Rect2) -> Rect2:
	match way:
		Way.LEFT:
			return Rect2(rect.position + Vector2(tip, 0.0), rect.size - Vector2(tip, 0.0))
		Way.DOWN:
			return Rect2(rect.position, rect.size - Vector2(0.0, tip))
	return rect


func _made(size: Vector2) -> Dictionary:
	if _kept.has(size):
		return _kept[size]
	if _kept.size() > 6:
		_kept.clear()
	var shape := outline(size, 0.0)
	var closed := shape.duplicate()
	closed.append(shape[0])
	var line := outline(size, inset)
	line.append(line[0])
	var made := {"shape": shape, "closed": closed, "line": line}
	_kept[size] = made
	return made


func _changed() -> void:
	_kept.clear()
	emit_changed()


func _set_fill(value: Color) -> void:
	fill = value
	emit_changed()


func _set_edge(value: Color) -> void:
	edge = value
	emit_changed()


func _set_way(value: Way) -> void:
	way = value
	_changed()


func _set_tip(value: float) -> void:
	tip = value
	_changed()


func _set_notch(value: float) -> void:
	notch = value
	_changed()


func _set_inset(value: float) -> void:
	inset = value
	_changed()


func _set_shadow(value: float) -> void:
	shadow = value
	emit_changed()


func _set_finish(value: String) -> void:
	finish = value
	_changed()


## Adds the point's room to the content margin on the side [param toward] points, or takes it off.
func _room(toward: Way, sign_of: float) -> void:
	if toward == Way.LEFT:
		content_margin_left = maxf(content_margin_left + tip * sign_of, 0.0)
	elif toward == Way.DOWN:
		content_margin_bottom = maxf(content_margin_bottom + tip * sign_of, 0.0)
