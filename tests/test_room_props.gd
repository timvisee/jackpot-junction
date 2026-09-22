extends GdUnitTestSuite
## What a room has in it besides the table, GAME.md 8.1. Each map is dressed by the room its
## layout names, and none of the dressing is allowed anywhere near the game: not on the floor the
## karts drive on, not in the air over it, and not standing up on the side the camera looks from.

const MAPS: Array[String] = ["lucky_crossing", "vault", "crossfire"]
## How high over the floor a kart, a shot or a thrown crate can reach. Nothing the rooms put out
## is allowed inside this.
const PLAY_HEIGHT := 12.0
## How tall something on the near apron may be before it is in front of the camera.
const APRON_LIMIT := 3.0


## Unbaked: after the merge of 8.1 there is no prop left to look at, only the result.
func _arena(map: String) -> Arena:
	var arena: Arena = auto_free(Arena.new())
	arena.layout = load("res://data/maps/%s.tres" % map)
	arena.bake_scenery = false
	add_child(arena)
	return arena


## The box every prop has to stay out of, in the arena's own space.
func _play_box(arena: Arena) -> AABB:
	var half := arena.world_size() * 0.5
	return AABB(Vector3(-half.x, 0.0, -half.y), Vector3(half.x * 2.0, PLAY_HEIGHT, half.y * 2.0))


## Everything a room is dressed with: the clutter lying about in it and the shell it stands in,
## which are two nodes now but one set of rules.
func _parts(arena: Arena) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for holder: String in ["Props", "Shell"]:
		for part: Node in arena.get_node(holder).get_children():
			out.append(part as MeshInstance3D)
	return out


## Every map is dressed, and dressed with enough to look like somewhere rather than like a table
## with three boxes next to it.
func test_every_room_is_dressed() -> void:
	for map: String in MAPS:
		var arena := _arena(map)
		var props := arena.get_node_or_null("Props")
		var shell := arena.get_node_or_null("Shell")
		assert_object(props).override_failure_message("%s has no props" % map).is_not_null()
		assert_object(shell).override_failure_message("%s has no shell" % map).is_not_null()
		assert_int(props.get_child_count()).is_greater(40)
		assert_int(shell.get_child_count()).is_greater(20)


## None of it collides and none of it moves: a room is scenery, so it is meshes and nothing else.
## A shape out here would be something a kart could be stopped by outside the arena.
func test_the_dressing_is_scenery_and_nothing_else() -> void:
	for map: String in MAPS:
		var arena := _arena(map)
		for part: MeshInstance3D in _parts(arena):
			assert_object(part).override_failure_message("%s: not a mesh" % map).is_not_null()
			assert_int(part.get_child_count()).is_equal(0)


## Nothing stands where the game is played. The floor, the air over it and the walls round it
## belong to the karts; the room's own things are outside that box or under it.
func test_nothing_is_put_down_on_the_floor() -> void:
	for map: String in MAPS:
		var arena := _arena(map)
		var play := _play_box(arena)
		for part: MeshInstance3D in _parts(arena):
			var box := part.transform * part.mesh.get_aabb()
			var where := "%s: something at %v is in the arena" % [map, part.position]
			assert_bool(box.intersects(play)).override_failure_message(where).is_false()


## The near side is kept flat. The camera of 8.2 looks down the table from there, so a tool chest
## on that side is a tool chest in front of the game.
func test_the_near_side_of_the_room_is_kept_low() -> void:
	for map: String in MAPS:
		var arena := _arena(map)
		var half := arena.world_size() * 0.5
		var reach := half.x + RoomProps.FAR
		for part: MeshInstance3D in _parts(arena):
			var box := part.transform * part.mesh.get_aabb()
			if box.position.z < half.y or absf(box.get_center().x) > reach:
				continue
			var tall := "%s: %.1fm of something stands in front of the table" % [map, box.end.y]
			assert_float(box.end.y).override_failure_message(tall).is_less(APRON_LIMIT)


## The dice come to rest apart. They were dropped at their own random offsets round the place
## they were dealt, which every so often put both of them in the same square foot of baize.
func test_no_two_dice_land_in_each_other() -> void:
	var arena := _arena("vault")
	var dice: Array[Vector3] = []
	var size := 0.0
	for part: MeshInstance3D in _parts(arena):
		var cube := part.mesh as BoxMesh
		# The dice are the only cubes in the room, and the only boxes small enough to be one.
		if cube == null or cube.size.x != cube.size.y or cube.size.y != cube.size.z:
			continue
		if cube.size.x < 0.5 or cube.size.x > 2.0:
			continue
		dice.append(part.position)
		# All one size, which is how the test knows it is looking at dice and not at something
		# else the room happens to have built out of a cube.
		if size > 0.0:
			assert_float(cube.size.x).is_equal_approx(size, 0.001)
		size = cube.size.x
	assert_int(dice.size()).is_greater(3)
	# However a cube is turned about its upright it reaches half its own diagonal, so two of them
	# any closer than a whole diagonal are two dice standing in each other.
	var closest := size * sqrt(2.0)
	for i: int in dice.size():
		for j: int in range(i + 1, dice.size()):
			var gap := Vector2(dice[i].x - dice[j].x, dice[i].z - dice[j].z).length()
			(
				assert_float(gap)
				. override_failure_message("two dice %.2f m apart" % gap)
				. is_greater_equal(closest)
			)


## Nothing is put down inside anything else, GAME.md 8.1. Every prop asks for the patch of table
## its own parts cover, turned the way it is turned, and no two of those patches touch. Props
## standing in each other is the one thing every room here has been wrong about more than once,
## so it is checked rather than looked at.
func test_no_prop_is_put_down_in_another() -> void:
	for map: String in MAPS:
		var arena := _arena(map)
		var props: RoomProps = arena.get_node("Props")
		assert_int(props.laid_out.size()).is_greater(10)
		for i: int in props.laid_out.size():
			for j: int in range(i + 1, props.laid_out.size()):
				var one: Dictionary = props.laid_out[i]
				var two: Dictionary = props.laid_out[j]
				(
					assert_bool(one["box"].intersects(two["box"]))
					. override_failure_message(
						"%s: %s stands in %s" % [map, one["kind"], two["kind"]]
					)
					. is_false()
				)


## And every prop keeps to the patch it asked for. A patch smaller than the thing measured for it
## would let two props miss each other on paper and stand in each other on the table, which is
## what the check above would then be worth.
func test_every_prop_keeps_to_its_own_patch() -> void:
	for map: String in MAPS:
		var arena := _arena(map)
		var props: RoomProps = arena.get_node("Props")
		for prop: Dictionary in props.laid_out:
			var claim: Rect2 = prop["box"]
			for i: int in range(int(prop["from"]), int(prop["to"])):
				var part := props.get_child(i) as MeshInstance3D
				var box := part.get_aabb()
				for corner: int in 8:
					var at: Vector3 = part.transform * box.get_endpoint(corner)
					(
						assert_bool(claim.has_point(Vector2(at.x, at.z)))
						. override_failure_message(
							"%s: %s reaches past its patch" % [map, prop["kind"]]
						)
						. is_true()
					)
