class_name GarageStyle
extends RoomStyle
## The Garage, GAME.md 8.1 and 9.4: the House's service bay, where its karts are fixed and dressed.
## The floor is rubber matting, interlocking tiles a meter square with fine ribs pressed into them;
## a wall is a run of steel tool cabinets under a rubber worktop, a box a red tool chest on its
## castors or a rack of labeled parts bins, a pit an inspection pit with a grate at its foot, a
## ladder down its far wall and a lamp hung in it, and the Junction a turntable with a roulette
## ring painted round its rim. Round the bay, see [ServiceBay]: red roll cabs under pegboard shadow
## boards, the House's soda machine, racks of parts and a tire rack, with walkways painted on the
## workshop's floor, all of it in a cool, even light. Nobody watches in here, so there is no crowd
## and no disco rig, 9.4; the Garage itself, the waiting room and the Showroom are in this room.

const RUBBER_ALBEDO := preload("res://assets/textures/rubber_albedo.png")
const RUBBER_NORMAL := preload("res://assets/textures/rubber_normal.png")
## How many meters one run of the rubber's texture covers: two of its tiles a side.
const RUBBER_TILE := 2.0
const RUBBER := Color(0.27, 0.28, 0.3)
## The tool cabinets a wall is made of: their steel, the pulls on their drawers, the rubber on
## their top, how long one cabinet is, so its seams fall between the grid's cells, and how deep the
## worktop is and how far in from the cabinet's sides.
const CABINET := Color(0.33, 0.39, 0.46)
const PULL := Color(0.8, 0.82, 0.86)
const WORKTOP := Color(0.15, 0.16, 0.17)
const MODULE := 1.25
const WORKTOP_DEEP := 0.09
const WORKTOP_INSET := 0.04
## How many pixels a side one cabinet's drawers are drawn at.
const DRAWER_PIXELS := 128
## Where the drawers of a cabinet part, down from its top as a share of a meter, the last over the
## kick plate at its foot.
const DRAWER_ROWS: Array[float] = [0.05, 0.23, 0.43, 0.65, 0.88]
## The drawers down the front of a red tool chest and of a roll cab, top to bottom, each a share of
## the front's height: shallow at the top for the small tools and deep at the foot, as a real cab's
## are. Drawn on the front alone, each with its handle; the sides and the top are plain steel.
const CHEST_DRAWERS: Array[float] = [0.28, 0.33, 0.39]
const CAB_DRAWERS: Array[float] = [0.17, 0.2, 0.27, 0.36]
## How far a drawer front stands off the steel behind it, and its handle off the front.
const FRONT_OFF := 0.006
const HANDLE_OFF := 0.03
## A tool chest's red, the parts bins' blue, the cards on them, steel and the dark of rubber.
const CHEST := Color(0.64, 0.15, 0.12)
const BIN := Color(0.29, 0.39, 0.51)
const LABEL := Color(0.93, 0.92, 0.87)
const STEEL := Color(0.64, 0.67, 0.71)
const DARK := Color(0.1, 0.1, 0.11)
## The lamp hung in a pit.
const LAMP := Color(1.0, 0.8, 0.46)
## The turntable: its pit ring, its deck, and the inks of the roulette ring painted round it.
const RING := Color(0.2, 0.21, 0.23)
const DECK := Color(0.52, 0.55, 0.59)
const POCKET_RED := Color(0.56, 0.13, 0.11)
const POCKET_BLACK := Color(0.1, 0.1, 0.11)
const POCKET_GREEN := Color(0.12, 0.42, 0.26)
## The safety yellow the bay's lines are painted in, the lift's own, see [KartLift].
const SAFETY := Color(0.92, 0.74, 0.16)

var _floor: StandardMaterial3D
## The cabinets' drawers, by the color of their steel, drawn once for the room.
var _drawer_looks: Dictionary[String, StandardMaterial3D] = {}
## The plain steel of a red cabinet's sides and the fronts of its drawers, by color and drawers.
var _plain_looks: Dictionary[String, StandardMaterial3D] = {}
var _front_looks: Dictionary[String, StandardMaterial3D] = {}


