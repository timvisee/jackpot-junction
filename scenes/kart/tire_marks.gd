class_name TireMarks
extends Node3D
## Faint fading ribbons drawn under the rear wheels, GAME.md 4.3: a subtle detail, barely there
## while driving straight and a little darker in a drift. Lives in world space, so it is a
## top-level node. Feed it wheel positions every physics tick with [method add_sample].
##
## Laid a stretch at a time. What a wheel puts down goes into the stretch still being laid, the
## only mesh built again as the kart drives on, and once that holds [constant STRETCH] samples it is
## closed and kept as a mesh of its own that nothing touches again. The fading is the shader's:
## every vertex carries the time it was laid, so a closed stretch costs nothing a frame until it has
## faded right out and goes. Built whole again every frame, the marks of four karts were tens of
## thousands of vertices a frame in script, which was most of what a match cost to run.

const TRACK_WIDTH := 0.13
const FADE_SECONDS := 20.0
## How many samples a stretch holds before it is closed: about thirty meters of track. Longer is
## more to build again each time the kart moves; shorter is more meshes on the floor to draw.
const STRETCH := 250
const BREAK_DISTANCE := 1.5
const MIN_SAMPLE_DISTANCE := 0.12
const HEIGHT := 0.015
## Opacity of a fresh mark at zero and full intensity; drifting reaches the top of the range.
const MIN_ALPHA := 0.03
const MAX_ALPHA := 0.45
const INK := Color(0.1, 0.09, 0.09)
## Unshaded, both faces, blended by the alpha each vertex was laid with, less however much of the
## fade it has been through: its time is in the first texture coordinate.
const LOOK := """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_opaque;

uniform vec4 tint : source_color = vec4(0.1, 0.09, 0.09, 1.0);
uniform float now = 0.0;
uniform float fade_seconds = 20.0;

void fragment() {
	ALBEDO = tint.rgb * COLOR.rgb;
	ALPHA = COLOR.a * clamp(1.0 - (now - UV.x) / fade_seconds, 0.0, 1.0);
}
"""

## One look for every kart's marks, told the time once a frame.
static var _look: ShaderMaterial

## The stretch still being laid: each wheel's samples in it, oldest first, each
## {"left": Vector3, "right": Vector3, "time": float, "alpha": float, "start": bool}, and the mesh
## drawing them, both wheels in the one.
var _open: Array[Array] = [[], []]
var _open_drawn: MeshInstance3D
var _dirty := false
## The closed stretches, oldest first, each [MeshInstance3D, the time its newest sample was laid].
var _closed: Array[Array] = []


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	_open_drawn = _stretch()


## The look every stretch is drawn with.
static func look() -> ShaderMaterial:
	if _look == null:
		var shader := Shader.new()
		shader.code = LOOK
		_look = ShaderMaterial.new()
		_look.shader = shader
		_look.set_shader_parameter(&"tint", INK)
		_look.set_shader_parameter(&"fade_seconds", FADE_SECONDS)
	return _look


## How many stretches are on the floor, closed or still being laid, for the tests.
func stretch_count() -> int:
	return _closed.size() + 1


## Records the contact point of one rear wheel. [param side] is the wheel's lateral axis in world
## space, [param intensity] 0 to 1 darkens and widens the mark.
func add_sample(wheel: int, contact: Vector3, side: Vector3, intensity: float, now: float) -> void:
	var samples: Array = _open[wheel]
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
			"alpha": lerpf(MIN_ALPHA, MAX_ALPHA, intensity),
			"start": start
		}
	)
	_dirty = true
	if samples.size() >= STRETCH:
		_close()


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec() * 0.001
	look().set_shader_parameter(&"now", now)
	_expire(now)
	if _dirty:
		_dirty = false
		_build(_open_drawn.mesh as ImmediateMesh, _open)


## A stretch that has faded right out goes, and so does the front of the one still being laid
## once it has, for a kart that has stood still for a while.
func _expire(now: float) -> void:
	while not _closed.is_empty() and now - float(_closed[0][1]) >= FADE_SECONDS:
		(_closed[0][0] as Node).queue_free()
		_closed.pop_front()
	for samples: Array in _open:
		while not samples.is_empty() and now - float(samples[0]["time"]) >= FADE_SECONDS:
			samples.pop_front()
			_dirty = true


## Finishes the stretch being laid and leaves it be, and starts the next from where each wheel's
## mark ended, so it runs on without a gap.
func _close() -> void:
	_build(_open_drawn.mesh as ImmediateMesh, _open)
	var newest := 0.0
	var carried: Array[Array] = [[], []]
	for wheel: int in _open.size():
		var samples: Array = _open[wheel]
		if samples.is_empty():
			continue
		var last: Dictionary = samples[samples.size() - 1].duplicate()
		newest = maxf(newest, float(last["time"]))
		last["start"] = false
		carried[wheel].append(last)
	_closed.append([_open_drawn, newest])
	_open = carried
	_open_drawn = _stretch()
	_dirty = false


## A mesh on the floor for one stretch.
func _stretch() -> MeshInstance3D:
	var drawn := MeshInstance3D.new()
	drawn.mesh = ImmediateMesh.new()
	drawn.material_override = look()
	drawn.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(drawn)
	return drawn


## Draws both wheels' [param wheels] of samples into [param mesh] as one strip, a run of it for
## every unbroken stretch of mark, so a stretch is one thing to draw rather than one a run. The runs
## are joined by triangles with no area: the last corner of one said again, then the first of the
## next, which draws nothing between them.
static func _build(mesh: ImmediateMesh, wheels: Array[Array]) -> void:
	mesh.clear_surfaces()
	var begun := false
	var last: Array = []
	for samples: Array in wheels:
		for run: Array in _runs(samples):
			# A run needs at least two samples to be any length of mark at all.
			if run.size() < 2:
				continue
			var first: Dictionary = run[0]
			if not begun:
				mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
				begun = true
			else:
				_corner(mesh, last[0], last[1])
				_corner(mesh, first, "left")
			for sample: Dictionary in run:
				_corner(mesh, sample, "left")
				_corner(mesh, sample, "right")
			last = [run[run.size() - 1], "right"]
	if begun:
		mesh.surface_end()


static func _corner(mesh: ImmediateMesh, sample: Dictionary, edge: String) -> void:
	mesh.surface_set_color(Color(INK, float(sample["alpha"])))
	mesh.surface_set_uv(Vector2(float(sample["time"]), 0.0))
	mesh.surface_set_normal(Vector3.UP)
	mesh.surface_add_vertex(sample[edge])


## Splits a wheel's samples into continuous runs, breaking where a sample starts a new track.
static func _runs(samples: Array) -> Array[Array]:
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
