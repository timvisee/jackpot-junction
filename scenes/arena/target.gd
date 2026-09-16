class_name Target
extends StaticBody3D
## A shooting-gallery target, GAME.md 6.2. A bullet knocks its face down and pays the shooter a
## few coins; it pops back up a few seconds later. Karts bump into the post like any other piece
## of furniture, but only a bullet counts as a hit.
##
## The face is tilted back toward the fixed camera so the rings read from the usual viewing
## angle, and it sits at bullet height so a straight shot finds it.

signal struck(target: Target, by_slot: int)

const FACE_HEIGHT := 0.75
const RESPAWN_DELAY := 4.0
## Ring colours from the outside in.
const RINGS: Array[Color] = [Palette.CHIP_WHITE, Palette.CHIP_RED, Palette.CHIP_GOLD]

## Coins the shooter collects, set by the arena from the rules.
var coins := 3
var alive := true

var _left := 0.0
var _face: Node3D


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0
	add_to_group(&"targets")
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.1, 1.0, 0.4)
	shape.shape = box
	shape.position = Vector3(0.0, FACE_HEIGHT, 0.0)
	add_child(shape)
	_build_visuals()


## A bullet reached the face. Returns false once it is already down, so a second bullet in the
## same volley carries on instead of vanishing on nothing.
func take_hit(bullet: Bullet) -> bool:
	if not alive:
		return false
	alive = false
	visible = false
	collision_layer = 0
	_left = RESPAWN_DELAY
	Burst.spawn(get_parent(), global_position + Vector3(0.0, FACE_HEIGHT, 0.0), RINGS[1], 0.7, 12)
	struck.emit(self, bullet.owner_slot)
	Events.target_struck.emit(bullet.owner_slot, coins)
	return true


func _physics_process(delta: float) -> void:
	if alive:
		return
	_left -= delta
	if _left <= 0.0:
		alive = true
		visible = true
		collision_layer = Layers.WORLD


func _build_visuals() -> void:
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.16, 0.16, 0.19)
	var post := MeshInstance3D.new()
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.14, FACE_HEIGHT, 0.14)
	post.mesh = post_mesh
	post.material_override = dark
	post.position = Vector3(0.0, FACE_HEIGHT * 0.5, 0.0)
	add_child(post)
	_face = Node3D.new()
	_face.name = "Face"
	# Tipped back so the rings face the camera, which looks down the table from the +Z side.
	_face.rotation_degrees = Vector3(40.0, 0.0, 0.0)
	_face.position = Vector3(0.0, FACE_HEIGHT, 0.0)
	add_child(_face)
	for i: int in RINGS.size():
		var ring := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.55 - 0.17 * i
		disc.bottom_radius = disc.top_radius
		disc.height = 0.06 if i == 0 else 0.03
		ring.mesh = disc
		var material := StandardMaterial3D.new()
		material.albedo_color = RINGS[i]
		material.emission_enabled = true
		material.emission = RINGS[i]
		material.emission_energy_multiplier = 0.25
		ring.material_override = material
		# The cylinder's axis is Y, which the leaning face has already tipped toward the camera,
		# so the rings stack along it straight out of the plate.
		ring.position = Vector3(0.0, 0.03 * i, 0.0)
		_face.add_child(ring)
