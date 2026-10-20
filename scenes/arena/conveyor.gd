class_name Conveyor
extends Node3D
## A conveyor belt, GAME.md 6.2: a run of `=` on a map, the Count Room's money-counting belt laid in
## the floor, that carries a kart on it along its length at [constant SPEED], driving or not, see
## [FloorCarry]. A belt runs along its longer side, toward +x in the top half of the room and -x in
## the bottom, toward +z in the left half and -z in the right, so a map's belts keep its point
## symmetry. Floor to everything else: shots fly over it and coins lie on it.
##
## Its slats run along with it, moved every frame rather than drawn in a shader of their own, so it
## compiles nothing the room has not.

## How fast a belt carries a kart, in meters a second, and how far a kart may stand past its edge,
## its middle, and still be on it.
const SPEED := 3.0
const EDGE := 0.15
## Its look: how deep the belt is set, the rubber and the slats across it, how far apart and how
## wide, and the rails either side.
const SLAT_GAP := 0.6
const SLAT := 0.22
const RUBBER := Color("#2B2A2E")
const SLATS := Color("#36353A")
const RAIL := Color("#A8ABB2")

## Which way it carries, flat and of length one.
var direction := Vector3.RIGHT
## Half its size, across x and along z.
var half := Vector2.ONE
var _match: Match
var _slats: Array[Node3D] = []
var _played := 0.0


## A belt for every run of `=` of [param arena]'s grid.
static func add_to(arena: Arena) -> void:
	var grid := arena.grid
	if grid.belts.is_empty():
		return
	var holder := Node3D.new()
	holder.name = "Belts"
	arena.add_child(holder)
	for i: int in grid.belts.size():
		var rect := grid.belts[i]
		var belt := Conveyor.new()
		belt.name = "Belt%d" % i
		belt.position = grid.rect_center(rect)
		var size := grid.rect_size(rect)
		belt.half = size * 0.5
		belt.direction = way(grid, rect)
		belt._dress(arena.surfaces)
		holder.add_child(belt)


## Which way the belt over [param rect] of [param grid] carries, see the top of this.
static func way(grid: ArenaGrid, rect: Rect2i) -> Vector3:
	var middle := Vector2(rect.position) + Vector2(rect.size) * 0.5
	if rect.size.x >= rect.size.y:
		return Vector3.RIGHT if middle.y < grid.height * 0.5 else Vector3.LEFT
	return Vector3.BACK if middle.x < grid.width * 0.5 else Vector3.FORWARD


func _ready() -> void:
	add_to_group(FloorCarry.GROUP)
	var node := get_parent()
	while node != null and not node is Match:
		node = node.get_parent()
	_match = node as Match


## How fast the belt moves [param kart], see [FloorCarry]: along it at [constant SPEED] while the
## kart's middle is on it, and not at all otherwise or for a kart of another match.
func carry_at(kart: Kart) -> Vector3:
	if _match != null and not _match.is_ancestor_of(kart):
		return Vector3.ZERO
	var local := kart.global_position - global_position
	if absf(local.x) > half.x + EDGE or absf(local.z) > half.y + EDGE:
		return Vector3.ZERO
	return direction * SPEED


func _process(delta: float) -> void:
	_played = LiveCabinet.clock(_match, _played, delta)
	var length := (half.x if absf(direction.x) > 0.5 else half.y) * 2.0
	var shift := fmod(_played * SPEED, SLAT_GAP)
	for i: int in _slats.size():
		var along := fmod(float(i) * SLAT_GAP + shift, length) - length * 0.5
		_slats[i].position = direction * along + Vector3.UP * 0.012


## The belt in the floor: dark rubber between two steel rails, slats across it running with it, and
## a roller at each end.
func _dress(surfaces: Surfaces) -> void:
	var along_x := absf(direction.x) > 0.5
	var length := half.x * 2.0 if along_x else half.y * 2.0
	var wide := half.y * 2.0 if along_x else half.x * 2.0
	var size := Vector3(length, 0.02, wide) if along_x else Vector3(wide, 0.02, length)
	ToyParts.box(self, size, surfaces.sheet(RUBBER), Vector3.UP * 0.005)
	var rail := surfaces.metal(RAIL)
	var across := Vector3.BACK if along_x else Vector3.RIGHT
	for side: float in [-1.0, 1.0]:
		var rail_size := Vector3(length, 0.05, 0.08) if along_x else Vector3(0.08, 0.05, length)
		ToyParts.box(
			self, rail_size, rail, across * side * (wide * 0.5 - 0.04) + Vector3.UP * 0.025
		)
	var slat_size := (
		Vector3(SLAT, 0.012, wide - 0.2) if along_x else Vector3(wide - 0.2, 0.012, SLAT)
	)
	var skin := surfaces.sheet(SLATS)
	for i: int in floori(length / SLAT_GAP):
		_slats.append(ToyParts.box(self, slat_size, skin, Vector3.ZERO))
