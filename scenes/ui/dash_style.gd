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
## Whether the row runs on into the one above it or below it, its wash square at that edge so the
## two washes read as one, as a team's lines on the payout slip do, GAME.md 3.14.
@export var joined_top := false
@export var joined_bottom := false
## How far the wash reaches up above the row, to close the gap the rows' spacing leaves so a
## highlighted line meets the dashed rule over it rather than floating a little under it, see
## [SlipPage]; its top squared off there so it sits flush to the rule.
@export var extend_top := 0.0

var _box: StyleBoxFlat


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if wash.a > 0.0:
		if _box == null:
			_box = StyleBoxFlat.new()
			_box.anti_aliasing = true
			_box.set_corner_radius_all(6)
		_box.bg_color = wash
		var top := 0 if joined_top or extend_top > 0.0 else 6
		var bottom := 0 if joined_bottom else 6
		_box.corner_radius_top_left = top
		_box.corner_radius_top_right = top
		_box.corner_radius_bottom_left = bottom
		_box.corner_radius_bottom_right = bottom
		_box.draw(to_canvas_item, rect.grow_individual(0.0, extend_top, 0.0, 0.0))
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
