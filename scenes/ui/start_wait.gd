class_name StartWait
extends PanelContainer
## What is on every screen while the lamps of a map are held for somebody still putting the room
## up, GAME.md 10.3: how many players are still coming, and a bar that fills as they arrive.
## The host's count, carried to its clients in the snapshot, so all of them say the same thing.

const WIDTH := 460.0

var match_node: Match

var _label: Label
var _bar: ProgressBar


## A pane over [param parent], shown while [param in_match] is waiting on somebody.
static func add_to(parent: Node, in_match: Match) -> StartWait:
	var pane := StartWait.new()
	pane.name = "StartWait"
	pane.match_node = in_match
	parent.add_child(pane)
	return pane


func _ready() -> void:
	add_theme_stylebox_override("panel", MenuTheme.pane_style(Palette.NEON_CYAN))
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	custom_minimum_size = Vector2(WIDTH, 0.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Type.text(_label, Type.BODY, Color(0.94, 0.94, 0.97))
	column.add_child(_label)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(0.0, 10.0)
	_bar.max_value = 1.0
	_bar.show_percentage = false
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_theme_stylebox_override("background", _bar_style(Color(0.16, 0.16, 0.2)))
	_bar.add_theme_stylebox_override("fill", _bar_style(Palette.NEON_CYAN))
	column.add_child(_bar)


func _process(_delta: float) -> void:
	if match_node == null or match_node.state != Match.State.LOBBY:
		visible = false
		return
	var count := match_node.loading
	# Somebody else still choosing a joker to keep holds the lamps too, GAME.md 9.7. Somebody here
	# choosing has the pick on the screen instead, which says it better.
	var keeping := JokerKeep.pending(match_node)
	visible = (count.y > 0 or keeping) and not JokerKeep.choosing_here(match_node)
	if not visible:
		return
	_bar.visible = count.y > 0
	if count.y > 0:
		_label.text = "Waiting on %d out of %d players" % [count.y - count.x, count.y]
		_bar.value = float(count.x) / float(count.y)
	else:
		_label.text = "Waiting for everybody to keep a joker"


func _bar_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(5)
	return style
