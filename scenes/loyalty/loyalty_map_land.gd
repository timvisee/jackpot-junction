class_name LoyaltyMapLand
extends RefCounted
## The country of the loyalty program's map, GAME.md 8.9: what is on the paper besides its roads,
## its landmarks and its furniture, laid out once with the rest of [LoyaltyMapLayout] and kept clear
## of all of it.
##
## The little drawings come in groups, as a country's woods and farms do: woods of round trees and
## pines on a tint of green, fields side by side in a patchwork with a barn, a row of hills, a
## village of a few houses and a tree. On the Strip a block of casinos, a row of palms, chips and
## dice; in the Department cones in a row, a depot with its stack of tires, a grove, a row of
## houses; Kit's in his margins, stars, spirals and question marks. The odd drawing stands on its
## own between them. A river winds across the foot of the House's sheet from edge to edge, a bridge
## wherever a road crosses it and a lake on it; the biggest wood, the farm, the hills, the lake
## and the river have names, the house's puns on its tables. Kit has put his coffee down on his.

## How big a place on the paper is, that a drawing takes or keeps clear of.
const CLEAR := 20.0
## The groups: tried on a lattice this far apart, each this far off it at most; the share of the
## places tried that get one in a district and in Kit's, and in the country where a slow swell
## over the paper is high, this far across a swell is, with this share anywhere between.
const GROUP_STEP := 112.0
const GROUP_JITTER := 40.0
const GROUPS := 1.0
const KIT_GROUPS := 0.45
const SWELL := 0.0017
const SCATTER := 0.5
## How near two drawings of one group may stand, a share of their sizes.
const PACK := 0.6
## The odd drawing on its own between the groups: tried this far apart, and the share that get one.
const STRAY_STEP := 44.0
const STRAYS := 0.13
## The river: the size of a place of the coarse grid it finds its way over, and what it costs it to
## run through a place near a landmark or the furniture, to go under a road by a bridge, and to run
## along the paper's edge; how much room it keeps; the lake on it, how far across and down at most,
## and how far from a bridge or the paper's edge.
const RIVER_CELL := 40.0
const NEAR_COST := 5.0
const ROAD_COST := 5.0
const EDGE_COST := 6.0
const EDGE_ROOM := 4
const RIVER_ROOM := 18.0
const LAKE := Vector2(84.0, 34.0)
const LAKE_CLEAR := 200.0
## How long a bridge over the river is; how much wider than the roundabout its island is, and the
## least and the most of water round the island, as far as there is room.
const BRIDGE := 30.0
const ISLAND := 18.0
const MOAT_LEAST := 34.0
const MOAT_MOST := 96.0
## The places named: the woods, the farm, the hills, the lake and the river; and the share of the
## groups that could have a name that are given it, the first of each kind laid big enough.
const NAMED := 0.45
## The fewest drawings a group laid can have and keep its name.
const NAMED_LEAST := 4
const WOODS_NAMES: Array[String] = ["Lucky Pines", "Flop Forest"]
const FARM_NAME := "Full House Farm"
const HILLS_NAME := "High Roller Hills"
const LAKE_NAME := "Bluff Lake"
const RIVER_NAME := "The River"
## Kit's coffee ring, how far round, and where on his sheet, a share of it.
const STAIN := 46.0
const STAIN_AT := Vector2(0.76, 0.66)
## The drawings that stand on their own in each district and, between them, in the country.
const STRAYS_OF := {
	LoyaltyLandmark.District.STRIP: [&"star", &"palm", &"dice", &"chips"],
	LoyaltyLandmark.District.DEPARTMENT: [&"cone", &"wood", &"house", &"tires"],
	LoyaltyLandmark.District.OFF_THE_BOOKS: [&"doodle_star", &"question", &"spiral"],
	-1: [&"wood", &"wood", &"pine", &"house", &"pond"],
}

var layout: LoyaltyMapLayout
var _taken := {}
## The places of [member _taken] a road took, and those something else did, which the river keeps
## off where it can go under a road.
var _road := {}
var _solid := {}
## The box round each district's wash, by its district.
var _boxes := {}
## The names of the country's places not given yet, by the kind of group they go to.
var _names := {&"woods": WOODS_NAMES.duplicate(), &"farm": [FARM_NAME], &"hills": [HILLS_NAME]}