## A run of tool cabinets: the steel bodies with their drawers drawn on, seams between them on the
## grid's lines, under a rubber worktop set in from the edge. All inside the wall's box.
func wall(holder: Node3D, size: Vector3, _index: int) -> bool:
	var top := minf(WORKTOP_DEEP, size.y * 0.2)
	var body := Vector3(size.x, size.y - top, size.z)
	_box(holder, body, drawers(CABINET), Vector3(0.0, -top * 0.5, 0.0))
	var inset := minf(WORKTOP_INSET, minf(size.x, size.z) * 0.2)
	# Sunk a little into the cabinets, so no face of it lies in one of theirs.
	var worktop := Vector3(size.x - inset * 2.0, top + 0.02, size.z - inset * 2.0)
	_box(holder, worktop, surfaces.painted(WORKTOP), Vector3(0.0, (size.y - worktop.y) * 0.5, 0.0))
	return true


## A box in the bay is whatever has been wheeled out of the way: a red tool chest on its castors,
## or a steel rack of parts bins with a card on every bin.
func crate(holder: Node3D, size: Vector3) -> bool:
	if rng.randf() < 0.5:
		_tool_chest(holder, size)
	else:
		_parts_rack(holder, size)
	return true


## An inspection pit: a steel angle round its top just under the floor, a grate across its foot, a
## ladder down the far wall and a caged lamp hung on it. Nothing stands above the floor.
func pit(into: Node3D, size: Vector2) -> bool:
	var steel := surfaces.metal(STEEL)
	var dark := surfaces.painted(DARK.lightened(0.12))
	var depth := Arena.PIT_DEPTH
	var lip := 0.08
	for side: float in [-1.0, 1.0]:
		_box(
			into,
			Vector3(size.x, 0.06, lip),
			steel,
			Vector3(0.0, -0.035, side * (size.y - lip) * 0.5)
		)
		_box(
			into,
			Vector3(lip, 0.06, size.y),
			steel,
			Vector3(side * (size.x - lip) * 0.5, -0.035, 0.0)
		)
	# The grate: bearers across, and bars along them the width of a hand apart.
	var grate := -depth + 0.18
	for side: float in [-1.0, 1.0]:
		_box(
			into, Vector3(size.x - 0.04, 0.07, 0.06), dark, Vector3(0.0, grate, side * size.y * 0.3)
		)
	var bars := maxi(int(size.x / 0.17), 3)
	for i: int in bars:
		var x := (float(i) + 0.5) * size.x / float(bars) - size.x * 0.5
		_box(into, Vector3(0.045, 0.05, size.y - 0.04), steel, Vector3(x, grate + 0.06, 0.0))
	# The ladder down the far wall, which the camera looks at.
	var wall := -size.y * 0.5 + 0.05
	for side: float in [-1.0, 1.0]:
		_box(
			into, Vector3(0.05, depth - 0.1, 0.05), steel, Vector3(side * 0.22, -depth * 0.5, wall)
		)
	for i: int in 4:
		var y := -depth + 0.3 + float(i) * 0.2
		_box(into, Vector3(0.44, 0.035, 0.04), steel, Vector3(0.0, y, wall + 0.02))
	# A lamp in a cage, hung on the ladder's side, the one warm light in the bay.
	var lamp := Vector3(size.x * 0.28, -0.42, wall + 0.08)
	_box(into, Vector3(0.12, 0.2, 0.12), surfaces.neon(LAMP, 0.9), lamp)
	for side: float in [-1.0, 1.0]:
		_box(into, Vector3(0.02, 0.24, 0.16), steel, lamp + Vector3(side * 0.07, 0.0, 0.0))
	return true


