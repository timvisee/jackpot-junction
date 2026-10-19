class_name PinballInserts
extends RefCounted
## The Arcade's inserts, GAME.md 8.1c: the lamps a pinball playfield has let into it, printed into
## the playfield's own picture ([PinballPrints]) so they glow with the coat it lights from under,
## [constant PinballStyle.FIELD_GLOW], at no cost but the picture. About half of them are lit, as
## the round-two mock-up had the machine mid-game, the rest dark plastic that still reads.
##
## Each is laid out round the pieces, never under one or across one: a lit ring of the coin's blue
## round every coin pad, a warm disc under every item pad, an amber rim round every turbo plate,
## the lane a turbo pad fires down printed as a lane, two guide lines along it broken round whatever
## stands in it and a run of three chevrons pointing the way, brightest by the plate; a lit arrow
## pointing each Jackpot out from the Junction's side; a dashed DRAIN frame round each drain; and
## under each three of pop bumpers a teal panel, keylined, a star in its middle. Drawn in cells, at
## [param cell] pixels a cell.

## The inks: the coin's blue and the item's warm white, lit and dark; the turbos' amber, lit, dim
## and dark; the arrows' warm white; the lane guides' cream; and the panels' teal, ochre and ink.
const COIN_LIT := Color("#5C8FD6")
const COIN_DARK := Color("#26375A")
const ITEM_LIT := Color("#EFC983")
const ITEM_DARK := Color("#5E4A33")
const AMBER_LIT := Color("#D99A3F")
const AMBER_DIM := Color("#8E6230")
const AMBER_DARK := Color("#4E3424")
const ARROW := Color("#CBB58A")
const GUIDE := Color(0.906, 0.855, 0.729, 0.42)
const TEAL := Color("#1F414E")
const OCHRE := Color("#C4943F")
const INK := Color("#141017")
## How far round each kind of piece the inserts keep, in cells, from its middle.
const KEEP: Dictionary[String, float] = {
	"C": 0.56,
	"P": 0.66,
	"S": 0.5,
	"s": 0.5,
	"F": 0.72,
	"$": 0.8,
	"B": 0.72,
	"@": 0.6,
	"R": 0.6,
	"D": 0.6,
}
## The coin pad's chip is this far across, in cells, and its ring of light goes out to this.
const CHIP := 0.4
const CHIP_RING := 0.47
## An item pad's disc, and the halo round a lit insert, in cells.
const ITEM_DISC := 0.62
const HALO := 0.9
## A lane's chevrons: how many, how long along the lane and across it, how thick their arms are.
const CHEVRONS := 3
const CHEVRON_ALONG := 0.44
const CHEVRON_ACROSS := 1.3
const CHEVRON_ARM := 0.17
## How far in from a lane's sides its guides are, and how thick, in cells.
const GUIDE_IN := 0.08
const GUIDE_WIDTH := 0.06
## A Jackpot's arrow: how far off the Jackpot it starts, how long it is and how tall its head.
const ARROW_OFF := 0.9
const ARROW_LONG := 1.8
const ARROW_HEAD := 0.9
## How far out of a drain its frame is drawn, in cells.
const DRAIN_OUT := 0.36
const FONT := preload("res://assets/fonts/BarlowCondensed-Black.ttf")


## Every insert of [param grid] onto [param on], [param cell] pixels a cell.
static func draw(on: CanvasItem, grid: ArenaGrid, cell: float) -> void:
	var keep := _keep_outs(grid)
	_panels(on, grid, cell)
	_drains(on, grid, cell)
	for guide: Array in guides(grid):
		_guide(on, grid, guide[0], guide[1], cell, keep)
	for chevron: Array in chevrons(grid):
		var k: int = chevron[3]
		var ink: Color = [AMBER_LIT, AMBER_DIM, AMBER_DARK][k]
		_chevron(on, chevron[0], chevron[1], chevron[2], cell, ink, k == 0)
	for section: Rect2i in grid.turbo_sections():
		_plate(on, section, cell)
	for i: int in grid.coin_pads.size():
		var lit := _lit(i, grid.coin_pads.size())
		_coin(on, _middle(grid.coin_pads[i]) * cell, cell, lit)
	for i: int in grid.power_pads.size():
		var lit := _lit(i, grid.power_pads.size())
		_item(on, _middle(grid.power_pads[i]) * cell, cell, lit)
	for arrow: Array in arrows(grid):
		_arrow(on, arrow[0], arrow[1], cell)


