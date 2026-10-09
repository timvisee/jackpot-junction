class_name LoyaltyMapLayout
extends RefCounted
## Where everything on the loyalty program's map goes, GAME.md 8.9, worked out once from the grid
## of [LoyaltyMap] for one profile's map, on the paper at a zoom of one, for [LoyaltyMapView] to
## draw and its cursor to drive.
##
## The grid says what joins what; the paper is a map rather than the grid. A column with a landmark
## in it is wide and the rest narrow, a row with one tall and the rest short, so a run of road
## between two landmarks is a road rather than a row of characters. Each landmark stands a little
## off its place on the grid and each bend a little off its own, the same way every time; a road
## runs from one to the next through its bends, wandering a little on a long stretch, its corners
## rounded off; each sign is as wide as its name. Each district is a wash of its own color round
## its landmarks, its edge drawn by hand; the empty paper between has the little drawings a road
## map has, the house's on the Strip, the Department's beside its roads, Kit's in pencil; and there
## is a compass over the roundabout, a legend in one corner and the house's title in the other.
##
## It is laid out a sheet at a time, see [enum Sheet]: the House's printed map, the Strip and the
## Department and the roundabout between them; and Kit's, off the books on a sheet of graph paper
## of its own, the two roads of it that run on into the House's districts running off its foot.

## The map's two sheets: the House's, and Kit's, off the books.
enum Sheet { HOUSE, KIT }

## How wide a column of the grid with a landmark in it is, and one without, and how tall a row with
## one and a row without; and the paper round the grid, room for the legend and the title under it.
const WIDE := 180.0
const NARROW := 12.0
const TALL := 134.0
const SHORT := 44.0
const MARGIN := Vector2(150.0, 120.0)
const FOOT := 210.0
## A sign: how tall, as wide as its name between these, and how far over its landmark's point it
## stands, so the road meets it at its foot rather than its middle.
const SIGN_TALL := 52.0
const SIGN_LEAST := 116.0
const SIGN_MOST := 178.0
const SIGN_LIFT := 16.0
const PICTURE_ROOM := 52.0
## How far a landmark stands off its place on the grid at most, across and down, and a bend; how far
## a long road wanders off straight and how long a stretch it takes to; how many times a road's
## corners are cut to round it.
const JITTER := Vector2(28.0, 17.0)
const BEND_JITTER := 9.0
const MEANDER := 13.0
const MEANDER_EVERY := 150.0
const SMOOTHING := 3
## The roundabout's ring, a share of the room its cells take.
const RING := 0.42
## How far a district's wash reaches past its signs, and how far its hand-drawn edge wanders.
const WASH_ROOM := 64.0
const WASH_WOBBLE := 26.0
## The side streets of a district: how far apart, and how far one leans off true.
const STREETS := 62.0
const STREET_LEAN := 10.0
## The little drawings: tried on a lattice this far apart, kept clear of the roads, the signs and
## the rest by this much, and this share of the places they could go get one.
const DOODLE_STEP := 52.0
const DOODLE_CLEAR := 26.0
const DOODLES := 0.8
## Out in the country between the districts the drawings come in clumps, where a slow swell over
## the paper is high, and this far across a swell is.
const COUNTRY_SWELL := 0.0017
## The compass, the legend and the title block.
const COMPASS := 46.0
const LEGEND := Vector2(262.0, 156.0)
const CARTOUCHE := Vector2(330.0, 118.0)
## What each district's little drawings are, and those on the paper between them.
const DRAWINGS := {
	LoyaltyLandmark.District.STRIP: [&"casino", &"palm", &"chips", &"dice", &"casino", &"star"],
	LoyaltyLandmark.District.DEPARTMENT:
	[&"cone", &"tree", &"parking", &"tower", &"house", &"tree"],
	LoyaltyLandmark.District.OFF_THE_BOOKS: [&"spiral", &"doodle_star", &"question", &"arrow"],
	-1: [&"tree", &"tree", &"tree", &"tree", &"palm"],
	-2: [&"field", &"field", &"hills", &"pond", &"house", &"tree"],
}

