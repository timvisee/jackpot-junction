class_name TouchScroll
extends Node
## A finger on a touch screen working a list of things that take the cursor, a [ScrollContainer] of
## them, GAME.md 4.2: dragged, it scrolls the list, a swipe let go carrying it on a little, slowing;
## and only a tap, a finger let go about where it was put down, picks the thing under it, giving it
## the cursor as a click would. Heard before the list is: without it the first touch of a swipe gave
## the card under it the cursor, which the list then scrolled to keep in sight, and the mouse a
## phone makes of a finger gave every card it passed over the cursor too, so that mouse is left
## alone over the list. Nothing at all off a touch screen, where the mouse and the keys work the
## list as ever.

## How far a finger may move, in the interface's units, and still be a tap.
const SLOP := 12.0
## How fast a swipe let go slows, each second, and the slowest it goes on at, in pixels a second.
const FLING_SLOWS := 5.0
const FLING_LEAST := 40.0

var scroll: ScrollContainer

## The finger on the list, or -1; where it was put down; and whether it has moved far enough to be
## a drag rather than a tap.
var _finger := -1
var _from := Vector2.ZERO
var _dragged := false
## How fast the list goes on once let go, in pixels a second, and the part of a pixel it has gone
## on and not yet moved.
var _fling := 0.0
var _fling_over := 0.0


## Works [param list] by finger.
static func attach(list: ScrollContainer) -> TouchScroll:
	var made := TouchScroll.new()
	made.name = "TouchScroll"
	made.scroll = list
	list.add_child(made)
	return made


func _input(event: InputEvent) -> void:
	if not TouchInput.enabled or scroll == null or not scroll.is_visible_in_tree():
		return
	var mouse := event as InputEventMouse
	if mouse != null:
		# The phone's mouse made of the finger, over the list: the finger itself is heard.
		if (
			mouse.device == InputEvent.DEVICE_ID_EMULATION
			and (_finger >= 0 or _over(mouse.position))
		):
			get_viewport().set_input_as_handled()
		return
	var touch := event as InputEventScreenTouch
	if touch != null:
		if touch.pressed and _finger < 0 and _over(touch.position):
			_finger = touch.index
			_from = touch.position
			_dragged = false
			_fling = 0.0
			get_viewport().set_input_as_handled()
		elif not touch.pressed and touch.index == _finger:
			_finger = -1
			get_viewport().set_input_as_handled()
			if not _dragged:
				_tap(touch.position)
		return
	var drag := event as InputEventScreenDrag
	if drag == null or drag.index != _finger:
		return
	get_viewport().set_input_as_handled()
	var tall := _scale()
	if not _dragged and drag.position.distance_to(_from) > SLOP * tall:
		_dragged = true
	if _dragged:
		scroll.scroll_vertical -= roundi(drag.relative.y / tall)
		_fling = -drag.velocity.y / tall


## The list going on after a swipe, slowing, until it is slow enough to stop or a finger has it.
func _process(delta: float) -> void:
	if _finger >= 0 or absf(_fling) < FLING_LEAST:
		_fling = 0.0
		_fling_over = 0.0
		return
	_fling_over += _fling * delta
	var step := roundi(_fling_over)
	_fling_over -= step
	var was := scroll.scroll_vertical
	scroll.scroll_vertical += step
	if step != 0 and scroll.scroll_vertical == was:
		_fling = 0.0
	_fling *= exp(-FLING_SLOWS * delta)


## The thing in the list under [param at], a point on the screen, given the cursor: the deepest one
## that can take it.
func _tap(at: Vector2) -> void:
	var picked: Control = null
	for each: Node in scroll.find_children("*", "Control", true, false):
		var control := each as Control
		if control.focus_mode == Control.FOCUS_NONE or not control.is_visible_in_tree():
			continue
		var local := control.get_global_transform_with_canvas().affine_inverse() * at
		if Rect2(Vector2.ZERO, control.size).has_point(local):
			picked = control
	if picked != null:
		picked.grab_focus()


## Whether [param at], a point on the screen, is on the list.
func _over(at: Vector2) -> bool:
	var local := scroll.get_global_transform_with_canvas().affine_inverse() * at
	return Rect2(Vector2.ZERO, scroll.size).has_point(local)


## How many of the screen's pixels a unit of the list is drawn over.
func _scale() -> float:
	return maxf(scroll.get_global_transform_with_canvas().get_scale().y, 0.001)
