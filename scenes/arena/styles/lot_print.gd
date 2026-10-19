class_name LotPrint
extends RefCounted
## The driving test's lot printed as the Department's traffic garden, GAME.md 8.1c and 9.4a, for
## [SchoolStyle]: drawn into the floor's printed layout under the House's own marks, so it costs
## nothing to draw. A ring road runs round the lot the way the lessons go, see [TestGround]: up
## the west through the lane of cones, east along the long run to the drift ring, down the east
## past the targets and back west along the south, a broken line down its middle and an arrow on
## each side the way the lessons go, wherever a side has room for one; the paint keeps off anything
## that stands on the road. Inside it a block of the Department's green kerbed in red and white,
## the Junction in the middle of it and the Jackpots and the Royal Flush pads either side, each a
## cell clear of the kerbs, and between the ring road and the walls a green verge. The trench and
## the pit are printed over like the rest, since their lids wear the print while they are shut,
## see [method Trench.lid_for], and nothing of them shows until they open. Kept to that: a first
## print with a street, a roundabout and a zebra round the Junction, and a street down the trench,
## read as too busy, and pieces standing across its kerbs and lines as untidy.
## None of it is anything to play: it is ink on the felt.

## How much of its ink the print lays on the felt, so the felt's grain still shows through it.
const INK := 0.9
const PAINT_INK := 0.85
## In cells, edge to edge: the ring road's outside, and the block of green it goes round.
const RING := Rect2(3.0, 2.0, 26.0, 14.0)
const BLOCK := Rect2(6.0, 5.0, 20.0, 8.0)
## How round the ring road's corners are, and the green's, in cells.
const RING_ROUND := 1.5
const GREEN_ROUND := 0.7
## A kerb: how wide it is, and how long one of its stones is, in cells.
const KERB := 0.2
const STONE := 1.0
## The paint: a line's width, and the broken line's dashes and gaps, in cells.
const LINE := 0.1
const DASH := 0.6
const GAP := 0.45
## The least a stone or a dash is stepped along, in cells.
const STEP_LEAST := 0.002
## How far the paint keeps off anything standing on the lot, and how much room an arrow wants
## clear round it, in cells.
const CLEAR := 0.45
const ARROW_ROOM := 1.1

var _on: LayoutPrint
var _lot: Rect2
## What stands on the lot, which the paint keeps off, see [method _find_pieces].
var _pieces: Array[Rect2] = []


## Whether [param grid] is the driving test's open lot: its size, and no wall inside its border.
static func fits(grid: ArenaGrid) -> bool:
	if grid == null or Rect2i(1, 1, grid.width - 2, grid.height - 2) != TestGround.LOT:
		return false
	for rect: Rect2i in grid.walls:
		if not grid.is_border(rect):
			return false
	return true


## Prints the traffic garden on [param on], in cells scaled to its pixels.
static func draw(on: LayoutPrint) -> void:
	var lot := LotPrint.new()
	lot._on = on
	lot._lot = Rect2(TestGround.LOT)
	lot._find_pieces(on.grid)
	on.unmarked = [TestGround.TRENCH, TestGround.PIT]
	on.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * LayoutPrint.CELL_PIXELS)
	lot._print()
	on.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _print() -> void:
	var green := Color(SchoolStyle.VERGE, INK)
	for piece: PackedVector2Array in _verge():
		_on.draw_colored_polygon(piece, green)
	for piece: PackedVector2Array in _block():
		_on.draw_colored_polygon(piece, green)
		_kerb(piece)
	_broken_line()
	var white := Color(SchoolStyle.PAINT, PAINT_INK)
	for side: Array in _sides():
		var at := _clearest(side[0], side[1])
		if _room(at) >= ARROW_ROOM:
			_arrow(at, side[2], white)


## The green between the ring road and the lot's walls: down the west and the east, each with the
## corners the ring road's rounding leaves, and along the north and the south between them.
func _verge() -> Array[PackedVector2Array]:
	var ring := _rounded(RING, RING_ROUND)
	var west := Rect2(
		_lot.position, Vector2(RING.position.x + RING_ROUND - _lot.position.x, _lot.size.y)
	)
	var east_from := RING.end.x - RING_ROUND
	var east := Rect2(east_from, _lot.position.y, _lot.end.x - east_from, _lot.size.y)
	var between := Vector2(west.end.x, east_from)
	var north := Rect2(
		between.x, _lot.position.y, between.y - between.x, RING.position.y - _lot.position.y
	)
	var south := Rect2(between.x, RING.end.y, between.y - between.x, _lot.end.y - RING.end.y)
	var pieces: Array[PackedVector2Array] = []
	for strip: Rect2 in [west, east, north, south]:
		pieces.append_array(_cut(_box(strip), ring))
	return pieces