## Lays out the country of [param on], into its drawings, woods, river, lake, bridges, places and
## stain.
static func lay(on: LoyaltyMapLayout) -> void:
	var land := LoyaltyMapLand.new()
	land.layout = on
	land._lay()


func _lay() -> void:
	_take_all()
	if layout.sheet == LoyaltyMapLayout.Sheet.HOUSE:
		_lay_moat()
		_lay_river()
	else:
		layout.stain = Vector3(layout.paper.x * STAIN_AT.x, layout.paper.y * STAIN_AT.y, STAIN)
	_lay_groups()
	_lay_strays()


## A number from 0 to 1 for [param seed], the same every time, see [method LoyaltyMapLayout.roll].
static func _roll(seed: String) -> float:
	return LoyaltyMapLayout.roll(seed)


## A number from -1 to 1 for [param seed], the same every time.
static func _wobble(seed: String) -> float:
	return LoyaltyMapLayout.roll(seed) * 2.0 - 1.0


## Everything the country keeps clear of taken: the roads and the words at the end of one off the
## sheet, each sign with the ticket under it, the districts' names, and the roundabout, the
## compass, the legend and the title block.
func _take_all() -> void:
	for each: Dictionary in layout.roads:
		var line: PackedVector2Array = each["points"]
		_take_line(line, 26.0, _road)
		if each.get("off_to", &"") != &"":
			_take_rect(Rect2(line[-1] - Vector2(40.0, 70.0), Vector2(300.0, 140.0)))
	for id: StringName in layout.points:
		var rect := layout.sign_rect(id).grow(18.0)
		rect.size.y += 70.0
		_take_rect(rect)
	for district: int in layout.names_at:
		_take_rect(Rect2(layout.names_at[district] - Vector2(0.0, 30.0), Vector2(340.0, 44.0)))
	if layout.sheet != LoyaltyMapLayout.Sheet.HOUSE:
		return
	var ring := layout.ring + 40.0
	_take_rect(Rect2(layout.ring_middle - Vector2.ONE * ring, Vector2.ONE * ring * 2.0))
	var compass := LoyaltyMapLayout.COMPASS + 30.0
	_take_rect(Rect2(layout.compass - Vector2.ONE * compass, Vector2.ONE * compass * 2.0))
	_take_rect(layout.legend.grow(20.0))
	_take_rect(layout.cartouche.grow(20.0))


## The water round the roundabout's island, where there is room for it: as far out as the nearest
## landmark, its ticket, a road that does not run into the ring, the furniture and the paper's edge
## let it, its edge drawn by hand; a bridge over it on each road into the ring.
func _lay_moat() -> void:
	var middle := layout.ring_middle
	var room := minf(
		minf(middle.x, layout.paper.x - middle.x), minf(middle.y, layout.paper.y - middle.y)
	)
	var rects: Array[Rect2] = [layout.legend, layout.cartouche]
	for id: StringName in layout.points:
		rects.append(layout.room_of(id))
	for district: int in layout.names_at:
		rects.append(Rect2(layout.names_at[district] - Vector2(0.0, 30.0), Vector2(340.0, 44.0)))
	for rect: Rect2 in rects:
		room = minf(room, middle.clamp(rect.position, rect.end).distance_to(middle))
	room = minf(room, middle.distance_to(layout.compass) - LoyaltyMapLayout.COMPASS)
	for each: Dictionary in layout.roads:
		if each["ring"]:
			continue
		for point: Vector2 in each["points"]:
			room = minf(room, point.distance_to(middle) - 16.0)
	var reach := minf(room - 14.0, layout.ring + ISLAND + MOAT_MOST)
	if reach < layout.ring + ISLAND + MOAT_LEAST:
		return
	var round_it := PackedVector2Array()
	for i: int in 40:
		var angle := TAU * i / 40.0
		round_it.append(
			middle + Vector2(cos(angle), sin(angle)) * reach * (1.0 + 0.04 * sin(angle * 3.0))
		)
	layout.moat = LoyaltyMapLayout.by_hand(round_it, "moat", 9.0, 12.0)
	var island := PackedVector2Array()
	for i: int in 24:
		island.append(middle + Vector2.from_angle(TAU * i / 24.0) * (layout.ring + ISLAND))
	for each: Dictionary in layout.roads:
		if not each["ring"]:
			continue
		for wet: PackedVector2Array in Geometry2D.intersect_polyline_with_polygon(
			each["points"], layout.moat
		):
			for over: PackedVector2Array in Geometry2D.clip_polyline_with_polygon(wet, island):
				if over.size() >= 2:
					layout.bridges.append(over)
	_take_rect(Rect2(middle - Vector2.ONE * reach, Vector2.ONE * reach * 2.0))


