class_name LooseThings
## The loose things lying on a room's floor, GAME.md 6.2: the bombs dropped, 7.1, the mines lying
## in wait, 5.3, and the chips a death dropped, 3.2. A magnet that is on drags them in, as it pulls
## a kart, each a node in [constant FloorCarry.GROUP] that says how fast it moves one where it lies,
## see [method Magnet.drag_at]; stopped by anything solid in the way, see [method slid].
##
## What the room does to them is the host's alone, as everything else a match's floor holds is,
## GAME.md 10.3: where each one is goes to the clients in the snapshot, see [MatchSnapshot].


## How fast everything that moves loose things moves [param loose] where it lies, flat.
static func pull_at(loose: Node3D) -> Vector3:
	var pull := Vector3.ZERO
	for node: Node in FrameGroups.of(loose.get_tree(), FloorCarry.GROUP):
		if is_instance_valid(node) and node.has_method(&"drag_at"):
			pull += node.call(&"drag_at", loose) as Vector3
	pull.y = 0.0
	return pull


## Where [param loose], a ball [param radius] round lying on the floor, ends up moved by
## [param motion]: as far along it as it goes before anything solid stops it, a wall, a crate, a
## magnet or a bumper. Its height is kept.
static func slid(loose: Node3D, radius: float, motion: Vector3) -> Vector3:
	var ball := SphereShape3D.new()
	ball.radius = radius
	var probe := PhysicsShapeQueryParameters3D.new()
	probe.shape = ball
	# Lifted a little off the floor, so the floor itself never stops it.
	var at := loose.global_position
	probe.transform = Transform3D(Basis(), Vector3(at.x, radius + 0.05, at.z))
	probe.motion = Vector3(motion.x, 0.0, motion.z)
	probe.collision_mask = Layers.WORLD
	var fit := loose.get_world_3d().direct_space_state.cast_motion(probe)
	return at + probe.motion * fit[0]


## The match [param node] is part of, or null.
static func match_of(node: Node) -> Match:
	var at := node.get_parent()
	while at != null:
		var found := at as Match
		if found != null:
			return found
		at = at.get_parent()
	return null


## Whether it is this machine's word what happens to [param node]: the host's, or a game played
## here alone, rather than a client's, which is told.
static func hosted(node: Node) -> bool:
	var match_node := match_of(node)
	return match_node == null or not match_node.puppet
