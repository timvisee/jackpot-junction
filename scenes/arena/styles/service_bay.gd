class_name ServiceBay
extends RefCounted
## The room round the Garage's bay, GAME.md 8.1 and 9.4, for [GarageStyle]: the House's service bay,
## kept the way a bay is kept. Behind the table the tool wall a player sees every time they come in:
## a steel workbench under the big shadow board, a pair of red roll cabs either side of it under a
## board of their own, every tool on a board hung over its yellow outline and one outline empty, the
## House's soda machine at one end and the compressor at the other. Down the left racks of labeled
## parts bins and a rack of tires; down the right the kart up on its stands, its drums and the floor
## the test bench stands on, kept clear for it. A yellow walkway painted round the table, and on the
## near side only what lies flat: the box where the doors open, its word the House's, KEEP CLEAR,
## see [method GarageStyle.house_word], and an air line.
##
## Built through the room's [RoomProps] and its [RoomShell], so it is baked with them, and every
## piece is put down by hand: a bay is kept tidy, and what stands in it stands in rows.

## The tool wall: how far behind the table its front is, how long and deep a roll cab is and how
## tall, how wide the bench is and the height of its top.
const WALL_AT := 1.6
const CAB := Vector3(3.4, 2.5, 1.6)
const BENCH := Vector3(10.0, 2.4, 2.2)
## A shadow board: how tall, how high its foot is over the cabs and the bench, and how far it leans
## back, so its face looks up at the camera rather than past it.
const BOARD_TALL := 3.2
const BOARD_FOOT := 3.0
const BOARD_LEAN := 0.16
## How far apart the pegboard's holes are drawn, in meters, and how far out a tool's outline shows.
const HOLES := 0.2
const OUTLINE := 0.035
## The pegboard's black, the frame's red, a darker steel and the handles' inks.
const BOARD_INK := Color(0.11, 0.11, 0.12)
const FRAME := Color(0.6, 0.14, 0.11)
const DARK_STEEL := Color(0.3, 0.31, 0.34)
const CHROME := Color(0.84, 0.86, 0.9)
const HANDLE_RED := Color(0.72, 0.16, 0.13)
const HANDLE_YELLOW := Color(0.9, 0.7, 0.16)
const TIMBER := Color(0.6, 0.45, 0.3)
const DRUM := Color(0.22, 0.35, 0.44)
## The parts racks down the left: how big, how many shelves and how many bins to a shelf.
const RACK := Vector3(3.4, 5.0, 1.4)
const SHELVES := 4
const BINS := 4
## The walkway painted round the table: how far out from the edge of it and how wide its line is.
const WALKWAY := 1.0
const LINE := 0.14
## How long and deep the box painted on the near side, where the bay's doors open, is, and how far
## past the walkway its middle is.
const KEEP_CLEAR := 9.0
const NEAR_BOX_DEEP := 2.4
const NEAR_BOX_OUT := 2.2

var props: RoomProps
var shell: RoomShell
var surfaces: Surfaces
var style: GarageStyle
var half: Vector2

var _steel: Material
var _dark: Material
var _board_holes: StandardMaterial3D


## Builds the bay round [param in_props]'s table for [param for_style].
static func build(in_props: RoomProps, for_style: GarageStyle) -> void:
	var bay := ServiceBay.new()
	bay.props = in_props
	bay.shell = in_props.shell
	bay.surfaces = in_props.surfaces
	bay.style = for_style
	bay.half = in_props.arena.world_size() * 0.5
	bay._build()


func _build() -> void:
	# Right up to the table. The band the other rooms leave is the room the stands need, and with
	# nobody in here the crowd's patches go with it.
	props.clutter_from = 1.0
	props._boxes.clear()
	props._keep_the_floor()
	_steel = surfaces.metal(GarageStyle.STEEL)
	_dark = surfaces.painted(GarageStyle.DARK)
	var wall := shell.enclose(Color(0.13, 0.135, 0.15), Color(0.42, 0.45, 0.49), 3.0, 40.0)
	shell.facade(wall)
	shell.skirt(props.room.table.darkened(0.25), 2.6)
	_walkway()
	_tool_wall()
	# The House's soda machine, the compressor, the kart on its stands and the creeper, see
	# [GarageGear]: kept off the floor the test bench stands on.
	props._taken.append_array(GarageGear.add_to(props.arena, props).taken)
	_parts_side()
	_kart_side()
	_near_side()