## The river, across the House's sheet from one edge to the other wherever there is most room for
## it: over a coarse grid of the paper, the way from one edge to the other that keeps furthest from
## every landmark, its ticket and the furniture, which it never runs through, going under a road by
## a bridge where it must and through a district where it will; across or down, whichever way has
## more room; its corners rounded. A lake on it where it has most room, and its name and the lake's
## beside them.
func _lay_river() -> void:
	var cells := Vector2i((layout.paper / RIVER_CELL).ceil())
	var grid := _river_grid(cells)
	var away := _away(cells, grid)
	var across := _river_way(cells, grid, away, true)
	var down := _river_way(cells, grid, away, false)
	var way: Array = across
	if down[1] < across[1]:
		way = down
	var path: Array[Vector2i] = way[0]
	if path.size() < 4:
		return
	var nodes := PackedVector2Array()
	for cell: Vector2i in path:
		nodes.append((Vector2(cell) + Vector2.ONE * 0.5) * RIVER_CELL)
	# Out to the paper's edge at either end, and no further.
	if way == across:
		nodes[0].x = 0.0
		nodes[-1].x = layout.paper.x
	else:
		nodes[0].y = 0.0
		nodes[-1].y = layout.paper.y
	layout.river = LoyaltyMapLayout.rounded(nodes, 3)
	_lay_bridges()
	_lay_lake(path, away)
	_name_river(way == across)
	_take_line(layout.river, RIVER_ROOM + 4.0)


## The coarse grid of the paper the river finds its way over, a byte a place: 2 where something it
## keeps off is, 1 where a road alone is, and 0 where nothing is.
func _river_grid(cells: Vector2i) -> PackedByteArray:
	var grid := PackedByteArray()
	grid.resize(cells.x * cells.y)
	var per := int(RIVER_CELL / CLEAR)
	for y: int in cells.y:
		for x: int in cells.x:
			var what := 0
			for dy: int in per:
				for dx: int in per:
					var place := Vector2i(x * per + dx, y * per + dy)
					if _solid.has(place):
						what = 2
					elif _road.has(place):
						what = maxi(what, 1)
			grid[y * cells.x + x] = what
	return grid


## How many places of [param grid] each is from the nearest that the river keeps off.
func _away(cells: Vector2i, grid: PackedByteArray) -> PackedInt32Array:
	var away := PackedInt32Array()
	away.resize(grid.size())
	away.fill(1 << 20)
	var next: Array[int] = []
	for i: int in grid.size():
		if grid[i] == 2:
			away[i] = 0
			next.append(i)
	var at := 0
	while at < next.size():
		var i := next[at]
		at += 1
		var cell := Vector2i(i % cells.x, i / cells.x)
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var there := cell + step
			if there.x < 0 or there.y < 0 or there.x >= cells.x or there.y >= cells.y:
				continue
			var k := there.y * cells.x + there.x
			if away[k] > away[i] + 1:
				away[k] = away[i] + 1
				next.append(k)
	return away


## The river's cheapest way over [param grid], from the left edge to the right where
## [param across] and from the top to the foot where not, a step along each time and at most one
## aside; and what it cost a step, INF where there is none.
func _river_way(
	cells: Vector2i, grid: PackedByteArray, away: PackedInt32Array, across: bool
) -> Array:
	var along := cells.x if across else cells.y
	var aside := cells.y if across else cells.x
	var best := PackedFloat32Array()
	best.resize(along * aside)
	var came := PackedInt32Array()
	came.resize(along * aside)
	for a: int in along:
		for s: int in aside:
			var cell := Vector2i(a, s) if across else Vector2i(s, a)
			var i := cell.y * cells.x + cell.x
			var cost := INF
			if grid[i] != 2:
				cost = 1.0 + NEAR_COST / pow(float(away[i]) + 0.5, 2.0)
				cost += ROAD_COST if grid[i] == 1 else 0.0
				cost += EDGE_COST if s < EDGE_ROOM or s >= aside - EDGE_ROOM else 0.0
			var from := INF
			var from_side := -1
			if a == 0:
				from = 0.0
			else:
				for ds: int in [0, -1, 1]:
					var t := s + ds
					if t >= 0 and t < aside and best[(a - 1) * aside + t] + absf(ds) * 0.4 < from:
						from = best[(a - 1) * aside + t] + absf(ds) * 0.4
						from_side = t
			best[a * aside + s] = from + cost
			came[a * aside + s] = from_side
	var end := -1
	for s: int in aside:
		if end < 0 or best[(along - 1) * aside + s] < best[(along - 1) * aside + end]:
			end = s
	var path: Array[Vector2i] = []
	var cost_all := best[(along - 1) * aside + end]
	if is_inf(cost_all):
		return [path, INF]
	var s := end
	for a: int in range(along - 1, -1, -1):
		path.push_front(Vector2i(a, s) if across else Vector2i(s, a))
		s = came[a * aside + s]
	return [path, cost_all / float(along)]


