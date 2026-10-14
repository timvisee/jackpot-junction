class_name ArenaLayout
extends Resource
## A map as an ASCII grid. The legend is in GAME.md section 6.3: # wall, . floor, S spawn,
## s spawn past four karts, C coin pad, P power-up pad, F Royal Flush pad, R shooting target,
## D joker pad, T turbo pad (^ v < > for an explicit direction), B crate, X pit, J Junction pad,
## K Jackpot zone, O portal, $ slot machine.
## Connected X, J and K cells form one rectangular area each.

@export_multiline var grid: String = ""
@export var cell_size: float = 1.25
@export var wall_height: float = 1.0
## The room this map is played in, GAME.md 8.1: the light, the surfaces and the crowd around the
## table. A map without one is played in the default room rather than in the dark.
@export var room: RoomLook


## Non-empty lines of the grid with surrounding whitespace removed.
func lines() -> PackedStringArray:
	var result: PackedStringArray = []
	for line: String in grid.split("\n"):
		var trimmed := line.strip_edges()
		if not trimmed.is_empty():
			result.append(trimmed)
	return result


## Problems with the grid, empty when it is valid.
func validate() -> PackedStringArray:
	var problems: PackedStringArray = []
	var rows := lines()
	if rows.size() < 3:
		problems.append("grid needs at least 3 rows")
		return problems
	var width := rows[0].length()
	for y: int in rows.size():
		var row := rows[y]
		if row.length() != width:
			problems.append("row %d has length %d, expected %d" % [y, row.length(), width])
			continue
		for x: int in width:
			var glyph := row[x]
			if glyph not in ArenaGrid.KNOWN_GLYPHS:
				problems.append("unknown glyph '%s' at %d,%d" % [glyph, x, y])
			var on_border := x == 0 or y == 0 or x == width - 1 or y == rows.size() - 1
			if on_border and glyph != ArenaGrid.WALL:
				problems.append("border cell %d,%d is not a wall" % [x, y])
	return problems


## Parses the grid. Fails loudly on an invalid grid; check [method validate] first for input
## that is not trusted.
func parse() -> ArenaGrid:
	var problems := validate()
	assert(problems.is_empty(), "invalid arena layout: %s" % ", ".join(problems))
	var result := ArenaGrid.new()
	result.cell_size = cell_size
	result.rows = lines()
	result.height = result.rows.size()
	result.width = result.rows[0].length()
	_collect_elements(result)
	result.walls = _merge_walls(result)
	return result


func _collect_elements(target: ArenaGrid) -> void:
	var visited: Dictionary[Vector2i, bool] = {}
	var extra: Array[Vector2i] = []
	for y: int in target.height:
		for x: int in target.width:
			var cell := Vector2i(x, y)
			var glyph := target.glyph(cell)
			match glyph:
				ArenaGrid.SPAWN:
					target.spawns.append(cell)
				ArenaGrid.EXTRA_SPAWN:
					extra.append(cell)
				ArenaGrid.COIN_PAD:
					target.coin_pads.append(cell)
				ArenaGrid.POWER_PAD:
					target.power_pads.append(cell)
				ArenaGrid.FLUSH_PAD:
					target.flush_pads.append(cell)
				ArenaGrid.TARGET:
					target.targets.append(cell)
				ArenaGrid.JOKER_PAD:
					target.joker_pads.append(cell)
				ArenaGrid.SLOT_PAD:
					target.slot_pads.append(cell)
				ArenaGrid.PORTAL:
					target.portals.append(cell)
				ArenaGrid.CRATE:
					target.crates.append(cell)
				_:
					if glyph in ArenaGrid.TURBO_GLYPHS:
						target.turbo_pads.append(cell)
					elif glyph in ArenaGrid.AREA_GLYPHS and not visited.has(cell):
						var rect := _flood_rect(target, cell, glyph, visited)
						match glyph:
							ArenaGrid.PIT:
								target.pits.append(rect)
							ArenaGrid.JACKPOT:
								target.jackpots.append(rect)
							ArenaGrid.JUNCTION:
								target.junctions.append(rect)
							ArenaGrid.GATE:
								target.gates.append(rect)
	target.corner_spawns = target.spawns.size()
	_add_extra_spawns(target, extra)


## The spawns for the fifth kart on after the corners, GAME.md 6.3, each followed by its twin across
## the middle of the room, so a match of six has one more at each end rather than two at one.
static func _add_extra_spawns(target: ArenaGrid, extra: Array[Vector2i]) -> void:
	while not extra.is_empty():
		var cell: Vector2i = extra.pop_front()
		target.spawns.append(cell)
		var twin := Vector2i(target.width - 1 - cell.x, target.height - 1 - cell.y)
		if twin in extra:
			extra.erase(twin)
			target.spawns.append(twin)


## Bounding rectangle of the connected cells sharing a glyph, marking them visited.
func _flood_rect(
	target: ArenaGrid, start: Vector2i, glyph: String, visited: Dictionary[Vector2i, bool]
) -> Rect2i:
	var rect := Rect2i(start, Vector2i.ONE)
	var stack: Array[Vector2i] = [start]
	visited[start] = true
	while not stack.is_empty():
		var cell: Vector2i = stack.pop_back()
		rect = rect.expand(cell).expand(cell + Vector2i.ONE)
		for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := cell + offset
			if next.x < 0 or next.y < 0 or next.x >= target.width or next.y >= target.height:
				continue
			if visited.has(next) or target.glyph(next) != glyph:
				continue
			visited[next] = true
			stack.append(next)
	return rect


## Greedy rectangle cover of the wall cells: grow each rectangle right, then down.
func _merge_walls(target: ArenaGrid) -> Array[Rect2i]:
	var rects: Array[Rect2i] = []
	var covered: Dictionary[Vector2i, bool] = {}
	for y: int in target.height:
		for x: int in target.width:
			var start := Vector2i(x, y)
			if covered.has(start) or not target.is_wall(start):
				continue
			var run_width := 1
			while x + run_width < target.width:
				var next := Vector2i(x + run_width, y)
				if covered.has(next) or not target.is_wall(next):
					break
				run_width += 1
			var run_height := 1
			while (
				y + run_height < target.height
				and _is_wall_row(target, x, y + run_height, run_width, covered)
			):
				run_height += 1
			var rect := Rect2i(start, Vector2i(run_width, run_height))
			for cy: int in range(y, y + run_height):
				for cx: int in range(x, x + run_width):
					covered[Vector2i(cx, cy)] = true
			rects.append(rect)
	return rects


func _is_wall_row(
	target: ArenaGrid, x: int, y: int, run_width: int, covered: Dictionary[Vector2i, bool]
) -> bool:
	for cx: int in range(x, x + run_width):
		var cell := Vector2i(cx, y)
		if covered.has(cell) or not target.is_wall(cell):
			return false
	return true
