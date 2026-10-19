class_name LotPrint
extends RefCounted
## The driving test's lot printed as the Department's traffic garden, GAME.md 8.1c and 9.4a, for
## [SchoolStyle]: drawn into the floor's printed layout under the House's own marks, so it costs
## nothing to draw. A ring road runs round the lot the way the lessons go, see [TestGround]: up
## the west through the lane of cones, round the ring of cones in the corner, east along the long
## run to the drift ring, down the east past the targets and back west along the south. A street
## runs down the trench, so its lid is road while it is shut and its painted rim the street's
## kerbs, and a short street runs from the south road to a roundabout round the Junction, its
## island green until the Junction comes down onto it. The rest is the Department's green, each
## piece of it kerbed in red and white. A broken line runs down the middle of the ring road, the
## rings of cones are printed under their cones, arrows point the way the lessons go, and a zebra
## and give-way teeth lie where the south street meets the roundabout.
## None of it is anything to play: it is ink on the felt.

## How much of its ink the print lays on the felt, so the felt's grain still shows through it.
const INK := 0.9
const PAINT_INK := 0.85
## In cells, edge to edge: the ring road's outside, and the block of green it goes round.
const RING := Rect2(3.0, 2.0, 27.0, 14.0)
const BLOCK := Rect2(6.0, 5.0, 20.0, 8.0)
## How round the ring road's corners are, and the green's, in cells.
const RING_ROUND := 1.5
const GREEN_ROUND := 0.7
## The street up the middle from the south road and through the roundabout, and how far out from
## the Junction's middle the roundabout's road goes, in cells.
const STREET := Rect2(13.0, 4.5, 2.0, 9.0)
const ROUNDABOUT_OUT := 3.2
## A kerb: how wide it is, and how long one of its stones is, in cells.
const KERB := 0.2
const STONE := 0.5
## The paint: a line's width, and the broken line's dashes and gaps, in cells.
const LINE := 0.1
const DASH := 0.6
const GAP := 0.45
## The least a stone or a dash is stepped along, in cells.
const STEP_LEAST := 0.002
## How far from a ring of cones the broken line stops short.
const RING_CLEAR := 1.8
## The arrows the way the lessons go: where each is, in cells, and which way it points.
const ARROWS: Array[Array] = [
	[Vector2(9.0, 3.5), Vector2.RIGHT],
	[Vector2(24.0, 3.5), Vector2.RIGHT],
	[Vector2(28.0, 6.0), Vector2.DOWN],
	[Vector2(16.5, 14.5), Vector2.LEFT],
	[Vector2(25.0, 14.3), Vector2.LEFT],
]
## Where the street meets the roundabout: the zebra's top and depth, and the give-way teeth's.
const ZEBRA_AT := 12.05
const ZEBRA_DEEP := 0.8
const TEETH_AT := 11.35
const TEETH_DEEP := 0.35

var _on: LayoutPrint
var _lot: Rect2
var _trench: Rect2


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
	lot._trench = Rect2(TestGround.TRENCH)
	on.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * LayoutPrint.CELL_PIXELS)
	lot._print()
	on.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _print() -> void:
	var green := Color(SchoolStyle.VERGE, INK)
	for piece: PackedVector2Array in _verge():
		_on.draw_colored_polygon(piece, green)
		_kerb(piece)
	for piece: PackedVector2Array in _islands():
		_on.draw_colored_polygon(piece, green)
		_kerb(piece)
	# The roundabout's island, green until the Junction comes down onto it.
	var junction := Rect2(TestGround.JUNCTION_RECT)
	var island := _disc(junction.get_center(), junction.size.x * 0.5)
	_on.draw_colored_polygon(island, green)
	_kerb(island)
	_broken_line()
	var white := Color(SchoolStyle.PAINT, PAINT_INK)
	var cone_ring := TestGround.RING_RADIUS / _on.grid.cell_size
	for ring: Vector2 in _cone_rings():
		_on.draw_arc(ring, cone_ring, 0.0, TAU, 48, white, LINE)
	_on.draw_circle(_cone_rings()[0], 0.32, white)
	for arrow: Array in ARROWS:
		_arrow(arrow[0], arrow[1], white)
	_crossing(white)


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
		for piece: PackedVector2Array in Geometry2D.clip_polygons(_box(strip), ring):
			pieces.append_array(_cut(piece, _box(_trench)))
	return pieces


