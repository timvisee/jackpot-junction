class_name Arena
extends Node3D
## Builds the arena from an [ArenaLayout]: table, floor, walls, pads, zones and spawn points.
## Everything is a grey box for now; the art pass replaces meshes and materials, not structure.

const FLOOR_THICKNESS := 0.2
const TABLE_OVERHANG := 30.0
const PAD_HEIGHT := 0.05
const PIT_COLOR := Color("#0B0B0E")
const JUNCTION_BASE_COLOR := Color("#1E1E24")

@export var layout: ArenaLayout

var grid: ArenaGrid
var spawn_points: Array[Vector3] = []
var turbo_pads: Array[TurboPad] = []
var pits: Array[Pit] = []
var crates: Array[Crate] = []
var junction_position := Vector3.ZERO
var junction_radius := 2.5
var jackpot_positions: Array[Vector3] = []

var _materials: Dictionary[Color, StandardMaterial3D] = {}


func _ready() -> void:
	if layout != null and grid == null:
		build()


## Rebuilds every child from the layout.
func build() -> void:
	grid = layout.parse()
	for child: Node in get_children():
		child.queue_free()
	spawn_points.clear()
	turbo_pads.clear()
	pits.clear()
	crates.clear()
	jackpot_positions.clear()
	_add_table()
	_add_floor()
	_add_walls()
	_add_spawns()
	_add_coin_pads()
	_add_power_pads()
	_add_turbo_pads()
	_add_crates()
	_add_pits()
	_add_junction()
	_add_jackpots()


func world_size() -> Vector2:
	return grid.world_size()


## Bounding box of the playable area including the walls, for camera framing.
func bounds() -> AABB:
	var size := world_size()
	return AABB(
		Vector3(-size.x * 0.5, 0.0, -size.y * 0.5), Vector3(size.x, layout.wall_height, size.y)
	)


func _add_table() -> void:
	var size := world_size()
	var table := _box_mesh(
		Vector3(size.x + TABLE_OVERHANG, 0.5, size.y + TABLE_OVERHANG), Palette.TABLE
	)
	table.name = "Table"
	table.position = Vector3(0.0, -FLOOR_THICKNESS - 0.25, 0.0)
	add_child(table)


func _add_floor() -> void:
	var size := world_size()
	var floor_mesh := _box_mesh(Vector3(size.x, FLOOR_THICKNESS, size.y), Palette.FELT)
	floor_mesh.name = "Floor"
	floor_mesh.position = Vector3(0.0, -FLOOR_THICKNESS * 0.5, 0.0)
	add_child(floor_mesh)


func _add_walls() -> void:
	var walls := Node3D.new()
	walls.name = "Walls"
	add_child(walls)
	for i: int in grid.walls.size():
		var rect := grid.walls[i]
		var size2 := grid.rect_size(rect)
		var size := Vector3(size2.x, layout.wall_height, size2.y)
		var body := StaticBody3D.new()
		body.name = "Wall%d" % i
		body.collision_layer = Layers.WORLD
		body.collision_mask = 0
		body.position = grid.rect_center(rect) + Vector3(0.0, layout.wall_height * 0.5, 0.0)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		body.add_child(_box_mesh(size, Palette.BLOCK))
		walls.add_child(body)


func _add_spawns() -> void:
	for i: int in grid.spawns.size():
		var position := grid.cell_center(grid.spawns[i])
		spawn_points.append(position)
		var marker := Marker3D.new()
		marker.name = "Spawn%d" % i
		marker.position = position
		add_child(marker)
		var disc := _disc_mesh(0.5, Palette.MARKING_CREAM)
		disc.position = Vector3(0.0, PAD_HEIGHT * 0.5, 0.0)
		marker.add_child(disc)


func _add_coin_pads() -> void:
	var pads := Node3D.new()
	pads.name = "CoinPads"
	add_child(pads)
	for cell: Vector2i in grid.coin_pads:
		var disc := _disc_mesh(0.45, Palette.MARKING_YELLOW)
		disc.position = grid.cell_center(cell) + Vector3(0.0, PAD_HEIGHT * 0.5, 0.0)
		pads.add_child(disc)


func _add_power_pads() -> void:
	var pads := Node3D.new()
	pads.name = "PowerPads"
	add_child(pads)
	for cell: Vector2i in grid.power_pads:
		var disc := _disc_mesh(0.6, Palette.NEON_MAGENTA)
		disc.position = grid.cell_center(cell) + Vector3(0.0, PAD_HEIGHT * 0.5, 0.0)
		pads.add_child(disc)


