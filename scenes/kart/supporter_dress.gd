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
	"House of cards": Vector2(0.84, 0.0),
	"Lucky cat": Vector2(0.72, 0.0),
	"Tip jar": Vector2(0.7, 0.0),
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
## The lantern, in meters, in a flag's space, where +x is back from the kart: its rod's wood, how
## far the rod stands up out of the kart and how far down into it, as a flag's pole does, how far
## its arm bends back from upright and how long the arm is; the cord, the paper lantern's radius,
## its paper's light, its ribs, the glow round it and the faint pool of its light on the felt,
## how far down the felt is, how big the pool and how strong; and how much it flares at a
## cash-out.
const ROD_WOOD := Color(0.35, 0.24, 0.14)
const ROD_RISE := 0.8
const ROD_ROOT := 0.5
const ARM_BEND := 50.0
const ARM_LONG := 0.42
const CORD := 0.096
const LANTERN_RADIUS := 0.16
const PAPER_LIT := 1.3
const RIBS := 6
const LANTERN_GLOW_SIZE := 0.8
const LANTERN_GLOW := 0.38
const FELT_BELOW := -0.7
const POOL_SIZE := 1.9
const POOL := 0.16
const LANTERN_FLARE := 0.6
## The pinwheel: its stick, how high its hub stands and how far back of the stick, its vanes' hues
## round the wheel, how long and wide each vane is and how far it is cupped to catch the wind.
const STICK := Color(0.95, 0.93, 0.88)
const HUB_HEIGHT := 0.45
const HUB_BACK := 0.04
const VANE_HUES: Array[float] = [0.0, 0.08, 0.15, 0.33, 0.58, 0.78]
const VANE := Vector2(0.2, 0.32)
const VANE_CUP := 28.0
## The warm light a lantern's color is lit toward.
const WARM := Color(1.0, 0.9, 0.7)

## The beam's fan and a soft round glow, each made once and shared.
static var _beam_mesh: ArrayMesh
static var _soft: GradientTexture2D


## Whether [param mesh] is a piece's light rather than its body, see [method light].
static func is_light(mesh: Node) -> bool:
	return mesh.has_meta(LIGHT)


## The hat of the pack called [param named], in [param color], the player's, as [method
## KartDress.hat] hangs a hat: on a node at the head, dropped onto it as far as [constant HATS]
## says, holding one cut to the helmet and worn at [constant KartDress.HAT_SCALE].
static func hat(named: String, color: Color) -> Node3D:
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
		"House of cards":
			SupporterFigures.house_of_cards(worn)
		"Lucky cat":
			SupporterFigures.lucky_cat(worn, color)
		"Tip jar":
			SupporterFigures.tip_jar(worn)
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


## The flag of the pack called [param named] on [param flown], a flag's node, in [param color]:
## what stands in the kart's back in place of a flag's pole and what hangs or turns on it.
static func flag(named: String, flown: Node3D, color: Color) -> Node3D:
	match named:
		"Lantern":
			lantern(flown, color)
		"Pinwheel":
			pinwheel(flown)
	return flown


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


## The lantern on [param flown]: a wooden rod standing in the kart's back as a flag's pole does,
## bent back over the tail, and from its tip on a short cord a paper lantern in [param color]
## glowing from inside, swinging as dice on a string do, see [DressSway], with a faint pool of its
## light on the felt under it; it flares at a cash-out and goes out at a death, see [DressLight].
static func lantern(flown: Node3D, color: Color) -> void:
	var wood := flat(ROD_WOOD)
	var rod := _frustum(0.024, 0.021, ROD_RISE + ROD_ROOT, ROD_WOOD, -ROD_ROOT)
	rod.material_override = wood
	flown.add_child(rod)
	var arm := Node3D.new()
	arm.name = "Arm"
	arm.position.y = ROD_RISE - 0.01
	arm.rotation_degrees.z = -ARM_BEND
	flown.add_child(arm)
	var reach := _frustum(0.021, 0.015, ARM_LONG, ROD_WOOD, 0.0)
	reach.material_override = wood
	arm.add_child(reach)
	var hang := Vector3(
		sin(deg_to_rad(ARM_BEND)) * ARM_LONG, ROD_RISE + cos(deg_to_rad(ARM_BEND)) * ARM_LONG, 0.0
	)
	var held := Node3D.new()
	held.name = "Lantern"
	held.position = hang
	flown.add_child(held)
	var cord := _frustum(0.004, 0.004, CORD, Color(0.18, 0.16, 0.15), -CORD)
	held.add_child(cord)
	var middle := Vector3(0.0, -CORD - 0.04 - LANTERN_RADIUS * 0.95, 0.0)
	var paper := MeshInstance3D.new()
	paper.name = "Paper"
	var round_paper := SphereMesh.new()
	round_paper.radius = LANTERN_RADIUS
	round_paper.height = LANTERN_RADIUS * 1.9
	round_paper.radial_segments = 20
	round_paper.rings = 10
	paper.mesh = round_paper
	var lit_paper := color.lerp(Color(1.0, 0.95, 0.85), 0.3)
	var lit := flat(lit_paper)
	lit.emission_enabled = true
	lit.emission = lit_paper
	lit.emission_energy_multiplier = PAPER_LIT
	paper.material_override = lit
	paper.position = middle
	held.add_child(paper)
	for i: int in RIBS:
		var along := (-0.75 + 1.5 * float(i) / float(RIBS - 1)) * LANTERN_RADIUS
		var out := sqrt(maxf(0.0, LANTERN_RADIUS * LANTERN_RADIUS - along * along)) + 0.004
		var rib := MeshInstance3D.new()
		var round_rib := TorusMesh.new()
		round_rib.inner_radius = out - 0.005
		round_rib.outer_radius = out + 0.005
		round_rib.rings = 20
		round_rib.ring_segments = 4
		rib.mesh = round_rib
		rib.material_override = flat(color.darkened(0.5))
		rib.position = middle + Vector3(0.0, along * 0.95, 0.0)
		held.add_child(rib)
	var cap := Color(0.15, 0.13, 0.12)
	held.add_child(_frustum(0.068, 0.056, 0.04, cap, middle.y + LANTERN_RADIUS * 0.95))
	held.add_child(_frustum(0.056, 0.068, 0.04, cap, middle.y - LANTERN_RADIUS * 0.95 - 0.04))
	var tassel_at := middle.y - LANTERN_RADIUS * 0.95 - 0.04 - 0.12
	held.add_child(_frustum(0.028, 0.008, 0.12, color.darkened(0.3), tassel_at))
	var warm := color.lerp(WARM, 0.5)
	var round_glow := glow(Color(warm, LANTERN_GLOW), LANTERN_GLOW_SIZE)
	round_glow.position = middle
	held.add_child(round_glow)
	var pool := _pool(Color(color.lerp(WARM, 0.4), POOL), POOL_SIZE)
	pool.position = Vector3(hang.x, FELT_BELOW, 0.0)
	flown.add_child(pool)
	var shine := DressLight.new()
	shine.name = "Shine"
	shine.flare = LANTERN_FLARE
	shine.shining = [paper, round_glow, pool]
	flown.add_child(shine)
	var sway := DressSway.new()
	sway.name = "Sway"
	sway.kind = DressSway.Kind.DICE
	sway.pivots = [held]
	flown.add_child(sway)


