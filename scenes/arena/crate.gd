class_name Crate
extends StaticBody3D
## Destructible cover. One bullet destroys it; it comes back after a delay. Chip drops land in M2.

signal destroyed(by_slot: int)
signal respawned

@export var respawn_delay := 30.0

var alive := true
## On a client a crate is told whether it is there, GAME.md 10.3; it does not keep its own
## clock. Left to run one it would revive itself the frame after a snapshot killed it, and the
## next snapshot would find it alive and kill it again, bursting once per snapshot for as long
## as it was really gone.
var puppet := false

var _respawn_left := 0.0


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0
	add_to_group(&"crates")


## A box a client has just driven through, GAME.md 10.3. It goes off the floor here so the kart
## is not seen ploughing through a box that is still drawn, and nothing else about it happens:
## the chips it drops, the credit for it and the burst are the host's, and arrive on their own. A
## snapshot that disagrees puts the box straight back, which is what makes guessing safe.
func predict_break() -> void:
	alive = false
	visible = false
	collision_layer = 0


func hit(by_slot: int) -> void:
	if not alive:
		return
	alive = false
	visible = false
	Burst.spawn(get_parent(), global_position, Palette.BLOCK, 0.9, 18)
	collision_layer = 0
	_respawn_left = respawn_delay
	destroyed.emit(by_slot)
	Events.crate_destroyed.emit()


func _physics_process(delta: float) -> void:
	if alive or puppet:
		return
	_respawn_left -= delta
	if _respawn_left <= 0.0:
		alive = true
		visible = true
		collision_layer = Layers.WORLD
		respawned.emit()