## A bridge wherever one of the House's roads crosses the river, [constant BRIDGE] long along the
## road. The river's
## stretches are found by the place of the paper they are in, so each road is tried against those
## near it alone.
func _lay_bridges() -> void:
	var river := layout.river
	var near := {}
	for i: int in range(1, river.size()):
		for at: Vector2 in [river[i - 1], river[i]]:
			var place := Vector2i((at / RIVER_CELL).floor())
			var held: Array = near.get(place, [])
			if i not in held:
				held.append(i)
			near[place] = held
	for each: Dictionary in layout.roads:
		# Kit's pencil runs over the House's print, river and all.
		if each["pencil"]:
			continue
		var line: PackedVector2Array = each["points"]
		for k: int in range(1, line.size()):
			var a := line[k - 1]
			var b := line[k]
			var tried := {}
			for at: Vector2 in [a, b]:
				for i: int in near.get(Vector2i((at / RIVER_CELL).floor()), []):
					if tried.has(i):
						continue
					tried[i] = true
					var hit: Variant = Geometry2D.segment_intersects_segment(
						a, b, river[i - 1], river[i]
					)
					if hit != null:
						var way := (b - a).normalized() * BRIDGE * 0.5
						layout.bridges.append(PackedVector2Array([hit - way, hit + way]))


## The lake on the river where it has most room along [param path], away from any bridge and the
## paper's edges: an oval along the river as long as there is room for, its edge drawn by hand, and
## its name under it.
func _lay_lake(path: Array[Vector2i], away: PackedInt32Array) -> void:
	var cells := int(ceil(layout.paper.x / RIVER_CELL))
	var best := -1
	for i: int in range(2, path.size() - 2):
		var at := (Vector2(path[i]) + Vector2.ONE * 0.5) * RIVER_CELL
		if not (
			Rect2(Vector2.ONE * LAKE_CLEAR * 0.6, layout.paper - Vector2.ONE * LAKE_CLEAR * 1.2)
			. has_point(at)
		):
			continue
		var clear := true
		for bridge: PackedVector2Array in layout.bridges:
			clear = clear and bridge[0].distance_to(at) > LAKE_CLEAR
		var room := away[path[i].y * cells + path[i].x]
		if clear and (best < 0 or room > away[path[best].y * cells + path[best].x]):
			best = i
	if best < 0:
		return
	var room := float(away[path[best].y * cells + path[best].x]) * RIVER_CELL - RIVER_CELL * 0.5
	var reach := Vector2(minf(LAKE.x, room * 1.6), minf(LAKE.y, room * 0.8))
	if reach.y < LAKE.y * 0.6:
		return
	var middle := _nearest_on_river((Vector2(path[best]) + Vector2.ONE * 0.5) * RIVER_CELL)
	var flow := (Vector2(path[best + 1] - path[best - 1])).normalized()
	var oval := PackedVector2Array()
	for i: int in 28:
		var angle := TAU * i / 28.0
		var out := Vector2(cos(angle), sin(angle) * (1.0 + 0.2 * sin(angle * 3.0))) * reach
		oval.append(middle + out.rotated(flow.angle()))
	layout.lake = LoyaltyMapLayout.by_hand(oval, "lake", 7.0, 10.0)
	_take_rect(Rect2(middle - Vector2.ONE * reach.x, Vector2.ONE * reach.x * 2.0))
	var under := Vector2(0.0, maxf(absf(reach.rotated(flow.angle()).y), reach.y) + 30.0)
	var aside := Vector2(maxf(absf(reach.rotated(flow.angle()).x), reach.x) + 14.0, 5.0)
	for at: Vector2 in [middle + under, middle - under + Vector2(0.0, 16.0), middle + aside]:
		if _name(LAKE_NAME, at, true):
			return


