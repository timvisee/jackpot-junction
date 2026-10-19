class_name SchoolStyle
extends RoomStyle
## The driving school, GAME.md 9.4a and STORY.md 6.7: the Department of Karts' road-safety mat, the
## clearest place in the game. The floor is a mat the Department printed, road gray on felt, with
## the roads marked on it, see [RoadMat]: lines along every kerb, a broken line down the middle of
## every road, a zebra crossing through every gate and bays to park in. A wall is a kerb, red and
## white stones round a grass verge; a box is one of the Department's crates with a warning sign on
## every face; a pit is a hole dug for roadworks, a pipe and a fallen barrier at the bottom of it
## and the barrier's red and white painted round its rim; and the Junction is a roundabout, a ring
## of red and white kerb stones with one of them green round its island, the arrows going round
## it. Round the mat a ring road, and cones and road signs on the green past it, see [RoadMat], in
## bright, clear daylight. Civic green and white, the Department's own, where the House prints in
## gold.

## The mat: its road gray, and how many meters one run of the felt it is printed on covers.
const ROAD := Color(0.28, 0.3, 0.32)
const FELT_TILE := 3.0
## The grass of the verges and the mat's margin, the Department's green, and the paint on the road.
const VERGE := Color(0.2, 0.39, 0.25)
const MARGIN := Color(0.19, 0.35, 0.23)
const PAINT := Color(0.94, 0.94, 0.9)
const DEPARTMENT := Color(0.15, 0.37, 0.26)
## A kerb: its red and its white, how long one stone is, how wide its top is round the verge and
## how far the verge stands over it.
const KERB_RED := Color(0.76, 0.22, 0.2)
const KERB_WHITE := Color(0.93, 0.92, 0.88)
const STONE := 0.625
const KERB_TOP := 0.3
const VERGE_OVER := 0.04
## How many pixels a side one run of the kerb's stones is drawn at: two stones each way.
const KERB_PIXELS := 64
## The warning sign on a crate, and how many pixels a side it is drawn at.
const SIGN_RED := Color("#C8362E")
const SIGN_WHITE := Color("#F6F3EC")
const SIGN_INK := Color("#17171A")
const SIGN_PIXELS := 128
## A pit dug for roadworks: its earth, its pipe and the barrier fallen into it.
const EARTH := Color(0.27, 0.19, 0.13)
const PIPE := Color(0.27, 0.33, 0.4)
const LAMP := Color(1.0, 0.72, 0.25)
## The arrows round the roundabout: how far round each runs and in how many strokes.
const ARROW_TURN := 0.55
const ARROW_STROKES := 5
## The orange of the cones by the roadside, [RoadMat].
const CONE := Color(0.94, 0.42, 0.1)

var _floor: StandardMaterial3D
var _margin: StandardMaterial3D
var _kerb: StandardMaterial3D
var _sign: StandardMaterial3D


## A kerb round a verge: red and white stones down every side and round the top, and the grass of
## the verge standing a hair over them in the middle. Inside the wall's box.
func wall(holder: Node3D, size: Vector3, _index: int) -> bool:
	var body := Vector3(size.x, size.y - VERGE_OVER, size.z)
	_box(holder, body, _kerb_stones(), Vector3(0.0, -VERGE_OVER * 0.5, 0.0))
	var inset := minf(KERB_TOP, minf(size.x, size.z) * 0.3)
	var verge := Vector3(size.x - inset * 2.0, VERGE_OVER + 0.03, size.z - inset * 2.0)
	_box(holder, verge, _grass(VERGE), Vector3(0.0, (size.y - verge.y) * 0.5, 0.0))
	return true