## A turntable let into the floor, the kind a bay turns a kart round on: its ring, a roulette ring
## of red and black pockets painted round its rim with the green zero among them, and the steel deck
## inside that, its seams running out from a bolted hub. Two dark treads ran across the deck for
## the wheels, and the turntable reads cleaner without them.
func junction(into: Node3D, radius: float) -> bool:
	var lift := RoomKit.PAD
	var layer := RoomKit.LAYER
	_disc(into, radius, surfaces.metal(RING), lift * 0.5, lift)
	var red := surfaces.marking(POCKET_RED)
	var black := surfaces.marking(POCKET_BLACK)
	var green := surfaces.marking(POCKET_GREEN)
	var deep := radius * 0.3
	var out := radius - RoomKit.RIM - 0.08 - deep * 0.5
	for i: int in RoomKit.POCKETS:
		var turn := TAU * float(i) / float(RoomKit.POCKETS)
		var ink := green if i == 0 else (red if i % 2 == 1 else black)
		var up := lift + layer + (layer * 0.25 if i % 2 == 1 else 0.0)
		var wide := TAU * out / float(RoomKit.POCKETS) * 1.1
		var pocket := _box(
			into, Vector3(wide, 0.01, deep), ink, Vector3(sin(turn), 0.0, cos(turn)) * out + _up(up)
		)
		pocket.rotation.y = turn
	# The deck: steel, a hair proud of the ring round it.
	var deck := out - deep * 0.5 - 0.06
	_disc(into, deck, surfaces.metal(DECK), lift + layer * 2.0)
	var seam := surfaces.marking(RING.darkened(0.3))
	for i: int in 12:
		var turn := TAU * (float(i) + 0.5) / 12.0
		var bar := _box(
			into,
			Vector3(0.03, 0.01, deck * 0.7),
			seam,
			Vector3(sin(turn), 0.0, cos(turn)) * deck * 0.6 + _up(lift + layer * 3.0)
		)
		bar.rotation.y = turn
	_disc(into, radius * 0.13, surfaces.metal(STEEL), lift + layer * 5.0, 0.02)
	for i: int in 6:
		var turn := TAU * float(i) / 6.0
		var at := Vector3(sin(turn), 0.0, cos(turn)) * radius * 0.085
		_disc(into, radius * 0.018, surfaces.metal(DARK), lift + layer * 6.0, 0.02).position += at
	return true


## Rubber matting: tiles a meter square with their ribs turned a quarter from tile to tile.
func floor_top() -> StandardMaterial3D:
	if _floor != null:
		return _floor
	_floor = StandardMaterial3D.new()
	_floor.albedo_color = RUBBER
	_floor.albedo_texture = RUBBER_ALBEDO
	_floor.normal_enabled = true
	_floor.normal_texture = RUBBER_NORMAL
	_floor.normal_scale = 0.45
	_floor.uv1_scale = Vector3.ONE / RUBBER_TILE
	_floor.roughness = 0.9
	_floor.metallic_specular = 0.22
	return _floor


## The bay round the table, see [ServiceBay].
func room_round(props: RoomProps) -> bool:
	ServiceBay.build(props, self)
	return true


## The House's layout in the bay's own paint: safety yellow lines, and the words in white.
func layout_inks() -> Array[Color]:
	return [SAFETY, Color(0.86, 0.87, 0.88)]


## The steel of a tool cabinet in [param body], its drawers drawn on: a seam where one cabinet meets
## the next, the drawers with a pull across the top of each and a dark kick plate at the foot. Laid
## on from the side in the world's meters, a cabinet to a cell of the grid and a meter up, so every
## wall in the room has its drawers at the same height.
func drawers(body: Color) -> StandardMaterial3D:
	var key := body.to_html()
	if _drawer_looks.has(key):
		return _drawer_looks[key]
	var side := DRAWER_PIXELS
	var image := Image.create_empty(side, side, false, Image.FORMAT_RGB8)
	image.fill(body)
	var gap := body.darkened(0.55)
	var kick := int(DRAWER_ROWS[DRAWER_ROWS.size() - 1] * side)
	image.fill_rect(Rect2i(0, kick, side, side - kick), body.darkened(0.62))
	for i: int in DRAWER_ROWS.size():
		var y := int(DRAWER_ROWS[i] * side)
		image.fill_rect(Rect2i(0, y, side, 2), gap)
		if i < DRAWER_ROWS.size() - 1:
			image.fill_rect(Rect2i(int(side * 0.2), y + 6, int(side * 0.6), 3), PULL)
			image.fill_rect(Rect2i(int(side * 0.2), y + 9, int(side * 0.6), 1), gap)
	# Where one cabinet meets the next, and a little light down the edge of each.
	image.fill_rect(Rect2i(0, 0, 2, side), gap)
	image.fill_rect(Rect2i(2, 0, 1, kick), body.lightened(0.18))
	image.generate_mipmaps()
	var look := StandardMaterial3D.new()
	look.albedo_texture = ImageTexture.create_from_image(image)
	look.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	look.uv1_triplanar = true
	look.uv1_world_triplanar = true
	look.uv1_triplanar_sharpness = 40.0
	look.uv1_scale = Vector3(1.0 / MODULE, 1.0, 1.0 / MODULE)
	look.roughness = 0.5
	look.metallic = 0.25
	look.metallic_specular = 0.45
	_drawer_looks[key] = look
	return look


