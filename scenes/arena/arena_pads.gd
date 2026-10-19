class_name ArenaPads
extends RefCounted
## The House's pieces on an arena's floor, GAME.md 8.1c: the coin pads, the item pads, the turbo
## plates and the Jackpots' tiles, put down where the map's grid says and the same in every room,
## each with whatever the room's kit adds over it. Built for [Arena] as the room goes up, one kind
## at a time, and baked into as few meshes as they will go, GAME.md 10.7.


## The coin pads of 3.2, onto [param arena]'s floor and into its [member Arena.coin_pads].
static func coin_pads(arena: Arena) -> void:
	var pads := Node3D.new()
	pads.name = "CoinPads"
	arena.add_child(pads)
	for i: int in arena.grid.coin_pads.size():
		var pad := CoinPad.new()
		pad.name = "CoinPad%d" % i
		pad.position = arena.grid.cell_center(arena.grid.coin_pads[i])
		var face := disc(arena, 0.45, arena.room.trim)
		face.position = Vector3(0.0, Arena.PAD_HEIGHT * 0.5, 0.0)
		pad.add_child(face)
		pad.add_child(_rim(arena, 0.5))
		pads.add_child(pad)
		arena.coin_pads.append(pad)
	if arena.bake_scenery:
		Bake.merge(pads)


## The item pads of 7.1, onto [param arena]'s floor and into its [member Arena.power_pads].
static func power_pads(arena: Arena) -> void:
	var pads := Node3D.new()
	pads.name = "PowerPads"
	arena.add_child(pads)
	for i: int in arena.grid.power_pads.size():
		var pad := PowerUpPad.new()
		pad.name = "PowerUpPad%d" % i
		pad.position = arena.grid.cell_center(arena.grid.power_pads[i])
		var face := disc(arena, 0.6, Palette.NEON_MAGENTA)
		face.position = Vector3(0.0, Arena.PAD_HEIGHT * 0.5, 0.0)
		face.material_override = arena.surfaces.neon(Palette.NEON_MAGENTA, 0.35)
		pad.add_child(face)
		pad.add_child(_rim(arena, 0.66, 0.07))
		pads.add_child(pad)
		arena.power_pads.append(pad)
	if arena.bake_scenery:
		Bake.merge(pads)


## The turbo pads, onto [param arena]'s floor and into its [member Arena.turbo_pads]. A section
## of pads side by side is one pad, so the line between two of them launches as surely as the
## middle of either, see [TurboPad]; each cell of it still wears a plate.
static func turbo_pads(arena: Arena) -> void:
	var grid := arena.grid
	var pads := Node3D.new()
	pads.name = "TurboPads"
	arena.add_child(pads)
	var sections := grid.turbo_sections()
	for i: int in sections.size():
		var section := sections[i]
		var pad := TurboPad.new()
		pad.name = "TurboPad%d" % i
		pad.direction = grid.turbo_direction(section.position)
		pad.half_extents = grid.rect_size(section) * 0.5
		pad.position = grid.rect_center(section)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		var extent := grid.rect_size(section)
		box.size = Vector3(extent.x, 1.0, extent.y)
		shape.shape = box
		shape.position = Vector3(0.0, 0.5, 0.0)
		pad.add_child(shape)
		for y: int in range(section.position.y, section.end.y):
			for x: int in range(section.position.x, section.end.x):
				_turbo_plate(arena, pad, grid.cell_center(Vector2i(x, y)) - pad.position)
		pads.add_child(pad)
		arena.turbo_pads.append(pad)
	if arena.bake_scenery:
		Bake.merge(pads)


