class_name ClosingRing
extends Control
## A ring that starts as wide as the screen and shrinks onto what the tutorial wants looked at,
## GAME.md 9.4a, which is what pulls the eye to it wherever it was looking: a piece of the HUD
## brought in, see [HudReveal], or a line written on the clipboard in mid-lesson, see
## [TutorialList]. Drawn about the middle of this control, which is as wide as the ring starts.

## How far out it starts, as a share of the screen's diagonal.
const FROM := 0.42

## How far along it is, 0 at the start out wide to 1 gone.
var progress := 0.0:
	set(value):
		progress = value
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Round [param target], a rect in the same space as this ring's parent, starting out as far as
## [param screen], the size of the screen, has it.
func close_on(target: Rect2, screen: Vector2) -> void:
	var reach := screen.length() * FROM
	position = target.get_center() - Vector2(reach, reach)
	size = Vector2(reach, reach) * 2.0


func _draw() -> void:
	var eased := progress * progress * (3.0 - 2.0 * progress)
	var radius := size.x * 0.5 * (1.0 - eased)
	if radius < 1.0:
		return
	var width := 3.0 + 5.0 * eased
	draw_arc(
		size * 0.5, radius, 0.0, TAU, 96, Color(Palette.NEON_CYAN, 0.3 + 0.6 * eased), width, true
	)
