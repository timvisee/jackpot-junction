class_name TireMarks
extends Node3D
## Faint fading ribbons drawn under the rear wheels, GAME.md 4.3: a subtle detail, barely there
## while driving straight and a little darker in a drift. Lives in world space, so it is a
## top-level node. Feed it wheel positions every physics tick with [method add_sample].
##
## A kart one cash-out from winning the match, GAME.md 3.4, lays them in gold instead, see
## [member gold]: faint and gone again a second and a half later, a short trail behind it every
## player can see rather than the table painted gold, leaving the ordinary marks under it. Laid
## whatever the tire marks setting says, since they say who is about to win rather than dressing
## the floor.

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
## The color of a mark: all but black.
const INK := Color(0.01, 0.0081, 0.0081)
## A gold mark: its color, how solid it is, how wide at the least, as an intensity, and how many
## seconds it takes to fade.
const GOLD := Color("#FFC21F")
const GOLD_ALPHA := 0.55
const GOLD_INTENSITY := 0.25
const GOLD_FADE := 1.5
## Unshaded, both faces. Every vertex carries the time it was laid in its first texture
## coordinate, and in its second the alpha of the ordinary mark there, which fades over
## [constant FADE_SECONDS] from the moment it is laid. A gold one carries its gold in its color on
## top of that, and a nonzero second coordinate for how long the gold lasts: it holds solid for
## the first part of that and then goes, so the trail behind the kart reads as gold rather than as
## a gold already going, and leaves the ordinary mark under it once it has.
const LOOK := """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_opaque;

uniform float now = 0.0;
uniform vec3 ink = vec3(0.01, 0.0081, 0.0081);
uniform float fade_seconds = 20.0;

void fragment() {
	float age = now - UV.x;
	float mark = UV2.x * clamp(1.0 - age / fade_seconds, 0.0, 1.0);
	float gold = UV.y > 0.0 ? 1.0 - smoothstep(0.45, 1.0, age / UV.y) : 0.0;
	ALBEDO = mix(ink, COLOR.rgb, gold);
	ALPHA = mix(mark, COLOR.a, gold);
}
"""

## One look for every kart's marks, told the time once a frame.
static var _look: ShaderMaterial

## Whether the marks being laid are gold, for a kart whose pot would win the match.
var gold := false

## The stretch still being laid: each wheel's samples in it, oldest first, each
## {"left": Vector3, "right": Vector3, "time": float, "alpha": float, "start": bool}, and the mesh
## drawing them, both wheels in the one.
var _open: Array[Array] = [[], []]
var _open_drawn: MeshInstance3D
var _dirty := false
## The closed stretches, oldest first, each [MeshInstance3D, the time its newest sample was laid].
var _closed: Array[Array] = []
## Whether the tire marks setting was on last frame, to clear the floor the moment it goes off.
var _shown := true


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	_open_drawn = _stretch()
	_shown = Game.settings.tire_marks


## The look every stretch is drawn with.
static func look() -> ShaderMaterial:
	if _look == null:
		var shader := Shader.new()
		shader.code = LOOK
		_look = ShaderMaterial.new()
		_look.shader = shader
		_look.set_shader_parameter(&"ink", Color(INK.r, INK.g, INK.b))
		_look.set_shader_parameter(&"fade_seconds", FADE_SECONDS)
	return _look


## Gilds the marks of the karts of [param match_node] whose pots would win it, GAME.md 3.4, and
## no others'. On every machine alike, from the banked scores and pots each already has.
static func gild(match_node: Match) -> void:
	var running := match_node.is_running()
	for slot: PlayerSlot in match_node.slots:
		if slot.kart != null and slot.kart.tire_marks != null:
			slot.kart.tire_marks.gold = (running and slot.would_win(match_node.rules.target_score))


## How many stretches are on the floor, closed or still being laid, for the tests.
func stretch_count() -> int:
	return _closed.size() + 1


## Records the contact point of one rear wheel. [param side] is the wheel's lateral axis in world
## space, [param intensity] 0 to 1 darkens and widens the mark.
func add_sample(wheel: int, contact: Vector3, side: Vector3, intensity: float, now: float) -> void:
	if not Game.settings.tire_marks and not gold:
		return
	var samples: Array = _open[wheel]
	var start := true
	if not samples.is_empty():
		var last: Dictionary = samples[samples.size() - 1]
		var last_mid: Vector3 = (last["left"] + last["right"]) * 0.5
		var gap := last_mid.distance_to(contact)
		if gap < MIN_SAMPLE_DISTANCE:
			return
		start = gap > BREAK_DISTANCE
	# The ordinary mark, left once the gold over it has gone: none with the marks turned off.
	var mark := lerpf(MIN_ALPHA, MAX_ALPHA, intensity) if Game.settings.tire_marks else 0.0
	var half := (
		side.normalized()
		* TRACK_WIDTH
		* 0.5
		* (1.0 + maxf(intensity, GOLD_INTENSITY if gold else 0.0))
	)
	var flat := Vector3(contact.x, HEIGHT, contact.z)
	samples.append(
		{
			"left": flat - half,
			"right": flat + half,
			"time": now,
			"alpha": mark,
			"gold": gold,
			"start": start
		}
	)
	_dirty = true
	if samples.size() >= STRETCH:
		_close()


func _process(_delta: float) -> void:
	# Turned off in the settings, GAME.md 8.5, what is down goes at once rather than fading out.
	# Gold marks are laid all the same, see [member gold].
	if _shown and not Game.settings.tire_marks:
		_clear()
	_shown = Game.settings.tire_marks
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


## Takes every mark off the floor.
func _clear() -> void:
	for stretch: Array in _closed:
		(stretch[0] as Node).queue_free()
	_closed.clear()
	_open = [[], []]
	(_open_drawn.mesh as ImmediateMesh).clear_surfaces()
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
	var gilded: bool = sample.get("gold", false)
	mesh.surface_set_color(Color(GOLD, GOLD_ALPHA) if gilded else Color(INK, 0.0))
	mesh.surface_set_uv(Vector2(float(sample["time"]), GOLD_FADE if gilded else 0.0))
	mesh.surface_set_uv2(Vector2(float(sample["alpha"]), 0.0))
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
