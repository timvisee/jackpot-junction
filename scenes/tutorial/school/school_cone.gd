class_name SchoolCone
extends Node3D
## A traffic cone of the driving test, GAME.md 9.4a: kart-sized, a square foot and a tapering body
## in cone orange with a pale band, out of the room's own materials as the rest of the dressing is.
## Each its own piece, so it rises out of the floor with its lesson, see [RisingPiece]. A kart that
## hits one knocks it over, away from where the kart came from, and it lies there, rolled a little,
## for the rest of the test; nothing stops for it, and the license counts it.

## Knocked over by the kart of [param by_slot].
signal knocked(by_slot: int)

const ORANGE := Color(0.94, 0.42, 0.1)
const FOOT := Color(0.16, 0.16, 0.18)
const BAND := Color(0.93, 0.92, 0.88)
const HEIGHT := 0.72
## How much floor a cone stands on, for its outline as it comes up.
const ACROSS := Vector2(0.6, 0.6)
const GROUP := &"school_cones"
## How near a kart's middle has to come to knock one over, in meters, how long it takes to go down,
## and how far it rolls.
const REACH := 0.75
const FALL := 0.35
const ROLL := 0.5

## Whether it is down.
var down := false


## A cone at [param at] on the floor of [param arena], held back until its lesson brings it up.
static func stand(arena: Arena, at: Vector3, name_as: String) -> SchoolCone:
	var cone := SchoolCone.new()
	cone.name = name_as
	cone.add_to_group(GROUP)
	var surfaces := arena.surfaces
	cone._part(BoxMesh.new(), Vector3(0.5, 0.06, 0.5), surfaces.painted(FOOT), 0.03)
	var body := CylinderMesh.new()
	body.top_radius = 0.05
	body.bottom_radius = 0.2
	body.height = HEIGHT
	body.radial_segments = 12
	cone._part(body, Vector3.ONE, surfaces.painted(ORANGE), HEIGHT * 0.5 + 0.06)
	var band := CylinderMesh.new()
	band.top_radius = 0.115
	band.bottom_radius = 0.145
	band.height = 0.12
	band.radial_segments = 12
	cone._part(band, Vector3.ONE, surfaces.painted(BAND), HEIGHT * 0.5 + 0.1)
	var feel := Area3D.new()
	feel.name = "Feel"
	feel.collision_layer = 0
	feel.collision_mask = Layers.KART
	feel.monitorable = false
	var shape := CollisionShape3D.new()
	var reach := CylinderShape3D.new()
	reach.radius = REACH
	reach.height = 1.2
	shape.shape = reach
	shape.position.y = 0.6
	feel.add_child(shape)
	feel.body_entered.connect(cone._on_body_entered)
	cone.add_child(feel)
	arena.add_child(cone)
	cone.position = Vector3(at.x, 0.0, at.z)
	RisingPiece.hold(cone)
	return cone


func _on_body_entered(body: Node3D) -> void:
	var kart := body as Kart
	if kart == null or down or not RisingPiece.is_up(self):
		return
	knock(kart.slot, kart.global_position)


## Knocked over by the kart of [param by_slot], which came from [param from]: down away from it,
## rolled a little, with a clatter, and down for good.
func knock(by_slot: int, from: Vector3) -> void:
	if down:
		return
	down = true
	var away := global_position - from
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else Vector3.FORWARD
	var axis := Vector3.UP.cross(away).normalized()
	var fall := create_tween().set_parallel(true)
	fall.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	fall.tween_property(self, "quaternion", Quaternion(axis, PI * 0.5) * quaternion, FALL)
	fall.tween_property(self, "position", position + away * ROLL + Vector3(0.0, 0.15, 0.0), FALL)
	Audio.play_sfx(&"bump", -10.0, 0.15, 1.4)
	var feel := get_node_or_null("Feel") as Area3D
	if feel != null:
		feel.set_deferred("monitoring", false)
	knocked.emit(by_slot)


func _part(mesh: PrimitiveMesh, box_size: Vector3, skin: Material, height: float) -> void:
	if mesh is BoxMesh:
		(mesh as BoxMesh).size = box_size
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = skin
	part.position.y = height
	add_child(part)
