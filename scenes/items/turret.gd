class_name Turret
extends StaticBody3D
## A deployed turret, GAME.md 7.1 and 7.2. Turns toward the nearest enemy kart and fires default
## bullets in its owner's color, so kills credit the owner. One hit or the end of its life
## removes it.

signal destroyed(turret: Turret)

const TURN_RATE := PI
const AIM_TOLERANCE := 0.09
const RANGE := 30.0

## Whether every turret shoots the gallery's targets of 6.2 as well, when no kart is in reach: the
## tutorial's do, GAME.md 9.4a, turned on by the tutorial for as long as it runs, and a match's
## never. [member shoots_targets] is the same for one turret.
static var hunts_targets := false

var owner_slot := -1
var shoots_targets := false
## How far it shoots, [constant RANGE] unless told otherwise.
var reach := RANGE
## The slot this turret belongs to, for bullets' target filtering.
var slot := -1
var lifetime := 20.0
var fire_interval := 1.0
var bullet_system: BulletSystem
var cannon_stats: CannonStats
var color := Color.WHITE
var alive := true
var puppet := false

var _fire_left := 0.5
var _barrel: Node3D


func _ready() -> void:
	slot = owner_slot
	collision_layer = Layers.TURRET
	collision_mask = 0
	add_to_group(&"turrets")
	add_to_group(Bullet.TARGET_GROUP)
	if cannon_stats == null:
		cannon_stats = load("res://data/cannons/default.tres").duplicate()
		cannon_stats.aim_assist = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 0.9, 0.9)
	shape.shape = box
	shape.position = Vector3(0.0, 0.45, 0.0)
	add_child(shape)
	_build_visuals()


func is_targetable() -> bool:
	return alive


func take_hit(_bullet: Bullet) -> bool:
	if not alive:
		return false
	destroy()
	return true


func destroy() -> void:
	if not alive:
		return
	alive = false
	Burst.spawn(get_parent(), global_position, color, 0.8, 14)
	destroyed.emit(self)
	queue_free()


func _physics_process(delta: float) -> void:
	if not alive or puppet:
		return
	lifetime -= delta
	if lifetime <= 0.0:
		destroy()
		return
	var target: Node3D = _nearest_enemy()
	if target == null and (shoots_targets or hunts_targets):
		target = _nearest_target()
	if target == null:
		return
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var wanted := atan2(-to_target.x, -to_target.z)
	rotation.y = rotate_toward(rotation.y, wanted, TURN_RATE * delta)
	_fire_left -= delta
	if (
		_fire_left <= 0.0
		and absf(angle_difference(rotation.y, wanted)) < AIM_TOLERANCE
		and bullet_system != null
	):
		_fire_left = fire_interval
		var direction := -global_basis.z
		var shot := bullet_system.spawn(
			owner_slot,
			global_position + direction * 0.9,
			direction,
			cannon_stats,
			color,
			global_position
		)
		shot.from_turret = true


func _nearest_enemy() -> Kart:
	var best: Kart = null
	var best_distance := reach
	for node: Node in FrameGroups.of(get_tree(), &"karts"):
		var kart := node as Kart if is_instance_valid(node) else null
		if kart == null or kart.slot == owner_slot or not kart.is_targetable():
			continue
		var distance := global_position.distance_to(kart.global_position)
		if distance < best_distance:
			best_distance = distance
			best = kart
	return best


func _nearest_target() -> Target:
	var best: Target = null
	var best_distance := reach
	for node: Node in FrameGroups.of(get_tree(), &"targets"):
		var target := node as Target if is_instance_valid(node) else null
		if target == null or not target.is_targetable():
			continue
		var distance := global_position.distance_to(target.global_position)
		if distance < best_distance:
			best_distance = distance
			best = target
	return best


func _build_visuals() -> void:
	var tint := StandardMaterial3D.new()
	tint.albedo_color = color
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.15, 0.15, 0.17)
	var base := MeshInstance3D.new()
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(0.8, 0.4, 0.8)
	base.mesh = base_mesh
	base.material_override = dark
	base.position = Vector3(0.0, 0.2, 0.0)
	add_child(base)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.3
	head_mesh.height = 0.6
	head_mesh.radial_segments = 12
	head_mesh.rings = 6
	head.mesh = head_mesh
	head.material_override = tint
	head.position = Vector3(0.0, 0.55, 0.0)
	add_child(head)
	_barrel = MeshInstance3D.new()
	var barrel_mesh := CylinderMesh.new()
	barrel_mesh.top_radius = 0.08
	barrel_mesh.bottom_radius = 0.08
	barrel_mesh.height = 0.7
	barrel_mesh.radial_segments = 10
	barrel_mesh.rings = 1
	_barrel.mesh = barrel_mesh
	_barrel.material_override = dark
	_barrel.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	_barrel.position = Vector3(0.0, 0.55, -0.45)
	add_child(_barrel)
