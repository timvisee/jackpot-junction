class_name TutorialReveal
extends RefCounted
## What the last room of the tutorial starts without and gains as its lessons come, GAME.md 9.4a:
## the pads and the Jackpots with the pads lesson, the Junction with the Junction's, the item pads
## and the crates with the fight's. Held back, a thing is not seen and not in play: not processed,
## and out of the physics world with it, which is what a paused body or area is; brought in, it
## grows out of the floor in a ring of light. The room is built without baking, so each of these
## is a node of its own to hold back.


## [param node] held back: unseen and not in play.
static func hold(node: Node3D) -> void:
	node.visible = false
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node is JackpotZone:
		(node as JackpotZone).deactivate()
	if node is SpawningPad:
		var pad := node as SpawningPad
		if pad.current != null and is_instance_valid(pad.current):
			pad.current.queue_free()
			pad.current = null


## [param node] brought in: in play, and grown out of the floor in a ring of light.
static func show(node: Node3D) -> void:
	node.visible = true
	node.process_mode = Node.PROCESS_MODE_INHERIT
	node.scale = Vector3.ONE * 0.05
	var grow := node.create_tween()
	grow.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	grow.tween_property(node, "scale", Vector3.ONE, 0.6)
	var at := node.global_position
	SpawnRing.spawn(node.get_parent(), Vector3(at.x, 0.0, at.z), Palette.NEON_CYAN)