## One cell of a turbo pad at [param at] on [param pad]: a dark plate set into the felt with a lit
## face on it, rather than a flat cyan square, since the frame is what makes it read as a fitting,
## GAME.md 8.1, and the arrow it launches along.
static func _turbo_plate(arena: Arena, pad: TurboPad, at: Vector3) -> void:
	var cell := arena.grid.cell_size
	var frame := box(arena, Vector3(cell, Arena.PAD_HEIGHT, cell), arena.room.lane)
	frame.position = at + Vector3(0.0, Arena.PAD_HEIGHT * 0.5, 0.0)
	pad.add_child(frame)
	var plate := box(arena, Vector3(cell * 0.82, Arena.PAD_HEIGHT, cell * 0.82), Palette.NEON_CYAN)
	plate.material_override = arena.surfaces.neon(Palette.NEON_CYAN, 0.4)
	plate.position = at + Vector3(0.0, Arena.PAD_HEIGHT * 0.9, 0.0)
	pad.add_child(plate)
	var arrow := _arrow(arena, Palette.CHIP_WHITE)
	arrow.position = at + Vector3(0.0, Arena.PAD_HEIGHT + 0.03, 0.0)
	# Fittings set into the felt throw no shadow anybody sees, GAME.md 10.7.
	frame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arrow.look_at_from_position(arrow.position, arrow.position + pad.direction, Vector3.UP)
	pad.add_child(arrow)
	arena.kit.turbo(pad, at, cell)


## The Jackpots of 3.5, onto [param arena]'s floor and into its [member Arena.jackpot_zones]:
## each a tile with whatever its room builds over it.
static func jackpots(arena: Arena) -> void:
	var grid := arena.grid
	var zones := Node3D.new()
	zones.name = "JackpotZones"
	arena.add_child(zones)
	for i: int in grid.jackpots.size():
		var rect := grid.jackpots[i]
		var size2 := grid.rect_size(rect)
		var position := grid.rect_center(rect)
		arena.jackpot_positions.append(position)
		var zone := JackpotZone.new()
		zone.name = "JackpotZone%d" % i
		zone.index = i
		zone.size = size2
		zone.position = position
		var tile := box(arena, Vector3(size2.x, Arena.PAD_HEIGHT, size2.y), arena.room.lane)
		tile.position = Vector3(0.0, Arena.PAD_HEIGHT * 0.5, 0.0)
		tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		zone.add_child(tile)
		var trim := box(
			arena, Vector3(size2.x * 0.8, Arena.PAD_HEIGHT, size2.y * 0.8), arena.room.trim
		)
		trim.position = Vector3(0.0, Arena.PAD_HEIGHT * 1.1, 0.0)
		trim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		zone.add_child(trim)
		arena.kit.jackpot(zone, size2)
		zones.add_child(zone)
		arena.jackpot_zones.append(zone)
	# The tiles and their trims across every zone; a zone's own pole, bulbs and counter each
	# wear a material of their own and stay where they are.
	if arena.bake_scenery:
		Bake.merge(zones)


## A block of [param color] paint [param size] across, centered on its middle.
static func box(arena: Arena, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = arena.surfaces.painted(color)
	return instance


## A disc of [param color] paint on the floor, [param radius] across and a pad's height thick.
static func disc(arena: Arena, radius: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = Arena.PAD_HEIGHT
	mesh.radial_segments = 32
	mesh.rings = 1
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	# A pad is paint on the floor rather than a thing standing on it, and paint casts nothing.
	instance.material_override = arena.surfaces.marking(color)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


## A thin ring of the room's metal, laid round a pad at [param radius]. A disc of color on the
## felt reads as a sticker; the same disc with a rim round it reads as something set into the
## table, GAME.md 8.1.
static func _rim(arena: Arena, radius: float, thickness := 0.06) -> MeshInstance3D:
	var torus := TorusMesh.new()
	torus.inner_radius = radius - thickness
	torus.outer_radius = radius
	torus.rings = 24
	# A tube a few centimeters thick: eight sides round it are as many as anybody sees, where
	# the thirty-two a torus comes with were a thousand triangles a rim, GAME.md 10.7.
	torus.ring_segments = 8
	var rim := MeshInstance3D.new()
	rim.mesh = torus
	rim.material_override = arena.surfaces.metal(arena.room.trim)
	rim.position = Vector3(0.0, Arena.PAD_HEIGHT * 0.9, 0.0)
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return rim


## A flat arrow pointing along -Z, the forward direction of look_at.
static func _arrow(arena: Arena, color: Color) -> MeshInstance3D:
	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.6, 0.6, 0.05)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = arena.surfaces.marking(color)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The prism points up along +Y; lay it flat so the tip points along -Z.
	instance.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	var pivot := MeshInstance3D.new()
	pivot.add_child(instance)
	return pivot
