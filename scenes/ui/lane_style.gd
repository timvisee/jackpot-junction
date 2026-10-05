class_name LaneStyle
extends StyleBox
## A lane, GAME.md 8.1a: a strip of road with a rim along it and its center line dashed, which a
## slider runs in and a room's loading bar fills. The part a slider has filled is laid over it in
## foil; a bar's fill is the same lane with only its dashes, painted gold, and a chip at its head.

## The road, its rim, and the dashes of its center line: their ink, how long, how far apart and how
## thick. Clear road and rim leave the dashes alone, which is a lane's fill.
@export var road := Color(0.05, 0.05, 0.07)
@export var rim := Color(1.0, 1.0, 1.0, 0.14)
@export var dash := Color(1.0, 1.0, 1.0, 0.22)
@export var dash_long := 8.0
@export var dash_gap := 7.0
@export var dash_thick := 2.0
## A white line along either side of the road, as a road has, for a lane tall enough to carry them.
@export var edges := false
## A chip at the far end, the head of a fill, clear for none.
@export var head := Color(0.0, 0.0, 0.0, 0.0)

var _strip: StyleBoxFlat


func _init() -> void:
	content_margin_top = 6.0
	content_margin_bottom = 6.0


## The road a room's loading bar runs along, and the gold its center line is painted as it fills.
static func road_and_paint() -> Array[LaneStyle]:
	var lane := LaneStyle.new()
	lane.road = Color(0.12, 0.12, 0.14)
	lane.rim = Color(0.0, 0.0, 0.0, 0.0)
	lane.edges = true
	lane.dash = Color(1.0, 1.0, 1.0, 0.14)
	lane.dash_long = 22.0
	lane.dash_gap = 14.0
	lane.dash_thick = 4.0
	var paint := lane.duplicate() as LaneStyle
	paint.road = Color(0.0, 0.0, 0.0, 0.0)
	paint.edges = false
	paint.dash = HouseTheme.FOIL
	paint.head = HouseTheme.FOIL
	return [lane, paint]


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if road.a > 0.0 or rim.a > 0.0:
		if _strip == null:
			_strip = StyleBoxFlat.new()
			_strip.anti_aliasing = true
		_strip.bg_color = road
		_strip.border_color = rim
		_strip.set_border_width_all(1 if rim.a > 0.0 else 0)
		_strip.set_corner_radius_all(int(rect.size.y * 0.5) if not edges else 4)
		_strip.draw(to_canvas_item, rect)
	if edges:
		for y: float in [rect.position.y + 3.0, rect.end.y - 3.0]:
			RenderingServer.canvas_item_add_line(
				to_canvas_item,
				Vector2(rect.position.x + 6.0, y),
				Vector2(rect.end.x - 6.0, y),
				Color(1.0, 1.0, 1.0, 0.3),
				1.5,
				true
			)
	var middle := rect.position.y + rect.size.y * 0.5
	var start := rect.position.x + rect.size.y * 0.5
	var x := start
	while x < rect.end.x - rect.size.y * 0.5:
		var end := minf(x + dash_long, rect.end.x - rect.size.y * 0.5)
		RenderingServer.canvas_item_add_line(
			to_canvas_item, Vector2(x, middle), Vector2(end, middle), dash, dash_thick, true
		)
		x += dash_long + dash_gap
	if head.a > 0.0 and rect.size.x > rect.size.y:
		var at := Vector2(rect.end.x - rect.size.y * 0.5, middle)
		var radius := rect.size.y * 0.42
		RenderingServer.canvas_item_add_circle(to_canvas_item, at, radius, head, true)
		RenderingServer.canvas_item_add_circle(
			to_canvas_item, at, radius * 0.55, head.darkened(0.25), true
		)
