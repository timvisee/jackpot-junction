class_name ArenaNav
extends RefCounted
## Pathfinding over the arena grid with AStarGrid2D: walls, crates and pits are solid, crates
## come and go. Paths are lists of cell centers in world space.
##
## Pits need more than being solid. A wall stops a kart that cuts a corner; a pit swallows it,
## and nothing on the way to one gets in the way of a raycast, so anything taking a short cut
## asks the grid with [method clear_run] rather than a ray.

## What a cell right beside a pit costs a path to cross, against one for open floor, see
## [method _keep_off_the_holes].
const HOLE_SIDE := 4.0

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
	# A gate starts shut, GAME.md 9.4a, and the room opening one says so, see set_cell_blocked.
	for rect: Rect2i in grid.gates:
		astar.fill_solid_region(rect, true)
	_keep_off_the_holes()


## Makes the floor right round a pit dear to cross, GAME.md 9.1, so a path takes the cell beside a
## hole only when there is no other way worth the detour. A wall a path hugs costs a scrape; a hole
## costs a life, and the cell beside one leaves a kart a hand's width either side of falling in.
func _keep_off_the_holes() -> void:
	for rect: Rect2i in grid.pits:
		for y: int in range(rect.position.y - 1, rect.end.y + 1):
			for x: int in range(rect.position.x - 1, rect.end.x + 1):
				var cell := Vector2i(x, y)
				if astar.is_in_boundsv(cell) and not astar.is_point_solid(cell):
					astar.set_point_weight_scale(cell, HOLE_SIDE)


## Whether a cell is part of a pit rather than merely blocked.
func is_pit(cell: Vector2i) -> bool:
	for rect: Rect2i in grid.pits:
		if rect.has_point(cell):
			return true
	return false


## Whether a pit lies over this point.
func is_pit_at(point: Vector3) -> bool:
	return is_pit(world_to_cell(point))


## Whether a kart [param half_width] either side of the straight line from [param from] to
## [param to] can drive the whole of it without any of it over a wall, a crate or a hole, as the
## grid has them, GAME.md 9.1: the line and its two edges sampled every quarter cell, which is
## finer than any corner is sharp. A ray along the middle is not enough, since a kart is a meter
## across and the corner a ray just misses is the corner the kart scrapes.
func clear_run(from: Vector3, to: Vector3, half_width: float) -> bool:
	var span := Vector3(to.x - from.x, 0.0, to.z - from.z)
	var length := span.length()
	if length < 0.01:
		return not is_blocked(world_to_cell(to))
	var side := Vector3(-span.z, 0.0, span.x) / length * half_width
	var steps := ceili(length / (grid.cell_size * 0.25))
	for i: int in steps + 1:
		var at := from.lerp(to, float(i) / float(steps))
		if (
			is_blocked(world_to_cell(at))
			or is_blocked(world_to_cell(at + side))
			or is_blocked(world_to_cell(at - side))
		):
			return false
	return true


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
