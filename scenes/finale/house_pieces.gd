class_name HousePieces
extends RefCounted
## The House's print in three dimensions, GAME.md 8.1a, for the party at the end of a Grand Prix,
## GAME.md 9.7: a ticket cut from its stock with its four corners punched, a hairline just inside
## an edge in the color of whatever it is about, and the House's rail, 8.1c, at any height, its dark
## stock printed with the microprint between foil hairlines under a cap of lit stock and a seal at
## each end of a run. Plain shapes in plain paint and the rail's own print, so the party draws only
## shaders the title's warm-up has compiled, GAME.md 10.7.

## Gold: the House's and nobody else's, GAME.md 8.1a.
const FOIL := Color("#F2C14E")
## The rail's parts, as [HouseRail] has them: how much of its height the cap takes and how far in
## from each side it stands, its hairlines, and the seal at a run's end and the widest rail that
## wears one.
const CAP := 0.12
const CAP_INSET := 0.07
const HAIRLINE_IN := 0.16
const HAIRLINE := 0.035
const SEAL := 0.36
const SEAL_WIDEST := 2.6
## The outline of a ticket is worked out by [method TicketStyle.outline] in the UI's pixels, which
## keeps a pixel of its own between its notches: it is worked out at this many to a meter.
const OUTLINE_SCALE := 100.0

## How much darker than its glow the paint of anything lit in a player's color is.
const LIT_SHADE := 0.45

static var _foil: StandardMaterial3D
static var _cap: StandardMaterial3D
## The rail's print, one for each height a rail is built at and where its foot is, see
## [method rail].
static var _prints: Dictionary[String, StandardMaterial3D] = {}
## Everything lit in a player's color, by color and strength, see [method lit].
static var _lights: Dictionary[String, StandardMaterial3D] = {}


## A ticket [param size] across and down, its corners punched [param notch] deep and a bite
## [param bite] deep out of either side [param bites] down from its top, cut [param thick] thick:
## lying face up round the origin with its top edge toward -z, as [method RoomStyle.cutout] cuts,
## and stood up facing +z by [method standing].
static func ticket(
	size: Vector2, notch: float, thick: float, bites := PackedFloat32Array(), bite := 0.0
) -> ArrayMesh:
	var scaled := PackedFloat32Array()
	for at: float in bites:
		scaled.append(at * OUTLINE_SCALE)
	var line := TicketStyle.outline(
		size * OUTLINE_SCALE, notch * OUTLINE_SCALE, scaled, bite * OUTLINE_SCALE
	)
	var centered := PackedVector2Array()
	for point: Vector2 in line:
		centered.append(point / OUTLINE_SCALE - size * 0.5)
	return RoomStyle.cutout(centered, thick)


## Where a piece built lying face up stands instead, facing +z with its middle at [param at]: the
## lying piece's -z goes up and its face comes toward the viewer.
static func standing(at: Vector3) -> Transform3D:
	return Transform3D(Basis(Vector3.RIGHT, PI * 0.5), at)


## A hairline [param line] wide round [param rect], in the plane of [param plane] lying face up,
## x across and y down it as z: four strips of [param skin] under [param into].
static func hairline(
	into: Node3D, rect: Rect2, line: float, skin: Material, plane: Transform3D
) -> void:
	var strips: Array[Rect2] = [
		Rect2(rect.position, Vector2(rect.size.x, line)),
		Rect2(rect.position + Vector2(0.0, rect.size.y - line), Vector2(rect.size.x, line)),
		Rect2(rect.position + Vector2(0.0, line), Vector2(line, rect.size.y - line * 2.0)),
		Rect2(
			rect.position + Vector2(rect.size.x - line, line),
			Vector2(line, rect.size.y - line * 2.0)
		),
	]
	for strip: Rect2 in strips:
		var center := strip.get_center()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(strip.size.x, 0.006, strip.size.y)
		var node := MeshInstance3D.new()
		node.mesh = mesh
		node.material_override = skin
		node.transform = plane * Transform3D(Basis.IDENTITY, Vector3(center.x, 0.0, center.y))
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		into.add_child(node)


