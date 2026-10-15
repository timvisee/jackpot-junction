class_name CountdownFill
extends Control
## A wait running out on the button it ends in, GAME.md 9.3: a bar along the foot of the button,
## filling from the left as the wait goes, so the press about to happen by itself is seen where it
## will happen and is no surprise. On a button in foil it is drawn in ink, on any other in foil; a
## faint track runs the whole way under it. The arrow down of a watcher's slip wears one, and the
## ways on of the demo's, 9.8.

## How far in from the button's sides and foot the bar runs, and how thick it is.
const SIDE := 14.0
const FOOT := 7.0
const THICKNESS := 6.0
const TRACK := 0.28

## How much of the wait has gone, from 0 when it starts to 1 when it is over.
var value := 0.0:
	set(gone):
		value = clampf(gone, 0.0, 1.0)
		queue_redraw()


## A fill on [param button], hidden until there is a wait to show.
static func on(button: Button) -> CountdownFill:
	var fill := CountdownFill.new()
	fill.name = "CountdownFill"
	fill.visible = false
	button.add_child(fill)
	return fill


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Over onto [param button], from whichever it was on.
func move_onto(button: Button) -> void:
	if get_parent() == button:
		return
	if get_parent() != null:
		get_parent().remove_child(self)
	button.add_child(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()


func _draw() -> void:
	var button := get_parent() as Button
	var foil := button != null and button.theme_type_variation == HouseTheme.PRIMARY
	var ink := HouseTheme.INK if foil else HouseTheme.FOIL
	var across := maxf(size.x - SIDE * 2.0, 0.0)
	var bar := Rect2(SIDE, size.y - FOOT - THICKNESS, across, THICKNESS)
	draw_rect(bar, Color(ink, TRACK))
	if value > 0.0:
		draw_rect(Rect2(bar.position, Vector2(across * value, THICKNESS)), ink)
