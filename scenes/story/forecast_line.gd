class_name ForecastLine
extends Node3D
## The House's forecast of the candidate thrown onto the floor at the Final Hand, STORY.md 8.2, as
## if by a projector out of the dark over the racks: a faint band of gold light running out ahead
## of the kart to where the House expects it to be a second and a half from now, widening as it
## goes, a cone of where the kart may be rather than a line it must keep to; a kart's outline there,
## lit by a faint beam down from the projector; and PREDICTING on the floor beside the outline, so
## nobody takes it for their own. It follows the kart as long as the forecast holds; when the kart
## does something the forecast did not have, it stutters, snaps, says RECALCULATING, and throws
## itself out again from the kart. At convergence a plain faint line runs back from the kart along
## the line it drove, the line the models follow. This screen's own, for its own candidate, see
## [HouseWatch].

const PROJECTION := preload("res://scenes/story/forecast_projection.gdshader")
const OUTLINE := preload("res://scenes/story/forecast_ghost.gdshader")
const BEAM := preload("res://scenes/story/forecast_beam.gdshader")
## How wide the band is at the kart and at its end, how far over the floor, and how faint; and the
## band back along the line driven, how wide and how faint.
const NEAR_WIDE := 0.2
const FAR_WIDE := 1.15
const LIFT := 0.04
const BAND_FAINT := 0.12
const TRAIL_WIDE := 0.16
const TRAIL_FAINT := 0.3
## How fast the line drawn follows the forecast as it changes; how far the forecast's end may be
## from the line's, and for how long, before the line snaps, and how soon after one snap it may
## snap again; how long it takes to draw itself out again, and how long it stutters as it does.
const FOLLOW := 9.0
const SNAP := 2.4
const SNAP_AFTER := 0.12
const SNAP_REST := 0.9
const DRAW := 0.35
const STUTTER := 0.4
## The kart's outline at the end: the floor it is thrown on, across and along, and how faint.
const GHOST := Vector2(1.6, 2.4)
const GHOST_FAINT := 0.14
## The beam: how wide where it starts and where it lands, and how faint.
const BEAM_FROM := 0.06
const BEAM_TO := 1.0
const BEAM_FAINT := 0.02
## Where the projector hangs: how high, and how far out past the far wall.
const PROJECTOR_UP := 14.0
const PROJECTOR_BACK := 2.0
## The words beside the outline: how tall their capitals, how far out from its side, how faint
## they are, and how long RECALCULATING stays after a snap.
const WORDS_TALL := 0.24
const WORDS_SIZE := 48
const WORDS_OUT := 0.2
const WORDS_FAINT := 0.32
const RECALCULATING_FOR := 0.7

## How many times it has snapped, for whoever wants to know.
var snaps := 0
## Where the light comes from, high in the dark over the racks; none, no beam.
var projector := Vector3.INF
## The floor it is thrown on, for the words to lie on open floor rather than under a wall; none,
## anywhere.
var grid: ArenaGrid
## How bright the whole of it is, as a share of how it is made.
var brightness := 1.0:
	set = _set_brightness

var _mesh: ImmediateMesh
var _band: MeshInstance3D
var _band_light: ShaderMaterial
var _trail_mesh: ImmediateMesh
var _trail: MeshInstance3D
var _trail_light: ShaderMaterial
var _ghost: MeshInstance3D
var _ghost_light: ShaderMaterial
var _beam: MeshInstance3D
var _beam_light: ShaderMaterial
var _words: Label3D
## The line drawn, each point from the kart.
var _offsets := PackedVector3Array()
var _drawn := 1.0
var _off_for := 0.0
var _since_snap := 1.0e3
var _clock := 0.0


func _ready() -> void:
	_mesh = ImmediateMesh.new()
	_band_light = _light(PROJECTION)
	_band = _part("Line", _mesh, _band_light)
	_trail_mesh = ImmediateMesh.new()
	# The line back is a plain line, the projector's bars kept for the forecast.
	_trail_light = _light(PROJECTION)
	_trail_light.set_shader_parameter(&"wash_share", 1.0)
	_trail_light.set_shader_parameter(&"bar_share", 0.0)
	_trail = _part("Trail", _trail_mesh, _trail_light)
	var floor_plane := PlaneMesh.new()
	floor_plane.size = GHOST
	_ghost_light = _light(OUTLINE)
	_ghost_light.set_shader_parameter(&"extent", GHOST)
	_ghost = _part("Ghost", floor_plane, _ghost_light)
	var cone := CylinderMesh.new()
	cone.height = 1.0
	cone.top_radius = BEAM_FROM
	cone.bottom_radius = BEAM_TO
	cone.cap_top = false
	cone.cap_bottom = false
	cone.radial_segments = 16
	cone.rings = 1
	_beam_light = _light(BEAM)
	_beam = _part("Beam", cone, _beam_light)
	_words = Label3D.new()
	_words.name = "Predicting"
	_words.font = Type.display_font()
	_words.font_size = WORDS_SIZE
	_words.outline_size = 0
	_words.pixel_size = WORDS_TALL / (WORDS_SIZE * Type.CAP_HEIGHT)
	_words.shaded = false
	_words.double_sided = true
	_words.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_words)
	top_level = true
	_set_brightness(brightness)
	clear()
	clear_trail()


