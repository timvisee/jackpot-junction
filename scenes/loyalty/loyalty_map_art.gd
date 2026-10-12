class_name LoyaltyMapArt
extends RefCounted
## The drawing of the loyalty program's map, GAME.md 8.9, everything on it but its signs and its
## words: the paper, grained, folded and darker at its edges; each district's wash with its edge
## drawn by hand; the roads, the house's double lines with gold inside, a road not open yet a dashed
## line, Kit's in pencil; the roundabout round its pot; the compass; and the little drawings a road
## map has in its empty places. Drawn in the paper's own measures, under the transform the view sets
## for its zoom, so each is sharp at every zoom. See [LoyaltyArt] for the signs.

## The House's roads: the casing and the gold lane inside it once open.
const ROAD := 12.0
const ROAD_INSIDE := 8.0
const ROAD_FILL := Color("#f5cf72")
## A road of the House's printed but not open yet: its casing and its lane paler; the dashed line
## down every road's middle, cream on a pale lane and darker gold on a gold one.
const CASING_SHUT := Color("#9a958b")
const ROAD_SHUT := Color("#e6e0d3")
const CENTER := Color(1.0, 0.98, 0.93, 0.95)
const CENTER_ON_GOLD := Color(0.58, 0.4, 0.1, 0.55)
const CENTER_WIDTH := 1.2
const CENTER_DASH := Vector2(7.0, 6.0)
## Half the width of one of Kit's roads, sketched as two pencil lines, and how much they wobble.
const SKETCH := 3.4
const WOBBLE := 0.55
## Kit's sheet of graph paper: the paper, its fine lines and its firm ones, how far apart they are,
## and what shows where the top is torn off its pad.
const GRAPH_PAPER := Color(0.97, 0.97, 0.94)
const GRAPH_FINE := Color(0.45, 0.62, 0.8, 0.22)
const GRAPH_FIRM := Color(0.45, 0.62, 0.8, 0.42)
const GRAPH_STEP := 24.0
const GRAPH_TORN := Color(0.11, 0.11, 0.13)
## Kit's road not open yet, dashed, and the pencil's width.
const DASH := Vector2(9.0, 7.0)
const PENCIL_WIDTH := 2.0
## The districts' washes and the line round each.
const STRIP_WASH := Color(0.94, 0.78, 0.37, 0.16)
const STRIP_EDGE := Color(0.76, 0.55, 0.17, 0.6)
const DEPARTMENT_WASH := Color(0.36, 0.52, 0.84, 0.1)
const DEPARTMENT_EDGE := Color(0.18, 0.38, 0.79, 0.45)
const KIT_WASH := Color(0.32, 0.32, 0.35, 0.04)
## The creases: folded in three across and two down, a shade either side of each.
const FOLDS := Vector2i(3, 2)
const FOLD_SHADE := 46.0
## The little drawings' ink and colors.
const LINE := Color(0.13, 0.12, 0.14, 0.6)
const LINE_WIDTH := 1.3
const GREEN := Color(0.46, 0.62, 0.38, 0.75)
const BARK := Color(0.47, 0.35, 0.23, 0.85)
const ROOF := Color(0.72, 0.29, 0.25, 0.7)
const WALL := Color(0.93, 0.88, 0.77, 1.0)
const CONE := Color(0.91, 0.52, 0.2, 0.9)
const STEEL := Color(0.7, 0.76, 0.83, 0.9)
const PINE := Color(0.33, 0.5, 0.36, 0.85)
const WHEAT := Color(0.88, 0.76, 0.42, 0.5)
const MEADOW := Color(0.68, 0.79, 0.52, 0.38)
const RUBBER := Color(0.2, 0.19, 0.21, 0.9)
## The country: the tint under a wood and its edge; the river's water and its banks, and how wide
## each is; the bridges' rails, how long and how far apart; and Kit's coffee.
const WOODS := Color(0.5, 0.66, 0.4, 0.2)
const WOODS_EDGE := Color(0.36, 0.5, 0.3, 0.3)
const WATER := Color(0.62, 0.77, 0.9, 1.0)
const BANK := Color(0.33, 0.5, 0.68, 0.75)
const RIVER := 8.0
const RIVER_BANK := 11.0
## The river drawn in this many stretches, the first this share of its width, widening to the last.
const RIVER_STRETCHES := 4
const RIVER_SOURCE := 0.6
## A House district's blocks between its side streets: their tint and their buildings' roofs, and
## the ways a block is built on, the buildings as shares of it across and down.
const STRIP_BLOCK := Color(0.83, 0.62, 0.32, 0.2)
const DEPARTMENT_BLOCK := Color(0.38, 0.46, 0.6, 0.14)
const STRIP_HOUSE := Color(0.72, 0.52, 0.28, 0.45)
const DEPARTMENT_HOUSE := Color(0.45, 0.52, 0.64, 0.38)
const BUILDINGS := [
	[Rect2(0.08, 0.1, 0.38, 0.42), Rect2(0.56, 0.12, 0.34, 0.32), Rect2(0.12, 0.6, 0.76, 0.3)],
	[Rect2(0.1, 0.1, 0.8, 0.35), Rect2(0.1, 0.55, 0.35, 0.35), Rect2(0.55, 0.55, 0.35, 0.35)],
	[Rect2(0.15, 0.15, 0.3, 0.7), Rect2(0.55, 0.15, 0.3, 0.3), Rect2(0.55, 0.55, 0.3, 0.3)],
	[Rect2(0.12, 0.14, 0.76, 0.72)],
	[Rect2(0.1, 0.12, 0.35, 0.76), Rect2(0.56, 0.3, 0.32, 0.5)],
]
const RAIL := 17.0
const SAND := Color(0.9, 0.84, 0.66)
const COFFEE := Color(0.45, 0.3, 0.16)

static var _grain: Texture2D


