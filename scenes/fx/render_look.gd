class_name RenderLook
extends Node
## How the room is drawn, GAME.md 8.1b: the look of [member Settings.look] over every room the game
## shows, a match, the Garage, the kart dialog's bay and the podium alike. A look is a pass over
## the whole of a camera's frame, a quad hung in front of its lens and drawn first of everything
## transparent (see [code]scenes/fx/looks/[/code]), a light on every material the engine shades
## itself, toon or none at all, or both: the cel look is the toon light with the keyline over it.
##
## One of these lives under the Game autoload. It hangs a pass on every camera that comes into the
## tree and lights every material that comes in as the look asks, so a screen built after the look
## was chosen is drawn in it the same as one standing when it was. A look costs a few tenths of a
## millisecond on a desktop's card, GAME.md 10.7.
##
## While the looks are being chosen between, a strip at the foot of any screen with a room on it
## steps through them (F7 and F8, or its buttons) and keeps the ones marked (F9), see
## [method _build_switcher]. Temporary: it goes once a look is chosen.

## Every look: the name the settings keep, what the Video page calls it, the pass it draws over the
## frame by the name of its shader (empty for none), the light on the room's materials ("made" for
## the light they were made with, "toon" for flat bands, "flat" for none, their color alone), and
## what the pass is set to, which is how two looks share one pass.
const TABLE: Array[Array] = [
	["clean", "Clean", "", "made", {}],
	["outline", "Black outline", "outline", "made", {}],
	["outline_thin", "Thin outline", "outline", "made", {"width": 1.1, "crease": 0.35}],
	["outline_bold", "Bold outline", "outline", "made", {"width": 2.8, "crease": 0.6}],
	["cartoon", "Cartoon", "outline", "toon", {"width": 2.0, "crease": 0.55}],
	["outline_flat", "Flat and outline", "outline", "flat", {"width": 2.0, "crease": 0.6}],
	["inkprint", "Ink and print", "inkprint", "made", {}],
	["inkprint_toon", "Ink and print, toon", "inkprint", "toon", {"dots": 0.35}],
	["toon", "Toon", "", "toon", {}],
	["flat", "Flat", "", "flat", {}],
	["keyline", "Keyline", "keyline", "made", {}],
	["cel", "Cel", "keyline", "toon", {}],
	["flatline", "Flat and keyline", "keyline", "flat", {}],
	["vivid", "Vivid", "vivid", "made", {}],
	["pastel", "Pastel", "pastel", "made", {}],
	["houseprint", "House print", "houseprint", "made", {}],
	["halftone", "Halftone", "halftone", "made", {}],
	["engrave", "Engraved", "engrave", "made", {}],
	["fineprint", "Fine print", "fineprint", "made", {"grain": 0.1, "spread": 0.8, "corners": 0.5}],
	["diorama", "Diorama", "diorama", "made", {}],
	["tiltshift", "Tilt-shift", "tiltshift", "made", {}],
	["riso", "Riso", "riso", "made", {}],
	["gouache", "Gouache", "gouache", "made", {}],
	["comic", "Comic", "comic", "toon", {}],
	["watercolor", "Watercolor", "watercolor", "made", {}],
	["pencil", "Pencil", "pencil", "made", {}],
	["inkwash", "Ink wash", "inkwash", "made", {}],
	["lineart", "Line art", "lineart", "flat", {}],
	["woodblock", "Woodblock", "woodblock", "toon", {}],
	["blueprint", "Blueprint", "blueprint", "flat", {}],
	["chalk", "Chalkboard", "chalk", "flat", {}],
	["crayon", "Crayon", "crayon", "toon", {}],
	["crt", "Arcade screen", "crt", "made", {}],
	["gameboy", "Four greens", "gameboy", "made", {}],
	["vhs", "Tape", "vhs", "made", {}],
	["film", "Technicolor", "film", "made", {}],
	["noir", "Noir", "noir", "made", {}],
	["neon", "Neon", "neon", "flat", {}],
	["oil", "Oil paint", "oil", "made", {}],
	["screenprint", "Screenprint", "screenprint", "toon", {}],
	["duotone", "Duotone", "duotone", "made", {}],
	["stainedglass", "Stained glass", "stainedglass", "flat", {}],
	["mosaic", "Mosaic", "mosaic", "toon", {}],
	["crossstitch", "Cross-stitch", "crossstitch", "toon", {}],
]
## Where a material keeps the light it was made with while a look lights it otherwise.
const KEPT := &"look_kept_modes"
## How often, in seconds, the strip looks for a room on the screen to show itself over.
const SWITCHER_CHECK := 0.4

## The look in use, one of [method ids].
var look := "clean"