## The point of the river nearest [param at].
func _nearest_on_river(at: Vector2) -> Vector2:
	var best := layout.river[0]
	for point: Vector2 in layout.river:
		if point.distance_squared_to(at) < best.distance_squared_to(at):
			best = point
	return best


## The river's name beside it, where it runs furthest from the lake, the bridges and its ends: over
## it where it runs [param across], and beside it where it runs down.
func _name_river(across: bool) -> void:
	var avoid: Array[Vector2] = [layout.river[0], layout.river[-1]]
	for bridge: PackedVector2Array in layout.bridges:
		avoid.append(bridge[0])
	if layout.lake.size() > 2:
		avoid.append(_middle_of(layout.lake))
	var tried: Array[Vector2] = []
	for i: int in range(0, layout.river.size(), 6):
		tried.append(layout.river[i])
	tried.sort_custom(
		func(a: Vector2, b: Vector2) -> bool: return _furthest(a, avoid) > _furthest(b, avoid)
	)
	var font := LoyaltyMapPrint.place_font()
	var wide := (
		font
		. get_string_size(RIVER_NAME, HORIZONTAL_ALIGNMENT_LEFT, -1, LoyaltyMapPrint.PLACE_SIZE)
		. x
	)
	for at: Vector2 in tried.slice(0, 8):
		var off := Vector2(0.0, -12.0) if across else Vector2(wide * 0.5 + 14.0, 4.0)
		if (
			_name(RIVER_NAME, at + off, true)
			or _name(RIVER_NAME, at - off + Vector2(0.0, 12.0), true)
		):
			return


## How far [param at] is from the nearest of [param points].
static func _furthest(at: Vector2, points: Array[Vector2]) -> float:
	var least := INF
	for point: Vector2 in points:
		least = minf(least, point.distance_to(at))
	return least


## Names [param named] with its baseline's middle at [param at], where it is clear, and takes it.
## False where it is not clear.
func _name(named: String, at: Vector2, water: bool) -> bool:
	var font := LoyaltyMapPrint.place_font()
	var size := font.get_string_size(
		named, HORIZONTAL_ALIGNMENT_LEFT, -1, LoyaltyMapPrint.PLACE_SIZE
	)
	var rect := Rect2(at - Vector2(size.x * 0.5, size.y * 0.8), size)
	if not _inside(rect.position) or not _inside(rect.end) or _is_rect_taken(rect.grow(4.0)):
		return false
	layout.places.append({"name": named, "at": at, "water": water})
	_take_rect(rect.grow(6.0))
	return true


## The groups of drawings, on a lattice over the paper, each row of it half a step along from the
## last: in each place the dice say gets one and that is clear, a group of the kind its district
## has, or the country's.
func _lay_groups() -> void:
	var paper := layout.paper
	var row := 0
	var y := GROUP_STEP * 0.5
	while y < paper.y:
		var x := GROUP_STEP * (0.25 + 0.5 * (row % 2))
		while x < paper.x:
			var seed := "group %d,%d" % [roundi(x), roundi(y)]
			var at := Vector2(x, y)
			at += Vector2(_wobble(seed + "a"), _wobble(seed + "b")) * GROUP_JITTER
			x += GROUP_STEP
			var district := _district_at(at)
			if (
				_roll(seed + "keep") < _chance(district, at)
				and _inside(at)
				and not _is_taken(at, 10.0)
			):
				_group(_kind_of(district, at, seed), district, at, seed)
		y += GROUP_STEP * 0.87
		row += 1


## The share of places at [param at], in [param district] or none, that get a group.
func _chance(district: int, at: Vector2) -> float:
	if district == LoyaltyLandmark.District.OFF_THE_BOOKS:
		return KIT_GROUPS
	if layout.sheet == LoyaltyMapLayout.Sheet.KIT:
		# Graph paper has no country on it, only what Kit drew.
		return 0.0
	if district >= 0:
		return GROUPS
	return SCATTER + (1.0 - SCATTER) * _swell(at)


