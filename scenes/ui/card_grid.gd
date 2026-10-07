class_name CardGrid
extends Container
## The catalog's cards in rows, GAME.md 8.8: as many to a row as makes them biggest in the room the
## grid has, and never much bigger than their own size, so all of a page's cards are on one screen,
## whatever its shape, rather than a page to scroll. The rows stand at the top of the room and are
## centered across it; a short last row starts at the left, as a hand dealt out would.

## A cell's shape at its own size, see [method CatalogCell.shape], the air between two, and the
## most a cell grows past its own size, for a page with only a few.
var cell := CatalogCell.shape()
var gap := 14.0
var most := 1.0
## How many to a row, and how big a cell is, as last laid out.
var columns := 1
var cell_size := Vector2.ZERO


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_sort()


func _get_minimum_size() -> Vector2:
	return Vector2.ZERO


## The cells, in the order they are laid out.
func cells() -> Array[Control]:
	var found: Array[Control] = []
	for child: Node in get_children():
		var control := child as Control
		if control != null and control.visible:
			found.append(control)
	return found


## How big a cell can be with [param count] of them in [param room], [param across] to a row.
func fit(count: int, room: Vector2, across: int) -> float:
	var rows := ceili(float(count) / float(across))
	var wide := (room.x - gap * float(across - 1)) / float(across) / cell.x
	var tall := (room.y - gap * float(rows - 1)) / float(rows) / cell.y
	return clampf(minf(wide, tall), 0.0, most)


func _sort() -> void:
	var placed := cells()
	if placed.is_empty():
		return
	var best := 0.0
	columns = 1
	for across: int in range(1, placed.size() + 1):
		var scale_of := fit(placed.size(), size, across)
		if scale_of > best + 0.001:
			best = scale_of
			columns = across
	cell_size = (cell * best).floor()
	var wide := cell_size.x * float(columns) + gap * float(columns - 1)
	var left := floorf((size.x - wide) * 0.5)
	for i: int in placed.size():
		var at := Vector2(
			left + float(i % columns) * (cell_size.x + gap),
			float(i / columns) * (cell_size.y + gap)
		)
		fit_child_in_rect(placed[i], Rect2(at, cell_size))
