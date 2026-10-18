class_name MagnetFlag
extends Node
## The Magnet that flies from a kart's pole, GAME.md 4.4 and 8.9: a red horseshoe magnet, its two
## poles bare steel, hung from the top of the pole by its bend and moved by [DressSway] as a flag
## is. While its kart pulls chips in, by a Chip Magnet, 7.1, or Magnet Hubcaps, 7.3, it grows to
## half as big again, beats and rocks, and the lines of its field arc out between its poles; it
## eases back as the pull ends. Worked out on every screen from what that screen already has of
## the kart, its reach and its hand, both of which the snapshot brings a client, GAME.md 10.3: the
## look alone, which nothing in a match feels.

## The magnet's colors: its red paint, its bare steel poles, and the glow of its field.
const RED := Color(0.8, 0.08, 0.07)
const STEEL := Color(0.78, 0.8, 0.84)
const FIELD := Color(1.0, 0.82, 0.4)
## Its shape, in meters: how far the middle of its bar is from the middle of its bend, how wide and
## how thick the bar is, how far each leg runs on past the bend, how much of that is bare steel, and
## how far out from the middle of the pole its bend hangs.
const BEND := 0.13
const BAR := 0.11
const THICK := 0.08
const LEG := 0.2
const STEEL_TIP := 0.07
const OFF_POLE := 0.035
## How many steps it takes round its bend.
const BEND_STEPS := 12
## How far it is turned on its bar, so that the camera over the table, which sees a flag's top edge
## more than its face, sees its bend as a U rather than as a bar.
const ROLL := -0.9
## How big it grows while it pulls; how quickly it gets there and back, one over the seconds it
## takes to come most of the way; how much it swells and shrinks with each beat and how often it
## beats a second; how far it rocks on its bar either way, in radians, and how often a second.
const GROWN := 1.5
const EASE := 9.0
const BEAT := 0.07
const BEAT_RATE := 2.2
const ROCK := 0.2
const ROCK_RATE := 1.3
## The arcs of its field: how far out past the poles each reaches, how thick they are, how much
## they breathe out and in and how often a second.
const ARCS: Array[float] = [0.07, 0.14, 0.22]
const ARC_THICK := 0.022
const BREATH := 0.25
const BREATH_RATE := 3.0

## The magnet's bar and its two poles, and the arcs of its field, each built once and shared by
## every kart flying one; the field's glow too, the same on all of them.
static var _bar_mesh: ArrayMesh
static var _poles_mesh: ArrayMesh
static var _field_mesh: ArrayMesh
static var _field_skin: StandardMaterial3D

## The magnet it grows and rocks.
var magnet: Node3D
## How far it has grown toward [constant GROWN], 0 at rest to 1 pulling.
var _charge := 0.0
## How long it has been going, for its beat, its rock and its field's breath.
var _time := 0.0
## The kart it flies from, null for a kart only to look at.
var _kart: Kart
## The arcs of its field, made the first time it pulls rather than on every kart flying one.
var _field: MeshInstance3D


## Hangs the magnet off [param cloth], a pivot at the top of the pole, with one of these to move it,
## and hands back the pivot for [DressSway] to swing.
static func fly(cloth: Node3D) -> Node3D:
	var held := Node3D.new()
	held.name = "Magnet"
	held.position = Vector3(OFF_POLE, 0.0, 0.0)
	held.rotation = Vector3(ROLL, 0.0, 0.0)
	cloth.add_child(held)
	var bar := MeshInstance3D.new()
	bar.name = "Bar"
	bar.mesh = _bar()
	bar.material_override = _painted(RED)
	held.add_child(bar)
	var poles := MeshInstance3D.new()
	poles.name = "Poles"
	poles.mesh = _poles()
	poles.material_override = _painted(STEEL)
	(poles.material_override as StandardMaterial3D).metallic = 0.7
	(poles.material_override as StandardMaterial3D).roughness = 0.32
	held.add_child(poles)
	var moves := MagnetFlag.new()
	moves.name = "Pull"
	moves.magnet = held
	cloth.add_child(moves)
	return cloth


