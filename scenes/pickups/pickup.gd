class_name Pickup
extends Area3D
## Something a kart drives over and takes. Sits on the pickup layer; the kart's pickup area
## detects it and calls [method collect]. Subclasses build their look and apply their effect.

signal collected(pickup: Pickup, kart: Kart)

const SPIN_SPEED := 2.0
const BOB_HEIGHT := 0.06
const BOB_SPEED := 3.0
## How long a pickup takes to drop out of sight down a pit, and how fast it sinks.
const FALL_TIME := 0.8
const FALL_SPEED := 2.6

## Seconds before the pickup vanishes on its own; 0 keeps it forever.
var lifetime := 0.0
## Set when the pickup landed over a pit: it drops out of sight instead of settling.
var falling := false
## Height the visual hovers at, the centre of its bob. Subclasses set it in [method
## _build_visual] so the mesh clears the floor instead of sinking into it.
var hover := 0.35

var _age := 0.0
var _fall := 0.0
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
	if falling:
		_step_fall(delta)
		return
	_age += delta
	_visual.rotation.y += SPIN_SPEED * delta
	_visual.position.y = hover + sin(_age * BOB_SPEED) * BOB_HEIGHT
	if lifetime > 0.0:
		if _age >= lifetime:
			queue_free()
		elif lifetime - _age < 3.0:
			_visual.visible = fmod(_age, 0.3) < 0.2


## Sent down a pit, GAME.md 3.6: it drops out of sight, shrinking, and is gone. Nobody can
## take it on the way down.
func fall_into_pit() -> void:
	falling = true


## Whether this kart may take the pickup right now. Subclasses add their own rule on top of
## this one, which refuses anything already on its way down a pit.
func can_collect(_kart: Kart) -> bool:
	return not falling


func collect(kart: Kart) -> void:
	if _taken or not can_collect(kart):
		return
	_taken = true
	_apply(kart)
	collected.emit(self, kart)
	queue_free()


## Sinking into the hole: down, spinning and shrinking, then gone.
func _step_fall(delta: float) -> void:
	_fall += delta
	position.y -= FALL_SPEED * delta
	_visual.rotation.y += SPIN_SPEED * 2.0 * delta
	_visual.scale = Vector3.ONE * maxf(1.0 - _fall / FALL_TIME, 0.05)
	if _fall >= FALL_TIME:
		queue_free()


func _build_visual(_parent: Node3D) -> void:
	pass


func _apply(_kart: Kart) -> void:
	pass


static func _unshaded(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material
