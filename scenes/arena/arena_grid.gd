class_name ArenaGrid
extends RefCounted
## A parsed arena layout: wall rectangles and element positions in grid cells, plus cell to
## world conversion. Produced by [method ArenaLayout.parse].
##
## World space: x runs along columns, z along rows, the grid center sits at the origin and row 0
## is at negative z, which is the top of the screen.

const WALL := "#"
const FLOOR := "."
const SPAWN := "S"
## A spawn point for a room of more than four karts, GAME.md 6.3, see [member corner_spawns].
const EXTRA_SPAWN := "s"
const COIN_PAD := "C"
const POWER_PAD := "P"
const TURBO_PAD := "T"
const TURBO_UP := "^"
const TURBO_DOWN := "v"
const TURBO_LEFT := "<"
const TURBO_RIGHT := ">"
const CRATE := "B"
const PIT := "X"
const JUNCTION := "J"
const JACKPOT := "K"
const FLUSH_PAD := "F"
const TARGET := "R"
const JOKER_PAD := "D"
## A way through to the other practice room, GAME.md 9.4.
const PORTAL := "O"
## A piece of wall that opens and shuts, GAME.md 9.4a: floor to drive on once open, see [Gate].
const GATE := "G"
## The slot machine, GAME.md 3.15: a pad that bets a quarter of a pot driven onto it, see [SlotPad].
const SLOT_PAD := "$"
## A pop bumper, GAME.md 6.2: solid and round, and it throws a kart that drives into it straight
## back off its middle, see [Bumper].
const BUMPER := "@"

const TURBO_GLYPHS: Array[String] = [TURBO_PAD, TURBO_UP, TURBO_DOWN, TURBO_LEFT, TURBO_RIGHT]
const AREA_GLYPHS: Array[String] = [PIT, JUNCTION, JACKPOT, GATE]
const KNOWN_GLYPHS: Array[String] = [
	WALL,
	FLOOR,
	SPAWN,
	EXTRA_SPAWN,
	COIN_PAD,
	POWER_PAD,
	TURBO_PAD,
	TURBO_UP,
	TURBO_DOWN,
	TURBO_LEFT,
	TURBO_RIGHT,
	CRATE,
	PIT,
	JUNCTION,
	JACKPOT,
	FLUSH_PAD,
	TARGET,
	JOKER_PAD,
	PORTAL,
	GATE,
	SLOT_PAD,
	BUMPER,
]

var width: int = 0
var height: int = 0
var cell_size: float = 1.25
var rows: PackedStringArray = []
var walls: Array[Rect2i] = []
## Each run of gate cells, one gate, see [Gate].
var gates: Array[Rect2i] = []
var spawns: Array[Vector2i] = []
## How many of [member spawns] are the `S` ones, in the corners of every arena, which come first
## and are all a match uses while they hold everybody in it; the `s` ones after them are for the
## fifth kart on, GAME.md 6.3.
var corner_spawns := 0
var coin_pads: Array[Vector2i] = []
var power_pads: Array[Vector2i] = []
var flush_pads: Array[Vector2i] = []
var targets: Array[Vector2i] = []
var joker_pads: Array[Vector2i] = []
var slot_pads: Array[Vector2i] = []
var portals: Array[Vector2i] = []
var turbo_pads: Array[Vector2i] = []
var crates: Array[Vector2i] = []
## The pop bumpers, GAME.md 6.2, which unlike a crate are never shot away.
var bumpers: Array[Vector2i] = []
var pits: Array[Rect2i] = []
var jackpots: Array[Rect2i] = []
## The Junctions, GAME.md 3.4: one on most maps, several on the tutorial's, 9.4a.
var junctions: Array[Rect2i] = []
## The first Junction, or an empty rect, for whatever asks for the one.
var junction: Rect2i:
	get:
		return junctions[0] if not junctions.is_empty() else Rect2i()
## Which room each floor cell is in, see [method region_of], found on the first ask.
var _regions: Dictionary[Vector2i, int] = {}


## Whether [param rect] touches the edge of the grid: the arena's outer wall, GAME.md 8.1c.
func is_border(rect: Rect2i) -> bool:
	return (
		rect.position.x == 0 or rect.position.y == 0 or rect.end.x == width or rect.end.y == height
	)


func world_size() -> Vector2:
	return Vector2(width, height) * cell_size


func glyph(cell: Vector2i) -> String:
	return rows[cell.y][cell.x]


func is_wall(cell: Vector2i) -> bool:
	return glyph(cell) == WALL


