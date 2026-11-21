class_name SupporterDress
extends RefCounted
## The pieces of the Steam supporter pack, GAME.md 10.8, built as the rest of the dress is, see
## [KartDress], in a file of their own. A piece that gives off light draws it rather than lighting
## anything: fans and glows added over what is under them, fading out rather than ending, each
## marked as light, see [method is_light], so that a finish, a picture's framing and the picture
## itself leave it out.

## The lighthouse, in the measures a hat is cut in: how much smaller than those it is worn, its
## colors, its rock, the bands of its tower from the bottom up, each its radius at its foot and at
## its head, and how tall each is.
const LIGHTHOUSE_SIZE := 0.8
const TOWER_RED := Color(0.78, 0.13, 0.12)
const TOWER_WHITE := Color(0.95, 0.93, 0.88)
const IRON := Color(0.15, 0.15, 0.17)
const ROCK := Color(0.3, 0.3, 0.33)
const GLASS := Color(1.0, 0.95, 0.8, 0.35)
const LAMP := Color(1.0, 0.9, 0.62)
const BANDS: Array[Vector2] = [
	Vector2(0.29, 0.25), Vector2(0.25, 0.215), Vector2(0.215, 0.18), Vector2(0.18, 0.165)
]
const BAND_TALL := 0.13
const ROCK_TALL := 0.08
const GALLERY_TALL := 0.035
const LAMP_ROOM_TALL := 0.17
const CAP_TALL := 0.15
## How bright the lamp's bulb is, and how big and how strong the glow round it.
const BULB_GLOW := 3.0
const HALO_SIZE := 0.6
const HALO_STRENGTH := 0.6
## The beam, in meters: how far out it reaches, how far down it falls over that so that it ends at
## the felt, how wide it is at its far end, how strong at the lamp, its color, and how finely it is
## cut, along and across, for its fade to be smooth.
const BEAM_REACH := 4.2
const BEAM_DROP := 1.6
const BEAM_HALF := 0.95
const BEAM_STRENGTH := 0.55
const BEAM := Color(1.0, 0.93, 0.76)
const BEAM_ROWS := 12
const BEAM_COLUMNS := 14
## What a light is marked with, see [method is_light].
const LIGHT := &"supporter_light"
## Each of the pack's hats by name: how far above the head it reaches, and how far it is dropped
## onto it, in the measures a hat is cut in and the body's, as [constant KartDress.HAT_LIFT] and
## [constant KartDress.HAT_DROP] are for the rest.
const HATS: Dictionary[String, Vector2] = {
	"Lighthouse": Vector2(0.8, 0.02),
	"Halo": Vector2(0.5, 0.0),
}
## The halo, in the measures a hat is cut in: its ring's inner and outer radius, how high over the
## helmet it floats and how it is tipped, its warm white, never gold, which is Guardian Angel's
## halo, GAME.md 7.3; how bright, how big its faint glow is and how strong, and how much brighter
## it is at a cash-out.
const HALO_INNER := 0.308
const HALO_OUTER := 0.358
const HALO_HEIGHT := 0.36
const HALO_TIP := Vector3(-12.0, 0.0, 5.0)
const HALO_WHITE := Color(1.0, 0.95, 0.8)
const HALO_LIT := 1.1
const HALO_GLOW_SIZE := 1.0
const HALO_GLOW := 0.16
const HALO_FLARE := 0.5

## The beam's fan and a soft round glow, each made once and shared.
static var _beam_mesh: ArrayMesh
static var _soft: GradientTexture2D


## Whether [param mesh] is a piece's light rather than its body, see [method light].
static func is_light(mesh: Node) -> bool:
	return mesh.has_meta(LIGHT)


## The hat of the pack called [param named], as [method KartDress.hat] hangs a hat: on a node at
## the head, dropped onto it as far as [constant HATS] says, holding one cut to the helmet and worn
## at [constant KartDress.HAT_SCALE]. None of them takes the player's color, [param _color].
static func hat(named: String, _color: Color) -> Node3D:
	var hat_node := Node3D.new()
	hat_node.name = "Hat"
	hat_node.position = KartDress.HEAD - Vector3(0.0, HATS.get(named, Vector2.ZERO).y, 0.0)
	var worn := Node3D.new()
	worn.name = "Fit"
	worn.scale = Vector3.ONE * KartDress.HAT_SCALE
	hat_node.add_child(worn)
	match named:
		"Lighthouse":
			lighthouse(worn)
		"Halo":
			halo(worn)
	return hat_node


