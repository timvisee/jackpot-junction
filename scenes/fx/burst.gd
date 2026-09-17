class_name Burst
extends Node3D
## The scatter left behind when something is destroyed, GAME.md 8.3: a brief flash and a handful
## of tumbling chunks in the thing's own colour. Deliberately small — a kart popping is a puff of
## debris, not a bomb blast, which stays reserved for the Bomb item's [Explosion].

const FLASH_TIME := 0.16
const LIFETIME := 1.4

## Scales the flash, the chunk size and how far they fly.
var size := 1.0

var _age := 0.0
var _flash: MeshInstance3D
var _flash_material: StandardMaterial3D


## Scatters [param count] chunks tinted [param color] at [param at]. Returns the effect so a
## caller can tune it further; it frees itself once the last chunk has faded.
static func spawn(
	parent: Node, at: Vector3, color: Color, scale_factor: float = 1.0, count: int = 16
) -> Burst:
	var burst := Burst.new()
	burst.name = "Burst"
	burst.size = scale_factor
	parent.add_child(burst)
	burst.global_position = Vector3(at.x, 0.0, at.z)
	burst._build(color, count)
	return burst


func _ready() -> void:
	add_to_group(&"bursts")


func _process(delta: float) -> void:
	_age += delta
	var flash := clampf(_age / FLASH_TIME, 0.0, 1.0)
	_flash.visible = flash < 1.0
	_flash.scale = Vector3.ONE * size * (0.35 + 0.65 * flash)
	_flash_material.albedo_color.a = 0.9 * (1.0 - flash)
	if _age >= LIFETIME:
		queue_free()


func _build(color: Color, count: int) -> void:
	_flash = MeshInstance3D.new()
	_flash.name = "Flash"
	var sphere := SphereMesh.new()
	sphere.radius = 0.55
	sphere.height = 1.1
	_flash.mesh = sphere
	_flash_material = StandardMaterial3D.new()
	_flash_material.albedo_color = Color(color.lightened(0.6), 0.9)
	_flash_material.emission_enabled = true
	_flash_material.emission = color.lightened(0.4)
	_flash_material.emission_energy_multiplier = 3.0
	_flash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash.material_override = _flash_material
	_flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flash.position = Vector3(0.0, 0.5, 0.0)
	add_child(_flash)
	add_child(_chunks(color, count))


## Tumbling shards that fly out, fall and fade. One shot, so the node is done after its lifetime.
func _chunks(color: Color, count: int) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = "Chunks"
	particles.amount = maxi(count, 1)
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.local_coords = false
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 1.0, 0.0)
	process.spread = 75.0
	process.initial_velocity_min = 2.5 * size
	process.initial_velocity_max = 6.0 * size
	process.gravity = Vector3(0.0, -13.0, 0.0)
	process.damping_min = 0.5
	process.damping_max = 1.5
	process.angle_min = -180.0
	process.angle_max = 180.0
	process.angular_velocity_min = -540.0
	process.angular_velocity_max = 540.0
	process.scale_min = 0.6 * size
	process.scale_max = 1.3 * size
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.3 * size
	process.color_ramp = ParticleLook.fade_out(color, color.darkened(0.4))
	particles.process_material = process
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * 0.16
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = material
	particles.draw_pass_1 = mesh
	particles.position = Vector3(0.0, 0.45, 0.0)
	particles.emitting = true
	return particles
