class_name GarageRail
extends Node3D
## What stands on the Garage's rail, GAME.md 9.4: the slot machines along the far rail are in to
## be fixed, as a workshop's machines are, one with its door swung open and a toolbox beside it,
## another with OUT OF ORDER taped across its reels and a screwdriver left lying by a third; a
## workshop clock beside the Showroom's roller door, stopped, in the one room with no clock to
## keep; and a pegboard of tools on the rail behind the range, each tool hung over its own yellow
## outline and one outline with no tool on it.
##
## Scenery: it reads where the arena put things and decides nothing. The machines still light up
## and spin as the row does anywhere, see [RailMachines]; everything else never moves, and is
## baked into a mesh a material, GAME.md 10.7.

## Which machine along the rail gets what, by its place in [constant RailMachines.ALONG]: not the
## one right of the Showroom's door, which stands behind its frame and its sign.
const OPEN_MACHINE := 3
const TAGGED_MACHINE := 0
const SCREWDRIVER_MACHINE := 1
## How far the open machine's door is swung, in radians.
const DOOR_SWUNG := 1.75
## The tag taped across the reels: its size and how far it is turned in its own plane.
const TAG := Vector2(0.72, 0.3)
const TAG_TURN := -0.12
const TAG_WORDS := "OUT OF\nORDER"
const TAG_INK := Color(0.11, 0.11, 0.13)
const MANILA := Color(0.85, 0.75, 0.53)
const MASKING := Color(0.89, 0.85, 0.71)
## The toolbox, beside the open machine.
const TOOLBOX := Vector3(0.56, 0.26, 0.3)
const TOOLBOX_RED := Color(0.72, 0.13, 0.11)
## The clock: how big, how far it leans back toward the camera, and the time it stopped at, in
## hours and minutes and seconds, ten to two.
const CLOCK := 0.32
const CLOCK_LEAN := 0.18
const STOPPED := Vector3(1.0, 50.0, 37.0)
const CLOCK_FACE := Color(0.93, 0.92, 0.87)
const CLOCK_RIM := Color(0.08, 0.08, 0.09)
const SECOND_HAND := Color(0.82, 0.14, 0.12)
## The pegboard: how big at most, how far it leans back as the machines' faces do, how far apart
## its holes are, and how far its yellow outlines stand out round each tool.
const BOARD := Vector2(3.4, 1.2)
const BOARD_LEAN := 0.42
const HOLES := 0.15
const OUTLINE := 0.035
const BOARD_INK := Color(0.1, 0.1, 0.11)
const HOLE_INK := Color(0.03, 0.03, 0.035)
const FRAME_RED := Color(0.62, 0.13, 0.11)
## The tools on the board, each [where its middle is across the board, its pieces], a piece
## [middle, size, turn, ink] in the board's plane, meters from the board's foot in the middle. An
## empty list of pieces with only an outline is the one tool not on the board.
const STEEL := Color(0.74, 0.75, 0.79)
const DARK_STEEL := Color(0.3, 0.31, 0.34)
const HANDLE_RED := Color(0.75, 0.16, 0.13)
const HANDLE_YELLOW := Color(0.92, 0.72, 0.16)
const WOOD := Color(0.56, 0.39, 0.22)
const TOOLS: Array[Array] = [
	# A spanner.
	[
		-1.3,
		[
			[Vector2(0.0, 0.52), Vector2(0.06, 0.46), 0.0, STEEL],
			[Vector2(0.0, 0.8), Vector2(0.15, 0.1), 0.0, STEEL],
		],
	],
	# A hammer.
	[
		-0.65,
		[
			[Vector2(0.0, 0.5), Vector2(0.05, 0.42), 0.0, WOOD],
			[Vector2(0.0, 0.74), Vector2(0.24, 0.08), 0.0, DARK_STEEL],
		],
	],
	# A screwdriver.
	[
		0.0,
		[
			[Vector2(0.0, 0.72), Vector2(0.06, 0.16), 0.0, HANDLE_YELLOW],
			[Vector2(0.0, 0.5), Vector2(0.02, 0.28), 0.0, STEEL],
		],
	],
	# Pliers.
	[
		0.65,
		[
			[Vector2(-0.05, 0.48), Vector2(0.04, 0.3), 0.17, HANDLE_RED],
			[Vector2(0.05, 0.48), Vector2(0.04, 0.3), -0.17, HANDLE_RED],
			[Vector2(0.0, 0.7), Vector2(0.06, 0.14), 0.0, STEEL],
		],
	],
	# The big wrench, not back on the board: its outline alone.
	[
		1.3,
		[
			[Vector2(0.0, 0.5), Vector2(0.08, 0.5), 0.0, Color.TRANSPARENT],
			[Vector2(0.0, 0.82), Vector2(0.2, 0.12), 0.0, Color.TRANSPARENT],
		],
	],
]

