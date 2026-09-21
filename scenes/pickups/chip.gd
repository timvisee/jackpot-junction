class_name Chip
extends Pickup
## A poker chip worth [member value] coins. Gold chips are worth more; dropped chips come from
## deaths, vanish after a while and count differently for some jokers.
##
## Built as a chip rather than as a disc, GAME.md 8.1: it stands on its edge, so the edge is what
## the camera of 8.2 looks at, and an edge with notches cut into it is the one thing that says
## poker chip at twenty pixels across.

## How many pale notches are cut round the rim, and how much of the rim each one takes.
const NOTCHES := 6
const NOTCH_SHARE := 0.42
const PLAIN_RADIUS := 0.28
const GOLD_RADIUS := 0.34
const THICKNESS := 0.1

var value := 1
var gold := false
var dropped := false


func _build_visual(parent: Node3D) -> void:
	# The chip is built standing up and then laid on its edge in one move, so everything inside
	# is placed the way a chip is: the flat faces along its own Y, the rim round it.
	var chip := Node3D.new()
	chip.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	parent.add_child(chip)
	var radius := GOLD_RADIUS if gold else PLAIN_RADIUS
	var ink := Palette.CHIP_GOLD if gold else Palette.CHIP_RED
	chip.add_child(_body(radius, THICKNESS, ink))
	# The face is a shade lighter and a hair proud of the body, which is how a chip is printed.
	chip.add_child(_body(radius * 0.62, THICKNESS * 1.04, ink.lightened(0.35)))
	for i: int in NOTCHES:
		chip.add_child(_notch(radius, TAU * float(i) / float(NOTCHES)))
	hover = 0.4


func _apply(kart: Kart) -> void:
	kart.collect_coins(value, self)


## The disc itself: a short cylinder standing on its own axis.
func _body(radius: float, height: float, ink: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 18
	var disc := MeshInstance3D.new()
	disc.mesh = mesh
	disc.material_override = _paint(ink, 0.5 if gold else 0.0)
	return disc


## One pale notch cut into the rim, at [param angle] round it.
func _notch(radius: float, angle: float) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(radius * NOTCH_SHARE, THICKNESS * 1.06, radius * 0.5)
	var notch := MeshInstance3D.new()
	notch.mesh = mesh
	notch.material_override = _paint(Palette.CHIP_WHITE)
	notch.position = Vector3(cos(angle), 0.0, sin(angle)) * radius * 0.86
	notch.rotation.y = -angle
	return notch
