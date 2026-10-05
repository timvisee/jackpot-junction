class_name TabStyle
extends StyleBox
## An index tab, GAME.md 8.1a: a tab with sloped sides standing on the pane under it. The page
## showing is cut from the pane's own stock, so the two read as one piece, with a strip of foil
## along its top; the others stand a little lower in a darker stock.

## How far in the sloped sides lean over the tab's height, and how thick the foil along the top is.
const SLOPE := 9.0
const TOP := 3.0

@export var fill := HouseTheme.STOCK_RAISED
## The foil along the top, clear on a tab that is not showing.
@export var top := Color(0.0, 0.0, 0.0, 0.0)
## The faint line along the sides and the top.
@export var edge := Color(1.0, 1.0, 1.0, 0.08)
## The gold round a tab with the cursor on it.
@export var border := Color(0.0, 0.0, 0.0, 0.0)
## How much lower than the page showing the tab stands.
@export var lift := 0.0


static func cut(stock: Color, across: float, down: float, stands: float) -> TabStyle:
	var style := TabStyle.new()
	style.fill = stock
	style.lift = stands
	style.content_margin_left = across
	style.content_margin_right = across
	style.content_margin_top = down + stands
	style.content_margin_bottom = down
	return style


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var y := rect.position.y + lift
	var slope := minf(SLOPE, rect.size.x * 0.25)
	var shape := PackedVector2Array(
		[
			Vector2(rect.position.x, rect.end.y),
			Vector2(rect.position.x + slope, y),
			Vector2(rect.end.x - slope, y),
			Vector2(rect.end.x, rect.end.y),
		]
	)
	if fill.a > 0.0:
		RenderingServer.canvas_item_add_polygon(to_canvas_item, shape, [fill])
		RenderingServer.canvas_item_add_polyline(to_canvas_item, shape, [fill], 1.0, true)
	if edge.a > 0.0:
		RenderingServer.canvas_item_add_polyline(to_canvas_item, shape, [edge], 1.0, true)
	if top.a > 0.0:
		var along := y + TOP * 0.5
		RenderingServer.canvas_item_add_line(
			to_canvas_item,
			Vector2(rect.position.x + slope + 1.0, along),
			Vector2(rect.end.x - slope - 1.0, along),
			top,
			TOP,
			true
		)
	if border.a > 0.0:
		RenderingServer.canvas_item_add_polyline(to_canvas_item, shape, [border], 2.0, true)
