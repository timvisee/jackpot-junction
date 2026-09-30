extends SceneTree
## What a frame of the playground is made of, GAME.md 10.7: the mesh instances by the script
## that built them, with their triangles; the distinct meshes and materials; the lights, the
## particle systems and the MultiMeshes; and the render info split by pass, which is how many
## triangles and draw calls the visible pass, the shadow pass and the canvas each take. With
## --ablate it then hides one group at a time and says what each costs in every pass, which is
## how the particles were found to be six of every seven triangles in a frame.
##
##   make probe                      the census, after 200 frames
##   make probe ARGS="--ablate"      and the cost of every group
##   tools/godot --path . -s tools/scene_probe.gd -- --frames=200 --map=vault --bots=3 --ablate

## Frames each ablation step is held for: the first three are settling, the rest are measured.
const MEASURE := 63

var _frames := 200
var _seen := 0
var _map := "lucky_crossing"
var _ablate := false
var _groups := {}
var _group_keys: Array = []
var _group_at := -1
var _wait := 0
var _base: Array = []
var _lights: Array = []
## GPU milliseconds a frame, summed over the frames a step is measured for, and how many.
var _gpu := 0.0
var _gpu_frames := 0
var _base_gpu := 0.0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--frames="):
			_frames = int(arg.get_slice("=", 1))
		elif arg.begins_with("--map="):
			_map = arg.get_slice("=", 1)
		elif arg == "--ablate":
			_ablate = true
	var scene: PackedScene = load("res://scenes/dev/playground.tscn")
	var node: Node = scene.instantiate()
	root.add_child(node)


func _process(_delta: float) -> bool:
	_seen += 1
	if _seen < _frames:
		return false
	if _seen == _frames:
		_report()
		if not _ablate:
			return true
		_collect()
		return false
	return _ablation_step()