## How far above the head the pack's hat called [param named] reaches, in the measures it is cut
## in, so the roof marker can be lifted clear of it, as [constant KartDress.HAT_LIFT] says of the
## rest.
static func hat_lift(named: String) -> float:
	return HATS.get(named, Vector2.ZERO).x


## How far above the head hat [param index] of [constant KartStyle.HATS] reaches, in the measures it
## is cut in: the pack's as [constant HATS] says, and the rest as [constant KartDress.HAT_LIFT].
static func lift_of(index: int) -> float:
	if KartStyle.supporter(1, index):
		return hat_lift(KartStyle.HATS[index])
	return KartDress.HAT_LIFT[index]


## The lighthouse on [param worn], a hat's node cut to the helmet: a striped tower on its rock, an
## iron gallery, a lamp room of glass and a red cap, and the lamp turning in it with its beam, see
## [LighthouseLamp].
static func lighthouse(worn: Node3D) -> void:
	var tower := Node3D.new()
	tower.name = "Lighthouse"
	tower.scale = Vector3.ONE * LIGHTHOUSE_SIZE
	worn.add_child(tower)
	tower.add_child(_frustum(0.36, 0.34, ROCK_TALL, ROCK, 0.0))
	var y := ROCK_TALL
	for i: int in BANDS.size():
		var band := BANDS[i]
		tower.add_child(
			_frustum(band.x, band.y, BAND_TALL, TOWER_RED if i % 2 == 0 else TOWER_WHITE, y)
		)
		y += BAND_TALL
	tower.add_child(_frustum(0.25, 0.25, GALLERY_TALL, IRON, y))
	var rail := MeshInstance3D.new()
	var round_rail := TorusMesh.new()
	round_rail.inner_radius = 0.215
	round_rail.outer_radius = 0.235
	round_rail.rings = 24
	round_rail.ring_segments = 6
	rail.mesh = round_rail
	rail.material_override = flat(IRON)
	rail.position.y = y + 0.09
	tower.add_child(rail)
	y += GALLERY_TALL
	var room := _frustum(0.14, 0.14, LAMP_ROOM_TALL, Color.WHITE, y)
	var pane := StandardMaterial3D.new()
	pane.albedo_color = GLASS
	pane.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pane.roughness = 0.05
	pane.cull_mode = BaseMaterial3D.CULL_DISABLED
	room.material_override = pane
	room.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tower.add_child(room)
	var head := Node3D.new()
	head.name = "Lamp"
	head.position.y = y + LAMP_ROOM_TALL * 0.5
	tower.add_child(head)
	var bulb := MeshInstance3D.new()
	var round_bulb := SphereMesh.new()
	round_bulb.radius = 0.085
	round_bulb.height = 0.17
	round_bulb.radial_segments = 16
	round_bulb.rings = 8
	bulb.mesh = round_bulb
	var lit := flat(LAMP)
	lit.emission_enabled = true
	lit.emission = LAMP
	lit.emission_energy_multiplier = BULB_GLOW
	bulb.material_override = lit
	head.add_child(bulb)
	var halo := glow(Color(LAMP, HALO_STRENGTH), HALO_SIZE)
	head.add_child(halo)
	# The beam is cut in meters, so it hangs off a node that undoes the hat's own scale.
	var unscaled := Node3D.new()
	unscaled.scale = Vector3.ONE / (KartDress.HAT_SCALE * LIGHTHOUSE_SIZE)
	head.add_child(unscaled)
	var beam := MeshInstance3D.new()
	beam.name = "Beam"
	beam.mesh = _beam()
	beam.material_override = added(Color(1.0, 1.0, 1.0, 1.0))
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.set_meta(LIGHT, true)
	unscaled.add_child(beam)
	y += LAMP_ROOM_TALL
	tower.add_child(_frustum(0.17, 0.02, CAP_TALL, TOWER_RED, y))
	var finial := MeshInstance3D.new()
	var round_top := SphereMesh.new()
	round_top.radius = 0.03
	round_top.height = 0.06
	round_top.radial_segments = 8
	round_top.rings = 4
	finial.mesh = round_top
	finial.material_override = flat(IRON)
	finial.position.y = y + CAP_TALL + 0.02
	tower.add_child(finial)
	var lamp := LighthouseLamp.new()
	lamp.name = "Turn"
	lamp.head = head
	lamp.beam = beam
	lamp.bulb = bulb
	lamp.halo = halo
	tower.add_child(lamp)


