class_name OilStain
extends Area3D
## A slick of oil dropped on the floor, GAME.md 7.1. A kart whose center crosses it loses its
## tires: the nose whips around and the kart skids on, out of control, until it straightens out.
## The stain stays until its life runs out and catches anyone, the kart that dropped it included.
## It never kills; it costs control, position and a line of skid marks.

signal triggered(stain: OilStain, kart: Kart)

const RADIUS := 0.85
## Karts hit before this may drive over the stain without spinning again.
const REARM_TIME := 1.6
## How high the slick lies. The floor of this arena is not flat: the Junction, the Jackpot tiles
## and every pad stand a few centimeters proud of it, and a slick at floor level simply vanishes
## inside whichever one it was dropped on. It rides above the tallest of them instead, which
## reads as oil lying on top of what it was spilled on.
const LIFT := 0.09

var owner_slot := -1
var lifetime := 25.0
var puppet := false

var _age := 0.0
var _visual: Node3D
var _material: StandardMaterial3D
## Kart instance id to the time it may be caught again.
var _recent: Dictionary[int, float] = {}


func _ready() -> void:
	collision_layer = Layers.TRIGGER
	collision_mask = Layers.KART | Layers.PROTECTED
	add_to_group(&"oil_stains")
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = RADIUS
	cylinder.height = 1.0
	shape.shape = cylinder
	shape.position = Vector3(0.0, 0.5, 0.0)
	add_child(shape)
	_build_visuals()


func _physics_process(delta: float) -> void:
	_age += delta
	# Spreading as it settles, then fading away in its last seconds.
	var spread := minf(_age / 0.5, 1.0)
	var left := lifetime - _age
	var fade := clampf(left / 3.0, 0.0, 1.0)
	_visual.scale = Vector3(spread, 1.0, spread)
	_material.albedo_color.a = 0.85 * fade
	if _age >= lifetime:
		queue_free()
		return
	if puppet:
		return
	for body: Node3D in get_overlapping_bodies():
		var kart := body as Kart
		if kart == null or not _catches(kart):
			continue
		_recent[kart.get_instance_id()] = _age + REARM_TIME
		kart.hit_oil(_spin_direction(kart))
		triggered.emit(self, kart)


## Whether this kart is in a state to be caught: alive, driving, and not still spinning from a
## stain it crossed a moment ago.
func _catches(kart: Kart) -> bool:
	if not kart.is_active() or kart.motor.spinning():
		return false
	if kart.global_position.distance_to(global_position) > RADIUS:
		return false
	return _age >= float(_recent.get(kart.get_instance_id(), -1.0))


## Which way the nose whips: away from the side of the stain the kart drives past, so the spin
## follows the line the kart was already taking.
func _spin_direction(kart: Kart) -> float:
	var offset := kart.global_position - global_position
	offset.y = 0.0
	var travel := kart.motor.velocity
	if travel.length() < 0.5 or offset.is_zero_approx():
		return 1.0 if kart.motor.steer >= 0.0 else -1.0
	var side := travel.normalized().signed_angle_to(offset.normalized(), Vector3.UP)
	return 1.0 if side >= 0.0 else -1.0


func _build_visuals() -> void:
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.06, 0.05, 0.08, 0.85)
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.metallic = 0.9
	_material.roughness = 0.1
	# Three overlapping puddles, so the slick reads as a spill rather than a disc.
	var blobs: Array[Vector3] = [
		Vector3(0.0, 0.0, 0.0), Vector3(0.42, 0.0, 0.18), Vector3(-0.3, 0.0, -0.34)
	]
	var sizes: Array[float] = [1.0, 0.62, 0.5]
	for i: int in blobs.size():
		var blob := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = RADIUS * sizes[i]
		mesh.bottom_radius = mesh.top_radius
		mesh.height = 0.02
		blob.mesh = mesh
		blob.material_override = _material
		blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		blob.position = blobs[i] + Vector3(0.0, LIFT, 0.0)
		_visual.add_child(blob)
	var sheen := MeshInstance3D.new()
	var sheen_mesh := CylinderMesh.new()
	sheen_mesh.top_radius = RADIUS * 0.34
	sheen_mesh.bottom_radius = sheen_mesh.top_radius
	sheen_mesh.height = 0.02
	sheen.mesh = sheen_mesh
	var sheen_material := StandardMaterial3D.new()
	sheen_material.albedo_color = Color(0.45, 0.4, 0.6, 0.35)
	sheen_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sheen_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sheen.material_override = sheen_material
	sheen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sheen.position = Vector3(-0.18, LIFT + 0.015, 0.12)
	_visual.add_child(sheen)
