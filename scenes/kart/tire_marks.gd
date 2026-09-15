class_name TireMarks
extends MeshInstance3D
## Fading ribbons drawn under the rear wheels. Lives in world space, so it is a top-level node.
## Feed it wheel positions every physics tick with [method add_sample].

const TRACK_WIDTH := 0.16
const FADE_SECONDS := 20.0
const MAX_SAMPLES_PER_WHEEL := 1500
const BREAK_DISTANCE := 1.5
const MIN_SAMPLE_DISTANCE := 0.12
const HEIGHT := 0.015

## Each entry: {"left": Vector3, "right": Vector3, "time": float, "intensity": float, "start": bool}
var _wheels: Array[Array] = [[], []]
var _mesh := ImmediateMesh.new()
var _dirty := false


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	mesh = _mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(0.08, 0.07, 0.07, 1.0)
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Records the contact point of one rear wheel. [param side] is the wheel's lateral axis in world
## space, [param intensity] 0 to 1 darkens and widens the mark.
func add_sample(wheel: int, contact: Vector3, side: Vector3, intensity: float, now: float) -> void:
	var samples: Array = _wheels[wheel]
	var start := true
	if not samples.is_empty():
		var last: Dictionary = samples[samples.size() - 1]
		var last_mid: Vector3 = (last["left"] + last["right"]) * 0.5
		var gap := last_mid.distance_to(contact)
		if gap < MIN_SAMPLE_DISTANCE:
			return
		start = gap > BREAK_DISTANCE
	var half := side.normalized() * TRACK_WIDTH * 0.5 * (1.0 + intensity)
	var flat := Vector3(contact.x, HEIGHT, contact.z)
	samples.append(
		{
			"left": flat - half,
			"right": flat + half,
			"time": now,
			"intensity": intensity,
			"start": start
		}
	)
	if samples.size() > MAX_SAMPLES_PER_WHEEL:
		samples.pop_front()
	_dirty = true


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec() * 0.001
	_expire(now)
	if _dirty or not _wheels[0].is_empty() or not _wheels[1].is_empty():
		_rebuild(now)
		_dirty = false


func _expire(now: float) -> void:
	for samples: Array in _wheels:
		while not samples.is_empty():
			var first: Dictionary = samples[0]
			if now - float(first["time"]) < FADE_SECONDS:
				break
			samples.pop_front()


func _rebuild(now: float) -> void:
	_mesh.clear_surfaces()
	for samples: Array in _wheels:
		for run: Array in _runs(samples):
			# A strip needs at least two samples, or the renderer rejects the surface.
			if run.size() < 2:
				continue
			_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
			for sample: Dictionary in run:
				var age: float = now - float(sample["time"])
				var alpha := (
					(1.0 - age / FADE_SECONDS) * lerpf(0.25, 0.9, float(sample["intensity"]))
				)
				var color := Color(0.08, 0.07, 0.07, clampf(alpha, 0.0, 1.0))
				_mesh.surface_set_color(color)
				_mesh.surface_set_normal(Vector3.UP)
				_mesh.surface_add_vertex(sample["left"])
				_mesh.surface_set_color(color)
				_mesh.surface_set_normal(Vector3.UP)
				_mesh.surface_add_vertex(sample["right"])
			_mesh.surface_end()


## Splits a wheel's samples into continuous runs, breaking where a sample starts a new track.
func _runs(samples: Array) -> Array[Array]:
	var runs: Array[Array] = []
	var current: Array = []
	for sample: Dictionary in samples:
		if sample["start"] and not current.is_empty():
			runs.append(current)
			current = []
		current.append(sample)
	if not current.is_empty():
		runs.append(current)
	return runs
