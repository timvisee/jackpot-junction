class_name FitScroll
extends ScrollContainer
## The part of a pane that scrolls when the pane would not fit on the screen, GAME.md 8.5: as tall
## as what is in it while there is room for that, and no taller than the screen leaves once
## everything else in the pane has its room, the header over it and the buttons under it, which
## stay where they can be seen and pressed. A big UI scale on a short screen, a phone's say, is
## what runs out of room. It follows the cursor down what it holds, and a finger drags it.

## How much of the screen is kept clear above and below the pane, and how short it is ever made.
const EDGE := 12.0
const SHORTEST := 120.0

## The pane it is in, whose other parts it leaves room for; its parent when not given.
var pane: Control


## A scroll holding [param content], in [param in_pane].
static func around(content: Control, in_pane: Control = null) -> FitScroll:
	var scroll := FitScroll.new()
	scroll.pane = in_pane
	scroll.add_child(content)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return scroll


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	follow_focus = true
	get_viewport().size_changed.connect(fit)
	for child: Node in get_children():
		if child is Control:
			(child as Control).minimum_size_changed.connect(fit)
	fit.call_deferred()


## Sizes it again for what it holds and the room there is on the screen.
func fit() -> void:
	if not is_inside_tree() or get_child_count() == 0:
		return
	var content := get_child(0) as Control
	if content == null:
		return
	var want := content.get_combined_minimum_size().y
	var holder := pane if pane != null else get_parent_control()
	var around := 0.0
	if holder != null:
		around = maxf(holder.get_combined_minimum_size().y - custom_minimum_size.y, 0.0)
	var room := get_viewport_rect().size.y - around - EDGE * 2.0
	var tall := minf(want, maxf(room, SHORTEST))
	if not is_equal_approx(tall, custom_minimum_size.y):
		custom_minimum_size.y = tall
