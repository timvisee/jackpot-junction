class_name Bake
extends RefCounted
## Bakes the scenery of a room into as few meshes as it will go, GAME.md 8.1.
##
## Everything a room is dressed with is built out of boxes and cylinders, one node each, and one
## node is one thing to draw: a card room was asking for fourteen hundred of them a frame, most
## of them a poker chip or a pack of cards the size of a hand. None of it moves, none of it is
## ever hidden by itself, and all of it wears a material out of the room's own small set, so it
## can be merged -- one mesh per material, built in the room's own space, with the nodes it came
## from freed behind it.
##
## This is what baking means here. Godot's lightmapper is an editor tool and its
## [code]LightmapGI.bake[/code] is not in the scripting API at all, so the light cannot be baked
## from a running game however long it is given. The geometry can, and the geometry is where the
## frames were.

## How many meshes a group has to have before merging it is worth the copy.
const WORTH_IT := 2


## Merges everything static under [param root] and returns how many meshes are left. The nodes
## are freed as they are taken, so nothing that called this may hold on to what it built.
static func merge(root: Node3D) -> int:
	var tools: Dictionary[String, SurfaceTool] = {}
	var counts: Dictionary[String, int] = {}
	var skins: Dictionary[String, Material] = {}
	var shadows: Dictionary[String, int] = {}
	var taken: Array[MeshInstance3D] = []
	_gather(root, root, tools, counts, skins, shadows, taken)
	var made := 0
	for key: String in tools:
		if counts[key] < WORTH_IT:
			continue
		var baked := MeshInstance3D.new()
		baked.name = "Baked%d" % made
		baked.mesh = tools[key].commit()
		baked.material_override = skins[key]
		baked.cast_shadow = shadows[key] as GeometryInstance3D.ShadowCastingSetting
		root.add_child(baked)
		made += 1
	for part: MeshInstance3D in taken:
		var group := _key(part)
		if counts[group] < WORTH_IT:
			continue
		part.get_parent().remove_child(part)
		# Freed on the spot rather than queued. Between coming out of the tree and a queued free
		# being run, a mesh is a node with no parent, which is what an orphan is; a room that was
		# still merging when its test finished counted every one of them, and on a slow machine
		# that was two dozen. Nothing holds these -- the doc above says as much -- so there is
		# nothing to wait for.
		part.free()
	return made


## One mesh out of [param pieces] that all wear one material: each piece a [Mesh] and the
## [Transform3D] it sits at. For a thing built out of a few primitives that is drawn many times
## over, a chip or a box, where [method merge] is for a room built once: the pieces are merged
## as the thing is designed, and every copy of it draws the one mesh.
static func joined(pieces: Array[Array]) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for piece: Array in pieces:
		tool.append_from(piece[0] as Mesh, 0, piece[1] as Transform3D)
	return tool.commit()


## One mesh out of [param pieces] in several colors, each piece a [Mesh], the [Transform3D] it
## sits at and the [Color] it is: the color goes on the vertices, so a material that takes its
## albedo from them draws the lot in one go, GAME.md 10.7. The colors are given as they are
## written, in sRGB, and stored linear, the way a material's own albedo is.
static func tinted(pieces: Array[Array]) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for piece: Array in pieces:
		var arrays: Array = (piece[0] as Mesh).surface_get_arrays(0)
		var at: Transform3D = piece[1]
		var color := (piece[2] as Color).srgb_to_linear()
		var base := vertices.size()
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var facing: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		for i: int in points.size():
			vertices.append(at * points[i])
			normals.append(at.basis * facing[i])
			colors.append(color)
		for index: int in arrays[Mesh.ARRAY_INDEX] as PackedInt32Array:
			indices.append(base + index)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Walks [param node] and its children, adding every mesh it finds to the group its material and
## its shadow setting put it in.
static func _gather(
	root: Node3D,
	node: Node3D,
	tools: Dictionary[String, SurfaceTool],
	counts: Dictionary[String, int],
	skins: Dictionary[String, Material],
	shadows: Dictionary[String, int],
	taken: Array[MeshInstance3D]
) -> void:
	for child: Node in node.get_children():
		var spatial := child as Node3D
		if spatial == null:
			continue
		_gather(root, spatial, tools, counts, skins, shadows, taken)
		var part := spatial as MeshInstance3D
		if part == null or part.mesh == null or part.material_override == null:
			continue
		var key := _key(part)
		if not tools.has(key):
			var tool := SurfaceTool.new()
			tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			tools[key] = tool
			counts[key] = 0
			skins[key] = part.material_override
			shadows[key] = part.cast_shadow
		tools[key].append_from(part.mesh, 0, _relative(root, part))
		counts[key] += 1
		taken.append(part)


## What a mesh is merged with: anything wearing the same material and casting the same shadow.
static func _key(part: MeshInstance3D) -> String:
	return "%d:%d" % [part.material_override.get_instance_id(), part.cast_shadow]


## Where [param node] stands in [param root]'s own space, walked up rather than read off the
## global transform, so this works on a room that is not in the tree yet.
static func _relative(root: Node3D, node: Node3D) -> Transform3D:
	var out := node.transform
	var parent := node.get_parent() as Node3D
	while parent != null and parent != root:
		out = parent.transform * out
		parent = parent.get_parent() as Node3D
	return out
