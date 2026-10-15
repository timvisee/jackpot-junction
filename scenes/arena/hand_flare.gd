class_name HandFlare
extends Node3D
## A hand made, seen on the table, GAME.md 7.3: the suits of it burst out round the kart in a ring
## and fade, every screen seeing every kart's, and for a Four of a Kind or a Flush a column of gold
## light goes up off the kart with them. See [HandFanfare] for what the player's own screen does.

## Whether the ring goes up at all, and the column for the best hands; to try the fanfare's pieces.
const RING := true
const COLUMN := true
## How many suits, how far out they fly, how high, how big and for how long; and the column's
## height, width and time.
const MARKS := 8
const OUT := 2.6
const RISE := 1.2
const MARK := 0.42
const TIME := 0.9
const COLUMN_HEIGHT := 5.0
const COLUMN_WIDE := 0.55
const COLUMN_TIME := 1.1

## The flat mesh of each suit, made once, by [enum Joker.Suit].
static var _meshes: Dictionary[int, ArrayMesh] = {}

var _suits: Array[int] = []
var _column := false
var _age := 0.0
var _marks: Array[MeshInstance3D] = []
var _beam: MeshInstance3D
var _beam_look: StandardMaterial3D


## [param kart]'s hand gained [param gained]: the flare for the best of it.
static func on_hands_changed(gained: Array[int], _lost: Array[int], kart: Kart) -> void:
	if gained.is_empty() or not RING or not is_instance_valid(kart) or not kart.is_inside_tree():
		return
	if not kart.alive or kart.is_decoy() or Game.is_headless():
		return
	var flare := HandFlare.new()
	flare._suits = kart.jokers.made.shown.duplicate()
	if flare._suits.is_empty():
		return
	var best: int = gained.min()
	flare._column = COLUMN and best <= JokerHands.Hand.FOUR_OF_A_KIND
	kart.add_child(flare)
	flare.position = Vector3(0.0, 0.6, 0.0)


func _ready() -> void:
	for i: int in MARKS:
		var suit := _suits[i % _suits.size()]
		var mark := MeshInstance3D.new()
		mark.mesh = _mesh_of(suit)
		var look := StandardMaterial3D.new()
		look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		look.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		look.cull_mode = BaseMaterial3D.CULL_DISABLED
		look.albedo_color = JokerSuits.color_of(suit)
		mark.material_override = look
		mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mark.scale = Vector3.ONE * MARK
		add_child(mark)
		_marks.append(mark)
	if _column:
		_beam = MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = COLUMN_WIDE * 0.6
		cylinder.bottom_radius = COLUMN_WIDE
		cylinder.height = COLUMN_HEIGHT
		cylinder.cap_top = false
		cylinder.cap_bottom = false
		_beam.mesh = cylinder
		_beam_look = StandardMaterial3D.new()
		_beam_look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_beam_look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_beam_look.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_beam_look.cull_mode = BaseMaterial3D.CULL_DISABLED
		_beam_look.albedo_color = Color(Palette.CHIP_GOLD, 0.0)
		_beam.material_override = _beam_look
		_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_beam.position = Vector3(0.0, COLUMN_HEIGHT * 0.5 - 0.4, 0.0)
		add_child(_beam)


func _process(delta: float) -> void:
	_age += delta
	var t := clampf(_age / TIME, 0.0, 1.0)
	var out := ease(t, 0.35)
	for i: int in _marks.size():
		var angle := TAU * i / _marks.size()
		var mark := _marks[i]
		mark.position = Vector3(cos(angle) * OUT * out, RISE * out, sin(angle) * OUT * out)
		var look := mark.material_override as StandardMaterial3D
		look.albedo_color.a = 1.0 - t * t
		mark.scale = Vector3.ONE * MARK * (0.6 + 0.4 * (1.0 - t))
	if _beam != null:
		var b := clampf(_age / COLUMN_TIME, 0.0, 1.0)
		_beam_look.albedo_color.a = 0.45 * sin(PI * b)
		_beam.scale = Vector3(1.0, 0.4 + 0.6 * ease(b, 0.3), 1.0)
	if _age >= maxf(TIME, COLUMN_TIME if _beam != null else 0.0):
		queue_free()


## [param suit]'s flat mesh, a unit across, standing up, made once.
static func _mesh_of(suit: int) -> ArrayMesh:
	if _meshes.has(suit):
		return _meshes[suit]
	var outline := SuitArt.outline(suit)
	var points := PackedVector3Array()
	for point: Vector2 in outline:
		points.append(Vector3(point.x - 0.5, 0.5 - point.y, 0.0))
	var indices := Geometry2D.triangulate_polygon(outline)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_meshes[suit] = mesh
	return mesh