## The pieces, for a test to find: the clock, the pegboard and the tag, each with nothing in it
## once baked but where it stands.
var clock: Node3D
var pegboard: Node3D
var tag: Node3D

var _arena: Arena
var _looks: Dictionary[Color, StandardMaterial3D] = {}


## Dresses the rail of [param in_match]'s room, the Garage's.
static func add_to(in_match: Match) -> GarageRail:
	var rail := GarageRail.new()
	rail.name = "GarageRail"
	rail._arena = in_match.arena
	in_match.arena.add_child(rail)
	rail._dress()
	return rail


func _dress() -> void:
	var machines := _arena.get_node_or_null("RailMachines") as RailMachines
	if machines != null:
		_machines(machines)
	var showroom := _arena.get_node_or_null("Showroom") as Showroom
	if showroom != null:
		_clock(showroom)
	if not _arena.targets.is_empty():
		_pegboard()
	if _arena.bake_scenery:
		Bake.merge(self)


# --- the machines --------------------------------------------------------------------------------


func _machines(machines: RailMachines) -> void:
	var spots := RailMachines.spots(_arena)
	if OPEN_MACHINE < spots.size():
		machines.swing_open(OPEN_MACHINE, DOOR_SWUNG)
		_toolbox(spots[OPEN_MACHINE] + Vector3(-RailMachines.BODY.x * 0.5 - 0.42, 0.0, 0.08))
	if TAGGED_MACHINE < spots.size():
		_tag(spots[TAGGED_MACHINE])
	if SCREWDRIVER_MACHINE < spots.size():
		_screwdriver(
			spots[SCREWDRIVER_MACHINE] + Vector3(RailMachines.BODY.x * 0.5 + 0.32, 0.0, 0.2)
		)


## OUT OF ORDER on a manila card taped across the reels of the machine standing at [param at],
## leant back with them toward the camera.
func _tag(at: Vector3) -> void:
	var body := RailMachines.BODY
	var lean := RailMachines.LEAN
	var out := Vector3(0.0, sin(lean), cos(lean))
	tag = Node3D.new()
	tag.name = "Tag"
	tag.position = at + Vector3(0.0, body.y * 0.62, body.z * 0.5 + 0.02) + out * 0.03
	tag.rotation = Vector3(-lean, 0.0, TAG_TURN)
	add_child(tag)
	tag.add_child(_box(Vector3(TAG.x, TAG.y, 0.008), MANILA, Vector3.ZERO))
	for side: float in [-1.0, 1.0]:
		var strip := _box(
			Vector3(0.16, 0.05, 0.01), MASKING, Vector3(side * TAG.x * 0.42, TAG.y * 0.5, 0.004)
		)
		strip.rotation.z = side * 0.6
		tag.add_child(strip)
	var words := Label3D.new()
	words.name = "Words"
	words.text = TAG_WORDS
	words.font = Type.mark_font()
	words.font_size = 64
	words.outline_size = 0
	words.line_spacing = -14.0
	words.pixel_size = 0.0021
	words.modulate = TAG_INK
	words.position = Vector3(0.0, 0.0, 0.008)
	tag.add_child(words)


## A red toolbox standing on the rail at [param at], its lid and handle.
func _toolbox(at: Vector3) -> void:
	var box := Node3D.new()
	box.name = "Toolbox"
	box.position = at
	box.rotation.y = 0.12
	add_child(box)
	box.add_child(_box(TOOLBOX, TOOLBOX_RED, Vector3(0.0, TOOLBOX.y * 0.5, 0.0)))
	var lid := Vector3(TOOLBOX.x + 0.02, 0.025, TOOLBOX.z + 0.02)
	box.add_child(_box(lid, TOOLBOX_RED.darkened(0.25), Vector3(0.0, TOOLBOX.y * 0.68, 0.0)))
	box.add_child(_box(Vector3(0.24, 0.03, 0.03), STEEL, Vector3(0.0, TOOLBOX.y + 0.05, 0.0)))
	for side: float in [-1.0, 1.0]:
		var post := Vector3(side * 0.11, TOOLBOX.y + 0.02, 0.0)
		box.add_child(_box(Vector3(0.025, 0.05, 0.025), STEEL, post))