## The guides along the lanes the turbo pads fire down, see [method _lane], each as its two ends
## in cells: one down each side of a lane, a lane two pads fire down from either end having one of
## each.
static func guides(grid: ArenaGrid) -> Array[Array]:
	var found: Dictionary[String, Array] = {}
	for section: Rect2i in grid.turbo_sections():
		var lane := _lane(grid, section)
		if lane.is_empty():
			continue
		var box: Rect2 = lane["box"]
		var across := Vector2(lane["across"])
		var long := Vector2((lane["way"] as Vector2i).abs())
		for side: float in [0.0, 1.0]:
			var inward := Vector2.ONE * GUIDE_IN * (1.0 - side * 2.0)
			var a := box.position + across * (box.size * side + inward)
			var b := a + long * box.size
			found["%.2f,%.2f,%.2f,%.2f" % [a.x, a.y, b.x, b.y]] = [a, b]
	var out: Array[Array] = []
	out.assign(found.values())
	return out


## The chevrons down the lanes, as [middle in cells, the way it points, how wide its lane is, its
## place in its run from the plate]: a run of [constant CHEVRONS] for each turbo section, in the
## first stretch of its own half of the lane clear for all of them, or none.
static func chevrons(grid: ArenaGrid) -> Array[Array]:
	var keep := _keep_outs(grid)
	var out: Array[Array] = []
	for section: Rect2i in grid.turbo_sections():
		var lane := _lane(grid, section)
		if lane.is_empty():
			continue
		var way: Vector2i = lane["way"]
		var wide: int = lane["wide"]
		var line: Vector2 = lane["line"]
		for first: int in range(0, maxi(int(lane["run"]) / 2 - CHEVRONS + 1, 0)):
			var spots: Array[Array] = []
			for k: int in CHEVRONS:
				var at := line + Vector2(way) * float(first + k)
				if not _clear(grid, chevron_box(at, way, wide), keep):
					break
				spots.append([at, way, wide, k])
			if spots.size() == CHEVRONS:
				out.append_array(spots)
				break
	return out


## The arrows pointing the Jackpots out, as [tip, tail] in cells: one on each Jackpot's middle
## line, from the side the Junction is on, where the floor there is clear.
static func arrows(grid: ArenaGrid) -> Array[Array]:
	var keep := _keep_outs(grid)
	var out: Array[Array] = []
	if grid.junctions.is_empty():
		return out
	for rect: Rect2i in grid.jackpots:
		var middle := Vector2(rect.position) + Vector2(rect.size) * 0.5
		var toward := Vector2(grid.junction.get_center()) - middle
		if absf(toward.x) < absf(toward.y):
			continue
		var way := Vector2(signf(toward.x), 0.0)
		var tip := middle + way * (float(rect.size.x) * 0.5 + ARROW_OFF)
		var tail := tip + way * ARROW_LONG
		if _clear(grid, arrow_box(tip, tail), keep):
			out.append([tip, tail])
	return out


## What an arrow from [param tip] to [param tail] covers, in cells.
static func arrow_box(tip: Vector2, tail: Vector2) -> Rect2:
	var half := ARROW_HEAD * 0.5
	return Rect2(tip, Vector2.ZERO).expand(tail).grow_individual(0.0, half, 0.0, half)


## Whether the [param i]th of [param count] pieces of a kind is lit: every other pair, a piece and
## its twin across the middle of the room alike, as the map is laid out by twins.
static func _lit(i: int, count: int) -> bool:
	return mini(i, count - 1 - i) % 2 == 0


static func _middle(cell: Vector2i) -> Vector2:
	return Vector2(cell) + Vector2.ONE * 0.5


