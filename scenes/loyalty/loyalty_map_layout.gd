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
## is a legend in one corner with a compass beside it and the house's title in the other.
##
## It is laid out a sheet at a time, see [enum Sheet]: the House's printed map, the Strip and the
## Department and the roundabout between them; and Kit's, off the books on a sheet of graph paper
## of its own, the two roads of it that run on into the House's districts running off its foot.

## The map's two sheets: the House's, and Kit's, off the books.
enum Sheet { HOUSE, KIT }

## How much worse a landmark off to one side of the way the cursor is sent is than one straight that
## way, a pixel across for a pixel along, see [method toward].
const ACROSS_COST := 2.5
## How far along the way it is sent a landmark must be at least, a share of how far off to one side
## it is, to be that way at all: one far across and a little that way is not.
const TOWARD_CONE := 0.25
## How wide a column of the grid with a landmark in it is, and one without, and how tall a row with
## one and a row without; and the paper round the grid, room for the legend and the title under it.
const WIDE := 180.0
const NARROW := 12.0
const TALL := 134.0
const SHORT := 44.0
const MARGIN := Vector2(170.0, 150.0)
const FOOT := 190.0
## How much wider or narrower than [constant WIDE] a column with a landmark in it is at most, and a
## row than [constant TALL], so the blocks between the roads are not all of a size.
const WIDE_SWAY := 30.0
const TALL_SWAY := 24.0
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
const JITTER := Vector2(30.0, 26.0)
const BEND_JITTER := 9.0
## The slow sway every landmark and bend is moved by, see [method _swayed]: how far each district is
## turned about its middle at most, in radians, and how far that moves its furthest landmark at
## most; how far a row of them curves up or down and a
## column across, and over how long a stretch of the paper one curve runs; and how far round the
## roundabout it fades in, so the roads into the ring come in straight.
const TURN := 0.07
const TURN_REACH := 34.0
const CURVE := Vector2(26.0, 34.0)
const CURVE_EVERY := Vector2(1700.0, 1250.0)
const CALM := Vector2(1.3, 3.2)
## How much room each sign keeps round it from the next, the label of its bet under it counted in,
## and how many times they are pushed apart at most to keep it.
const SIGN_GAP := 12.0
const LABEL_ROOM := 72.0
const SPREADS := 12
const MEANDER := 13.0
const MEANDER_EVERY := 150.0
const SMOOTHING := 3
## The roundabout's ring, a share of the width of the columns its cells are in.
const RING := 0.42
## How far a district's wash reaches past the room round its signs and either side of its own
## roads, how much of a bay in its edge is filled in, and how far its hand-drawn edge wanders.
const WASH_ROOM := 46.0
const WASH_ROAD := 30.0
const WASH_FILL := 44.0
const WASH_WOBBLE := 22.0
## The side streets of a district: how far apart across and down on the Strip, the Department's a
## share further apart; how far a corner of one stands off true; what share of the stretches
## between two corners are drawn; and how far in from the wash's edge they stop.
const STREETS := Vector2(58.0, 70.0)
const STREETS_DEPARTMENT := 1.25
const STREET_JITTER := 9.0
const STREETS_KEPT := 0.62
const STREETS_IN := 10.0
## How far in from the streets round it a block is, a share of the way to its middle.
const BLOCK_IN := 0.2
## The compass, and how far it stands off the legend's side; the legend and the title block.
const COMPASS := 46.0
const COMPASS_GAP := 34.0
const LEGEND := Vector2(262.0, 156.0)
const CARTOUCHE := Vector2(330.0, 118.0)

## Every layout laid out this run, by the map, the sheet and whether Kit's district is drawn,
## which is all of a profile's progress that changes where anything goes.
static var _laid: Dictionary[String, LoyaltyMapLayout] = {}

