class_name Crate
extends StaticBody3D
## Destructible cover. One bullet destroys it; it comes back after a delay. Chip drops land in M2.

signal destroyed(by_slot: int)
signal respawned

## How long a client's own guess that it broke this box stands before the snapshot is allowed to
## put it back, GAME.md 10.3. Comfortably past any round trip: the host either agrees inside it,
## in which case the box stays gone, or it does not and the box returns.
const PREDICTED_HOLD := 1.0

@export var respawn_delay := 30.0

var alive := true
## On a client a crate is told whether it is there, GAME.md 10.3; it does not keep its own
## clock. Left to run one it would revive itself the frame after a snapshot killed it, and the
## next snapshot would find it alive and kill it again, bursting once per snapshot for as long
## as it was really gone.
var puppet := false

var _respawn_left := 0.0
## Seconds left of this client standing by its own answer about this box.
var _predicted_left := 0.0


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0
	add_to_group(&"crates")
	# Worth bending a shot toward, GAME.md 5.1: a box broken is cover gone and coins on the floor.
	add_to_group(Bullet.TARGET_GROUP)


## Whether a shot may be aimed at this box, GAME.md 5.1.
func is_targetable() -> bool:
	return alive


## A box a client has just driven through, GAME.md 10.3. It goes off the floor here and stays
## off it: the snapshots arriving over the next round trip were built before the host had heard
## about this, and letting them put the box back is what left a kart stuck against a box it had
## already gone through, waiting to be dragged past it.
##
## The pieces fly here too, because a box that vanishes without them reads as a glitch and the
## host's own burst will not arrive: the host says a box is gone and this machine already knew.
## Nothing else about it happens here. The chips it drops and the credit for it are the host's.
func predict_break() -> void:
	if not alive:
		return
	alive = false
	visible = false
	collision_layer = 0
	_predicted_left = PREDICTED_HOLD
	Burst.spawn(get_parent(), global_position, Palette.BLOCK, 0.9, 18)


## Whether this client is still standing by its own answer about this box rather than the
## snapshot's. The snapshot wins again the moment this lapses.
func predicted_break() -> bool:
	return _predicted_left > 0.0


## The host's word, which settles it either way: gone for good, or never gone at all.
func settle_break(host_says_alive: bool) -> void:
	_predicted_left = 0.0
	if host_says_alive == alive:
		return
	alive = host_says_alive
	visible = host_says_alive
	collision_layer = Layers.WORLD if host_says_alive else 0


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
	_predicted_left = maxf(_predicted_left - delta, 0.0)
	if alive or puppet:
		return
	_respawn_left -= delta
	if _respawn_left <= 0.0:
		alive = true
		visible = true
		collision_layer = Layers.WORLD
		respawned.emit()
