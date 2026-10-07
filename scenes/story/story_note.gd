class_name StoryNote
extends Node3D
## One of Kit's notes lying on the table, STORY.md 7.1: a folded scrap among the room's litter, of
## the room's own paper, graph paper on the Workbench, a cocktail napkin After Hours, a page off a
## clipboard in the Yard, a strip of printout in the Count Room. It has to be told from the litter
## round it: a soft pale halo breathes on the floor under it, one corner lifts now and then as if
## in a draft, and a glint runs across it every three seconds. No beam and no label. It collides
## with nothing, is in no group anything looks for and is sent nowhere: [NoteDealer] lays it down
## and sees who drives over it.

## Each room's paper: its color, its lines' color, how its lines run, and its size folded, in
## meters. Lines run across, down, both, or as the printout's broad bars.
enum Lines { NONE, RULED, GRID, BARS }
const PAPERS := {
	&"workbench": [Color(0.88, 0.91, 0.93), Color(0.5, 0.62, 0.78), Lines.GRID, Vector2(0.5, 0.38)],
	&"after_hours":
	[Color(0.95, 0.94, 0.9), Color(0.7, 0.18, 0.2), Lines.NONE, Vector2(0.42, 0.42)],
	&"the_yard": [Color(0.93, 0.91, 0.83), Color(0.42, 0.5, 0.66), Lines.RULED, Vector2(0.46, 0.4)],
	&"count_room":
	[Color(0.86, 0.95, 0.86), Color(0.5, 0.78, 0.52), Lines.BARS, Vector2(0.7, 0.22)],
}
const PLAIN: Array = [
	Color(0.93, 0.92, 0.88), Color(0.5, 0.5, 0.55), Lines.RULED, Vector2(0.46, 0.4)
]
## How far each half of the fold stands up off the floor, as an angle.
const TENT := 0.2
## The glint: how often it comes round, how long it takes to cross, and how bright it is.
const GLINT_EVERY := 3.0
const GLINT_TAKES := 0.45
const GLINT := 0.38
## The halo on the floor under it: how far it reaches past the paper, how high it lies over the
## floor's litter, how bright at its faintest and its brightest, and how long a breath takes.
const HALO_REACH := 2.8
const HALO_LIFT := 0.035
const HALO_LOW := 0.12
const HALO_HIGH := 0.3
const BREATH := 2.6
const HALO_INK := Color(1.0, 0.96, 0.84)
## The draft: how often a corner lifts, how far, and how long the lift takes up and down.
const DRAFT_EVERY := 5.5
const DRAFT_LIFT := 0.32
const DRAFT_TAKES := 1.1

## Which note it is, STORY.md 7.3.
var number := 0
var _size := Vector2.ONE
var _glint: MeshInstance3D
var _halo: MeshInstance3D
var _halves: Array[Node3D] = []
var _since := 0.0
var _clock := 0.0


## Note [param numbered] in the paper of the room [param room_id], built of [param surfaces].
static func make(numbered: int, room_id: StringName, surfaces: Surfaces) -> StoryNote:
	var note := StoryNote.new()
	note.name = "StoryNote"
	note.number = numbered
	var paper: Array = PAPERS.get(room_id, PLAIN)
	note._build(paper, surfaces)
	return note


func _build(paper: Array, surfaces: Surfaces) -> void:
	_size = paper[3]
	var sheet := surfaces.painted(paper[0])
	var ink := surfaces.painted(paper[1])
	# Folded once across the middle and left lying open a little, the fold up, as a sheet folded and
	# dropped lies.
	for side: float in [-1.0, 1.0]:
		var half := Node3D.new()
		half.position = Vector3(0.0, sin(TENT) * _size.x * 0.5 + 0.003, 0.0)
		half.rotation.z = -side * TENT
		add_child(half)
		_halves.append(half)
		var leaf := _part(half, Vector3(_size.x * 0.5, 0.006, _size.y), sheet)
		leaf.position = Vector3(side * _size.x * 0.25, 0.0, 0.0)
		_lines(half, side, paper[2], ink)
	_glint = MeshInstance3D.new()
	_glint.name = "Glint"
	var strip := QuadMesh.new()
	strip.size = Vector2(_size.x * 0.12, _size.y * 0.96)
	_glint.mesh = strip
	var shine := StandardMaterial3D.new()
	shine.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shine.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shine.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	shine.albedo_color = Color(1.0, 1.0, 1.0, GLINT)
	_glint.material_override = shine
	_glint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_glint.rotation.x = -PI * 0.5
	_glint.visible = false
	add_child(_glint)
	add_child(_halo_under())


