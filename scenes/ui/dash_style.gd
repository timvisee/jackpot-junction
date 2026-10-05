class_name DashStyle
extends StyleBox
## A line of a receipt, GAME.md 8.1a: an optional wash of color behind it and a dashed rule along
## its foot, the lane's own dashes, which is how the house prints the line between two rows.

## The wash behind the row, clear for none, and the dashes along its foot.
@export var wash := Color(0.0, 0.0, 0.0, 0.0)
@export var dash := Color(0.0, 0.0, 0.0, 0.2)
## How long a dash is, the gap after it, and how thick.
@export var dash_long := 10.0
@export var dash_gap := 7.0
@export var thick := 1.0

var _box: StyleBoxFlat


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if wash.a > 0.0:
		if _box == null:
			_box = StyleBoxFlat.new()
			_box.anti_aliasing = true
			_box.set_corner_radius_all(6)
		_box.bg_color = wash
		_box.draw(to_canvas_item, rect)
	if dash.a <= 0.0:
		return
	var y := rect.end.y - thick * 0.5
	var x := rect.position.x
	while x < rect.end.x:
		var end := minf(x + dash_long, rect.end.x)
		RenderingServer.canvas_item_add_line(
			to_canvas_item, Vector2(x, y), Vector2(end, y), dash, thick, true
		)
		x += dash_long + dash_gap