## The pinwheel on [param flown]: a white stick standing in the kart's back as a flag's pole does,
## and on it a paper wheel of six vanes in the colors of the spectrum, turned by the kart's speed
## until it is a pale disc, see [PinwheelSpin].
static func pinwheel(flown: Node3D) -> void:
	flown.add_child(_frustum(0.02, 0.02, HUB_HEIGHT + ROD_ROOT, STICK, -ROD_ROOT))
	var hub := Node3D.new()
	hub.name = "Hub"
	hub.position = Vector3(HUB_BACK, HUB_HEIGHT, 0.0)
	# The wheel faces the way the kart goes: its own z along the flag's x.
	hub.rotation_degrees.y = 90.0
	flown.add_child(hub)
	var pin := MeshInstance3D.new()
	var round_pin := SphereMesh.new()
	round_pin.radius = 0.04
	round_pin.height = 0.08
	round_pin.radial_segments = 10
	round_pin.rings = 5
	pin.mesh = round_pin
	pin.material_override = flat(STICK)
	hub.add_child(pin)
	var wheel := Node3D.new()
	wheel.name = "Wheel"
	hub.add_child(wheel)
	var vanes: Array[MeshInstance3D] = []
	for i: int in VANE_HUES.size():
		var turned := Node3D.new()
		turned.rotation.z = TAU * float(i) / float(VANE_HUES.size())
		wheel.add_child(turned)
		var vane := MeshInstance3D.new()
		var cut := PrismMesh.new()
		cut.size = Vector3(VANE.x, VANE.y, 0.008)
		cut.left_to_right = 0.0
		vane.mesh = cut
		var paper := flat(Color.from_hsv(VANE_HUES[i], 0.75, 0.95))
		paper.cull_mode = BaseMaterial3D.CULL_DISABLED
		paper.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		vane.material_override = paper
		vane.position = Vector3(VANE.x * 0.35, VANE.y * 0.53, 0.0)
		vane.rotation_degrees.y = VANE_CUP
		turned.add_child(vane)
		vanes.append(vane)
	var blur := MeshInstance3D.new()
	blur.name = "Blur"
	blur.mesh = PinwheelSpin.blur_mesh(VANE.y * 1.05)
	var smear := StandardMaterial3D.new()
	smear.vertex_color_use_as_albedo = true
	smear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smear.cull_mode = BaseMaterial3D.CULL_DISABLED
	smear.roughness = 0.6
	smear.albedo_color = Color(1.0, 1.0, 1.0, 0.0)
	blur.material_override = smear
	blur.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hub.add_child(blur)
	var spin := PinwheelSpin.new()
	spin.name = "Spin"
	spin.wheel = wheel
	spin.vanes = vanes
	spin.blur = blur
	flown.add_child(spin)


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


## A soft round pool of light lying flat, [param color] at its middle fading to nothing at its edge,
## [param size] across; marked as light.
static func _pool(color: Color, size: float) -> MeshInstance3D:
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	var mesh := MeshInstance3D.new()
	mesh.name = "Pool"
	mesh.mesh = plane
	var light_paint := added(color)
	light_paint.albedo_texture = _glow_texture()
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