## One of the Department's crates: green, banded in white, with a warning sign on every face.
func crate(holder: Node3D, size: Vector3) -> bool:
	var body := size * Vector3(0.9, 0.86, 0.9)
	var foot := -size.y * 0.5
	_box(holder, body, surfaces.painted(DEPARTMENT), Vector3(0.0, foot + body.y * 0.5, 0.0))
	var white := surfaces.painted(PAINT)
	for y: float in [0.12, body.y - 0.12]:
		var band := Vector3(size.x * 0.92, 0.04, size.z * 0.92)
		_box(holder, band, white, Vector3(0.0, foot + y, 0.0))
	var lid := Vector3(size.x * 0.94, size.y * 0.1, size.z * 0.94)
	var lid_top := foot + body.y + lid.y - 0.02
	_box(
		holder,
		lid,
		surfaces.painted(DEPARTMENT.darkened(0.2)),
		Vector3(0.0, lid_top - lid.y * 0.5, 0.0)
	)
	var face := _sign_face()
	var side := minf(body.x, body.y) * 0.5
	var plate := QuadMesh.new()
	plate.size = Vector2(side, side)
	for turn: int in 4:
		var angle := PI * 0.5 * float(turn)
		var out := Vector3(sin(angle), 0.0, cos(angle))
		var shown := _put(holder, plate, face, out * (body.x * 0.5 + 0.005))
		shown.position.y = foot + body.y * 0.5
		shown.rotation.y = angle
	var top := QuadMesh.new()
	top.size = Vector2(side, side) * 1.2
	var on_top := _put(holder, top, face, Vector3(0.0, lid_top + 0.004, 0.0))
	on_top.rotation.x = -PI * 0.5
	holder.rotation.y = rng.randf_range(-0.04, 0.04)
	return true


## A hole dug for roadworks: earth at the bottom, a pipe across it, the barrier that stood round it
## fallen in, its lamp still lit, and the barrier's red and white painted round the rim.
func pit(into: Node3D, size: Vector2) -> bool:
	var depth := Arena.PIT_DEPTH
	for i: int in 5:
		var clod := Vector3(rng.randf_range(0.3, 0.6), 0.18, rng.randf_range(0.3, 0.5))
		var at := Vector3(
			rng.randf_range(-0.35, 0.35) * size.x,
			-depth + 0.09,
			rng.randf_range(-0.35, 0.35) * size.y
		)
		_box(into, clod, surfaces.painted(EARTH.darkened(0.2)), at).rotation.y = rng.randf_range(
			0.0, TAU
		)
	var pipe := _cylinder(
		into, 0.2, size.x, surfaces.painted(PIPE), Vector3(0.0, -depth + 0.4, -size.y * 0.05)
	)
	pipe.rotation.z = PI * 0.5
	# The barrier, fallen in across the hole: a striped board on its two feet, on its side.
	var board := Node3D.new()
	board.position = Vector3(0.0, -depth + 0.5, -size.y * 0.18)
	board.rotation = Vector3(0.0, 0.25, 0.32)
	into.add_child(board)
	var stripes := 6
	var long := minf(size.x, size.y) * 0.95
	for i: int in stripes:
		var ink := KERB_RED if i % 2 == 0 else KERB_WHITE
		var x := (float(i) + 0.5) * long / float(stripes) - long * 0.5
		_box(
			board,
			Vector3(long / float(stripes), 0.2, 0.05),
			surfaces.painted(ink),
			Vector3(x, 0.0, 0.0)
		)
	_box(board, Vector3(0.1, 0.12, 0.08), surfaces.neon(LAMP, 0.9), Vector3(long * 0.42, 0.16, 0.0))
	# The barrier's red and white round the top, painted on the mat.
	var band := 0.3
	for side: int in 4:
		var along := side % 2 == 0
		var span := (size.x + band * 2.0) if along else size.y
		var count := maxi(int(span / STONE), 2)
		for i: int in count:
			var offset := (float(i) + 0.5) * span / float(count) - span * 0.5
			var out := (
				((size.y if along else size.x) * 0.5 + band * 0.5) * (1.0 if side < 2 else -1.0)
			)
			var at := Vector3(offset, 0.006, out) if along else Vector3(out, 0.006, offset)
			var stone := (
				Vector3(span / float(count), 0.01, band)
				if along
				else Vector3(band, 0.01, span / float(count))
			)
			var ink := KERB_RED if i % 2 == 0 else KERB_WHITE
			_box(into, stone, surfaces.marking(ink), at)
	return true