var map: LoyaltyMap
var profile: Profile
## Which sheet it is.
var sheet := Sheet.HOUSE
## The paper, at a zoom of one.
var paper := Vector2.ZERO
## Each landmark drawn: where its point is, and its sign's size.
var points: Dictionary[StringName, Vector2] = {}
var signs: Dictionary[StringName, Vector2] = {}
## Every road drawn, a dictionary each: its `ends` by id, its `points` from the first end on, and
## whether it is in `pencil`, runs into the `ring` or off the paper's `edge`.
var roads: Array[Dictionary] = []
## The roundabout's middle and how far round its ring is.
var ring_middle := Vector2.ZERO
var ring := 0.0
## Each district's wash, and where its name is printed: the left of its baseline; and the side
## streets drawn faint across the house's two.
var washes: Dictionary[int, PackedVector2Array] = {}
var streets: Array[PackedVector2Array] = []
var names_at: Dictionary[int, Vector2] = {}
## The little drawings: a dictionary each, its `kind`, where it is `at`, its `size` and its `turn`.
var doodles: Array[Dictionary] = []
## The compass's middle, the legend's box and the title block's.
var compass := Vector2.ZERO
var legend := Rect2()
var cartouche := Rect2()

var _cols := PackedFloat32Array()
var _rows := PackedFloat32Array()
var _first_row := 0
var _by_pair: Dictionary[String, int] = {}


## The layout of [param drawn]'s map as [param whose] profile has it drawn, the sheet [param on].
static func of(drawn: LoyaltyMap, whose: Profile, on := Sheet.HOUSE) -> LoyaltyMapLayout:
	var layout := LoyaltyMapLayout.new()
	layout.map = drawn
	layout.profile = whose
	layout.sheet = on
	layout._lay()
	return layout


## The sheet [param landmark] is on: Kit's for a landmark off the books, the House's for the rest.
static func sheet_of(landmark: LoyaltyLandmark) -> Sheet:
	if landmark != null and landmark.district == LoyaltyLandmark.District.OFF_THE_BOOKS:
		return Sheet.KIT
	return Sheet.HOUSE


## The sheet the landmark [param id] is on, the roundabout's the House's.
static func sheet_of_id(id: StringName) -> Sheet:
	return sheet_of(Loyalty.map().landmark(id)) if id != Loyalty.ROUNDABOUT else Sheet.HOUSE


## Every landmark drawn on the profile's map, on this sheet.
func drawn() -> Array[LoyaltyLandmark]:
	var shown: Array[LoyaltyLandmark] = []
	for each: LoyaltyLandmark in map.landmarks:
		if Loyalty.is_drawn(profile, each) and sheet_of(each) == sheet:
			shown.append(each)
	return shown


## Where [param id]'s sign is on the paper: the roundabout's the ring itself.
func sign_rect(id: StringName) -> Rect2:
	if id == Loyalty.ROUNDABOUT:
		return Rect2(ring_middle - Vector2.ONE * ring, Vector2.ONE * ring * 2.0)
	var size: Vector2 = signs.get(id, Vector2(SIGN_LEAST, SIGN_TALL))
	var middle: Vector2 = points.get(id, Vector2.ZERO) - Vector2(0.0, SIGN_LIFT)
	return Rect2(middle - size * 0.5, size)


## The points of the road from [param from] to [param to], in that order; none for two with no
## road drawn between them. The roundabout's roads are those that run into its ring.
func road(from: StringName, to: StringName) -> PackedVector2Array:
	if from == Loyalty.ROUNDABOUT or to == Loyalty.ROUNDABOUT:
		var keystone := to if from == Loyalty.ROUNDABOUT else from
		for each: Dictionary in roads:
			var ends: Array = each["ends"]
			if each["ring"] and ends.size() == 1 and ends[0] == keystone:
				var line: PackedVector2Array = (each["points"] as PackedVector2Array).duplicate()
				if from == Loyalty.ROUNDABOUT:
					line.reverse()
				return line
		return PackedVector2Array()
	var at: int = _by_pair.get("%s|%s" % [from, to], -1)
	if at >= 0:
		return roads[at]["points"]
	at = _by_pair.get("%s|%s" % [to, from], -1)
	if at < 0:
		return PackedVector2Array()
	var back: PackedVector2Array = (roads[at]["points"] as PackedVector2Array).duplicate()
	back.reverse()
	return back


