class_name LaneStyle
extends StyleBox
## A lane, GAME.md 8.1a: a strip of road with a rim along it and its center line dashed, which a
## slider runs in. The part a slider has filled is laid over it in foil, so the lane reads as
## painted gold as far as the knob.

## The dashes of the center line: how long, how far apart and how thick.
const DASH := 8.0
const GAP := 7.0
const THICK := 2.0

@export var road := Color(0.05, 0.05, 0.07)
@export var rim := Color(1.0, 1.0, 1.0, 0.14)
@export var dash := Color(1.0, 1.0, 1.0, 0.22)

var _strip: StyleBoxFlat


func _init() -> void:
	content_margin_top = 6.0
	content_margin_bottom = 6.0


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if _strip == null:
		_strip = StyleBoxFlat.new()
		_strip.anti_aliasing = true
	_strip.bg_color = road
	_strip.border_color = rim
	_strip.set_border_width_all(1)
	_strip.set_corner_radius_all(int(rect.size.y * 0.5))
	_strip.draw(to_canvas_item, rect)
	var middle := rect.position.y + rect.size.y * 0.5
	var x := rect.position.x + rect.size.y * 0.5
	while x < rect.end.x - rect.size.y * 0.5:
		var end := minf(x + DASH, rect.end.x - rect.size.y * 0.5)
		RenderingServer.canvas_item_add_line(
			to_canvas_item, Vector2(x, middle), Vector2(end, middle), dash, THICK, true
		)
		x += DASH + GAP