## Where the House's projector hangs over [param arena]: high in the dark over the far racks.
static func projector_over(arena: Arena) -> Vector3:
	return Vector3(0.0, PROJECTOR_UP, -arena.world_size().y * 0.5 - PROJECTOR_BACK)


func _set_brightness(value: float) -> void:
	brightness = value
	if _band_light == null:
		return
	_band_light.set_shader_parameter(&"strength", BAND_FAINT * value)
	_trail_light.set_shader_parameter(&"strength", TRAIL_FAINT * value)
	_ghost_light.set_shader_parameter(&"strength", GHOST_FAINT * value)
	_beam_light.set_shader_parameter(&"strength", BEAM_FAINT * value)


func _light(shader: Shader) -> ShaderMaterial:
	var light := ShaderMaterial.new()
	light.shader = shader
	return light


func _part(called: String, mesh: Mesh, light: ShaderMaterial) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = called
	part.mesh = mesh
	part.material_override = light
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(part)
	return part


## The band back along the line the kart drove, [param line] from the kart back, as the models
## follow it at convergence.
func show_trail(line: PackedVector3Array) -> void:
	if line.size() < 2:
		clear_trail()
		return
	_trail.visible = true
	_band_along(_trail_mesh, _trail_light, line, line.size(), TRAIL_WIDE, TRAIL_WIDE)


## No band back along the line driven.
func clear_trail() -> void:
	_trail_mesh.clear_surfaces()
	_trail.visible = false


## Nothing drawn, till the next forecast.
func clear() -> void:
	_mesh.clear_surfaces()
	_ghost.visible = false
	_beam.visible = false
	_words.visible = false
	_offsets.clear()


## The forecast [param line] drawn, its first point where the kart is, following it as it changes;
## snapped and drawn out again from the kart when its end has gone somewhere the line was not.
func show_forecast(line: PackedVector3Array, delta: float) -> void:
	if line.size() < 2:
		clear()
		return
	_clock += delta
	var start := line[0]
	var count := HouseForecast.STEPS + 1
	var wanted := PackedVector3Array()
	for i: int in count:
		wanted.append(line[mini(i, line.size() - 1)] - start)
	_since_snap += delta
	var off := (
		_offsets.size() == count and wanted[count - 1].distance_to(_offsets[count - 1]) > SNAP
	)
	_off_for = _off_for + delta if off else 0.0
	if _offsets.size() != count:
		_offsets = wanted
		_drawn = 0.0
	elif _off_for > SNAP_AFTER and _since_snap > SNAP_REST:
		_offsets = wanted
		_drawn = 0.0
		_off_for = 0.0
		_since_snap = 0.0
		snaps += 1
	else:
		var blend := 1.0 - exp(-FOLLOW * delta)
		for i: int in count:
			_offsets[i] = _offsets[i].lerp(wanted[i], blend)
	_drawn = minf(_drawn + delta / DRAW, 1.0)
	var shown := PackedVector3Array()
	for offset: Vector3 in _offsets:
		shown.append(start + offset)
	var glitch := clampf(1.0 - _since_snap / STUTTER, 0.0, 1.0)
	for light: ShaderMaterial in [_band_light, _ghost_light, _beam_light]:
		light.set_shader_parameter(&"glitch", glitch)
	var drawn := maxi(roundi(float(shown.size() - 1) * _drawn) + 1, 2)
	_band_along(_mesh, _band_light, shown, drawn, NEAR_WIDE, FAR_WIDE)
	var end := shown[count - 1]
	# Which way it is going at the end, from the last point short of it: one cut off by a wall
	# stops there, its last points all the same.
	var going := Vector3.ZERO
	for i: int in range(count - 2, -1, -1):
		going = end - shown[i]
		if going.length() > 0.05:
			break
	going.y = 0.0
	var landed := _drawn >= 1.0 and not going.is_zero_approx()
	_ghost.visible = landed
	_words.visible = landed
	_beam.visible = landed and projector.is_finite()
	if not landed:
		return
	var heading := going.normalized()
	_ghost.global_position = end + Vector3(0.0, LIFT + 0.01, 0.0)
	_ghost.global_rotation = Vector3(0.0, atan2(heading.x, heading.z), 0.0)
	_lay_words(end, heading)
	if _beam.visible:
		_lay_beam(end + Vector3(0.0, LIFT, 0.0))


