class_name LoyaltyMapWater
extends RefCounted
## The water of the loyalty program's map, GAME.md 8.9, laid out with the rest of the country by
## [LoyaltyMapLand], on the House's sheet alone: the moat round the roundabout's island where there
## is room for it, a lake in the middle of the map between the districts, and the river.
##
## The river finds the roomiest way over the sheet, never through a landmark or its ticket, under a
## road by a bridge where it must and through a district where it will. Where there is a lake
## between the districts it runs down the valley between them from the top of the sheet to its
## foot, through the moat and through the lake; elsewhere across or down, whichever way has more
## room. It wanders, widens on its way, and has a lake of its own where it has most room; the lakes
## have reeds and the middle one a boat; the river and the lakes are named.

## The river: the size of a place of the coarse grid it finds its way over, and what it costs it to
## run through a place near a landmark or the furniture, to go under a road by a bridge, to run
## along the paper's edge, and through water already there; how much room it keeps; how far it
## wanders off its way, a share of a place of the grid.
const CELL := 40.0
const NEAR_COST := 5.0
const ROAD_COST := 5.0
const EDGE_COST := 6.0
const EDGE_ROOM := 4
const WATER_COST := 0.3
const ROOM := 18.0
const WANDER := 0.42
## The river's own lake, how far across and down at most, and how far from a bridge, another lake
## or the paper's edge; the lake between the districts, how far across and down at most and least,
## and how much room it keeps from the moat and the slip road.
const LAKE := Vector2(84.0, 34.0)
const LAKE_CLEAR := 200.0
const MIDDLE_LAKE := Vector2(130.0, 64.0)
const MIDDLE_LAKE_LEAST := Vector2(60.0, 30.0)
const MIDDLE_ROOM := 34.0
## How long a bridge over the river is; how much wider than the roundabout its island is, and the
## least and the most of water round the island, as far as there is room, and how far it keeps off
## the paper's edge.
const BRIDGE := 30.0
const ISLAND := 18.0
const MOAT_LEAST := 34.0
const MOAT_MOST := 96.0
const MOAT_EDGE := 44.0
## The water's names: the lake between the districts, the river's own, and the river.
const MIDDLE_LAKE_NAME := "Bluff Lake"
const LAKE_NAME := "Lake Ante"
const RIVER_NAME := "The River"

var land: LoyaltyMapLand
var layout: LoyaltyMapLayout


## Lays out the water of the House's sheet [member LoyaltyMapLand.layout] for [param on].
static func lay(on: LoyaltyMapLand) -> void:
	var water := LoyaltyMapWater.new()
	water.land = on
	water.layout = on.layout
	water._lay_moat()
	var middle := water._lay_middle_lake()
	water._lay_river(middle)


## The water round the roundabout's island, where there is room for it: as far out as the nearest
## landmark, its ticket, a road that does not run into the ring, the furniture and the paper's edge
## let it, its edge drawn by hand; a bridge over it on each road into the ring.
func _lay_moat() -> void:
	var middle := layout.ring_middle
	# Clear of the rule round the paper's edge.
	var room := (
		minf(minf(middle.x, layout.paper.x - middle.x), minf(middle.y, layout.paper.y - middle.y))
		- MOAT_EDGE
	)
	for rect: Rect2 in _keep_off():
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
	land.take_rect(Rect2(middle - Vector2.ONE * reach, Vector2.ONE * reach * 2.0), land.water)


## Every landmark's room, the districts' names and the furniture, which the water keeps off.
func _keep_off() -> Array[Rect2]:
	var rects: Array[Rect2] = [layout.legend, layout.cartouche]
	for id: StringName in layout.points:
		rects.append(layout.room_of(id))
	for district: int in layout.names_at:
		rects.append(Rect2(layout.names_at[district] - Vector2(0.0, 30.0), Vector2(340.0, 44.0)))
	return rects