# --- the tool wall -----------------------------------------------------------


## The wall behind the table: the bench in the middle under the big board, and a pair of roll cabs
## either side under a board each. One thing put down, since it stands as one.
func _tool_wall() -> void:
	var front := -(half.y + WALL_AT)
	var reach := BENCH.x * 0.5 + 0.8 + CAB.x * 2.0 + 0.1
	var deep := BENCH.z + 0.8
	var at := Vector3(0.0, RoomBuild.TOP, front - deep * 0.5)
	_place(&"tool_wall", Rect2(-reach, -deep * 0.5, reach * 2.0, deep), at, _build_tool_wall)


func _build_tool_wall(at: Vector3, _turn: float) -> void:
	var front := at.z + (BENCH.z + 0.8) * 0.5
	_bench(Vector3(0.0, RoomBuild.TOP, front - BENCH.z * 0.5))
	_board(Vector3(0.0, RoomBuild.TOP + BOARD_FOOT, front - BENCH.z - 0.2), BENCH.x - 0.4, 0)
	var pair := CAB.x * 2.0 + 0.1
	for side: float in [-1.0, 1.0]:
		var middle := side * (BENCH.x * 0.5 + 0.8 + pair * 0.5)
		for i: int in 2:
			var x := middle + (float(i) - 0.5) * (CAB.x + 0.1)
			_roll_cab(Vector3(x, RoomBuild.TOP, front - CAB.z * 0.5))
		var board_at := Vector3(middle, RoomBuild.TOP + BOARD_FOOT, front - CAB.z - 0.2)
		_board(board_at, pair - 0.4, 1 if side < 0.0 else 2)


## A roll cab: red drawers on castors, a rubber top and a steel handle along its side.
func _roll_cab(at: Vector3) -> void:
	var body := Vector3(CAB.x, CAB.y - 0.3, CAB.z)
	props._box(body, style.drawers(GarageStyle.CHEST), at + Vector3(0.0, 0.3 + body.y * 0.5, 0.0))
	props._box(
		Vector3(CAB.x + 0.06, 0.12, CAB.z + 0.06), _dark, at + Vector3(0.0, CAB.y + 0.06, 0.0)
	)
	props._box(
		Vector3(0.12, 0.12, CAB.z * 0.7), _steel, at + Vector3(CAB.x * 0.5 + 0.1, CAB.y - 0.4, 0.0)
	)
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			var castor := props._cylinder(
				0.15,
				0.14,
				_dark,
				at + Vector3(x * (CAB.x * 0.5 - 0.3), 0.15, z * (CAB.z * 0.5 - 0.25))
			)
			castor.rotation.x = PI * 0.5


## The workbench: a thick timber top on steel legs with a shelf under it, a vice on its left end
## and a few tins along the back.
func _bench(at: Vector3) -> void:
	var timber := surfaces.painted(TIMBER)
	props._box(Vector3(BENCH.x, 0.3, BENCH.z), timber, at + Vector3(0.0, BENCH.y - 0.15, 0.0))
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			var leg := (
				at
				+ Vector3(
					x * (BENCH.x * 0.5 - 0.3), (BENCH.y - 0.3) * 0.5, z * (BENCH.z * 0.5 - 0.2)
				)
			)
			props._box(Vector3(0.22, BENCH.y - 0.3, 0.22), _steel, leg)
	props._box(Vector3(BENCH.x - 0.6, 0.12, BENCH.z - 0.3), _steel, at + Vector3(0.0, 0.9, 0.0))
	var iron := surfaces.painted(Color(0.24, 0.26, 0.3))
	var vice := at + Vector3(-BENCH.x * 0.5 + 1.0, BENCH.y, 0.3)
	props._box(Vector3(1.0, 0.36, 1.2), iron, vice + Vector3(0.0, 0.18, 0.0))
	props._box(Vector3(0.9, 0.6, 0.3), iron, vice + Vector3(0.0, 0.62, -0.3))
	props._box(Vector3(0.9, 0.5, 0.3), iron, vice + Vector3(0.0, 0.58, 0.3))
	var screw := props._cylinder(0.08, 1.3, _steel, vice + Vector3(0.0, 0.6, 0.7))
	screw.rotation.x = PI * 0.5
	var tin := surfaces.painted(Color(0.78, 0.8, 0.84))
	for i: int in 3:
		props._cylinder(0.3, 0.6, tin, at + Vector3(1.6 + float(i) * 0.75, BENCH.y + 0.3, -0.5))


