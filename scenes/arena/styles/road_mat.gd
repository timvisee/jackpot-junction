class_name RoadMat
extends RefCounted
## The driving school's mat and what stands round it, GAME.md 9.4a, for [SchoolStyle]. The roads
## are found from the map's own grid, so they go where the karts do: a white line along every kerb,
## set in from it and turning round its corners; a broken line down the middle of every road narrow
## enough to be one; a zebra crossing through every gate; and bays to park in along the far kerb of
## every room wide enough to hold them. Round the arena, on the mat's green margin, a ring road; and
## past it cones in rows and the Department's road signs on their poles, facing the camera. Past the
## mat the hall it is laid out in, its windows letting the daylight in.
##
## The paint is flat and one mesh for each ink, GAME.md 10.7: the driving test is built without its
## scenery baked, see [Tutorial], so the mat bakes its own, and the cones and signs with it.

## How far a kerb's line is set in from it, how wide a line is painted, and a dash's length.
const INSET := 0.38
const LINE := 0.1
const DASH := 0.75
## How many cells across a road may be and still have a line down its middle.
const ROAD_CELLS := 6
## A zebra crossing: how wide a stripe is and how far past the gate it runs either side.
const STRIPE := 0.42
const CROSSING_OVER := 0.5
## Bays along the far kerb of a room: how many cells across and deep each is, how much floor a room
## must have in front of a kerb to be given them, and how long the kerb must run.
const BAY_CELLS := 2
const BAY_DEEP := 2
const BAY_ROOM := 10
const BAY_RUN := 8
## How high the paint lies over the mat.
const PAINT_UP := 0.006
## The ring road round the arena: how far out its middle runs and how wide it is.
const RING_OUT := 4.2
const RING_WIDE := 3.2
## The cones and signs on the green past it: how far out from the arena, how far apart the signs
## stand, a cone's height and a pole's.
const ROADSIDE_OUT := 7.4
const SIGN_EVERY := 18.0
const CONE_TALL := 0.72
const POLE_TALL := 2.6
const SIGN_SIDE := 1.1
const SIGN_PIXELS := 256
## The signs along the roadside, in turn.
const SIGNS: Array[SchoolFigure.Kind] = [
	SchoolFigure.Kind.SPEED,
	SchoolFigure.Kind.WARNING,
	SchoolFigure.Kind.ROUNDABOUT,
	SchoolFigure.Kind.PARKING,
	SchoolFigure.Kind.NO_ENTRY,
]
## The hall: its floor and walls, and the daylight in its windows.
const HALL_FLOOR := Color(0.62, 0.53, 0.41)
const HALL_WALL := Color(0.86, 0.85, 0.8)
const DAYLIGHT := Color(0.88, 0.94, 1.0)
## How high its walls stand, in meters, how far its floor runs on toward the camera past where the
## walls stop, and how many windows go down the far wall and down each side.
const HALL_HIGH := 40.0
const HALL_APRON := 40.0
const FAR_WINDOWS := 9
const SIDE_WINDOWS := 5

var props: RoomProps
var arena: Arena
var grid: ArenaGrid
var style: SchoolStyle
var surfaces: Surfaces

## The paint, by ink.
var _paint: Dictionary[Color, SurfaceTool] = {}
## What stands round the mat, baked on its own.
var _roadside: Node3D


## Lays the mat out for [param in_props]' arena in [param for_style].
static func build(in_props: RoomProps, for_style: SchoolStyle) -> void:
	var mat := RoadMat.new()
	mat.props = in_props
	mat.arena = in_props.arena
	mat.grid = in_props.arena.grid
	mat.style = for_style
	mat.surfaces = in_props.surfaces
	mat._build()


func _build() -> void:
	props.clutter_from = 1.0
	props._boxes.clear()
	props._keep_the_floor()
	_roadside = Node3D.new()
	_roadside.name = "Roadside"
	arena.add_child(_roadside)
	_kerb_lines()
	_middle_lines()
	_crossings()
	_bays()
	_ring_road()
	_commit_paint()
	_cones_and_signs()
	_hall()
	Bake.merge(_roadside)


# --- the roads ---------------------------------------------------------------


