class_name Engraving
extends RefCounted
## The fine lines under the house's print, GAME.md 8.1a: what a banknote or a license carries
## behind its words, felt before it is seen. Each pattern is a set of polylines in the pixels of
## whatever it is drawn on, made from a handful of numbers, so the same pattern serves a button
## and a whole screen and stays sharp at any scale of the UI. Nothing here is a picture: a
## pattern is worked out when its size is known and drawn as lines, the way every picture in the
## game is drawn, 8.3a.

## How strong the lines are, as the alpha of their ink: a whisper on stock, a little more on paper,
## which is lighter and takes a line more quietly.
const ON_STOCK := 0.06
const ON_PAPER := 0.07
## How wide a line is drawn, in pixels.
const WIDTH := 1.0


## Lines running across [param area], [param gap] apart, each a wave [param height] high and
## [param length] long, each a little further along its wave than the one above it, so that they
## drift together and apart down the area like the lines across a banknote.
static func waves(
	area: Rect2, gap: float, height: float, length: float, drift := 0.42, step := 8.0
) -> Array[PackedVector2Array]:
	var lines: Array[PackedVector2Array] = []
	if area.size.x <= 0.0 or gap <= 0.0:
		return lines
	var count := int(area.size.y / gap) + 1
	for i: int in count:
		var line := PackedVector2Array()
		var y := area.position.y + float(i) * gap
		var x := area.position.x
		while true:
			var along := (x - area.position.x) / length * TAU + float(i) * drift
			line.append(Vector2(x, y + height * sin(along)))
			if x >= area.end.x:
				break
			x = minf(x + step, area.end.x)
		lines.append(line)
	return lines


## Rings round [param center]: [param count] closed lines, each [param radius] out and swinging
## [param depth] either side of that [param lobes] times on the way round, each a little further
## round than the last, so they plait into the band a guilloché has.
static func rings(
	center: Vector2, radius: float, depth: float, lobes: int, count: int, steps := 360
) -> Array[PackedVector2Array]:
	var lines: Array[PackedVector2Array] = []
	for i: int in count:
		var phase := float(i) * TAU / float(count)
		var line := PackedVector2Array()
		for s: int in steps + 1:
			var turn := float(s) / float(steps) * TAU
			var out := radius + depth * sin(float(lobes) * turn + phase)
			line.append(center + Vector2(cos(turn), sin(turn)) * out)
		lines.append(line)
	return lines


## The rosette at the heart of a seal, [param size] out from [param center]: the line a pen
## draws on a wheel of [param inner] teeth rolling round inside a ring of [param outer], set
## [param pen] out from the wheel's middle, drawn [param copies] times, each turned a little.
static func rosette(
	center: Vector2, size: float, outer := 7, inner := 3, pen := 2.2, copies := 5, steps := 160
) -> Array[PackedVector2Array]:
	var lines: Array[PackedVector2Array] = []
	var common := _divisor(outer, inner)
	var turns := inner / common
	var lobes := outer / common
	var reach := float(outer - inner) + pen
	var ratio := float(outer - inner) / float(inner)
	for copy: int in copies:
		var turned := float(copy) * TAU / float(lobes) / float(copies)
		var line := PackedVector2Array()
		var points := steps * turns
		for s: int in points + 1:
			var t := float(s) / float(points) * TAU * float(turns)
			var at := Vector2(
				float(outer - inner) * cos(t) + pen * cos(ratio * t),
				float(outer - inner) * sin(t) - pen * sin(ratio * t)
			)
			line.append(center + at.rotated(turned) * size / reach)
		lines.append(line)
	return lines


## The license's long arcs, GAME.md 9.4a: [param count] of them between the angles [param from]
## and [param to], the first [param radius] round [param center] and each next one moved
## [param shift] x along and grown by its y.
static func arcs(
	center: Vector2, radius: float, count: int, shift: Vector2, from: float, to: float, steps := 48
) -> Array[PackedVector2Array]:
	var lines: Array[PackedVector2Array] = []
	for i: int in count:
		var middle := center + Vector2(shift.x * float(i), 0.0)
		var out := radius + shift.y * float(i)
		var line := PackedVector2Array()
		for s: int in steps + 1:
			var angle := lerpf(from, to, float(s) / float(steps))
			line.append(middle + Vector2(cos(angle), sin(angle)) * out)
		lines.append(line)
	return lines


## Only the parts of [param lines] inside [param outline], a closed shape such as a ticket's.
static func inside(
	lines: Array[PackedVector2Array], outline: PackedVector2Array
) -> Array[PackedVector2Array]:
	var kept: Array[PackedVector2Array] = []
	for line: PackedVector2Array in lines:
		for part: PackedVector2Array in Geometry2D.intersect_polyline_with_polygon(line, outline):
			if part.size() >= 2:
				kept.append(part)
	return kept


## The ink of every point of [param lines], [param ink] at [param top] and fading to nothing by
## [param bottom], so a band of lines across the head of something dies away down it.
static func faded(
	lines: Array[PackedVector2Array], ink: Color, top: float, bottom: float
) -> Array[PackedColorArray]:
	var inks: Array[PackedColorArray] = []
	for line: PackedVector2Array in lines:
		var each := PackedColorArray()
		for point: Vector2 in line:
			var left := clampf(inverse_lerp(bottom, top, point.y), 0.0, 1.0)
			each.append(Color(ink, ink.a * left))
		inks.append(each)
	return inks


## Draws [param lines] onto [param item] in [param ink], or point by point in [param inks] where
## that is given, see [method faded].
static func draw(
	item: RID,
	lines: Array[PackedVector2Array],
	ink: Color,
	inks: Array[PackedColorArray] = [],
	width := WIDTH
) -> void:
	for i: int in lines.size():
		var colors := inks[i] if i < inks.size() else PackedColorArray([ink])
		RenderingServer.canvas_item_add_polyline(item, lines[i], colors, width, true)


## Draws [param lines] onto [param canvas] in [param ink], for something that draws itself.
static func draw_on(
	canvas: CanvasItem, lines: Array[PackedVector2Array], ink: Color, width := WIDTH
) -> void:
	for line: PackedVector2Array in lines:
		canvas.draw_polyline(line, ink, width, true)


static func _divisor(a: int, b: int) -> int:
	while b != 0:
		var rest := a % b
		a = b
		b = rest
	return a
