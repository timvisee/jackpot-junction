extends GdUnitTestSuite
## What the things inside the arena are made of, GAME.md 8.1. A room decides what its cover is
## built out of and what is left on top of its walls, and neither is allowed to change what the
## karts drive into: a box is the cube its collider is, and a wall is the block it always was
## with something small on top of it.

const MAPS: Array[String] = ["lucky_crossing", "vault", "crossfire"]
## How far outside the shape it is allowed to be. Nothing should be; this is float slack.
const SLACK := 0.002


## Unbaked: after the merge of 8.1 there is no wall left to look at, only the result.
func _arena(map: String) -> Arena:
	var arena: Arena = auto_free(Arena.new())
	arena.layout = load("res://data/maps/%s.tres" % map)
	arena.bake_scenery = false
	add_child(arena)
	return arena


## Every room builds its cover out of something rather than out of one painted cube: card packs
## in the card room, offcuts on the bench, sacks in the yard.
func test_every_room_builds_its_own_boxes() -> void:
	for map: String in MAPS:
		var arena := _arena(map)
		assert_int(arena.crates.size()).is_greater(0)
		for crate: Crate in arena.crates:
			var box := crate.get_node_or_null("Box")
			assert_object(box).override_failure_message("%s: undressed box" % map).is_not_null()
			assert_int(box.get_child_count()).is_greater(2)


## And builds it inside the cube the collider is. A sack hanging over the edge of its own footing
## is a box that is bumped into before it is reached.
func test_the_cover_is_the_shape_it_looks_like() -> void:
	for map: String in MAPS:
		var arena := _arena(map)
		for crate: Crate in arena.crates:
			var shape: CollisionShape3D = crate.get_child(0)
			var cube: BoxShape3D = shape.shape
			var room := AABB(
				-cube.size * 0.5 - Vector3.ONE * SLACK, cube.size + Vector3.ONE * SLACK * 2.0
			)
			for part: MeshInstance3D in crate.get_node("Box").get_children():
				var box := part.transform * part.mesh.get_aabb()
				var out := "%s: a piece of a box sticks out of it at %v" % [map, part.position]
				assert_bool(room.encloses(box)).override_failure_message(out).is_true()


## A wall is the block it always was. What the room adds to it -- the step on top, the odd thing
## left up there -- stays inside the footprint the collider has, so a kart never meets anything
## that was not part of the wall.
func test_a_wall_is_still_the_block_it_was() -> void:
	for map: String in MAPS:
		var arena := _arena(map)
		for body: Node in arena.get_node("Walls").get_children():
			var shape: CollisionShape3D = body.get_child(0)
			var cube: BoxShape3D = shape.shape
			var half := cube.size * 0.5
			for part: MeshInstance3D in body.get_node("Wall").get_children():
				var box := part.transform * part.mesh.get_aabb()
				var over := "%s: something on a wall hangs over the side of it" % map
				assert_float(box.position.x).override_failure_message(over).is_greater_equal(
					-half.x - SLACK
				)
				assert_float(box.end.x).override_failure_message(over).is_less_equal(half.x + SLACK)
				assert_float(box.position.z).override_failure_message(over).is_greater_equal(
					-half.z - SLACK
				)
				assert_float(box.end.z).override_failure_message(over).is_less_equal(half.z + SLACK)
				var under := "%s: a wall has something hanging below it" % map
				assert_float(box.position.y).override_failure_message(under).is_greater_equal(
					-half.y - SLACK
				)


## And the block and the step on it share no plane. Two surfaces at the same depth flicker
## against each other as the camera moves, which is what a strip laid into the top face of a wall
## does and why there is not one any more.
func test_the_block_and_its_step_share_no_plane() -> void:
	for map: String in MAPS:
		var arena := _arena(map)
		for body: Node in arena.get_node("Walls").get_children():
			var parts := body.get_node("Wall").get_children()
			var block: MeshInstance3D = parts[0]
			var step: MeshInstance3D = parts[1]
			var one := block.transform * block.mesh.get_aabb()
			var two := step.transform * step.mesh.get_aabb()
			var flat := "%s: the step on a wall lies in a face of the wall" % map
			for axis: int in 3:
				var low := absf(one.position[axis] - two.position[axis])
				var high := absf(one.end[axis] - two.end[axis])
				assert_float(low).override_failure_message(flat).is_greater(SLACK)
				assert_float(high).override_failure_message(flat).is_greater(SLACK)