# --- the shadow boards -------------------------------------------------------


## A shadow board [param wide] across with its foot's middle at [param foot]: black pegboard in a
## red frame, leaning back, every tool hung over its own yellow outline and one outline with
## nothing on it. [param kit] is which tools it holds: spanners over hammers and drivers, or the
## same the other way about, or the big tools.
func _board(foot: Vector3, wide: float, kit: int) -> void:
	var basis := Basis(Vector3.RIGHT, -BOARD_LEAN)
	var place := Transform3D(basis, foot)
	_on(place, Vector3(wide, BOARD_TALL, 0.1), _holes(), Vector2(0.0, BOARD_TALL * 0.5), 0.0)
	var frame := surfaces.painted(FRAME)
	for y: float in [0.0, BOARD_TALL]:
		_on(place, Vector3(wide + 0.3, 0.16, 0.18), frame, Vector2(0.0, y), 0.0)
	for x: float in [-1.0, 1.0]:
		_on(
			place,
			Vector3(0.16, BOARD_TALL, 0.18),
			frame,
			Vector2(x * (wide + 0.14) * 0.5, BOARD_TALL * 0.5),
			0.0
		)
	# The uprights it stands on, down to the floor behind whatever is under it.
	for x: float in [-1.0, 1.0]:
		var post := foot + Vector3(x * wide * 0.42, -BOARD_FOOT * 0.5, -0.1)
		props._box(Vector3(0.14, BOARD_FOOT, 0.14), _steel, post)
	var rows: Array = [_spanners(wide), _hand_tools(wide, kit)]
	if kit == 2:
		rows.reverse()
	var heights: Array[float] = [BOARD_TALL * 0.66, BOARD_TALL * 0.24]
	var empty := 2 + kit
	var count := 0
	for row: int in 2:
		for tool: Array in rows[row]:
			_tool(place, tool[0], heights[row], tool[1], count == empty)
			count += 1


## The spanners along a board: a row of them graduated small to big, each hung by its ring.
func _spanners(wide: float) -> Array:
	var out: Array = []
	var count := maxi(int((wide - 0.6) / 0.62), 3)
	for i: int in count:
		var size := 0.55 + float(i) / float(count - 1) * 0.5
		var x := (float(i) - float(count - 1) * 0.5) * (wide - 0.8) / float(count - 1)
		(
			out
			. append(
				[
					x,
					[
						[Vector2(0.0, 0.0), Vector2(0.09, size), 0.0, CHROME],
						[Vector2(0.0, size * 0.5), Vector2(0.26, 0.2), 0.0, CHROME],
						[Vector2(0.0, -size * 0.5), Vector2(0.28, 0.14), 0.0, CHROME],
					]
				]
			)
		)
	return out


