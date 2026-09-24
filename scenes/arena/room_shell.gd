class_name RoomShell
extends RoomBuild
## The room a table stands in, GAME.md 8.1: the floor under it, the walls round it, the board at
## the back of it and whatever a room hangs on that board.
##
## A table standing in the dark is a table standing in the dark -- the eye finds the edge of it
## as soon as the camera moves -- so every room is built as a room. What is lying about in it is
## [RoomProps]; this is the place itself.
##
## The wall behind the arena is nearer than the rest of the room and what it carries hangs low on
## it. The camera of 8.2 looks down at the table, so anything far behind the crowd is high up on
## the screen rather than far off, and a wall much past the clutter is a wall above the top of
## the picture.

## The patches of table the shell itself stands on: the fence line, the hoarding, the rope and the
## board at the back. Whatever is put down out here afterwards reads them, so that nothing ends up
## standing in a fence.
var taken: Array[Rect2] = []

## Where the floor of the room is and how tall its walls are, for whatever is hung on them. Both
## are set by [method enclose], which every room builds first.
var _ground := 0.0
var _height := 0.0


## Keeps the patch of table between [param from] and [param to], grown by [param width], for
## whatever is being built along it.
func _keep(from: Vector3, to: Vector3, width: float) -> void:
	var box := Rect2(Vector2(from.x, from.z), Vector2.ZERO)
	box = box.expand(Vector2(to.x, to.z))
	taken.append(box.grow(width * 0.5))


## Puts an empty shell in [param for_arena]. The room fills it in.
static func add_to(for_arena: Arena) -> RoomShell:
	var shell := RoomShell.new()
	shell._stand_in(for_arena, "Shell")
	return shell


## The room the table stands in: a floor under it and walls round it, far enough out that the
## table is still what the eye lands on. Without them the table is an island in the dark, and the
## camera only has to move a little to find the edge of the world.
##
## [param drop] is how far under the table the floor lies -- a bench stands on legs, a yard is the
## ground -- and the walls rise from it. Returns where the far wall is, for whatever the room
## hangs on it.
##
## There is no wall on the near side. The camera sits there while the match is played, and a wall
## behind the camera is a wall in front of it the moment the view pulls out over the winner.
func enclose(floor_ink: Color, wall_ink: Color, drop: float, height: float) -> float:
	var half := _room_half()
	_ground = TOP - drop
	_height = height
	var ground := Vector3(half.x * 2.0, 3.0, half.y * 2.0)
	_dim(_box(ground, surfaces.painted(floor_ink), Vector3(0.0, _ground - 1.5, 0.0)))
	var paint := surfaces.painted(wall_ink)
	var middle := _ground + height * 0.5
	var back := -(half.y + WALL_THICKNESS * 0.5)
	var across := Vector3(half.x * 2.0 + WALL_THICKNESS * 2.0, height, WALL_THICKNESS)
	_dim(_box(across, paint, Vector3(0.0, middle, back)))
	for side: float in [-1.0, 1.0]:
		var down := Vector3(WALL_THICKNESS, height, half.y * 2.0)
		_dim(_box(down, paint, Vector3(side * (half.x + WALL_THICKNESS * 0.5), middle, 0.0)))
	return back


## The edge of the table: a skirt round the top, so the room stands on something with a thickness
## rather than on a plane with an edge.
func skirt(ink: Color, depth: float) -> void:
	var half := _table()
	var paint := surfaces.painted(ink)
	for side: int in 4:
		var along := side % 2 == 0
		var size := (
			Vector3(half.x * 2.0, depth, 1.2) if along else Vector3(1.2, depth, half.y * 2.0)
		)
		var at := Vector3(
			0.0 if along else (half.x - 0.6) * (1.0 if side == 1 else -1.0),
			TOP - depth * 0.5,
			(half.y - 0.6) * (1.0 if side == 2 else -1.0) if along else 0.0
		)
		_dim(_box(size, paint, at))


## The legs under it, going down out of sight. A table with no legs is a floor.
##
## They stand well in from the corners rather than under them. A leg under the near corner is a
## dark column up the side of the screen as soon as the camera looks across the table, and the
## table is wide enough that one set in is still a table.
func legs(ink: Color) -> void:
	var half := _table() * 0.6
	var paint := surfaces.painted(ink)
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var at := Vector3(half.x * corner.x, TOP - 17.0, half.y * corner.y)
		_dim(_box(Vector3(3.2, 30.0, 3.2), paint, at))


