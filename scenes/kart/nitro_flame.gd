class_name NitroFlame
extends Node3D
## The exhaust flame while nitro burns, GAME.md 4.3: a flickering two-tone cone pointing backward
## along +Z, a warm glow, a trail of tiny glowing sparks, and a thick plume of smoke that
## swells as it drifts, well beyond the faint trail the exhaust leaves the rest of the time.

var active := false

var _outer: Node3D
var _core: Node3D
var _light: OmniLight3D
var _sparks: GPUParticles3D
var _smoke: GPUParticles3D
var _time := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_outer = _cone(0.22, 1.25, Color(0.35, 0.65, 1.0, 0.7), 2.5)
	_core = _cone(0.1, 0.85, Color(0.92, 0.97, 1.0, 0.95), 4.0)
	_light = OmniLight3D.new()
	_light.name = "Glow"
	_light.light_color = Color(0.55, 0.75, 1.0)
	_light.light_energy = 2.0
	_light.omni_range = 3.5
	_light.shadow_enabled = false
	_light.position = Vector3(0.0, 0.2, 0.4)
	add_child(_light)
	_sparks = _build_sparks()
	add_child(_sparks)
	_smoke = _build_smoke()
	add_child(_smoke)
	set_active(false)


## Shows or hides the flame. Sparks and smoke already in the air keep drifting until they fade.
func set_active(on: bool) -> void:
	active = on
	_outer.visible = on
	_core.visible = on
	_light.visible = on
	_sparks.emitting = on
	_smoke.emitting = on


func _process(delta: float) -> void:
	if not active:
		return
	_time += delta
	var width := 0.85 + 0.15 * sin(_time * 41.0) + _rng.randf_range(-0.08, 0.08)
	var stretch := 0.9 + 0.2 * sin(_time * 23.0 + 1.3) + _rng.randf_range(-0.06, 0.06)
	_outer.scale = Vector3(width, stretch, width)
	_core.scale = Vector3(width * 0.95, stretch * 1.05, width * 0.95)
	_light.light_energy = 1.6 + 0.8 * width


## A cone with its base at this node, its tip [param length] behind it. Scaling the returned pivot
## stretches the flame away from the exhaust rather than about its middle.
func _cone(base_radius: float, length: float, color: Color, glow: float) -> Node3D:
	var pivot := Node3D.new()
	# The pivot's +Y is the cylinder's axis; tip it so +Y points backward along +Z.
	pivot.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	var cone := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.01
	mesh.bottom_radius = base_radius
	mesh.height = length
	cone.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b)
	material.emission_energy_multiplier = glow
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cone.material_override = material
	cone.position = Vector3(0.0, length * 0.5, 0.0)
	cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pivot.add_child(cone)
	add_child(pivot)
	return pivot


## The plume behind a burning kart: far heavier than the exhaust's own trail, thrown backward
## and growing as it goes, so a kart on nitro leaves a wake worth looking at.
func _build_smoke() -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = "Smoke"
	particles.amount = 110
	particles.lifetime = 1.3
	particles.local_coords = false
	particles.emitting = false
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 0.2, 1.0)
	process.spread = 22.0
	process.initial_velocity_min = 2.0
	process.initial_velocity_max = 4.5
	process.gravity = Vector3(0.0, 0.5, 0.0)
	process.damping_min = 1.5
	process.damping_max = 3.0
	process.scale_min = 0.7
	process.scale_max = 1.5
	process.scale_curve = _growth_curve()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.18
	process.color_ramp = ParticleLook.fade_out(
		Color(0.72, 0.78, 0.9, 0.55), Color(0.5, 0.55, 0.68, 0.0)
	)
	particles.process_material = process
	particles.draw_pass_1 = ParticleLook.ball(0.22)
	ParticleLook.no_shadows(particles)
	particles.position = Vector3(0.0, 0.05, 0.35)
	return particles


## Puffs start small and swell as they fall behind.
static func _growth_curve() -> CurveTexture:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.3))
	curve.add_point(Vector2(1.0, 1.0))
	var texture := CurveTexture.new()
	texture.curve = curve
	return texture


func _build_sparks() -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = "Sparks"
	particles.amount = 90
	particles.lifetime = 0.9
	particles.local_coords = false
	particles.emitting = false
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 0.25, 1.0)
	process.spread = 18.0
	process.initial_velocity_min = 1.5
	process.initial_velocity_max = 3.5
	process.gravity = Vector3(0.0, -1.2, 0.0)
	process.damping_min = 1.0
	process.damping_max = 2.0
	process.scale_min = 0.4
	process.scale_max = 1.0
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.12
	process.color_ramp = ParticleLook.fade_out(
		Color(0.85, 0.95, 1.0, 1.0), Color(0.3, 0.6, 1.0, 0.0)
	)
	particles.process_material = process
	particles.draw_pass_1 = ParticleLook.ball(0.05, 6)
	ParticleLook.no_shadows(particles)
	particles.position = Vector3(0.0, 0.0, 0.2)
	return particles
