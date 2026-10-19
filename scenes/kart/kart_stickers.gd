class_name KartStickers
extends RefCounted
## The card suits paint, GAME.md 8.9: three stickers on a plain kart, a spade on its nose and a
## heart and a diamond on its sides, each a suit of the Royal Flush pads' on a cream disc. Suits
## printed all over the kart as a pattern were a blur: its parts are small and curved, and a suit
## on them was a few pixels wrapped round a corner.
##
## A sticker is laid on the body's own faces rather than floated over them on a card: the faces it
## falls on are copied a hair out from the body, its picture laid on them straight from the way it
## faces, so it bends over the nose's two slopes as a sticker would. Each body of
## [constant KartVisuals.BODIES] takes them where its own shell is, see [method _on_shell].

## The paint that wears them.
const PAINT := 4
## Each sticker in the body model's own space, where its nose is +Z and its left +X: where the
## middle of it is on the tin, which way it faces, which way its top is, how wide it is and its
## suit. The nose's lower slope, and the slanted outside of the pod either side between the
## wheels, which looks out and up at the camera: the flat panels beside the cockpit were behind
## the driver's legs and the front wheels.
const PLACES: Array[Array] = [
	[
		Vector3(0.0, 0.31, 0.73),
		Vector3(0.0, 0.6, 0.8),
		Vector3(0.0, 0.8, -0.6),
		0.22,
		SuitArt.Suit.SPADE,
	],
	[
		Vector3(0.425, 0.27, -0.01),
		Vector3(0.84, 0.54, 0.0),
		Vector3(-0.54, 0.84, 0.0),
		0.17,
		SuitArt.Suit.HEART,
	],
	[
		Vector3(-0.425, 0.27, -0.01),
		Vector3(-0.84, 0.54, 0.0),
		Vector3(0.54, 0.84, 0.0),
		0.17,
		SuitArt.Suit.DIAMOND,
	],
]
## How far in front of or behind a sticker's middle a face can be and still take it, and how
## squarely it must face the way the sticker does: enough for the nose's two slopes and a pod's
## bend, too little for the panel behind a pod or the far side of the kart.
const DEPTH := 0.1
const SQUARE := 0.3
## How far out from the body a sticker is laid, so it never flickers in and out of it.
const LIFT := 0.006
## Side of a sticker's picture in pixels, how far across it its disc and its suit reach, and the
## disc's ink rim, as shares of it.
const SIDE := 128
const DISC := 0.47
const RIM := 0.04
const SUIT := 0.56
const CREAM := Palette.CHIP_WHITE
const RED := Palette.MULT
const BLACK := HouseTheme.INK

## Each place's sticker, built once off each body's shell and worn by every kart of that body, by
## the shell's mesh, and each place's picture, worn on every body.
static var _shells: Dictionary[Mesh, Array] = {}
static var _skins: Array[StandardMaterial3D] = []


## Puts the stickers on [param model], a kart model made by [KartVisuals], or takes off the ones it
## wore if [param paint] is not the suits.
static func dress(model: Node3D, paint: int) -> void:
	var hull := _hull(model)
	if hull == null:
		return
	var old := hull.get_node_or_null("Stickers")
	if old != null:
		old.name = "StickersWorn"
		old.queue_free()
	if paint != PAINT:
		return
	var laid := _laid_on(hull)
	var stickers := Node3D.new()
	stickers.name = "Stickers"
	for i: int in laid.size():
		var sticker := MeshInstance3D.new()
		sticker.mesh = laid[i]
		sticker.material_override = _skins[i]
		sticker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		stickers.add_child(sticker)
	hull.add_child(stickers)


## The body of [param model]: the part that is neither a wheel nor its driver.
static func _hull(model: Node3D) -> MeshInstance3D:
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var lower := node.name.to_lower()
		if not lower.begins_with("wheel") and not lower.contains("character"):
			return node as MeshInstance3D
	return null


## The stickers of every place laid on [param hull], a body's shell, made the first time a kart of
## that body wears them.
static func _laid_on(hull: MeshInstance3D) -> Array:
	if _skins.is_empty():
		for place: Array in PLACES:
			_skins.append(_skin(place[4]))
	if not _shells.has(hull.mesh):
		var arrays := hull.mesh.surface_get_arrays(0)
		var laid: Array[ArrayMesh] = []
		for place: Array in PLACES:
			laid.append(_laid(arrays, place))
		_shells[hull.mesh] = laid
	return _shells[hull.mesh]