var map: LoyaltyMap
## Whether Kit's district is drawn, see [method Loyalty.district_open]: the House's districts always
## are.
var kit_drawn := false
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
## The blocks between the side streets, a dictionary each, its `quad` of corners and its `district`:
## every one inside the wash, and once the country is laid out those built on, see [LoyaltyMapLand].
var blocks: Array[Dictionary] = []
var names_at: Dictionary[int, Vector2] = {}
## The little drawings: a dictionary each, its `kind`, where it is `at`, its `size` and its `turn`.
var doodles: Array[Dictionary] = []
## The places of the country named: a dictionary each, its `name`, the middle of its baseline
## `at`, and whether it is `water`.
var places: Array[Dictionary] = []
## The country, see [LoyaltyMapLand]: the tint under each wood; the river over the House's sheet
## and its lakes, none on Kit's; the water round the roundabout's island where there is room
## for it, none where not; the stretch of road over the water of each bridge; and the coffee ring
## on Kit's sheet, its middle and how far round, none on the House's.
var woods: Array[PackedVector2Array] = []
var river := PackedVector2Array()
var lakes: Array[PackedVector2Array] = []
var moat := PackedVector2Array()
var bridges: Array[PackedVector2Array] = []
var stain := Vector3.ZERO
## The compass's middle, the legend's box and the title block's.
var compass := Vector2.ZERO
var legend := Rect2()
var cartouche := Rect2()

var _cols := PackedFloat32Array()
var _rows := PackedFloat32Array()
var _first_row := 0
var _by_pair: Dictionary[String, int] = {}
## The middle of each side of the sheet the sway turns about, and how far it turns it, see [method
## _swayed]: the House's two districts either side of the roundabout, Kit's on its own; and where
## the sway's curves start.
var _sway_middles: Array[Vector2] = []
var _sway_turns: Array[float] = []
var _sway_phase := Vector2.ZERO


## The layout of [param drawn]'s map as [param whose] profile has it drawn, the sheet [param on]:
## laid out once a run for each way a map can be drawn, see [member _laid], and the same one given
## back after, so the map opens and turns its sheets without laying it all out again.
static func of(drawn: LoyaltyMap, whose: Profile, on := Sheet.HOUSE) -> LoyaltyMapLayout:
	var kit := Loyalty.district_open(whose, LoyaltyLandmark.District.OFF_THE_BOOKS)
	var key := "%d|%d|%d|%s" % [drawn.get_instance_id(), drawn.grid.hash(), on, kit]
	if _laid.has(key):
		return _laid[key]
	var layout := LoyaltyMapLayout.new()
	layout.map = drawn
	layout.kit_drawn = kit
	layout.sheet = on
	layout._lay()
	_laid[key] = layout
	return layout


## The sheet [param landmark] is on: Kit's for a landmark off the books, the House's for the rest.
static func sheet_of(landmark: LoyaltyLandmark) -> Sheet:
	if landmark != null and landmark.district == LoyaltyLandmark.District.OFF_THE_BOOKS:
		return Sheet.KIT
	return Sheet.HOUSE


## The sheet the landmark [param id] is on, the roundabout's the House's.
static func sheet_of_id(id: StringName) -> Sheet:
	return sheet_of(Loyalty.map().landmark(id)) if id != Loyalty.ROUNDABOUT else Sheet.HOUSE


## Whether [param landmark] is drawn: the House's always, Kit's once his district is.
func _is_drawn(landmark: LoyaltyLandmark) -> bool:
	return kit_drawn or landmark.district != LoyaltyLandmark.District.OFF_THE_BOOKS


## Every landmark drawn on the profile's map, on this sheet.
func drawn() -> Array[LoyaltyLandmark]:
	var shown: Array[LoyaltyLandmark] = []
	for each: LoyaltyLandmark in map.landmarks:
		if _is_drawn(each) and sheet_of(each) == sheet:
			shown.append(each)
	return shown


