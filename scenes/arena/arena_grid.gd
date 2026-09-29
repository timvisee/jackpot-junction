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

const TURBO_GLYPHS: Array[String] = [TURBO_PAD, TURBO_UP, TURBO_DOWN, TURBO_LEFT, TURBO_RIGHT]
const AREA_GLYPHS: Array[String] = [PIT, JUNCTION, JACKPOT]
const KNOWN_GLYPHS: Array[String] = [
	WALL,
	FLOOR,
	SPAWN,
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
]

var width: int = 0
var height: int = 0
var cell_size: float = 1.25
var rows: PackedStringArray = []
var walls: Array[Rect2i] = []
var spawns: Array[Vector2i] = []
var coin_pads: Array[Vector2i] = []
var power_pads: Array[Vector2i] = []
var flush_pads: Array[Vector2i] = []
var targets: Array[Vector2i] = []
var joker_pads: Array[Vector2i] = []
var portals: Array[Vector2i] = []
var turbo_pads: Array[Vector2i] = []
var crates: Array[Vector2i] = []
var pits: Array[Rect2i] = []
var jackpots: Array[Rect2i] = []
var junction: Rect2i = Rect2i()


func world_size() -> Vector2:
	return Vector2(width, height) * cell_size


func glyph(cell: Vector2i) -> String:
	return rows[cell.y][cell.x]


func is_wall(cell: Vector2i) -> bool:
	return glyph(cell) == WALL


## World position of the center of a cell, on the floor plane.
func cell_center(cell: Vector2i) -> Vector3:
	return Vector3(
		(cell.x + 0.5 - width * 0.5) * cell_size, 0.0, (cell.y + 0.5 - height * 0.5) * cell_size
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