## The board at the back of a bench: the wall the room actually has, rather than the one at the
## edge of the table that nothing but the opening shot ever sees. It stands just past the last of
## the clutter, which is close enough that a player looking down the table looks at it. Returns
## its front face.
func backboard(height: float, ink: Color) -> float:
	var half := Vector2(_table().x, arena.world_size().y * 0.5 + BACK_FAR + BACK_WALL)
	var back := -half.y
	_keep(Vector3(-half.x, TOP, back), Vector3(half.x, TOP, back), 4.0)
	var board := Vector3(half.x * 2.0, height, 2.0)
	_dim(_box(board, surfaces.painted(ink), Vector3(0.0, TOP - 2.0 + height * 0.5, back)))
	return back + 1.0


## The pegboard over a workbench with the long tools hung on it: a saw, a square and a level,
## which is what the back of a workshop looks like from across the room.
func pegboard(face: float) -> void:
	var half := _table()
	var z := face + 0.4
	# Low on the wall. The camera looks down at the table, so anything much above head height on
	# a wall this close to the crowd is above the top of the picture.
	var hang := TOP + 4.6
	var panel := surfaces.painted(room.table.darkened(0.34))
	_dim(_box(Vector3(half.x * 0.9, 8.4, 0.6), panel, Vector3(0.0, hang, z)))
	var steel := surfaces.metal(Color(0.66, 0.68, 0.72))
	var timber := surfaces.painted(room.table.lightened(0.22))
	_dim(_box(Vector3(0.9, 5.6, 0.5), steel, Vector3(-half.x * 0.3, hang - 0.6, z + 0.6)))
	_dim(_box(Vector3(4.0, 2.6, 0.4), steel, Vector3(-half.x * 0.3 + 1.8, hang + 1.8, z + 0.6)))
	_dim(_box(Vector3(1.2, 6.4, 0.6), timber, Vector3(half.x * 0.26, hang, z + 0.6)))
	_dim(_box(Vector3(5.0, 1.2, 0.6), timber, Vector3(half.x * 0.26 + 2.2, hang - 2.6, z + 0.6)))
	for i: int in 7:
		var x := -half.x * 0.36 + float(i) * (half.x * 0.72 / 6.0)
		_dim(_box(Vector3(0.4, 0.4, 1.4), steel, Vector3(x, hang + 3.0, z + 0.9)))


## The calendar nobody has turned over, hung on the board at the back of the bench.
func calendar(face: float) -> void:
	var half := _table()
	var at := Vector3(half.x * 0.62, TOP + 13.0, face + 0.5)
	var paper := surfaces.painted(Color(0.88, 0.86, 0.8))
	var band := surfaces.painted(Color(0.72, 0.24, 0.2))
	_dim(_box(Vector3(7.0, 9.0, 0.3), paper, at))
	_dim(_box(Vector3(7.0, 2.4, 0.4), band, at + Vector3(0.0, 3.3, 0.1)))


## The folds in the drape behind a card room: a row of pleats down the far wall, which is what
## stops eighty meters of flat color reading as a backdrop.
func drape(back: float) -> void:
	var half := _room_half()
	var fold := surfaces.painted(Color(0.24, 0.08, 0.12))
	var count := 21
	for i: int in count:
		var x := -half.x + float(i) * (half.x * 2.0 / float(count - 1))
		var at := Vector3(x, _ground + _height * 0.5, back + WALL_THICKNESS * 0.5 + 1.6)
		_dim(_box(Vector3(3.6, _height, 3.2), fold, at))


## Pictures on the wall of a card room: a frame, and something dark in it. What they are of is
## eighty meters from the table and nobody's business.
func pictures(back: float) -> void:
	var half := _room_half()
	var frame := surfaces.painted(room.trim.darkened(0.4))
	var print := surfaces.painted(Color(0.12, 0.08, 0.1))
	for side: float in [-1.0, 1.0]:
		var at := Vector3(side * half.x * 0.42, _ground + 26.0, back + WALL_THICKNESS * 0.5 + 0.6)
		_dim(_box(Vector3(16.0, 11.0, 0.6), frame, at))
		_dim(_box(Vector3(14.0, 9.0, 0.7), print, at))