## The circles round the pieces the inserts keep clear of, as [middle, reach] in cells.
static func _keep_outs(grid: ArenaGrid) -> Array[Array]:
	var keep: Array[Array] = []
	for y: int in grid.height:
		for x: int in grid.width:
			var glyph := grid.glyph(Vector2i(x, y))
			if KEEP.has(glyph):
				keep.append([_middle(Vector2i(x, y)), KEEP[glyph]])
	return keep


## Whether [param rect], in cells, lies on open floor clear of every piece.
static func _clear(grid: ArenaGrid, rect: Rect2, keep: Array[Array]) -> bool:
	for y: int in range(floori(rect.position.y), ceili(rect.end.y)):
		for x: int in range(floori(rect.position.x), ceili(rect.end.x)):
			if x < 0 or y < 0 or x >= grid.width or y >= grid.height:
				return false
			if grid.glyph(Vector2i(x, y)) != ArenaGrid.FLOOR:
				return false
	for spot: Array in keep:
		var middle: Vector2 = spot[0]
		var nearest := middle.clamp(rect.position, rect.end)
		if nearest.distance_to(middle) < float(spot[1]):
			return false
	return true


## A ring of the coin's blue round the chip at [param at], and a halo on the coat round a lit one.
static func _coin(on: CanvasItem, at: Vector2, cell: float, lit: bool) -> void:
	if lit:
		_halo(on, at, HALO * cell * 1.1, COIN_LIT, 0.36)
	var ink := COIN_LIT if lit else COIN_DARK
	on.draw_circle(at, CHIP_RING * cell + 2.0, INK, true, -1.0, true)
	on.draw_circle(at, CHIP_RING * cell, ink, true, -1.0, true)
	on.draw_circle(at, CHIP * cell, ink.darkened(0.35), true, -1.0, true)


## A warm disc under the ticket at [param at], showing round its sides, and its halo when lit.
static func _item(on: CanvasItem, at: Vector2, cell: float, lit: bool) -> void:
	if lit:
		_halo(on, at, (HALO + 0.25) * cell, ITEM_LIT, 0.22)
	on.draw_circle(at, ITEM_DISC * cell + 2.0, INK, true, -1.0, true)
	on.draw_circle(at, ITEM_DISC * cell, ITEM_LIT if lit else ITEM_DARK, true, -1.0, true)


## A lit amber rim round the turbo plate of [param section], and the amber its light throws on the
## coat round it.
static func _plate(on: CanvasItem, section: Rect2i, cell: float) -> void:
	var rect := Rect2(Vector2(section.position) * cell, Vector2(section.size) * cell)
	var middle := rect.get_center()
	_halo(on, middle, maxf(rect.size.x, rect.size.y) * 0.5 + cell * 0.6, AMBER_LIT, 0.28)
	var rim := StyleBoxFlat.new()
	rim.bg_color = AMBER_LIT
	rim.set_corner_radius_all(int(cell * 0.12))
	rim.border_color = INK
	rim.set_border_width_all(2)
	on.draw_style_box(rim, rect.grow(cell * 0.06))


## The lane [param section] fires down, as far as it is open floor: as a box of cells, the way it
## fires, the way across it, how wide it is, how many rows it runs, and the line down its middle
## its chevrons stand on, in cells; or nothing, for a pad that fires into a wall.
static func _lane(grid: ArenaGrid, section: Rect2i) -> Dictionary:
	var way3 := grid.turbo_direction(section.position)
	var way := Vector2i(roundi(way3.x), roundi(way3.z))
	var across := Vector2i(absi(way.y), absi(way.x))
	var wide := section.size.x if across.x != 0 else section.size.y
	# The first row of cells past the plate, and how many rows the lane runs on for.
	var start := section.position + way
	if way.x > 0:
		start.x = section.end.x
	elif way.y > 0:
		start.y = section.end.y
	var run := 0
	while _open_row(grid, start + way * run, across, wide):
		run += 1
	if run <= 0:
		return {}
	var row := across * wide + way.abs()
	var cells := Rect2i(start, row).merge(Rect2i(start + way * (run - 1), row))
	var line := Vector2(start) + Vector2(across) * float(wide) * 0.5 + Vector2(way.abs()) * 0.5
	return {
		"box": Rect2(Vector2(cells.position), Vector2(cells.size)),
		"way": way,
		"across": across,
		"wide": wide,
		"run": run,
		"line": line,
	}