## A floor cell for the paint: anything a kart drives on, the gates included, and the pits, which
## are no kerb, though nothing is painted in one.
func _open(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= grid.width or cell.y >= grid.height:
		return false
	return not grid.is_wall(cell)


## Whether paint may go on [param cell]: open floor, not a pit and not under the Junction.
func _paintable(cell: Vector2i) -> bool:
	if not _open(cell):
		return false
	var glyph := grid.glyph(cell)
	return glyph != ArenaGrid.PIT and glyph != "J"


## A line along every kerb, set in from it, its ends turning round the kerb's corners: an end runs
## on past the cell where the kerb goes on, stops short where another kerb meets it, and runs on by
## as much as it is set in where the kerb ends, so it meets the line coming round the corner.
func _kerb_lines() -> void:
	var half := grid.cell_size * 0.5
	for y: int in grid.height:
		for x: int in grid.width:
			var cell := Vector2i(x, y)
			if not _paintable(cell):
				continue
			var middle := grid.cell_center(cell)
			for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				if _open(cell + side):
					continue
				var along := Vector2i(absi(side.y), absi(side.x))
				var ends: Array[float] = []
				for end: int in [-1, 1]:
					var next := cell + along * end
					var reach := half
					if not _open(next):
						reach -= INSET
					elif _open(next + side):
						reach += INSET
					ends.append(reach * float(end))
				var out := Vector3(side.x, 0.0, side.y) * (half - INSET)
				var axis := Vector3(along.x, 0.0, along.y)
				_strip(middle + out + axis * ends[0], middle + out + axis * ends[1], LINE)


## A broken line down the middle of every road: a run of open cells between two kerbs, few enough
## across to be a road, with the cells either side of it along the road the same road.
func _middle_lines() -> void:
	for across: int in 2:
		var runs := _runs(across == 0)
		for key: Vector2i in runs:
			var run: Vector2i = runs[key]
			var span := run.y - run.x + 1
			if span < 3 or span > ROAD_CELLS:
				continue
			var step := Vector2i(1, 0) if across == 0 else Vector2i(0, 1)
			var before: Variant = runs.get(key - step)
			var after: Variant = runs.get(key + step)
			if before != run or after != run:
				continue
			var first := Vector2i(key.x, run.x) if across == 0 else Vector2i(run.x, key.y)
			var last := Vector2i(key.x, run.y) if across == 0 else Vector2i(run.y, key.y)
			var middle := (grid.cell_center(first) + grid.cell_center(last)) * 0.5
			var mid_cells := [first + (last - first) / 2, last - (last - first) / 2]
			if not _paintable(mid_cells[0]) or not _paintable(mid_cells[1]):
				continue
			var axis := Vector3(1.0, 0.0, 0.0) if across == 0 else Vector3(0.0, 0.0, 1.0)
			_strip(middle - axis * DASH * 0.5, middle + axis * DASH * 0.5, LINE)


## The runs of open cells from kerb to kerb: down every column when [param down], keyed by
## (column, first row), and along every row when not, keyed by (first column, row); each run its
## first and last row, or column. A run that reaches the edge of the map is no road and is left out.
func _runs(down: bool) -> Dictionary:
	var out := {}
	var lines := grid.width if down else grid.height
	var long := grid.height if down else grid.width
	for line: int in lines:
		var start := -1
		for i: int in long + 1:
			var open := i < long and _open(Vector2i(line, i) if down else Vector2i(i, line))
			if open and start < 0:
				start = i
			elif not open and start >= 0:
				if start > 0 and i < long:
					out[Vector2i(line, start) if down else Vector2i(start, line)] = Vector2i(
						start, i - 1
					)
				start = -1
	return out


## A zebra crossing through every gate: stripes the way through it, across its width, running a
## little past the gate either side.
func _crossings() -> void:
	for rect: Rect2i in grid.gates:
		var middle := grid.rect_center(rect)
		var size := grid.rect_size(rect)
		var through_x := rect.size.x < rect.size.y
		var wide := size.y if through_x else size.x
		var deep := (size.x if through_x else size.y) + CROSSING_OVER * 2.0
		var count := int(wide / (STRIPE * 2.0))
		for i: int in count:
			var offset := (float(i) + 0.5) * wide / float(count) - wide * 0.5
			var at := (
				middle + (Vector3(0.0, 0.0, offset) if through_x else Vector3(offset, 0.0, 0.0))
			)
			var axis := Vector3(1.0, 0.0, 0.0) if through_x else Vector3(0.0, 0.0, 1.0)
			_strip(at - axis * deep * 0.5, at + axis * deep * 0.5, STRIPE)


## Bays along the far kerb of every room with the floor to hold them: lines out from the kerb a
## couple of cells apart, as a car park's are, where a long run of kerb faces a deep room.
func _bays() -> void:
	var cell := grid.cell_size
	for y: int in range(1, grid.height):
		var run := 0
		for x: int in grid.width + 1:
			var fits := x < grid.width and _bay_fits(Vector2i(x, y))
			if fits:
				run += 1
				continue
			if run >= BAY_RUN:
				var count := run / BAY_CELLS
				var first := x - run + (run - count * BAY_CELLS) / 2
				for i: int in count + 1:
					var line_x := (
						grid.cell_center(Vector2i(first + i * BAY_CELLS, y)).x - cell * 0.5
					)
					var top := grid.cell_center(Vector2i(first, y)).z - cell * 0.5 + INSET
					var foot := top + float(BAY_DEEP) * cell
					_strip(Vector3(line_x, 0.0, top), Vector3(line_x, 0.0, foot), LINE)
			run = 0


## Whether a bay fits at [param at]: a kerb behind it, the floor in front of it open for
## [constant BAY_ROOM] cells and nothing on the floor where the bay would be.
func _bay_fits(at: Vector2i) -> bool:
	if _open(at + Vector2i.UP):
		return false
	for down: int in BAY_ROOM:
		var cell := at + Vector2i(0, down)
		if not _open(cell):
			return false
		if down < BAY_DEEP + 1 and grid.glyph(cell) != ArenaGrid.FLOOR:
			return false
	return true


## The ring road round the arena on the mat's margin: road gray with a white line along each edge
## and a broken one down its middle, its corners squared off.
func _ring_road() -> void:
	var half := arena.world_size() * 0.5
	var out := half + Vector2.ONE * RING_OUT
	var top := RoomBuild.TOP
	var road := SchoolStyle.ROAD.lightened(0.04)
	for side: float in [-1.0, 1.0]:
		var z := side * out.y
		_strip(
			Vector3(-out.x - RING_WIDE * 0.5, top, z),
			Vector3(out.x + RING_WIDE * 0.5, top, z),
			RING_WIDE,
			road,
			-0.002
		)
		var x := side * out.x
		_strip(
			Vector3(x, top, -out.y + RING_WIDE * 0.5),
			Vector3(x, top, out.y - RING_WIDE * 0.5),
			RING_WIDE,
			road,
			-0.002
		)
	for edge: float in [-1.0, 1.0]:
		var line := out + Vector2.ONE * edge * (RING_WIDE * 0.5 - 0.25)
		for side: float in [-1.0, 1.0]:
			_strip(Vector3(-line.x, top, side * line.y), Vector3(line.x, top, side * line.y), LINE)
			_strip(Vector3(side * line.x, top, -line.y), Vector3(side * line.x, top, line.y), LINE)
	for side: float in [-1.0, 1.0]:
		var dashes := int(out.x * 2.0 / (DASH * 2.0))
		for i: int in dashes:
			var x := -out.x + (float(i) + 0.5) * out.x * 2.0 / float(dashes)
			_strip(
				Vector3(x - DASH * 0.5, top, side * out.y),
				Vector3(x + DASH * 0.5, top, side * out.y),
				LINE
			)
		dashes = int(out.y * 2.0 / (DASH * 2.0))
		for i: int in dashes:
			var z := -out.y + (float(i) + 0.5) * out.y * 2.0 / float(dashes)
			if absf(z) > out.y - RING_WIDE * 0.5:
				continue
			_strip(
				Vector3(side * out.x, top, z - DASH * 0.5),
				Vector3(side * out.x, top, z + DASH * 0.5),
				LINE
			)


## A strip of paint [param wide] across from [param from] to [param to], on the mat, in
## [param ink], [param lift] over the paint's own height.
func _strip(from: Vector3, to: Vector3, wide: float, ink := SchoolStyle.PAINT, lift := 0.0) -> void:
	if not _paint.has(ink):
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		_paint[ink] = tool
	var tool: SurfaceTool = _paint[ink]
	var along := Vector3(to.x - from.x, 0.0, to.z - from.z).normalized()
	var across := Vector3(-along.z, 0.0, along.x) * wide * 0.5
	var up := Vector3(0.0, from.y + PAINT_UP + lift, 0.0)
	var a := Vector3(from.x, 0.0, from.z) + up
	var b := Vector3(to.x, 0.0, to.z) + up
	tool.set_normal(Vector3.UP)
	for corner: Vector3 in [a - across, b - across, b + across, a - across, b + across, a + across]:
		tool.add_vertex(corner)


## Every ink's paint as a mesh of its own, lying on the mat.
func _commit_paint() -> void:
	for ink: Color in _paint:
		var paint := MeshInstance3D.new()
		paint.name = (
			"RoadPaint%s"
			% ("" if arena.get_node_or_null("RoadPaint") == null else ink.to_html(false))
		)
		paint.mesh = (_paint[ink] as SurfaceTool).commit()
		paint.material_override = surfaces.marking(ink)
		paint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arena.add_child(paint)


# --- the roadside ------------------------------------------------------------


## Cones in rows of three at the roadside, and a road sign between every few of them, along the
## far side and both flanks, facing the camera. The near side is the camera's, and is kept bare.
func _cones_and_signs() -> void:
	var half := arena.world_size() * 0.5
	var out := half + Vector2.ONE * ROADSIDE_OUT
	var faces: Dictionary[SchoolFigure.Kind, Material] = {}
	var steel := surfaces.metal(Color(0.66, 0.68, 0.72))
	var count := 0
	var spots: Array[Vector3] = []
	var along := int(out.x * 2.0 / SIGN_EVERY)
	for i: int in along + 1:
		spots.append(Vector3(-out.x + float(i) * out.x * 2.0 / float(along), RoomBuild.TOP, -out.y))
	var down := int(out.y / SIGN_EVERY * 1.5)
	for side: float in [-1.0, 1.0]:
		for i: int in range(1, down + 1):
			spots.append(
				Vector3(side * out.x, RoomBuild.TOP, -out.y + float(i) * SIGN_EVERY * 0.75)
			)
	for at: Vector3 in spots:
		if count % 2 == 0:
			var kind: SchoolFigure.Kind = SIGNS[(count / 2) % SIGNS.size()]
			if not faces.has(kind):
				var figure := SchoolFigure.of(kind, SIGN_PIXELS)
				var drawn := DrawnTexture.of(_roadside, figure, Vector2i(SIGN_PIXELS, SIGN_PIXELS))
				faces[kind] = DrawnTexture.decal(drawn)
			_sign(at, faces[kind], steel)
		else:
			var row := (
				Vector3(1.0, 0.0, 0.0) if absf(at.z + out.y) < 0.1 else Vector3(0.0, 0.0, 1.0)
			)
			for k: int in 3:
				_cone(at + row * (float(k) - 1.0) * 1.1)
		count += 1


## A cone, as the test route's are, see [SchoolProps]: a dark foot, the cone and a white band.
func _cone(at: Vector3) -> void:
	var cone := surfaces.painted(SchoolStyle.CONE)
	var foot := surfaces.painted(Color(0.16, 0.16, 0.18))
	var band := surfaces.painted(SchoolStyle.PAINT)
	_part(BoxMesh.new(), foot, at + Vector3(0.0, 0.03, 0.0), Vector3(0.5, 0.06, 0.5))
	_taper(0.2, 0.05, CONE_TALL, cone, at + Vector3(0.0, CONE_TALL * 0.5 + 0.06, 0.0))
	_taper(0.145, 0.115, 0.12, band, at + Vector3(0.0, CONE_TALL * 0.5 + 0.1, 0.0))


## A road sign on its pole, its face in front of the pole and turned to the camera.
func _sign(foot: Vector3, face: Material, steel: Material) -> void:
	_taper(0.05, 0.05, POLE_TALL, steel, foot + Vector3(0.0, POLE_TALL * 0.5, 0.0))
	var plate := QuadMesh.new()
	plate.size = Vector2(SIGN_SIDE, SIGN_SIDE)
	var at := foot + Vector3(0.0, POLE_TALL - SIGN_SIDE * 0.5 - 0.1, 0.09)
	var front := _part(plate, face, at + Vector3(0.0, 0.0, 0.025), Vector3.ONE)
	front.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var back := surfaces.painted(Color(0.2, 0.2, 0.22))
	_part(BoxMesh.new(), back, at, Vector3(SIGN_SIDE * 0.92, SIGN_SIDE * 0.92, 0.04))


## The hall the mat is laid out in: a floor of boards under the stage it lies on, deep enough for
## the pits, pale walls round it and rows of tall windows down the far one and down both sides,
## bright with the day outside, over a band of the Department's green along the foot of every wall.
##
## The opening shot of GAME.md 8.2 is the furthest back the camera ever goes here, and in a wide
## window most of its sides are the hall's side walls: left bare, a flat pale slab down one side and
## the same in shadow down the other, they read as the world's edge rather than a wall. Windowed and
## banded as the far wall is, they are the hall. The walls stand high and the floor runs on under
## the camera, so a tall window's opening shot sees the hall too and nothing past it. A few big
## boxes, merged like the rest of the room where the arena does not bake it, as the driving test's
## does not.
func _hall() -> void:
	var shell := props.shell
	var wall := shell.enclose(HALL_FLOOR, HALL_WALL, 2.0, HALL_HIGH)
	shell.skirt(SchoolStyle.MARGIN.darkened(0.3), 2.0)
	var half := shell._room_half()
	var light := surfaces.neon(DAYLIGHT, 0.55)
	var frame := surfaces.painted(SchoolStyle.DEPARTMENT)
	var high := RoomBuild.TOP + 9.0
	var face := wall + RoomBuild.WALL_THICKNESS * 0.5
	for i: int in FAR_WINDOWS:
		var x := -half.x * 0.85 + float(i) * half.x * 1.7 / float(FAR_WINDOWS - 1)
		_window(shell, Vector3(x, high, face + 0.2), false, frame, light)
	for side: float in [-1.0, 1.0]:
		for i: int in SIDE_WINDOWS:
			var z := lerpf(-half.y * 0.8, half.y * 0.6, float(i) / float(SIDE_WINDOWS - 1))
			_window(shell, Vector3(side * (half.x - 0.2), high, z), true, frame, light)
	# A band of the Department's green along the foot of every wall, the sides' stopping at the far
	# one's.
	var foot := RoomBuild.TOP + 0.7
	shell._dim(shell._box(Vector3(half.x * 2.0, 2.4, 0.4), frame, Vector3(0.0, foot, face + 0.2)))
	for side: float in [-1.0, 1.0]:
		var along := Vector3(0.4, 2.4, half.y * 2.0 - 0.4)
		shell._dim(shell._box(along, frame, Vector3(side * (half.x - 0.2), foot, 0.2)))
	# The boards on toward the camera, where the hall has no wall, see [method RoomShell.enclose].
	var ground := RoomBuild.TOP - 2.0
	var apron := Vector3(half.x * 2.0 + RoomBuild.WALL_THICKNESS * 2.0, 3.0, HALL_APRON)
	var boards := surfaces.painted(HALL_FLOOR)
	shell._dim(shell._box(apron, boards, Vector3(0.0, ground - 1.5, half.y + HALL_APRON * 0.5)))
	if not arena.bake_scenery:
		Bake.merge(shell)


## A tall window at [param at], its frame in [param frame] and its panes in [param light], set in
## the far wall or, [param sideways], in a side one.
func _window(
	shell: RoomShell, at: Vector3, sideways: bool, frame: Material, light: Material
) -> void:
	var outer := Vector3(9.0, 12.0, 0.3)
	var pane := Vector3(8.2, 11.2, 0.4)
	if sideways:
		outer = Vector3(outer.z, outer.y, outer.x)
		pane = Vector3(pane.z, pane.y, pane.x)
	shell._dim(shell._box(outer, frame, at))
	shell._dim(shell._box(pane, light, at))


# --- the parts ---------------------------------------------------------------


func _taper(bottom: float, top: float, tall: float, skin: Material, at: Vector3) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = tall
	mesh.radial_segments = 10
	mesh.rings = 1
	return _part(mesh, skin, at, Vector3.ONE)


## [param mesh] in [param skin] at [param at], a box of [param size] if it is one, on the roadside.
func _part(mesh: Mesh, skin: Material, at: Vector3, size: Vector3) -> MeshInstance3D:
	if mesh is BoxMesh:
		(mesh as BoxMesh).size = size
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = skin
	part.position = at
	_roadside.add_child(part)
	return part