## A screwdriver left lying on the rail at [param at].
func _screwdriver(at: Vector3) -> void:
	var tool := Node3D.new()
	tool.name = "Screwdriver"
	tool.position = at + Vector3(0.0, 0.035, 0.0)
	tool.rotation.y = 0.5
	add_child(tool)
	var handle := _cylinder(0.035, 0.15, HANDLE_YELLOW, Vector3(-0.08, 0.0, 0.0))
	handle.rotation.z = PI * 0.5
	tool.add_child(handle)
	var shaft := _cylinder(0.011, 0.2, STEEL, Vector3(0.09, 0.0, 0.0))
	shaft.rotation.z = PI * 0.5
	tool.add_child(shaft)


# --- the clock -----------------------------------------------------------------------------------


## The clock beside the Showroom's door, left of its frame at the height of its lintel, on a
## bracket off the frame, shut or open: where the door stands is the Showroom's, see [Showroom].
func _clock(showroom: Showroom) -> void:
	var grid := _arena.grid
	var row := Showroom.BAY if showroom.open else 0
	var left := grid.cell_center(Vector2i(Showroom.OPENING.x, row))
	var right := grid.cell_center(Vector2i(Showroom.OPENING.y - 1, row))
	var wide := right.x - left.x + grid.cell_size
	var middle := (left + right) * 0.5
	var frame := middle.x - wide * 0.5 - Showroom.FRAME - 0.04
	clock = Node3D.new()
	clock.name = "Clock"
	clock.position = Vector3(
		frame - 0.12 - CLOCK, Showroom.DOOR_TALL + 0.35, middle.z + grid.cell_size * 0.5 + 0.12
	)
	clock.rotation.x = -CLOCK_LEAN
	add_child(clock)
	# The bracket it hangs off, back to the frame.
	clock.add_child(_box(Vector3(0.18, 0.05, 0.05), CLOCK_RIM, Vector3(CLOCK + 0.07, 0.0, -0.04)))
	var face := _cylinder(CLOCK, 0.04, CLOCK_FACE, Vector3.ZERO)
	face.rotation.x = PI * 0.5
	clock.add_child(face)
	var rim := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = CLOCK - 0.01
	ring.outer_radius = CLOCK + 0.035
	ring.rings = 24
	ring.ring_segments = 8
	rim.mesh = ring
	rim.material_override = _look(CLOCK_RIM)
	rim.rotation.x = PI * 0.5
	rim.position.z = 0.02
	clock.add_child(rim)
	for hour: int in 12:
		var long := 0.07 if hour % 3 == 0 else 0.04
		_hand(TAU * hour / 12.0, CLOCK - 0.04 - long * 0.5, Vector2(0.018, long), CLOCK_RIM, 0.022)
	var minutes := STOPPED.y + STOPPED.z / 60.0
	_hand(TAU * (STOPPED.x + minutes / 60.0) / 12.0, 0.09, Vector2(0.03, 0.18), CLOCK_RIM, 0.03)
	_hand(TAU * minutes / 60.0, 0.12, Vector2(0.022, 0.25), CLOCK_RIM, 0.034)
	_hand(TAU * STOPPED.z / 60.0, 0.1, Vector2(0.008, 0.27), SECOND_HAND, 0.038)
	var cap := _cylinder(0.02, 0.02, CLOCK_RIM, Vector3(0.0, 0.0, 0.04))
	cap.rotation.x = PI * 0.5
	clock.add_child(cap)
	# A crack across the glass, from a knock nobody owned up to.
	for crack: Array in [
		[Vector2(0.05, 0.18), 0.1, -0.9],
		[Vector2(0.13, 0.08), 0.12, -0.3],
		[Vector2(0.2, -0.04), 0.1, -1.1],
	]:
		var at: Vector2 = crack[0]
		var line := _box(
			Vector3(0.006, crack[1], 0.004), CLOCK_FACE.darkened(0.45), Vector3(at.x, at.y, 0.045)
		)
		line.rotation.z = crack[2]
		clock.add_child(line)


## One hand or one mark on the clock's face, pointing at [param angle] round from twelve, its
## middle [param out] from the middle of the face, [param size] across and long, [param lift] off
## the face.
func _hand(angle: float, out: float, size: Vector2, ink: Color, lift: float) -> void:
	var along := Vector2(sin(angle), cos(angle))
	var hand := _box(
		Vector3(size.x, size.y, 0.006), ink, Vector3(along.x * out, along.y * out, lift)
	)
	hand.rotation.z = -angle
	clock.add_child(hand)


# --- the pegboard --------------------------------------------------------------------------------


