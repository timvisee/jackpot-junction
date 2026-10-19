extends GdUnitTestSuite
## The driving school's room, GAME.md 9.4a: the Department's road-safety mat, see [SchoolStyle]
## and [RoadMat]. Its kerbs are the walls they were, its crates the cubes, its roadworks under the
## floor and its paint flat on it; and what stands round the mat stands off it.

const MAP := "tutorial"
## How far outside the shape it is allowed to be. Nothing should be; this is float slack.
const SLACK := 0.002
## How high paint may lie over the mat, and how high over the floor a kart can reach.
const PAINT_HIGH := 0.02
const PLAY_HEIGHT := 12.0


func _arena(map := MAP) -> Arena:
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


## Where [param part] stands in [param root]'s own space.
func _placed(part: Node3D, root: Node) -> Transform3D:
	var out := part.transform
	var parent := part.get_parent() as Node3D
	while parent != null and parent != root:
		out = parent.transform * out
		parent = parent.get_parent() as Node3D
	return out


func test_the_school_is_the_departments_mat() -> void:
	var arena := _arena()
	assert_object(arena.kit.style).is_instanceof(SchoolStyle)
	assert_object(arena.surfaces.floor_top().albedo_texture).is_same(Surfaces.FELT_ALBEDO)
	assert_object(arena.room.emblem).is_not_null()
	assert_object(arena.get_node_or_null("Roadside")).is_not_null()
	assert_object(arena.get_node_or_null("RoadPaint")).is_not_null()


## A kerb is the block its wall was, and a crate the cube its box was. The open lot of 9.4a has no
## wall inside its border, so a kerb is only checked where a lot is given one.
func test_kerbs_and_crates_keep_to_their_blocks() -> void:
	var arena := _arena()
	for body: Node in arena.get_node("Walls").get_children():
		if arena.grid.is_border(arena.grid.walls[body.get_index()]):
			continue
		var cube: BoxShape3D = (body.get_child(0) as CollisionShape3D).shape
		var room := AABB(
			-cube.size * 0.5 - Vector3.ONE * SLACK, cube.size + Vector3.ONE * SLACK * 2
		)
		for part: MeshInstance3D in body.get_node("Wall").get_children():
			var box := part.transform * part.mesh.get_aabb()
			assert_bool(room.encloses(box)).override_failure_message("a kerb sticks out").is_true()
	assert_int(arena.crates.size()).is_greater(0)
	for crate: Crate in arena.crates:
		var cube: BoxShape3D = (crate.get_child(0) as CollisionShape3D).shape
		var room := AABB(
			-cube.size * 0.5 - Vector3.ONE * SLACK, cube.size + Vector3.ONE * SLACK * 2
		)
		for part: MeshInstance3D in crate.get_node("Box").get_children():
			var box := part.transform * part.mesh.get_aabb()
			assert_bool(room.encloses(box)).override_failure_message("a crate sticks out").is_true()


## The roadworks are under the floor, the paint round them flat on it, and the roundabout flat
## paint on its pad.
func test_the_roadworks_and_the_roundabout_lie_low() -> void:
	var arena := _arena()
	assert_int(arena.pits.size()).is_greater(0)
	for pit: Pit in arena.pits:
		for part: MeshInstance3D in _meshes(pit):
			var box := _placed(part, pit) * part.mesh.get_aabb()
			assert_float(box.end.y).is_less_equal(PAINT_HIGH)
	assert_object(arena.junction).is_not_null()
	for part: MeshInstance3D in _meshes(arena.junction):
		assert_float((part.transform * part.get_aabb()).end.y).is_less(0.5)


## The roads are paint: flat on the mat and round it, one mesh for each ink.
func test_the_roads_are_flat_paint() -> void:
	var arena := _arena()
	var paints := 0
	for child: Node in arena.get_children():
		if not String(child.name).begins_with("RoadPaint"):
			continue
		paints += 1
		var box := (child as MeshInstance3D).get_aabb()
		assert_float(box.end.y).is_less_equal(PAINT_HIGH)
		assert_float(box.position.y).is_greater(RoomBuild.TOP)
	assert_int(paints).is_between(1, 3)


## What stands round the mat is scenery, baked into a few meshes, and nowhere on the floor the
## karts drive on or over it. Baked, a mesh runs all round the mat, so it is its every corner that
## is looked at rather than the box round the lot.
func test_the_roadside_stands_off_the_mat() -> void:
	var arena := _arena()
	var half := arena.world_size() * 0.5
	var mat := Rect2(-half, half * 2.0)
	var roadside := arena.get_node("Roadside")
	var drawn := _meshes(roadside)
	assert_int(drawn.size()).is_between(1, 12)
	for holder: Node in [roadside, arena.get_node("Shell"), arena.get_node("Props")]:
		for part: MeshInstance3D in _meshes(holder):
			var placed := _placed(part, holder)
			for surface: int in part.mesh.get_surface_count():
				var points: PackedVector3Array = part.mesh.surface_get_arrays(surface)[
					Mesh.ARRAY_VERTEX
				]
				for point: Vector3 in points:
					var at := placed * point
					if at.y <= 0.0:
						continue
					var where := "%s reaches onto the mat at %v" % [part.name, at]
					(
						assert_bool(mat.grow(-SLACK).has_point(Vector2(at.x, at.z)))
						. override_failure_message(where)
						. is_false()
					)


## The open lot is printed as the Department's traffic garden under the House's layout, see
## [LotPrint], and a table with walls inside its border is not.
func test_the_lot_is_printed_as_a_traffic_garden() -> void:
	var arena := _arena()
	assert_bool(LotPrint.fits(arena.grid)).is_true()
	assert_object(arena.kit.style).is_instanceof(SchoolStyle)
	assert_bool(LotPrint.fits(_arena("lucky_crossing").grid)).is_false()