## The hand tools along a board: hammers, screwdrivers, pliers and a saw, in turn.
func _hand_tools(wide: float, kit: int) -> Array:
	var kinds: Array = [
		# A hammer: its handle, and the head across the top of it.
		[
			[Vector2(0.0, 0.0), Vector2(0.11, 0.9), 0.0, TIMBER],
			[Vector2(0.0, 0.48), Vector2(0.5, 0.16), 0.0, DARK_STEEL],
		],
		# A screwdriver: a fat handle and a thin blade.
		[
			[Vector2(0.0, 0.26), Vector2(0.14, 0.36), 0.0, HANDLE_YELLOW],
			[Vector2(0.0, -0.2), Vector2(0.05, 0.56), 0.0, CHROME],
		],
		# Pliers: two handles spread apart under the jaws.
		[
			[Vector2(-0.08, -0.1), Vector2(0.08, 0.56), 0.22, HANDLE_RED],
			[Vector2(0.08, -0.1), Vector2(0.08, 0.56), -0.22, HANDLE_RED],
			[Vector2(0.0, 0.3), Vector2(0.12, 0.3), 0.0, DARK_STEEL],
		],
		# Another screwdriver, red.
		[
			[Vector2(0.0, 0.26), Vector2(0.14, 0.36), 0.0, HANDLE_RED],
			[Vector2(0.0, -0.2), Vector2(0.05, 0.56), 0.0, CHROME],
		],
	]
	if kit != 1:
		# A hacksaw: its frame and the blade along the foot of it.
		(
			kinds
			. append(
				[
					[Vector2(0.0, 0.18), Vector2(0.9, 0.08), 0.0, DARK_STEEL],
					[Vector2(-0.42, 0.0), Vector2(0.08, 0.42), 0.0, DARK_STEEL],
					[Vector2(0.0, -0.12), Vector2(0.86, 0.06), 0.0, CHROME],
					[Vector2(0.48, -0.04), Vector2(0.16, 0.34), 0.0, HANDLE_RED],
				]
			)
		)
	var out: Array = []
	var count := maxi(int((wide - 0.6) / 0.85), 3)
	for i: int in count:
		var x := (float(i) - float(count - 1) * 0.5) * (wide - 1.0) / float(count - 1)
		out.append([x, kinds[(i + kit) % kinds.size()]])
	return out


## One tool hung on a board at [param across] and [param up] from its foot, its [param pieces]
## over their yellow outline, or the outline alone if it is [param missing].
func _tool(place: Transform3D, across: float, up: float, pieces: Array, missing: bool) -> void:
	var outline := surfaces.painted(GarageStyle.SAFETY)
	for piece: Array in pieces:
		var at: Vector2 = piece[0] + Vector2(across, up)
		var size: Vector2 = piece[1]
		var turn: float = piece[2]
		var line := Vector3(size.x + OUTLINE * 2.0, size.y + OUTLINE * 2.0, 0.02)
		_on(place, line, outline, at, turn, 0.06)
		if missing:
			continue
		var ink: Color = piece[3]
		_on(place, Vector3(size.x, size.y, 0.06), surfaces.painted(ink), at, turn, 0.11)


## The pegboard: its black with a hole every [constant HOLES] meters, laid on from the front in the
## world's meters.
func _holes() -> StandardMaterial3D:
	if _board_holes != null:
		return _board_holes
	var side := 32
	var image := Image.create_empty(side, side, false, Image.FORMAT_RGB8)
	image.fill(BOARD_INK)
	var hole := BOARD_INK.darkened(0.7)
	image.fill_rect(Rect2i(side / 2 - 4, side / 2 - 4, 8, 8), hole)
	image.fill_rect(Rect2i(side / 2 - 5, side / 2 - 2, 10, 4), hole)
	image.fill_rect(Rect2i(side / 2 - 2, side / 2 - 5, 4, 10), hole)
	image.generate_mipmaps()
	_board_holes = StandardMaterial3D.new()
	_board_holes.albedo_texture = ImageTexture.create_from_image(image)
	# Laid on as the House's tin walls are, so it is a shader the warm-up has already compiled.
	_board_holes.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_board_holes.uv1_triplanar = true
	_board_holes.uv1_world_triplanar = true
	_board_holes.uv1_triplanar_sharpness = 40.0
	_board_holes.uv1_scale = Vector3.ONE / HOLES
	_board_holes.roughness = 0.8
	return _board_holes


## A box of [param size] on a board placed at [param place], its middle [param at] across and up
## the board's face, turned [param turn] in the board's plane and standing [param out] off it.
func _on(
	place: Transform3D, size: Vector3, skin: Material, at: Vector2, turn: float, out := 0.0
) -> MeshInstance3D:
	var part := props._box(size, skin, Vector3.ZERO)
	part.transform = place * Transform3D(Basis(Vector3.BACK, turn), Vector3(at.x, at.y, out))
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return part