## The halo: a pale glow fading out round the paper, lying just over the litter on the floor.
func _halo_under() -> MeshInstance3D:
	_halo = MeshInstance3D.new()
	_halo.name = "Halo"
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * maxf(_size.x, _size.y) * HALO_REACH
	_halo.mesh = plane
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow.albedo_color = Color(HALO_INK, HALO_LOW)
	glow.albedo_texture = halo_texture()
	_halo.material_override = glow
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_halo.position.y = HALO_LIFT
	return _halo


## A round glow, full in the middle and gone at the edge.
static func halo_texture() -> GradientTexture2D:
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	fade.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	fade.add_point(0.35, Color(1.0, 1.0, 1.0, 0.7))
	var round_glow := GradientTexture2D.new()
	round_glow.gradient = fade
	round_glow.fill = GradientTexture2D.FILL_RADIAL
	round_glow.fill_from = Vector2(0.5, 0.5)
	round_glow.fill_to = Vector2(1.0, 0.5)
	round_glow.width = 128
	round_glow.height = 128
	return round_glow


## The lines on one half of the sheet, [param side] of the fold.
func _lines(half: Node3D, side: float, lines: int, ink: Material) -> void:
	var across := _size.x * 0.5
	match lines:
		Lines.RULED, Lines.GRID:
			for i: int in 5:
				var z := -_size.y * 0.4 + float(i) * _size.y * 0.2
				var rule := _part(half, Vector3(across * 0.92, 0.002, 0.008), ink)
				rule.position = Vector3(side * _size.x * 0.25, 0.004, z)
			if lines == Lines.GRID:
				for i: int in 4:
					var x := side * (_size.x * 0.06 + float(i) * across * 0.25)
					var rule := _part(half, Vector3(0.008, 0.002, _size.y * 0.96), ink)
					rule.position = Vector3(x, 0.004, 0.0)
		Lines.BARS:
			for i: int in 2:
				var bar := _part(half, Vector3(across * 0.96, 0.002, _size.y * 0.22), ink)
				bar.position = Vector3(
					side * _size.x * 0.25, 0.004, -_size.y * 0.2 + i * _size.y * 0.4
				)
		_:
			# A napkin's embossed edge.
			var edge := _part(half, Vector3(across * 0.86, 0.002, 0.01), ink)
			edge.position = Vector3(side * _size.x * 0.25, 0.004, _size.y * 0.42)


func _part(parent: Node3D, size: Vector3, skin: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = skin
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(part)
	return part


func _process(delta: float) -> void:
	_clock += delta
	var breath := 0.5 - 0.5 * cos(_clock * TAU / BREATH)
	(_halo.material_override as StandardMaterial3D).albedo_color.a = lerpf(
		HALO_LOW, HALO_HIGH, breath
	)
	# A corner lifting in the draft: up quickly, down slowly.
	var draft := fmod(_clock + float(number) * 1.3, DRAFT_EVERY) / DRAFT_TAKES
	var lift := 0.0
	if draft < 1.0:
		lift = sin(minf(draft / 0.35, 1.0) * PI * 0.5) * (1.0 - smoothstep(0.35, 1.0, draft))
	if _halves.size() == 2:
		_halves[1].rotation.z = -TENT + DRAFT_LIFT * lift
		_halves[1].rotation.x = DRAFT_LIFT * 0.4 * lift
	_since = fmod(_since + delta, GLINT_EVERY)
	_glint.visible = _since < GLINT_TAKES
	if _glint.visible:
		var along := _since / GLINT_TAKES
		_glint.position = Vector3(
			lerpf(-0.45, 0.45, along) * _size.x, sin(TENT) * _size.x * 0.5 + 0.01, 0.0
		)
