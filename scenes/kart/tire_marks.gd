class_name TireMarks
extends Node3D
## Faint fading ribbons drawn under the rear wheels, GAME.md 4.3: a subtle detail, barely there
## while driving straight and a little darker in a drift. Lives in world space, so it is a
## top-level node. Feed it wheel positions every physics tick with [method add_sample].
##
## A kart one cash-out from winning the match, GAME.md 3.4, lays them in gold instead, see
## [member gold]: a little wider than a plain mark, solid and bright, and gone again two seconds
## later, a short trail behind it every player can see rather than the table painted gold, leaving
## the ordinary marks under it. Faint, they were lost on the felt and all but gone on a pale floor;
## twice as wide, they were too heavy. Laid
## whatever the tire marks setting says, since they say who is about to win rather than dressing
## the floor.
##
## The setting, GAME.md 8.5, says whose marks are laid and how long they last: every kart's for
## [constant FADE_SECONDS], every kart's for [constant SHORT_FADE], only the karts of the players
## at this screen for the short time, or none.

const TRACK_WIDTH := 0.13
const FADE_SECONDS := 20.0
const SHORT_FADE := 4.0
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
const GOLD_ALPHA := 0.92
const GOLD_INTENSITY := 0.25
const GOLD_FADE := 2.0
## The look every stretch is drawn with, see tire_marks.gdshader beside this script.
const LOOK: Shader = preload("res://scenes/kart/tire_marks.gdshader")
## The marks the loyalty program of GAME.md 8.9 pays, by [constant KartStyle.MARKS]: Chalk a paler
## mark, Dashed a mark broken into dashes like a lane line, this long from one dash to the next.
## As faint as the plain ones and fading as fast, never bright and never lit.
const CHALK := Color(0.66, 0.65, 0.6)
const DASH := 0.6
const DASH_ON := 0.55
## Kit's pencil, GAME.md 8.9: dark graphite, under the floor's own gray so the scribble reads as
## drawn on it, the mark drawn by hand rather than laid, see tire_marks.gdshader.
const PENCIL := Color(0.2, 0.21, 0.25)

## One look for every kart's marks of each kind, told the time once a frame.
static var _looks: Dictionary[int, ShaderMaterial] = {}

## Whether the marks being laid are gold, for a kart whose pot would win the match.
var gold := false
## Which of [constant KartStyle.MARKS] this kart lays, from the next stretch it starts, and in
## which finish, GAME.md 8.9.
var marks := 0:
	set(value):
		marks = value
		if _open_drawn != null:
			_open_drawn.material_override = look_for(marks, finish)
var finish := 0:
	set(value):
		finish = value
		if _open_drawn != null:
			_open_drawn.material_override = look_for(marks, finish)

## The stretch still being laid: each wheel's samples in it, oldest first, each
## {"left": Vector3, "right": Vector3, "time": float, "alpha": float, "start": bool}, and the mesh
## drawing them, both wheels in the one.
var _open: Array[Array] = [[], []]
var _open_drawn: MeshInstance3D
var _dirty := false
## The closed stretches, oldest first, each [MeshInstance3D, the time its newest sample was laid].
var _closed: Array[Array] = []
## Whether this kart was laying ordinary marks last frame, to clear the floor the moment the setting
## says it may not.
var _shown := true


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	_open_drawn = _stretch()
	_shown = laying()


## A kart's marks, named for it, laying [param kind] of [constant KartStyle.MARKS] in
## [param finished].
static func laid(kind: int, finished := 0) -> TireMarks:
	var made := TireMarks.new()
	made.name = "TireMarks"
	made.marks = kind
	made.finish = finished
	return made


## How long a mark lasts on the floor, as the setting has it.
static func fade_seconds() -> float:
	return FADE_SECONDS if Game.settings.tire_marks == Settings.MARKS_FULL else SHORT_FADE


## Whether this kart lays its ordinary marks, as the setting has it: a kart of a player at this
## screen, as the aim guide knows one, online too, see [KartAim], for only those players' marks.
## A mark not under any kart, as in a test, is anybody's.
func laying() -> bool:
	match Game.settings.tire_marks:
		Settings.MARKS_OFF:
			return false
		Settings.MARKS_MINE:
			var kart := get_parent() as Kart
			return kart == null or kart.input is PlayerInput
	return true


## The look the plain marks are drawn with.
static func look() -> ShaderMaterial:
	return look_for(0)