## The sticker of [param place] laid on the faces of [param arrays], a surface of the body.
static func _laid(arrays: Array, place: Array) -> ArrayMesh:
	var facing: Vector3 = place[1]
	var top: Vector3 = place[2]
	var size: float = place[3]
	var right := top.cross(facing)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var middle := _on_shell(verts, index, place[0], facing)
	var laid_verts := PackedVector3Array()
	var laid_normals := PackedVector3Array()
	var laid_uvs := PackedVector2Array()
	for i: int in range(0, index.size(), 3):
		var corners: Array[int] = [index[i], index[i + 1], index[i + 2]]
		var uvs: Array[Vector2] = []
		var near := false
		var square := 0.0
		for corner: int in corners:
			var from := verts[corner] - middle
			uvs.append(Vector2(from.dot(right), -from.dot(top)) / size + Vector2.ONE * 0.5)
			near = near or absf(from.dot(facing)) < DEPTH
			square += normals[corner].dot(facing) / 3.0
		if not near or square < SQUARE or not _overlaps(uvs):
			continue
		for k: int in 3:
			laid_verts.append(verts[corners[k]] + facing * LIFT)
			laid_normals.append(normals[corners[k]])
			laid_uvs.append(uvs[k])
	var surface := []
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = laid_verts
	surface[Mesh.ARRAY_NORMAL] = laid_normals
	surface[Mesh.ARRAY_TEX_UV] = laid_uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
	return mesh


## Where the line through [param middle] along [param facing] first meets the shell whose corners
## are [param verts], three to a face by [param index], coming from outside: the place a sticker
## meant for about there goes, on a body slimmer or fuller there than the tin. [param middle]
## itself where the line misses the shell.
static func _on_shell(
	verts: PackedVector3Array, index: PackedInt32Array, middle: Vector3, facing: Vector3
) -> Vector3:
	var from := middle + facing
	var found := middle
	var nearest := INF
	for i: int in range(0, index.size(), 3):
		var hit: Variant = Geometry3D.ray_intersects_triangle(
			from, -facing, verts[index[i]], verts[index[i + 1]], verts[index[i + 2]]
		)
		if hit != null and from.distance_to(hit) < nearest:
			nearest = from.distance_to(hit)
			found = hit
	return found


## Whether a face whose corners are at [param uvs] on a sticker's picture covers any of it.
static func _overlaps(uvs: Array[Vector2]) -> bool:
	var low := uvs[0].min(uvs[1]).min(uvs[2])
	var high := uvs[0].max(uvs[1]).max(uvs[2])
	return high.x > 0.0 and high.y > 0.0 and low.x < 1.0 and low.y < 1.0


## A sticker of [param suit] in the lacquer of the paint under it, cut to its disc.
static func _skin(suit: int) -> StandardMaterial3D:
	var skin := StandardMaterial3D.new()
	skin.albedo_texture = printed(suit)
	skin.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	skin.texture_repeat = false
	skin.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	skin.alpha_scissor_threshold = 0.5
	skin.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
	skin.roughness = 0.34
	skin.metallic_specular = 0.6
	skin.clearcoat_enabled = true
	skin.clearcoat = 0.55
	skin.clearcoat_roughness = 0.15
	return skin


## The picture of a sticker of [param suit], one of [enum SuitArt.Suit]: the suit in its card's
## red or black on a cream disc with an ink rim, see-through round it. Each pixel is four points
## of it, so an edge is clean rather than a staircase.
static func printed(suit: int) -> Texture2D:
	var image := Image.create_empty(SIDE, SIDE, true, Image.FORMAT_RGBA8)
	var ink := RED if suit == SuitArt.Suit.HEART or suit == SuitArt.Suit.DIAMOND else BLACK
	var points: Array[Vector2] = [
		Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.25, 0.75), Vector2(0.75, 0.75)
	]
	for y: int in SIDE:
		for x: int in SIDE:
			var color := Color(0.0, 0.0, 0.0, 0.0)
			for point: Vector2 in points:
				color += _at(suit, ink, (Vector2(x, y) + point) / float(SIDE)) * 0.25
			image.set_pixel(x, y, color)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


## What a sticker of [param suit] is at [param at], across and down it from 0 to 1.
static func _at(suit: int, ink: Color, at: Vector2) -> Color:
	var out := at.distance_to(Vector2.ONE * 0.5)
	if out > DISC:
		# See-through, but the rim's color, so the disc's edge does not fade to black.
		return Color(BLACK, 0.0)
	if out > DISC - RIM:
		return BLACK
	return ink if in_suit(suit, (at - Vector2.ONE * 0.5) / SUIT + Vector2.ONE * 0.5) else CREAM


## Whether [param at], across and down a unit square, is inside [param suit] drawn in it.
static func in_suit(suit: int, at: Vector2) -> bool:
	if at.x < 0.0 or at.y < 0.0 or at.x > 1.0 or at.y > 1.0:
		return false
	return Geometry2D.is_point_in_polygon(at, SuitArt.outline(suit))
