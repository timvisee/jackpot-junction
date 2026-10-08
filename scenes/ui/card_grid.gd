class_name CardGrid
extends Container
## The catalog's cards in rows, GAME.md 8.8, every card on every page the one size: as many to a row
## as fit the width the grid has, the room left over shared out between them so the rows reach from
## one side to the other, a short last row starting at the left. As tall as its rows make it, for
## the scroll it is put in to scroll when they are more than the screen has room for.

## How big a card is drawn, a share of its own size, and the least air between two cells, across
## and down, and round the outside, each cell having the room for the cursor's frame round its card
## already.
const SCALE := 0.85
const GAP := 4.0
const ROOM := 8.0

## A cell's size: a card at [constant SCALE] and the frame's room round it.
var cell := CatalogCell.shape(SCALE).floor()
## How many to a row, and the air across between two of them, as last laid out.
var columns := 1
var gap_across := GAP


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_sort()
	elif what == NOTIFICATION_RESIZED:
		update_minimum_size()


## As wide as one card, and as tall as the rows the width it has makes.
func _get_minimum_size() -> Vector2:
	var rows := rows_for(size.x)
	return Vector2(
		cell.x + ROOM * 2.0, float(rows) * cell.y + float(maxi(rows - 1, 0)) * GAP + ROOM * 2.0
	)


## The cells, in the order they are laid out.
func cells() -> Array[Control]:
	var found: Array[Control] = []
	for child: Node in get_children():
		var control := child as Control
		if control != null and control.visible:
			found.append(control)
	return found


## How many cells fit in a row [param wide] across.
func columns_for(wide: float) -> int:
	return maxi(floori((wide - ROOM * 2.0 + GAP) / (cell.x + GAP)), 1)


## How many rows the cells take [param wide] across.
func rows_for(wide: float) -> int:
	return ceili(float(cells().size()) / float(columns_for(wide)))


func _sort() -> void:
	var placed := cells()
	columns = columns_for(size.x)
	var spare := size.x - ROOM * 2.0 - cell.x * float(columns)
	gap_across = spare / float(columns - 1) if columns > 1 else 0.0
	for i: int in placed.size():
		var at := Vector2(
			ROOM + float(i % columns) * (cell.x + gap_across),
			ROOM + float(i / columns) * (cell.y + GAP)
		)
		fit_child_in_rect(placed[i], Rect2(at.floor(), cell))
