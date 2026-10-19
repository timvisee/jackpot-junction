class_name Trench
extends Node3D
## The jokers lesson's trench, GAME.md 9.4a: the map's pit across the lot from wall to wall, under
## a lid of the floor's own look for the rest of the test, so the lot is whole. It opens as the
## lesson wants a death: outlined on the floor a moment, then the lid drops away into it with a
## rumble, and there is no way round. It closes again once the lesson is done, the lid coming back
## up into its place. Shut, it is no pit to anything: not to a kart, which drives over it, nor to
## the bots' map, which finds its way across, see [ArenaNav].

## How long it is outlined before it opens, how long the lid takes to drop or come back, and how
## far down it goes.
const MARK := 0.6
const MOVE := 0.6
const DROP := 3.0
const LINE := 0.1
## How deep the lid is.
const LID_DEEP := 0.1
const INK := Palette.NEON_CYAN

var rect := Rect2i()
var _grid: ArenaGrid
var _nav: ArenaNav
var _pit: Pit
var _lid: MeshInstance3D
var _outline: MeshInstance3D
var _ink: StandardMaterial3D
var _open := false
var _moving: Tween


## The trench of the map's pit [param at], in [param arena], shut to start with.
static func lay(arena: Arena, nav: ArenaNav, at: Rect2i) -> Trench:
	var trench := Trench.new()
	trench.name = "Trench"
	trench.rect = at
	trench._grid = arena.grid
	trench._nav = nav
	# By where it is: a trench already shut is out of the grid's list, and the list's order with it.
	var middle := arena.grid.rect_center(at)
	for pit: Pit in arena.pits:
		if pit.position.distance_to(middle) < 0.01:
			trench._pit = pit
	arena.add_child(trench)
	trench.position = arena.grid.rect_center(at)
	trench._build(arena.surfaces.floor_top() if arena.surfaces != null else null)
	trench._shut()
	return trench


func _build(skin: Material) -> void:
	var size := _grid.rect_size(rect)
	_lid = lid_for(size, skin, position, _grid.world_size())
	add_child(_lid)
	_outline = RisingPiece.outline_for(size, LINE)
	_ink = _outline.material_override as StandardMaterial3D
	_outline.visible = false
	add_child(_outline)


## The lid over [param size] of floor, a slab in [param skin], its top flush with the floor. Its top
## wears the floor's own two UVs for where it lies, [param at] in an arena [param across], the felt
## laid on in meters and the floor's print corner to corner, see [method Arena._quad]: so the print
## runs on over it and, shut, nothing of the trench shows. Its sides, seen only as it drops, carry
## on the felt and the print's edge downward.
static func lid_for(size: Vector2, skin: Material, at: Vector3, across: Vector2) -> MeshInstance3D:
	var lid := MeshInstance3D.new()
	lid.name = "Lid"
	var half := Vector3(size.x * 0.5, LID_DEEP * 0.5, size.y * 0.5)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces: Array[Array] = [
		[Vector3.UP, [Vector3(-1, 1, -1), Vector3(1, 1, -1), Vector3(1, 1, 1), Vector3(-1, 1, 1)]],
		[
			Vector3.BACK,
			[Vector3(-1, 1, 1), Vector3(1, 1, 1), Vector3(1, -1, 1), Vector3(-1, -1, 1)]
		],
		[
			Vector3.FORWARD,
			[Vector3(1, 1, -1), Vector3(-1, 1, -1), Vector3(-1, -1, -1), Vector3(1, -1, -1)]
		],
		[
			Vector3.RIGHT,
			[Vector3(1, 1, 1), Vector3(1, 1, -1), Vector3(1, -1, -1), Vector3(1, -1, 1)]
		],
		[
			Vector3.LEFT,
			[Vector3(-1, 1, -1), Vector3(-1, 1, 1), Vector3(-1, -1, 1), Vector3(-1, -1, -1)]
		],
	]
	for face: Array in faces:
		var normal: Vector3 = face[0]
		var corners: Array = face[1]
		st.set_normal(normal)
		for index: int in [0, 1, 2, 0, 2, 3]:
			var vertex: Vector3 = corners[index] * half
			var world := at + vertex + Vector3(0.0, -LID_DEEP * 0.5, 0.0)
			if normal == Vector3.UP:
				st.set_uv(Vector2(world.x, world.z))
			elif absf(normal.x) > 0.5:
				st.set_uv(Vector2(world.z, world.y))
			else:
				st.set_uv(Vector2(world.x, world.y))
			st.set_uv2(Vector2(world.x / across.x + 0.5, world.z / across.y + 0.5))
			st.add_vertex(vertex)
	st.generate_tangents()
	lid.mesh = st.commit()
	if skin != null:
		lid.material_override = skin
	lid.position.y = -LID_DEEP * 0.5
	return lid


## Opens: outlined a moment, then the lid drops away and it is a pit to everything.
func open() -> void:
	if _open:
		return
	_open = true
	_stop()
	_outline.visible = true
	# The shaft under the lid, to be seen once it drops.
	if _pit != null and is_instance_valid(_pit):
		_pit.visible = true
	_moving = create_tween()
	_moving.tween_property(_ink, "albedo_color:a", 0.9, MARK * 0.3)
	_moving.tween_property(_ink, "albedo_color:a", 0.4, MARK * 0.35)
	_moving.tween_property(_ink, "albedo_color:a", 0.9, MARK * 0.35)
	_moving.tween_callback(_dig)
	_moving.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_moving.tween_property(_lid, "position:y", -DROP, MOVE)
	_moving.parallel().tween_property(_ink, "albedo_color:a", 0.0, MOVE)
	_moving.tween_callback(
		func() -> void:
			_lid.visible = false
			_outline.visible = false
	)


## Closes: the lid comes back up into its place, and it is floor again.
func close() -> void:
	if not _open:
		return
	_open = false
	_stop()
	_lid.visible = true
	_moving = create_tween()
	_moving.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_moving.tween_property(_lid, "position:y", -LID_DEEP * 0.5, MOVE)
	_moving.tween_callback(_shut)
	Audio.play_sfx(RisingPiece.RUMBLE, RisingPiece.RUMBLE_DB, 0.05, RisingPiece.RUMBLE_PITCH)


func is_open() -> bool:
	return _open


## The pit is a pit: to a kart, which falls in, and to the bots' map.
func _dig() -> void:
	Audio.play_sfx(RisingPiece.RUMBLE, RisingPiece.RUMBLE_DB, 0.05, RisingPiece.RUMBLE_PITCH)
	if not _grid.pits.has(rect):
		_grid.pits.append(rect)
	for cell: Vector2i in _cells():
		_nav.set_cell_blocked(cell, true)
	if _pit != null and is_instance_valid(_pit):
		_pit.process_mode = Node.PROCESS_MODE_INHERIT


## Floor again: nothing falls in, and the bots' map goes across it.
func _shut() -> void:
	_grid.pits.erase(rect)
	for cell: Vector2i in _cells():
		_nav.set_cell_blocked(cell, false)
	# Its shaft and the dark rim round it out of sight too: under the lid they drew a seam across
	# the lot.
	if _pit != null and is_instance_valid(_pit):
		_pit.process_mode = Node.PROCESS_MODE_DISABLED
		_pit.visible = false
	_lid.position.y = -LID_DEEP * 0.5
	_lid.visible = true
	_outline.visible = false


func _stop() -> void:
	if _moving != null and _moving.is_valid():
		_moving.kill()
	_moving = null


func _cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			cells.append(Vector2i(x, y))
	return cells