## The middle of [param cell] on the paper.
func middle(cell: Vector2i) -> Vector2:
	var column := clampi(cell.x, 0, _cols.size() - 2)
	var row := clampi(cell.y, 0, _rows.size() - 2)
	return Vector2((_cols[column] + _cols[column + 1]) * 0.5, (_rows[row] + _rows[row + 1]) * 0.5)


## A number from -1 to 1 for [param seed], the same every time.
static func wobble(seed: String) -> float:
	return float(posmod(hash(seed), 20001)) / 10000.0 - 1.0


func _lay() -> void:
	_lay_grid()
	for each: LoyaltyLandmark in drawn():
		var jitter := Vector2(wobble(each.id + "x") * JITTER.x, wobble(each.id + "y") * JITTER.y)
		if each.district == LoyaltyLandmark.District.SLIP:
			jitter = Vector2.ZERO
		points[each.id] = middle(map.at(each.id)) + jitter
		signs[each.id] = sign_size(each)
	_lay_ring()
	for run: Dictionary in map.runs():
		_lay_run(run)
	_lay_washes()
	_lay_streets()
	_lay_furniture()
	_lay_doodles()


## How big [param landmark]'s sign is: as wide as its name in two lines at most, between the least
## and the most a sign is.
static func sign_size(landmark: LoyaltyLandmark) -> Vector2:
	var kit := landmark.district == LoyaltyLandmark.District.OFF_THE_BOOKS
	var font: Font = LoyaltyArt.HAND if kit else Type.STRONG
	var size := roundi(LoyaltyArt.TITLE_SIZE * (LoyaltyArt.HAND_SCALE if kit else 1.0))
	var room := SIGN_MOST - PICTURE_ROOM - LoyaltyArt.ROOM
	var widest := 0.0
	for line: String in LoyaltyArt.lines_of(font, landmark.title, size, room, 2):
		widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)
	var wide := clampf(widest + PICTURE_ROOM + LoyaltyArt.ROOM + 6.0, SIGN_LEAST, SIGN_MOST)
	return Vector2(roundf(wide), SIGN_TALL + (6.0 if landmark.keystone else 0.0))


## How wide each column of the grid is and how tall each row, and the paper round them: the rows of
## this sheet's landmarks alone, and on Kit's the columns from its first landmark's, with a row's
## room under its last for its roads off the foot and no foot of furniture.
func _lay_grid() -> void:
	var cells := map.size()
	var wide := {}
	var tall := {}
	_first_row = cells.y
	var last_row := 0
	var first_column := cells.x
	for each: LoyaltyLandmark in drawn():
		var at := map.at(each.id)
		tall[at.y] = true
		_first_row = mini(_first_row, at.y)
		last_row = maxi(last_row, at.y)
		first_column = mini(first_column, at.x)
	var kit := sheet == Sheet.KIT
	for each: LoyaltyLandmark in map.landmarks:
		if not kit or sheet_of(each) == Sheet.KIT:
			wide[map.at(each.id).x] = true
	_cols = PackedFloat32Array()
	var x := MARGIN.x
	for column: int in cells.x + 1:
		_cols.append(x)
		if not kit or column >= first_column:
			x += WIDE if wide.has(column) else NARROW
	_rows = PackedFloat32Array()
	var y := MARGIN.y
	for row: int in cells.y + 1:
		_rows.append(y)
		if row >= _first_row and (not kit or row <= last_row + 1):
			y += TALL if tall.has(row) else SHORT
	paper = Vector2(x + MARGIN.x, y + (MARGIN.y if kit else FOOT))


