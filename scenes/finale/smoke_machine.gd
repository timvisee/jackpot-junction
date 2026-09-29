class_name SmokeMachine
extends Node3D
## A stage smoke machine, GAME.md 9.7: a box on the floor with a nozzle in its front, which spits
## a wide jet of smoke along the floor that slows and spreads into a thick haze and drifts up as
## it thins, slowly enough that there is still some about when the lights come up on the drop.
## It only runs for a moment, so it spits hard while it does.
## The lamp on top is lit while it spits. Built facing -Z, the way everything in Godot faces.

## The box, the nozzle in its front and the lamp on its top.
const BODY := Vector3(0.85, 0.52, 1.05)
const BODY_COLOR := Color(0.1, 0.1, 0.12)
const NOZZLE_RADIUS := 0.09
const NOZZLE_LENGTH := 0.18
const NOZZLE_COLOR := Color(0.55, 0.56, 0.6)
const LAMP_ON := Color(1.0, 0.25, 0.2)
const LAMP_OFF := Color(0.2, 0.06, 0.05)
## The jet: how fast it leaves the nozzle, how quickly it slows and how it drifts up; how wide it
## fans out, [constant SPREAD] degrees either side and most of that sideways along the floor
## rather than up off it; how many puffs are out at once at the most, how big one grows to from a
## fraction of that, and how it looks. A puff is a soft round card turned to the camera rather
## than a ball, which shows its edge wherever two of them overlap.
const SPEED := Vector2(5.5, 8.5)
const DRAG := 3.4
const RISE := 0.2
const SPREAD := 32.0
const FLAT := 0.65
const PUFFS := 840
const PUFF_SIZE := 2.6
const GROWTH := 4.0
const SMOKE := Color(0.84, 0.86, 0.92, 0.45)
## How long a puff keeps most of its thickness, and how much of it, and then how long it takes to
## thin away to nothing: slowly, so the haze goes rather than vanishes.
const THICK_SECONDS := 3.0
const THICK := 0.8
const FADE_SECONDS := 3.0
const LIFETIME := THICK_SECONDS + FADE_SECONDS

var _smoke: GPUParticles3D
var _lamp: StandardMaterial3D


func _ready() -> void:
	_build()


## Starts or stops the jet. Whatever is already out drifts on and fades as it would.
func spit(on: bool) -> void:
	if _smoke == null or _smoke.emitting == on:
		return
	_smoke.emitting = on
	_lamp.emission = LAMP_ON if on else LAMP_OFF
	_lamp.albedo_color = _lamp.emission


func is_spitting() -> bool:
	return _smoke != null and _smoke.emitting


func _build() -> void:
	var body := MeshInstance3D.new()
	body.name = "Body"
	var box := BoxMesh.new()
	box.size = BODY
	body.mesh = box
	var paint := StandardMaterial3D.new()
	paint.albedo_color = BODY_COLOR
	paint.roughness = 0.6
	body.material_override = paint
	body.position = Vector3(0.0, BODY.y * 0.5, 0.0)
	add_child(body)
	var nozzle := MeshInstance3D.new()
	nozzle.name = "Nozzle"
	var pipe := CylinderMesh.new()
	pipe.top_radius = NOZZLE_RADIUS
	pipe.bottom_radius = NOZZLE_RADIUS
	pipe.height = NOZZLE_LENGTH
	pipe.radial_segments = 12
	pipe.rings = 1
	nozzle.mesh = pipe
	var metal := StandardMaterial3D.new()
	metal.albedo_color = NOZZLE_COLOR
	metal.metallic = 0.8
	metal.roughness = 0.35
	nozzle.material_override = metal
	var mouth := Vector3(0.0, BODY.y * 0.5, -BODY.z * 0.5 - NOZZLE_LENGTH * 0.5)
	nozzle.position = mouth
	nozzle.rotation.x = PI * 0.5
	add_child(nozzle)
	var lamp := MeshInstance3D.new()
	lamp.name = "Lamp"
	var bulb := SphereMesh.new()
	bulb.radius = 0.05
	bulb.height = 0.1
	lamp.mesh = bulb
	_lamp = StandardMaterial3D.new()
	_lamp.emission_enabled = true
	_lamp.emission = LAMP_OFF
	_lamp.albedo_color = LAMP_OFF
	_lamp.emission_energy_multiplier = 2.0
	lamp.material_override = _lamp
	lamp.position = Vector3(BODY.x * 0.3, BODY.y + 0.03, -BODY.z * 0.3)
	add_child(lamp)
	_smoke = _jet()
	_smoke.position = mouth + Vector3(0.0, 0.0, -NOZZLE_LENGTH * 0.5)
	add_child(_smoke)


func _jet() -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = "Smoke"
	particles.amount = PUFFS
	particles.lifetime = LIFETIME
	particles.local_coords = false
	particles.emitting = false
	particles.draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	# The cloud reaches well past the machine, so what is on screen is not cut by a box sized to
	# the nozzle.
	particles.visibility_aabb = AABB(Vector3(-9.0, -1.0, -13.0), Vector3(18.0, 7.0, 14.0))
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 0.0, -1.0)
	process.spread = SPREAD
	process.flatness = FLAT
	process.initial_velocity_min = SPEED.x
	process.initial_velocity_max = SPEED.y
	process.damping_min = DRAG
	process.damping_max = DRAG * 1.2
	process.gravity = Vector3(0.0, RISE, 0.0)
	process.scale_min = 0.7
	process.scale_max = 1.1
	var growth := Curve.new()
	growth.add_point(Vector2(0.0, 1.0 / GROWTH))
	growth.add_point(Vector2(1.0, 1.0))
	var growing := CurveTexture.new()
	growing.curve = growth
	process.scale_curve = growing
	var ramp := ParticleLook.fade_out(SMOKE, SMOKE.lightened(0.1))
	var thinning := THICK_SECONDS / LIFETIME
	var ink := SMOKE.lerp(SMOKE.lightened(0.1), thinning)
	ramp.gradient.add_point(thinning, Color(ink, SMOKE.a * THICK))
	process.color_ramp = ramp
	particles.process_material = process
	var puff := QuadMesh.new()
	puff.size = Vector2.ONE * PUFF_SIZE
	var look := ParticleLook.material()
	look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	look.albedo_texture = _soft()
	puff.material = look
	particles.draw_pass_1 = puff
	ParticleLook.no_shadows(particles)
	return particles


## White in the middle and nothing at the edge, for a puff with no edge to it.
func _soft() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var soft := GradientTexture2D.new()
	soft.gradient = gradient
	soft.fill = GradientTexture2D.FILL_RADIAL
	soft.fill_from = Vector2(0.5, 0.5)
	soft.fill_to = Vector2(0.5, 0.0)
	soft.width = 64
	soft.height = 64
	return soft