func _add_turbo_pads() -> void:
	var pads := Node3D.new()
	pads.name = "TurboPads"
	add_child(pads)
	for i: int in grid.turbo_pads.size():
		var cell := grid.turbo_pads[i]
		var pad := TurboPad.new()
		pad.name = "TurboPad%d" % i
		pad.direction = grid.turbo_direction(cell)
		pad.position = grid.cell_center(cell)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(grid.cell_size, 1.0, grid.cell_size)
		shape.shape = box
		shape.position = Vector3(0.0, 0.5, 0.0)
		pad.add_child(shape)
		var plate := _box_mesh(
			Vector3(grid.cell_size, PAD_HEIGHT, grid.cell_size), Palette.NEON_CYAN
		)
		plate.position = Vector3(0.0, PAD_HEIGHT * 0.5, 0.0)
		pad.add_child(plate)
		var arrow := _arrow_mesh(Palette.CHIP_WHITE)
		arrow.position = Vector3(0.0, PAD_HEIGHT + 0.03, 0.0)
		arrow.look_at_from_position(arrow.position, arrow.position + pad.direction, Vector3.UP)
		pad.add_child(arrow)
		pads.add_child(pad)
		turbo_pads.append(pad)


func _add_crates() -> void:
	var container := Node3D.new()
	container.name = "Crates"
	add_child(container)
	var size := Vector3(1.0, 1.0, 1.0)
	for i: int in grid.crates.size():
		var crate := Crate.new()
		crate.name = "Crate%d" % i
		crate.position = grid.cell_center(grid.crates[i]) + Vector3(0.0, 0.5, 0.0)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		crate.add_child(shape)
		crate.add_child(_box_mesh(size, Palette.BLOCK_EDGE))
		container.add_child(crate)
		crates.append(crate)


func _add_pits() -> void:
	var holes := Node3D.new()
	holes.name = "Pits"
	add_child(holes)
	for i: int in grid.pits.size():
		var rect := grid.pits[i]
		var size2 := grid.rect_size(rect)
		var pit := Pit.new()
		pit.name = "Pit%d" % i
		pit.position = grid.rect_center(rect)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(size2.x * 0.7, 1.0, size2.y * 0.7)
		shape.shape = box
		shape.position = Vector3(0.0, 0.5, 0.0)
		pit.add_child(shape)
		var hole := _box_mesh(Vector3(size2.x, FLOOR_THICKNESS, size2.y), PIT_COLOR)
		hole.position = Vector3(0.0, -FLOOR_THICKNESS * 0.5 + 0.01, 0.0)
		pit.add_child(hole)
		holes.add_child(pit)
		pits.append(pit)


func _add_junction() -> void:
	var rect := grid.junction
	var size2 := grid.rect_size(rect)
	junction_position = grid.rect_center(rect)
	junction_radius = minf(size2.x, size2.y) * 0.5
	var pad := Node3D.new()
	pad.name = "JunctionPad"
	pad.position = junction_position
	add_child(pad)
	var base := _disc_mesh(junction_radius, JUNCTION_BASE_COLOR)
	base.position = Vector3(0.0, PAD_HEIGHT * 0.5, 0.0)
	pad.add_child(base)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = junction_radius - 0.25
	torus.outer_radius = junction_radius
	ring.mesh = torus
	ring.material_override = _material(Palette.NEON_MAGENTA)
	ring.position = Vector3(0.0, PAD_HEIGHT + 0.02, 0.0)
	pad.add_child(ring)


func _add_jackpots() -> void:
	var zones := Node3D.new()
	zones.name = "JackpotZones"
	add_child(zones)
	for i: int in grid.jackpots.size():
		var rect := grid.jackpots[i]
		var size2 := grid.rect_size(rect)
		var position := grid.rect_center(rect)
		jackpot_positions.append(position)
		var tile := _box_mesh(Vector3(size2.x, PAD_HEIGHT, size2.y), Palette.ASPHALT)
		tile.name = "JackpotZone%d" % i
		tile.position = position + Vector3(0.0, PAD_HEIGHT * 0.5, 0.0)
		zones.add_child(tile)
		var trim := _box_mesh(Vector3(size2.x * 0.8, PAD_HEIGHT, size2.y * 0.8), Palette.CHIP_GOLD)
		trim.position = Vector3(0.0, PAD_HEIGHT * 0.6, 0.0)
		tile.add_child(trim)


func _material(color: Color) -> StandardMaterial3D:
	if not _materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		_materials[color] = material
	return _materials[color]


func _box_mesh(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _material(color)
	return instance


func _disc_mesh(radius: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = PAD_HEIGHT
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _material(color)
	return instance


## A flat arrow pointing along -Z, the forward direction of look_at.
func _arrow_mesh(color: Color) -> MeshInstance3D:
	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.6, 0.6, 0.05)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _material(color)
	# The prism points up along +Y; lay it flat so the tip points along -Z.
	instance.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	var pivot := MeshInstance3D.new()
	pivot.add_child(instance)
	return pivot