## Whether the row of [param wide] cells across from [param at] is open floor a turbo lane runs on.
static func _open_row(grid: ArenaGrid, at: Vector2i, across: Vector2i, wide: int) -> bool:
	for i: int in wide:
		var cell := at + across * i
		if cell.x < 0 or cell.y < 0 or cell.x >= grid.width or cell.y >= grid.height:
			return false
		var glyph := grid.glyph(cell)
		if glyph in [ArenaGrid.WALL, ArenaGrid.CRATE, ArenaGrid.PIT, ArenaGrid.BUMPER]:
			return false
		if glyph in ArenaGrid.TURBO_GLYPHS:
			return false
	return true


## The cells a chevron at [param at], in cells, takes up, pointing [param way] down a lane
## [param wide] cells across.
static func chevron_box(at: Vector2, way: Vector2i, wide: int) -> Rect2:
	var half_across := _across(wide) * 0.5
	var half_along := CHEVRON_ALONG * 0.5 + CHEVRON_ARM * 0.5
	var half := Vector2(half_along, half_across) if way.x != 0 else Vector2(half_across, half_along)
	return Rect2(at - half, half * 2.0)


## How far across a lane [param wide] cells wide its chevrons reach.
static func _across(wide: int) -> float:
	return minf(CHEVRON_ACROSS, float(wide) * 0.7)


## A chevron of [param ink] at [param at], in cells, pointing [param way] down a lane [param wide]
## cells across, keylined in ink, with a halo when [param lit].
static func _chevron(
	on: CanvasItem, at: Vector2, way: Vector2i, wide: int, cell: float, ink: Color, lit: bool
) -> void:
	var middle := at * cell
	var along := Vector2(way) * cell
	var side := Vector2(-way.y, way.x) * cell
	var tip := middle + along * (CHEVRON_ALONG * 0.5)
	var back := middle - along * (CHEVRON_ALONG * 0.5)
	var arm := CHEVRON_ARM
	var reach := _across(wide) * 0.5
	var outline := PackedVector2Array(
		[
			tip,
			back + side * reach,
			back + side * reach - along * arm,
			tip - along * arm,
			back - side * reach - along * arm,
			back - side * reach,
		]
	)
	if lit:
		_halo(on, middle, cell * 0.75, ink, 0.24)
	var keyline := PackedVector2Array(outline)
	keyline.append(outline[0])
	on.draw_colored_polygon(outline, ink)
	on.draw_polyline(keyline, INK, 2.0, true)


## A lane's guide from [param a] to [param b], in cells, broken round anything it would cross.
static func _guide(
	on: CanvasItem, grid: ArenaGrid, a: Vector2, b: Vector2, cell: float, keep: Array[Array]
) -> void:
	var steps := ceili(a.distance_to(b) / 0.1)
	var from := -1
	for i: int in steps + 1:
		var at := a.lerp(b, float(i) / float(steps))
		var open := _clear(grid, Rect2(at - Vector2.ONE * 0.05, Vector2.ONE * 0.1), keep)
		if open and from < 0:
			from = i
		if (not open or i == steps) and from >= 0:
			var until := i if open else i - 1
			if until > from:
				var p := a.lerp(b, float(from) / float(steps)) * cell
				var q := a.lerp(b, float(until) / float(steps)) * cell
				on.draw_line(p, q, GUIDE, GUIDE_WIDTH * cell, true)
			from = -1


## A lit arrow of warm white from [param tip] to [param tail], in cells, keylined in ink, and its
## halo on the coat.
static func _arrow(on: CanvasItem, tip: Vector2, tail: Vector2, cell: float) -> void:
	var out := (tail - tip).normalized()
	var head := ARROW_HEAD * 0.5
	var neck := tip + out * ARROW_HEAD * 0.7
	var shaft := head * 0.45
	var up := Vector2(-out.y, out.x)
	var points := PackedVector2Array(
		[
			tip,
			neck + up * head,
			neck + up * shaft,
			tail + up * shaft,
			tail - up * shaft,
			neck - up * shaft,
			neck - up * head,
		]
	)
	for i: int in points.size():
		points[i] *= cell
	_halo(on, (tip + tail) * 0.5 * cell, cell * 1.3, ARROW, 0.2)
	var keyline := PackedVector2Array(points)
	keyline.append(points[0])
	on.draw_colored_polygon(points, ARROW)
	on.draw_polyline(keyline, INK, 2.5, true)


