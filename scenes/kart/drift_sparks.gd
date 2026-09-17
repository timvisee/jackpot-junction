class_name DriftSparks
extends Node3D
## What a drift looks like while it is earning its exit boost, GAME.md 4.3. A pair of spark
## fountains off the rear wheels: white and thin while the slide is still paying its dues, gold
## and twice as thick once the boost is charged, and a flash of the same gold thrown off the back
## when it is finally spent. The kart has no HUD for this and should not need one; the boost is a
## driving reward and belongs on the kart.

## The two states the sparks read in, and the colour of the flash when the boost is taken.
const CHARGING := Color(0.85, 0.87, 0.95)
const READY := Palette.CHIP_GOLD
## How long the flash on release lasts, and how bright it starts.
const FLASH_TIME := 0.45
const FLASH_ENERGY := 3.2
## Spark counts, so a charged drift is visibly busier than one still working at it.
const RATE_CHARGING := 0.35
const RATE_READY := 1.0

var _fountains: Array[GPUParticles3D] = []
var _materials: Array[ParticleProcessMaterial] = []
var _glow: OmniLight3D
var _burst: GPUParticles3D
var _flash := 0.0
var _charged := false


func _ready() -> void:
	var half_track := 0.42
	var rear := 0.55
	for side: float in [-1.0, 1.0]:
		var fountain := _build_fountain()
		fountain.position = Vector3(side * half_track, 0.12, rear)
		add_child(fountain)
		_fountains.append(fountain)
		_materials.append(fountain.process_material as ParticleProcessMaterial)
	_burst = _build_fountain()
	_burst.name = "Release"
	_burst.amount = 40
	_burst.lifetime = 0.5
	_burst.one_shot = true
	_burst.emitting = false
	_burst.position = Vector3(0.0, 0.25, rear)
	var burst_material := _burst.process_material as ParticleProcessMaterial
	burst_material.initial_velocity_min = 4.0
	burst_material.initial_velocity_max = 9.0
	burst_material.spread = 40.0
	burst_material.color = READY
	add_child(_burst)
	_glow = OmniLight3D.new()
	_glow.name = "Glow"
	_glow.light_color = READY
	_glow.light_energy = 0.0
	_glow.omni_range = 3.0
	_glow.shadow_enabled = false
	_glow.position = Vector3(0.0, 0.3, rear)
	add_child(_glow)
	set_state(false, false)


## Whether the rear is sliding, and whether the slide has run long enough to have earned the
## boost. The colour is the whole message: white means keep going, gold means let it go.
func set_state(sliding: bool, charged: bool) -> void:
	_charged = charged
	for i: int in _fountains.size():
		var fountain := _fountains[i]
		fountain.emitting = sliding
		fountain.amount_ratio = RATE_READY if charged else RATE_CHARGING
		_materials[i].color = READY if charged else CHARGING


## The boost has been taken: a flash and a shower off the back, in the same gold that promised it.
func pop() -> void:
	_flash = 1.0
	_burst.restart()
	_burst.emitting = true


func _process(delta: float) -> void:
	if _flash <= 0.0:
		# A charged drift keeps a low glow of its own, so the promise is visible from outside too.
		_glow.light_energy = 0.6 if _charged and _fountains[0].emitting else 0.0
		return
	_flash = maxf(_flash - delta / FLASH_TIME, 0.0)
	_glow.light_energy = FLASH_ENERGY * _flash * _flash


## One fountain of sparks: small, bright, unshaded, thrown backward and outward off a tire.
func _build_fountain() -> GPUParticles3D:
	var sparks := GPUParticles3D.new()
	sparks.name = "Sparks"
	sparks.amount = 24
	sparks.lifetime = 0.35
	sparks.local_coords = false
	sparks.emitting = false
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 0.35, 1.0)
	process.spread = 22.0
	process.initial_velocity_min = 2.0
	process.initial_velocity_max = 4.5
	process.gravity = Vector3(0.0, -7.0, 0.0)
	process.scale_min = 0.5
	process.scale_max = 1.0
	process.color = CHARGING
	sparks.process_material = process
	var mesh := SphereMesh.new()
	mesh.radius = 0.045
	mesh.height = 0.09
	mesh.radial_segments = 6
	mesh.rings = 3
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = material
	sparks.draw_pass_1 = mesh
	return sparks
