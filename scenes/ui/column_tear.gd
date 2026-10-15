class_name ColumnTear
extends Control
## The perforation between the match settings' two columns, GAME.md 9.6: a line of holes down the
## middle, where a ticket is torn from its stub, or across between them where a narrow screen
## stacks them. The same holes a pane's perforation has, see [method TicketStyle.hole_mesh], in one
## draw rather than one a hole, and a small bite at either end where it meets the rest.

## How much room it takes beside the columns, or between them stacked.
const ROOM := 28.0
## How far in from either end the holes stop, and how big the bite there is.
const END := 4.0
const BITE := 3.5

## Whether it runs across between columns stacked one over the other, rather than down between
## them side by side.
var across := false:
	set(value):
		if across == value:
			return
		across = value
		_fit()

var _mesh := {}
var _length := -1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	_fit()


func _fit() -> void:
	custom_minimum_size = Vector2(0.0, ROOM) if across else Vector2(ROOM, 0.0)
	_length = -1.0
	queue_redraw()


func _draw() -> void:
	var length := size.x if across else size.y
	if length < END * 4.0:
		return
	if length != _length:
		_length = length
		var holes := PackedVector2Array()
		var along := END + BITE * 2.0
		var middle := (size.y if across else size.x) * 0.5
		while along <= length - END - BITE * 2.0:
			holes.append(Vector2(along, middle) if across else Vector2(middle, along))
			along += TicketStyle.HOLE_GAP
		_mesh = TicketStyle.hole_mesh(holes)
	if _mesh.is_empty() or _mesh["indices"].is_empty():
		return
	RenderingServer.canvas_item_add_triangle_array(
		get_canvas_item(), _mesh["indices"], _mesh["points"], _mesh["inks"]
	)
	# The bites: a half round notch at either end, the pane's stock showing through.
	var ink := Color(TicketStyle.HOLE_INK, 0.9)
	for at: float in [END, length - END]:
		var point := Vector2(at, size.y * 0.5) if across else Vector2(size.x * 0.5, at)
		draw_circle(point, BITE, ink, true, -1.0, true)
