class_name Crate
extends StaticBody3D
## Destructible cover. One bullet destroys it; it comes back after a delay. Chip drops land in M2.

signal destroyed(by_slot: int)
signal respawned

@export var respawn_delay := 30.0

var alive := true

var _respawn_left := 0.0


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0


func hit(by_slot: int) -> void:
	if not alive:
		return
	alive = false
	visible = false
	collision_layer = 0
	_respawn_left = respawn_delay
	destroyed.emit(by_slot)


func _physics_process(delta: float) -> void:
	if alive:
		return
	_respawn_left -= delta
	if _respawn_left <= 0.0:
		alive = true
		visible = true
		collision_layer = Layers.WORLD
		respawned.emit()
