class_name ItemBox
extends Pickup
## A power-up on the floor: a glowing, pulsing crate with a big question mark and a beam of light,
## so it stands out from the pads and chips. From a pad it holds a whole table and decides the item
## when taken, like a roulette; dropped on death it holds one fixed item. Karts already holding an
## item cannot take it.

var table: PowerUpTable
var fixed_item: PowerUp
var rng: RandomNumberGenerator
var reveal_time := 0.5

var _material: StandardMaterial3D
var _pulse := 0.0


func can_collect(kart: Kart) -> bool:
	return super(kart) and kart.held_item == null and not kart.is_decoy()


func _build_visual(parent: Node3D) -> void:
	var color := fixed_item.color if fixed_item != null else Palette.CHIP_GOLD
	_material = StandardMaterial3D.new()
	_material.albedo_color = color
	_material.emission_enabled = true
	_material.emission = color
	_material.emission_energy_multiplier = 1.0
	var cube := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * 0.75
	cube.mesh = mesh
	cube.material_override = _material
	parent.add_child(cube)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.1, 0.1, 0.12)
	for axis: int in 2:
		var band := MeshInstance3D.new()
		var band_mesh := BoxMesh.new()
		band_mesh.size = Vector3(0.8, 0.16, 0.8) if axis == 0 else Vector3(0.16, 0.8, 0.8)
		band.mesh = band_mesh
		band.material_override = dark
		parent.add_child(band)
	var mark := Label3D.new()
	mark.text = "?" if fixed_item == null else fixed_item.display_name.left(1)
	mark.font_size = 120
	mark.outline_size = 20
	mark.modulate = Palette.CHIP_WHITE
	mark.outline_modulate = Color(0.05, 0.05, 0.06)
	mark.pixel_size = 0.01
	mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mark.no_depth_test = true
	mark.position = Vector3(0.0, 1.15, 0.0)
	parent.add_child(mark)
	var beam := MeshInstance3D.new()
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.04
	beam_mesh.bottom_radius = 0.28
	beam_mesh.height = 2.6
	beam.mesh = beam_mesh
	var beam_material := StandardMaterial3D.new()
	beam_material.albedo_color = Color(color.r, color.g, color.b, 0.22)
	beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam.material_override = beam_material
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.position = Vector3(0.0, 1.65, 0.0)
	parent.add_child(beam)
	hover = 0.65


## Spins and bobs like every pickup, and pulses its glow and size on top.
func _process(delta: float) -> void:
	super(delta)
	# Taken, its look has gone into the kart with PickupFlight, GAME.md 8.3, and the box only has
	# the rest of the frame to live.
	if _visual == null:
		return
	_pulse += delta
	var wave := 0.5 + 0.5 * sin(_pulse * 4.0)
	_material.emission_energy_multiplier = 0.6 + 1.2 * wave
	# Its size is the fall's and the throw's while either is under way.
	if not falling and throw_state().is_empty():
		_visual.scale = Vector3.ONE * (0.94 + 0.12 * wave)


func _apply(kart: Kart) -> void:
	var item := fixed_item if fixed_item != null else table.pick(rng)
	kart.hold_item(item, reveal_time if fixed_item == null else 0.0)