## A roundabout: road round a ring of kerb stones, red and white with one of them green as a
## roulette wheel has its zero, a grass island inside them with a white bollard in the middle, and
## the arrows painted going round it.
func junction(into: Node3D, radius: float) -> bool:
	var lift := RoomKit.PAD
	var layer := RoomKit.LAYER
	_disc(into, radius, surfaces.marking(ROAD.darkened(0.08)), lift * 0.5, lift)
	var red := surfaces.marking(KERB_RED)
	var white := surfaces.marking(KERB_WHITE)
	var green := surfaces.marking(DEPARTMENT.lightened(0.15))
	var ring := radius * 0.52
	var deep := radius * 0.12
	for i: int in RoomKit.POCKETS:
		var turn := TAU * float(i) / float(RoomKit.POCKETS)
		var ink := green if i == 0 else (red if i % 2 == 1 else white)
		var up := lift + layer + (layer * 0.25 if i % 2 == 1 else 0.0)
		var wide := TAU * ring / float(RoomKit.POCKETS) * 1.1
		var at := Vector3(sin(turn), 0.0, cos(turn)) * ring + _up(up)
		_box(into, Vector3(wide, 0.012, deep), ink, at).rotation.y = turn
	_disc(into, ring - deep * 0.5, surfaces.marking(VERGE), lift + layer * 2.0)
	_disc(into, radius * 0.1, surfaces.marking(PAINT), lift + layer * 3.0, 0.03)
	# The arrows round the road between the stones and the rim, three of them, going round: a bent
	# shaft of short strokes along the lane and a head of two barbs at its end.
	var paint := surfaces.marking(PAINT)
	var lane := (ring + deep * 0.5 + radius - RoomKit.RIM) * 0.5
	var flat := _up(lift + layer * 2.0)
	for i: int in 3:
		var start := TAU * (float(i) + 0.1) / 3.0
		for k: int in ARROW_STROKES:
			var bit := start + (float(k) + 0.5) * ARROW_TURN / float(ARROW_STROKES)
			var piece := Vector3(lane * ARROW_TURN / float(ARROW_STROKES) * 1.15, 0.01, 0.1)
			_box(into, piece, paint, Vector3(sin(bit), 0.0, cos(bit)) * lane + flat).rotation.y = bit
		var end := start + ARROW_TURN
		var ahead := Vector3(cos(end), 0.0, -sin(end))
		var tip := Vector3(sin(end), 0.0, cos(end)) * lane + ahead * 0.16 + flat
		for side: float in [-1.0, 1.0]:
			var back := (-ahead).rotated(Vector3.UP, side * 0.6)
			var barb := _box(into, Vector3(0.36, 0.01, 0.1), paint, tip + back * 0.16)
			barb.rotation.y = atan2(-back.z, back.x)
	return true


## The Department's mat: road gray printed on felt.
func floor_top() -> StandardMaterial3D:
	if _floor == null:
		_floor = _felt(ROAD)
	return _floor


## The mat's margin round the arena, in the Department's green.
func surround() -> StandardMaterial3D:
	if _margin == null:
		_margin = _felt(MARGIN)
	return _margin


## The roads, the ring road and what stands on the green, see [RoadMat].
func room_round(props: RoomProps) -> bool:
	RoadMat.build(props, self)
	return true


## The House's layout in the Department's inks: green lines and pale green words.
func layout_inks() -> Array[Color]:
	return [Color(0.5, 0.74, 0.56), Color(0.8, 0.91, 0.82)]


## The kerb's stones, red and white, laid on in the world's meters so every kerb's stones fall on
## the grid's lines: along each side, and round the top a checker, which is the stones along its
## edges seen from above.
func _kerb_stones() -> StandardMaterial3D:
	if _kerb != null:
		return _kerb
	var side := KERB_PIXELS
	var image := Image.create_empty(side, side, false, Image.FORMAT_RGB8)
	var seam := KERB_WHITE.darkened(0.35)
	for y: int in side:
		for x: int in side:
			var red := (x < side / 2) != (y < side / 2)
			image.set_pixel(x, y, KERB_RED if red else KERB_WHITE)
	for at: int in [0, side / 2]:
		image.fill_rect(Rect2i(at, 0, 1, side), seam)
	image.generate_mipmaps()
	_kerb = StandardMaterial3D.new()
	_kerb.albedo_texture = ImageTexture.create_from_image(image)
	_kerb.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_kerb.uv1_triplanar = true
	_kerb.uv1_world_triplanar = true
	_kerb.uv1_triplanar_sharpness = 40.0
	# A stone each half of the picture; and the picture's height squeezed so far that the side of a
	# kerb, a meter up, is all one row of stones.
	_kerb.uv1_scale = Vector3(1.0 / (STONE * 2.0), 0.2, 1.0 / (STONE * 2.0))
	_kerb.roughness = 0.7
	_kerb.metallic_specular = 0.3
	return _kerb


