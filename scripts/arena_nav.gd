class_name ArenaNav
extends RefCounted
## Pathfinding over the arena grid with AStarGrid2D: walls, crates and pits are solid, crates
## come and go. Paths are lists of cell centers in world space.
##
## Pits need more than being solid. A wall stops a kart that cuts a corner; a pit swallows it,
## and nothing on the way to one gets in the way of a raycast, so anything taking a short cut
## has to ask [method crosses_pit] first.

var grid: ArenaGrid
var astar := AStarGrid2D.new()


func _init(arena_grid: ArenaGrid) -> void:
	grid = arena_grid
	astar.region = Rect2i(0, 0, grid.width, grid.height)
	astar.cell_size = Vector2(grid.cell_size, grid.cell_size)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	astar.update()
	for rect: Rect2i in grid.walls:
		astar.fill_solid_region(rect, true)
	for rect: Rect2i in grid.pits:
		astar.fill_solid_region(rect, true)
	for cell: Vector2i in grid.crates:
		astar.set_point_solid(cell, true)


## Whether a cell is part of a pit rather than merely blocked.
func is_pit(cell: Vector2i) -> bool:
	for rect: Rect2i in grid.pits:
		if rect.has_point(cell):
			return true
	return false


## Whether a pit lies over this point.
func is_pit_at(point: Vector3) -> bool:
	return is_pit(world_to_cell(point))


## Whether a pit lies within [param margin] of this point. A kart goes down a hole when any
## corner of it touches the hole, not when its middle arrives, so anything asking "may I drive
## here" has to ask about a body rather than about a point.
func is_pit_within(point: Vector3, margin: float) -> bool:
	for rect: Rect2i in grid.pits:
		var center := grid.rect_center(rect)
		var half := grid.rect_size(rect) * 0.5 + Vector2.ONE * margin
		if absf(point.x - center.x) <= half.x and absf(point.z - center.z) <= half.y:
			return true
	return false


## Whether the straight line between two points passes over a pit, allowing [param margin] of
## clearance around the hole. Sampled every half cell, which is finer than a kart is wide, so
## nothing slips between two samples.
func crosses_pit(from: Vector3, to: Vector3, margin: float = 0.0) -> bool:
	var span := Vector2(to.x - from.x, to.z - from.z)
	var steps := maxi(ceili(span.length() / (grid.cell_size * 0.5)), 1)
	for i: int in steps + 1:
		var at := from.lerp(to, float(i) / float(steps))
		if is_pit_within(at, margin) if margin > 0.0 else is_pit_at(at):
			return true
	return false


## The middle of the first pit the line runs into, or [param from] when it meets none. What a
## kart has to turn out of is the hole it is about to reach, not the far end of its look-ahead.
func first_pit_center(from: Vector3, to: Vector3) -> Vector3:
	var span := Vector2(to.x - from.x, to.z - from.z)
	var steps := maxi(ceili(span.length() / (grid.cell_size * 0.5)), 1)
	for i: int in steps + 1:
		var cell := world_to_cell(from.lerp(to, float(i) / float(steps)))
		for rect: Rect2i in grid.pits:
			if rect.has_point(cell):
				return grid.rect_center(rect)
	return from


func world_to_cell(point: Vector3) -> Vector2i:
	var x := floori(point.x / grid.cell_size + grid.width * 0.5)
	var y := floori(point.z / grid.cell_size + grid.height * 0.5)
	return Vector2i(clampi(x, 0, grid.width - 1), clampi(y, 0, grid.height - 1))


func is_blocked(cell: Vector2i) -> bool:
	return astar.is_point_solid(cell)


func set_cell_blocked(cell: Vector2i, blocked: bool) -> void:
	astar.set_point_solid(cell, blocked)


## The closest walkable cell to [param cell], searching in growing rings.
func nearest_open_cell(cell: Vector2i) -> Vector2i:
	if not is_blocked(cell):
		return cell
	for ring: int in range(1, 6):
		for dy: int in range(-ring, ring + 1):
			for dx: int in range(-ring, ring + 1):
				if absi(dx) != ring and absi(dy) != ring:
					continue
				var candidate := cell + Vector2i(dx, dy)
				if astar.is_in_boundsv(candidate) and not is_blocked(candidate):
					return candidate
	return cell


## Waypoints from [param from] to [param to], excluding the start cell. Empty when no path exists.
func path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var start := nearest_open_cell(world_to_cell(from))
	var goal := nearest_open_cell(world_to_cell(to))
	var cells := astar.get_id_path(start, goal, true)
	var result: PackedVector3Array = []
	for i: int in cells.size():
		if i == 0 and cells.size() > 1:
			continue
		result.append(grid.cell_center(cells[i]))
	return result
