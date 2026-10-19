class_name HouseRail
extends RefCounted
## The edge of every table, GAME.md 8.1c: whatever room an arena stands in, its outer wall is the
## House's own rail, the same everywhere, so every table is framed as one of the House's tickets
## is. Dark stock printed with a foil hairline near its top and foot and the House's microprint
## along it, a cap of lit stock with a foil hairline down each edge of it, and the House's seal in
## foil at each end of a run. It stays inside the wall's box, which is what a kart drives into.

const PRINT := preload("res://assets/textures/rail_print.png")
## How far along the rail one run of its print goes.
const RUN := 8.0
## The cap: how much of the height it takes, how far in from each side it stands, and the foil
## hairlines down it, how far in and how thin.
const CAP := 0.12
const CAP_INSET := 0.07
const HAIRLINE_IN := 0.16
const HAIRLINE := 0.035
## The seal at a run's end: its radius as a share of the rail's width.
const SEAL := 0.36

static var _print: StandardMaterial3D
static var _cap: StandardMaterial3D
static var _foil: StandardMaterial3D


## The rail of [param size], the wall's box, under [param holder] with its foot at -size.y / 2.
static func build(holder: Node3D, size: Vector3, _surfaces: Surfaces) -> void:
	_make_materials()
	var cap_height := size.y * CAP
	var body := Vector3(size.x, size.y - cap_height, size.z)
	_box(holder, body, _print, Vector3(0.0, -cap_height * 0.5, 0.0))
	var top := Vector3(size.x - CAP_INSET * 2.0, cap_height + 0.02, size.z - CAP_INSET * 2.0)
	var top_y := size.y * 0.5 - cap_height * 0.5 - 0.01
	_box(holder, top, _cap, Vector3(0.0, top_y, 0.0))
	var along_x := size.x >= size.z
	var length := maxf(size.x, size.z) - CAP_INSET * 2.0
	var across := minf(size.x, size.z)
	var face := size.y * 0.5 + 0.004
	for side: float in [-1.0, 1.0]:
		var offset := side * (across * 0.5 - HAIRLINE_IN)
		var line_size := (
			Vector3(length, 0.01, HAIRLINE) if along_x else Vector3(HAIRLINE, 0.01, length)
		)
		var at := Vector3(0.0, face, offset) if along_x else Vector3(offset, face, 0.0)
		_box(holder, line_size, _foil, at)
	# The seal at each end of a run, where two runs meet at a corner of the table.
	if length > across * 2.0:
		for end: float in [-1.0, 1.0]:
			var reach := end * (length * 0.5 - across * 0.5)
			var at := Vector3(reach, face, 0.0) if along_x else Vector3(0.0, face, reach)
			holder.add_child(_seal(across * SEAL, at))


## The House's chip, the emblem of a room with none of its own, GAME.md 8.1c: a chip of the
## House's stock with cream notches round its rim and a foil ring on its face, a meter across.
static func chip(_surfaces: Surfaces) -> Node3D:
	_make_materials()
	var holder := Node3D.new()
	holder.name = "HouseChip"
	var disc := CylinderMesh.new()
	disc.top_radius = 0.5
	disc.bottom_radius = 0.5
	disc.height = 0.12
	disc.radial_segments = 32
	disc.rings = 1
	var body := MeshInstance3D.new()
	body.mesh = disc
	body.material_override = _cap
	holder.add_child(body)
	var cream := StandardMaterial3D.new()
	cream.albedo_color = Color("#F2EAD6")
	cream.roughness = 0.6
	for k: int in 8:
		var turn := TAU * float(k) / 8.0
		var notch := MeshInstance3D.new()
		var block := BoxMesh.new()
		block.size = Vector3(0.14, 0.125, 0.12)
		notch.mesh = block
		notch.material_override = cream
		notch.position = Vector3(sin(turn), 0.0, cos(turn)) * 0.45
		notch.rotation.y = turn
		holder.add_child(notch)
	holder.add_child(_seal(0.3, Vector3(0.0, 0.065, 0.0)))
	return holder


static func _seal(radius: float, at: Vector3) -> MeshInstance3D:
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.012
	disc.radial_segments = 24
	disc.rings = 1
	var seal := MeshInstance3D.new()
	seal.mesh = disc
	seal.material_override = _foil
	seal.position = at
	seal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return seal


static func _box(into: Node3D, size: Vector3, skin: Material, at: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = skin
	node.position = at
	into.add_child(node)
	return node


static func _make_materials() -> void:
	if _print != null:
		return
	_print = StandardMaterial3D.new()
	_print.albedo_texture = PRINT
	_print.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_print.uv1_triplanar = true
	_print.uv1_world_triplanar = true
	_print.uv1_triplanar_sharpness = 40.0
	_print.uv1_scale = Vector3(1.0 / RUN, 1.0, 1.0 / RUN)
	_print.roughness = 0.62
	_print.metallic_specular = 0.4
	_cap = StandardMaterial3D.new()
	_cap.albedo_color = Color("#27252F")
	_cap.roughness = 0.55
	_cap.metallic_specular = 0.45
	_foil = StandardMaterial3D.new()
	_foil.albedo_color = Color("#F2C14E")
	_foil.metallic = 0.75
	_foil.roughness = 0.38