## The paper of [param size]: the cream, its grain, the shade either side of each crease and the
## crease itself, darker toward its edges, and the rules inside them.
static func paper(on: CanvasItem, size: Vector2) -> void:
	var sheet := Rect2(Vector2.ZERO, size)
	on.draw_rect(Rect2(Vector2(5.0, 7.0), size), Color(0, 0, 0, 0.35))
	on.draw_rect(sheet, HouseTheme.PAPER)
	on.draw_texture_rect(_grain_texture(), sheet, true)
	var panel := size / Vector2(FOLDS)
	for across: int in range(1, FOLDS.x):
		var x := panel.x * across
		_shade(on, Rect2(x - FOLD_SHADE, 0.0, FOLD_SHADE, size.y), Vector2.RIGHT, 0.07)
		_shade(on, Rect2(x, 0.0, FOLD_SHADE * 0.6, size.y), Vector2.LEFT, 0.05)
		on.draw_line(Vector2(x, 0.0), Vector2(x, size.y), Color(0, 0, 0, 0.12), 1.4)
		on.draw_line(Vector2(x + 1.4, 0.0), Vector2(x + 1.4, size.y), Color(1, 1, 1, 0.4), 1.0)
	for down: int in range(1, FOLDS.y):
		var y := panel.y * down
		_shade(on, Rect2(0.0, y - FOLD_SHADE, size.x, FOLD_SHADE), Vector2.DOWN, 0.06)
		on.draw_line(Vector2(0.0, y), Vector2(size.x, y), Color(0, 0, 0, 0.12), 1.4)
		on.draw_line(Vector2(0.0, y + 1.4), Vector2(size.x, y + 1.4), Color(1, 1, 1, 0.4), 1.0)
	# Where two creases cross the paper is worn thin and pale.
	for across: int in range(1, FOLDS.x):
		for down: int in range(1, FOLDS.y):
			var worn := panel * Vector2(across, down)
			on.draw_circle(worn, 14.0, Color(1.0, 1.0, 1.0, 0.12))
			on.draw_circle(worn, 6.0, Color(1.0, 1.0, 1.0, 0.18))
	var edge := 34.0
	_shade(on, Rect2(0.0, 0.0, size.x, edge), Vector2.UP, 0.08)
	_shade(on, Rect2(0.0, size.y - edge, size.x, edge), Vector2.DOWN, 0.08)
	_shade(on, Rect2(0.0, 0.0, edge, size.y), Vector2.LEFT, 0.08)
	_shade(on, Rect2(size.x - edge, 0.0, edge, size.y), Vector2.RIGHT, 0.08)
	var rule := sheet.grow(-22.0)
	on.draw_rect(rule, Color(HouseTheme.INK, 0.55), false, 1.3)
	on.draw_rect(rule.grow(-4.0), Color(HouseTheme.INK, 0.3), false, 0.8)


## A shade over [param rect], darkest at its side toward [param dark] and nothing at the other.
static func _shade(on: CanvasItem, rect: Rect2, dark: Vector2, most: float) -> void:
	var deep := Color(0.25, 0.2, 0.12, most)
	var none := Color(0.25, 0.2, 0.12, 0.0)
	var corners := PackedVector2Array(
		[
			rect.position,
			Vector2(rect.end.x, rect.position.y),
			rect.end,
			Vector2(rect.position.x, rect.end.y)
		]
	)
	var colors := PackedColorArray()
	for corner: Vector2 in corners:
		var side := (corner - rect.get_center()).dot(dark) > 0.0
		colors.append(deep if side else none)
	on.draw_polygon(corners, colors)


## The paper's grain, a little ink in a few of its fibers, made once.
static func _grain_texture() -> Texture2D:
	if _grain != null:
		return _grain
	var side := 128
	var image := Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
	var dice := RandomNumberGenerator.new()
	dice.seed = 9
	for y: int in side:
		for x: int in side:
			var fiber := pow(dice.randf(), 6.0) * 0.16
			image.set_pixel(x, y, Color(0.4, 0.33, 0.22, fiber))
	_grain = ImageTexture.create_from_image(image)
	return _grain


## A district's wash, [param outline], in its color, and the line round it: the Strip's dotted in
## gold, the Department's dashed and dotted in its blue, Kit's in pencil twice over.
static func wash(on: CanvasItem, outline: PackedVector2Array, district: int) -> void:
	if outline.size() < 3:
		return
	var closed := outline.duplicate()
	closed.append(outline[0])
	match district:
		LoyaltyLandmark.District.STRIP:
			on.draw_colored_polygon(outline, STRIP_WASH)
			_dotted(on, closed, STRIP_EDGE, 1.7, 9.0)
		LoyaltyLandmark.District.DEPARTMENT:
			on.draw_colored_polygon(outline, DEPARTMENT_WASH)
			dashed(on, closed, DEPARTMENT_EDGE, 1.6, Vector2(14.0, 5.0), true)
		_:
			on.draw_colored_polygon(outline, KIT_WASH)
			on.draw_polyline(closed, Color(LoyaltyArt.PENCIL, 0.4), 1.2, true)
			var shifted := PackedVector2Array()
			for point: Vector2 in closed:
				shifted.append(point + Vector2(1.6, -1.2))
			on.draw_polyline(shifted, Color(LoyaltyArt.PENCIL, 0.2), 1.0, true)


