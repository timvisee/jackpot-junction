class_name DriftSparks
extends Node3D
## What a drift looks like once it has earned its exit boost, GAME.md 4.3. A pair of spark
## fountains off the rear wheels light up white the moment the boost is in the bank, and stay
## quiet before it: the sparks are the news that the drift is worth something, so they say
## nothing until it is. Spending the boost throws gold off the back with a flash of light.
##
## Two colors, two meanings, and nothing on the HUD: white is ready, gold is gone.

## The sparks a charged drift throws, and the gold of the boost being spent.
const READY := Color(0.85, 0.87, 0.95)
const SPENT := Palette.CHIP_GOLD
## How long the flash on release lasts, and how bright it starts.
const FLASH_TIME := 0.45
const FLASH_ENERGY := 3.2
## How hard a charged drift throws them.
const RATE_READY := 0.8

var _fountains: Array[GPUParticles3D] = []
var _materials: Array[ParticleProcessMaterial] = []
var _glow: OmniLight3D
var _burst: GPUParticles3D
var _flash := 0.0


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
	burst_material.color = SPENT
	add_child(_burst)
	_glow = OmniLight3D.new()
	_glow.name = "Glow"
	_glow.light_color = SPENT
	_glow.light_energy = 0.0
	_glow.omni_range = 3.0
	_glow.shadow_enabled = false
	_glow.position = Vector3(0.0, 0.3, rear)
	add_child(_glow)
	set_state(false, false)


## Whether the rear is sliding, and whether the slide has run long enough to have earned the
## boost. Only the second of those shows: sparks mean the drift is worth ending, so a slide
## that has not got there yet throws none at all.
func set_state(sliding: bool, charged: bool) -> void:
	for i: int in _fountains.size():
		var fountain := _fountains[i]
		fountain.emitting = sliding and charged
		fountain.amount_ratio = RATE_READY
		_materials[i].color = READY


## The boost has been taken: a flash and a shower off the back, and the only gold in the effect.
func pop() -> void:
	_flash = 1.0
	_burst.restart()
	_burst.emitting = true


func _process(delta: float) -> void:
	if _flash <= 0.0:
		# The light belongs to the boost alone, so a charged drift is sparks and nothing else.
		# Hidden rather than left on at nothing, GAME.md 10.7: a light at zero energy is still
		# a light to every mesh in its range on a phone's renderer.
		if _glow.visible:
			_glow.light_energy = 0.0
			_glow.visible = false
		return
	_flash = maxf(_flash - delta / FLASH_TIME, 0.0)
	_glow.visible = true
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
	process.color = READY
	sparks.process_material = process
	sparks.draw_pass_1 = ParticleLook.ball(0.045, 6)
	ParticleLook.no_shadows(sparks)
	return sparks
