class_name TouchSettings
extends Control
## The match settings' button of a touch screen in the lobby, GAME.md 9.6 and 4.2: a small round
## one beside the menu button, with three sliders on it, at the machine that chooses the match,
## which a keyboard opens with E and a pad with View. A tap on it opens them. The emote button, when
## there is one, stands on past it, see [TouchEmotes].

## How big the button is, and how far it keeps from the menu button, as the emote button's.
const RADIUS := TouchEmotes.RADIUS
const GAP := TouchEmotes.GAP

## What a tap on it does: opens the match settings.
var opens: Callable


static func attach(hud: CanvasLayer, then: Callable) -> TouchSettings:
	var button := TouchSettings.new()
	button.name = "TouchSettings"
	button.opens = then
	hud.add_child(button)
	return button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


## The middle of the button, to the left of the menu button and level with it.
func button_center() -> Vector2:
	var menu := Vector2(size.x - TouchControls.MENU_INSET.x, TouchControls.MENU_INSET.y)
	return menu - Vector2(TouchControls.MENU_RADIUS + GAP + RADIUS, 0.0)


## How much further along the emote button stands for this one, while it is up.
static func room_in(hud: Node) -> float:
	var button := hud.get_node_or_null("TouchSettings") as TouchSettings if hud != null else null
	return RADIUS * 2.0 + GAP if button != null and button.visible else 0.0


func _process(_delta: float) -> void:
	var shown := not PauseMenu.is_open_in(get_tree()) and not TouchInput.kept_from(self)
	shown = shown and get_viewport().gui_get_focus_owner() == null
	if shown != visible:
		visible = shown


# Heard before the driving controls, which are under it, so a tap that lands on it is its alone.
func _input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if not visible or touch == null or not touch.pressed:
		return
	var at := get_global_transform_with_canvas().affine_inverse() * touch.position
	if at.distance_to(button_center()) > RADIUS * TouchControls.REACH:
		return
	get_viewport().set_input_as_handled()
	if opens.is_valid():
		opens.call()


func _draw() -> void:
	var middle := button_center()
	draw_circle(middle, RADIUS, TouchControls.FILL)
	draw_arc(middle, RADIUS, 0.0, TAU, 48, TouchInk.rim(), TouchControls.RIM_WIDTH, true)
	# Three sliders, each a line with its knob somewhere along it, in the menu button's ink.
	var box := Rect2(middle - Vector2.ONE * RADIUS, Vector2.ONE * RADIUS * 2.0)
	var ink := TouchControls.INK
	var knobs: Array[float] = [0.62, 0.36, 0.55]
	for i: int in knobs.size():
		var y := 0.34 + 0.16 * i
		IconShapes.line(self, box, 0.28, y, 0.72, y, ink)
		IconShapes.disc(self, box, knobs[i], y, 0.07, ink)