## The halo on [param worn]: a fine ring of warm white light floating just over the helmet, a little
## tipped, with a faint glow round it; brighter at a cash-out, see [DressLight].
static func halo(worn: Node3D) -> void:
	var ring := MeshInstance3D.new()
	ring.name = "Halo"
	var round_ring := TorusMesh.new()
	round_ring.inner_radius = HALO_INNER
	round_ring.outer_radius = HALO_OUTER
	round_ring.rings = 48
	round_ring.ring_segments = 8
	ring.mesh = round_ring
	var lit := flat(HALO_WHITE)
	lit.emission_enabled = true
	lit.emission = HALO_WHITE
	lit.emission_energy_multiplier = HALO_LIT
	ring.material_override = lit
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.position.y = HALO_HEIGHT
	ring.rotation_degrees = HALO_TIP
	worn.add_child(ring)
	var round_glow := glow(Color(HALO_WHITE, HALO_GLOW), HALO_GLOW_SIZE)
	round_glow.position.y = HALO_HEIGHT
	worn.add_child(round_glow)
	var shine := DressLight.new()
	shine.name = "Shine"
	shine.flare = HALO_FLARE
	shine.shining = [ring, round_glow]
	worn.add_child(shine)


## A soft round glow, [param color] at its middle fading to nothing at its edge, [param size]
## across, always facing the camera; marked as light.
static func glow(color: Color, size: float) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var mesh := MeshInstance3D.new()
	mesh.mesh = quad
	var light_paint := added(color)
	light_paint.albedo_texture = _glow_texture()
	light_paint.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mesh.material_override = light_paint
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.set_meta(LIGHT, true)
	return mesh


## The beam: a fan from the lamp out along -z and down to the felt, its light at its strongest a
## little way out from the lamp and fading to nothing at its far end and at its edges, so it has
## no end to it, only less of it; carried in the colors of its corners, so the fade costs nothing.
static func _beam() -> ArrayMesh:
	if _beam_mesh != null:
		return _beam_mesh
	var far := Vector3(0.0, -BEAM_DROP, -BEAM_REACH)
	var side := Vector3.RIGHT
	var cut := SurfaceTool.new()
	cut.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row: int in BEAM_ROWS:
		for column: int in BEAM_COLUMNS:
			var near_along := float(row) / BEAM_ROWS
			var far_along := float(row + 1) / BEAM_ROWS
			var left := float(column) / BEAM_COLUMNS * 2.0 - 1.0
			var right := float(column + 1) / BEAM_COLUMNS * 2.0 - 1.0
			for corner: Vector2 in [
				Vector2(near_along, left),
				Vector2(far_along, left),
				Vector2(far_along, right),
				Vector2(near_along, left),
				Vector2(far_along, right),
				Vector2(near_along, right),
			]:
				var along := corner.x
				var across := corner.y
				var strength := (
					BEAM_STRENGTH
					* pow(1.0 - along, 1.7)
					* pow(1.0 - across * across, 1.6)
					* smoothstep(0.0, 0.08, along)
				)
				cut.set_color(Color(BEAM, strength))
				cut.add_vertex(far * along + side * (across * BEAM_HALF * along))
	_beam_mesh = cut.commit()
	return _beam_mesh


## Light added over what is under it: no shading, no shadow, nothing written to the depth, seen from
## both sides, in [param color] times the colors of its corners.
static func added(color: Color) -> StandardMaterial3D:
	var light_paint := StandardMaterial3D.new()
	light_paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	light_paint.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	light_paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	light_paint.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	light_paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	light_paint.vertex_color_use_as_albedo = true
	light_paint.albedo_color = color
	return light_paint


static func _glow_texture() -> GradientTexture2D:
	if _soft != null:
		return _soft
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	fade.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	fade.add_point(0.35, Color(1.0, 1.0, 1.0, 0.45))
	_soft = GradientTexture2D.new()
	_soft.gradient = fade
	_soft.fill = GradientTexture2D.FILL_RADIAL
	_soft.fill_from = Vector2(0.5, 0.5)
	_soft.fill_to = Vector2(1.0, 0.5)
	_soft.width = 64
	_soft.height = 64
	return _soft


## A cone cut short, [param bottom] across at its foot and [param top] at its head, [param tall],
## standing on [param lift].
static func _frustum(
	bottom: float, top: float, tall: float, color: Color, lift: float
) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = tall
	mesh.radial_segments = 18
	mesh.rings = 1
	node.mesh = mesh
	node.material_override = flat(color)
	node.position.y = lift + tall * 0.5
	return node


## The flat paint every piece of dress is in, as [KartDress]'s.
static func flat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.62
	material.rim_enabled = true
	material.rim = 0.3
	return material
