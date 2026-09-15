class_name ChipBurst
extends Node3D
## Chips that fly from a kart into the Junction pad when a cash-out completes, GAME.md 8.3.

const DURATION := 0.7
const STAGGER := 0.04
const ARC_HEIGHT := 1.8

var _chips: Array[MeshInstance3D] = []
var _delays: PackedFloat32Array = []
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _age := 0.0
var _rng := RandomNumberGenerator.new()


static func spawn(parent: Node, from: Vector3, to: Vector3, count: int, color: Color) -> ChipBurst:
	var burst := ChipBurst.new()
	burst._from = from + Vector3(0.0, 0.6, 0.0)
	burst._to = to + Vector3(0.0, 0.2, 0.0)
	parent.add_child(burst)
	burst._build(count, color)
	return burst


func _build(count: int, color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.5
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.22
	mesh.bottom_radius = 0.22
	mesh.height = 0.08
	for i: int in count:
		var chip := MeshInstance3D.new()
		chip.mesh = mesh
		chip.material_override = material
		chip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		chip.position = (
			_from
			+ Vector3(
				_rng.randf_range(-0.5, 0.5), _rng.randf_range(0.0, 0.5), _rng.randf_range(-0.5, 0.5)
			)
		)
		add_child(chip)
		_chips.append(chip)
		_delays.append(i * STAGGER)


func _process(delta: float) -> void:
	_age += delta
	var all_done := true
	for i: int in _chips.size():
		var t := clampf((_age - _delays[i]) / DURATION, 0.0, 1.0)
		if t < 1.0:
			all_done = false
		var chip := _chips[i]
		var start := _from + Vector3(float(i % 5) * 0.12 - 0.24, 0.0, float(i / 5) * 0.12 - 0.12)
		chip.position = start.lerp(_to, t) + Vector3(0.0, sin(t * PI) * ARC_HEIGHT, 0.0)
		chip.rotation.x += 6.0 * delta
		chip.visible = t < 1.0
	if all_done:
		queue_free()
