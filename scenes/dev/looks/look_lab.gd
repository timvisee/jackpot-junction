extends Node
## The rendering lab of the 3D art direction's trials: a look laid over the whole of a camera's
## frame, as a quad in front of its lens drawn first of everything transparent. Asked to, it also
## prints the time the card takes over each frame once a run has settled, or holds one frame of the
## match still and saves it under every look in turn, so they can be held against each other.
## Development only: the playground's `--look=`, `--gpu-time=` and `--look-sheet=` put it in.

const LOOKS: Array[String] = [
	"keyline",
	"cel",
	"halftone",
	"engrave",
	"houseprint",
	"riso",
	"gouache",
	"fineprint",
	"diorama",
	"comic",
]
## What each look is called on the caption a cycling run shows.
const TITLES := {
	"none": "Today: no look",
	"keyline": "Keyline: ink round every edge",
	"cel": "Cel: toon light and a keyline",
	"halftone": "Halftone: shadows printed in dots",
	"engrave": "Engrave: shadows in engraved lines",
	"houseprint": "House print: keyline, dotted shade, paper",
	"riso": "Riso: spot inks a hair off register",
	"gouache": "Gouache: painted in flat strokes",
	"fineprint": "Fine print: paper tooth and ink spread",
	"diorama": "Diorama: graded like a model photograph",
	"comic": "Comic: bands, keyline and dots",
}
## Frames left to settle before the time is counted: the first ones compile shaders.
const WARMUP := 180
## Frames each look is given on the held frame before it is saved, so its pass has run.
const SETTLE := 4

var look := ""
var frames := 0
## Where the held frame's pictures go, one per look and one with none, and at which frame of the
## run the match is held.
var sheet_dir := ""
var sheet_at := 0
## Frames each look is shown for in turn, for a recording of all of them in motion; none for one
## look all the run.
var cycle := 0

var _rid: RID
var _seen := 0
var _total := 0.0
var _cpu := 0.0
var _material: ShaderMaterial
var _quad: MeshInstance3D
var _sheet: Array[String] = []
var _wait := 0
var _toon := false
var _modes := {}
var _caption: Label


## Lays [param name] over [param camera]'s frame, or nothing for "none", and counts the card's time
## over [param count] frames when that is more than nothing. Returns the lab node.
static func attach(camera: Camera3D, name: String, count := 0) -> Node:
	var lab := _made()
	lab.look = name
	lab.frames = count
	camera.add_child(lab)
	return lab


## Shows every look in turn for [param each] frames, with a caption naming it, from the first frame.
static func cycling(camera: Camera3D, each: int) -> Node:
	var lab := _made()
	lab.cycle = each
	camera.add_child(lab)
	return lab


## Holds the match at frame [param at] and saves the frame under every look into [param dir].
static func sheet(camera: Camera3D, dir: String, at: int) -> Node:
	var lab := _made()
	lab.sheet_dir = dir
	lab.sheet_at = at
	camera.add_child(lab)
	return lab


static func _made() -> Node:
	var lab: Node = load("res://scenes/dev/looks/look_lab.gd").new()
	lab.name = "LookLab"
	return lab


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var camera := get_parent() as Camera3D
	_material = ShaderMaterial.new()
	_material.render_priority = Material.RENDER_PRIORITY_MIN
	var mesh := QuadMesh.new()
	mesh.size = Vector2(2.0, 2.0)
	mesh.material = _material
	_quad = MeshInstance3D.new()
	_quad.name = "Look"
	_quad.mesh = mesh
	_quad.position = Vector3(0.0, 0.0, -1.0)
	# Never culled: the vertex shader puts it over the whole frame wherever the box is.
	_quad.extra_cull_margin = 16384.0
	_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	camera.add_child.call_deferred(_quad)
	_show(look)
	if frames > 0:
		_rid = get_viewport().get_viewport_rid()
		RenderingServer.viewport_set_measure_render_time(_rid, true)
	elif sheet_dir.is_empty() and cycle <= 0:
		set_process(false)
	if cycle > 0:
		var layer := CanvasLayer.new()
		layer.layer = 100
		add_child(layer)
		_caption = Label.new()
		_caption.add_theme_font_size_override("font_size", 30)
		_caption.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.06))
		_caption.add_theme_constant_override("outline_size", 10)
		_caption.anchor_left = 0.0
		_caption.anchor_right = 1.0
		_caption.anchor_top = 1.0
		_caption.anchor_bottom = 1.0
		_caption.offset_top = -64.0
		_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		layer.add_child(_caption)
		_show("none")
		_caption.text = TITLES["none"]


