class_name LooseThings
## The loose things lying on a room's floor, GAME.md 6.2: the bombs dropped, 7.1, the mines lying
## in wait, 5.3, and the chips a death dropped, 3.2. A magnet that is on drags them in and a belt
## carries them along, as each does a kart, each a node in [constant FloorCarry.GROUP] that says how
## fast it moves one where it lies, see [method Magnet.drag_at]; stopped by anything solid in the
## way, see [method slid]; and down a hole once over one, see [method over_pit]: a bomb sinks
## without going off, a mine is gone and a chip drops out of sight as one dropped over a hole does.
##
## A bomb or a mine is set off by what the room has that strikes or runs into it, see
## [method set_off_where]: a sewing needle stabbing it, a wind-up toy running into it.
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


## Whether [param point] is over one of the holes of the room [param node] lies in, so it goes
## down there, as a pickup dropped over one does, see [method Arena.is_over_pit].
static func over_pit(node: Node, point: Vector3) -> bool:
	var match_node := match_of(node)
	return match_node != null and match_node.arena != null and match_node.arena.is_over_pit(point)


## Whether it is this machine's word what happens to [param node]: the host's, or a game played
## here alone, rather than a client's, which is told.
static func hosted(node: Node) -> bool:
	var match_node := match_of(node)
	return match_node == null or not match_node.puppet


## The bombs and the mines lying in wait of [param match_node], which a needle and the like set
## off: not a client's copies, nor one on its way down a hole.
static func explosives(match_node: Match) -> Array[Node3D]:
	var found: Array[Node3D] = []
	for node: Node in MatchSnapshot.own_nodes(match_node, &"bombs"):
		var bomb := node as Bomb
		if bomb != null and bomb.alive and not bomb.falling and not bomb.puppet:
			found.append(bomb)
	for mine: Bullet in match_node.bullets.bullets:
		if (
			is_instance_valid(mine)
			and mine.kind == &"mine"
			and mine._at_rest
			and not mine.is_dead()
		):
			found.append(mine)
	return found


## Sets off every bomb and mine of [param match_node] that [param meets], given where it lies,
## says is met, see [method set_off].
static func set_off_where(match_node: Match, meets: Callable) -> void:
	for thing: Node3D in explosives(match_node):
		if meets.call(thing.global_position):
			set_off(thing)


## Sets off every bomb and mine of [param match_node] within [param reach] of [param at], flat.
static func set_off_near(match_node: Match, at: Vector3, reach: float) -> void:
	var near := func(point: Vector3) -> bool:
		return Vector2(point.x - at.x, point.z - at.z).length() <= reach
	set_off_where(match_node, near)


## Sets [param thing] off, a bomb or a mine of [method explosives]: the bomb goes up and the mine
## bursts, each as when a kart sets it off, its owner's kill.
static func set_off(thing: Node3D) -> void:
	var bomb := thing as Bomb
	if bomb != null:
		bomb.explode()
		return
	var mine := thing as Bullet
	if mine != null and not mine.is_dead():
		mine._burst()
		mine.destroy()