func _lay_ring() -> void:
	if sheet == Sheet.KIT:
		return
	var cells: Array[Vector2i] = []
	var bounds := map.size()
	for row: int in bounds.y:
		for column: int in bounds.x:
			if map.cell(Vector2i(column, row)) == LoyaltyMap.ROUNDABOUT:
				cells.append(Vector2i(column, row))
	if cells.is_empty():
		return
	ring_middle = (middle(cells[0]) + middle(cells[-1])) * 0.5
	var reach := minf(
		_cols[cells[-1].x + 1] - _cols[cells[0].x], _rows[cells[-1].y + 1] - _rows[cells[0].y]
	)
	ring = reach * RING


## The road of one run of the grid, if every landmark at its ends is drawn: through its cells from
## one end to the other, as [method _shape] has it.
func _lay_run(run: Dictionary) -> void:
	var ends: Array[StringName] = []
	ends.assign(run["ends"])
	if _lay_way_off(ends):
		return
	for id: StringName in ends:
		if not points.has(id):
			return
	var cells: Array[Vector2i] = []
	cells.assign(run["cells"])
	var pencil: bool = run["pencil"]
	if ends.size() >= 2:
		for i: int in ends.size():
			for j: int in range(i + 1, ends.size()):
				_add_road([ends[i], ends[j]], map.path(ends[i], ends[j]), pencil, false, false)
		return
	if ends.is_empty():
		return
	var into_ring: bool = run["roundabout"]
	var chain := _chain(map.at(ends[0]), cells, into_ring)
	_add_road(ends, chain, pencil, into_ring, not into_ring)


func _add_road(
	ends: Array[StringName],
	cells: Array[Vector2i],
	pencil: bool,
	into_ring: bool,
	edge: bool,
	off_to := &""
) -> void:
	if cells.size() < 2:
		return
	var shaped := _shape(cells, into_ring, edge)
	if ends.size() == 2:
		_by_pair["%s|%s" % [ends[0], ends[1]]] = roads.size()
	roads.append(
		{
			"ends": ends,
			"points": shaped,
			"pencil": pencil,
			"ring": into_ring,
			"edge": edge,
			"off_to": off_to
		}
	)


## A road from one of this sheet's landmarks on to one on the other sheet, see [param ends]: run
## off this sheet's edge from as far as the sheet goes, toward the landmark it leads to, which the
## view names at its end; on Kit's sheet off its foot, and on the House's in Kit's pencil up off its
## top, once Kit's sheet is drawn. True for a road it laid so.
func _lay_way_off(ends: Array[StringName]) -> bool:
	if ends.size() != 2:
		return false
	var mine := -1
	for i: int in 2:
		if points.has(ends[i]):
			mine = i
	var other: StringName = ends[1 - mine] if mine >= 0 else &""
	var there := map.landmark(other)
	if mine < 0 or points.has(other) or there == null or sheet_of(there) == sheet:
		return false
	if not Loyalty.is_drawn(profile, there):
		return false
	var cells := map.path(ends[mine], other)
	var on_sheet: Array[Vector2i] = []
	for cell: Vector2i in cells:
		var off := cell.y > _last_row() if sheet == Sheet.KIT else cell.y < _first_row - 1
		if off:
			break
		on_sheet.append(cell)
	_add_road([ends[mine]], on_sheet, true, false, true, other)
	return true


## The last row with height on this sheet.
func _last_row() -> int:
	var last := 0
	for row: int in range(1, _rows.size()):
		if _rows[row] > _rows[row - 1]:
			last = row - 1
	return last


## The cells of a run with one landmark at its end, from its cell on to where it leaves the grid or
## meets the roundabout.
func _chain(start: Vector2i, cells: Array[Vector2i], into_ring: bool) -> Array[Vector2i]:
	var bounds := Rect2i(Vector2i.ZERO, map.size())
	var came := {start: start}
	var next: Array[Vector2i] = [start]
	var last := start
	while not next.is_empty():
		var here: Vector2i = next.pop_front()
		last = here
		var done := false
		for step: Vector2i in LoyaltyMap.ways(map.cell(here)):
			var there := here + step
			var what := map.cell(there)
			var bend := map.cell(here) == LoyaltyMap.BEND
			if (
				(into_ring and what == LoyaltyMap.ROUNDABOUT)
				or (not into_ring and not bend and not bounds.has_point(there))
			):
				done = here != start
		if done:
			break
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var there := here + step
			if there in cells and not came.has(there):
				came[there] = here
				next.append(there)
	var chain: Array[Vector2i] = [last]
	while chain[0] != start:
		chain.push_front(came[chain[0]])
	return chain