## The landmark of this sheet nearest [param from] in [param way] on the paper, right, left, up or
## down, whether or not a road goes there, for the cursor where none does, see [method
## LoyaltyMapView.drive_toward]: the nearer that way the better, and straight that way better than
## off to one side, [constant ACROSS_COST] times as much; none past the edge of the map that way,
## nor more off to one side than [constant TOWARD_CONE] has it.
func toward(from: StringName, way: Vector2i) -> StringName:
	var among: Array[StringName] = []
	for each: LoyaltyLandmark in drawn():
		among.append(each.id)
	if sheet == Sheet.HOUSE:
		among.append(Loyalty.ROUNDABOUT)
	var here := point_of(from)
	var heading := Vector2(way)
	var best := &""
	var least := INF
	for id: StringName in among:
		var off := point_of(id) - here
		var along := off.dot(heading)
		if id == from or along <= 1.0 or along < absf(off.cross(heading)) * TOWARD_CONE:
			continue
		var cost := along + absf(off.cross(heading)) * ACROSS_COST
		if cost < least:
			least = cost
			best = id
	return best


## Where [param id] is on the paper: the roundabout's the middle of its ring.
func point_of(id: StringName) -> Vector2:
	return ring_middle if id == Loyalty.ROUNDABOUT else points.get(id, ring_middle)


## Where [param id]'s sign is on the paper: the roundabout's the ring itself.
func sign_rect(id: StringName) -> Rect2:
	if id == Loyalty.ROUNDABOUT:
		return Rect2(ring_middle - Vector2.ONE * ring, Vector2.ONE * ring * 2.0)
	var size: Vector2 = signs.get(id, Vector2(SIGN_LEAST, SIGN_TALL))
	var middle: Vector2 = points.get(id, Vector2.ZERO) - Vector2(0.0, SIGN_LIFT)
	return Rect2(middle - size * 0.5, size)


## The road on this sheet that comes over its edge to [param id], from the edge in, the one from
## [param from] on the other sheet where there is one; none where no road comes over to it.
func way_in(from: StringName, id: StringName) -> PackedVector2Array:
	var found := PackedVector2Array()
	for each: Dictionary in roads:
		var to: StringName = each.get("off_to", &"")
		var ends: Array = each["ends"]
		if to == &"" or ends.size() != 1 or ends[0] != id:
			continue
		found = (each["points"] as PackedVector2Array).duplicate()
		found.reverse()
		if to == from:
			break
	return found


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


## Where a landmark or a bend in [param cell] stands on the paper, before its own jitter: the middle
## of the cell moved by the sway, see [method _swayed].
func spot(cell: Vector2i) -> Vector2:
	return _swayed(middle(cell))


## A number from -1 to 1 for [param seed], the same every time.
static func wobble(seed: String) -> float:
	return float(posmod(hash(seed), 20001)) / 10000.0 - 1.0


## A number from 0 to 1 for [param seed], the same every time, its hash stirred first: two seeds
## that differ in their last letter alone have hashes near each other, which [method wobble] gives
## back as numbers near each other too.
static func roll(seed: String) -> float:
	var stirred := hash(seed)
	for _time: int in 2:
		stirred = ((stirred >> 16) ^ stirred) * 0x45d9f3b
	stirred = (stirred >> 16) ^ stirred
	return float(posmod(stirred, 1000003)) / 1000002.0


func _lay() -> void:
	_lay_grid()
	_lay_ring()
	_lay_sway()
	for each: LoyaltyLandmark in drawn():
		var jitter := Vector2(wobble(each.id + "x") * JITTER.x, wobble(each.id + "y") * JITTER.y)
		points[each.id] = spot(map.at(each.id)) + jitter
		# The way onto the map stands just where it is drawn, under the districts' sway.
		if each.district == LoyaltyLandmark.District.SLIP:
			points[each.id] = middle(map.at(each.id))
		signs[each.id] = sign_size(each)
	_spread()
	for run: Dictionary in map.runs():
		_lay_run(run)
	_lay_washes()
	_lay_streets()
	_lay_furniture()
	LoyaltyMapLand.lay(self)


