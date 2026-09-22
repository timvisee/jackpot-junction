extends GdUnitTestSuite
## Baking the scenery, GAME.md 8.1: everything static in a room is merged into one mesh per
## material as the map loads. What has to hold is that nothing is lost and nothing that still
## has to move or hide on its own is taken.

const MAPS: Array[String] = ["lucky_crossing", "vault", "crossfire"]


func _arena(map: String, baked: bool) -> Arena:
	var arena: Arena = auto_free(Arena.new())
	arena.layout = load("res://data/maps/%s.tres" % map)
	arena.bake_scenery = baked
	add_child(arena)
	return arena


## Counts the meshes and the triangles under [param node], whatever they are hung on.
func _meshes(node: Node, into: Array[MeshInstance3D] = []) -> Array[MeshInstance3D]:
	for child: Node in node.get_children():
		_meshes(child, into)
		var part := child as MeshInstance3D
		if part != null and part.mesh != null:
			into.append(part)
	return into


func _triangles(parts: Array[MeshInstance3D]) -> int:
	var total := 0
	for part: MeshInstance3D in parts:
		for surface: int in part.mesh.get_surface_count():
			total += part.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX].size()
	return total


## The room ends up in far fewer meshes than it was built out of, and the same geometry is in
## them: a merge that drops a hundred chips is not a merge.
func test_the_scenery_ends_up_in_far_fewer_meshes() -> void:
	for map: String in MAPS:
		var loose := _meshes(_arena(map, false).get_node("Props"))
		var baked := _meshes(_arena(map, true).get_node("Props"))
		assert_int(baked.size()).is_less(loose.size() / 4)
		assert_int(_triangles(baked)).is_equal(_triangles(loose))


## A wall keeps its collider whatever happens to the meshes, because that is the part the karts
## are driving into.
func test_the_walls_keep_their_colliders() -> void:
	for map: String in MAPS:
		var arena := _arena(map, true)
		for body: Node in arena.get_node("Walls").get_children():
			var shape := body as StaticBody3D
			if shape == null:
				continue
			assert_object(shape.get_child(0) as CollisionShape3D).is_not_null()


## A breakable box is baked on its own rather than into the room. Baked into the room it could
## not go off the floor when it was shot.
func test_a_box_is_baked_on_its_own() -> void:
	for map: String in MAPS:
		var arena := _arena(map, true)
		assert_int(arena.crates.size()).is_greater(0)
		for crate: Crate in arena.crates:
			var parts := _meshes(crate)
			assert_int(parts.size()).is_greater(0)
			assert_int(parts.size()).is_less(5)
			for part: MeshInstance3D in parts:
				assert_bool(crate.is_ancestor_of(part)).is_true()
