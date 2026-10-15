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

var _clock := 0.0


## A glint on [param button].
static func on(button: Control) -> Glint:
	var glint := Glint.new()
	glint.name = "Glint"
	button.add_child(glint)
	return glint


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
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
	var clear := Color(SHINE, 0.0)
	var half := WIDTH * 0.5
	for side: float in [0.0, half]:
		var foot := at + side
		var points := PackedVector2Array(
			[
				Vector2(foot + SLANT, 0.0),
				Vector2(foot + SLANT + half, 0.0),
				Vector2(foot + half, size.y),
				Vector2(foot, size.y),
			]
		)
		var inner := SHINE if side == 0.0 else clear
		var outer := clear if side == 0.0 else SHINE
		draw_polygon(points, PackedColorArray([outer, inner, inner, outer]))