func _report() -> void:
	var meshes := {}
	var by_script := {}
	var materials := {}
	var mesh_res := {}
	var lights := []
	var particles := 0
	var canvas_items := 0
	var sub_viewports := 0
	var total_instances := 0
	var total_surfaces := 0
	var multimeshes := []
	var tris_by_script := {}
	var shadow_casters := 0
	var shadow_tris := 0
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c: Node in n.get_children():
			stack.append(c)
		if n is CanvasItem:
			if (n as CanvasItem).is_visible_in_tree():
				canvas_items += 1
		if n is SubViewport:
			sub_viewports += 1
		if n is Light3D and (n as Light3D).is_visible_in_tree():
			var l := n as Light3D
			lights.append("%s %s shadow=%s" % [l.get_class(), l.name, l.shadow_enabled])
		if n is GPUParticles3D or n is CPUParticles3D or n is GPUParticles2D or n is CPUParticles2D:
			particles += 1
		if n is MultiMeshInstance3D and (n as MultiMeshInstance3D).is_visible_in_tree():
			var mm := n as MultiMeshInstance3D
			var mtris := _tris(mm.multimesh.mesh) if mm.multimesh and mm.multimesh.mesh else 0
			multimeshes.append(
				(
					"%s count=%d visible=%d tris/instance=%d total=%d shadow=%s"
					% [
						_owner(mm),
						mm.multimesh.instance_count if mm.multimesh else 0,
						mm.multimesh.visible_instance_count if mm.multimesh else 0,
						mtris,
						mtris * (mm.multimesh.instance_count if mm.multimesh else 0),
						mm.cast_shadow
					]
				)
			)
		if n is MeshInstance3D and (n as MeshInstance3D).is_visible_in_tree():
			var mi := n as MeshInstance3D
			if mi.mesh == null:
				continue
			total_instances += 1
			var surfaces := mi.mesh.get_surface_count()
			total_surfaces += surfaces
			var key := _owner(mi)
			by_script[key] = by_script.get(key, 0) + 1
			var t := _tris(mi.mesh)
			tris_by_script[key] = tris_by_script.get(key, 0) + t
			if mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				shadow_casters += 1
				shadow_tris += t
			var mid := mi.mesh.get_instance_id()
			mesh_res[mid] = mesh_res.get(mid, 0) + 1
			for s: int in surfaces:
				var mat: Material = mi.get_active_material(s)
				var mk := (
					"none" if mat == null else "%s#%d" % [mat.get_class(), mat.get_instance_id()]
				)
				materials[mk] = materials.get(mk, 0) + 1
	print("=== scene probe on %s after %d frames" % [_map, _frames])
	print(
		(
			"visible MeshInstance3D: %d, surfaces: %d, distinct meshes: %d, distinct materials: %d"
			% [total_instances, total_surfaces, mesh_res.size(), materials.size()]
		)
	)
	print(
		(
			"canvas items visible: %d, sub viewports: %d, particles: %d"
			% [canvas_items, sub_viewports, particles]
		)
	)
	print("lights (%d):" % lights.size())
	for l: String in lights:
		print("  ", l)
	print("multimeshes (%d):" % multimeshes.size())
	for m: String in multimeshes:
		print("  ", m)
	print("mesh instances by owner script:")
	var keys := by_script.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return by_script[a] > by_script[b])
	for k: String in keys:
		print("  %4d  %7d tris  %s" % [by_script[k], tris_by_script[k], k])
	print("shadow casters: %d instances, %d tris" % [shadow_casters, shadow_tris])
	print("materials used by more than 3 surfaces:")
	var mkeys := materials.keys()
	mkeys.sort_custom(func(a: String, b: String) -> bool: return materials[a] > materials[b])
	var shared := 0
	for k: String in mkeys:
		if materials[k] > 3:
			print("  %4d  %s" % [materials[k], k])
		else:
			shared += 1
	print("  ... and %d materials used by 3 or fewer surfaces" % shared)
	print(
		(
			"draw calls this frame: %d, objects: %d, primitives: %d"
			% [
				RenderingServer.get_rendering_info(
					RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME
				),
				RenderingServer.get_rendering_info(
					RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME
				),
				RenderingServer.get_rendering_info(
					RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME
				)
			]
		)
	)
	var vp := root.get_viewport_rid()
	for kind: Array in [
		["visible", RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE],
		["shadow", RenderingServer.VIEWPORT_RENDER_INFO_TYPE_SHADOW],
		["canvas", RenderingServer.VIEWPORT_RENDER_INFO_TYPE_CANVAS]
	]:
		print(
			(
				"  %s: objects %d, primitives %d, draw calls %d"
				% [
					kind[0],
					RenderingServer.viewport_get_render_info(
						vp, kind[1], RenderingServer.VIEWPORT_RENDER_INFO_OBJECTS_IN_FRAME
					),
					RenderingServer.viewport_get_render_info(
						vp, kind[1], RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME
					),
					RenderingServer.viewport_get_render_info(
						vp, kind[1], RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME
					)
				]
			)
		)
	print(
		(
			"nodes in tree: %d, orphans: %d"
			% [
				root.get_child_count(true),
				Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
			]
		)
	)
	print(
		(
			"node count monitor: %d, resources: %d, objects: %d"
			% [
				Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
				Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
				Performance.get_monitor(Performance.OBJECT_COUNT)
			]
		)
	)


## The nearest ancestor with a script, and the node's own name under it.
func _owner(n: Node) -> String:
	var p := n
	while p != null:
		var s: Script = p.get_script()
		if s != null:
			return "%s (%s)" % [s.resource_path.get_file(), n.name.rstrip("0123456789_").rstrip("0123456789")]
		p = p.get_parent()
	return "no script (%s)" % n.name


func _tris(mesh: Mesh) -> int:
	var n := 0
	for s: int in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var raw: Variant = arrays[Mesh.ARRAY_INDEX]
		var idx: PackedInt32Array = raw if raw != null else PackedInt32Array()
		if idx.is_empty():
			var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			n += v.size() / 3
		else:
			n += idx.size() / 3
	return n


func _counts() -> Array:
	var vp := root.get_viewport_rid()
	var out: Array = []
	for kind: int in [
		RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,
		RenderingServer.VIEWPORT_RENDER_INFO_TYPE_SHADOW
	]:
		out.append(
			RenderingServer.viewport_get_render_info(
				vp, kind, RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME
			)
		)
		out.append(
			RenderingServer.viewport_get_render_info(
				vp, kind, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME
			)
		)
	out.append(
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	)
	return out