## Kit's sheet, [param size] big: graph paper, white a little blue, ruled fine every so often and
## firmer every fifth line, its edge torn off a pad at the top.
static func graph_paper(on: CanvasItem, size: Vector2) -> void:
	on.draw_rect(Rect2(Vector2(10.0, 14.0), size), Color(0.0, 0.0, 0.0, 0.25))
	on.draw_rect(Rect2(Vector2.ZERO, size), GRAPH_PAPER)
	var line := 0
	var x := 0.0
	while x < size.x:
		var firm := line % 5 == 0
		on.draw_line(Vector2(x, 0.0), Vector2(x, size.y), GRAPH_FIRM if firm else GRAPH_FINE, 1.0)
		x += GRAPH_STEP
		line += 1
	line = 0
	var y := 0.0
	while y < size.y:
		var firm := line % 5 == 0
		on.draw_line(Vector2(0.0, y), Vector2(size.x, y), GRAPH_FIRM if firm else GRAPH_FINE, 1.0)
		y += GRAPH_STEP
		line += 1
	# The top torn off the pad: a ragged edge of the board's dark under the paper's.
	var torn := PackedVector2Array([Vector2(0.0, -1.0)])
	var along := 0.0
	while along < size.x:
		torn.append(Vector2(along, 3.0 + absf(sin(along * 0.37) * 4.0 + sin(along * 0.11) * 3.0)))
		along += 6.0
	torn.append(Vector2(size.x, -1.0))
	on.draw_colored_polygon(torn, GRAPH_TORN)


## A wood's tint, [param outline], under its trees.
static func woods(on: CanvasItem, outline: PackedVector2Array) -> void:
	if outline.size() < 3:
		return
	on.draw_colored_polygon(outline, WOODS)
	var closed := outline.duplicate()
	closed.append(outline[0])
	on.draw_polyline(closed, WOODS_EDGE, 1.0, true)


## The river through [param points] and its lakes, [param lakes], the moat among them: the banks,
## then the water over them, the river a little wider each stretch of its way, and a ripple or two
## on each lake.
static func river(
	on: CanvasItem, points: PackedVector2Array, lakes: Array[PackedVector2Array]
) -> void:
	var stretches := _widening(points)
	for stretch: Array in stretches:
		on.draw_polyline(stretch[0], BANK, RIVER_BANK * stretch[1], true)
	for lake: PackedVector2Array in lakes:
		if lake.size() < 3:
			continue
		var closed := lake.duplicate()
		closed.append(lake[0])
		on.draw_colored_polygon(lake, BANK)
		on.draw_polyline(closed, BANK, 3.0, true)
	for stretch: Array in stretches:
		on.draw_polyline(stretch[0], WATER, RIVER * stretch[1], true)
	var ripples := PackedVector2Array()
	for lake: PackedVector2Array in lakes:
		if lake.size() < 3:
			continue
		var inner := Geometry2D.offset_polygon(lake, -2.0)
		if not inner.is_empty():
			on.draw_colored_polygon(inner[0], WATER)
		var middle := LoyaltyMapLand.middle_of(lake)
		for ripple: Vector3 in [Vector3(-26, -6, 18), Vector3(8, 4, 22), Vector3(-6, 13, 12)]:
			ripples.append(middle + Vector2(ripple.x, ripple.y))
			ripples.append(middle + Vector2(ripple.x + ripple.z, ripple.y))
	if not ripples.is_empty():
		on.draw_multiline(ripples, Color(1.0, 1.0, 1.0, 0.75), 1.2, true)


## [param points] in [constant RIVER_STRETCHES] stretches, each a stretch and the share of the
## river's width it is drawn at, a little more each one.
static func _widening(points: PackedVector2Array) -> Array:
	var stretches: Array = []
	if points.size() < 2:
		return stretches
	var each := maxi(points.size() / RIVER_STRETCHES, 2)
	var start := 0
	var k := 0
	while start < points.size() - 1:
		var end := mini(start + each, points.size() - 1)
		var share := lerpf(RIVER_SOURCE, 1.0, float(k) / maxf(RIVER_STRETCHES - 1.0, 1.0))
		stretches.append([points.slice(start, end + 1), share])
		start = end
		k += 1
	return stretches


## A block of a House district between its side streets, [param quad], drawn by [param seed]: a
## tint of the district's color and the buildings on it, see [constant BUILDINGS].
static func block(on: CanvasItem, quad: PackedVector2Array, district: int, seed: int) -> void:
	var strip := district == LoyaltyLandmark.District.STRIP
	on.draw_colored_polygon(quad, STRIP_BLOCK if strip else DEPARTMENT_BLOCK)
	var plots: Array = BUILDINGS[posmod(seed, BUILDINGS.size())]
	var roof := STRIP_HOUSE if strip else DEPARTMENT_HOUSE
	for plot: Rect2 in plots:
		var shape := PackedVector2Array()
		for corner: Vector2 in [
			plot.position,
			Vector2(plot.end.x, plot.position.y),
			plot.end,
			Vector2(plot.position.x, plot.end.y)
		]:
			var top := quad[0].lerp(quad[1], corner.x)
			var foot := quad[3].lerp(quad[2], corner.x)
			shape.append(top.lerp(foot, corner.y))
		on.draw_colored_polygon(shape, roof)
		shape.append(shape[0])
		on.draw_polyline(shape, Color(HouseTheme.INK, 0.3), 0.8, true)


## A bridge carrying the road through [param line] over water: a rail either side of the road
## along it, its ends turned out onto the banks.
static func bridge(on: CanvasItem, line: PackedVector2Array) -> void:
	if line.size() < 2:
		return
	var start := (line[1] - line[0]).normalized()
	var end := (line[-1] - line[-2]).normalized()
	for side: float in [-1.0, 1.0]:
		var rail := LoyaltyMapArt.beside(line, RAIL * 0.5 * side, 0.0)
		var out_from := Vector2(start.y, -start.x) * side * 5.0 - start * 4.0
		var out_to := Vector2(end.y, -end.x) * side * 5.0 + end * 4.0
		rail.insert(0, rail[0] + out_from)
		rail.append(rail[-1] + out_to)
		on.draw_polyline(rail, HouseTheme.INK, 2.0, true)


## The roundabout's island, [param radius] round [param middle], in the water round it: a shore of
## sand and the grass inside it.
static func island(on: CanvasItem, middle: Vector2, radius: float) -> void:
	on.draw_circle(middle, radius, SAND)
	on.draw_circle(middle, radius - 5.0, Color(0.72, 0.8, 0.56))
	on.draw_arc(middle, radius, 0.0, TAU, 48, BANK, 1.4, true)


