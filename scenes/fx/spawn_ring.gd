class_name SpawnRing
extends Node3D
## The flare a kart comes back with, GAME.md 3.6: a ring that opens out across the floor in the
## player's color with a column of light standing in the middle of it, both gone inside a
## second. A kart that has just respawned is untouchable for a moment and blinking, which says
## something about that kart to whoever is looking at it; this says, to everybody at once and
## from anywhere on the floor, that somebody is back and where they came back.

const LIFETIME := 0.75
const START_RADIUS := 0.5
const END_RADIUS := 3.6
## How thick the ring is, as a share of its radius, and how tall the column stands.
const THICKNESS := 0.16
const COLUMN_HEIGHT := 3.4
const COLUMN_RADIUS := 0.55
## The column has gone by this share of the flare's life; the ring keeps going to the end.
const COLUMN_LIFE := 0.55

var color := Color.WHITE

var _age := 0.0
var _ring: MeshInstance3D
var _ring_material: StandardMaterial3D
var _column: MeshInstance3D
var _column_material: StandardMaterial3D


static func spawn(parent: Node, at: Vector3, player_color: Color) -> SpawnRing:
	var flare := SpawnRing.new()
	flare.name = "SpawnRing"
	flare.color = player_color
	parent.add_child(flare)
	flare.global_position = Vector3(at.x, 0.0, at.z)
	flare._build()
	return flare


func _process(delta: float) -> void:
	_age += delta
	var life := _age / LIFETIME
	if life >= 1.0:
		queue_free()
		return
	var radius := lerpf(START_RADIUS, END_RADIUS, ease(life, 0.35))
	_ring.scale = Vector3(radius, 1.0, radius)
	_ring_material.albedo_color.a = 0.85 * (1.0 - life)
	var column_life := clampf(life / COLUMN_LIFE, 0.0, 1.0)
	_column.visible = column_life < 1.0
	_column.scale = Vector3(
		1.0 - 0.4 * column_life, 1.0 + 0.5 * column_life, 1.0 - 0.4 * column_life
	)
	_column_material.albedo_color.a = 0.5 * (1.0 - column_life)


func _build() -> void:
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.0 - THICKNESS
	torus.outer_radius = 1.0
	_ring.mesh = torus
	_ring_material = _glow(0.85)
	_ring.material_override = _ring_material
	_ring.position = Vector3(0.0, 0.08, 0.0)
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	_column = MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = COLUMN_RADIUS * 0.6
	cylinder.bottom_radius = COLUMN_RADIUS
	cylinder.height = COLUMN_HEIGHT
	_column.mesh = cylinder
	_column_material = _glow(0.5)
	_column.material_override = _column_material
	_column.position = Vector3(0.0, COLUMN_HEIGHT * 0.5, 0.0)
	_column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_column)


func _glow(alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color, alpha)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.2
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