## Each side's middle and turn for [method _swayed]: the middle of its landmarks, the Strip turned
## one way and the Department the other, by more or less of [constant TURN].
func _lay_sway() -> void:
	var sides := 1 if sheet == Sheet.KIT else 2
	var sums: Array[Vector2] = []
	var counts: Array[int] = []
	for side: int in sides:
		sums.append(Vector2.ZERO)
		counts.append(0)
	var spots: Array[Array] = [[], []]
	for each: LoyaltyLandmark in drawn():
		var at := middle(map.at(each.id))
		var side := 0 if sides == 1 or at.x < ring_middle.x else 1
		sums[side] += at
		counts[side] += 1
		spots[side].append(at)
	for side: int in sides:
		var turned_about := sums[side] / maxf(float(counts[side]), 1.0)
		_sway_middles.append(turned_about)
		# A big district turned less, so its far corners move no further than a small one's.
		var reach := 1.0
		for at: Vector2 in spots[side]:
			reach = maxf(reach, at.distance_to(turned_about))
		var how := 0.55 + 0.45 * absf(wobble("turn %d %d" % [sheet, side]))
		var turn := minf(TURN * how, TURN_REACH / reach)
		_sway_turns.append(turn * (1.0 if side == 1 else -1.0))
	_sway_phase = Vector2(wobble("phase x %d" % sheet), wobble("phase y %d" % sheet)) * PI


## Where [param at], a place on the paper of the grid, is drawn: turned with its district about
## the district's middle, and moved along slow curves over the paper, across by how far down it is
## and up or down by how far across, so a row of landmarks runs as a street does and keeps its
## room along it. Less of both the nearer the roundabout, which stays where it is, and blended
## from one district's turn to the other's across the middle.
func _swayed(at: Vector2) -> Vector2:
	if _sway_middles.is_empty():
		return at
	var curve := Vector2(
		sin(at.y / CURVE_EVERY.y * TAU + _sway_phase.x) * CURVE.x,
		sin(at.x / CURVE_EVERY.x * TAU + _sway_phase.y) * CURVE.y
	)
	var turned: Array[Vector2] = []
	for side: int in _sway_middles.size():
		var from := at - _sway_middles[side]
		turned.append(from.rotated(_sway_turns[side]) - from)
	if sheet == Sheet.KIT:
		return at + turned[0] + curve
	var right := smoothstep(-ring, ring, at.x - ring_middle.x)
	var calm := smoothstep(ring * CALM.x, ring * CALM.y, at.distance_to(ring_middle))
	return at + (turned[0].lerp(turned[1], right) + curve) * calm


## The landmarks pushed apart a little at a time, wherever the room round one's sign and the label
## of its bet under it comes into another's, see [method _room_of]; the slip road stays where it
## is, and so does the roundabout.
func _spread() -> void:
	var ids: Array[StringName] = []
	ids.assign(points.keys())
	if sheet == Sheet.HOUSE:
		ids.append(Loyalty.ROUNDABOUT)
	for _time: int in SPREADS:
		var pushed := false
		for i: int in ids.size():
			for j: int in range(i + 1, ids.size()):
				var a := room_of(ids[i])
				var b := room_of(ids[j])
				if not a.intersects(b):
					continue
				var over := a.intersection(b).size
				var way := a.get_center() - b.get_center()
				var push := Vector2(1.0 if way.x >= 0.0 else -1.0, 0.0) * (over.x + 0.5)
				if over.y < over.x:
					push = Vector2(0.0, 1.0 if way.y >= 0.0 else -1.0) * (over.y + 0.5)
				var share := 0.5
				if _stays(ids[j]):
					share = 1.0
				elif _stays(ids[i]):
					share = 0.0
				if _stays(ids[i]) and _stays(ids[j]):
					continue
				if share > 0.0:
					points[ids[i]] += push * share
				if share < 1.0:
					points[ids[j]] -= push * (1.0 - share)
				pushed = true
		if not pushed:
			return