## The lake in the middle of the map, between the roundabout over the districts and the slip road
## under them, as big as there is room for there, where there is room for one; its name beside it,
## reeds on its shore and a boat on it. Gives back its middle, none, (0, 0), where there is none.
func _lay_middle_lake() -> Vector2:
	var slip := layout.points.get(&"slip_road", Vector2.ZERO) as Vector2
	if layout.ring <= 0.0 or slip.y <= layout.ring_middle.y:
		return Vector2.ZERO
	var under_ring := layout.ring + ISLAND
	if layout.moat.size() > 2:
		for point: Vector2 in layout.moat:
			under_ring = maxf(under_ring, point.y - layout.ring_middle.y)
	var top := layout.ring_middle.y + under_ring + MIDDLE_ROOM
	var foot := layout.sign_rect(&"slip_road").position.y - MIDDLE_ROOM
	var middle := Vector2(layout.ring_middle.x, (top + foot) * 0.5)
	var reach := Vector2(MIDDLE_LAKE.x, minf(MIDDLE_LAKE.y, (foot - top) * 0.5))
	# As wide as there is room for, between whatever stands either side of it.
	while reach.x >= MIDDLE_LAKE_LEAST.x:
		if not land.is_rect_taken(Rect2(middle - reach, reach * 2.0)):
			break
		reach.x -= 10.0
		reach.y = maxf(reach.y - 3.0, MIDDLE_LAKE_LEAST.y)
	if reach.x < MIDDLE_LAKE_LEAST.x or reach.y < MIDDLE_LAKE_LEAST.y:
		return Vector2.ZERO
	var oval := PackedVector2Array()
	for i: int in 32:
		var angle := TAU * i / 32.0
		var swell := 1.0 + 0.12 * sin(angle * 2.0 + 0.6) + 0.06 * sin(angle * 5.0)
		oval.append(middle + Vector2(cos(angle), sin(angle)) * reach * swell)
	layout.lakes.append(LoyaltyMapLayout.by_hand(oval, "middle lake", 8.0, 11.0))
	land.take_rect(Rect2(middle - reach, reach * 2.0), land.water)
	layout.doodles.append(
		{
			"kind": &"boat",
			"at": middle + Vector2(reach.x * 0.35, -reach.y * 0.25),
			"size": 26.0,
			"turn": 0.12
		}
	)
	var font := LoyaltyMapPrint.place_font()
	var size := LoyaltyMapPrint.PLACE_SIZE
	var half := font.get_string_size(MIDDLE_LAKE_NAME, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
	for at: Vector2 in [
		middle + Vector2(0.0, reach.y + 30.0),
		middle - Vector2(0.0, reach.y + 14.0),
		middle + Vector2(reach.x + half + 12.0, 5.0),
		middle - Vector2(reach.x + half + 12.0, -5.0),
	]:
		if land.name_place(MIDDLE_LAKE_NAME, at, true):
			break
	_shore(layout.lakes[-1], "middle lake")
	return middle


## Reeds on a few clear places of the shore of [param lake], by [param seed].
func _shore(lake: PackedVector2Array, seed: String) -> void:
	var middle := LoyaltyMapLand.middle_of(lake)
	var dice := RandomNumberGenerator.new()
	dice.seed = hash(seed)
	var laid := 0
	for i: int in range(0, lake.size(), maxi(lake.size() / 9, 1)):
		if laid >= 4 or dice.randf() > 0.6:
			continue
		var at := lake[i] + (lake[i] - middle).normalized() * 10.0
		if land.inside(at) and not land.is_taken(at, 8.0):
			layout.doodles.append({"kind": &"reeds", "at": at, "size": 22.0, "turn": 0.0})
			land.take(at, 9.0)
			laid += 1


## The river over the sheet, see the class's description: down the valley through the lake between
## the districts at [param middle] where there is one, else across or down, whichever has more
## room; wandering, its corners rounded; its bridges, its own lake and its name.
func _lay_river(middle: Vector2) -> void:
	var cells := Vector2i((layout.paper / CELL).ceil())
	var grid := _grid(cells)
	var away := _away(cells, grid)
	var way: Array = []
	if middle != Vector2.ZERO:
		way = _way(cells, grid, away, false, Vector2i((middle / CELL).floor()))
	if way.is_empty() or is_inf(way[1]):
		var across := _way(cells, grid, away, true)
		var down := _way(cells, grid, away, false)
		way = across if across[1] <= down[1] else down
	var path: Array[Vector2i] = way[0]
	if path.size() < 4:
		return
	var across_it: bool = way[2]
	var nodes := _wandered(path, away, cells, grid)
	# Out to the paper's edge at either end, and no further.
	if across_it:
		nodes[0].x = 0.0
		nodes[-1].x = layout.paper.x
	else:
		nodes[0].y = 0.0
		nodes[-1].y = layout.paper.y
	layout.river = LoyaltyMapLayout.rounded(nodes, 3)
	_lay_bridges()
	_lay_lake(path, away)
	_name_river(across_it)
	land.take_line(layout.river, ROOM + 4.0)


## The coarse grid of the paper the river finds its way over, a byte a place: 2 where something it
## keeps off is, 1 where a road alone is, 3 where water already is, and 0 where nothing is.
func _grid(cells: Vector2i) -> PackedByteArray:
	var grid := PackedByteArray()
	grid.resize(cells.x * cells.y)
	var per := int(CELL / LoyaltyMapLand.CLEAR)
	for y: int in cells.y:
		for x: int in cells.x:
			var what := 0
			var wet := false
			for dy: int in per:
				for dx: int in per:
					var place := Vector2i(x * per + dx, y * per + dy)
					wet = wet or land.water.has(place)
					if land.solid.has(place):
						what = 2
					elif land.road.has(place):
						what = maxi(what, 1)
			grid[y * cells.x + x] = 3 if wet and what != 2 else what
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
## aside, and through the place [param through] where it is given; its places, what it cost a
## step, INF where there is none, and whether it runs across.
func _way(
	cells: Vector2i,
	grid: PackedByteArray,
	away: PackedInt32Array,
	across: bool,
	through := Vector2i(-1, -1)
) -> Array:
	var along := cells.x if across else cells.y
	var aside := cells.y if across else cells.x
	var best := PackedFloat32Array()
	best.resize(along * aside)
	var came := PackedInt32Array()
	came.resize(along * aside)
	var at_stage := through.x if across else through.y
	var at_side := through.y if across else through.x
	for a: int in along:
		for s: int in aside:
			var cell := Vector2i(a, s) if across else Vector2i(s, a)
			var i := cell.y * cells.x + cell.x
			var cost := INF
			if grid[i] != 2 and (a != at_stage or absi(s - at_side) <= 1):
				cost = 1.0 + NEAR_COST / pow(float(away[i]) + 0.5, 2.0)
				cost += ROAD_COST if grid[i] == 1 else 0.0
				cost += EDGE_COST if s < EDGE_ROOM or s >= aside - EDGE_ROOM else 0.0
				cost = WATER_COST if grid[i] == 3 else cost
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
		return [path, INF, across]
	var s := end
	for a: int in range(along - 1, -1, -1):
		path.push_front(Vector2i(a, s) if across else Vector2i(s, a))
		s = came[a * aside + s]
	return [path, cost_all / float(along), across]


## The points of the river's [param path], each moved a little aside of the way it runs by slow
## swells along it, as far as the room round it lets it, never in water already there.
func _wandered(
	path: Array[Vector2i], away: PackedInt32Array, cells: Vector2i, grid: PackedByteArray
) -> PackedVector2Array:
	var nodes := PackedVector2Array()
	var phase := LoyaltyMapLayout.roll("river wander") * TAU
	for i: int in path.size():
		var at := (Vector2(path[i]) + Vector2.ONE * 0.5) * CELL
		var k := path[i].y * cells.x + path[i].x
		if i > 0 and i < path.size() - 1 and grid[k] != 3:
			var flow := Vector2(path[i + 1] - path[i - 1]).normalized()
			var room := clampf(float(away[k]) - 1.0, 0.0, 1.0)
			var swing := sin(i * 0.8 + phase) * 0.7 + sin(i * 0.31 + phase * 2.0) * 0.3
			at += flow.orthogonal() * swing * room * WANDER * CELL
		nodes.append(at)
	return nodes


## A bridge wherever one of the House's roads crosses the river, [constant BRIDGE] long along the
## road. The river's stretches are found by the place of the paper they are in, so each road is
## tried against those near it alone.
func _lay_bridges() -> void:
	var river := layout.river
	var near := {}
	for i: int in range(1, river.size()):
		for at: Vector2 in [river[i - 1], river[i]]:
			var place := Vector2i((at / CELL).floor())
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
				for i: int in near.get(Vector2i((at / CELL).floor()), []):
					if tried.has(i):
						continue
					tried[i] = true
					var hit: Variant = Geometry2D.segment_intersects_segment(
						a, b, river[i - 1], river[i]
					)
					if hit != null and not _is_wet(hit):
						var way := (b - a).normalized() * BRIDGE * 0.5
						layout.bridges.append(PackedVector2Array([hit - way, hit + way]))


## Whether [param at] is in a lake or the moat, where the moat's own bridges carry its roads.
func _is_wet(at: Vector2) -> bool:
	if layout.moat.size() > 2 and Geometry2D.is_point_in_polygon(at, layout.moat):
		return true
	for lake: PackedVector2Array in layout.lakes:
		if Geometry2D.is_point_in_polygon(at, lake):
			return true
	return false


## The river's own lake where it has most room along [param path], away from any bridge, the
## other lakes and the paper's edges: an oval along the river as long as there is room for, its
## edge drawn by hand, its name beside it and reeds on its shore.
func _lay_lake(path: Array[Vector2i], away: PackedInt32Array) -> void:
	var cells := int(ceil(layout.paper.x / CELL))
	var avoid: Array[Vector2] = []
	for bridge: PackedVector2Array in layout.bridges:
		avoid.append(bridge[0])
	for lake: PackedVector2Array in layout.lakes:
		avoid.append(LoyaltyMapLand.middle_of(lake))
	if layout.moat.size() > 2:
		avoid.append(layout.ring_middle)
	var best := -1
	var clear_of := Rect2(
		Vector2.ONE * LAKE_CLEAR * 0.6, layout.paper - Vector2.ONE * LAKE_CLEAR * 1.2
	)
	for i: int in range(2, path.size() - 2):
		var at := (Vector2(path[i]) + Vector2.ONE * 0.5) * CELL
		if not clear_of.has_point(at) or LoyaltyMapLand.furthest(at, avoid) <= LAKE_CLEAR:
			continue
		var room := away[path[i].y * cells + path[i].x]
		if best < 0 or room > away[path[best].y * cells + path[best].x]:
			best = i
	if best < 0:
		return
	var room := float(away[path[best].y * cells + path[best].x]) * CELL - CELL * 0.5
	var reach := Vector2(minf(LAKE.x, room * 1.6), minf(LAKE.y, room * 0.8))
	if reach.y < LAKE.y * 0.6:
		return
	var middle := _nearest_on_river((Vector2(path[best]) + Vector2.ONE * 0.5) * CELL)
	var flow := (Vector2(path[best + 1] - path[best - 1])).normalized()
	var oval := PackedVector2Array()
	for i: int in 28:
		var angle := TAU * i / 28.0
		var out := Vector2(cos(angle), sin(angle) * (1.0 + 0.2 * sin(angle * 3.0))) * reach
		oval.append(middle + out.rotated(flow.angle()))
	layout.lakes.append(LoyaltyMapLayout.by_hand(oval, "lake", 7.0, 10.0))
	land.take_rect(Rect2(middle - Vector2.ONE * reach.x, Vector2.ONE * reach.x * 2.0), land.water)
	var under := Vector2(0.0, maxf(absf(reach.rotated(flow.angle()).y), reach.y) + 30.0)
	var aside := Vector2(maxf(absf(reach.rotated(flow.angle()).x), reach.x) + 60.0, 5.0)
	for at: Vector2 in [
		middle + under, middle - under + Vector2(0.0, 16.0), middle + aside, middle - aside
	]:
		if land.name_place(LAKE_NAME, at, true):
			break
	_shore(layout.lakes[-1], "lake")


## The point of the river nearest [param at].
func _nearest_on_river(at: Vector2) -> Vector2:
	var best := layout.river[0]
	for point: Vector2 in layout.river:
		if point.distance_squared_to(at) < best.distance_squared_to(at):
			best = point
	return best


## The river's name beside it, where it runs furthest from the lakes, the bridges and its ends:
## over it where it runs [param across], and beside it where it runs down.
func _name_river(across: bool) -> void:
	var avoid: Array[Vector2] = [layout.river[0], layout.river[-1]]
	for bridge: PackedVector2Array in layout.bridges:
		avoid.append(bridge[0])
	for lake: PackedVector2Array in layout.lakes:
		avoid.append(LoyaltyMapLand.middle_of(lake))
	if layout.moat.size() > 2:
		avoid.append(layout.ring_middle)
	var tried: Array[Vector2] = []
	for i: int in range(0, layout.river.size(), 6):
		tried.append(layout.river[i])
	tried.sort_custom(
		func(a: Vector2, b: Vector2) -> bool:
			return LoyaltyMapLand.furthest(a, avoid) > LoyaltyMapLand.furthest(b, avoid)
	)
	var font := LoyaltyMapPrint.place_font()
	var size := LoyaltyMapPrint.PLACE_SIZE
	var wide := font.get_string_size(RIVER_NAME, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	for at: Vector2 in tried.slice(0, 8):
		var off := Vector2(0.0, -12.0) if across else Vector2(wide * 0.5 + 14.0, 4.0)
		if land.name_place(RIVER_NAME, at + off, true):
			return
		if land.name_place(RIVER_NAME, at - off + Vector2(0.0, 12.0), true):
			return
