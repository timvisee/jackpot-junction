class_name HudShadow
extends RefCounted
## The soft dark edge that lifts a piece of the HUD off the room, GAME.md 8.1a, the same one the
## corner blocks carry, see [member StripStyle.shadow]: a shape grown outward in a few faint steps
## that stack up darker toward it and fade out past its edge, a tight edge not a cast shadow. A
## handful of flat polygons and no blur pass of its own, so it is cheap; off on a phone all the
## same, GAME.md 8.5, and off with the room's shadows, see [member Settings.shadows], so turning
## those off to save the frames saves these too.

## How dark at the edge and how far it reaches out, matching the corner blocks, see [HudBlock]; and
## in how many steps it is grown, as [StripStyle] draws it.
const COLOR := Color(0.0, 0.0, 0.0, 0.24)
const REACH := 16.0
const STEPS := 6


## Whether the HUD casts its lifting shadows at all: not on a phone, and not with the room's shadows
## turned off.
static func on() -> bool:
	return not OS.has_feature("mobile") and Game.settings.shadows != Settings.SHADOWS_OFF


## A soft shadow behind [param shape], a polygon in [param canvas]'s own coordinates, reaching
## [param reach] out past its edge in [param color]; nothing while the HUD casts none, see
## [method on], so it is laid only where it will be seen.
static func cast(
	canvas: CanvasItem, shape: PackedVector2Array, color := COLOR, reach := REACH
) -> void:
	if not on() or color.a <= 0.0 or reach <= 0.0 or shape.size() < 3:
		return
	var per := Color(color.r, color.g, color.b, color.a / float(STEPS) * 1.8)
	for i: int in range(STEPS, 0, -1):
		var grow := reach * float(i) / float(STEPS)
		for step: PackedVector2Array in Geometry2D.offset_polygon(shape, grow):
			canvas.draw_colored_polygon(step, per)
