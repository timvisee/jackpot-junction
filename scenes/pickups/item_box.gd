class_name ItemBox
extends Pickup
## A power-up on the floor: a glowing, pulsing crate with a beam of light, so it stands out from
## the pads and chips. From a pad it holds a whole table and decides the item when taken, like a
## roulette, and wears a question mark; dropped on death it holds one fixed item, and wears that,
## GAME.md 8.3a: the item's own picture, branded on its top and sides. Karts already holding an
## item cannot take it.

## How big the brand is drawn, how big it is on each face and how far out from the middle, just
## clear of the bands, and the chip it is drawn on.
const BRAND_PIXELS := 128
const BRAND_SIZE := 0.56
const BRAND_OUT := 0.41
const BRAND_CHIP := Color(0.05, 0.05, 0.07)

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
	_brand(parent)
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


## What the box holds, branded on its top and four sides: a dropped box's item, pictured, or a
## question mark on a box from a pad, since what comes out of that is anybody's guess.
func _brand(parent: Node3D) -> void:
	var badge := Badge.new()
	badge.item = fixed_item
	var ink := DrawnTexture.decal(DrawnTexture.of(parent, badge, Vector2i.ONE * BRAND_PIXELS))
	# Over the beam of light rising out of the box, which would tint the top one its own color.
	ink.render_priority = 1
	for side: int in 5:
		var brand := DrawnTexture.face(Vector2.ONE * BRAND_SIZE, ink)
		brand.name = "Brand%d" % side
		if side < 4:
			brand.rotation.y = side * PI * 0.5
		else:
			# And on top, the face the camera sees the most of.
			brand.rotation.x = -PI * 0.5
		brand.position = brand.basis.z * BRAND_OUT
		parent.add_child(brand)


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


## A dropped box's item, pictured on a dark chip so it reads against the box in its own color,
## or a question mark for a box from a pad.
class Badge:
	extends Control

	var item: PowerUp

	func _draw() -> void:
		var chip := StyleBoxFlat.new()
		chip.bg_color = ItemBox.BRAND_CHIP
		chip.set_corner_radius_all(roundi(size.x * 0.18))
		draw_style_box(chip, Rect2(Vector2.ZERO, size))
		if item != null:
			PowerUpArt.draw_into(self, Rect2(size * 0.1, size * 0.8), item.id, item.color)
			return
		var height := roundi(size.y * 0.8)
		# Stood on a baseline that puts its middle on the chip's.
		var baseline := Vector2(0.0, size.y * 0.5 + height * 0.36)
		draw_string(
			Type.DISPLAY,
			baseline,
			"?",
			HORIZONTAL_ALIGNMENT_CENTER,
			size.x,
			height,
			Palette.CHIP_WHITE
		)
