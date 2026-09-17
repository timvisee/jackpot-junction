class_name SpawningPad
extends Node3D
## A pad that keeps one pickup lying on it and puts another out a while after somebody takes it:
## the coin pads of GAME.md 3.2, the item pads of 7.1 and the joker pad of 6.2 are all this same
## thing with a different thing on top.
##
## Inert until [method start] on the pad itself hands it the rules and the match's generator.
## Subclasses say what to put out, how long to wait before the next one, and whether they have
## what they need to put anything out at all.

var rules: MatchRules
var rng: RandomNumberGenerator
var pickup_parent: Node
## What is lying on the pad, or null while it is waiting to put the next one out.
var current: Pickup

var _respawn_left := 0.0


func _physics_process(delta: float) -> void:
	if not _can_spawn() or current != null:
		return
	_respawn_left -= delta
	if _respawn_left <= 0.0:
		_spawn()


## Lays [param pickup] on the pad and watches for it being taken.
func _place(pickup: Pickup) -> void:
	pickup.position = global_position
	pickup.collected.connect(_on_collected)
	pickup_parent.add_child(pickup)
	current = pickup


func _on_collected(_pickup: Pickup, _kart: Kart) -> void:
	current = null
	_respawn_left = _respawn_delay()


## Whether the pad has everything it needs to put something out.
func _can_spawn() -> bool:
	return rules != null


func _spawn() -> void:
	pass


func _respawn_delay() -> float:
	return 0.0