## The pegboard on the rail behind the range, from the corner to the first machine along that rail,
## leant back toward the camera, in a red frame, each tool on a peg over its yellow outline.
func _pegboard() -> void:
	var grid := _arena.grid
	var cell := grid.cell_size
	var first := _arena.targets[0].global_position
	var last := first
	for target: Target in _arena.targets:
		if target.global_position.x < first.x:
			first = target.global_position
		last.x = maxf(last.x, target.global_position.x)
	# The rail behind the range: the wall the targets stand against.
	var back := grid.cell_of(first)
	while back.y > 0 and not grid.is_wall(back + Vector2i.UP):
		back += Vector2i.UP
	var rail := grid.cell_center(back + Vector2i.UP)
	var from := -_arena.world_size().x * 0.5 + cell + 0.25
	var to := last.x + cell
	var machines: Array[Vector3] = []
	if _arena.has_node("RailMachines"):
		machines = RailMachines.spots(_arena)
	for spot: Vector3 in machines:
		if absf(spot.z - rail.z) < 0.01 and spot.x > from:
			to = minf(to, spot.x - RailMachines.BODY.x * 0.5 - 0.25)
	var wide := minf(BOARD.x, to - from)
	if wide < 1.0:
		return
	pegboard = Node3D.new()
	pegboard.name = "Pegboard"
	pegboard.position = Vector3((from + to) * 0.5, _arena.layout.wall_height, rail.z + 0.1)
	pegboard.rotation.x = -BOARD_LEAN
	add_child(pegboard)
	var tall := BOARD.y
	pegboard.add_child(_box(Vector3(wide, tall, 0.04), BOARD_INK, Vector3(0.0, tall * 0.5, 0.0)))
	for bar: Array in [
		[Vector3(wide + 0.1, 0.06, 0.06), Vector3(0.0, tall, 0.0)],
		[Vector3(wide + 0.1, 0.06, 0.06), Vector3(0.0, 0.0, 0.0)],
		[Vector3(0.06, tall, 0.06), Vector3(-wide * 0.5 - 0.02, tall * 0.5, 0.0)],
		[Vector3(0.06, tall, 0.06), Vector3(wide * 0.5 + 0.02, tall * 0.5, 0.0)],
	]:
		pegboard.add_child(_box(bar[0], FRAME_RED, bar[1]))
	var columns := int((wide - 0.1) / HOLES)
	var rows := int((tall - 0.1) / HOLES)
	for y: int in rows:
		for x: int in columns:
			var hole := Vector3((x - (columns - 1) * 0.5) * HOLES, 0.05 + (y + 0.5) * HOLES, 0.021)
			var dot := _cylinder(0.014, 0.004, HOLE_INK, hole, 6)
			dot.rotation.x = PI * 0.5
			pegboard.add_child(dot)
	var share := wide / BOARD.x
	for tool: Array in TOOLS:
		_tool(float(tool[0]) * share, tool[1])


## One tool on the board at [param across], its [param pieces] over their yellow outline, on a peg.
func _tool(across: float, pieces: Array) -> void:
	var top := 0.0
	for piece: Array in pieces:
		var at: Vector2 = piece[0]
		var size: Vector2 = piece[1]
		var outline := _box(
			Vector3(size.x + OUTLINE * 2.0, size.y + OUTLINE * 2.0, 0.004),
			KartLift.LINE_INK,
			Vector3(across + at.x, at.y, 0.024)
		)
		outline.rotation.z = piece[2]
		pegboard.add_child(outline)
		top = maxf(top, at.y + size.y * 0.5)
		var ink: Color = piece[3]
		if ink.a <= 0.0:
			continue
		var part := _box(Vector3(size.x, size.y, 0.03), ink, Vector3(across + at.x, at.y, 0.05))
		part.rotation.z = piece[2]
		pegboard.add_child(part)
	var peg := _cylinder(0.012, 0.07, STEEL, Vector3(across, top + 0.03, 0.05))
	peg.rotation.x = PI * 0.5
	pegboard.add_child(peg)


# --- pieces --------------------------------------------------------------------------------------


func _box(size: Vector3, ink: Color, at: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _piece(mesh, ink, at)


func _cylinder(radius: float, high: float, ink: Color, at: Vector3, sides := 12) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = high
	mesh.radial_segments = sides
	mesh.rings = 1
	return _piece(mesh, ink, at)


func _piece(mesh: Mesh, ink: Color, at: Vector3) -> MeshInstance3D:
	var made := MeshInstance3D.new()
	made.mesh = mesh
	made.material_override = _look(ink)
	made.position = at
	# Small things up on the rail, seen from far off: nothing worth the shadow pass, GAME.md 10.7.
	made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return made


## One material for each ink, shared by everything wearing it so the bake makes one mesh of them.
func _look(ink: Color) -> StandardMaterial3D:
	if not _looks.has(ink):
		var look := StandardMaterial3D.new()
		look.albedo_color = ink
		look.roughness = 0.6 if ink == STEEL else 0.85
		look.metallic = 0.7 if ink == STEEL else 0.0
		_looks[ink] = look
	return _looks[ink]
