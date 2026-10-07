class_name CountRoom
extends RoomBuild
## The Count Room, STORY.md 3.9 and GAME.md 8.1: the room the House built for itself. The table
## stands on a raised floor of square tiles in a hall of server racks, rows of them behind the
## crowd with their lights winking, cable trays over them and monitors on them scrolling numbers
## nobody reads, all of it lit in a hard green. Everything stands exactly on the grid and square to
## the table, nothing is stacked by hand and nothing is left lying about: nobody has ever been in
## here to put anything down. The racks wink and the monitors scroll in their shaders, see
## [CountKit], so the hall costs its meshes and nothing per frame.

## The floor's tiles, in meters, and the dark of the gaps between them.
const TILE := 2.5
const GAP := Color(0.03, 0.04, 0.04)
## A rack: how wide, deep and tall; how far out past the arena the rows of them stand, clear of
## the back of the crowd; and every how many racks the row leaves an aisle.
const RACK := Vector3(2.2, 6.0, 3.0)
const OUT := 10.5
const AISLE_EVERY := 6
## How high the cable trays run over the racks, and every how many racks one carries a monitor.
const TRAY_OVER := 1.2
const MONITOR_EVERY := 4
const MONITOR := Vector2(1.7, 1.05)

## Where the racks of the back row stand, for whatever else hangs a thing on one.
var back_racks: Array[Vector3] = []


## The Count Room round [param for_arena], in [param shell].
static func add_to(for_arena: Arena, shell: RoomShell) -> CountRoom:
	var hall := CountRoom.new()
	hall._stand_in(for_arena, "CountRoom")
	hall._build(shell)
	return hall


func _build(shell: RoomShell) -> void:
	shell.enclose(Color(0.04, 0.05, 0.05), Color(0.03, 0.04, 0.04), 3.0, 40.0)
	shell.skirt(room.table, 2.6)
	_tiles()
	var half := arena.world_size() * 0.5
	var table := _table()
	# A row along the back, and one down each side; none on the near side, which is the camera's.
	_row(
		Vector3(-table.x + 2.0, TOP, -(half.y + OUT)),
		Vector3(table.x - 2.0, TOP, -(half.y + OUT)),
		true
	)
	for side: float in [-1.0, 1.0]:
		var x := side * (half.x + OUT)
		_row(Vector3(x, TOP, -(half.y + OUT) + RACK.x * 2.0), Vector3(x, TOP, half.y + 2.0), false)
	if arena.bake_scenery:
		Bake.merge(self)


## The raised floor's tiles: the gaps between them laid over the table round the arena, every one
## the same, square to it.
func _tiles() -> void:
	var table := _table()
	var dark := surfaces.painted(GAP)
	var x := -table.x + TILE
	while x < table.x:
		_dim(_box(Vector3(0.06, 0.01, table.y * 2.0), dark, Vector3(x, TOP + 0.006, 0.0)))
		x += TILE
	var z := -table.y + TILE
	while z < table.y:
		_dim(_box(Vector3(table.x * 2.0, 0.01, 0.06), dark, Vector3(0.0, TOP + 0.006, z)))
		z += TILE


## A row of racks from [param from] to [param to], facing the table, an aisle every few, a cable
## tray over the lot, and a monitor on every few facing in.
func _row(from: Vector3, to: Vector3, back: bool) -> void:
	var along := to - from
	var count := int(along.length() / RACK.x)
	var step := along.normalized() * RACK.x
	var size := RACK if back else Vector3(RACK.z, RACK.y, RACK.x)
	var inward := Vector3(0.0, 0.0, 1.0) if back else Vector3(-signf(from.x), 0.0, 0.0)
	var leds := CountKit.leds(room)
	for i: int in count:
		if i % AISLE_EVERY == AISLE_EVERY - 1:
			continue
		var at := from + step * (float(i) + 0.5)
		_dim(_box(size, leds, at + Vector3(0.0, size.y * 0.5, 0.0)))
		if back:
			back_racks.append(at)
		if i % MONITOR_EVERY == 1:
			_monitor(at + inward * (size.z * 0.5 if back else size.x * 0.5), inward, float(i))
	var tray := surfaces.metal(Color(0.3, 0.32, 0.33))
	var middle := from + along * 0.5 + Vector3(0.0, RACK.y + TRAY_OVER, 0.0)
	var run := Vector3(along.length(), 0.14, 1.0) if back else Vector3(1.0, 0.14, along.length())
	_dim(_box(run, tray, middle))
	for i: int in CountKit.CABLES.size():
		var lay := (float(i) - 1.5) * 0.2
		var cable := (
			Vector3(along.length(), 0.08, 0.12) if back else Vector3(0.12, 0.08, along.length())
		)
		var off := Vector3(0.0, 0.1, lay) if back else Vector3(lay, 0.1, 0.0)
		_dim(_box(cable, surfaces.painted(CountKit.CABLES[i]), middle + off))


## A monitor on a rack's face at [param at], facing [param inward], its numbers scrolling. The
## screen is a node of its own beside its bezel rather than under it: the bezels bake into one
## mesh, and what hung under one would go with it.
func _monitor(at: Vector3, inward: Vector3, offset: float) -> void:
	var turn := atan2(inward.x, inward.z)
	var middle := at + Vector3(0.0, RACK.y * 0.62, 0.0)
	var bezel := _box(
		Vector3(MONITOR.x + 0.16, MONITOR.y + 0.16, 0.12),
		surfaces.painted(Color(0.05, 0.05, 0.06)),
		middle + inward * 0.06
	)
	bezel.rotation.y = turn
	_dim(bezel)
	var screen := QuadMesh.new()
	screen.size = MONITOR
	var lit := MeshInstance3D.new()
	lit.name = "Monitor%d" % int(offset)
	lit.mesh = screen
	lit.material_override = CountKit.screen(room, offset * 3.1)
	lit.position = middle + inward * 0.13
	lit.rotation.y = turn
	_dim(lit)
	add_child(lit)