var _material: ShaderMaterial
var _quads: Array[MeshInstance3D] = []
## Meshes come in before their materials are put on them, so they are looked at a frame late.
var _arrived: Array[GeometryInstance3D] = []
var _switcher: CanvasLayer
var _switcher_name: Label
var _switcher_keep: Button
var _switcher_wait := 0.0


## Every look's name, as the settings keep it, in the order they are offered.
static func ids() -> Array[String]:
	var all: Array[String] = []
	for row: Array in TABLE:
		all.append(row[0])
	return all


## What each look is called, in the order of [method ids].
static func names() -> Array[String]:
	var all: Array[String] = []
	for row: Array in TABLE:
		all.append(row[1])
	return all


## The row of [param id], or the clean look's for one that is not a look.
static func row_of(id: String) -> Array:
	for row: Array in TABLE:
		if row[0] == id:
			return row
	return TABLE[0]


## The look's node under [param parent], made if there is none yet.
static func of(parent: Node) -> RenderLook:
	var found := parent.get_node_or_null("RenderLook") as RenderLook
	if found != null:
		return found
	var made := RenderLook.new()
	made.name = "RenderLook"
	parent.add_child(made)
	return made


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_material = ShaderMaterial.new()
	_material.render_priority = Material.RENDER_PRIORITY_MIN
	get_tree().node_added.connect(_on_node_added)
	if DisplayServer.get_name() != "headless":
		_build_switcher()


## Draws every room in [param id] from now on, one of [method ids]; anything else is clean.
func use(id: String) -> void:
	var row := row_of(id)
	var was_light: String = row_of(look)[3]
	look = row[0]
	var shader_name: String = row[2]
	if not shader_name.is_empty():
		# A material of its own each time, so what one look set its pass to is not left on the next.
		_material = ShaderMaterial.new()
		_material.render_priority = Material.RENDER_PRIORITY_MIN
		_material.shader = load("res://scenes/fx/looks/%s.gdshader" % shader_name)
		var settings: Dictionary = row[4]
		for key: String in settings:
			_material.set_shader_parameter(key, settings[key])
	for camera: Node in get_tree().root.find_children("*", "Camera3D", true, false):
		_hang(camera as Camera3D)
	# A pass goes with its camera, so some of these may be freed. Looked at untyped: a freed
	# object is no longer a MeshInstance3D to anything typed, and asking one errors.
	var alive: Array[MeshInstance3D] = []
	for quad: Variant in _quads:
		if is_instance_valid(quad):
			alive.append(quad as MeshInstance3D)
	_quads = alive
	for quad: MeshInstance3D in _quads:
		quad.visible = not shader_name.is_empty()
		(quad.mesh as QuadMesh).material = _material
	if was_light != row[3]:
		for node: Node in get_tree().root.find_children("*", "GeometryInstance3D", true, false):
			_light(node as GeometryInstance3D)
	_show_switcher()


func _on_node_added(node: Node) -> void:
	if node is Camera3D:
		_hang.call_deferred(node)
	elif node is GeometryInstance3D and row_of(look)[3] != "made":
		if _arrived.is_empty():
			_light_arrived.call_deferred()
		_arrived.append(node)


## Hangs the look's pass in front of [param camera], once.
func _hang(camera: Camera3D) -> void:
	if not is_instance_valid(camera) or camera.has_node("LookPass"):
		return
	var mesh := QuadMesh.new()
	mesh.size = Vector2(2.0, 2.0)
	mesh.material = _material
	var quad := MeshInstance3D.new()
	quad.name = "LookPass"
	quad.mesh = mesh
	quad.position = Vector3(0.0, 0.0, -1.0)
	# Never culled: the pass's vertex shader lays it over the whole frame wherever its box is.
	quad.extra_cull_margin = 16384.0
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	quad.visible = not str(row_of(look)[2]).is_empty()
	camera.add_child(quad)
	_quads.append(quad)


func _light_arrived() -> void:
	# Untyped for the same reason as the passes in [method use]: some may be freed by now.
	for node: Variant in _arrived:
		if is_instance_valid(node):
			_light(node as GeometryInstance3D)
	_arrived.clear()


## Every material on [param node] in the light the look asks for, see [method light_material].
func _light(node: GeometryInstance3D) -> void:
	if node == null or node.name == "LookPass":
		return
	var light: String = row_of(look)[3]
	var materials: Array[Material] = [node.material_override]
	var mesh_node := node as MeshInstance3D
	if mesh_node != null and mesh_node.mesh != null:
		for surface: int in mesh_node.mesh.get_surface_count():
			materials.append(mesh_node.get_surface_override_material(surface))
			materials.append(mesh_node.mesh.surface_get_material(surface))
	for material: Material in materials:
		light_material(material, light)


