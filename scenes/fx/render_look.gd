class_name RenderLook
extends Node
## How the room is drawn, GAME.md 8.1b: the look of [member Settings.look] over every room the game
## shows, a match, the Garage, the kart dialog's bay and the podium alike. A look is a pass over
## the whole of a camera's frame, a quad hung in front of its lens and drawn first of everything
## transparent (see [code]scenes/fx/looks/[/code]), the toon light on every material the engine
## shades itself, or both: the cel look is the toon light with the keyline over it.
##
## One of these lives under the Game autoload. It hangs a pass on every camera that comes into the
## tree and turns every material that comes in to the toon light while the look asks for it, so a
## screen built after the look was chosen is drawn in it the same as one standing when it was. A
## look costs a few tenths of a millisecond on a desktop's card, the gouache more, GAME.md 10.7.

## Every look, by the name the settings keep, in the order the Video page offers them.
const LOOKS: Array[String] = [
	"clean",
	"toon",
	"keyline",
	"cel",
	"houseprint",
	"halftone",
	"engrave",
	"fineprint",
	"diorama",
	"riso",
	"gouache",
	"comic",
]
## What each is called on the Video page.
const NAMES: Array[String] = [
	"Clean",
	"Toon",
	"Keyline",
	"Cel",
	"House print",
	"Halftone",
	"Engraved",
	"Fine print",
	"Diorama",
	"Riso",
	"Gouache",
	"Comic",
]
## The pass each draws over the frame, by the name of its shader, or none.
const PASSES := {
	"keyline": "keyline",
	"cel": "keyline",
	"houseprint": "houseprint",
	"halftone": "halftone",
	"engrave": "engrave",
	"fineprint": "fineprint",
	"diorama": "diorama",
	"riso": "riso",
	"gouache": "gouache",
	"comic": "comic",
}
## The looks that light every material in bands rather than in a smooth fall.
const TOON: Array[String] = ["toon", "cel"]
## Where a material keeps the light it was made with while the toon light is on it.
const KEPT := &"look_kept_modes"

## The look in use, one of [constant LOOKS].
var look := "clean"

var _material: ShaderMaterial
var _quads: Array[MeshInstance3D] = []
## Meshes come in before their materials are put on them, so they are looked at a frame late.
var _arrived: Array[GeometryInstance3D] = []


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


## Draws every room in [param name] from now on, one of [constant LOOKS]; anything else is clean.
func use(name: String) -> void:
	var wanted := name if name in LOOKS else "clean"
	var was_toon := look in TOON
	look = wanted
	var shader_name: String = PASSES.get(look, "")
	if not shader_name.is_empty():
		_material.shader = load("res://scenes/fx/looks/%s.gdshader" % shader_name)
	for camera: Node in get_tree().root.find_children("*", "Camera3D", true, false):
		_hang(camera as Camera3D)
	_quads = _quads.filter(func(quad: MeshInstance3D) -> bool: return is_instance_valid(quad))
	for quad: MeshInstance3D in _quads:
		quad.visible = not shader_name.is_empty()
	if was_toon != (look in TOON):
		for node: Node in get_tree().root.find_children("*", "GeometryInstance3D", true, false):
			_light(node as GeometryInstance3D)


func _on_node_added(node: Node) -> void:
	if node is Camera3D:
		_hang.call_deferred(node)
	elif node is GeometryInstance3D and look in TOON:
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
	quad.visible = PASSES.has(look)
	camera.add_child(quad)
	_quads.append(quad)


func _light_arrived() -> void:
	for node: GeometryInstance3D in _arrived:
		if is_instance_valid(node):
			_light(node)
	_arrived.clear()


## Every material on [param node] in the light the look asks for: toon, or the one it was made
## with, which it keeps while it wears the toon light.
func _light(node: GeometryInstance3D) -> void:
	if node == null or node.name == "LookPass":
		return
	var toon := look in TOON
	var materials: Array[Material] = [node.material_override]
	var mesh_node := node as MeshInstance3D
	if mesh_node != null and mesh_node.mesh != null:
		for surface: int in mesh_node.mesh.get_surface_count():
			materials.append(mesh_node.get_surface_override_material(surface))
			materials.append(mesh_node.mesh.surface_get_material(surface))
	for material: Material in materials:
		light_material(material, toon)


## [param material] in the toon light when [param toon], or back in the light it was made with.
static func light_material(material: Material, toon: bool) -> void:
	var base := material as BaseMaterial3D
	if base == null or base.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
		return
	if toon:
		if not base.has_meta(KEPT):
			base.set_meta(KEPT, PackedInt32Array([base.diffuse_mode, base.specular_mode]))
		base.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		base.specular_mode = BaseMaterial3D.SPECULAR_TOON
	elif base.has_meta(KEPT):
		var kept: PackedInt32Array = base.get_meta(KEPT)
		base.diffuse_mode = kept[0] as BaseMaterial3D.DiffuseMode
		base.specular_mode = kept[1] as BaseMaterial3D.SpecularMode
		base.remove_meta(KEPT)