## A band of light into [param mesh] down the first [param count] points of [param line], from
## [param near] wide at its start to [param far] at its end, its UV meters along it and 0 to 1
## across, as far as [param light] is told it reaches.
func _band_along(
	mesh: ImmediateMesh,
	light: ShaderMaterial,
	line: PackedVector3Array,
	count: int,
	near: float,
	far: float
) -> void:
	mesh.clear_surfaces()
	var lengths := _lengths_of(line)
	var whole := maxf(lengths[lengths.size() - 1], 0.01)
	light.set_shader_parameter(&"reach", maxf(lengths[count - 1], 0.5))
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i: int in count:
		var at := line[i] + Vector3(0.0, LIFT, 0.0)
		var side := _across(line, i) * lerpf(near, far, lengths[i] / whole) * 0.5
		mesh.surface_set_uv(Vector2(lengths[i], 0.0))
		mesh.surface_add_vertex(at + side)
		mesh.surface_set_uv(Vector2(lengths[i], 1.0))
		mesh.surface_add_vertex(at - side)
	mesh.surface_end()


## How far along [param line] each of its points is.
static func _lengths_of(line: PackedVector3Array) -> PackedFloat32Array:
	var lengths := PackedFloat32Array([0.0])
	for i: int in range(1, line.size()):
		lengths.append(lengths[i - 1] + line[i].distance_to(line[i - 1]))
	return lengths


## Which way is across [param line] at its point [param i], flat on the floor.
static func _across(line: PackedVector3Array, i: int) -> Vector3:
	var along := line[mini(i + 1, line.size() - 1)] - line[maxi(i - 1, 0)]
	along.y = 0.0
	if along.is_zero_approx():
		along = Vector3.FORWARD
	return Vector3(-along.z, 0.0, along.x).normalized()


## PREDICTING flat on the floor beside the outline at [param end], along its side the way it is
## [param heading] and never upside down for the camera, on its near side where that is open floor
## and on its far side where it is not; RECALCULATING for a moment after a snap.
func _lay_words(end: Vector3, heading: Vector3) -> void:
	var recalculating := _since_snap < RECALCULATING_FOR
	_words.text = StoryLines.RECALCULATING if recalculating else StoryLines.PREDICTING
	var wide := _words.font.get_string_size(_words.text, HORIZONTAL_ALIGNMENT_LEFT, -1, WORDS_SIZE)
	var half := wide.x * _words.pixel_size * 0.5
	var reading := heading
	var up_page := Vector3(reading.z, 0.0, -reading.x)
	if up_page.z > 0.0:
		reading = -reading
		up_page = -up_page
	# Off the outline's side, the near one first: up the page is away from the camera.
	var out := GHOST.x * 0.5 + WORDS_OUT + WORDS_TALL * 0.5
	var at := end - up_page * out
	if not _open(at, reading, half):
		var far := end + up_page * out
		if _open(far, reading, half):
			at = far
	_words.global_transform = Transform3D(
		Basis(reading, up_page, Vector3.UP), at + Vector3(0.0, LIFT + 0.012, 0.0)
	)
	var flicker := 0.85 + 0.15 * sin(_clock * 41.0) * sin(_clock * 13.0)
	if recalculating:
		flicker *= 1.0 if fmod(_clock * 9.0, 1.0) < 0.5 else 0.55
	_words.modulate = Color(HouseTheme.FOIL_HIGH, WORDS_FAINT * brightness * flicker)


## Whether words [param half] long either way along [param reading] from [param at] lie on open
## floor, not under a wall nor off the table.
func _open(at: Vector3, reading: Vector3, half: float) -> bool:
	if grid == null:
		return true
	for along: float in [-half, 0.0, half]:
		var cell := grid.cell_of(at + reading * along)
		if cell.x < 0 or cell.y < 0 or cell.x >= grid.width or cell.y >= grid.height:
			return false
		if grid.is_wall(cell):
			return false
	return true


## The beam stretched from the projector down onto [param target].
func _lay_beam(target: Vector3) -> void:
	var up := projector - target
	var axis := up.normalized()
	var across := axis.cross(Vector3.RIGHT)
	if across.length() < 0.1:
		across = axis.cross(Vector3.FORWARD)
	across = across.normalized()
	var other := across.cross(axis).normalized()
	_beam.global_transform = Transform3D(Basis(across, up, other), target + up * 0.5)