## [param material] in [param light]: "toon" for flat bands, "flat" for its color alone, or "made"
## for the light it was made with, which it keeps while it wears another.
static func light_material(material: Material, light: String) -> void:
	var base := material as BaseMaterial3D
	if base == null:
		return
	if not base.has_meta(KEPT):
		if base.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED or light == "made":
			return
		base.set_meta(
			KEPT, PackedInt32Array([base.diffuse_mode, base.specular_mode, base.shading_mode])
		)
	var kept: PackedInt32Array = base.get_meta(KEPT)
	match light:
		"toon":
			base.shading_mode = kept[2] as BaseMaterial3D.ShadingMode
			base.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
			base.specular_mode = BaseMaterial3D.SPECULAR_TOON
		"flat":
			base.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_:
			base.diffuse_mode = kept[0] as BaseMaterial3D.DiffuseMode
			base.specular_mode = kept[1] as BaseMaterial3D.SpecularMode
			base.shading_mode = kept[2] as BaseMaterial3D.ShadingMode
			base.remove_meta(KEPT)


## The strip at the foot of the screen that steps through the looks while they are being chosen
## between: the one before, its name and its place among them, the one after, and a mark for the
## ones worth keeping, which the settings remember, [member Settings.looks_kept].
func _build_switcher() -> void:
	_switcher = CanvasLayer.new()
	_switcher.name = "LookSwitcher"
	_switcher.layer = 120
	_switcher.visible = false
	add_child(_switcher)
	var strip := PanelContainer.new()
	strip.anchor_left = 0.5
	strip.anchor_right = 0.5
	strip.anchor_top = 1.0
	strip.anchor_bottom = 1.0
	strip.grow_horizontal = Control.GROW_DIRECTION_BOTH
	strip.grow_vertical = Control.GROW_DIRECTION_BEGIN
	strip.offset_bottom = -8.0
	_switcher.add_child(strip)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	strip.add_child(row)
	var back := Button.new()
	back.text = "◀ F7"
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(step.bind(-1))
	row.add_child(back)
	_switcher_name = Label.new()
	_switcher_name.custom_minimum_size = Vector2(300.0, 0.0)
	_switcher_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_switcher_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_switcher_name)
	var on := Button.new()
	on.text = "F8 ▶"
	on.focus_mode = Control.FOCUS_NONE
	on.pressed.connect(step.bind(1))
	row.add_child(on)
	_switcher_keep = Button.new()
	_switcher_keep.toggle_mode = true
	_switcher_keep.focus_mode = Control.FOCUS_NONE
	_switcher_keep.toggled.connect(_keep)
	row.add_child(_switcher_keep)
	_show_switcher()


## Steps [param by] looks along [method ids], round from the last to the first, and keeps it.
func step(by: int) -> void:
	var all := ids()
	var at := posmod(all.find(look) + by, all.size())
	use(all[at])
	var settings: Variant = _settings()
	if settings != null:
		settings.look = look
		settings.save_to_disk()


func _keep(on: bool) -> void:
	var settings: Variant = _settings()
	if settings == null:
		return
	var kept: PackedStringArray = settings.looks_kept
	if on and not kept.has(look):
		kept.append(look)
	elif not on and kept.has(look):
		kept.remove_at(kept.find(look))
	settings.looks_kept = kept
	settings.save_to_disk()
	_show_switcher()


func _settings() -> Variant:
	var game := get_parent()
	if game == null or not "settings" in game:
		return null
	return game.settings


func _show_switcher() -> void:
	if _switcher_name == null:
		return
	var all := ids()
	var at := all.find(look)
	_switcher_name.text = "Look %d of %d · %s" % [at + 1, all.size(), row_of(look)[1]]
	var settings: Variant = _settings()
	var kept: bool = settings != null and settings.looks_kept.has(look)
	_switcher_keep.set_pressed_no_signal(kept)
	var count: int = settings.looks_kept.size() if settings != null else 0
	_switcher_keep.text = ("★ kept" if kept else "☆ keep") + " F9 (%d)" % count


func _process(delta: float) -> void:
	if _switcher == null:
		return
	_switcher_wait -= delta
	if _switcher_wait > 0.0:
		return
	_switcher_wait = SWITCHER_CHECK
	_switcher.visible = get_viewport().get_camera_3d() != null


func _input(event: InputEvent) -> void:
	if _switcher == null or not _switcher.visible:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_F7:
			step(-1)
		KEY_F8:
			step(1)
		KEY_F9:
			_keep(not _switcher_keep.button_pressed)
		_:
			return
	get_viewport().set_input_as_handled()