## The block of green inside the ring road, its corners rounded: shrunk, then grown back round.
func _block() -> Array[PackedVector2Array]:
	var rounded: Array[PackedVector2Array] = []
	for small: PackedVector2Array in Geometry2D.offset_polygon(_box(BLOCK), -GREEN_ROUND):
		rounded.append_array(Geometry2D.offset_polygon(small, GREEN_ROUND, Geometry2D.JOIN_ROUND))
	return rounded


## The red and white stones round [param piece] of green, just inside it, but not along the lot's
## walls, which are the House's rail.
func _kerb(piece: PackedVector2Array) -> void:
	for inside: PackedVector2Array in Geometry2D.offset_polygon(piece, -KERB * 0.5):
		var along := 0.0
		for i: int in inside.size():
			var from := inside[i]
			var to := inside[(i + 1) % inside.size()]
			var length := from.distance_to(to)
			if not _kerbed(from, to):
				along += length
				continue
			var done := 0.0
			while done < length - 0.001:
				var stone := floorf((along + done) / STONE)
				var step := minf((stone + 1.0) * STONE - (along + done), length - done)
				# Never nothing: landing on a stone's end exactly would otherwise step no further.
				step = maxf(step, STEP_LEAST)
				var red := int(stone) % 2 == 0
				var color := SchoolStyle.KERB_RED if red else SchoolStyle.KERB_WHITE
				_on.draw_line(
					from.lerp(to, done / length),
					from.lerp(to, (done + step) / length),
					Color(color, INK),
					KERB
				)
				done += step
			along += length


## Whether the edge from [param from] to [param to] is kerbed: not along a wall.
func _kerbed(from: Vector2, to: Vector2) -> bool:
	for at: float in [_lot.position.x, _lot.end.x]:
		if absf(from.x - at) < KERB and absf(to.x - at) < KERB:
			return false
	for at: float in [_lot.position.y, _lot.end.y]:
		if absf(from.y - at) < KERB and absf(to.y - at) < KERB:
			return false
	return true


## The broken line down the middle of the ring road, short of whatever stands on it.
func _broken_line() -> void:
	var from := (RING.position + BLOCK.position) * 0.5
	var middle := Rect2(from, (RING.end + BLOCK.end) * 0.5 - from)
	var path := _rounded(middle, RING_ROUND * 0.75)
	var white := Color(SchoolStyle.PAINT, PAINT_INK)
	var along := 0.0
	for i: int in path.size():
		var start := path[i]
		var to := path[(i + 1) % path.size()]
		var length := start.distance_to(to)
		var done := 0.0
		while done < length - 0.001:
			var phase := fmod(along + done, DASH + GAP)
			var step := minf((DASH if phase < DASH else DASH + GAP) - phase, length - done)
			step = maxf(step, STEP_LEAST)
			var a := start.lerp(to, done / length)
			var b := start.lerp(to, (done + step) / length)
			if phase < DASH and _room((a + b) * 0.5) > CLEAR:
				_on.draw_line(a, b, white, LINE)
			done += step
		along += length


## What stands on the lot that the paint keeps off, in cells: the map's pieces but for the trench
## and the pit, which are lidded and printed over till they open, and the lessons' own spots, the
## start, the mode pads, the item box, the parked kart and its bay, the lane of cones and the
## crossing over it; and the rings of cones, by their middles.
func _find_pieces(grid: ArenaGrid) -> void:
	var lidded := [Rect2(TestGround.TRENCH), Rect2(TestGround.PIT)]
	for y: int in grid.height:
		for x: int in grid.width:
			var cell := Vector2i(x, y)
			var glyph := grid.glyph(cell)
			if glyph == ArenaGrid.FLOOR or glyph == ArenaGrid.WALL:
				continue
			var middle := Vector2(cell) + Vector2.ONE * 0.5
			if lidded.any(func(rect: Rect2) -> bool: return rect.has_point(middle)):
				continue
			_pieces.append(Rect2(Vector2(cell), Vector2.ONE))
	var spots: Array[Vector2i] = [
		TestGround.START, TestGround.SIMPLE_PAD, TestGround.ADVANCED_PAD, TestGround.ITEM_BOX
	]
	spots.append_array(TestGround.LANE)
	for spot: Vector2i in spots:
		_pieces.append(Rect2(Vector2(spot), Vector2.ONE))
	_pieces.append(Rect2(SchoolProps.BAY))
	_pieces.append(Rect2(SchoolProps.CROSSING))
	var reach := TestGround.RING_RADIUS / grid.cell_size
	for ring: Vector2i in [TestGround.ROUNDABOUT, TestGround.DRIFT_RING]:
		var middle := Vector2(ring) + Vector2.ONE * 0.5
		_pieces.append(Rect2(middle - Vector2.ONE * reach, Vector2.ONE * reach * 2.0))