## The points of a road through [param cells]: its ends and its bends, each where it stands, the
## ring's edge or the paper's edge after the last for a road that runs on there; a long stretch
## wandering a little; the corners cut until it runs smoothly.
func _shape(cells: Array[Vector2i], into_ring: bool, edge: bool) -> PackedVector2Array:
	var nodes := PackedVector2Array()
	for i: int in cells.size():
		var cell := cells[i]
		var landmark := _landmark_in(cell)
		if landmark != &"":
			nodes.append(points[landmark])
			continue
		var turned := (
			i > 0 and i < cells.size() - 1 and (cells[i] - cells[i - 1] != cells[i + 1] - cells[i])
		)
		if turned or i == cells.size() - 1:
			var seed := "%d,%d" % [cell.x, cell.y]
			nodes.append(
				middle(cell) + Vector2(wobble(seed + "x"), wobble(seed + "y")) * BEND_JITTER
			)
	if into_ring:
		var way := (nodes[-1] - ring_middle).normalized()
		nodes.append(ring_middle + way * ring)
	elif edge:
		var way := Vector2(cells[-1] - cells[-2])
		var out := nodes[-1]
		if way.y > 0.0:
			out.y = paper.y
		elif way.y < 0.0:
			out.y = 0.0
		elif way.x > 0.0:
			out.x = paper.x
		else:
			out.x = 0.0
		nodes.append(out)
	return _rounded(_wandered(nodes), SMOOTHING)


func _landmark_in(cell: Vector2i) -> StringName:
	for id: StringName in points:
		if map.at(id) == cell:
			return id
	return &""


## [param nodes] with a point put in partway along each long stretch, a little off it to one side.
func _wandered(nodes: PackedVector2Array) -> PackedVector2Array:
	var wandered := PackedVector2Array([nodes[0]])
	for i: int in range(1, nodes.size()):
		var from := nodes[i - 1]
		var to := nodes[i]
		var stretch := from.distance_to(to)
		var many := int(stretch / MEANDER_EVERY)
		var side := (to - from).orthogonal().normalized()
		for k: int in many:
			var along := float(k + 1) / float(many + 1)
			var seed := "%d,%d,%d" % [roundi(from.x), roundi(to.y), k]
			wandered.append(from.lerp(to, along) + side * wobble(seed) * MEANDER)
		wandered.append(to)
	return wandered


## [param line] with its corners cut [param times] over, its ends where they were.
static func _rounded(line: PackedVector2Array, times: int) -> PackedVector2Array:
	var cut := line
	for _time: int in times:
		if cut.size() < 3:
			return cut
		var next := PackedVector2Array([cut[0]])
		for i: int in cut.size() - 1:
			next.append(cut[i].lerp(cut[i + 1], 0.25))
			next.append(cut[i].lerp(cut[i + 1], 0.75))
		next.append(cut[-1])
		next.remove_at(1)
		next.remove_at(next.size() - 2)
		cut = next
	return cut


## Each district's wash: round its signs and a way past them, its edge wandering as a hand's does;
## and where its name goes, over its top left.
func _lay_washes() -> void:
	var corners: Dictionary[int, PackedVector2Array] = {}
	for each: LoyaltyLandmark in drawn():
		if each.district == LoyaltyLandmark.District.SLIP:
			continue
		var held: PackedVector2Array = corners.get(each.district, PackedVector2Array())
		var rect := sign_rect(each.id)
		held.append_array(
			[
				rect.position,
				Vector2(rect.end.x, rect.position.y),
				rect.end,
				Vector2(rect.position.x, rect.end.y)
			]
		)
		corners[each.district] = held
	for district: int in corners:
		var hull := Geometry2D.convex_hull(corners[district])
		var grown := Geometry2D.offset_polygon(hull, WASH_ROOM, Geometry2D.JOIN_ROUND)
		if grown.is_empty():
			continue
		washes[district] = _by_hand(grown[0], str(district))
		var top_left := Vector2(INF, INF)
		for point: Vector2 in corners[district]:
			top_left = top_left.min(point)
		names_at[district] = top_left + Vector2(-8.0, -22.0)