## Whether [param kart] is pulling chips in now: a Chip Magnet working on it, which widens its
## reach, GAME.md 7.1, or a hand with Magnet Hubcaps in play, 7.3, or anything else in a hand that
## widens its reach. A decoy pulls as its owner does, since it wears what its owner wears to be
## taken for them, 4.4.
static func pulling(kart: Kart) -> bool:
	var whose := _owner_of(kart)
	if whose == null:
		return false
	if whose.pickup_radius_bonus > 1.0:
		return true
	if whose.jokers == null:
		return false
	for joker: Joker in whose.jokers.in_play:
		if joker.modify_pickup_radius(1.0) > 1.0:
			return true
	return false


## The kart [param kart] is taken for: a decoy's owner, the kart in its seat on a client, which
## knows a decoy only as a decoy, and any other kart itself.
static func _owner_of(kart: Kart) -> Kart:
	if kart == null or not is_instance_valid(kart) or not kart.is_decoy():
		return kart
	var in_match := kart.get_parent() as Match
	if in_match != null and kart.slot >= 0 and kart.slot < in_match.slots.size():
		var seated := in_match.slots[kart.slot].kart
		if seated != null and seated != kart:
			return seated
	return kart.decoy_owner if kart.decoy_owner != kart else null


## The kart it flies from, if it flies from one; a kart only to look at, in the kart dialog, on the
## podium or in a picture, has none, and its magnet stays as it is.
func _ready() -> void:
	var above := get_parent()
	while above != null and not above is Kart:
		above = above.get_parent()
	_kart = above as Kart
	set_process(_kart != null)


## Every drawn frame rather than every step, since it is the look alone and moves smoothly.
func _process(delta: float) -> void:
	step(delta, pulling(_kart))


## One frame of [param delta] seconds, [param pulled] whether its kart pulls chips in: grown toward
## the size it is pulling at or back to its own, and while it is grown at all, beating and rocking
## with its field out between its poles.
func step(delta: float, pulled: bool) -> void:
	_time += delta
	var was := _charge
	_charge = lerpf(_charge, 1.0 if pulled else 0.0, 1.0 - exp(-EASE * delta))
	if not pulled and _charge < 0.002:
		_charge = 0.0
		if was == 0.0:
			return
	var beat := sin(_time * TAU * BEAT_RATE) * BEAT * _charge
	magnet.scale = Vector3.ONE * (lerpf(1.0, GROWN, _charge) + beat)
	magnet.rotation.x = ROLL + sin(_time * TAU * ROCK_RATE) * ROCK * _charge
	_show_field()


## How far it has grown, 0 at rest to 1 pulling.
func charge() -> float:
	return _charge


## The arcs of its field out between its poles while it pulls, breathing out and in, drawn out of
## the poles as it grows and back into them as it settles.
func _show_field() -> void:
	var shown := _charge > 0.02
	if _field == null:
		if not shown:
			return
		_field = MeshInstance3D.new()
		_field.name = "Field"
		_field.mesh = _field_arcs()
		_field.material_override = _glow()
		_field.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_field.position = Vector3(_tip_end(), 0.0, 0.0)
		magnet.add_child(_field)
	_field.visible = shown
	if shown:
		var breath := 1.0 + sin(_time * TAU * BREATH_RATE) * BREATH
		_field.scale = Vector3(maxf(_charge * breath, 0.01), 1.0, 1.0)