## How far [param at] is from the nearest thing standing on the lot, in cells.
func _room(at: Vector2) -> float:
	var least := INF
	for piece: Rect2 in _pieces:
		var nearest := at.clamp(piece.position, piece.end)
		least = minf(least, at.distance_to(nearest))
	return least


## The ring road's four straight sides down its middle, the way the lessons go round: each from
## where to where, and which way.
func _sides() -> Array[Array]:
	var west := (RING.position.x + BLOCK.position.x) * 0.5
	var east := (RING.end.x + BLOCK.end.x) * 0.5
	var north := (RING.position.y + BLOCK.position.y) * 0.5
	var south := (RING.end.y + BLOCK.end.y) * 0.5
	return [
		[Vector2(west, BLOCK.end.y), Vector2(west, BLOCK.position.y), Vector2.UP],
		[Vector2(BLOCK.position.x, north), Vector2(BLOCK.end.x, north), Vector2.RIGHT],
		[Vector2(east, BLOCK.position.y), Vector2(east, BLOCK.end.y), Vector2.DOWN],
		[Vector2(BLOCK.end.x, south), Vector2(BLOCK.position.x, south), Vector2.LEFT],
	]


## The point between [param from] and [param to] with the most room round it, off the lids of
## the trench and the pit, which drop away with whatever is printed on them.
func _clearest(from: Vector2, to: Vector2) -> Vector2:
	var lids := [Rect2(TestGround.TRENCH).grow(ARROW_ROOM), Rect2(TestGround.PIT).grow(ARROW_ROOM)]
	var best := from
	var steps := int(from.distance_to(to) / 0.25)
	for i: int in steps + 1:
		var at := from.lerp(to, float(i) / float(maxi(steps, 1)))
		if lids.any(func(lid: Rect2) -> bool: return lid.has_point(at)):
			continue
		if _room(at) > _room(best):
			best = at
	return best


## An arrow at [param at] pointing [param toward], a cell and a bit long.
func _arrow(at: Vector2, toward: Vector2, white: Color) -> void:
	var side := Vector2(-toward.y, toward.x)
	_on.draw_line(at - toward * 0.6, at + toward * 0.1, white, 0.16)
	var head := PackedVector2Array(
		[at + toward * 0.6, at + toward * 0.1 + side * 0.3, at + toward * 0.1 - side * 0.3]
	)
	_on.draw_colored_polygon(head, white)


## [param piece] with [param cutter] taken out of it, in as many pieces as that leaves. The ring
## road reaches out past every strip it cuts, so none is left with a hole.
static func _cut(
	piece: PackedVector2Array, cutter: PackedVector2Array
) -> Array[PackedVector2Array]:
	var left: Array[PackedVector2Array] = []
	left.assign(Geometry2D.clip_polygons(piece, cutter))
	return left


static func _box(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array(
		[
			rect.position,
			Vector2(rect.end.x, rect.position.y),
			rect.end,
			Vector2(rect.position.x, rect.end.y)
		]
	)


## [param rect] with its corners rounded [param radius].
static func _rounded(rect: Rect2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var corners: Array[Vector2] = [
		Vector2(rect.end.x - radius, rect.position.y + radius),
		Vector2(rect.end.x - radius, rect.end.y - radius),
		Vector2(rect.position.x + radius, rect.end.y - radius),
		Vector2(rect.position.x + radius, rect.position.y + radius),
	]
	for k: int in 4:
		for i: int in 9:
			var angle := -PI * 0.5 + PI * 0.5 * (float(k) + float(i) / 8.0)
			points.append(corners[k] + Vector2.from_angle(angle) * radius)
	return points
