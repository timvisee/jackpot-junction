extends GdUnitTestSuite
## High Limit, the showdown's own room, GAME.md 8.1c and 9.7a, held to what every room is held to,
## see test_room_kit.gd and test_room_props.gd, whose maps all have the furniture the showdown's
## floor has none of: its walls are the blocks they were and its boxes the cubes, its salon is
## scenery out of the game's way, the pair stands past the far side where the opening looks, and
## all of it bakes into a handful of meshes, GAME.md 10.7.

const MAP := "res://data/maps/showdown.tres"
## How far outside the shape a part may be: float slack, nothing more.
const SLACK := 0.002
## How high over the floor a kart, a shot or a thrown crate can reach, and how tall something on
## the near apron may be, as test_room_props.gd has them.
const PLAY_HEIGHT := 12.0
const APRON_LIMIT := 3.0
## The most meshes each part of the room may bake into: the walls, the House's rail among them;
## a box; the things set down about the table; and the salon itself.
const WALL_MESHES := 8
const BOX_MESHES := 1
const PROP_MESHES := 3
const SHELL_MESHES := 10


func _arena(baked := false) -> Arena:
	var arena: Arena = auto_free(Arena.new())
	arena.layout = load(MAP)
	arena.bake_scenery = baked
	add_child(arena)
	return arena


## Every mesh under [param node], however deep it is hung.
func _meshes(node: Node, into: Array[MeshInstance3D] = []) -> Array[MeshInstance3D]:
	for child: Node in node.get_children():
		_meshes(child, into)
		var part := child as MeshInstance3D
		if part != null and part.mesh != null:
			into.append(part)
	return into


## Everything the room is dressed with round the table, the props and the salon they stand in.
func _parts(arena: Arena) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for holder: String in ["Props", "Shell"]:
		for part: Node in arena.get_node(holder).get_children():
			out.append(part as MeshInstance3D)
	return out


## The showdown plays in a room of its own, with a style and a sticker of its own: not After
## Hours, whose room it borrowed.
func test_the_showdown_has_a_room_of_its_own() -> void:
	var room := (load(MAP) as ArenaLayout).room
	assert_str(String(room.id)).is_equal("high_limit")
	assert_object(room.style).is_equal(HighLimitStyle)
	assert_object(room.emblem).is_not_null()
	assert_float(room.opening_toward.y).is_less(0.0)
	var vault: RoomLook = load("res://data/rooms/after_hours.tres")
	assert_bool(room.style == vault.style).is_false()
	assert_bool(room.emblem == vault.emblem).is_false()


## A wall is the block it was: the plinth, the piping, the leather and its rolled top all stay
## inside the collider's box, and nothing hangs below its foot. The House's rail round the table is
## the House's, the same in every room, and held to it in test_room_kit.gd.
func test_a_wall_is_still_the_block_it_was() -> void:
	var arena := _arena()
	var walls := arena.get_node("Walls")
	var inner := 0
	for i: int in arena.grid.walls.size():
		if arena.grid.is_border(arena.grid.walls[i]):
			continue
		inner += 1
		var body := walls.get_child(i)
		var cube: BoxShape3D = (body.get_child(0) as CollisionShape3D).shape
		var box := AABB(
			-cube.size * 0.5 - Vector3.ONE * SLACK, cube.size + Vector3.ONE * SLACK * 2.0
		)
		for part: MeshInstance3D in body.get_node("Wall").get_children():
			var shape := part.transform * part.mesh.get_aabb()
			var out := "a piece of a wall sticks out of it at %v" % shape.get_center()
			assert_bool(box.encloses(shape)).override_failure_message(out).is_true()
	# Six pieces of wall inside the House's rail, GAME.md 6.3, some of them in more than one block.
	assert_int(inner).is_greater_equal(6)