## Kit's coffee ring, [param radius] round [param at]: where his cup stood, a ring darker at its
## edge and not quite even, a fainter one a little off it where it was put down again.
static func coffee(on: CanvasItem, at: Vector2, radius: float) -> void:
	on.draw_circle(at, radius, Color(COFFEE, 0.05))
	on.draw_arc(at, radius, 0.4, TAU + 0.1, 48, Color(COFFEE, 0.2), 2.6, true)
	on.draw_arc(at, radius - 2.0, 2.2, 5.6, 32, Color(COFFEE, 0.12), 1.4, true)
	on.draw_arc(
		at + Vector2(9.0, 6.0), radius * 0.97, -1.2, 1.9, 32, Color(COFFEE, 0.12), 1.8, true
	)


## The side streets, [param streets], faint, a lane of paper between two thin lines: all of them
## at once, two lines of a multiline each, rather than a line drawn for each.
static func streets(on: CanvasItem, streets: Array[PackedVector2Array]) -> void:
	var lines := PackedVector2Array()
	for street: PackedVector2Array in streets:
		_into(lines, street)
	if not lines.is_empty():
		on.draw_multiline(lines, Color(HouseTheme.INK, 0.09), 5.0, true)
		on.draw_multiline(lines, Color(HouseTheme.PAPER, 0.7), 2.6, true)


## A road through [param points]: the House's casing, dark once it is open and paler before, its
## lane and middle line laid on after every road's casing, see [method road_inside] and
## [method road_middle]; or Kit's, sketched in pencil as two lines by hand, the way a road is drawn
## on a napkin, dashed and fainter until it is open.
static func road(on: CanvasItem, points: PackedVector2Array, pencil: bool, open: bool) -> void:
	if points.size() < 2:
		return
	if pencil:
		_sketch(on, points, open)
		return
	on.draw_polyline(points, HouseTheme.INK if open else CASING_SHUT, ROAD, true)


## The lane of the House's road through [param points], over its casing, gold once it is
## [param open] and pale before: laid on after every road's casing, so where two roads meet the
## lane runs on through.
static func road_inside(on: CanvasItem, points: PackedVector2Array, open := true) -> void:
	if points.size() >= 2:
		on.draw_polyline(points, ROAD_FILL if open else ROAD_SHUT, ROAD_INSIDE, true)


## The dashed line down the middle of the House's road through [param points], over every lane.
static func road_middle(on: CanvasItem, points: PackedVector2Array, open := true) -> void:
	if points.size() >= 2:
		dashed(on, points, CENTER_ON_GOLD if open else CENTER, CENTER_WIDTH, CENTER_DASH, false)


## The whole of one of the House's roads at once, casing, lane and middle, for the legend.
static func house_road(on: CanvasItem, points: PackedVector2Array, open: bool) -> void:
	road(on, points, false, open)
	road_inside(on, points, open)
	road_middle(on, points, open)


## Kit's road through [param points]: two pencil lines either side of it, wobbling as a hand does,
## and the hand going over one of them again; dashed and fainter until it is [param open].
static func _sketch(on: CanvasItem, points: PackedVector2Array, open: bool) -> void:
	var ink := Color(LoyaltyArt.PENCIL, 0.82 if open else 0.36)
	for side: float in [-1.0, 1.0]:
		var line := beside(points, SKETCH * side, side * 2.3)
		if open:
			on.draw_polyline(line, ink, PENCIL_WIDTH * 0.75, true)
		else:
			dashed(on, line, ink, PENCIL_WIDTH * 0.7, DASH, false)
	if open:
		var again := beside(points, SKETCH + 0.8, 5.1)
		on.draw_polyline(again, Color(LoyaltyArt.PENCIL, 0.25), 1.0, true)


## [param points] moved [param by] to their left, as the line runs, wobbling a little by
## [param seed] as a line drawn by hand beside another does.
static func beside(points: PackedVector2Array, by: float, seed: float) -> PackedVector2Array:
	var moved := PackedVector2Array()
	var last := points.size() - 1
	var along := 0.0
	for i: int in points.size():
		var before := points[maxi(i - 1, 0)]
		var after := points[mini(i + 1, last)]
		var way := (after - before).normalized()
		if i > 0:
			along += points[i].distance_to(points[i - 1])
		var wobble := sin(along * 0.045 + seed) * WOBBLE
		moved.append(points[i] + Vector2(way.y, -way.x) * (by + wobble))
	return moved


## [param points] as dashes [param pattern] long and apart.
static func dashed(
	on: CanvasItem,
	points: PackedVector2Array,
	ink: Color,
	width: float,
	pattern: Vector2,
	dots: bool
) -> void:
	# Every dash a pair of points or more of one multiline, drawn at once rather than a line each,
	# and every dot one of a row of them.
	var lines := PackedVector2Array()
	var spots := PackedVector2Array()
	var drawing := true
	var left := pattern.x
	var dash := PackedVector2Array([points[0]])
	for i: int in range(1, points.size()):
		var from := points[i - 1]
		var to := points[i]
		var stretch := from.distance_to(to)
		var gone := 0.0
		while stretch - gone > left:
			gone += left
			var at := from.lerp(to, gone / stretch)
			if drawing:
				dash.append(at)
				_into(lines, dash)
				if dots:
					spots.append(from.lerp(to, minf(gone + pattern.y * 0.5, stretch) / stretch))
			dash = PackedVector2Array([at])
			drawing = not drawing
			left = pattern.x if drawing else pattern.y
		left -= stretch - gone
		if drawing:
			dash.append(to)
	if drawing and dash.size() >= 2:
		_into(lines, dash)
	if not lines.is_empty():
		on.draw_multiline(lines, ink, width, true)
	LoyaltyArt.dots(on, spots, width * 0.6, ink)


## [param dash], a line through its points, into [param lines] as the pairs a multiline draws.
static func _into(lines: PackedVector2Array, dash: PackedVector2Array) -> void:
	for i: int in range(1, dash.size()):
		lines.append(dash[i - 1])
		lines.append(dash[i])