func _show(name: String) -> void:
	# Cel is the one look that is not a pass over the frame alone: the room's own materials take
	# the toon light, and the keyline goes over them.
	_set_toon(name == "cel")
	var pass_name := "keyline" if name == "cel" else name
	_quad.visible = pass_name != "none" and not pass_name.is_empty()
	if _quad.visible:
		_material.shader = load("res://scenes/fx/looks/%s.gdshader" % pass_name)


## Every material in the scene that the engine shades itself lit in bands rather than in a smooth
## fall, or put back as it was.
func _set_toon(on: bool) -> void:
	if on == _toon:
		return
	_toon = on
	var nodes: Array[Node] = [get_tree().root]
	while not nodes.is_empty():
		var node: Node = nodes.pop_back()
		nodes.append_array(node.get_children())
		var geometry := node as GeometryInstance3D
		if geometry == null:
			continue
		var materials: Array[Material] = [geometry.material_override]
		var mesh_node := geometry as MeshInstance3D
		if mesh_node != null and mesh_node.mesh != null:
			for surface: int in mesh_node.mesh.get_surface_count():
				materials.append(mesh_node.get_surface_override_material(surface))
				materials.append(mesh_node.mesh.surface_get_material(surface))
		for material: Material in materials:
			var base := material as BaseMaterial3D
			if base == null:
				continue
			if on:
				if not _modes.has(base):
					_modes[base] = [base.diffuse_mode, base.specular_mode]
				base.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
				base.specular_mode = BaseMaterial3D.SPECULAR_TOON
			elif _modes.has(base):
				base.diffuse_mode = _modes[base][0]
				base.specular_mode = _modes[base][1]


func _process(_delta: float) -> void:
	_seen += 1
	if not sheet_dir.is_empty():
		_step_sheet()
		return
	if cycle > 0:
		var order: Array[String] = ["none"]
		order.append_array(LOOKS)
		var index := mini(_seen / cycle, order.size() - 1)
		var name := order[index]
		if _caption.text != TITLES[name]:
			_show(name)
			_caption.text = TITLES[name]
			print("cycle %s from frame %d" % [name, _seen])
		return
	if _seen <= WARMUP:
		return
	_total += RenderingServer.viewport_get_measured_render_time_gpu(_rid)
	_cpu += RenderingServer.viewport_get_measured_render_time_cpu(_rid)
	if _seen == WARMUP + frames:
		var method := str(ProjectSettings.get_setting("rendering/renderer/rendering_method"))
		print(
			(
				"look %s on %s: gpu %.3f ms, render cpu %.3f ms, over %d frames at %s"
				% [
					look if not look.is_empty() else "none",
					method,
					_total / frames,
					_cpu / frames,
					frames,
					get_viewport().get_visible_rect().size
				]
			)
		)


func _step_sheet() -> void:
	if _seen < sheet_at:
		return
	if _seen == sheet_at:
		get_tree().paused = true
		_sheet = ["none"]
		_sheet.append_array(LOOKS)
		_show(_sheet[0])
		_wait = SETTLE
		return
	_wait -= 1
	if _wait > 0:
		return
	var image := get_viewport().get_texture().get_image()
	var path := sheet_dir.path_join("%s.png" % _sheet[0])
	print("sheet %s: %s" % [path, error_string(image.save_png(path))])
	_sheet.remove_at(0)
	if _sheet.is_empty():
		get_tree().quit()
		return
	_show(_sheet[0])
	_wait = SETTLE