## The look the marks of [param kind], one of [constant KartStyle.MARKS], are drawn with in
## [param finished].
static func look_for(kind: int, finished := 0) -> ShaderMaterial:
	var key := kind * 4 + finished
	if _looks.has(key):
		return _looks[key]
	var made := ShaderMaterial.new()
	made.shader = LOOK
	var ink := CHALK if kind == 1 else (PENCIL if kind == 3 else INK)
	made.set_shader_parameter(&"ink", Color(ink.r, ink.g, ink.b))
	made.set_shader_parameter(&"dash", DASH if kind == 2 else 0.0)
	made.set_shader_parameter(&"dash_on", DASH_ON)
	made.set_shader_parameter(&"pencil", kind == 3)
	made.set_shader_parameter(&"gilt", Color(GOLD.r, GOLD.g, GOLD.b))
	made.set_shader_parameter(&"gilt_alpha", GOLD_ALPHA)
	made.set_shader_parameter(&"fade_seconds", fade_seconds())
	made.set_shader_parameter(&"finish", finished)
	_looks[key] = made
	return made


## Gilds the marks of the karts of [param match_node] whose pots would win it, GAME.md 3.4, and
## no others'. On every machine alike, from the banked scores and pots each already has.
static func gild(match_node: Match) -> void:
	var running := match_node.is_running()
	for slot: PlayerSlot in match_node.slots:
		if slot.kart != null and slot.kart.tire_marks != null:
			slot.kart.tire_marks.gold = (running and match_node.would_win(slot))


## How many stretches are on the floor, closed or still being laid, for the tests.
func stretch_count() -> int:
	return _closed.size() + 1


## Records the contact point of one rear wheel. [param side] is the wheel's lateral axis in world
## space, [param intensity] 0 to 1 darkens and widens the mark; [param fresh] starts a new mark
## rather than running the last on to it, as a wheel set down again does.
func add_sample(
	wheel: int, contact: Vector3, side: Vector3, intensity: float, now: float, fresh := false
) -> void:
	var ordinary := laying()
	if not ordinary and not gold:
		return
	var samples: Array = _open[wheel]
	var start := true
	var along := 0.0
	if not samples.is_empty():
		var last: Dictionary = samples[samples.size() - 1]
		var last_mid: Vector3 = (last["left"] + last["right"]) * 0.5
		var gap := last_mid.distance_to(contact)
		if gap < MIN_SAMPLE_DISTANCE:
			return
		start = fresh or gap > BREAK_DISTANCE
		along = 0.0 if start else float(last.get("along", 0.0)) + gap
	# The ordinary mark, left once the gold over it has gone: none with the marks turned off.
	var mark := lerpf(MIN_ALPHA, MAX_ALPHA, intensity) if ordinary else 0.0
	var half := (
		side.normalized()
		* TRACK_WIDTH
		* 0.5
		* (1.0 + maxf(intensity, GOLD_INTENSITY if gold else 0.0))
	)
	var flat := Vector3(contact.x, HEIGHT, contact.z)
	(
		samples
		. append(
			{
				"left": flat - half,
				"right": flat + half,
				"time": now,
				"alpha": mark,
				"gold": gold,
				"start": start,
				"along": along,
			}
		)
	)
	_dirty = true
	if samples.size() >= STRETCH:
		_close()


func _process(_delta: float) -> void:
	# Turned off in the settings, GAME.md 8.5, or turned to the players here, what is down goes at
	# once rather than fading out. Gold marks are laid all the same, see [member gold].
	var ordinary := laying()
	if _shown and not ordinary:
		_clear()
	_shown = ordinary
	var now := Time.get_ticks_msec() * 0.001
	look()
	for kind: int in _looks:
		_looks[kind].set_shader_parameter(&"now", now)
		_looks[kind].set_shader_parameter(&"fade_seconds", fade_seconds())
	_expire(now)
	if _dirty:
		_dirty = false
		_build(_open_drawn.mesh as ImmediateMesh, _open)


## A stretch that has faded right out goes, and so does the front of the one still being laid
## once it has, for a kart that has stood still for a while.
func _expire(now: float) -> void:
	var lasting := fade_seconds()
	while not _closed.is_empty() and now - float(_closed[0][1]) >= lasting:
		(_closed[0][0] as Node).queue_free()
		_closed.pop_front()
	for samples: Array in _open:
		while not samples.is_empty() and now - float(samples[0]["time"]) >= lasting:
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
	drawn.material_override = look_for(marks, finish)
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


## One corner of the strip: [param edge] of [param sample], its color's red which edge it is and its
## green how wide the mark is, in half meters, for a mark drawn across as well as along, see
## tire_marks.gdshader.
static func _corner(mesh: ImmediateMesh, sample: Dictionary, edge: String) -> void:
	var gilded: bool = sample.get("gold", false)
	var wide := (sample["left"] as Vector3).distance_to(sample["right"]) * 2.0
	mesh.surface_set_color(Color(1.0 if edge == "right" else 0.0, wide, 0.0, 0.0))
	mesh.surface_set_uv(Vector2(float(sample["time"]), GOLD_FADE if gilded else 0.0))
	mesh.surface_set_uv2(Vector2(float(sample["alpha"]), float(sample.get("along", 0.0))))
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