static func _dotted(
	on: CanvasItem, points: PackedVector2Array, ink: Color, radius: float, step: float
) -> void:
	var spots := PackedVector2Array()
	var left := 0.0
	for i: int in range(1, points.size()):
		var from := points[i - 1]
		var to := points[i]
		var stretch := from.distance_to(to)
		var at := left
		while at < stretch:
			spots.append(from.lerp(to, at / stretch))
			at += step
		left = at - stretch
	LoyaltyArt.dots(on, spots, radius, ink)


## The roundabout round [param middle], [param radius] out: its ring a road, open or not yet; the
## island inside, its burst of rays and its bulbs, and the pot as a chip in the middle, waiting for
## the word JACKPOT the view prints on it.
static func roundabout(on: CanvasItem, middle: Vector2, radius: float, open: bool) -> void:
	var ring := PackedVector2Array()
	for i: int in 73:
		ring.append(middle + Vector2.from_angle(TAU * i / 72.0) * radius)
	house_road(on, ring, open)
	on.draw_circle(middle, radius * 0.8, Color(0.9, 0.85, 0.72, 1.0))
	on.draw_arc(middle, radius * 0.8, 0.0, TAU, 64, Color(HouseTheme.INK, 0.35), 1.2, true)
	for i: int in 16:
		var angle := TAU * i / 16.0
		var spread := TAU / 64.0
		(
			on
			. draw_colored_polygon(
				PackedVector2Array(
					[
						middle + Vector2.from_angle(angle - spread) * radius * 0.42,
						middle + Vector2.from_angle(angle) * radius * 0.76,
						middle + Vector2.from_angle(angle + spread) * radius * 0.42,
					]
				),
				Color(HouseTheme.FOIL, 0.45 if i % 2 == 0 else 0.22)
			)
		)
	for i: int in 20:
		var at := middle + Vector2.from_angle(TAU * (i + 0.5) / 20.0) * radius * 0.71
		on.draw_circle(at, 2.2, HouseTheme.FOIL_HIGH, true, -1.0, true)
		on.draw_arc(at, 2.2, 0.0, TAU, 12, Color(HouseTheme.ON_FOIL, 0.35), 0.6, true)
	var chip := radius * 0.52
	on.draw_circle(middle + Vector2(1.5, 2.5), chip, Color(0, 0, 0, 0.18))
	on.draw_circle(middle, chip, HouseTheme.FOIL_LOW)
	for i: int in 8:
		var angle := TAU * i / 8.0
		var notch := PackedVector2Array()
		for corner: Vector2 in [
			Vector2(-0.12, 0.84), Vector2(0.12, 0.84), Vector2(0.12, 1.0), Vector2(-0.12, 1.0)
		]:
			notch.append(middle + (Vector2(corner.x, -corner.y) * chip).rotated(angle))
		on.draw_colored_polygon(notch, Color(HouseTheme.PAPER, 0.85))
	on.draw_circle(middle, chip * 0.8, HouseTheme.FOIL)
	on.draw_arc(middle, chip * 0.72, 0.0, TAU, 48, Color(HouseTheme.ON_FOIL, 0.45), 1.0, true)
	# Shut, printed pale as a closed landmark's sign is, see [method LoyaltyArt.draw_sign].
	if not open:
		on.draw_circle(middle, radius * 0.82, Color(HouseTheme.PAPER, LoyaltyArt.PALE))


## The ring's bets round the roundabout [param radius] round [param middle], GAME.md 8.9, for
## [param profile]: a badge each over and under the ring, clear of the roads in at its sides, its
## share come filled in gold.
static func ring_bets(on: CanvasItem, middle: Vector2, radius: float, profile: Profile) -> void:
	var ring := profile.loyalty.ring
	var out := radius * 1.32
	var badge := 13.0
	for i: int in ring.size():
		var over := i < (ring.size() + 1) / 2
		var count := (ring.size() + 1) / 2 if over else ring.size() / 2
		var k := i if over else i - (ring.size() + 1) / 2
		var spread := deg_to_rad(110.0)
		var angle := -PI * 0.5 + (float(k) / maxf(count - 1, 1) - 0.5) * spread
		if not over:
			angle = PI * 0.5 + (float(k) / maxf(count - 1, 1) - 0.5) * spread
		var at := middle + Vector2.from_angle(angle) * out
		var come := Loyalty.ring_progress(profile, ring[i])
		on.draw_circle(at, badge, HouseTheme.PAPER)
		var share := come.x / come.y if come.y > 0.0 else 0.0
		if share > 0.0:
			var pie := PackedVector2Array([at])
			for step: int in 25:
				pie.append(at + Vector2.from_angle(-PI * 0.5 + TAU * share * step / 24.0) * badge)
			on.draw_colored_polygon(pie, HouseTheme.FOIL if share < 1.0 else HouseTheme.FOIL_LOW)
		on.draw_arc(at, badge, 0.0, TAU, 32, HouseTheme.INK, 1.6, true)