## Whether [param id] stays where it is as the rest are spread: the slip road and the roundabout.
func _stays(id: StringName) -> bool:
	if id == Loyalty.ROUNDABOUT:
		return true
	var landmark := map.landmark(id)
	return landmark != null and landmark.district == LoyaltyLandmark.District.SLIP


## The room [param id] keeps clear of the next: its sign and the ticket of its bet hung under it,
## see [method LoyaltyMapPrint.bet], and half [constant SIGN_GAP] round both.
func room_of(id: StringName) -> Rect2:
	var rect := sign_rect(id)
	if id == Loyalty.ROUNDABOUT:
		return rect.grow(SIGN_GAP * 2.0)
	var wide := rect.size.x
	var room := Rect2(
		Vector2(rect.get_center().x - wide * 0.5, rect.position.y),
		Vector2(wide, rect.size.y + LABEL_ROOM)
	)
	return room.grow(SIGN_GAP * 0.5)


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


## How wide each column of the grid is and how tall each row, and the paper round them: the columns
## and rows of this sheet's landmarks alone, the roundabout and the House's roads over them too,
## and on Kit's the columns from its first landmark's, with a row's room under its last for its
## roads off the foot and no foot of furniture.
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
	if not kit:
		# The roundabout's rows too, and the House's roads', where they run over the landmarks'
		# first.
		var lines := map.grid.split("\n")
		for row: int in mini(lines.size(), _first_row):
			if _is_house_row(lines[row]):
				_first_row = row
				break
	for each: LoyaltyLandmark in drawn():
		wide[map.at(each.id).x] = true
	_cols = PackedFloat32Array()
	var x := MARGIN.x
	for column: int in cells.x + 1:
		_cols.append(x)
		if not kit or column >= first_column:
			x += WIDE + wobble("column %d" % column) * WIDE_SWAY if wide.has(column) else NARROW
	_rows = PackedFloat32Array()
	var y := MARGIN.y
	for row: int in cells.y + 1:
		_rows.append(y)
		if row >= _first_row and (not kit or row <= last_row + 1):
			y += TALL + wobble("row %d" % row) * TALL_SWAY if tall.has(row) else SHORT
	paper = Vector2(x + MARGIN.x, y + (MARGIN.y if kit else FOOT))


## Whether [param line] of the grid has the roundabout or a road of the House's in it.
static func _is_house_row(line: String) -> bool:
	for what: String in [LoyaltyMap.ROUNDABOUT, LoyaltyMap.INK_ACROSS, LoyaltyMap.INK_DOWN]:
		if line.contains(what):
			return true
	return false


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
	# As wide as its columns, however few short rows it stands in.
	ring = (_cols[cells[-1].x + 1] - _cols[cells[0].x]) * RING


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
	if not _is_drawn(there):
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
			nodes.append(spot(cell) + Vector2(wobble(seed + "x"), wobble(seed + "y")) * BEND_JITTER)
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
	return rounded(_wandered(nodes), SMOOTHING)


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
static func rounded(line: PackedVector2Array, times: int) -> PackedVector2Array:
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


## Each district's wash: round the room its signs keep, see [method room_of], and a way past it,
## and along its own roads between them, its bays filled in a little and its edge wandering as a
## hand's does, so it follows where its landmarks are rather than a box round them; and where its
## name goes, over its top left.
func _lay_washes() -> void:
	var rooms: Dictionary[int, Array] = {}
	for each: LoyaltyLandmark in drawn():
		if each.district == LoyaltyLandmark.District.SLIP:
			continue
		var held: Array = rooms.get(each.district, [])
		held.append(room_of(each.id))
		rooms[each.district] = held
	for district: int in rooms:
		var shapes: Array[PackedVector2Array] = []
		var top_left := Vector2(INF, INF)
		for room: Rect2 in rooms[district]:
			var round_room := Geometry2D.offset_polygon(
				_corners(room), WASH_ROOM, Geometry2D.JOIN_ROUND
			)
			shapes.append(largest(round_room))
			top_left = top_left.min(room.position)
		# And its own roads, so it holds together where its landmarks stand far apart.
		for road: Dictionary in roads:
			if road["ring"] or road["edge"] or not _all_of(road["ends"], district):
				continue
			var ribbon := Geometry2D.offset_polyline(
				road["points"], WASH_ROAD, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND
			)
			if not ribbon.is_empty():
				shapes.append(largest(ribbon))
		# Grown and shrunk again by as much, so a narrow bay between two signs is filled.
		var whole := _union(shapes)
		whole = largest(Geometry2D.offset_polygon(whole, WASH_FILL, Geometry2D.JOIN_ROUND))
		whole = largest(Geometry2D.offset_polygon(whole, -WASH_FILL, Geometry2D.JOIN_ROUND))
		if whole.size() < 3:
			continue
		washes[district] = by_hand(whole, str(district))
		names_at[district] = top_left + Vector2(-4.0, -16.0)


