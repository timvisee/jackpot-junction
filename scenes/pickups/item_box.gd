class_name ItemBox
extends Pickup
## A power-up on the floor: a glowing, pulsing crate with a big question mark and a beam of light,
## so it stands out from the pads and chips. From a pad it holds a whole table and decides the item
## when taken, like a roulette; dropped on death it holds one fixed item, and wears it, GAME.md
## 8.3a: the item's own picture over the crate where the question mark would be, and branded on
## its top and sides. Karts already holding an item cannot take it.

## How big the picture of a dropped box's item is rendered, how big it hangs over the crate, how
## big it is branded on each face and how far out from the middle, just clear of the bands, and
## the chip it sits on.
const BRAND_PIXELS := 128
const SIGN_SIZE := 0.8
const BRAND_SIZE := 0.42
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
	if fixed_item != null:
		_brand(parent)
	else:
		_question_mark(parent)
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


## The big question mark over a box from a pad: what comes out of it is anybody's guess.
func _question_mark(parent: Node3D) -> void:
	var mark := Label3D.new()
	mark.text = "?"
	mark.font_size = 120
	mark.outline_size = 20
	mark.modulate = Palette.CHIP_WHITE
	mark.outline_modulate = Color(0.05, 0.05, 0.06)
	mark.pixel_size = 0.01
	mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mark.no_depth_test = true
	mark.position = Vector3(0.0, 1.15, 0.0)
	parent.add_child(mark)


## The item a dropped box holds, pictured over it and on its top and four sides. The picture is
## drawn once into a texture, the way the hints in the world are, and kept in [param parent] so it
## goes with the look into the kart that takes the box.
func _brand(parent: Node3D) -> void:
	var render := SubViewport.new()
	render.name = "Brand"
	render.transparent_bg = true
	render.disable_3d = true
	render.gui_disable_input = true
	render.size = Vector2i.ONE * BRAND_PIXELS
	render.render_target_update_mode = SubViewport.UPDATE_ONCE
	var badge := Badge.new()
	badge.item = fixed_item
	badge.size = Vector2.ONE * BRAND_PIXELS
	render.add_child(badge)
	# Drawn again should it be moved, as the look is into the kart taking the box.
	render.tree_entered.connect(
		func() -> void: render.render_target_update_mode = SubViewport.UPDATE_ONCE
	)
	parent.add_child(render)
	var picture := render.get_texture()
	var over := Sprite3D.new()
	over.name = "Sign"
	over.texture = picture
	over.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	over.no_depth_test = true
	over.shaded = false
	over.double_sided = true
	over.pixel_size = SIGN_SIZE / BRAND_PIXELS
	over.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	over.position = Vector3(0.0, 1.15, 0.0)
	# Over the beam of light it hangs in, which would tint it its own color.
	over.render_priority = 1
	parent.add_child(over)
	var ink := StandardMaterial3D.new()
	ink.albedo_texture = picture
	ink.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var face := QuadMesh.new()
	face.size = Vector2.ONE * BRAND_SIZE
	for side: int in 5:
		var brand := MeshInstance3D.new()
		brand.name = "Side%d" % side
		brand.mesh = face
		brand.material_override = ink
		brand.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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


## A dropped box's item, pictured on a dark chip so it reads against the box in its own color.
class Badge:
	extends Control

	var item: PowerUp

	func _draw() -> void:
		var chip := StyleBoxFlat.new()
		chip.bg_color = ItemBox.BRAND_CHIP
		chip.set_corner_radius_all(roundi(size.x * 0.18))
		draw_style_box(chip, Rect2(Vector2.ZERO, size))
		PowerUpArt.draw_into(self, Rect2(size * 0.1, size * 0.8), item.id, item.color)