## The compass, [param radius] round [param middle]: a ring cut like a chip's edge, the four long
## points and four short ones, the north's in the stamp's red.
static func compass(on: CanvasItem, middle: Vector2, radius: float) -> void:
	on.draw_circle(middle, radius, Color(HouseTheme.PAPER, 0.9))
	on.draw_arc(middle, radius, 0.0, TAU, 64, Color(HouseTheme.INK, 0.7), 1.6, true)
	on.draw_arc(middle, radius * 0.86, 0.0, TAU, 64, Color(HouseTheme.INK, 0.4), 1.0, true)
	for i: int in 32:
		var angle := TAU * i / 32.0
		var inner := radius * (0.86 if i % 4 == 0 else 0.92)
		on.draw_line(
			middle + Vector2.from_angle(angle) * inner,
			middle + Vector2.from_angle(angle) * radius,
			Color(HouseTheme.INK, 0.55),
			1.0,
			true
		)
	for i: int in 8:
		var angle := -PI * 0.5 + TAU * i / 8.0
		var long := i % 2 == 0
		var reach := radius * (0.8 if long else 0.48)
		var side := radius * (0.13 if long else 0.09)
		var tip := middle + Vector2.from_angle(angle) * reach
		var left := middle + Vector2.from_angle(angle - PI * 0.5) * side
		var right := middle + Vector2.from_angle(angle + PI * 0.5) * side
		var dark := HouseTheme.STAMP_RED if i == 0 else Color(HouseTheme.INK, 0.8)
		on.draw_colored_polygon(PackedVector2Array([middle, left, tip]), dark)
		on.draw_colored_polygon(
			PackedVector2Array([middle, tip, right]), Color(HouseTheme.PAPER, 1.0)
		)
		on.draw_polyline(
			PackedVector2Array([left, tip, right, middle, left]),
			Color(HouseTheme.INK, 0.7),
			1.0,
			true
		)
	on.draw_circle(middle, radius * 0.07, HouseTheme.INK)


## A box on the paper for the legend or the title block: paper over the map, two rules round it, a
## diamond at each corner.
static func box(on: CanvasItem, rect: Rect2) -> void:
	on.draw_rect(Rect2(rect.position + Vector2(3.0, 4.0), rect.size), Color(0, 0, 0, 0.12))
	on.draw_rect(rect, HouseTheme.PAPER)
	on.draw_rect(rect, Color(HouseTheme.INK, 0.75), false, 1.4)
	on.draw_rect(rect.grow(-4.0), Color(HouseTheme.INK, 0.35), false, 0.8)
	for corner: Vector2 in [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y)
	]:
		var diamond := PackedVector2Array()
		for way: Vector2 in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
			diamond.append(corner + way * 5.0)
		on.draw_colored_polygon(diamond, HouseTheme.INK)