func _collect() -> void:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c: Node in n.get_children():
			stack.append(c)
		if n is GeometryInstance3D and (n as GeometryInstance3D).is_visible_in_tree():
			var key := _owner(n) if not (n is MultiMeshInstance3D) else "multimesh " + _owner(n)
			if n is GPUParticles3D or n is CPUParticles3D:
				key = "particles " + _owner(n)
			if not _groups.has(key):
				_groups[key] = []
			(_groups[key] as Array).append(n)
		if n is Light3D and (n as Light3D).is_visible_in_tree():
			_lights.append(n)
	_group_keys = _groups.keys()
	# Each light on its own, then the shadows of the lot, then the lot.
	for l: Light3D in _lights:
		_group_keys.append("LIGHT OFF: %s %s" % [l.name, l.get_parent().name])
	_group_keys.append("LIGHT SHADOW OFF")
	_group_keys.append("ALL LIGHTS OFF")
	# The crowd shows itself again every frame from its setting, so it is the setting that goes.
	_group_keys.append("CROWD SETTING OFF")
	_group_at = -1
	_wait = MEASURE
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	print("=== ablation: hiding one group at a time")
	print("    (visible prims, visible draws, shadow prims, shadow draws, total draws)")


func _ablation_step() -> bool:
	_wait -= 1
	# The first frames after a change are left out; the rest are averaged for the GPU time.
	if _wait < MEASURE - 3:
		_gpu += RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())
		_gpu_frames += 1
	if _wait > 0:
		return false
	var gpu := _gpu / maxf(float(_gpu_frames), 1.0)
	_gpu = 0.0
	_gpu_frames = 0
	if _group_at >= 0:
		var counts := _counts()
		var key: String = _group_keys[_group_at]
		var line := "  %-50s" % key
		for i: int in counts.size():
			line += " %9d" % (_base[i] - counts[i])
		line += "  gpu %+.3f ms" % (gpu - _base_gpu)
		print(line)
		_restore(key)
	else:
		_base = _counts()
		_base_gpu = gpu
		var line := "  %-50s" % "BASE"
		for v: int in _base:
			line += " %9d" % v
		line += "  gpu %.3f ms" % gpu
		print(line)
	_group_at += 1
	if _group_at >= _group_keys.size():
		return true
	_hide(_group_keys[_group_at])
	_wait = MEASURE
	return false


func _hide(key: String) -> void:
	if key == "LIGHT SHADOW OFF":
		for l: Light3D in _lights:
			if is_instance_valid(l):
				l.set_meta("was_shadow", l.shadow_enabled)
				l.shadow_enabled = false
	elif key == "ALL LIGHTS OFF":
		for l: Light3D in _lights:
			if is_instance_valid(l):
				l.set_meta("was_visible", l.visible)
				l.visible = false
	elif key == "CROWD SETTING OFF":
		_settings().crowd = false
	elif key.begins_with("LIGHT OFF: "):
		var l := _light_named(key)
		if l != null:
			l.set_meta("was_visible", l.visible)
			l.visible = false
	else:
		for g: Variant in _groups[key]:
			if is_instance_valid(g):
				(g as GeometryInstance3D).visible = false


func _restore(key: String) -> void:
	if key == "LIGHT SHADOW OFF":
		for l: Light3D in _lights:
			if is_instance_valid(l):
				l.shadow_enabled = l.get_meta("was_shadow")
	elif key == "ALL LIGHTS OFF":
		for l: Light3D in _lights:
			if is_instance_valid(l):
				l.visible = l.get_meta("was_visible")
	elif key == "CROWD SETTING OFF":
		_settings().crowd = true
	elif key.begins_with("LIGHT OFF: "):
		var l := _light_named(key)
		if l != null:
			l.visible = l.get_meta("was_visible")
	else:
		for g: Variant in _groups[key]:
			if is_instance_valid(g):
				(g as GeometryInstance3D).visible = true


## The light a "LIGHT OFF" step names, or null if it has gone.
func _light_named(key: String) -> Light3D:
	for l: Light3D in _lights:
		if is_instance_valid(l) and key == "LIGHT OFF: %s %s" % [l.name, l.get_parent().name]:
			return l
	return null


## The game's settings, through the autoload rather than by name, so this script compiles
## without the project's classes.
func _settings() -> Variant:
	return root.get_node("/root/Game").get("settings")
