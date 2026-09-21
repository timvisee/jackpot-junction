extends GdUnitTestSuite
## What the things inside the arena are made of, GAME.md 8.1. A room decides what its cover is
## built out of and what is left on top of its walls, and neither is allowed to change what the
## karts drive into: a box is the cube its collider is, and a wall is the block it always was
## with something small on top of it.

const MAPS: Array[String] = ["lucky_crossing", "vault", "crossfire"]
## How far outside the shape it is allowed to be. Nothing should be; this is float slack.
const SLACK := 0.002


func _arena(map: String) -> Arena:
	var arena: Arena = auto_free(Arena.new())
	arena.layout = load("res://data/maps/%s.tres" % map)
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


## What a room leaves on a wall stays on top of it. Anything hanging over the side is in the way
## of a kart that never touched it.
func test_what_is_on_a_wall_stays_on_top_of_it() -> void:
	for map: String in MAPS:
		var arena := _arena(map)
		for body: Node in arena.get_node("Walls").get_children():
			var shape: CollisionShape3D = body.get_child(0)
			var cube: BoxShape3D = shape.shape
			var half := cube.size * 0.5
			for part: MeshInstance3D in body.get_node("Trim").get_children():
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
				var low := "%s: something on a wall hangs down inside it" % map
				var floor_of_it := half.y - cube.size.y * RoomKit.CAP - SLACK
				assert_float(box.position.y).override_failure_message(low).is_greater_equal(
					floor_of_it
				)
