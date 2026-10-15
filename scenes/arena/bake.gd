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

## The looks of [method tinted_look], plain and metal.
static var _tinted_looks: Dictionary[int, StandardMaterial3D] = {}


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


## Merges everything static under [param root] into one mesh whatever it wears, its colors on its
## vertices, GAME.md 10.7: for a small thing built of many pieces in many plain colors, the pegboard
## of tools, a board on its stand, where [method merge] would make a mesh of each color. Each
## piece keeps its material's albedo and whether it is metal, and loses the rest, a texture
## included, so it is for pieces in plain paint. Metal and the rest are one mesh each, and so are
## what casts a shadow and what does not. The nodes are freed as they are taken, as with
## [method merge]; nothing that is not a [MeshInstance3D] wearing a [StandardMaterial3D] is
## touched. Returns how many meshes it made.
static func tint(root: Node3D) -> int:
	var groups: Dictionary[String, Array] = {}
	var taken: Array[MeshInstance3D] = []
	_gather_tinted(root, root, groups, taken)
	var made := 0
	for key: String in groups:
		var group: Array = groups[key]
		var baked := MeshInstance3D.new()
		baked.name = "Tinted%d" % made
		baked.mesh = tinted(group[2])
		baked.material_override = tinted_look(group[0])
		baked.cast_shadow = group[1]
		root.add_child(baked)
		made += 1
	for part: MeshInstance3D in taken:
		part.get_parent().remove_child(part)
		part.free()
	return made


## The look a mesh baked by [method tint] is drawn in, its colors off its vertices: the same as the
## Garage's bay's tinted props, see [BaySet], so it is a shader the warm-up has already compiled;
## metal for [param metal]. One of each, shared by every mesh baked so.
static func tinted_look(metal: bool) -> StandardMaterial3D:
	var key := 1 if metal else 0
	if not _tinted_looks.has(key):
		var look := StandardMaterial3D.new()
		look.vertex_color_use_as_albedo = true
		look.roughness = 0.6
		look.metallic = 0.7 if metal else 0.0
		_tinted_looks[key] = look
	return _tinted_looks[key]


static func _gather_tinted(
	root: Node3D, node: Node3D, groups: Dictionary[String, Array], taken: Array[MeshInstance3D]
) -> void:
	for child: Node in node.get_children():
		var spatial := child as Node3D
		if spatial == null:
			continue
		_gather_tinted(root, spatial, groups, taken)
		var part := spatial as MeshInstance3D
		if part == null or part.mesh == null or part.mesh.get_surface_count() == 0:
			continue
		var look := part.material_override as StandardMaterial3D
		if look == null:
			continue
		var metal := look.metallic > 0.5
		var key := "%d:%d" % [int(metal), part.cast_shadow]
		if not groups.has(key):
			groups[key] = [metal, part.cast_shadow, [] as Array[Array]]
		(groups[key][2] as Array[Array]).append(
			[part.mesh, _relative(root, part), look.albedo_color]
		)
		taken.append(part)


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
		# Normals turned the way the piece is, and kept a unit long however it is scaled.
		var turn := at.basis.inverse().transposed()
		for i: int in points.size():
			vertices.append(at * points[i])
			normals.append((turn * facing[i]).normalized())
			colors.append(color)
		# A mesh with no index list is drawn three vertices a triangle, in order.
		var listed: Variant = arrays[Mesh.ARRAY_INDEX]
		if listed == null or (listed as PackedInt32Array).is_empty():
			for i: int in points.size():
				indices.append(base + i)
		else:
			for index: int in listed as PackedInt32Array:
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