## Which room [param cell] is in, GAME.md 9.4a: the cells that can be reached from one another
## without crossing a wall or a gate are one room, numbered from 0 in reading order, and a wall is
## -1. A map of one room is one room, which is every map but the tutorial's.
func region_of(cell: Vector2i) -> int:
	if _regions.is_empty():
		_find_regions()
	return _regions.get(cell, -1)


func _find_regions() -> void:
	var next := 0
	for y: int in height:
		for x: int in width:
			var start := Vector2i(x, y)
			if _solid(start) or _regions.has(start):
				continue
			_regions[start] = next
			var stack: Array[Vector2i] = [start]
			while not stack.is_empty():
				var cell: Vector2i = stack.pop_back()
				for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var near := cell + offset
					if near.x < 0 or near.y < 0 or near.x >= width or near.y >= height:
						continue
					if _solid(near) or _regions.has(near):
						continue
					_regions[near] = next
					stack.append(near)
			next += 1


func _solid(cell: Vector2i) -> bool:
	var glyph_here := glyph(cell)
	return glyph_here == WALL or glyph_here == GATE


## World position of the center of a cell, on the floor plane.
func cell_center(cell: Vector2i) -> Vector3:
	return Vector3(
		(cell.x + 0.5 - width * 0.5) * cell_size, 0.0, (cell.y + 0.5 - height * 0.5) * cell_size
	)


## The cell under [param point] on the floor plane, the reverse of [method cell_center].
func cell_of(point: Vector3) -> Vector2i:
	return Vector2i(
		floori(point.x / cell_size + width * 0.5), floori(point.z / cell_size + height * 0.5)
	)


## World position of the center of a rectangle of cells, on the floor plane.
func rect_center(rect: Rect2i) -> Vector3:
	var center := Vector2(rect.position) + Vector2(rect.size) * 0.5
	return Vector3((center.x - width * 0.5) * cell_size, 0.0, (center.y - height * 0.5) * cell_size)


func rect_size(rect: Rect2i) -> Vector2:
	return Vector2(rect.size) * cell_size


## Launch direction of a turbo pad. Arrow glyphs are explicit; a plain T pad points along its
## column toward the far half of the arena, so pads in the top half fire downward.
func turbo_direction(cell: Vector2i) -> Vector3:
	match glyph(cell):
		TURBO_UP:
			return Vector3(0.0, 0.0, -1.0)
		TURBO_DOWN:
			return Vector3(0.0, 0.0, 1.0)
		TURBO_LEFT:
			return Vector3(-1.0, 0.0, 0.0)
		TURBO_RIGHT:
			return Vector3(1.0, 0.0, 0.0)
	return Vector3(0.0, 0.0, 1.0) if cell.y < height / 2 else Vector3(0.0, 0.0, -1.0)


## The turbo pads grouped into sections, GAME.md 6.3: pads side by side that fire the same way,
## as the rectangle of cells they make up, so they launch as one pad. A group that is not a
## rectangle stays a pad a cell.
func turbo_sections() -> Array[Rect2i]:
	var sections: Array[Rect2i] = []
	var placed: Dictionary[Vector2i, bool] = {}
	for start: Vector2i in turbo_pads:
		if placed.has(start):
			continue
		var way := turbo_direction(start)
		var group: Array[Vector2i] = [start]
		placed[start] = true
		var i := 0
		while i < group.size():
			for step: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
				var next := group[i] + step
				if placed.has(next) or next not in turbo_pads or turbo_direction(next) != way:
					continue
				placed[next] = true
				group.append(next)
			i += 1
		var bounds := Rect2i(start, Vector2i.ONE)
		for cell: Vector2i in group:
			bounds = bounds.merge(Rect2i(cell, Vector2i.ONE))
		if bounds.get_area() == group.size():
			sections.append(bounds)
		else:
			for cell: Vector2i in group:
				sections.append(Rect2i(cell, Vector2i.ONE))
	return sections


## True when the layout reads the same after a 180 degree rotation, ignoring arrow glyphs.
func is_point_symmetric() -> bool:
	for y: int in height:
		for x: int in width:
			var a := glyph(Vector2i(x, y))
			var b := glyph(Vector2i(width - 1 - x, height - 1 - y))
			if a in TURBO_GLYPHS and b in TURBO_GLYPHS:
				continue
			if a != b:
				return false
	return true


func wall_cell_count() -> int:
	var count := 0
	for row: String in rows:
		count += row.count(WALL)
	return count
