class_name Hologram
extends StaticBody3D
## A wall of light across a doorway, GAME.md 9.4a: a kart cannot drive through it, a shot can. The
## tutorial's Ricochet pocket is shut with one, so the target behind the stub of wall in there can
## only be reached by a shot bounced in. On the layer a protected kart is on, which karts bump
## into and bullets pass through, see [Layers].

const INK := Palette.NEON_CYAN
const DEPTH := 0.12
const FRAME := 0.06
## How fast the pane breathes, in beats a second.
const PULSE := 0.5

var _pane: StandardMaterial3D
var _time := 0.0


## Builds the wall across [param size], in meters, standing on the floor at [param at].
static func add_to(parent: Node, at: Vector3, size: Vector3) -> Hologram:
	var wall := Hologram.new()
	wall.name = "Hologram"
	wall.position = at
	parent.add_child(wall)
	wall.build(size)
	return wall


func build(size: Vector3) -> void:
	collision_layer = Layers.PROTECTED
	collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = Vector3(0.0, size.y * 0.5, 0.0)
	add_child(shape)
	var pane := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, size.y, size.z)
	pane.mesh = mesh
	_pane = StandardMaterial3D.new()
	_pane.albedo_color = Color(INK, 0.3)
	_pane.emission_enabled = true
	_pane.emission = INK
	_pane.emission_energy_multiplier = 0.6
	_pane.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_pane.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_pane.cull_mode = BaseMaterial3D.CULL_DISABLED
	pane.material_override = _pane
	pane.position = Vector3(0.0, size.y * 0.5, 0.0)
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pane)
	# A bright frame round the pane, so its edges read as edges of something.
	var frame := StandardMaterial3D.new()
	frame.albedo_color = INK
	frame.emission_enabled = true
	frame.emission = INK
	frame.emission_energy_multiplier = 1.5
	var along_x := size.x >= size.z
	var long := maxf(size.x, size.z)
	var thick := minf(size.x, size.z)
	for y: float in [FRAME * 0.5, size.y - FRAME * 0.5]:
		var bar := MeshInstance3D.new()
		var bar_mesh := BoxMesh.new()
		bar_mesh.size = (
			Vector3(long, FRAME, thick + 0.02) if along_x else Vector3(thick + 0.02, FRAME, long)
		)
		bar.mesh = bar_mesh
		bar.material_override = frame
		bar.position = Vector3(0.0, y, 0.0)
		add_child(bar)


func _process(delta: float) -> void:
	_time += delta
	var breath := 0.5 + 0.5 * sin(_time * TAU * PULSE)
	_pane.albedo_color = Color(INK, 0.22 + 0.16 * breath)
	_pane.emission_energy_multiplier = 0.4 + 0.5 * breath