## [param outline] drawn by hand: a point every so often along it, each a little in or out from
## its middle, smoothly round.
static func _by_hand(outline: PackedVector2Array, seed: String) -> PackedVector2Array:
	var middle := Vector2.ZERO
	for point: Vector2 in outline:
		middle += point
	middle /= float(outline.size())
	var drawn := PackedVector2Array()
	var phase := wobble(seed) * PI
	var gone := 0.0
	for i: int in outline.size():
		var from := outline[i]
		var to := outline[(i + 1) % outline.size()]
		var steps := maxi(int(from.distance_to(to) / 18.0), 1)
		for k: int in steps:
			var point := from.lerp(to, float(k) / float(steps))
			gone += from.distance_to(to) / float(steps)
			# Swells along the way round rather than round the middle, so a long side wanders too.
			var out := (
				sin(gone * 0.011 + phase) * 0.55
				+ sin(gone * 0.029 + phase * 2.0) * 0.3
				+ sin(gone * 0.07 + phase * 3.0) * 0.15
			)
			drawn.append(point + (point - middle).normalized() * out * WASH_WOBBLE)
	return drawn


## The side streets across the house's districts: a lattice a little off true, as much of each line
## as is inside the wash.
func _lay_streets() -> void:
	for district: int in [LoyaltyLandmark.District.STRIP, LoyaltyLandmark.District.DEPARTMENT]:
		if not washes.has(district):
			continue
		var outline := washes[district]
		var low := Vector2(INF, INF)
		var high := -low
		for point: Vector2 in outline:
			low = low.min(point)
			high = high.max(point)
		var lean := wobble(str(district) + "lean") * STREET_LEAN
		var y := low.y + STREETS * 0.5
		while y < high.y:
			var line := PackedVector2Array([Vector2(low.x, y - lean), Vector2(high.x, y + lean)])
			streets.append_array(Geometry2D.intersect_polyline_with_polygon(line, outline))
			y += STREETS
		var x := low.x + STREETS * 0.5
		while x < high.x:
			var line := PackedVector2Array([Vector2(x + lean, low.y), Vector2(x - lean, high.y)])
			streets.append_array(Geometry2D.intersect_polyline_with_polygon(line, outline))
			x += STREETS * 1.2


## The compass over the roundabout, the legend in the foot's left corner and the house's title block
## in its right.
func _lay_furniture() -> void:
	if sheet == Sheet.KIT:
		return
	var house_top := INF
	for each: LoyaltyLandmark in drawn():
		if each.district in [LoyaltyLandmark.District.STRIP, LoyaltyLandmark.District.DEPARTMENT]:
			house_top = minf(house_top, points[each.id].y)
	compass = Vector2(ring_middle.x, (house_top + ring_middle.y - ring) * 0.5)
	var foot := paper.y - 44.0
	legend = Rect2(Vector2(46.0, foot - LEGEND.y), LEGEND)
	cartouche = Rect2(Vector2(paper.x - 46.0 - CARTOUCHE.x, foot - CARTOUCHE.y), CARTOUCHE)