## The House's rail of [param size] with its middle at [param at] under [param into], its foot
## [param foot] up in the world: as every table's edge is, scaled to its height, so its microprint
## stands as tall on it as on a table's and its hairlines where they are on one. [param grown] is
## how much bigger [param into] is drawn than its own meters, for a rail on something scaled up.
static func rail(into: Node3D, size: Vector3, at: Vector3, foot: float, grown := 1.0) -> void:
	_make()
	var cap_height := size.y * CAP
	var body := Vector3(size.x, size.y - cap_height, size.z)
	_box(into, body, _print(size.y * grown, foot), at + Vector3(0.0, -cap_height * 0.5, 0.0))
	var top := Vector3(size.x - CAP_INSET * 2.0, cap_height + 0.02, size.z - CAP_INSET * 2.0)
	_box(into, top, _cap, at + Vector3(0.0, size.y * 0.5 - cap_height * 0.5 - 0.01, 0.0))
	var along_x := size.x >= size.z
	var length := maxf(size.x, size.z) - CAP_INSET * 2.0
	var across := minf(size.x, size.z)
	var face := size.y * 0.5 + 0.004
	for side: float in [-1.0, 1.0]:
		var offset := side * (across * 0.5 - minf(HAIRLINE_IN, across * 0.3))
		var line := Vector3(length, 0.01, HAIRLINE) if along_x else Vector3(HAIRLINE, 0.01, length)
		var on := Vector3(0.0, face, offset) if along_x else Vector3(offset, face, 0.0)
		var hair := _box(into, line, _foil, at + on)
		hair.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if length > across * 2.0 and across <= SEAL_WIDEST:
		for end: float in [-1.0, 1.0]:
			var reach := end * (length * 0.5 - across * 0.5)
			var on := Vector3(reach, face, 0.0) if along_x else Vector3(0.0, face, reach)
			seal(into, across * SEAL, at + on)


## The House's seal in foil, [param radius] round, lying at [param at] under [param into].
static func seal(into: Node3D, radius: float, at: Vector3) -> MeshInstance3D:
	_make()
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.012
	disc.radial_segments = 24
	disc.rings = 1
	var node := MeshInstance3D.new()
	node.mesh = disc
	node.material_override = _foil
	node.position = at
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	into.add_child(node)
	return node


## A line of the House's condensed capitals lying on [param on] facing +z, [param lift] out from
## it, [param size] tall at the most and brought down to fit [param wide] across, in [param ink]:
## words on a sign rather than a label turned to the camera.
static func words(
	on: Node3D, text: String, size: float, wide: float, ink: Color, lift: float
) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font = Type.display_font()
	label.font_size = Billboard.FONT_SIZE
	var span := label.font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.font_size).x
	# A font's size is the height of its em, and a capital is about seven tenths of that.
	var em := size / Type.CAP_HEIGHT
	if span > 0.0:
		em = minf(em, wide * label.font_size / span)
	label.pixel_size = em / float(label.font_size)
	label.modulate = ink
	label.outline_size = 0
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.double_sided = false
	label.position = Vector3(0.0, 0.0, lift)
	on.add_child(label)
	return label


## Paint lit from inside in [param color] at [param energy], one for each color and strength, so
## everything lit alike is baked together. Its paint is the color a step darker, so it glows in its
## color rather than washing out to a pastel of it under the lights.
static func lit(color: Color, energy: float) -> StandardMaterial3D:
	var key := "%s:%.2f" % [color.to_html(false), energy]
	if not _lights.has(key):
		var glow := StandardMaterial3D.new()
		glow.albedo_color = color.darkened(LIT_SHADE)
		glow.emission_enabled = true
		glow.emission = color
		glow.emission_energy_multiplier = energy
		_lights[key] = glow
	return _lights[key]


## The House's foil, as its rail wears it.
static func foil() -> StandardMaterial3D:
	_make()
	return _foil


## The House's lit stock, the cap of its rail.
static func lit_stock() -> StandardMaterial3D:
	_make()
	return _cap


static func _box(into: Node3D, size: Vector3, skin: Material, at: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = skin
	node.position = at
	into.add_child(node)
	return node


## The rail's print for a rail [param height] tall with its foot [param foot] up in the world: laid
## on from the world as a table's rail's is, scaled so one run of it is the rail's height, and
## moved so a run starts at its foot. The same shader as the table's rail's, the scale and the
## offset being only numbers to it.
static func _print(height: float, foot: float) -> StandardMaterial3D:
	var key := "%.3f:%.3f" % [height, fposmod(foot / height, 1.0)]
	if _prints.has(key):
		return _prints[key]
	var scale := 1.0 / height
	var printed := StandardMaterial3D.new()
	printed.albedo_texture = HouseRail.PRINT
	printed.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	printed.uv1_triplanar = true
	printed.uv1_world_triplanar = true
	printed.uv1_triplanar_sharpness = 40.0
	printed.uv1_scale = Vector3(scale / HouseRail.RUN, scale, scale / HouseRail.RUN)
	printed.uv1_offset = Vector3(0.0, -foot * scale, 0.0)
	printed.roughness = 0.62
	printed.metallic_specular = 0.4
	_prints[key] = printed
	return printed


static func _make() -> void:
	if _foil != null:
		return
	_foil = StandardMaterial3D.new()
	_foil.albedo_color = FOIL
	_foil.metallic = 0.75
	_foil.roughness = 0.38
	_cap = StandardMaterial3D.new()
	_cap.albedo_color = Color("#27252F")
	_cap.roughness = 0.55
	_cap.metallic_specular = 0.45