## The kind of group at [param at] in [param district]: the district's own, or out in the country
## farmland in one place and woods in another, by a second swell.
func _kind_of(district: int, at: Vector2, seed: String) -> StringName:
	var roll := _roll(seed + "kind")
	match district:
		LoyaltyLandmark.District.STRIP:
			return &"casinos" if roll < 0.36 else (&"palms" if roll < 0.72 else &"table")
		LoyaltyLandmark.District.DEPARTMENT:
			if roll < 0.3:
				return &"cones"
			return &"grove" if roll < 0.55 else (&"houses" if roll < 0.78 else &"depot")
		LoyaltyLandmark.District.OFF_THE_BOOKS:
			return &"stars" if roll < 0.45 else (&"scribble" if roll < 0.78 else &"pointer")
	if _swell(at.rotated(1.1) * 0.7) > 0.35:
		return &"farm" if roll < 0.55 else (&"village" if roll < 0.8 else &"hills")
	return &"woods" if roll < 0.52 else (&"hills" if roll < 0.74 else &"village")


## The drawings a group of [param kind] round [param at] tries: a kind, a place and a size each.
func _tries(kind: StringName, at: Vector2, seed: String) -> Array:
	# The group's own dice, thrown in turn, rather than a seed made and stirred for each throw.
	var dice := RandomNumberGenerator.new()
	dice.seed = int(LoyaltyMapLayout.roll(seed) * 2147483647.0)
	var turn := dice.randf_range(-0.5, 0.5)
	var many := func(least: int, most: int) -> int: return dice.randi_range(least, most)
	var tries: Array = []
	match kind:
		&"woods":
			var trees: int = many.call(6, 14)
			var reach := 26.0 + trees * 3.4
			for i: int in trees * 2:
				var off := Vector2.from_angle(dice.randf() * TAU) * sqrt(dice.randf()) * reach
				var tree := &"pine" if dice.randf() < 0.4 else &"wood"
				tries.append(
					[
						tree,
						at + (off * Vector2(1.4, 0.8)).rotated(turn * 0.6),
						22.0 + dice.randf() * 8.0
					]
				)
		&"farm":
			var across: int = many.call(2, 3)
			var down := 1 + int(dice.randf() * 2.0)
			var crops: Array[StringName] = [&"field", &"wheat", &"meadow"]
			for i: int in across:
				for k: int in down:
					var off := Vector2(
						(i - (across - 1) * 0.5) * 41.0, (k - (down - 1) * 0.5) * 29.0
					)
					var crop := crops[posmod(i + k * 2 + hash(seed), crops.size())]
					tries.append([crop, at + off.rotated(turn * 0.4), 40.0])
			var barn := Vector2((across * 0.5 + 0.55) * 41.0, 4.0).rotated(turn * 0.4)
			tries.append([&"barn", at + barn, 28.0])
			tries.append([&"wood", at - barn, 24.0])
		&"hills":
			var hills: int = many.call(3, 4)
			for i: int in hills:
				var off := Vector2((i - (hills - 1) * 0.5) * 24.0, sin(i * 1.9) * 7.0)
				tries.append([&"hills", at + off.rotated(turn * 0.4), 28.0 + dice.randf() * 8.0])
		&"village":
			var homes: int = many.call(3, 5)
			for i: int in homes + 2:
				var off := (
					Vector2.from_angle(TAU * i / (homes + 2) + turn) * (18.0 + dice.randf() * 18.0)
				)
				tries.append([&"house" if i < homes else &"wood", at + off, 24.0])
		&"casinos", &"palms", &"cones", &"houses":
			var rows := {
				&"casinos": [&"casino", 2, 3, 31.0, 30.0],
				&"palms": [&"palm", 3, 5, 22.0, 28.0],
				&"cones": [&"cone", 3, 5, 17.0, 22.0],
				&"houses": [&"house", 2, 3, 26.0, 24.0]
			}
			var spec: Array = rows[kind]
			var count: int = many.call(spec[1], spec[2])
			for i: int in count:
				var off := Vector2((i - (count - 1) * 0.5) * spec[3], sin(i * 1.3) * 3.0)
				tries.append([spec[0], at + off.rotated(turn * 0.5), spec[4]])
		&"table":
			tries.append([&"chips", at, 28.0])
			tries.append([&"dice", at + Vector2(24.0, 6.0).rotated(turn), 20.0])
			tries.append([&"dice", at + Vector2(-22.0, 8.0).rotated(turn), 18.0])
		&"grove":
			for i: int in many.call(2, 4):
				tries.append([&"wood", at + Vector2.from_angle(TAU * i / 4.0 + turn) * 15.0, 24.0])
		&"depot":
			tries.append([&"parking", at, 30.0])
			tries.append([&"tower", at + Vector2(30.0, -6.0).rotated(turn * 0.3), 28.0])
			tries.append([&"tires", at + Vector2(-26.0, 6.0).rotated(turn * 0.3), 22.0])
		&"stars":
			for i: int in many.call(3, 4):
				var off := Vector2.from_angle(dice.randf() * TAU) * (12.0 + dice.randf() * 22.0)
				tries.append([&"doodle_star", at + off, 16.0 + dice.randf() * 10.0])
		&"scribble":
			tries.append([&"spiral", at, 28.0])
			tries.append([&"question", at + Vector2(26.0, -4.0), 24.0])
		&"pointer":
			tries.append([&"arrow", at, 30.0])
			tries.append([&"question", at + Vector2(-26.0, 2.0), 24.0])
	return tries