## The little drawings, on a lattice over the paper, in each place clear of everything else on it
## that the dice say gets one, each its district's kind or, between them, the country's.
func _lay_doodles() -> void:
	var taken := {}
	var bucket := DOODLE_CLEAR
	for each: Dictionary in roads:
		var line: PackedVector2Array = each["points"]
		for i: int in range(1, line.size()):
			var steps := maxi(int(line[i - 1].distance_to(line[i]) / 8.0), 1)
			for k: int in steps + 1:
				_take(taken, line[i - 1].lerp(line[i], float(k) / float(steps)), 26.0)
		# And the words at the end of a road off the sheet, beside its arrow.
		if each.get("off_to", &"") != &"":
			_take_rect(taken, Rect2(line[-1] - Vector2(40.0, 70.0), Vector2(300.0, 140.0)))
	for id: StringName in points:
		var rect := sign_rect(id).grow(18.0)
		# And the label of the bet under it.
		rect.size.y += 70.0
		_take_rect(taken, rect)
	for district: int in names_at:
		_take_rect(taken, Rect2(names_at[district] - Vector2(0.0, 30.0), Vector2(320.0, 44.0)))
	_take_rect(
		taken, Rect2(ring_middle - Vector2.ONE * (ring + 40.0), Vector2.ONE * (ring + 40.0) * 2.0)
	)
	_take_rect(
		taken, Rect2(compass - Vector2.ONE * (COMPASS + 30.0), Vector2.ONE * (COMPASS + 30.0) * 2.0)
	)
	_take_rect(taken, legend.grow(20.0))
	_take_rect(taken, cartouche.grow(20.0))
	var inside := Rect2(Vector2.ONE * 60.0, paper - Vector2.ONE * 120.0)
	var y := inside.position.y
	while y < inside.end.y:
		var x := inside.position.x
		while x < inside.end.x:
			var seed := "%d,%d" % [roundi(x), roundi(y)]
			var at := Vector2(x, y) + Vector2(wobble(seed + "a"), wobble(seed + "b")) * 22.0
			var district := _district_at(at)
			var chance := DOODLES * (1.0 if district >= 0 else _swell(at))
			if district == LoyaltyLandmark.District.OFF_THE_BOOKS:
				chance = DOODLES * 0.32
			elif sheet == Sheet.KIT:
				# Graph paper has no country on it, only what Kit drew.
				chance = 0.0
			if (wobble(seed + "keep") + 1.0) * 0.5 < chance and not _is_taken(taken, at):
				# The country is woods in one place and farms in another, by a second swell.
				var country := -2 if _swell(at.rotated(1.1) * 0.7) > 0.35 else -1
				var kinds: Array = DRAWINGS[district if district >= 0 else country]
				var kind: StringName = kinds[posmod(hash(seed + "kind"), kinds.size())]
				var size := 30.0 + wobble(seed + "size") * 6.0
				doodles.append(
					{"kind": kind, "at": at, "size": size, "turn": wobble(seed + "turn") * 0.22}
				)
				_take(taken, at, bucket * 1.6)
			x += DOODLE_STEP
		y += DOODLE_STEP * 0.86


## The slow swell over the paper the country's drawings clump where it is high: nothing over
## half of it, and the other half rising to most.
static func _swell(at: Vector2) -> float:
	var rise := (
		sin(at.x * COUNTRY_SWELL * TAU + 1.3) * cos(at.y * COUNTRY_SWELL * 1.3 * TAU - 0.7)
		+ sin((at.x + at.y) * COUNTRY_SWELL * 2.1 * TAU) * 0.5
	)
	return clampf(rise, 0.0, 1.0)


func _district_at(at: Vector2) -> int:
	for district: int in washes:
		if Geometry2D.is_point_in_polygon(at, washes[district]):
			return district
	return -1


func _take(taken: Dictionary, at: Vector2, radius: float) -> void:
	var low := ((at - Vector2.ONE * radius) / DOODLE_CLEAR).floor()
	var high := ((at + Vector2.ONE * radius) / DOODLE_CLEAR).floor()
	for x: int in range(int(low.x), int(high.x) + 1):
		for y: int in range(int(low.y), int(high.y) + 1):
			taken[Vector2i(x, y)] = true


func _take_rect(taken: Dictionary, rect: Rect2) -> void:
	var low := (rect.position / DOODLE_CLEAR).floor()
	var high := (rect.end / DOODLE_CLEAR).floor()
	for x: int in range(int(low.x), int(high.x) + 1):
		for y: int in range(int(low.y), int(high.y) + 1):
			taken[Vector2i(x, y)] = true


func _is_taken(taken: Dictionary, at: Vector2) -> bool:
	var cell := Vector2i((at / DOODLE_CLEAR).floor())
	for x: int in range(-1, 2):
		for y: int in range(-1, 2):
			if taken.has(cell + Vector2i(x, y)):
				return true
	return false
