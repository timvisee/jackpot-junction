class_name Chip
extends Pickup
## A poker chip worth [member value] coins. Gold chips are worth more; dropped chips come from
## deaths, vanish after a while and count differently for some jokers.
##
## Built as a chip rather than as a disc, GAME.md 8.1: it stands on its edge, so the edge is what
## the camera of 8.2 looks at, and an edge with notches cut into it is the one thing that says
## poker chip at twenty pixels across.
##
## One mesh and one material, shared by every chip of its kind, GAME.md 10.7: the body, the face
## and the six notches are merged once with their colors on the vertices, so a chip is one thing
## to draw rather than eight, and a death that drops ten builds nothing.

## How many pale notches are cut round the rim, and how much of the rim each one takes.
const NOTCHES := 6
const NOTCH_SHARE := 0.42
const PLAIN_RADIUS := 0.28
const GOLD_RADIUS := 0.34
const THICKNESS := 0.1

## The two kinds of chip, plain and gold, each one mesh and one material, made the first time
## either is asked for.
static var _meshes: Dictionary[bool, ArrayMesh] = {}
static var _paints: Dictionary[bool, StandardMaterial3D] = {}

var value := 1
var gold := false
var dropped := false


func _build_visual(parent: Node3D) -> void:
	# The chip is built standing up and then laid on its edge in one move, so everything inside
	# is placed the way a chip is: the flat faces along its own Y, the rim round it.
	var chip := MeshInstance3D.new()
	chip.name = "Chip"
	chip.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	chip.mesh = mesh_for(gold)
	chip.material_override = paint_for(gold)
	parent.add_child(chip)
	hover = 0.4


func _apply(kart: Kart) -> void:
	kart.collect_coins(value, self)


func heard_as(kart: Kart) -> Array:
	return [&"coin_collected", [kart.slot, value]]


## The one mesh a chip of a kind is: the disc, the lighter face a hair proud of it, which is how
## a chip is printed, and the notches round the rim, in their colors.
static func mesh_for(is_gold: bool) -> ArrayMesh:
	if _meshes.has(is_gold):
		return _meshes[is_gold]
	var radius := GOLD_RADIUS if is_gold else PLAIN_RADIUS
	var ink := Palette.CHIP_GOLD if is_gold else Palette.CHIP_RED
	var pieces: Array[Array] = [
		[_body(radius, THICKNESS), Transform3D.IDENTITY, ink],
		[_body(radius * 0.62, THICKNESS * 1.04), Transform3D.IDENTITY, ink.lightened(0.35)],
	]
	for i: int in NOTCHES:
		var angle := TAU * float(i) / float(NOTCHES)
		var notch := BoxMesh.new()
		notch.size = Vector3(radius * NOTCH_SHARE, THICKNESS * 1.06, radius * 0.5)
		var at := Vector3(cos(angle), 0.0, sin(angle)) * radius * 0.86
		pieces.append([notch, Transform3D(Basis(Vector3.UP, -angle), at), Palette.CHIP_WHITE])
	var mesh := Bake.tinted(pieces)
	_meshes[is_gold] = mesh
	return mesh


## What a chip of a kind wears: plastic, or metal for the gold ones, colored by the mesh.
static func paint_for(is_gold: bool) -> StandardMaterial3D:
	if _paints.has(is_gold):
		return _paints[is_gold]
	var paint := _paint(Color.WHITE, 0.5 if is_gold else 0.0)
	paint.vertex_color_use_as_albedo = true
	_paints[is_gold] = paint
	return paint


## The disc itself: a short cylinder standing on its own axis.
static func _body(radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 18
	mesh.rings = 1
	return mesh
