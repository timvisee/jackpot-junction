class_name Billboard
extends Node3D
## A hoarding standing over the crowd, GAME.md 8.1: the kind of board a real arena sells to
## whoever will pay for it. Two of them carry the house's own advertising and a third carries
## the clock, see [LedClock].
##
## Scenery, like the crowd and the tanks: no collision, nothing decided here. The board is built
## facing +Z, and [method add_to] turns it to look at the middle of the table.

## The face, and how far above the table its bottom edge sits: over the heads of a crowd four
## rows deep and up a tier, so a board is read rather than glimpsed between shoulders.
const WIDTH := 5.6
const HEIGHT := 2.25
const LIFT := 1.9
## The legs it stands on and the frame around the face.
const POST := 0.18
const FRAME := 0.15
const DEPTH := 0.15
const STEEL := Color(0.17, 0.17, 0.2)
const FACE := Color(0.07, 0.07, 0.09)

## The middle of the face, in board space: x to the right of it, y up, and +z out of it. Ads and
## the clock hang off this rather than off the board, so neither has to know about the legs.
var face: Node3D


## Stands a board at [param at] with its face turned toward [param toward], and returns it.
static func add_to(parent: Node3D, at: Vector3, toward: Vector3) -> Billboard:
	var board := Billboard.new()
	board.name = "Billboard"
	parent.add_child(board)
	board.global_position = at
	var away := Vector3(toward.x - at.x, 0.0, toward.z - at.z)
	if away.length() > 0.01:
		board.rotation.y = atan2(away.x, away.z)
	board._build()
	return board


## A panel of colour across the face, for an ad to be built out of. [param at] and [param size]
## are in metres from the middle of the face.
func panel(at: Vector2, size: Vector2, color: Color, lit := false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, size.y, 0.04)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _paint(color, lit)
	node.position = Vector3(at.x, at.y, 0.03)
	face.add_child(node)
	return node


## Words across the face, lying flat on it rather than turning to the camera: a board is part of
## the room, and a sign that swings round to face you is a label.
func words(text: String, at: Vector2, size: float, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = 64
	label.pixel_size = size / 64.0
	label.modulate = color
	label.outline_size = 10
	label.outline_modulate = Color(0.03, 0.03, 0.04, 0.9)
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.double_sided = false
	label.position = Vector3(at.x, at.y, 0.06)
	face.add_child(label)
	return label


func _build() -> void:
	var stand := LIFT + HEIGHT * 0.5
	for side: float in [-1.0, 1.0]:
		var leg := _box(Vector3(POST, LIFT + HEIGHT * 0.5, POST), STEEL)
		leg.position = Vector3(side * (WIDTH * 0.5 - POST), stand * 0.5 - HEIGHT * 0.5, 0.0)
		add_child(leg)
	var frame := _box(Vector3(WIDTH + FRAME * 2.0, HEIGHT + FRAME * 2.0, DEPTH), STEEL)
	frame.position = Vector3(0.0, stand, 0.0)
	add_child(frame)
	face = Node3D.new()
	face.name = "Face"
	face.position = Vector3(0.0, stand, DEPTH * 0.5)
	add_child(face)
	var board := _box(Vector3(WIDTH, HEIGHT, 0.02), FACE)
	board.position = Vector3(0.0, 0.0, 0.01)
	face.add_child(board)


func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _paint(color, false)
	return node


func _paint(color: Color, lit: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if lit:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.7
	return material
