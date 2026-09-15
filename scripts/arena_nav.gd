class_name ArenaNav
extends RefCounted
## Pathfinding over the arena grid with AStarGrid2D: walls, crates and pits are solid, crates
## come and go. Paths are lists of cell centres in world space.

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