## The painted steel of a red cabinet, [param body], plain: its sides, top and back, which carry no
## drawers. The steel of [method drawers] without anything drawn on it.
func cabinet(body: Color) -> StandardMaterial3D:
	var key := body.to_html()
	if not _plain_looks.has(key):
		var look := StandardMaterial3D.new()
		look.albedo_color = body
		look.roughness = 0.5
		look.metallic = 0.25
		look.metallic_specular = 0.45
		_plain_looks[key] = look
	return _plain_looks[key]


## The drawers down the front of a red cabinet, [param width] across and [param height] tall with
## its middle at [param at] and facing +z in [param into]: one flat front with the drawers' seams
## drawn on it, [param rows] of them as shares of the height from the top, and a steel handle across
## the top of each. Drawn on the front alone, rather than laid on from the world as a wall's are:
## laid on every face, the drawers ran round the corners and down the sides, eight of them deep.
func drawer_front(
	into: Node3D, width: float, height: float, at: Vector3, rows: Array[float]
) -> void:
	var face := QuadMesh.new()
	face.size = Vector2(width, height)
	_put(into, face, _front(CHEST, rows), at + Vector3(0.0, 0.0, FRONT_OFF))
	# The pulls in the walls' own light steel, which reads on the red where polished steel took the
	# dark of the room and went gray.
	var steel := surfaces.painted(PULL)
	var top := at.y + height * 0.5
	for share: float in rows:
		var tall := share * height
		var grip := Vector3(width * 0.62, minf(0.06, tall * 0.14), 0.05)
		var lift := top - tall * 0.2
		_box(into, grip, steel, Vector3(at.x, lift, at.z + FRONT_OFF + HANDLE_OFF))
		top -= tall


## The drawn front of [method drawer_front]: [param body]'s steel with a dark seam round it and
## between the drawers, and a little light under each seam where a drawer's lip catches it.
func _front(body: Color, rows: Array[float]) -> StandardMaterial3D:
	var key := "%s %s" % [body.to_html(), str(rows)]
	if _front_looks.has(key):
		return _front_looks[key]
	var side := DRAWER_PIXELS
	var image := Image.create_empty(side, side, false, Image.FORMAT_RGB8)
	image.fill(body)
	var gap := body.darkened(0.55)
	var lip := body.lightened(0.16)
	var y := 0.0
	for share: float in rows:
		var row := int(roundf(y * side))
		image.fill_rect(Rect2i(0, row, side, 2), gap)
		image.fill_rect(Rect2i(2, row + 2, side - 4, 1), lip)
		y += share
	image.fill_rect(Rect2i(0, side - 2, side, 2), gap)
	image.fill_rect(Rect2i(0, 0, 2, side), gap)
	image.fill_rect(Rect2i(side - 2, 0, 2, side), gap)
	image.generate_mipmaps()
	var look := cabinet(body).duplicate() as StandardMaterial3D
	look.albedo_color = Color.WHITE
	look.albedo_texture = ImageTexture.create_from_image(image)
	look.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_front_looks[key] = look
	return look


# --- the boxes ---------------------------------------------------------------