## A little drawing of [param kind], in a box thirty across round the origin, under the transform
## its caller has set for where it is, how big and how far turned.
static func doodle(on: CanvasItem, kind: StringName) -> void:
	match kind:
		&"casino":
			on.draw_colored_polygon(
				PackedVector2Array([Vector2(-14, -3), Vector2(0, -13), Vector2(14, -3)]), ROOF
			)
			_outline(on, PackedVector2Array([Vector2(-14, -3), Vector2(0, -13), Vector2(14, -3)]))
			_block(on, Rect2(-12, -3, 24, 16), WALL)
			on.draw_rect(Rect2(-9, -1, 18, 4), Color(HouseTheme.INK, 0.85))
			for x: float in [-6.0, 0.0, 6.0]:
				on.draw_circle(Vector2(x, 1), 1.0, HouseTheme.FOIL_HIGH)
			on.draw_rect(Rect2(-3, 6, 6, 7), Color(HouseTheme.INK, 0.55))
		&"palm":
			on.draw_polyline(
				PackedVector2Array([Vector2(3, 15), Vector2(2, 7), Vector2(-1, 0), Vector2(0, -7)]),
				BARK,
				2.4,
				true
			)
			for angle: float in [-170.0, -130.0, -90.0, -50.0, -10.0]:
				var way := Vector2.from_angle(deg_to_rad(angle))
				var tip := Vector2(0, -7) + way * 12.0
				var side := way.orthogonal() * 3.0
				var leaf := PackedVector2Array(
					[
						Vector2(0, -7),
						Vector2(0, -7) + way * 6.0 + side,
						tip,
						Vector2(0, -7) + way * 6.0 - side
					]
				)
				on.draw_colored_polygon(leaf, GREEN)
				_outline(on, leaf)
		&"chips":
			var inks: Array[Color] = [Palette.MULT, Palette.CHIP_GOLD, Palette.CHIP_WHITE]
			for i: int in 3:
				var disc := _ellipse(Vector2(0, 8 - i * 5), Vector2(11, 4.2))
				on.draw_colored_polygon(disc, Color(inks[i], 0.9))
				_outline(on, disc)
		&"dice":
			var side := PackedVector2Array(
				[Vector2(-9, -9), Vector2(9, -9), Vector2(9, 9), Vector2(-9, 9)]
			)
			on.draw_colored_polygon(side, Palette.CHIP_WHITE)
			_outline(on, side)
			for pip: Vector2 in [Vector2(-4.5, -4.5), Vector2(0, 0), Vector2(4.5, 4.5)]:
				on.draw_circle(pip, 1.8, Color(HouseTheme.INK, 0.85))
		&"star", &"doodle_star":
			var star := PackedVector2Array()
			for i: int in 10:
				star.append(
					Vector2.from_angle(-PI * 0.5 + TAU * i / 10.0) * (10.0 if i % 2 == 0 else 4.2)
				)
			if kind == &"star":
				on.draw_colored_polygon(star, Color(HouseTheme.FOIL, 0.75))
				_outline(on, star)
			else:
				_pencil(on, star, true)
		&"cone":
			var cone := PackedVector2Array(
				[Vector2(-8, 11), Vector2(-2, -12), Vector2(2, -12), Vector2(8, 11)]
			)
			on.draw_colored_polygon(cone, CONE)
			on.draw_colored_polygon(
				PackedVector2Array(
					[Vector2(-5, 0), Vector2(-3.5, -5), Vector2(3.5, -5), Vector2(5, 0)]
				),
				Color(1, 1, 1, 0.9)
			)
			_outline(on, cone)
			_block(on, Rect2(-11, 11, 22, 3), Color(HouseTheme.INK, 0.7))
		&"wood":
			on.draw_line(Vector2(0, 3), Vector2(0, 13), BARK, 2.6)
			on.draw_circle(Vector2(0, -3), 10.0, GREEN)
			on.draw_arc(Vector2(0, -3), 10.0, 0.0, TAU, 20, LINE, LINE_WIDTH, true)
		&"pine":
			on.draw_line(Vector2(0, 8), Vector2(0, 14), BARK, 2.6)
			var pine := PackedVector2Array(
				[
					Vector2(0, -15),
					Vector2(7, -4),
					Vector2(4, -4),
					Vector2(11, 8),
					Vector2(-11, 8),
					Vector2(-4, -4),
					Vector2(-7, -4)
				]
			)
			on.draw_colored_polygon(pine, PINE)
			_outline(on, pine)
		&"wheat", &"meadow":
			var plot := PackedVector2Array(
				[Vector2(-15, -9), Vector2(15, -9), Vector2(15, 9), Vector2(-15, 9)]
			)
			on.draw_colored_polygon(plot, WHEAT if kind == &"wheat" else MEADOW)
			var marks := PackedVector2Array()
			for y: float in [-5.0, 0.0, 5.0]:
				for x: float in [-11.0, -4.0, 3.0, 10.0]:
					var shift := 2.0 if y == 0.0 else 0.0
					if kind == &"wheat":
						marks.append_array([Vector2(x + shift - 2, y), Vector2(x + shift + 2, y)])
					else:
						marks.append_array(
							[Vector2(x + shift, y + 1.5), Vector2(x + shift + 1, y - 1.5)]
						)
			on.draw_multiline(marks, Color(0.4, 0.38, 0.2, 0.45), 1.0, true)
			_outline(on, plot)
		&"barn":
			_block(on, Rect2(-10, -2, 20, 15), ROOF)
			var roof := PackedVector2Array(
				[
					Vector2(-13, -1),
					Vector2(-9, -9),
					Vector2(0, -14),
					Vector2(9, -9),
					Vector2(13, -1)
				]
			)
			on.draw_colored_polygon(roof, Color(0.45, 0.2, 0.17, 0.9))
			_outline(on, roof)
			on.draw_multiline(
				PackedVector2Array(
					[Vector2(-4, 4), Vector2(4, 13), Vector2(4, 4), Vector2(-4, 13)]
				),
				Color(1, 1, 1, 0.75),
				1.0,
				true
			)
		&"tires":
			for i: int in 3:
				var tire := _ellipse(Vector2(0, 9 - i * 6), Vector2(11, 4.4))
				on.draw_colored_polygon(tire, RUBBER)
				_outline(on, tire)
			on.draw_colored_polygon(
				_ellipse(Vector2(0, -3), Vector2(4.5, 1.6)), Color(0.55, 0.53, 0.5)
			)
		&"fountain":
			on.draw_circle(Vector2.ZERO, 14.0, Color(0.93, 0.88, 0.76))
			on.draw_arc(Vector2.ZERO, 14.0, 0.0, TAU, 32, LINE, LINE_WIDTH, true)
			for i: int in 8:
				var way := Vector2.from_angle(TAU * i / 8.0)
				on.draw_line(way * 10.0, way * 14.0, Color(HouseTheme.INK, 0.25), 0.8, true)
			on.draw_circle(Vector2.ZERO, 8.5, WATER)
			on.draw_arc(Vector2.ZERO, 8.5, 0.0, TAU, 28, BANK, 1.4, true)
			on.draw_circle(Vector2.ZERO, 2.4, HouseTheme.FOIL)
			for i: int in 6:
				var way := Vector2.from_angle(TAU * i / 6.0 + 0.3)
				on.draw_line(way * 2.6, way * 6.5, Color(1, 1, 1, 0.85), 1.0, true)
		&"track":
			var outer := _ellipse(Vector2.ZERO, Vector2(14.5, 9.0))
			on.draw_colored_polygon(outer, Color(0.42, 0.42, 0.44, 0.75))
			on.draw_colored_polygon(
				_ellipse(Vector2.ZERO, Vector2(10.5, 5.2)), Color(0.66, 0.78, 0.52)
			)
			_outline(on, outer)
			_outline(on, _ellipse(Vector2.ZERO, Vector2(10.5, 5.2)))
			for i: int in 4:
				var flag := Color.WHITE if i % 2 == 0 else Color(0.1, 0.1, 0.1)
				on.draw_rect(Rect2(-1.0 + (i % 2) * 1.0, 5.2 + (i / 2) * 1.9, 1.0, 1.9), flag)
			_outline(on, _ellipse(Vector2.ZERO, Vector2(12.5, 7.1)))
		&"reeds":
			var stems := PackedVector2Array()
			for i: int in 5:
				var x := -6.0 + i * 3.0
				stems.append_array(
					[Vector2(x, 8), Vector2(x + sin(i * 1.7) * 2.0, -4 - (i % 2) * 4)]
				)
			on.draw_multiline(stems, Color(0.36, 0.48, 0.3, 0.9), 1.3, true)
			for i: int in [1, 3]:
				var x := -6.0 + i * 3.0 + sin(i * 1.7) * 2.0
				on.draw_rect(Rect2(x - 1.2, -9 - (i % 2) * 4, 2.4, 5), BARK)
		&"boat":
			var hull := PackedVector2Array(
				[Vector2(-11, 2), Vector2(11, 2), Vector2(7, 7), Vector2(-7, 7)]
			)
			on.draw_colored_polygon(hull, ROOF)
			_outline(on, hull)
			on.draw_line(Vector2(0, 2), Vector2(0, -12), LINE, 1.2, true)
			var sail := PackedVector2Array([Vector2(1, -11), Vector2(9, 0), Vector2(1, 0)])
			on.draw_colored_polygon(sail, Color(1, 1, 1, 0.95))
			_outline(on, sail)
		&"tree":
			on.draw_rect(Rect2(-1.6, 4, 3.2, 10), BARK)
			for blob: Vector3 in [Vector3(0, -4, 9), Vector3(-6, 1, 6), Vector3(6, 1, 6)]:
				on.draw_circle(Vector2(blob.x, blob.y), blob.z, GREEN)
			for blob: Vector3 in [Vector3(0, -4, 9), Vector3(-6, 1, 6), Vector3(6, 1, 6)]:
				on.draw_arc(Vector2(blob.x, blob.y), blob.z, 0.0, TAU, 20, LINE, LINE_WIDTH, true)
		&"parking":
			_block(on, Rect2(-14, -6, 28, 18), Color(HouseTheme.INK, 0.06))
			for x: float in [-7.0, 0.0, 7.0]:
				on.draw_line(Vector2(x, -6), Vector2(x, 1), LINE, 1.0, true)
				on.draw_line(Vector2(x, 5), Vector2(x, 12), LINE, 1.0, true)
			_block(on, Rect2(-15, -15, 9, 9), LoyaltyArt.SIGN_BLUE)
			on.draw_polyline(
				PackedVector2Array(
					[
						Vector2(-12.5, -8),
						Vector2(-12.5, -13),
						Vector2(-9.5, -13),
						Vector2(-8.5, -12),
						Vector2(-9.5, -10.5),
						Vector2(-12.5, -10.5)
					]
				),
				Color.WHITE,
				1.1,
				true
			)
		&"tower":
			for leg: Array in [
				[Vector2(-6, 0), Vector2(-9, 14)],
				[Vector2(6, 0), Vector2(9, 14)],
				[Vector2(0, 2), Vector2(0, 14)]
			]:
				on.draw_line(leg[0], leg[1], LINE, 1.4, true)
			on.draw_line(Vector2(-7.5, 7), Vector2(7.5, 7), LINE, 1.0, true)
			on.draw_circle(Vector2(0, -6), 8.0, STEEL)
			on.draw_arc(Vector2(0, -6), 8.0, 0.0, TAU, 24, LINE, LINE_WIDTH, true)
		&"house":
			_block(on, Rect2(-9, -2, 18, 14), WALL)
			var roof := PackedVector2Array([Vector2(-12, -2), Vector2(0, -12), Vector2(12, -2)])
			on.draw_colored_polygon(roof, ROOF)
			_outline(on, roof)
			on.draw_rect(Rect2(-2.5, 5, 5, 7), Color(HouseTheme.INK, 0.55))
		&"field":
			var field := PackedVector2Array(
				[Vector2(-15, -9), Vector2(15, -9), Vector2(15, 9), Vector2(-15, 9)]
			)
			on.draw_colored_polygon(field, Color(0.66, 0.77, 0.52, 0.35))
			for x: float in [-11.0, -6.0, -1.0, 4.0, 9.0]:
				on.draw_line(
					Vector2(x, -8), Vector2(x + 4, 8), Color(0.32, 0.45, 0.25, 0.35), 1.0, true
				)
			_outline(on, field)
		&"hills":
			for hill: Vector3 in [Vector3(-6, 6, 9), Vector3(5, 6, 12)]:
				var arc := PackedVector2Array()
				for i: int in 13:
					var angle := PI + PI * i / 12.0
					arc.append(
						(
							Vector2(hill.x, hill.y)
							+ Vector2(cos(angle) * hill.z, sin(angle) * hill.z * 0.9)
						)
					)
				on.draw_colored_polygon(arc, Color(0.66, 0.74, 0.5, 0.35))
				on.draw_polyline(arc, LINE, LINE_WIDTH, true)
		&"pond":
			var pond := PackedVector2Array()
			for i: int in 20:
				var angle := TAU * i / 20.0
				var reach := 1.0 + sin(angle * 3.0) * 0.12
				pond.append(Vector2(cos(angle) * 14.0, sin(angle) * 8.0) * reach)
			on.draw_colored_polygon(pond, Color(0.55, 0.7, 0.86, 0.6))
			_outline(on, pond)
			for y: float in [-2.0, 2.5]:
				on.draw_line(Vector2(-5, y), Vector2(3, y), Color(1, 1, 1, 0.7), 1.0, true)
		&"spiral":
			var spiral := PackedVector2Array()
			for i: int in 60:
				spiral.append(Vector2.from_angle(i * 0.32) * (1.0 + i * 0.19))
			_pencil(on, spiral, false)
		&"question":
			var hook := PackedVector2Array()
			for i: int in 14:
				hook.append(
					Vector2(0, -6) + Vector2.from_angle(deg_to_rad(-200.0 + i * 18.0)) * 6.0
				)
			hook.append(Vector2(0, 5))
			_pencil(on, hook, false)
			on.draw_circle(Vector2(0, 10), 1.4, Color(LoyaltyArt.PENCIL, 0.7))
		&"arrow":
			var shaft := PackedVector2Array()
			for i: int in 12:
				var along := i / 11.0
				shaft.append(
					Vector2(lerpf(-13.0, 11.0, along), 8.0 - sin(along * PI) * 10.0 - along * 6.0)
				)
			_pencil(on, shaft, false)
			var tip := shaft[-1]
			_pencil(
				on, PackedVector2Array([tip + Vector2(-6, -2), tip, tip + Vector2(-3, 5)]), false
			)


static func _block(on: CanvasItem, rect: Rect2, fill: Color) -> void:
	on.draw_rect(rect, fill)
	on.draw_rect(rect, LINE, false, LINE_WIDTH)


static func _outline(on: CanvasItem, shape: PackedVector2Array) -> void:
	var closed := shape.duplicate()
	closed.append(shape[0])
	on.draw_polyline(closed, LINE, LINE_WIDTH, true)


## [param line] in Kit's pencil, gone over twice, closed where [param closed].
static func _pencil(on: CanvasItem, line: PackedVector2Array, closed: bool) -> void:
	var drawn := line.duplicate()
	if closed:
		drawn.append(line[0])
	on.draw_polyline(drawn, Color(LoyaltyArt.PENCIL, 0.65), 1.3, true)
	var again := PackedVector2Array()
	for point: Vector2 in drawn:
		again.append(point + Vector2(0.7, 0.6))
	on.draw_polyline(again, Color(LoyaltyArt.PENCIL, 0.25), 0.9, true)


static func _ellipse(middle: Vector2, radius: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in 24:
		points.append(middle + Vector2.from_angle(TAU * i / 24.0) * radius)
	return points
