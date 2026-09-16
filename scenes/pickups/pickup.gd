class_name Pickup
extends Area3D
## Something a kart drives over and takes. Sits on the pickup layer; the kart's pickup area
## detects it and calls [method collect]. Subclasses build their look and apply their effect.

signal collected(pickup: Pickup, kart: Kart)

const SPIN_SPEED := 2.0
const BOB_HEIGHT := 0.06
const BOB_SPEED := 3.0

## Seconds before the pickup vanishes on its own; 0 keeps it forever.
var lifetime := 0.0
## Height the visual hovers at, the centre of its bob. Subclasses set it in [method
## _build_visual] so the mesh clears the floor instead of sinking into it.
var hover := 0.35

var _age := 0.0
var _taken := false
var _base_y := 0.3
var _visual: Node3D


func _ready() -> void:
	collision_layer = Layers.PICKUP
	collision_mask = 0
	monitoring = false
	add_to_group(&"pickups")
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.35
	shape.shape = sphere
	add_child(shape)
	_base_y = position.y
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_build_visual(_visual)


func _process(delta: float) -> void:
	_age += delta
	_visual.rotation.y += SPIN_SPEED * delta
	_visual.position.y = hover + sin(_age * BOB_SPEED) * BOB_HEIGHT
	if lifetime > 0.0:
		if _age >= lifetime:
			queue_free()
		elif lifetime - _age < 3.0:
			_visual.visible = fmod(_age, 0.3) < 0.2


## Whether this kart may take the pickup right now.
func can_collect(_kart: Kart) -> bool:
	return true


func collect(kart: Kart) -> void:
	if _taken or not can_collect(kart):
		return
	_taken = true
	_apply(kart)
	collected.emit(self, kart)
	queue_free()


func _build_visual(_parent: Node3D) -> void:
	pass


func _apply(_kart: Kart) -> void:
	pass


static func _unshaded(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material
