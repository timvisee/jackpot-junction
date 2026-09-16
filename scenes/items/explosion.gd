class_name Explosion
extends Node3D
## The blast of a bomb, GAME.md 7.1: a flash of light, a fireball that swells and fades, a shock
## ring racing outward along the floor, a burst of glowing sparks, a puff of smoke and a scorch
## mark that lingers for a while. Purely visual; the [Bomb] deals the damage.

const FIREBALL_TIME := 0.45
const RING_TIME := 0.55
const LIGHT_TIME := 0.35
const SCORCH_TIME := 8.0
const SCORCH_FADE_START := 3.0

var radius := 2.6
## Holds the animation at its current moment, for previews and screenshots.
var frozen := false

var _age := 0.0
var _fireball: MeshInstance3D
var _fire_material: StandardMaterial3D
var _ring: MeshInstance3D
var _ring_material: StandardMaterial3D
var _light: OmniLight3D
var _scorch_material: StandardMaterial3D


static func spawn(parent: Node, at: Vector3, blast_radius: float, tint: Color) -> Explosion:
	var explosion := Explosion.new()
	explosion.name = "Explosion"
	explosion.radius = blast_radius
	parent.add_child(explosion)
	explosion.global_position = Vector3(at.x, 0.0, at.z)
	explosion._build(tint)
	return explosion


func _ready() -> void:
	add_to_group(&"explosions")


func _process(delta: float) -> void:
	if not frozen:
		_age += delta
	var fire := clampf(_age / FIREBALL_TIME, 0.0, 1.0)
	var swell := 1.0 - pow(1.0 - fire, 3.0)
	_fireball.visible = fire < 1.0
	_fireball.scale = Vector3.ONE * radius * (0.2 + 0.8 * swell)
	_fire_material.albedo_color = Color(1.0, 0.95 - 0.6 * fire, 0.5 - 0.45 * fire, 1.0 - fire)
	_fire_material.emission = Color(1.0, 0.8 - 0.5 * fire, 0.3 - 0.25 * fire)
	_fire_material.emission_energy_multiplier = 6.0 * (1.0 - fire)
	var ring := clampf(_age / RING_TIME, 0.0, 1.0)
	_ring.visible = ring < 1.0
	var reach := lerpf(0.4, radius * 1.35, 1.0 - pow(1.0 - ring, 2.0))
	_ring.scale = Vector3(reach, 1.0, reach)
	_ring_material.albedo_color = Color(1.0, 0.9, 0.7, 0.75 * (1.0 - ring))
	_light.light_energy = 9.0 * (1.0 - clampf(_age / LIGHT_TIME, 0.0, 1.0))
	_light.visible = _age < LIGHT_TIME
	var scorch := clampf((_age - SCORCH_FADE_START) / (SCORCH_TIME - SCORCH_FADE_START), 0.0, 1.0)
	_scorch_material.albedo_color = Color(0.05, 0.05, 0.06, 0.75 * (1.0 - scorch))
	if _age >= SCORCH_TIME and not frozen:
		queue_free()


func _build(tint: Color) -> void:
	_fireball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	_fireball.mesh = sphere
	_fire_material = StandardMaterial3D.new()
	_fire_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_fire_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fire_material.emission_enabled = true
	_fire_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_fireball.material_override = _fire_material
	_fireball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_fireball.position = Vector3(0.0, 0.5, 0.0)
	add_child(_fireball)
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.82
	torus.outer_radius = 1.0
	_ring.mesh = torus
	_ring_material = StandardMaterial3D.new()
	_ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring.material_override = _ring_material
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.position = Vector3(0.0, 0.08, 0.0)
	add_child(_ring)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.75, 0.4)
	_light.omni_range = radius * 3.0
	_light.shadow_enabled = false
	_light.position = Vector3(0.0, 1.0, 0.0)
	add_child(_light)
	var scorch := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = radius * 0.55
	disc.bottom_radius = radius * 0.55
	disc.height = 0.02
	scorch.mesh = disc
	_scorch_material = StandardMaterial3D.new()
	_scorch_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_scorch_material.albedo_color = Color(0.05, 0.05, 0.06, 0.75)
	scorch.material_override = _scorch_material
	scorch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scorch.position = Vector3(0.0, 0.015, 0.0)
	add_child(scorch)
	add_child(_sparks(tint))
	add_child(_smoke())


func _sparks(tint: Color) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = "Sparks"
	particles.amount = 56
	particles.lifetime = 0.9
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.local_coords = false
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 1.0, 0.0)
	process.spread = 85.0
	process.initial_velocity_min = 4.0
	process.initial_velocity_max = 9.0
	process.gravity = Vector3(0.0, -9.0, 0.0)
	process.scale_min = 0.5
	process.scale_max = 1.2
	process.color = Color(1.0, 0.8, 0.35, 1.0)
	process.color_ramp = _fade_ramp(Color(1.0, 0.95, 0.6), tint.lerp(Color(1.0, 0.4, 0.1), 0.5))
	particles.process_material = process
	var mesh := SphereMesh.new()
	mesh.radius = 0.07
	mesh.height = 0.14
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	mesh.material = material
	particles.draw_pass_1 = mesh
	particles.position = Vector3(0.0, 0.4, 0.0)
	particles.emitting = true
	return particles


func _smoke() -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = "Smoke"
	particles.amount = 22
	particles.lifetime = 1.8
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.local_coords = false
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 1.0, 0.0)
	process.spread = 60.0
	process.initial_velocity_min = 1.0
	process.initial_velocity_max = 2.6
	process.gravity = Vector3(0.0, 0.6, 0.0)
	process.scale_min = 0.8
	process.scale_max = 1.8
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.9
	process.color_ramp = _fade_ramp(Color(0.3, 0.3, 0.32, 0.4), Color(0.5, 0.5, 0.52, 0.0))
	particles.process_material = process
	var mesh := SphereMesh.new()
	mesh.radius = 0.35
	mesh.height = 0.7
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	mesh.material = material
	particles.draw_pass_1 = mesh
	particles.position = Vector3(0.0, 0.6, 0.0)
	particles.emitting = true
	return particles


## A colour ramp from [param from] to a transparent [param to], so particles fade out.
static func _fade_ramp(from: Color, to: Color) -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.set_color(0, from)
	gradient.set_color(1, Color(to.r, to.g, to.b, 0.0))
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture
