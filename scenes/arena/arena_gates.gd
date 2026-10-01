class_name ArenaGates
extends RefCounted
## Puts a map's gates down, GAME.md 9.4a: one for every run of G cells, a piece of the room's wall
## that the room running the map opens and shuts, see [Gate]. Apart from the walls, since these
## move and the walls are baked, and apart from [Arena], which has no room left in it.


## The gates of [param arena]'s grid, built under a holder of their own.
static func build(arena: Arena) -> Array[Gate]:
	var holder := Node3D.new()
	holder.name = "Gates"
	arena.add_child(holder)
	var made: Array[Gate] = []
	var grid := arena.grid
	for i: int in grid.gates.size():
		var rect := grid.gates[i]
		var size2 := grid.rect_size(rect)
		var gate := Gate.new()
		gate.name = "Gate%d" % i
		for y: int in range(rect.position.y, rect.end.y):
			for x: int in range(rect.position.x, rect.end.x):
				gate.cells.append(Vector2i(x, y))
		gate.build(grid.rect_center(rect), Vector3(size2.x, arena.layout.wall_height, size2.y))
		holder.add_child(gate)
		made.append(gate)
	return made
