class_name ForecastLine
extends Node3D
## The House's forecast of the candidate drawn on the floor at the Final Hand, STORY.md 8.2: a gold
## line running out ahead of the kart to where the House expects it to be a second and a half from
## now, and a faint ghost of the kart there. It follows the kart as long as the forecast holds; when
## the kart does something the forecast did not have, the line snaps, and draws itself out again
## from the kart. This screen's own, for its own candidate, see [HouseWatch].

## How wide the line is and the glow round it, how far over the floor, and how faint each is at the
## kart and at its end.
const WIDTH := 0.12
const GLOW := 0.42
const LIFT := 0.04
const NEAR := 0.35
const FAR := 1.0
const GLOW_FAINT := 0.16
## How fast the line drawn follows the forecast as it changes; how far the forecast's end may be
## from the line's, and for how long, before the line snaps, and how soon after one snap it may
## snap again; and how long it takes to draw itself out again.
const FOLLOW := 9.0
const SNAP := 2.4
const SNAP_AFTER := 0.12
const SNAP_REST := 0.9
const DRAW := 0.35
## The ghost: a kart's size, how faint, and the frame round where it stands.
const GHOST := Vector3(1.0, 0.45, 1.6)
const GHOST_FAINT := 0.3
const GHOST_FRAME := Vector2(1.3, 1.9)

## How many times it has snapped, for whoever wants to know.
var snaps := 0

var _mesh: ImmediateMesh
var _ribbon: MeshInstance3D
var _ghost: MeshInstance3D
var _ghost_skin: StandardMaterial3D
var _frame: MeshInstance3D
## The line drawn, each point from the kart.
var _offsets := PackedVector3Array()
var _drawn := 1.0
var _off_for := 0.0
var _since_snap := 0.0


func _ready() -> void:
	_mesh = ImmediateMesh.new()
	_ribbon = MeshInstance3D.new()
	_ribbon.name = "Line"
	_ribbon.mesh = _mesh
	_ribbon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var gold := StandardMaterial3D.new()
	gold.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gold.vertex_color_use_as_albedo = true
	gold.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gold.cull_mode = BaseMaterial3D.CULL_DISABLED
	_ribbon.material_override = gold
	add_child(_ribbon)
	_ghost = MeshInstance3D.new()
	_ghost.name = "Ghost"
	var box := BoxMesh.new()
	box.size = GHOST
	_ghost.mesh = box
	_ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ghost_skin = StandardMaterial3D.new()
	_ghost_skin.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost_skin.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_skin.albedo_color = Color(HouseTheme.FOIL_HIGH, GHOST_FAINT)
	_ghost.material_override = _ghost_skin
	add_child(_ghost)
	_frame = MeshInstance3D.new()
	_frame.name = "Frame"
	_frame.mesh = HouseRack.outline_mesh(GHOST_FRAME, 0.07)
	_frame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var framed := StandardMaterial3D.new()
	framed.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	framed.albedo_color = HouseTheme.FOIL
	_frame.material_override = framed
	add_child(_frame)
	top_level = true
	clear()


## Nothing drawn, till the next forecast.
func clear() -> void:
	_mesh.clear_surfaces()
	_ghost.visible = false
	_frame.visible = false
	_offsets.clear()


## The forecast [param line] drawn, its first point where the kart is, following it as it changes;
## snapped and drawn out again from the kart when its end has gone somewhere the line was not.
func show_forecast(line: PackedVector3Array, delta: float) -> void:
	if line.size() < 2:
		clear()
		return
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
	_draw_line(shown)
	var end := shown[count - 1]
	# Which way it is going at the end, from the last point short of it: one cut off by a wall
	# stops there, its last points all the same.
	var going := Vector3.ZERO
	for i: int in range(count - 2, -1, -1):
		going = end - shown[i]
		if going.length() > 0.05:
			break
	_ghost.visible = _drawn >= 1.0 and not going.is_zero_approx()
	_frame.visible = _ghost.visible
	_ghost.global_position = end + Vector3(0.0, GHOST.y * 0.5 + LIFT, 0.0)
	_frame.global_position = end + Vector3(0.0, LIFT, 0.0)
	if not going.is_zero_approx():
		_ghost.global_rotation = Vector3(0.0, atan2(going.x, going.z), 0.0)
		_frame.global_rotation = _ghost.global_rotation
	_ghost_skin.albedo_color.a = GHOST_FAINT * (0.8 + 0.2 * sin(Time.get_ticks_msec() * 0.008))


## The line along [param line], as far along as it is drawn: its glow, and the line over it.
func _draw_line(line: PackedVector3Array) -> void:
	_mesh.clear_surfaces()
	var count := maxi(roundi(float(line.size() - 1) * _drawn) + 1, 2)
	_ribbon_along(line, count, GLOW, GLOW_FAINT, LIFT)
	_ribbon_along(line, count, WIDTH, 1.0, LIFT + 0.005)


## A ribbon down the first [param count] points of [param line], [param wide] across, [param faint]
## times the line's own fading, [param lift] over the floor.
func _ribbon_along(
	line: PackedVector3Array, count: int, wide: float, faint: float, lift: float
) -> void:
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i: int in count:
		var at := line[i] + Vector3(0.0, lift, 0.0)
		var along := line[mini(i + 1, line.size() - 1)] - line[maxi(i - 1, 0)]
		var side := Vector3(-along.z, 0.0, along.x).normalized() * wide * 0.5
		var share := float(i) / float(maxi(line.size() - 1, 1))
		var ink := Color(HouseTheme.FOIL, lerpf(NEAR, FAR, share) * faint)
		_mesh.surface_set_color(ink)
		_mesh.surface_add_vertex(at + side)
		_mesh.surface_set_color(ink)
		_mesh.surface_add_vertex(at - side)
	_mesh.surface_end()