# --- the sides ---------------------------------------------------------------


## Down the left: two racks of parts bins side by side facing the table, and a rack of tires
## behind them.
func _parts_side() -> void:
	var x := -(half.x + 1.4 + RACK.z * 0.5)
	var long := RACK.x * 2.0 + 0.4
	var at := Vector3(x, RoomBuild.TOP, -half.y * 0.55 + long * 0.5 - RACK.x * 0.5)
	var patch := Rect2(-long * 0.5, -RACK.z * 0.5, long, RACK.z)
	_place(&"parts_racks", patch, at, _parts_racks, PI * 0.5)
	var tires := Vector3(x - 1.0, RoomBuild.TOP, -half.y - 3.0)
	_place(&"tire_rack", Rect2(-3.6, -1.2, 7.2, 2.4), tires, _tire_rack, PI * 0.5)


func _parts_racks(at: Vector3, turn: float) -> void:
	var along := Basis(Vector3.UP, turn) * Vector3.RIGHT
	for side: float in [-1.0, 1.0]:
		_parts_rack(at + along * side * (RACK.x + 0.4) * 0.5, turn)


## A rack of parts bins: steel uprights and shelves, and on every shelf a row of bins, each with a
## white card on its front.
func _parts_rack(at: Vector3, turn: float) -> void:
	var basis := Basis(Vector3.UP, turn)
	var bins := surfaces.painted(GarageStyle.BIN)
	var card := surfaces.painted(GarageStyle.LABEL)
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			var post := Vector3(x * (RACK.x * 0.5 - 0.06), RACK.y * 0.5, z * (RACK.z * 0.5 - 0.06))
			props._box(Vector3(0.1, RACK.y, 0.1), _steel, at + basis * post)
	var shelf := (RACK.y - 0.3) / float(SHELVES)
	for level: int in SHELVES:
		var low := 0.25 + float(level) * shelf
		var plank := props._box(
			Vector3(RACK.x - 0.1, 0.06, RACK.z - 0.1), _steel, at + basis * Vector3(0.0, low, 0.0)
		)
		plank.basis = basis
		for i: int in BINS:
			var across := (float(i) - float(BINS - 1) * 0.5) * (RACK.x - 0.3) / float(BINS)
			var bin := Vector3((RACK.x - 0.5) / float(BINS), shelf * 0.62, RACK.z * 0.8)
			var spot := Vector3(across, low + 0.03 + bin.y * 0.5, 0.0)
			props._box(bin, bins, at + basis * spot).basis = basis
			var face := spot + Vector3(0.0, bin.y * 0.1, bin.z * 0.5 + 0.02)
			props._box(Vector3(bin.x * 0.55, bin.y * 0.34, 0.04), card, at + basis * face).basis = basis
	props._box(Vector3(RACK.x, 0.08, RACK.z), _steel, at + Vector3(0.0, RACK.y, 0.0)).basis = basis


## A rack of tires stood on their treads in a row between two steel ends.
func _tire_rack(at: Vector3, turn: float) -> void:
	var basis := Basis(Vector3.UP, turn)
	for x: float in [-1.0, 1.0]:
		props._box(Vector3(0.14, 2.2, 2.0), _steel, at + basis * Vector3(x * 3.4, 1.1, 0.0)).basis = basis
	for y: float in [0.3, 2.1]:
		props._box(Vector3(6.9, 0.1, 0.1), _steel, at + basis * Vector3(0.0, y, -0.8)).basis = basis
	for i: int in 6:
		var spot := at + basis * Vector3(-2.75 + float(i) * 1.1, 1.0, 0.0)
		var tire := props._cylinder(0.95, 0.7, _dark, spot)
		tire.basis = basis * Basis(Vector3.BACK, PI * 0.5)
		var hub := props._cylinder(0.45, 0.74, _steel, spot)
		hub.basis = tire.basis


## Down the right, past the test bench: a row of drums on a pallet.
func _kart_side() -> void:
	var at := Vector3(half.x + 6.0, RoomBuild.TOP, half.y * 0.15)
	_place(&"drums", Rect2(-1.2, -3.3, 2.4, 6.6), at, _drums)