## The rope line behind the crowd: cast bases, brass posts with a ball on top and a rope slung
## between them, the way a room that charges for the table keeps the rest of the room off it.
func rope_line() -> void:
	var half := arena.world_size() * 0.5
	var line := -(half.y + NEAR * 0.75)
	var from := Vector3(-half.x - NEAR, TOP, line)
	var to := Vector3(half.x + NEAR, TOP, line)
	_keep(from, to, 2.6)
	rope_run(from, to, 10)


## A run of it anywhere: a post at each end and [param spans] lengths of rope between, the posts
## evenly along the way. The end of a Grand Prix fences its dance floor with it, GAME.md 9.7.
func rope_run(from: Vector3, to: Vector3, spans: int) -> void:
	var post := surfaces.metal(room.trim)
	var step := (to - from) / float(maxi(spans, 1))
	for i: int in spans + 1:
		var stand := from + step * float(i)
		_stanchion(stand, post)
		if i < spans:
			_rope(stand, stand + step)


## One post of it: a weighted base, a column, a collar and a ball.
func _stanchion(at: Vector3, brass: Material) -> void:
	_taper(0.62, 0.46, 0.16, brass, at + Vector3(0.0, 0.08, 0.0))
	_cylinder(0.12, 2.3, brass, at + Vector3(0.0, 1.15, 0.0))
	_cylinder(0.2, 0.18, brass, at + Vector3(0.0, 1.9, 0.0))
	_taper(0.24, 0.0, 0.34, brass, at + Vector3(0.0, 2.47, 0.0))


## The rope between two of them, hung rather than stretched: three lengths, the middle one lower,
## which is all it takes for a rope to read as a rope rather than as a rail.
func _rope(from: Vector3, to: Vector3) -> void:
	var velvet := surfaces.painted(Color(0.46, 0.07, 0.12))
	var along := to - from
	var lengths := 3
	var dips: Array[float] = [0.12, 0.3, 0.12]
	for i: int in lengths:
		var a := from + along * (float(i) / float(lengths))
		var b := from + along * (float(i + 1) / float(lengths))
		var middle := (a + b) * 0.5 + Vector3(0.0, 1.78 - dips[i], 0.0)
		var run := b - a
		var rope := _box(Vector3(run.length() * 1.04, 0.14, 0.14), velvet, middle)
		# Turned to lie along the run, whichever way it goes, and dipped toward the middle of it.
		rope.rotation.y = -atan2(run.z, run.x)
		rope.rotation.z = -0.22 if i == 0 else (0.22 if i == 2 else 0.0)


## The warehouse the yard backs onto: a band of windows across the wall and two roller doors
## under it.
func facade(back: float) -> void:
	var half := _room_half()
	var z := back + WALL_THICKNESS * 0.5 + 0.3
	var glass := surfaces.painted(Color(0.16, 0.19, 0.24))
	var door := surfaces.painted(Color(0.27, 0.28, 0.29))
	for i: int in 11:
		var x := -half.x * 0.9 + float(i) * (half.x * 1.8 / 10.0)
		_dim(_box(Vector3(14.0, 7.0, 0.5), glass, Vector3(x, _ground + 26.0, z)))
	for side: float in [-1.0, 1.0]:
		var at := Vector3(side * half.x * 0.4, _ground + 7.5, z)
		_dim(_box(Vector3(20.0, 15.0, 0.6), door, at))


## The board over the warehouse doors, lit the way a yard's sign is at the end of the day.
func sign(back: float) -> void:
	var half := _room_half()
	var at := Vector3(0.0, _ground + 34.0, back + WALL_THICKNESS * 0.5 + 0.5)
	var board := surfaces.painted(Color(0.16, 0.17, 0.18))
	var lit := surfaces.neon(room.trim, 0.5)
	_dim(_box(Vector3(46.0, 9.0, 0.8), board, at))
	for row: float in [-1.0, 1.0]:
		_dim(_box(Vector3(40.0, 1.2, 0.4), lit, at + Vector3(0.0, row * 2.6, 0.4)))