## Lays a group of [param kind] in [param district] round [param at]: each of its drawings where
## it is clear of everything laid before the group, in the group's own district, and not too near
## another of it; taken once it is laid, and kept to be named. A wood laid a tint of green under it.
func _group(kind: StringName, district: int, at: Vector2, seed: String) -> void:
	var laid: Array[Dictionary] = []
	var named := _name_group(kind, at, seed)
	var tries := _tries(kind, at, seed)
	for i: int in tries.size():
		var each: Array = tries[i]
		var spot: Vector2 = each[1]
		var size: float = each[2]
		if not _inside(spot) or _is_taken(spot, size * 0.36) or _district_at(spot) != district:
			continue
		var near := false
		for other: Dictionary in laid:
			near = (
				near
				or (other["at"] as Vector2).distance_to(spot) < (size + other["size"]) * 0.5 * PACK
			)
		if near:
			continue
		var upright: bool = (
			each[0] in [&"wood", &"pine", &"house", &"barn", &"tower", &"casino", &"palm"]
		)
		var turn := sin(float(i) * 2.7 + float(hash(seed) % 97)) * (0.07 if upright else 0.3)
		laid.append({"kind": each[0], "at": spot, "size": size, "turn": turn})
	if named != "" and laid.size() < NAMED_LEAST:
		# Too little came of it to carry a name: the name to the next of its kind.
		layout.places.pop_back()
		_names[kind].push_front(named)
	if laid.size() < mini(2, tries.size()):
		return
	var points := PackedVector2Array()
	for each: Dictionary in laid:
		layout.doodles.append(each)
		points.append(each["at"])
	for each: Dictionary in laid:
		_take(each["at"], each["size"] * 0.5)
	if kind == &"woods" and points.size() >= 4:
		var hull := Geometry2D.convex_hull(points)
		var grown := LoyaltyMapLayout.largest(
			Geometry2D.offset_polygon(hull, 16.0, Geometry2D.JOIN_ROUND)
		)
		if grown.size() >= 3:
			layout.woods.append(LoyaltyMapLayout.by_hand(grown, seed, 6.0, 12.0))


## The name of a group of [param kind] round [param at], where it is one of the House's places
## with a name and the dice say it is to have it: put down before the group is, so its drawings
## keep clear of it, across a wood's middle as a map names one and under a farm or a row of hills.
## Empty where it has none.
func _name_group(kind: StringName, at: Vector2, seed: String) -> String:
	var left: Array = _names.get(kind, [])
	if layout.sheet != LoyaltyMapLayout.Sheet.HOUSE or left.is_empty():
		return ""
	if _roll(seed + "named") > NAMED:
		return ""
	var under := Vector2(0.0, 8.0 if kind == &"woods" else 40.0)
	if not _name(left[0], at + under, false):
		return ""
	return left.pop_front()


