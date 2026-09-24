class_name TouchControls
extends Control
## The controls on a touch screen, GAME.md 4.2, drawn over the room for the player at this screen.
##
## Answered here finger by finger, from the touches themselves rather than from the mouse the
## engine makes out of the first of them: a player steering with one thumb and pressing with the
## other is two fingers at once, and a mouse is only ever one of them. A finger belongs to what it
## went down on until it comes up.

## The round buttons: a dark disc with a light rim, lit up while a finger is on it.
const FILL := Color(0.05, 0.05, 0.07, 0.45)
const FILL_DOWN := Color(1.0, 1.0, 1.0, 0.3)
const RIM := Color(1.0, 1.0, 1.0, 0.55)
const INK := Color(1.0, 1.0, 1.0, 0.92)
const RIM_WIDTH := 3.0
## A finger a little off the edge of a button is still on it: a thumb is not a point.
const REACH := 1.15
## The menu button in the top right corner, which opens the room's menu: the way back to the title
## and out of the game for a player with no Escape key, GAME.md 3.8.
const MENU := &"menu"
const MENU_RADIUS := 34.0
const MENU_INSET := Vector2(64.0, 62.0)


## One round button.
class Pad:
	var id: StringName
	var center := Vector2.ZERO
	var radius := 0.0
	## How many fingers are on it.
	var held := 0

	func _init(pad_id: StringName, pad_radius: float) -> void:
		id = pad_id
		radius = pad_radius

	func reaches(point: Vector2) -> bool:
		return point.distance_to(center) <= radius * REACH


var _pads: Array[Pad] = []
## Which pads each finger is on, by the finger's index.
var _fingers: Dictionary[int, Array] = {}


## Hangs the controls over [param hud].
static func attach(hud: CanvasLayer) -> TouchControls:
	var controls := TouchControls.new()
	controls.name = "TouchControls"
	hud.add_child(controls)
	return controls


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pads.append(Pad.new(MENU, MENU_RADIUS))
	resized.connect(_layout)
	_layout()


## The pad called [param id], for asking where it is and whether it is held.
func pad(id: StringName) -> Pad:
	for each: Pad in _pads:
		if each.id == id:
			return each
	return null


func _layout() -> void:
	pad(MENU).center = Vector2(size.x - MENU_INSET.x, MENU_INSET.y)
	queue_redraw()


func _process(_delta: float) -> void:
	# The room's menu takes the screen while it is up, and a finger that was down when it opened
	# has let go of everything as far as the room is concerned.
	if PauseMenu.is_open_in(get_tree()) and not _fingers.is_empty():
		_let_go()


func _input(event: InputEvent) -> void:
	if PauseMenu.is_open_in(get_tree()):
		return
	var touch := event as InputEventScreenTouch
	if touch != null:
		var at := _local(touch.position)
		if touch.pressed:
			_finger_down(touch.index, at)
		else:
			_finger_up(touch.index, at)
		return


func _local(point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * point


func _finger_down(finger: int, at: Vector2) -> void:
	var on: Array[StringName] = []
	for each: Pad in _pads:
		if each.reaches(at):
			on.append(each.id)
			each.held += 1
	if on.is_empty():
		return
	_fingers[finger] = on
	get_viewport().set_input_as_handled()
	queue_redraw()


func _finger_up(finger: int, at: Vector2) -> void:
	if not _fingers.has(finger):
		return
	var on: Array = _fingers[finger]
	_fingers.erase(finger)
	for id: StringName in on:
		var each := pad(id)
		each.held = maxi(each.held - 1, 0)
		# A button that does something once does it as the finger comes up, and only if it
		# comes up still on it: sliding off is how a thumb changes its mind.
		if id == MENU and each.reaches(at):
			PauseMenu.open_in(get_tree())
	get_viewport().set_input_as_handled()
	queue_redraw()


## Every finger off everything.
func _let_go() -> void:
	_fingers.clear()
	for each: Pad in _pads:
		each.held = 0
	queue_redraw()


func _draw() -> void:
	for each: Pad in _pads:
		_draw_disc(each)
	var menu := pad(MENU)
	# Three bars, the menu everybody already knows.
	var half := menu.radius * 0.42
	for row: int in 3:
		var y := menu.center.y + (float(row) - 1.0) * menu.radius * 0.3
		draw_line(Vector2(menu.center.x - half, y), Vector2(menu.center.x + half, y), INK, 4.0)


func _draw_disc(each: Pad) -> void:
	draw_circle(each.center, each.radius, FILL_DOWN if each.held > 0 else FILL)
	draw_arc(each.center, each.radius, 0.0, TAU, 48, RIM, RIM_WIDTH, true)
