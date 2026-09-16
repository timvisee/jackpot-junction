class_name NitroFlame
extends Node3D
## The exhaust flame while nitro burns, GAME.md 4.3: a flickering two-tone cone pointing backward
## along +Z, a warm glow and a trail of tiny glowing sparks left behind in the world.

var active := false

var _outer: Node3D
var _core: Node3D
var _light: OmniLight3D
var _sparks: GPUParticles3D
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
	set_active(false)


## Shows or hides the flame. Sparks already in the air keep drifting until they fade.
func set_active(on: bool) -> void:
	active = on
	_outer.visible = on
	_core.visible = on
	_light.visible = on
	_sparks.emitting = on


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
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.85, 0.95, 1.0, 1.0))
	gradient.set_color(1, Color(0.3, 0.6, 1.0, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	process.color_ramp = ramp
	particles.process_material = process
	var mesh := SphereMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.1
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	mesh.material = material
	particles.draw_pass_1 = mesh
	particles.position = Vector3(0.0, 0.0, 0.2)
	return particles