## Whether every one of [param ends] is a landmark of [param district].
func _all_of(ends: Array, district: int) -> bool:
	for id: StringName in ends:
		var landmark := map.landmark(id)
		if landmark == null or landmark.district != district:
			return false
	return true


## The four corners of [param rect], round it.
static func _corners(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array(
		[
			rect.position,
			Vector2(rect.end.x, rect.position.y),
			rect.end,
			Vector2(rect.position.x, rect.end.y)
		]
	)


## One outline round all of [param shapes], each touching the rest through the others, the holes
## in it filled; the largest of it where one does not touch.
static func _union(shapes: Array[PackedVector2Array]) -> PackedVector2Array:
	var whole: PackedVector2Array = shapes[0]
	var left: Array[PackedVector2Array] = shapes.slice(1)
	var tries := left.size() * 3
	while not left.is_empty() and tries > 0:
		tries -= 1
		var next: PackedVector2Array = left.pop_front()
		var merged := Geometry2D.merge_polygons(whole, next)
		var outer := largest(merged)
		var outers := 0
		for each: PackedVector2Array in merged:
			if Geometry2D.is_polygon_clockwise(each) == Geometry2D.is_polygon_clockwise(outer):
				outers += 1
		if outers == 1:
			whole = outer
		else:
			# Not touching yet: once the rest are in, it may.
			left.append(next)
	return whole


## The largest of [param shapes], none for none.
static func largest(shapes: Array[PackedVector2Array]) -> PackedVector2Array:
	var best := PackedVector2Array()
	var most := -1.0
	for each: PackedVector2Array in shapes:
		var area := 0.0
		for i: int in each.size():
			area += each[i].cross(each[(i + 1) % each.size()])
		if absf(area) > most:
			most = absf(area)
			best = each
	return best


## [param outline] drawn by hand: a point every [param every] along it, each in or out across it
## by as much as [param by], by swells along the way round, so a long side wanders too and a bay
## stays a bay.
static func by_hand(
	outline: PackedVector2Array, seed: String, by := WASH_WOBBLE, every := 16.0
) -> PackedVector2Array:
	var along := PackedVector2Array()
	for i: int in outline.size():
		var from := outline[i]
		var to := outline[(i + 1) % outline.size()]
		var steps := maxi(int(from.distance_to(to) / every), 1)
		for k: int in steps:
			along.append(from.lerp(to, float(k) / float(steps)))
	# Out is the way off the side a step from the first point that is not in the outline.
	var first := (along[1] - along[-1]).orthogonal().normalized()
	var outward := (
		1.0 if not Geometry2D.is_point_in_polygon(along[0] + first * 3.0, outline) else -1.0
	)
	var drawn := PackedVector2Array()
	var phase := wobble(seed) * PI
	var gone := 0.0
	for i: int in along.size():
		var before := along[i - 1]
		var after := along[(i + 1) % along.size()]
		gone += before.distance_to(along[i])
		var out := (
			sin(gone * 0.011 + phase) * 0.5
			+ sin(gone * 0.027 + phase * 2.0) * 0.3
			+ sin(gone * 0.063 + phase * 3.0) * 0.2
		)
		drawn.append(along[i] + (after - before).orthogonal().normalized() * outward * out * by)
	# Where the hand would cross its own line, at a tight corner, the line as it was.
	if Geometry2D.triangulate_polygon(drawn).is_empty():
		return along
	return drawn


## The side streets across the House's districts: a lattice of corners, each moved by the sway the
## landmarks are and a little off true besides, and some of the stretches between two corners
## drawn, as much of each as is inside the wash. A dead end here, a crossing there, as a town's
## streets are.
func _lay_streets() -> void:
	for district: int in [LoyaltyLandmark.District.STRIP, LoyaltyLandmark.District.DEPARTMENT]:
		if not washes.has(district):
			continue
		var inside := largest(Geometry2D.offset_polygon(washes[district], -STREETS_IN))
		if inside.size() < 3:
			continue
		var low := Vector2(INF, INF)
		var high := -low
		for point: Vector2 in inside:
			low = low.min(point)
			high = high.max(point)
		var step := (
			STREETS
			* (STREETS_DEPARTMENT if district == LoyaltyLandmark.District.DEPARTMENT else 1.0)
		)
		var count := Vector2i(((high - low) / step).ceil()) + Vector2i.ONE
		var corners: Dictionary[Vector2i, Vector2] = {}
		var within: Dictionary[Vector2i, bool] = {}
		for row: int in count.y:
			for column: int in count.x:
				var seed := "%d street %d,%d" % [district, column, row]
				var at := low + Vector2(column, row) * step
				var off := (
					Vector2(roll(seed + "x") - 0.5, roll(seed + "y") - 0.5) * 2.0 * STREET_JITTER
				)
				var cell := Vector2i(column, row)
				corners[cell] = _swayed(at) + off
				within[cell] = Geometry2D.is_point_in_polygon(corners[cell], inside)
		_lay_blocks(corners, within, district)
		for cell: Vector2i in corners:
			for way: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
				var seed := "%d stretch %d,%d %d" % [district, cell.x, cell.y, way.x]
				if not corners.has(cell + way) or roll(seed) > STREETS_KEPT:
					continue
				var line := PackedVector2Array([corners[cell], corners[cell + way]])
				# Cut at the wash's edge only where it crosses it: a stretch with both its corners
				# inside is kept whole, and one with neither is left out.
				if within[cell] and within[cell + way]:
					streets.append(line)
				elif within[cell] or within[cell + way]:
					streets.append_array(Geometry2D.intersect_polyline_with_polygon(line, inside))


## A block between each four corners of the side streets of [param district] that are all inside
## its wash, see [member blocks], a way in from the streets round it.
func _lay_blocks(
	corners: Dictionary[Vector2i, Vector2], within: Dictionary[Vector2i, bool], district: int
) -> void:
	for cell: Vector2i in corners:
		var round_it: Array[Vector2i] = [
			cell, cell + Vector2i.RIGHT, cell + Vector2i.ONE, cell + Vector2i.DOWN
		]
		var quad := PackedVector2Array()
		for corner: Vector2i in round_it:
			if not within.get(corner, false):
				break
			quad.append(corners[corner])
		if quad.size() < 4:
			continue
		var middle := (quad[0] + quad[1] + quad[2] + quad[3]) * 0.25
		for k: int in 4:
			quad[k] = quad[k].lerp(middle, BLOCK_IN)
		blocks.append({"quad": quad, "district": district})


## The legend in the foot's left corner with the compass beside it, out of the way of the roads,
## and the house's title block in its right.
func _lay_furniture() -> void:
	if sheet == Sheet.KIT:
		return
	var foot := paper.y - 44.0
	legend = Rect2(Vector2(46.0, foot - LEGEND.y), LEGEND)
	cartouche = Rect2(Vector2(paper.x - 46.0 - CARTOUCHE.x, foot - CARTOUCHE.y), CARTOUCHE)
	compass = Vector2(legend.end.x + COMPASS_GAP + COMPASS, legend.get_center().y + 10.0)
