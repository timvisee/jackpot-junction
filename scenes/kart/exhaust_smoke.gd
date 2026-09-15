class_name ExhaustSmoke
extends GPUParticles3D
## A faint smoke trail from the exhaust. Its density follows the throttle and thickens while
## drifting, on drift exit boosts and on turbo pads.

const BASE_RATIO := 0.15


func _ready() -> void:
	amount = 48
	lifetime = 1.4
	local_coords = false
	amount_ratio = BASE_RATIO
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 1.0, 0.0)
	process.spread = 35.0
	process.initial_velocity_min = 0.4
	process.initial_velocity_max = 1.1
	process.gravity = Vector3.ZERO
	process.scale_min = 0.6
	process.scale_max = 1.4
	process.color = Color(0.75, 0.75, 0.78, 0.35)
	process_material = process
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	sphere.material = material
	draw_pass_1 = sphere


## Updates the emission density from the kart state.
func update_state(throttle: float, drifting: bool, boosting: bool) -> void:
	var ratio := BASE_RATIO + throttle * 0.45
	if drifting:
		ratio += 0.4
	if boosting:
		ratio = 1.0
	amount_ratio = clampf(ratio, 0.0, 1.0)
