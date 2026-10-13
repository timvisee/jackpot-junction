class_name FitScale
extends Container
## Holds a page in its middle at its own size, or shrunk all over, never grown, until it fits where
## it would not, GAME.md 8.5: for a page laid out at a size of its own, such as the driving
## school's, on a short screen at a big UI scale, where scrolling would leave part of it out of
## sight. Its children are laid out so, each on its own.

## How much room is kept round a page that has to shrink, so it does not run to the screen's edge,
## and the least it shrinks to.
const ROOM := 16.0
const LEAST := 0.4


## A page holder filling [param parent], for the page to be added to.
static func filling(parent: Control) -> FitScale:
	var fit := FitScale.new()
	fit.name = "Fit"
	fit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(fit)
	return fit


## How much [param need] is shrunk to fit in [param room], [constant ROOM] kept round it once it
## has to be: 1 where it fits as it is.
static func shrink(need: Vector2, room: Vector2) -> float:
	if need.x <= 0.0 or need.y <= 0.0 or (need.x <= room.x and need.y <= room.y):
		return 1.0
	var inside := (room - Vector2.ONE * ROOM * 2.0).max(Vector2.ONE)
	return clampf(minf(inside.x / need.x, inside.y / need.y), LEAST, 1.0)


func _notification(what: int) -> void:
	if what != NOTIFICATION_SORT_CHILDREN:
		return
	for child: Node in get_children():
		var page := child as Control
		if page == null or not page.visible:
			continue
		var need := page.get_combined_minimum_size()
		var fit := shrink(need, size)
		# Laid out at its own size first, which also puts its scale back to whole, and then shrunk
		# about its corner, set where the shrunk page sits in the middle.
		fit_child_in_rect(page, Rect2((size - need * fit) * 0.5, need))
		page.pivot_offset = Vector2.ZERO
		page.scale = Vector2.ONE * fit


func _get_minimum_size() -> Vector2:
	return Vector2.ZERO