## A red tool chest on four castors: its drawers, a lid a shade darker with a handle on it, and a
## handle on either end.
func _tool_chest(into: Node3D, size: Vector3) -> void:
	var foot := -size.y * 0.5
	var steel := surfaces.metal(STEEL)
	var rubber := surfaces.painted(DARK)
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			var castor := Vector3(x * size.x * 0.36, foot + 0.06, z * size.z * 0.34)
			_cylinder(into, 0.06, 0.12, rubber, castor).rotation.x = PI * 0.5
	var body := Vector3(size.x * 0.88, size.y * 0.72, size.z * 0.84)
	var low := foot + 0.12
	_box(into, body, cabinet(CHEST), Vector3(0.0, low + body.y * 0.5, 0.0))
	var front := Vector3(0.0, low + body.y * 0.5, body.z * 0.5)
	drawer_front(into, body.x - 0.04, body.y - 0.04, front, CHEST_DRAWERS)
	var lid := Vector3(size.x * 0.92, size.y * 0.1, size.z * 0.88)
	var lid_at := low + body.y + lid.y * 0.5 - 0.01
	_box(into, lid, surfaces.painted(CHEST.darkened(0.25)), Vector3(0.0, lid_at, 0.0))
	var handle := Vector3(size.x * 0.46, 0.04, 0.05)
	_box(into, handle, steel, Vector3(0.0, lid_at + lid.y * 0.5 + 0.02, 0.0))
	for side: float in [-1.0, 1.0]:
		var grip := Vector3(0.04, 0.05, size.z * 0.36)
		_box(into, grip, steel, Vector3(side * (size.x * 0.5 - 0.02), lid_at - 0.12, 0.0))
	into.rotation.y = rng.randf_range(-0.05, 0.05)


## A steel rack of parts bins: four posts, three shelves and a top, and on every shelf a row of
## bins two deep, each with a white card on its front.
func _parts_rack(into: Node3D, size: Vector3) -> void:
	var steel := surfaces.metal(STEEL)
	var bins := surfaces.painted(BIN)
	var card := surfaces.painted(LABEL)
	var half := size * 0.5
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			_box(
				into,
				Vector3(0.05, size.y, 0.05),
				steel,
				Vector3(x * (half.x - 0.03), 0.0, z * (half.z - 0.03))
			)
	var shelf := size.y / 3.0
	for level: int in 3:
		var floor_at := -half.y + float(level) * shelf
		_box(
			into,
			Vector3(size.x - 0.02, 0.03, size.z - 0.02),
			steel,
			Vector3(0.0, floor_at + 0.02, 0.0)
		)
		for x: float in [-1.0, 1.0]:
			for z: float in [-1.0, 1.0]:
				var bin := Vector3(size.x * 0.44, shelf * 0.72, size.z * 0.44)
				var at := Vector3(
					x * size.x * 0.235, floor_at + 0.035 + bin.y * 0.5, z * size.z * 0.235
				)
				_box(into, bin, bins, at)
				# The card on the face that looks out of the rack.
				var face := at + Vector3(0.0, bin.y * 0.08, z * (bin.z * 0.5 + 0.006))
				_box(into, Vector3(bin.x * 0.5, bin.y * 0.32, 0.012), card, face)
	_box(
		into, Vector3(size.x - 0.02, 0.03, size.z - 0.02), steel, Vector3(0.0, half.y - 0.015, 0.0)
	)


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
	mesh.radial_segments = 8
	mesh.rings = 1
	return _put(into, mesh, skin, at)


func _put(into: Node3D, mesh: Mesh, skin: Material, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = skin
	node.position = at
	into.add_child(node)
	return node


## The House's word, STORY.md 6.1, which here is the box's own: painted in the box on the near side
## of the bay where its doors open, in the walkway's yellow, see [ServiceBay].
func house_word(word: HouseWord, arena: Arena) -> bool:
	var at := ServiceBay.near_box(arena.world_size() * 0.5) + Vector3(0.0, 0.05, 0.0)
	var inside := Vector2(ServiceBay.KEEP_CLEAR, ServiceBay.NEAR_BOX_DEEP) - Vector2.ONE * 0.5
	word.lay(at, inside, SAFETY, HouseWord.Medium.PAINT, HouseWord.FLAT, HouseWord.STRETCH)
	return true