## The hoarding round the back of a yard: corrugated panels on posts, at the edge of the apron
## rather than against the wall.
func hoarding() -> void:
	var half := arena.world_size() * 0.5
	var panel := surfaces.metal(Color(0.62, 0.66, 0.6))
	var post := surfaces.metal(Color(0.4, 0.42, 0.44))
	var z := -(half.y + BACK_FAR + BACK_WALL)
	_keep(Vector3(-half.x - FAR, TOP, z), Vector3(half.x + FAR, TOP, z), 3.0)
	# The panels meet edge to edge. A hoarding with daylight between its boards is a fence, and a
	# yard is hoarded off so that what is in it cannot be seen from the road.
	var count := 15
	var wide := half.x + FAR
	var span := wide * 2.0 / float(count)
	for i: int in count:
		var x := -wide + (float(i) + 0.5) * span
		_box(Vector3(span, 6.4, 0.35), panel, Vector3(x, TOP + 3.2, z))
		_box(Vector3(0.5, 7.0, 0.8), post, Vector3(x - span * 0.5, TOP + 3.5, z))
		if i == 4:
			_hard_hat(Vector3(x, TOP + 2.6, z + 0.6))


## A hard hat, hung on the hoarding by whoever finished their shift.
func _hard_hat(at: Vector3) -> void:
	var shell := surfaces.painted(Color(0.95, 0.72, 0.1))
	_taper(0.42, 0.3, 0.34, shell, at)
	_cylinder(0.56, 0.08, shell, at + Vector3(0.0, -0.17, 0.0))
	_box(
		Vector3(0.1, 0.34, 0.1), surfaces.metal(Color(0.5, 0.52, 0.5)), at + Vector3(0.0, 0.3, 0.0)
	)


## The fence behind the crowd, which is what keeps a yard's onlookers off a yard's forklifts:
## posts and two rails, along the back and the two flanks. Never the near side -- that is the one
## the camera looks across, and a rail through the middle of the picture is a rail in the way.
func crowd_fence() -> void:
	var half := arena.world_size() * 0.5 + Vector2.ONE * (NEAR - 0.8)
	var steel := surfaces.metal(Color(0.56, 0.58, 0.56))
	_fence_run(Vector3(0.0, TOP, -half.y), Vector3(1.0, 0.0, 0.0), half.x, steel)
	for side: float in [-1.0, 1.0]:
		_fence_run(Vector3(side * half.x, TOP, 0.0), Vector3(0.0, 0.0, 1.0), half.y, steel)


## One straight run of it, [param reach] each way from [param at] along [param along].
func _fence_run(at: Vector3, along: Vector3, reach: float, steel: Material) -> void:
	_keep(at - along * reach, at + along * reach, 2.4)
	var tall := 1.3
	var span := 4.0
	var posts := int(reach * 2.0 / span) + 1
	for i: int in posts:
		var where := at + along * (float(i) - float(posts - 1) * 0.5) * span
		_box(Vector3(0.12, tall, 0.12), steel, where + Vector3(0.0, tall * 0.5, 0.0))
	var bar := (
		Vector3(reach * 2.0, 0.08, 0.08) if along.x != 0.0 else Vector3(0.08, 0.08, reach * 2.0)
	)
	for lift: float in [0.55, 0.96]:
		_box(bar, steel, at + Vector3(0.0, tall * lift, 0.0))


## Hazard stripes, black and yellow, the way a yard marks anything that could be walked into.
## Painted on the concrete rather than standing on it.
func _hazard_paint(at: Vector3, length: float, turn: float) -> void:
	var black := surfaces.marking(Color(0.11, 0.11, 0.12))
	var yellow := surfaces.marking(Color(0.93, 0.76, 0.12))
	var count := maxi(int(length / 1.3), 2)
	var out := Vector3(cos(turn), 0.0, -sin(turn))
	for i: int in count:
		var skin := black if i % 2 == 0 else yellow
		var where := at + Vector3(0.0, 0.04, 0.0) + out * (float(i) - float(count - 1) * 0.5) * 1.3
		var slab := _box(Vector3(1.3, 0.08, 2.4), skin, where)
		slab.rotation.y = turn
		_dim(slab)


## Paint on the apron: a hazard area where the plant is kept, a walkway across the back and a
## hatched box where nothing should be left.
func apron_markings() -> void:
	var half := arena.world_size() * 0.5
	var paint := surfaces.marking(room.marking)
	# One painted area, at the back where the plant is kept. Stripes underfoot all round the room
	# read as a pattern rather than as a warning.
	_hazard_paint(Vector3(half.x * 0.28, TOP, -(half.y + BACK_FAR - 1.0)), 15.0, 0.0)
	var lane := -(half.y + FAR + 4.0)
	for i: int in 9:
		var x := -half.x * 0.8 + float(i) * (half.x * 1.6 / 8.0)
		_dim(_box(Vector3(4.0, 0.08, 0.6), paint, Vector3(x, TOP + 0.04, lane)))
