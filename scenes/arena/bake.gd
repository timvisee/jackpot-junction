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
		part.queue_free()
	return made


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