## The block of green inside the ring road, cut by the street, the trench's street and the
## roundabout, each piece's corners rounded.
func _islands() -> Array[PackedVector2Array]:
	var middle := Rect2(TestGround.JUNCTION_RECT).get_center()
	var pieces: Array[PackedVector2Array] = [_box(BLOCK)]
	for cutter: PackedVector2Array in [_box(STREET), _box(_trench), _disc(middle, ROUNDABOUT_OUT)]:
		var cut: Array[PackedVector2Array] = []
		for piece: PackedVector2Array in pieces:
			cut.append_array(_cut(piece, cutter))
		pieces = cut
	var rounded: Array[PackedVector2Array] = []
	for piece: PackedVector2Array in pieces:
		for small: PackedVector2Array in Geometry2D.offset_polygon(piece, -GREEN_ROUND):
			for grown: PackedVector2Array in Geometry2D.offset_polygon(
				small, GREEN_ROUND, Geometry2D.JOIN_ROUND
			):
				rounded.append(grown)
	return rounded


## The red and white stones round [param piece] of green, just inside it, but not along the lot's
## walls, which are the House's rail, nor the trench's sides, which have their own painted rim.
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


## Whether the edge from [param from] to [param to] is kerbed: not along a wall nor the trench.
func _kerbed(from: Vector2, to: Vector2) -> bool:
	for at: float in [_lot.position.x, _lot.end.x, _trench.position.x, _trench.end.x]:
		if absf(from.x - at) < KERB and absf(to.x - at) < KERB:
			return false
	for at: float in [_lot.position.y, _lot.end.y]:
		if absf(from.y - at) < KERB and absf(to.y - at) < KERB:
			return false
	return true


## The broken line down the middle of the ring road, stopping short of the rings of cones.
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
			if phase < DASH and _clear((a + b) * 0.5):
				_on.draw_line(a, b, white, LINE)
			done += step
		along += length


## Whether the broken line may be painted at [param at]: clear of the rings of cones.
func _clear(at: Vector2) -> bool:
	for ring: Vector2 in _cone_rings():
		if at.distance_to(ring) < RING_CLEAR:
			return false
	return true


## The middles of the two rings of cones, the roundabout's in the corner and the drift ring.
func _cone_rings() -> Array[Vector2]:
	return [
		Vector2(TestGround.ROUNDABOUT) + Vector2.ONE * 0.5,
		Vector2(TestGround.DRIFT_RING) + Vector2.ONE * 0.5,
	]


## An arrow at [param at] pointing [param toward], a cell and a bit long.
func _arrow(at: Vector2, toward: Vector2, white: Color) -> void:
	var side := Vector2(-toward.y, toward.x)
	_on.draw_line(at - toward * 0.6, at + toward * 0.1, white, 0.16)
	var head := PackedVector2Array(
		[at + toward * 0.6, at + toward * 0.1 + side * 0.3, at + toward * 0.1 - side * 0.3]
	)
	_on.draw_colored_polygon(head, white)


## The zebra across the street where it leaves the south road, and the give-way teeth at the
## roundabout, pointing at whoever comes up the street.
func _crossing(white: Color) -> void:
	var stripes := 4
	var stripe := STREET.size.x / float(stripes)
	for i: int in stripes:
		var x := STREET.position.x + stripe * (float(i) + 0.25)
		_on.draw_rect(Rect2(x, ZEBRA_AT, stripe * 0.5, ZEBRA_DEEP), white)
	var teeth := 4
	var tooth := STREET.size.x / float(teeth)
	for i: int in teeth:
		var left := STREET.position.x + tooth * float(i) + tooth * 0.12
		var right := left + tooth * 0.76
		var triangle := PackedVector2Array(
			[
				Vector2(left, TEETH_AT),
				Vector2(right, TEETH_AT),
				Vector2((left + right) * 0.5, TEETH_AT + TEETH_DEEP),
			]
		)
		_on.draw_colored_polygon(triangle, white)


## [param piece] with [param cutter] taken out of it, in as many pieces as that leaves. Every
## cutter here reaches out past the piece it cuts, so none leaves a hole.
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


static func _disc(middle: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in 48:
		points.append(middle + Vector2.from_angle(TAU * float(i) / 48.0) * radius)
	return points


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