## Paint or steel in [param color], lit as the rest of what a kart wears is, see [KartDress].
static func _painted(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.62
	material.rim_enabled = true
	material.rim = 0.3
	return material


## How far out from the pole the ends of its poles are, along it.
static func _tip_end() -> float:
	return BAR * 0.5 + BEND + LEG


## The red of the bar: a U from the end of one leg round the bend to the end of the other, short of
## the bare steel at each end, built once.
static func _bar() -> ArrayMesh:
	if _bar_mesh != null:
		return _bar_mesh
	var middle := BAR * 0.5 + BEND
	var red_end := _tip_end() - STEEL_TIP + 0.004
	var path := PackedVector2Array([Vector2(red_end, BEND)])
	for i: int in BEND_STEPS + 1:
		var angle := PI * 0.5 + PI * float(i) / float(BEND_STEPS)
		path.append(Vector2(middle + cos(angle) * BEND, sin(angle) * BEND))
	path.append(Vector2(red_end, -BEND))
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_sweep(tool, path, BAR, THICK)
	_bar_mesh = tool.commit()
	return _bar_mesh


## The bare steel at the end of each leg, the two of them one mesh so they are drawn together,
## built once.
static func _poles() -> ArrayMesh:
	if _poles_mesh != null:
		return _poles_mesh
	var box := BoxMesh.new()
	box.size = Vector3(STEEL_TIP, BAR, THICK)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: float in [-1.0, 1.0]:
		var at := Vector3(_tip_end() - STEEL_TIP * 0.5, side * BEND, 0.0)
		tool.append_from(box, 0, Transform3D(Basis.IDENTITY, at))
	_poles_mesh = tool.commit()
	return _poles_mesh


## The arcs of the field, from one pole out and round to the other, each a thin bar, built once.
static func _field_arcs() -> ArrayMesh:
	if _field_mesh != null:
		return _field_mesh
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for reach: float in ARCS:
		var path := PackedVector2Array()
		for i: int in BEND_STEPS + 1:
			var angle := PI * float(i) / float(BEND_STEPS)
			path.append(Vector2(sin(angle) * reach, cos(angle) * BEND))
		_sweep(tool, path, ARC_THICK, ARC_THICK)
	_field_mesh = tool.commit()
	return _field_mesh


## The glow of the field: lit by nothing, added to what is behind it.
static func _glow() -> StandardMaterial3D:
	if _field_skin == null:
		_field_skin = StandardMaterial3D.new()
		_field_skin.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_field_skin.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_field_skin.cull_mode = BaseMaterial3D.CULL_DISABLED
		_field_skin.albedo_color = FIELD
	return _field_skin


## A bar [param wide] across in the plane of [param path] and [param thick] out of it, run along
## [param path], its sides smooth round the bends, into [param tool].
static func _sweep(tool: SurfaceTool, path: PackedVector2Array, wide: float, thick: float) -> void:
	var outs: Array[Vector3] = []
	for i: int in path.size():
		var along := path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)]
		outs.append(Vector3(-along.y, along.x, 0.0).normalized())
	var flat := Vector3(0.0, 0.0, thick * 0.5)
	for i: int in path.size() - 1:
		var a := Vector3(path[i].x, path[i].y, 0.0)
		var b := Vector3(path[i + 1].x, path[i + 1].y, 0.0)
		var a_out := outs[i] * wide * 0.5
		var b_out := outs[i + 1] * wide * 0.5
		for side: float in [-1.0, 1.0]:
			# Its two edges, the one out and the one in, and its two faces.
			_quad(
				tool,
				[a + a_out * side + flat, b + b_out * side + flat],
				[a + a_out * side - flat, b + b_out * side - flat],
				[outs[i] * side, outs[i + 1] * side]
			)
			_quad(
				tool,
				[a + a_out + flat * side, b + b_out + flat * side],
				[a - a_out + flat * side, b - b_out + flat * side],
				[Vector3.BACK * side, Vector3.BACK * side]
			)


## A quad between the edge [param one] and the edge [param other], each from the near end of a step
## to its far end, facing [param facing] at the two ends: wound to face that way.
static func _quad(tool: SurfaceTool, one: Array, other: Array, facing: Array) -> void:
	var corners: Array[Vector3] = [one[0], one[1], other[1], other[0]]
	var normals: Array[Vector3] = [facing[0], facing[1], facing[1], facing[0]]
	var wound := (corners[1] - corners[0]).cross(corners[2] - corners[0])
	# Godot's front faces go round clockwise seen from in front.
	var order: Array[int] = [0, 1, 2, 0, 2, 3]
	if wound.dot(normals[0] + normals[1]) > 0.0:
		order = [0, 2, 1, 0, 3, 2]
	for at: int in order:
		tool.set_normal(normals[at])
		tool.add_vertex(corners[at])