## A dashed ochre frame round every drain, and DRAIN under it where the floor is clear.
static func _drains(on: CanvasItem, grid: ArenaGrid, cell: float) -> void:
	for pit: Rect2i in grid.pits:
		var frame := Rect2(Vector2(pit.position), Vector2(pit.size)).grow(DRAIN_OUT)
		var corners := [
			frame.position,
			Vector2(frame.end.x, frame.position.y),
			frame.end,
			Vector2(frame.position.x, frame.end.y),
		]
		for i: int in 4:
			var a: Vector2 = corners[i] * cell
			var b: Vector2 = corners[(i + 1) % 4] * cell
			on.draw_dashed_line(a, b, Color(OCHRE, 0.45), 3.0, cell * 0.22, true, true)
		var font_size := int(cell * 0.42)
		var words := "DRAIN"
		var width := FONT.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var at := Vector2(frame.get_center().x * cell - width * 0.5, (frame.end.y + 0.55) * cell)
		on.draw_string(FONT, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(OCHRE, 0.5))


## Under each three of pop bumpers a teal panel round all three, keylined in ink with an ochre rule
## inside it, and an ochre star in its middle.
static func _panels(on: CanvasItem, grid: ArenaGrid, cell: float) -> void:
	var placed: Dictionary[Vector2i, bool] = {}
	for start: Vector2i in grid.bumpers:
		if placed.has(start):
			continue
		var three: Array[Vector2i] = [start]
		for other: Vector2i in grid.bumpers:
			var apart := maxi(absi(other.x - start.x), absi(other.y - start.y))
			if other != start and apart <= 2:
				three.append(other)
		for member: Vector2i in three:
			placed[member] = true
		var corners := PackedVector2Array()
		var middle := Vector2.ZERO
		for member: Vector2i in three:
			corners.append(_middle(member) * cell)
			middle += _middle(member) * cell / float(three.size())
		if three.size() < 3:
			continue
		var outer := Geometry2D.offset_polygon(corners, cell * 0.95, Geometry2D.JOIN_ROUND)
		var inner := Geometry2D.offset_polygon(corners, cell * 0.82, Geometry2D.JOIN_ROUND)
		if outer.is_empty() or inner.is_empty():
			continue
		var edge := Geometry2D.offset_polygon(corners, cell * 0.95 + 3.0, Geometry2D.JOIN_ROUND)
		on.draw_colored_polygon(edge[0], INK)
		on.draw_colored_polygon(outer[0], TEAL)
		var rule := PackedVector2Array(inner[0])
		rule.append(inner[0][0])
		on.draw_polyline(rule, Color(OCHRE, 0.7), 2.0, true)
		PinballInserts._star(on, middle, cell * 0.32, OCHRE)


## A four-pointed sparkle.
static func _star(on: CanvasItem, at: Vector2, reach: float, ink: Color) -> void:
	var points := PackedVector2Array()
	for i: int in 8:
		var r := reach if i % 2 == 0 else reach * 0.3
		points.append(at + Vector2.from_angle(PI * 0.25 * float(i) - PI * 0.5) * r)
	on.draw_colored_polygon(points, ink)


## The soft light a lit insert throws on the coat round it.
static func _halo(on: CanvasItem, at: Vector2, reach: float, light: Color, strength: float) -> void:
	var sides := 32
	for i: int in sides:
		var a := at + Vector2.from_angle(TAU * float(i) / float(sides)) * reach
		var b := at + Vector2.from_angle(TAU * float(i + 1) / float(sides)) * reach
		on.draw_polygon(
			PackedVector2Array([at, a, b]),
			PackedColorArray([Color(light, strength), Color(light, 0.0), Color(light, 0.0)])
		)
