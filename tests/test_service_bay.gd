extends GdUnitTestSuite
## The Garage's room, GAME.md 8.1 and 9.4: the House's service bay, see [GarageStyle] and
## [ServiceBay]. Its walls are tool cabinets, its boxes tool chests and racks of bins, its pits
## inspection pits and its Junction a turntable, and none of it changes what the karts drive into;
## the bay round the table is scenery, kept off the floor and out of the air over it.

## The maps in the Garage's room: the Garage, the Garage with the Showroom open, and the waiting
## room.
const MAPS: Array[String] = ["garage", "garage_showroom", "waiting_room"]
## How far outside the shape it is allowed to be. Nothing should be; this is float slack.
const SLACK := 0.002
## How high over the floor a kart, a shot or a thrown crate can reach.
const PLAY_HEIGHT := 12.0
## How tall something on the near side may be before it is in front of the camera.
const APRON_LIMIT := 3.0


func _arena(map: String) -> Arena:
	var arena: Arena = auto_free(Arena.new())
	arena.layout = load("res://data/maps/%s.tres" % map)
	arena.bake_scenery = false
	add_child(arena)
	return arena


func _meshes(node: Node, into: Array[MeshInstance3D] = []) -> Array[MeshInstance3D]:
	for child: Node in node.get_children():
		_meshes(child, into)
		var part := child as MeshInstance3D
		if part != null and part.mesh != null:
			into.append(part)
	return into


func test_the_garage_is_the_service_bay() -> void:
	for map: String in MAPS:
		var arena := _arena(map)
		assert_object(arena.kit.style).is_instanceof(GarageStyle)
		var floor_skin := arena.surfaces.floor_top()
		assert_object(floor_skin.albedo_texture).is_same(GarageStyle.RUBBER_ALBEDO)
		assert_object(arena.room.emblem).is_not_null()


## A wall is a run of cabinets inside the block it always was, and a box a chest or a rack inside
## its cube.
func test_cabinets_and_chests_keep_to_their_blocks() -> void:
	var arena := _arena("garage_showroom")
	var inner := 0
	for body: Node in arena.get_node("Walls").get_children():
		# The House's rail round the edge is the House's, GAME.md 8.1c, and not the bay's.
		if arena.grid.is_border(arena.grid.walls[body.get_index()]):
			continue
		inner += 1
		var cube: BoxShape3D = (body.get_child(0) as CollisionShape3D).shape
		var half := cube.size * 0.5
		var room := AABB(-half - Vector3.ONE * SLACK, cube.size + Vector3.ONE * SLACK * 2.0)
		for part: MeshInstance3D in body.get_node("Wall").get_children():
			var box := part.transform * part.mesh.get_aabb()
			(
				assert_bool(room.encloses(box))
				. override_failure_message("a cabinet sticks out")
				. is_true()
			)
	assert_int(inner).is_greater(0)
	assert_int(arena.crates.size()).is_greater(0)
	for crate: Crate in arena.crates:
		var cube: BoxShape3D = (crate.get_child(0) as CollisionShape3D).shape
		var room := AABB(
			-cube.size * 0.5 - Vector3.ONE * SLACK, cube.size + Vector3.ONE * SLACK * 2
		)
		var box_node := crate.get_node("Box")
		assert_int(box_node.get_child_count()).is_greater(4)
		for part: MeshInstance3D in box_node.get_children():
			var box := part.transform * part.mesh.get_aabb()
			assert_bool(room.encloses(box)).override_failure_message("a box sticks out").is_true()


## An inspection pit stands nothing above the floor, and the turntable is flat paint on the pad.
func test_the_pit_and_the_turntable_lie_low() -> void:
	var arena := _arena("garage")
	assert_int(arena.pits.size()).is_greater(0)
	for pit: Pit in arena.pits:
		var parts := _meshes(pit)
		assert_int(parts.size()).is_greater(10)
		for part: MeshInstance3D in parts:
			var box := part.transform * part.mesh.get_aabb()
			assert_float(box.end.y).is_less_equal(0.02)
	for part: MeshInstance3D in _meshes(arena.junction):
		assert_float((part.transform * part.get_aabb()).end.y).is_less(0.5)


## The bay round the table is meshes and nothing else, stands nowhere on the floor or over it, and
## keeps the near side low.
func test_the_bay_is_scenery_off_the_floor() -> void:
	for map: String in MAPS:
		var arena := _arena(map)
		var half := arena.world_size() * 0.5
		var play := AABB(
			Vector3(-half.x, 0.0, -half.y), Vector3(half.x * 2.0, PLAY_HEIGHT, half.y * 2.0)
		)
		var reach := half.x + RoomProps.FAR
		for holder: String in ["Props", "Shell"]:
			var root := arena.get_node(holder)
			for part: MeshInstance3D in _meshes(root):
				assert_int(part.get_child_count()).is_equal(0)
				var box := _placed(part, root) * part.mesh.get_aabb()
				var where := "%s: something at %v is in the arena" % [map, box.get_center()]
				assert_bool(box.intersects(play)).override_failure_message(where).is_false()
				if box.position.z >= half.y and absf(box.get_center().x) <= reach:
					assert_float(box.end.y).is_less(APRON_LIMIT)


## Where [param part] stands in [param root]'s own space.
func _placed(part: Node3D, root: Node) -> Transform3D:
	var out := part.transform
	var parent := part.get_parent() as Node3D
	while parent != null and parent != root:
		out = parent.transform * out
		parent = parent.get_parent() as Node3D
	return out


## What the bay puts down by hand stands apart and inside the patch it asked for.
func test_nothing_in_the_bay_stands_in_anything_else() -> void:
	for map: String in MAPS:
		var arena := _arena(map)
		var props: RoomProps = arena.get_node("Props")
		assert_int(props.laid_out.size()).is_greater(4)
		for i: int in props.laid_out.size():
			var one: Dictionary = props.laid_out[i]
			for j: int in range(i + 1, props.laid_out.size()):
				var two: Dictionary = props.laid_out[j]
				var why := "%s: %s stands in %s" % [map, one["kind"], two["kind"]]
				(
					assert_bool(one["box"].intersects(two["box"]))
					. override_failure_message(why)
					. is_false()
				)
			for k: int in range(int(one["from"]), int(one["to"])):
				var part := props.get_child(k) as MeshInstance3D
				for corner: int in 8:
					var at: Vector3 = part.transform * part.get_aabb().get_endpoint(corner)
					var why := "%s: %s reaches past its patch" % [map, one["kind"]]
					(
						assert_bool(one["box"].has_point(Vector2(at.x, at.z)))
						. override_failure_message(why)
						. is_true()
					)
