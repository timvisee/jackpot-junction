class_name FocusMark
extends RefCounted
## The cursor's mark on the things on the title that are not the House's buttons but are reached
## from them, the license peeking in from the right and Kit's folder from the left, STORY.md 7.2:
## the buttons' own gold edge round it, a little way out, and their lane chevron, two of it,
## outside on the side the cursor came from and pointing in. Drawn by whatever carries it, in its
## own space, so it tilts and slides with it.

const INK := HouseTheme.FOIL
## How thick the edge is, how far out from the thing it runs, and the chevron's size, gap and
## stroke, all on screen whatever the thing is scaled by.
const WIDTH := 3.0
const OUT := 7.0
const CHEVRON_HALF := 9.0
const CHEVRON_GAP := 10.0
const CHEVRON_WIDTH := 3.0
const CHEVRON_OUT := 14.0
## How much wider either side a casing is than what it cases, see [method draw_on].
const CASED := 2.0


## The mark round [param rect] of [param item], its corners rounded by [param radius], the chevrons
## outside it on [param side] (SIDE_LEFT or SIDE_RIGHT) pointing in; [param scale] is what the item
## is drawn at, so the lines come out the same on screen. With a [param casing] of some color, the
## edge and the chevrons are cased in it, [constant CASED] wider either side, so the gold shows on
## gold or on paper as well as on the dark.
static func draw_on(
	item: CanvasItem,
	rect: Rect2,
	radius: float,
	side: int,
	scale := 1.0,
	casing := Color.TRANSPARENT
) -> void:
	var by := 1.0 / maxf(scale, 0.01)
	var cased := casing.a > 0.0
	for under: bool in [true, false] if cased else [false]:
		var more := CASED if under else 0.0
		var ring := StyleBoxFlat.new()
		ring.draw_center = false
		ring.set_border_width_all(maxi(roundi((WIDTH + more * 2.0) * by), 1))
		ring.border_color = casing if under else INK
		ring.set_corner_radius_all(roundi(radius + (OUT + more) * by))
		ring.anti_aliasing = true
		item.draw_style_box(ring, rect.grow((OUT + more) * by))
	var way := 1.0 if side == SIDE_LEFT else -1.0
	var edge := rect.position.x if side == SIDE_LEFT else rect.end.x
	var middle := rect.get_center().y
	for i: int in 2:
		var tip := edge - way * (CHEVRON_OUT + OUT + float(1 - i) * CHEVRON_GAP) * by
		var back := tip - way * CHEVRON_HALF * 0.85 * by
		var points := PackedVector2Array(
			[
				Vector2(back, middle - CHEVRON_HALF * by),
				Vector2(tip, middle),
				Vector2(back, middle + CHEVRON_HALF * by),
			]
		)
		var ink := Color(INK, 0.5 if i == 0 else 1.0)
		if cased:
			item.draw_polyline(points, casing, (CHEVRON_WIDTH + CASED * 2.0) * by, true)
		item.draw_polyline(points, ink, CHEVRON_WIDTH * by, true)


## The mark's edge as a ring of [param radius] round [param middle] on [param item], for something
## round, cased in [param casing] as [method draw_on] cases it, without the chevrons.
static func draw_ring(item: CanvasItem, middle: Vector2, radius: float, casing: Color) -> void:
	item.draw_arc(middle, radius, 0.0, TAU, 72, casing, WIDTH + CASED * 2.0, true)
	item.draw_arc(middle, radius, 0.0, TAU, 72, INK, WIDTH, true)
