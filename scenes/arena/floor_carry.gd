class_name FloorCarry
## What the room does to a kart besides its own driving, GAME.md 6.2: a conveyor belt carrying it
## along, a magnet pulling it in. Each is a node in [constant GROUP] that says how fast it moves a
## kart where it stands, see [method Conveyor.carry_at], all of them added up and the kart slid that
## far after it has driven, against the walls as driving is.
##
## Worked out the same way by the host and by a client driving its own kart, and again on every
## tick a client replays, see [method KartPrediction.step]: what moves a kart is where it is and the
## match's clock, which every machine has, so nothing of it goes on the wire.

const GROUP := &"carriers"


## Slides [param kart] by everything carrying it for [param delta] seconds. A kart rolling out the
## end of a match, falling or dead is carried by nothing.
static func step(kart: Kart, delta: float) -> void:
	if not kart.alive or kart.falling or kart.coasting or not kart.is_inside_tree():
		return
	var carry := Vector3.ZERO
	for node: Node in FrameGroups.of(kart.get_tree(), GROUP):
		if is_instance_valid(node):
			carry += node.call("carry_at", kart) as Vector3
	carry.y = 0.0
	if carry.length_squared() < 0.0001:
		return
	kart.move_and_collide(carry * delta)
	kart.position.y = 0.0
