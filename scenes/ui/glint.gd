class_name Glint
extends Control
## A band of light sweeping across the button it is on now and then, the way light runs across
## foil turned in the hand, GAME.md 8.1a, to draw the eye to the one thing on a menu worth trying:
## Play the full game on the pause menu of the demo for a booth, 9.8. Slanted, bright in its middle
## and clear at its edges, and kept inside the button.

## How long a sweep takes, and how long from the start of one to the start of the next, in seconds.
const SWEEP := 0.9
const EVERY := 2.8
## How wide the band is, how far its top leans ahead of its foot, and how bright it is in its
## middle.
const WIDTH := 52.0
const SLANT := 22.0
const SHINE := Color(1.0, 1.0, 1.0, 0.6)
## How deep the notch in a button's corners is, for the sweep kept to the ticket's shape rather than
## its box, when the button cannot be asked, see [method _button_shape] and [constant
## MenuTheme.BUTTON_NOTCH].
const NOTCH := 9.0

var _clock := 0.0


## A glint on [param button].
static func on(button: Control) -> Glint:
	var glint := Glint.new()
	glint.name = "Glint"
	button.add_child(glint)
	return glint


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	var was := _clock
	_clock = fmod(_clock + delta, EVERY)
	if _clock <= SWEEP or was <= SWEEP:
		queue_redraw()


func _draw() -> void:
	if _clock > SWEEP:
		return
	var at := lerpf(-WIDTH - SLANT, size.x, _clock / SWEEP)
	var half := WIDTH * 0.5
	# Two trapezoids meeting at the band's bright middle, each clipped to the ticket's notched shape
	# so the sweep does not show in the corners the notch cuts away, and shaded from the middle out by
	# where each corner falls across it, see [constant SHINE].
	var shape := _button_shape()
	for side: float in [0.0, half]:
		var foot := at + side
		var trapezoid := PackedVector2Array(
			[
				Vector2(foot + SLANT, 0.0),
				Vector2(foot + SLANT + half, 0.0),
				Vector2(foot + half, size.y),
				Vector2(foot, size.y),
			]
		)
		for piece: PackedVector2Array in Geometry2D.intersect_polygons(trapezoid, shape):
			var colors := PackedColorArray()
			for point: Vector2 in piece:
				var middle := at + half + SLANT * (1.0 - point.y / maxf(size.y, 1.0))
				var bright := clampf(1.0 - absf(point.x - middle) / half, 0.0, 1.0)
				colors.append(Color(SHINE.r, SHINE.g, SHINE.b, SHINE.a * bright))
			draw_polygon(piece, colors)


## The shape of the button under the glint: the house ticket's notched outline, by the button's own
## notch where it has one, so the sweep is kept to the ticket rather than its square box.
func _button_shape() -> PackedVector2Array:
	var notch := NOTCH
	var button := get_parent() as Control
	if button != null:
		var box := button.get_theme_stylebox(&"normal") as TicketStyle
		if box != null:
			notch = box.notch
	return TicketStyle.outline(size, notch)