## The odd drawing on its own between the groups, on a lattice of its own, its district's kind or
## the country's.
func _lay_strays() -> void:
	var inside := Rect2(Vector2.ONE * 60.0, layout.paper - Vector2.ONE * 120.0)
	var y := inside.position.y
	while y < inside.end.y:
		var x := inside.position.x
		while x < inside.end.x:
			var seed := "%d,%d" % [roundi(x), roundi(y)]
			x += STRAY_STEP
			# The dice first, the most any place gets, before the rest is worked out.
			var keep := _roll(seed + "keep")
			if keep >= STRAYS * 2.0:
				continue
			var at := Vector2(x - STRAY_STEP, y)
			at += Vector2(_wobble(seed + "a"), _wobble(seed + "b")) * 18.0
			var district := _district_at(at)
			var chance := STRAYS * (2.0 if district >= 0 else 1.0)
			if layout.sheet == LoyaltyMapLayout.Sheet.KIT and district < 0:
				chance = 0.0
			var size := 28.0 + _wobble(seed + "size") * 5.0
			if keep >= chance or _is_taken(at, size * 0.5):
				continue
			var kinds: Array = STRAYS_OF[district if district >= 0 else -1]
			var kind: StringName = kinds[posmod(hash(seed + "kind"), kinds.size())]
			var turn := _wobble(seed + "turn") * 0.12
			layout.doodles.append({"kind": kind, "at": at, "size": size, "turn": turn})
			_take(at, size * 0.55)
		y += STRAY_STEP * 0.86


## Whether [param at] is inside the paper's rule, a way in from its edge.
func _inside(at: Vector2) -> bool:
	return Rect2(Vector2.ONE * 50.0, layout.paper - Vector2.ONE * 100.0).has_point(at)


## The slow swell over the paper the country's groups gather where it is high: nothing over half of
## it, and the other half rising to most.
static func _swell(at: Vector2) -> float:
	var rise := (
		sin(at.x * SWELL * TAU + 1.3) * cos(at.y * SWELL * 1.3 * TAU - 0.7)
		+ sin((at.x + at.y) * SWELL * 2.1 * TAU) * 0.5
	)
	return clampf(rise, 0.0, 1.0)


## The district whose wash [param at] is in, -1 for none; the box round each wash tried first.
func _district_at(at: Vector2) -> int:
	if _boxes.is_empty():
		for district: int in layout.washes:
			var low := Vector2(INF, INF)
			var high := -low
			for point: Vector2 in layout.washes[district]:
				low = low.min(point)
				high = high.max(point)
			_boxes[district] = Rect2(low, high - low)
	for district: int in layout.washes:
		var box: Rect2 = _boxes[district]
		if box.has_point(at) and Geometry2D.is_point_in_polygon(at, layout.washes[district]):
			return district
	return -1


static func _middle_of(points: PackedVector2Array) -> Vector2:
	var sum := Vector2.ZERO
	for point: Vector2 in points:
		sum += point
	return sum / maxf(float(points.size()), 1.0)


## Takes the places [param radius] round every point of [param line], into [param also] as well
## as everything taken: the roads into [member _road], the rest into [member _solid].
func _take_line(line: PackedVector2Array, radius: float, also: Variant = null) -> void:
	for i: int in range(1, line.size()):
		var steps := maxi(int(line[i - 1].distance_to(line[i]) / 12.0), 1)
		for k: int in steps + 1:
			_take(line[i - 1].lerp(line[i], float(k) / float(steps)), radius, also)


func _take(at: Vector2, radius: float, also: Variant = null) -> void:
	_take_rect(Rect2(at - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), also)


## Takes every place [param rect] covers, into [param also] as well, [member _solid] where none is
## named.
func _take_rect(rect: Rect2, also: Variant = null) -> void:
	var into: Dictionary = also if also != null else _solid
	var low := (rect.position / CLEAR).floor()
	var high := (rect.end / CLEAR).floor()
	for x: int in range(int(low.x), int(high.x) + 1):
		for y: int in range(int(low.y), int(high.y) + 1):
			_taken[Vector2i(x, y)] = true
			into[Vector2i(x, y)] = true


## Whether any place a drawing [param radius] round [param at] would cover is taken.
func _is_taken(at: Vector2, radius: float) -> bool:
	return _is_rect_taken(Rect2(at - Vector2.ONE * radius, Vector2.ONE * radius * 2.0))


func _is_rect_taken(rect: Rect2) -> bool:
	var low := (rect.position / CLEAR).floor()
	var high := (rect.end / CLEAR).floor()
	for x: int in range(int(low.x), int(high.x) + 1):
		for y: int in range(int(low.y), int(high.y) + 1):
			if _taken.has(Vector2i(x, y)):
				return true
	return false
