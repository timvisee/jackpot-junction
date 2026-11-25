class_name StickScroll
extends Node
## A pad's right stick scrolls the pane the cursor is in, up and down, as the mouse wheel does,
## GAME.md 4.2: the settings' pages, the pause menu, the match settings, the catalog, the loyalty
## program's list, the server list and whatever else scrolls, faster the further it is pushed. With
## the cursor on what does not scroll, the tabs over a page say, it is the biggest pane that scrolls
## on the same screen, so a page with nothing on it to take the cursor, the About page or the
## catalog's hands, scrolls as well.
##
## Not where the right stick is something else's: while a view that takes it is up, see
## [method leave_to], the kart dialog turning the kart, the loyalty map moving, a card held up
## tilting; not a pane that scrolls with it by itself, in [constant OWN], the payout slip and the
## achievements; and not while a room goes on under the menus with a kart of this machine's driven
## in it, online before everybody has the menu open, where the stick aims and opens the emote
## wheel, 3.8. Nothing while no control has the cursor, so a match being driven never scrolls.

## A pane in this group scrolls with the right stick by itself.
const OWN := &"scrolls_with_stick"
## A stick pushed less than this is resting, and how far a pane goes a second with it pushed all
## the way, in the interface's units, eased in from resting as the payout slip has it.
const REST := 0.2
const RATE := 1100.0
## How long a look round the screen for a pane that found none holds, before the next, in
## milliseconds: a page shown under the same cursor, a tab changed, is found then.
const LOOK_AGAIN_MS := 250

## The views up that take the right stick themselves, see [method leave_to].
static var _views: Array[Node] = []

## The pane the cursor's stick scrolls, found again as the cursor moves, the cursor it was found
## for and when; and the part of a pixel it has gone and not yet moved.
var _pane: ScrollContainer
var _for: Control
var _found_at := 0
var _over := 0.0


## [param view] takes the right stick itself while it is up: nothing scrolls with it meanwhile.
static func leave_to(view: Node) -> void:
	_views.append(view)
	view.tree_exiting.connect(func() -> void: _views.erase(view), CONNECT_ONE_SHOT)


## Whether a view that takes the right stick itself is up, see [method leave_to].
static func _view_up() -> bool:
	for view: Node in _views:
		if is_instance_valid(view) and view.is_inside_tree():
			if not (view is CanvasItem) or (view as CanvasItem).is_visible_in_tree():
				return true
	return false


func _ready() -> void:
	# The pause menu stops the tree, and its pane scrolls all the same.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	scroll_with(pushed(), delta)


## How far any pad's right stick is pushed down, less for up: the one pushed furthest.
static func pushed() -> float:
	var push := 0.0
	for pad: int in DeviceInput.pads():
		var down := Input.get_joy_axis(pad, JOY_AXIS_RIGHT_Y)
		if absf(down) > absf(push):
			push = down
	return push


## The pane the cursor is in scrolled for [param delta] seconds by a right stick pushed [param push]
## of the way down, less for up, see [method pane].
func scroll_with(push: float, delta: float) -> void:
	var scroll := pane() if absf(push) > REST else null
	if scroll == null:
		_over = 0.0
		return
	var past := (absf(push) - REST) / (1.0 - REST)
	_over += signf(push) * past * past * RATE * delta
	var step := roundi(_over)
	_over -= step
	if step != 0:
		scroll.scroll_vertical += step


## The pane the right stick scrolls now, or null for none: the one the cursor is in, or with the
## cursor on what does not scroll, the biggest that does on its screen.
func pane() -> ScrollContainer:
	var focus := get_viewport().gui_get_focus_owner()
	if focus == null or not focus.is_visible_in_tree() or _view_up() or _driven():
		return null
	var gone := not is_instance_valid(_pane) or not _pane.is_visible_in_tree()
	if focus != _for or (gone and Time.get_ticks_msec() - _found_at >= LOOK_AGAIN_MS):
		_for = focus
		_found_at = Time.get_ticks_msec()
		_pane = around(focus)
	if not is_instance_valid(_pane) or not _pane.is_visible_in_tree():
		return null
	if _pane.is_in_group(OWN) or not scrolls(_pane):
		return null
	return _pane


## The pane [param focus] is in that scrolls, or else the biggest that scrolls on the screen it is
## on, its layer or the scene; null for none.
static func around(focus: Control) -> ScrollContainer:
	var node := focus.get_parent()
	while node != null:
		var scroll := node as ScrollContainer
		if scroll != null and (scroll.is_in_group(OWN) or scrolls(scroll)):
			return scroll
		if node is CanvasLayer or node == focus.get_tree().current_scene:
			break
		node = node.get_parent()
	if node == null:
		return null
	var biggest: ScrollContainer = null
	for found: Node in node.find_children("*", "ScrollContainer", true, false):
		var scroll := found as ScrollContainer
		if not scroll.is_visible_in_tree() or not scrolls(scroll):
			continue
		if biggest == null or _area(scroll) > _area(biggest):
			biggest = scroll
	return biggest


## Whether [param scroll] has more to show up or down than it shows.
static func scrolls(scroll: ScrollContainer) -> bool:
	if scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
		return false
	var bar := scroll.get_v_scroll_bar()
	return bar.max_value - bar.page > 0.5


static func _area(scroll: ScrollContainer) -> float:
	var shown := scroll.get_global_rect().size
	return shown.x * shown.y


## Whether a room goes on under the menus with a kart of this machine's driven in it, not held still
## by a menu as the lobby's are, GAME.md 9.6: its right stick aims and opens the emote wheel.
func _driven() -> bool:
	if get_tree().paused:
		return false
	for kart: Node in get_tree().get_nodes_in_group(&"karts"):
		var input: Object = kart.get(&"input")
		if input != null and input.has_method(&"held_device") and not kart.get(&"held"):
			return true
	return false