## A box is the carton the cube is, inside the cube, and bakes into one mesh: every part of it is
## the one plain paint.
func test_a_box_is_the_cube_it_looks_like() -> void:
	var arena := _arena()
	assert_int(arena.crates.size()).is_equal(44)
	for crate: Crate in arena.crates:
		var cube: BoxShape3D = (crate.get_child(0) as CollisionShape3D).shape
		var room := AABB(
			-cube.size * 0.5 - Vector3.ONE * SLACK, cube.size + Vector3.ONE * SLACK * 2.0
		)
		var parts := crate.get_node("Box").get_children()
		assert_int(parts.size()).is_greater(2)
		for part: MeshInstance3D in parts:
			var shape := part.transform * part.mesh.get_aabb()
			assert_bool(room.encloses(shape)).is_true()
	for crate: Crate in _arena(true).crates:
		assert_int(_meshes(crate).size()).is_less_equal(BOX_MESHES)


## The salon is scenery and out of the game's way: meshes and nothing else, none of it on the floor
## or in the air over it, and nothing standing up on the near side the camera looks across.
func test_the_salon_keeps_out_of_the_game() -> void:
	var arena := _arena()
	var half := arena.world_size() * 0.5
	var play := AABB(
		Vector3(-half.x, 0.0, -half.y), Vector3(half.x * 2.0, PLAY_HEIGHT, half.y * 2.0)
	)
	var reach := half.x + RoomProps.FAR
	var parts := _parts(arena)
	assert_int(parts.size()).is_greater(40)
	for part: MeshInstance3D in parts:
		assert_object(part).is_not_null()
		assert_int(part.get_child_count()).is_equal(0)
		var box := part.transform * part.mesh.get_aabb()
		var where := "something at %v is in the arena" % box.get_center()
		assert_bool(box.intersects(play)).override_failure_message(where).is_false()
		if box.position.z >= half.y and absf(box.get_center().x) <= reach:
			var tall := "%.1fm of something stands in front of the table" % box.end.y
			assert_float(box.end.y).override_failure_message(tall).is_less(APRON_LIMIT)


## Nothing is put down in anything else, and every prop keeps to the patch it asked for.
func test_no_prop_stands_in_another() -> void:
	var arena := _arena()
	var props: RoomProps = arena.get_node("Props")
	assert_int(props.laid_out.size()).is_equal(5)
	for i: int in props.laid_out.size():
		var one: Dictionary = props.laid_out[i]
		for j: int in range(i + 1, props.laid_out.size()):
			var two: Dictionary = props.laid_out[j]
			var where := "%s stands in %s" % [one["kind"], two["kind"]]
			(
				assert_bool(one["box"].intersects(two["box"]))
				. override_failure_message(where)
				. is_false()
			)
		for k: int in range(int(one["from"]), int(one["to"])):
			var part := props.get_child(k) as MeshInstance3D
			var box := part.get_aabb()
			for corner: int in 8:
				var at: Vector3 = part.transform * box.get_endpoint(corner)
				var past := "%s reaches past its patch" % one["kind"]
				var inside: bool = (one["box"] as Rect2).has_point(Vector2(at.x, at.z))
				assert_bool(inside).override_failure_message(past).is_true()


## The room's showpiece stands past the table's far side, behind the crowd and in the middle,
## where the opening shot of every match looks, GAME.md 8.2: the two aces, printed.
func test_the_pair_stands_past_the_far_side() -> void:
	var arena := _arena()
	var half := arena.world_size() * 0.5
	var faces: Array[MeshInstance3D] = []
	for part: MeshInstance3D in _parts(arena):
		var skin := part.material_override as StandardMaterial3D
		if skin != null and skin.albedo_texture in Surfaces.CARD_FACES:
			faces.append(part)
	assert_int(faces.size()).is_equal(2)
	for face: MeshInstance3D in faces:
		var box := face.transform * face.mesh.get_aabb()
		assert_float(box.get_center().z).is_less(-(half.y + RoomProps.NEAR))
		assert_float(absf(box.get_center().x)).is_less(3.0)
		assert_float(box.position.y).is_greater(RoomBuild.TOP)


## All of it bakes into a handful of meshes, GAME.md 10.7: the walls, the things about the table
## and the salon round them each into a few, whatever they are built of.
func test_the_room_bakes_into_a_handful_of_meshes() -> void:
	var arena := _arena(true)
	assert_int(_meshes(arena.get_node("Walls")).size()).is_less_equal(WALL_MESHES)
	assert_int(_meshes(arena.get_node("Props")).size()).is_less_equal(PROP_MESHES)
	assert_int(_meshes(arena.get_node("Shell")).size()).is_less_equal(SHELL_MESHES)
