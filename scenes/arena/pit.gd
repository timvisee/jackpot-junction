class_name Pit
extends Area3D
## A hole in the floor. A kart that enters starts falling and dies, see GAME.md 3.6.

signal kart_entered(body: Node3D)

## How far outside the hole still counts as being at it, in metres. Comfortably more than a kart
## is long, so nothing that is really falling in is turned away.
const NEAR := 2.0


func _ready() -> void:
	collision_layer = Layers.TRIGGER
	# Puppets too, so a client sees its own kart go down the hole when it drives into one rather
	# than a round trip later, GAME.md 10.3.
	collision_mask = Layers.KART | Layers.PROTECTED | Layers.PUPPET
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	var kart := body as Kart
	# Somebody else's kart, drawn on this screen where the host last said it was. Whether it is
	# over the hole is not a question this machine gets to answer, and dropping it here would be
	# dropping it on the strength of a position a round trip old.
	if kart != null and kart.puppet and not kart.predicted:
		return
	if not covers(body.global_position):
		return
	if body.has_method("start_fall"):
		body.call("start_fall")
	kart_entered.emit(body)


## Whether [param point] is anywhere near the hole. Worth asking, because a body that was already
## overlapping when it became something this could see at all is reported as entering, even if it
## has since been put somewhere else entirely. A kart coming back from a respawn is exactly that:
## it loses its collisions when it falls, gets them back when it returns, and was being dropped
## straight back down the hole it had just been fished out of.
##
## Generous on purpose. The shapes decide who falls, as they always have, and a kart goes down
## when a corner of it touches rather than when its middle arrives; this is only here to tell a
## kart at the edge of the hole from a kart that is halfway across the room.
func covers(point: Vector3) -> bool:
	for child: Node in get_children():
		var shape := child as CollisionShape3D
		var box := shape.shape as BoxShape3D if shape != null else null
		if box == null:
			continue
		var offset := point - global_position
		var half := box.size * 0.5 + Vector3.ONE * NEAR
		return absf(offset.x) <= half.x and absf(offset.z) <= half.z
	return true
