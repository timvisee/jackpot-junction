class_name SettingsColumns
extends Container
## A page of settings in groups, each under a heading of its own, GAME.md 8.5: in two columns side
## by side where the page is wide enough for the widest of them twice over, the first [member split]
## groups down the left and the rest down the right, and in one column, one group under the next,
## where it is not, as on a handheld under a big UI scale. The groups are laid where they go rather
## than moved from one box to another, so the one with the cursor keeps it as the page goes from one
## column to two.

## The room a heading keeps between its words and the dotted rule after them.
const HEADING_ROOM := 18

## How many of the groups stand in the left column.
var split := 0
## The room between the two columns, and between one group and the next under it.
var gap := Vector2(72.0, 24.0)

## What takes the cursor that was given a way across to the other column, and to which side.
var _linked: Dictionary[Control, Side] = {}


## A group of rows under [param title] in capitals with a dotted rule running on after it, as the
## house prints a heading, GAME.md 8.1a. Put the rows in it, then the group in the page.
static func group(title: String) -> VBoxContainer:
	var rows := VBoxContainer.new()
	rows.name = title
	rows.add_theme_constant_override("separation", 12)
	var head := HBoxContainer.new()
	head.name = "Heading"
	head.add_theme_constant_override("separation", HEADING_ROOM)
	var words := MenuTheme.title(title, Type.LARGE)
	words.name = "Title"
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	head.add_child(words)
	var rule := MenuTheme.dotted_rule()
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(rule)
	rows.add_child(head)
	return rows


## Whether the groups stand in two columns at [param width].
func two_columns(width: float) -> bool:
	var groups := _groups()
	if split <= 0 or split >= groups.size():
		return false
	return (width - gap.x) * 0.5 >= _widest(groups)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_lay_out()
	elif what == NOTIFICATION_RESIZED:
		update_minimum_size()


func _get_minimum_size() -> Vector2:
	var groups := _groups()
	var wide := _widest(groups)
	if not two_columns(size.x):
		return Vector2(wide, _height(groups))
	return Vector2(wide, maxf(_height(groups.slice(0, split)), _height(groups.slice(split))))


func _lay_out() -> void:
	var groups := _groups()
	# Once the rows in the groups are laid where they go in turn.
	_link.call_deferred()
	if not two_columns(size.x):
		_stack(groups, 0.0, size.x)
		return
	var column := (size.x - gap.x) * 0.5
	_stack(groups.slice(0, split), 0.0, column)
	_stack(groups.slice(split), column + gap.x, column)


## In two columns, right from a row on the left goes to the row level with it on the right, and
## left from one on the right back across: the engine's own search took a slider under a box for
## what lies to the box's right, the slider standing out further. Only from the last control of a
## row that way: the keyboard's socket of a binding has the pad's beside it, which right goes to
## first. A way across somebody else has given a row is kept, as Reset beside the aim guide's color
## has; in one column there is none.
func _link() -> void:
	for each: Control in _linked:
		if is_instance_valid(each):
			each.set_focus_neighbor(_linked[each], NodePath())
	_linked.clear()
	if not is_inside_tree() or not two_columns(size.x):
		return
	var groups := _groups()
	var left := _takers(groups.slice(0, split))
	var right := _takers(groups.slice(split))
	_across(left, right, SIDE_RIGHT)
	_across(right, left, SIDE_LEFT)


## Each of [param from] with none of its own column beside it to its [param side] given the way to
## the one of [param to] most nearly level with it there, and of those level the nearest across.
func _across(from: Array[Control], to: Array[Control], side: Side) -> void:
	if to.is_empty():
		return
	for each: Control in from:
		if not each.get_focus_neighbor(side).is_empty() or _beside(each, from, side):
			continue
		var at := each.get_global_rect().get_center()
		var nearest := to[0]
		for other: Control in to:
			if _off(other, at) < _off(nearest, at):
				nearest = other
		each.set_focus_neighbor(side, each.get_path_to(nearest))
		_linked[each] = side


## How far [param control] is from [param at]: down first, and across only between those level.
static func _off(control: Control, at: Vector2) -> float:
	var there := control.get_global_rect().get_center()
	return absf(there.y - at.y) + absf(there.x - at.x) * 0.001


## Whether one of [param others] stands level with [param control] to its [param side].
static func _beside(control: Control, others: Array[Control], side: Side) -> bool:
	var rect := control.get_global_rect()
	for other: Control in others:
		var there := other.get_global_rect()
		var level := there.position.y < rect.end.y and there.end.y > rect.position.y
		var way := there.get_center().x - rect.get_center().x
		if other != control and level and (way > 0.0 if side == SIDE_RIGHT else way < 0.0):
			return true
	return false


## What takes the cursor in [param groups].
static func _takers(groups: Array[Control]) -> Array[Control]:
	var takers: Array[Control] = []
	for each: Control in groups:
		for node: Node in each.find_children("*", "Control", true, false):
			var control := node as Control
			if control.focus_mode == Control.FOCUS_ALL and control.is_visible_in_tree():
				takers.append(control)
	return takers


## [param groups] one under another from the top, [param across] in and [param wide] wide.
func _stack(groups: Array[Control], across: float, wide: float) -> void:
	var down := 0.0
	for each: Control in groups:
		var tall := each.get_combined_minimum_size().y
		fit_child_in_rect(each, Rect2(across, down, wide, tall))
		down += tall + gap.y


## How tall [param groups] stand one under another.
func _height(groups: Array[Control]) -> float:
	var tall := 0.0
	for each: Control in groups:
		tall += each.get_combined_minimum_size().y
	return tall + gap.y * maxf(groups.size() - 1, 0.0)


static func _widest(groups: Array[Control]) -> float:
	var wide := 0.0
	for each: Control in groups:
		wide = maxf(wide, each.get_combined_minimum_size().x)
	return wide


func _groups() -> Array[Control]:
	var groups: Array[Control] = []
	for child: Node in get_children():
		if child is Control and (child as Control).visible:
			groups.append(child)
	return groups
