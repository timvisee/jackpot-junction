class_name SuitBurst
extends Node3D
## A ring of card suits bursting out round a point on the table and fading, flat marks turned to
## the camera, each in its suit's own color. Made for a hand made, GAME.md 7.3, and found too much
## for it; kept for a moment that earns it, see [method spawn].

## How many marks, how far out they fly, how high, how big and for how long.
const MARKS := 8
const OUT := 2.6
const RISE := 1.2
const MARK := 0.42
const TIME := 0.9

## The flat mesh of each suit, made once, by [enum Joker.Suit].
static var _meshes: Dictionary[int, ArrayMesh] = {}

var _suits: Array[int] = []
var _age := 0.0
var _marks: Array[MeshInstance3D] = []


## A burst of [param suits], by [enum Joker.Suit], taken in turn round the ring, at [param at] under
## [param parent]. Nothing with no screen to draw on.
static func spawn(parent: Node, suits: Array[int], at: Vector3) -> SuitBurst:
	if suits.is_empty() or Game.is_headless():
		return null
	var burst := SuitBurst.new()
	burst._suits = suits.duplicate()
	parent.add_child(burst)
	burst.position = at
	return burst


func _ready() -> void:
	for i: int in MARKS:
		var suit := _suits[i % _suits.size()]
		var mark := MeshInstance3D.new()
		mark.mesh = mesh_of(suit)
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
	if _age >= TIME:
		queue_free()


## [param suit]'s flat mesh, a unit across, standing up, made once.
static func mesh_of(suit: int) -> ArrayMesh:
	if _meshes.has(suit):
		return _meshes[suit]
	var outline := SuitArt.outline(suit)
	var points := PackedVector3Array()
	for point: Vector2 in outline:
		points.append(Vector3(point.x - 0.5, 0.5 - point.y, 0.0))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_INDEX] = Geometry2D.triangulate_polygon(outline)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_meshes[suit] = mesh
	return mesh