## A warning sign, a red triangle on white with the mark under it, drawn once for every crate.
func _sign_face() -> StandardMaterial3D:
	if _sign != null:
		return _sign
	var side := SIGN_PIXELS
	var image := Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
	image.fill(Color(SIGN_WHITE, 0.0))
	var top := Vector2(side * 0.5, side * 0.08)
	var left := Vector2(side * 0.04, side * 0.9)
	var right := Vector2(side * 0.96, side * 0.9)
	for y: int in side:
		for x: int in side:
			var at := Vector2(x + 0.5, y + 0.5)
			var depth := _inside(at, top, left, right)
			if depth < 0.0:
				continue
			image.set_pixel(x, y, SIGN_RED if depth < side * 0.1 else SIGN_WHITE)
	# The mark: a bar and a dot.
	image.fill_rect(
		Rect2i(int(side * 0.46), int(side * 0.36), int(side * 0.08), int(side * 0.28)), SIGN_INK
	)
	image.fill_rect(
		Rect2i(int(side * 0.46), int(side * 0.7), int(side * 0.08), int(side * 0.08)), SIGN_INK
	)
	image.generate_mipmaps()
	# Worn as the road signs round the test route wear theirs, see [method DrawnTexture.decal].
	_sign = DrawnTexture.decal(ImageTexture.create_from_image(image))
	return _sign


## How far [param at] is inside the triangle [param a], [param b], [param c], in pixels from its
## nearest edge; below nought outside it.
static func _inside(at: Vector2, a: Vector2, b: Vector2, c: Vector2) -> float:
	var nearest := INF
	for edge: Array in [[a, b], [b, c], [c, a]]:
		var from: Vector2 = edge[0]
		var to: Vector2 = edge[1]
		var along := (to - from).normalized()
		var inward := Vector2(-along.y, along.x)
		# Every edge's inward side is toward the triangle's middle.
		if inward.dot((a + b + c) / 3.0 - from) < 0.0:
			inward = -inward
		nearest = minf(nearest, inward.dot(at - from))
	return nearest


## Felt in [param color], mapped off the slab's own meters, GAME.md 8.1.
func _felt(color: Color) -> StandardMaterial3D:
	var felt := StandardMaterial3D.new()
	felt.albedo_color = color
	felt.albedo_texture = Surfaces.FELT_ALBEDO
	felt.normal_enabled = true
	felt.normal_texture = Surfaces.FELT_NORMAL
	felt.normal_scale = 0.12
	felt.uv1_scale = Vector3.ONE / FELT_TILE
	felt.roughness = 0.94
	felt.metallic_specular = 0.15
	return felt


## Grass on a verge: the felt in [param color], laid on from above in the world's meters.
func _grass(color: Color) -> StandardMaterial3D:
	var grass := _felt(color)
	grass.uv1_triplanar = true
	grass.uv1_world_triplanar = true
	return grass


# --- the parts ---------------------------------------------------------------


func _up(lift: float) -> Vector3:
	return Vector3(0.0, lift, 0.0)


func _disc(
	into: Node3D, radius: float, skin: Material, lift: float, thick := 0.01
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = thick
	mesh.radial_segments = 48
	mesh.rings = 1
	return _put(into, mesh, skin, _up(lift))


func _box(into: Node3D, size: Vector3, skin: Material, at: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _put(into, mesh, skin, at)


func _cylinder(
	into: Node3D, radius: float, height: float, skin: Material, at: Vector3
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 1
	return _put(into, mesh, skin, at)


func _put(into: Node3D, mesh: Mesh, skin: Material, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = skin
	node.position = at
	into.add_child(node)
	return node