func _drums(at: Vector3, _turn: float) -> void:
	var paint := surfaces.painted(DRUM)
	props._box(
		Vector3(2.4, 0.3, 6.6), surfaces.painted(TIMBER.darkened(0.2)), at + Vector3(0.0, 0.15, 0.0)
	)
	for i: int in 3:
		var foot := at + Vector3(0.0, 0.3, (float(i) - 1.0) * 2.15)
		props._cylinder(1.0, 2.6, paint, foot + Vector3(0.0, 1.3, 0.0))
		for y: float in [0.8, 1.8]:
			props._cylinder(1.05, 0.14, _steel, foot + Vector3(0.0, y, 0.0))


# --- the floor ---------------------------------------------------------------


## The walkway painted round the table on the workshop's floor, a yellow line all the way round.
func _walkway() -> void:
	var paint := surfaces.marking(GarageStyle.SAFETY)
	var out := half + Vector2.ONE * WALKWAY
	for side: float in [-1.0, 1.0]:
		shell._dim(
			shell._box(
				Vector3(out.x * 2.0 + LINE, 0.04, LINE),
				paint,
				Vector3(0.0, RoomBuild.TOP + 0.02, side * out.y)
			)
		)
		shell._dim(
			shell._box(
				Vector3(LINE, 0.04, out.y * 2.0),
				paint,
				Vector3(side * out.x, RoomBuild.TOP + 0.02, 0.0)
			)
		)


## The near side, where the camera looks across: only what lies flat on the floor, the box painted
## where the bay's doors open, and the air line coiled beside it.
func _near_side() -> void:
	var at := near_box(half)
	_keep_clear(at, Vector2(KEEP_CLEAR, NEAR_BOX_DEEP))
	_place(
		&"air_line",
		Rect2(-0.9, -0.9, 1.8, 1.8),
		at + Vector3(KEEP_CLEAR * 0.5 + 3.0, 0, 0),
		_air_line
	)


## Where the middle of the box on the near side is, on the floor, for a bay [param half_bay] across.
static func near_box(half_bay: Vector2) -> Vector3:
	return Vector3(0.0, RoomBuild.TOP, half_bay.y + WALKWAY + NEAR_BOX_OUT)


## A box of yellow paint on the floor, [param size] across, where nothing may be left: its outline
## here, and the word in it the House's, painted with the House's own, see [HouseWord].
func _keep_clear(at: Vector3, size: Vector2) -> void:
	var paint := surfaces.marking(GarageStyle.SAFETY)
	for side: float in [-1.0, 1.0]:
		var edge := Vector3(size.x + LINE, 0.04, LINE)
		shell._dim(shell._box(edge, paint, at + Vector3(0.0, 0.02, side * size.y * 0.5)))
		var end := Vector3(LINE, 0.04, size.y)
		shell._dim(shell._box(end, paint, at + Vector3(side * size.x * 0.5, 0.02, 0.0)))


## The air line, coiled on the floor.
func _air_line(at: Vector3, _turn: float) -> void:
	var red := surfaces.painted(GarageGear.HOSE_RED)
	for i: int in 3:
		var coil := TorusMesh.new()
		coil.inner_radius = 0.5 + float(i) * 0.06
		coil.outer_radius = 0.64 + float(i) * 0.06
		coil.rings = 18
		coil.ring_segments = 6
		props._put(coil, red, at + Vector3(0.0, 0.07 + float(i) * 0.12, 0.0))


# --- putting things down -----------------------------------------------------


## Puts [param build] down at [param at] turned [param turn], over [param patch] of the table in its
## own frame, as [method RoomProps._lay] puts down a kind it has measured: the patch is kept, so
## nothing dealt afterwards lands in it, and the parts are listed under it.
func _place(kind: StringName, patch: Rect2, at: Vector3, build: Callable, turn := 0.0) -> void:
	var box := props._ground(patch, at, turn)
	var from := props.get_child_count()
	build.call(at, turn)
	props._taken.append(box)
	props.laid_out.append(
		{"kind": kind, "box": box, "from": from, "to": props.get_child_count(), "turn": turn}
	)
