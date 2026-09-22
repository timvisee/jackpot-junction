class_name RoomProps
extends Node3D
## What a room has in it besides the table, GAME.md 8.1: the walls it stands in and the clutter
## lying about outside the arena. The workbench has a workshop wall behind it and the tools of
## whoever built the thing left on the bench; the card room has chips and decks out on the baize;
## the yard has scaffolding, barriers and a truck.
##
## Two of the rooms are models standing on a real table, so everything around them is the size it
## would be next to a model: a hammer left on the bench is a quarter as long as the arena is wide.
## The yard is a place rather than a model, so a scaffold tower there is the size of a scaffold
## tower. Either way all of it is boxes and cylinders in the room's own materials, which is what
## keeps a hammer and a stack of chips looking like they came out of the same game.
##
## None of it collides and none of it decides anything. Nothing stands where a kart could reach
## it, and the near side of the room is kept flat on purpose: the camera of 8.2 looks down the
## table from there, so anything standing up on that side is between the player and the game.

## How far past the arena wall the clutter starts and how far out it may go: right behind the
## crowd, and not much further. A room reads as somewhere because of what is close enough to make
## out, and the camera of 8.2 sees very little past the stands while a match is being played, so
## a prop twenty-five metres out is a prop nobody has ever seen.
const NEAR := 6.0
const FAR := 15.0
## How much the clutter crowds the near end of that range: the square of a flat random, which puts
## two thirds of it in the first half.
const CROWDING := 1.7
## How far out a prop has to be before it is allowed to be one of the big ones.
const CLOSE := 10.0
## The grid the clutter is set out on. Things put down by somebody line up with the edge of the
## table and roughly with each other; things dropped at random read as a spill whatever they are.
const SPACING := 4.0
## How much further out the near apron starts than the flanks do.
const APRON_CLEAR := 3.0
## The table's own surface, a little under the arena floor. Everything outside the wall stands on
## this rather than on the floor the karts drive on.
const TOP := -Arena.FLOOR_THICKNESS
## How far past the edge of the table the wall round the room stands, and how thick it is. Close
## enough to be seen: a wall sixty metres behind the crowd is a wall nobody ever knew was there,
## and the point of a room having one is that the table is in a room.
const ROOM_CLEAR := 2.0
const WALL_THICKNESS := 2.0

var arena: Arena
var room: RoomLook
var surfaces: Surfaces

## Its own generator, seeded off the room, so a room is dressed the same way every time it is
## built and two rooms are not dressed the same way.
var _rng := RandomNumberGenerator.new()
## Where the floor of the room is and how tall its walls are, for whatever is hung on them. Both
## are set by [method _room], which every room builds first.
var _ground := 0.0
var _height := 0.0


## Dresses [param for_arena]'s room and returns the holder everything went into.
static func add_to(for_arena: Arena) -> RoomProps:
	var props := RoomProps.new()
	props.name = "Props"
	props.arena = for_arena
	props.room = for_arena.room
	props.surfaces = for_arena.surfaces
	for_arena.add_child(props)
	props._build()
	return props


func _build() -> void:
	_rng.seed = hash(room.id)
	match room.id:
		&"after_hours":
			_card_room()
		&"the_yard":
			_yard()
		_:
			_workbench()
	# And the lot of it goes into as few meshes as it will go, GAME.md 8.1: none of it moves and
	# none of it is ever hidden on its own, so a chip does not need a draw call of its own.
	if arena.bake_scenery:
		Bake.merge(self)


# --- the rooms ---------------------------------------------------------------


## A bench against a workshop wall: the table's own edge and legs, a pegboard over it, and the
## tools of whoever built the thing lying where they were put down.
func _workbench() -> void:
	_room(Color(0.15, 0.13, 0.12), Color(0.26, 0.22, 0.18), 32.0, 80.0)
	_skirt(room.table.darkened(0.32), 2.4)
	_legs(room.table.darkened(0.42))
	var board := _backboard(24.0, room.table.lightened(0.22))
	_pegboard(board)
	_calendar(board)
	var half := arena.world_size() * 0.5
	_bench_lamp(Vector3(-(half.x + 12.0), TOP, -(half.y + 10.0)))
	_vice(Vector3(-(half.x + 9.0), TOP, half.y * 0.25))
	var timber := surfaces.painted(room.table.lightened(0.16))
	var steel := surfaces.metal(Color(0.64, 0.66, 0.7))
	# Rod stock is painted rather than metal: there is nothing in a dim workshop for a metal to
	# reflect, so a metal bar the size of this one reads as a black bar.
	var stock := surfaces.painted(Color(0.7, 0.72, 0.76))
	var handle := surfaces.painted(Color(0.58, 0.27, 0.16))
	for at: Vector3 in _ring(14):
		if _close(at):
			match _rng.randi_range(0, 2):
				0:
					_rods(at, stock)
				1:
					_tape(at, surfaces.painted(Color(0.85, 0.78, 0.12)), steel)
				_:
					_tin(at, surfaces.painted(Color(0.76, 0.78, 0.82)), steel)
		else:
			match _rng.randi_range(0, 3):
				0:
					_hammer(at, steel, handle)
				1:
					_planks(at, timber)
				2:
					_drill(at, surfaces.painted(Color(0.87, 0.66, 0.16)), steel)
				_:
					_mug(at, surfaces.painted(Color(0.87, 0.88, 0.91)))
	for at: Vector3 in _apron(3):
		match _rng.randi_range(0, 2):
			0:
				_pencil(at, surfaces.painted(Color(0.9, 0.72, 0.2)), steel)
			1:
				_rods(at, stock)
			_:
				_rule(at, stock)


## A card room after hours: the baize is the floor, a rope line runs behind the crowd, and what
## the house plays with is left out around the table.
func _card_room() -> void:
	var wall := _room(Color(0.1, 0.045, 0.06), Color(0.17, 0.06, 0.09), 32.0, 80.0)
	_drape(wall)
	_pictures(wall)
	_skirt(room.table.darkened(0.34), 2.4)
	_legs(room.table.darkened(0.46))
	_rope_line()
	var half := arena.world_size() * 0.5
	for side: float in [-1.0, 1.0]:
		_pendant(Vector3(side * half.x * 0.62, TOP, -(half.y + 10.0)))
	for at: Vector3 in _ring(11):
		if _close(at):
			match _rng.randi_range(0, 2):
				0:
					_dice(at)
				1:
					_fanned_cards(at)
				_:
					_chip_stack(at)
		else:
			match _rng.randi_range(0, 2):
				0:
					_card_deck(at)
				1:
					_glass(at)
				_:
					_chip_stack(at)
	for at: Vector3 in _apron(4):
		if _rng.randf() < 0.5:
			_fanned_cards(at)
		else:
			_dice(at)


## A yard between warehouse walls: an apron of concrete, hoarding along the back, floodlights over
## it and the things a yard has standing about in it.
func _yard() -> void:
	var wall := _room(Color(0.13, 0.13, 0.12), Color(0.25, 0.24, 0.22), 3.4, 46.0)
	_facade(wall)
	_sign(wall)
	_skirt(room.table.darkened(0.22), 3.2)
	_hoarding()
	_apron_markings()
	var steel := surfaces.metal(Color(0.72, 0.74, 0.78))
	var timber := surfaces.painted(room.table.lightened(0.26))
	var half := arena.world_size() * 0.5
	for side: float in [-1.0, 1.0]:
		_floodlight(Vector3(side * half.x * 0.8, TOP, -(half.y + 11.0)), steel)
	_truck(Vector3(-(half.x + 9.0), TOP, half.y * 0.1), steel)
	for at: Vector3 in _ring(14):
		if _close(at):
			match _rng.randi_range(0, 2):
				0:
					_cones(at)
				1:
					_pallets(at, timber)
				_:
					_barrels(at, surfaces.painted(Color(0.78, 0.44, 0.14)), steel)
		else:
			match _rng.randi_range(0, 3):
				0:
					_scaffold(at, steel)
				1:
					_container(at)
				2:
					_bricks(at, surfaces.painted(Color(0.56, 0.29, 0.22)))
				_:
					_barrier(at)
	for at: Vector3 in _apron(4):
		if _rng.randf() < 0.5:
			_cones(at)
		else:
			_pallets(at, timber)


# --- the shell ---------------------------------------------------------------


## The edge of the table: a skirt round the top, so the room stands on something with a thickness
## rather than on a plane with an edge.
func _skirt(ink: Color, depth: float) -> void:
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
func _legs(ink: Color) -> void:
	var half := _table() * 0.6
	var paint := surfaces.painted(ink)
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var at := Vector3(half.x * corner.x, TOP - 17.0, half.y * corner.y)
		_dim(_box(Vector3(3.2, 30.0, 3.2), paint, at))


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
func _room(floor_ink: Color, wall_ink: Color, drop: float, height: float) -> float:
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


## The board at the back of a bench, standing up from the table itself. It is the first thing
## behind the arena when the camera looks down the table, which is what a room hangs its tools on
## rather than a wall sixty metres further back. Returns its front face.
func _backboard(height: float, ink: Color) -> float:
	var half := _table()
	var back := -(half.y - 1.0)
	var board := Vector3(half.x * 2.0, height, 2.0)
	_dim(_box(board, surfaces.painted(ink), Vector3(0.0, TOP - 2.0 + height * 0.5, back)))
	return back + 1.0


## The pegboard over a workbench with the long tools hung on it: a saw, a square and a level,
## which is what the back of a workshop looks like from across the room.
func _pegboard(face: float) -> void:
	var half := _table()
	var z := face + 0.4
	var hang := TOP + 12.0
	var panel := surfaces.painted(room.table.darkened(0.34))
	_dim(_box(Vector3(half.x * 0.9, 17.0, 0.6), panel, Vector3(0.0, hang, z)))
	var steel := surfaces.metal(Color(0.66, 0.68, 0.72))
	var timber := surfaces.painted(room.table.lightened(0.22))
	_dim(_box(Vector3(1.0, 11.0, 0.5), steel, Vector3(-half.x * 0.3, hang - 1.0, z + 0.6)))
	_dim(_box(Vector3(7.0, 5.0, 0.4), steel, Vector3(-half.x * 0.3 + 3.2, hang + 4.0, z + 0.6)))
	_dim(_box(Vector3(1.4, 13.0, 0.6), timber, Vector3(half.x * 0.26, hang, z + 0.6)))
	_dim(_box(Vector3(9.0, 1.4, 0.6), timber, Vector3(half.x * 0.26 + 4.0, hang - 5.5, z + 0.6)))
	for i: int in 7:
		var x := -half.x * 0.36 + float(i) * (half.x * 0.72 / 6.0)
		_dim(_box(Vector3(0.4, 0.4, 1.4), steel, Vector3(x, hang + 6.0, z + 0.9)))


## The folds in the drape behind a card room: a row of pleats down the far wall, which is what
## stops eighty metres of flat colour reading as a backdrop.
func _drape(back: float) -> void:
	var half := _room_half()
	var fold := surfaces.painted(Color(0.24, 0.08, 0.12))
	var count := 21
	for i: int in count:
		var x := -half.x + float(i) * (half.x * 2.0 / float(count - 1))
		var at := Vector3(x, _ground + _height * 0.5, back + WALL_THICKNESS * 0.5 + 1.6)
		_dim(_box(Vector3(3.6, _height, 3.2), fold, at))


## The rope line behind the crowd: brass posts with a rope between them, so the room the onlookers
## are standing in has a front to it.
func _rope_line() -> void:
	var half := arena.world_size() * 0.5
	var rope := surfaces.painted(Color(0.44, 0.09, 0.15))
	var post := surfaces.metal(room.trim)
	var span := (half.x + NEAR) * 2.0 / 10.0
	for i: int in 11:
		var stand := Vector3(-(half.x + NEAR) + float(i) * span, TOP, -(half.y + NEAR * 0.75))
		_cylinder(0.22, 2.2, post, stand + Vector3(0.0, 1.1, 0.0))
		if i < 10:
			_box(Vector3(span, 0.3, 0.3), rope, stand + Vector3(span * 0.5, 1.9, 0.0))


## The warehouse the yard backs onto: a band of windows across the wall and two roller doors
## under it.
func _facade(back: float) -> void:
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


## The hoarding round the back of a yard: corrugated panels on posts, at the edge of the apron
## rather than against the wall.
func _hoarding() -> void:
	var half := arena.world_size() * 0.5
	var panel := surfaces.metal(Color(0.62, 0.66, 0.6))
	var post := surfaces.metal(Color(0.4, 0.42, 0.44))
	var z := -(half.y + FAR + 2.0)
	# The panels meet edge to edge. A hoarding with daylight between its boards is a fence, and a
	# yard is hoarded off so that what is in it cannot be seen from the road.
	var count := 15
	var wide := half.x + FAR
	var span := wide * 2.0 / float(count)
	for i: int in count:
		var x := -wide + (float(i) + 0.5) * span
		_box(Vector3(span, 6.4, 0.35), panel, Vector3(x, TOP + 3.2, z))
		_box(Vector3(0.5, 7.0, 0.8), post, Vector3(x - span * 0.5, TOP + 3.5, z))


## The lamp the workbench is lit by, standing at the back corner of the bench: a base, a column,
## an arm out over the table and a shade with the bulb under it. The room says there is a lamp
## over the table, GAME.md 8.1, and this is the thing saying so.
func _bench_lamp(at: Vector3) -> void:
	var steel := surfaces.painted(Color(0.32, 0.33, 0.36))
	var reach := 9.0
	_cylinder(3.2, 0.8, steel, at + Vector3(0.0, 0.4, 0.0))
	_cylinder(0.5, 15.0, steel, at + Vector3(0.0, 7.5, 0.0))
	var arm := _box(Vector3(0.6, 0.6, reach), steel, at + Vector3(0.0, 14.6, reach * 0.5))
	arm.rotation.x = -0.12
	_taper(3.4, 1.2, 3.0, steel, at + Vector3(0.0, 13.2, reach))
	_cylinder(2.6, 0.3, surfaces.neon(room.lamp_color, 0.5), at + Vector3(0.0, 11.9, reach))


## A vice on the edge of the bench: the one thing every workshop has, and the one shape that says
## workshop from across a room.
func _vice(at: Vector3) -> void:
	var iron := surfaces.painted(Color(0.24, 0.26, 0.3))
	var brass := surfaces.painted(Color(0.55, 0.42, 0.18))
	_box(Vector3(4.0, 1.2, 4.6), iron, at + Vector3(0.0, 0.6, 0.0))
	_box(Vector3(3.0, 3.4, 1.4), iron, at + Vector3(0.0, 2.6, -1.2))
	_box(Vector3(3.0, 3.0, 1.2), iron, at + Vector3(0.0, 2.4, 1.4))
	var screw := _cylinder(0.5, 7.0, brass, at + Vector3(0.0, 2.6, 1.6))
	screw.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	_box(Vector3(4.4, 0.5, 0.5), brass, at + Vector3(0.0, 2.6, 4.6))


## The calendar nobody has turned over, hung on the board at the back of the bench.
func _calendar(face: float) -> void:
	var half := _table()
	var at := Vector3(half.x * 0.62, TOP + 13.0, face + 0.5)
	var paper := surfaces.painted(Color(0.88, 0.86, 0.8))
	var band := surfaces.painted(Color(0.72, 0.24, 0.2))
	_dim(_box(Vector3(7.0, 9.0, 0.3), paper, at))
	_dim(_box(Vector3(7.0, 2.4, 0.4), band, at + Vector3(0.0, 3.3, 0.1)))


## Two lamps hung over the far side of a card room, out past the rope. They are what the room is
## dressed with rather than what it is lit by -- the light over the table is the table's own --
## but a bulb in the dark is worth having where the eye has nothing else to land on.
func _pendant(at: Vector3) -> void:
	var brass := surfaces.painted(room.trim.darkened(0.45))
	var high := 11.0
	_cylinder(0.2, 14.0, brass, at + Vector3(0.0, high + 7.0, 0.0))
	_taper(4.2, 1.0, 3.4, brass, at + Vector3(0.0, high, 0.0))
	_cylinder(3.4, 0.4, surfaces.neon(room.lamp_color, 0.45), at + Vector3(0.0, high - 1.6, 0.0))


## Pictures on the wall of a card room: a frame, and something dark in it. What they are of is
## eighty metres from the table and nobody's business.
func _pictures(back: float) -> void:
	var half := _room_half()
	var frame := surfaces.painted(room.trim.darkened(0.4))
	var print := surfaces.painted(Color(0.12, 0.08, 0.1))
	for side: float in [-1.0, 1.0]:
		var at := Vector3(side * half.x * 0.42, _ground + 26.0, back + WALL_THICKNESS * 0.5 + 0.6)
		_dim(_box(Vector3(16.0, 11.0, 0.6), frame, at))
		_dim(_box(Vector3(14.0, 9.0, 0.7), print, at))


## The board over the warehouse doors, lit the way a yard's sign is at the end of the day.
func _sign(back: float) -> void:
	var half := _room_half()
	var at := Vector3(0.0, _ground + 34.0, back + WALL_THICKNESS * 0.5 + 0.5)
	var board := surfaces.painted(Color(0.16, 0.17, 0.18))
	var lit := surfaces.neon(room.trim, 0.5)
	_dim(_box(Vector3(46.0, 9.0, 0.8), board, at))
	for row: float in [-1.0, 1.0]:
		_dim(_box(Vector3(40.0, 1.2, 0.4), lit, at + Vector3(0.0, row * 2.6, 0.4)))


## Paint on the apron: a walkway across the back and a hatched box where nothing should be left.
## Flat, and laid on the concrete rather than standing on it.
func _apron_markings() -> void:
	var half := arena.world_size() * 0.5
	var paint := surfaces.marking(room.marking)
	var lane := -(half.y + 22.0)
	for i: int in 9:
		var x := -half.x * 0.8 + float(i) * (half.x * 1.6 / 8.0)
		_dim(_box(Vector3(4.0, 0.08, 0.6), paint, Vector3(x, TOP + 0.04, lane)))
	for i: int in 6:
		var at := Vector3(half.x + 16.0, TOP + 0.04, -half.y * 0.6 + float(i) * 2.4)
		var hatch := _box(Vector3(9.0, 0.08, 0.7), paint, at)
		hatch.rotation.y = 0.6
		_dim(hatch)


# --- where the clutter goes --------------------------------------------------


## [param count] places round the far side and the two flanks of the table, past the crowd and
## short of the edge.
func _ring(count: int) -> Array[Vector3]:
	var half := arena.world_size() * 0.5
	var out: Array[Vector3] = []
	for i: int in count:
		var away := _lined(NEAR + (FAR - NEAR) * pow(_rng.randf(), CROWDING))
		var along := _rng.randf_range(-0.95, 0.95)
		# Three out of five go behind the arena. The camera looks down the table, so that is the
		# side a player sees for most of a match; the flanks are only ever glimpsed.
		match i % 5:
			0, 1, 2:
				out.append(Vector3(_lined(along * half.x), TOP, -(half.y + away)))
			3:
				out.append(Vector3(half.x + away, TOP, _lined(_flank() * (half.y + NEAR))))
			_:
				out.append(Vector3(-(half.x + away), TOP, _lined(_flank() * (half.y + NEAR))))
	return out


## How far down a flank a prop may stand. The back of the table is fair game and the middle of
## it is fine, but the near corners are beside the camera rather than behind it, and something
## five metres tall there is in the corner of the picture the whole match.
func _flank() -> float:
	return _rng.randf_range(-1.0, 0.25)


## Puts [param along] on the grid the room is set out on, give or take a hand's width.
func _lined(along: float) -> float:
	return snappedf(along, SPACING) + _rng.randf_range(-0.6, 0.6)


## An angle for something that was put down rather than dropped: square with the table, off by a
## degree or two. A room where everything sits at its own angle reads as a mess however carefully
## each thing is made, and a room where everything is exactly square reads as a spreadsheet.
func _squared() -> float:
	return snappedf(_rng.randf_range(0.0, TAU), PI * 0.5) + _rng.randf_range(-0.05, 0.05)


## Whether [param at] is one of the places near the arena. Only the small things go there: a
## stack of boards half the length of the table, right behind the crowd, is a wall across the
## side of the screen.
func _close(at: Vector3) -> bool:
	var half := arena.world_size() * 0.5
	return absf(at.x) < half.x + CLOSE and absf(at.z) < half.y + CLOSE


## [param count] places on the near apron, where the camera looks across. Only things that lie
## flat go here.
func _apron(count: int) -> Array[Vector3]:
	var half := arena.world_size() * 0.5
	var out: Array[Vector3] = []
	for i: int in count:
		var along := _lined(_rng.randf_range(-1.0, 1.0) * (half.x + FAR))
		# Further out than the flanks: a pencil is longer than it is far from the wall otherwise.
		var away := NEAR + APRON_CLEAR + (FAR - NEAR - APRON_CLEAR) * pow(_rng.randf(), CROWDING)
		out.append(Vector3(along, TOP, half.y + _lined(away)))
	return out


# --- what is lying on the bench ----------------------------------------------


func _hammer(at: Vector3, steel: Material, handle: Material) -> void:
	var turn := _squared()
	var out := Vector3(sin(turn), 0.0, cos(turn))
	_turned(_box(Vector3(1.2, 1.2, 15.0), handle, at + Vector3(0.0, 0.6, 0.0)), turn)
	_turned(_box(Vector3(2.8, 2.6, 5.4), steel, at + Vector3(0.0, 1.3, 0.0) + out * 8.6), turn)


func _planks(at: Vector3, timber: Material) -> void:
	var turn := _squared()
	for i: int in _rng.randi_range(2, 3):
		var lift := Vector3(_rng.randf_range(-0.6, 0.6), 0.6 + float(i) * 1.2, 0.0)
		var plank := _box(Vector3(5.4, 1.2, 16.0), timber, at + lift)
		plank.rotation.y = turn + _rng.randf_range(-0.04, 0.04)


func _drill(at: Vector3, shell: Material, steel: Material) -> void:
	var turn := _squared()
	var out := Vector3(sin(turn), 0.0, cos(turn))
	_turned(_box(Vector3(3.6, 4.0, 9.0), shell, at + Vector3(0.0, 4.2, 0.0)), turn)
	_turned(_box(Vector3(3.0, 5.6, 3.6), shell, at + Vector3(0.0, 2.8, 0.0) - out * 2.2), turn)
	var bit := _cylinder(0.4, 5.0, steel, at + Vector3(0.0, 4.6, 0.0) + out * 7.0)
	bit.rotation = Vector3(PI * 0.5, turn, 0.0)


func _tin(at: Vector3, paint: Material, steel: Material) -> void:
	_cylinder(3.2, 6.2, paint, at + Vector3(0.0, 3.1, 0.0))
	_cylinder(3.4, 0.5, steel, at + Vector3(0.0, 6.2, 0.0))


func _mug(at: Vector3, china: Material) -> void:
	var turn := _squared()
	var out := Vector3(sin(turn), 0.0, cos(turn))
	_cylinder(2.6, 5.6, china, at + Vector3(0.0, 2.8, 0.0))
	_turned(_box(Vector3(0.8, 2.6, 0.8), china, at + Vector3(0.0, 3.4, 0.0) + out * 2.9), turn)


## A bundle of rod stock: three down, two nestled on top, all pointing the same way. Scattered
## singly they read as a spill rather than as something stacked against the day it is wanted.
func _rods(at: Vector3, steel: Material) -> void:
	var turn := _squared()
	var side := Vector3(cos(turn), 0.0, -sin(turn))
	var radius := 0.42
	var rows: Array[int] = [3, 2]
	for tier: int in rows.size():
		var count: int = rows[tier]
		for i: int in count:
			var across := (float(i) - float(count - 1) * 0.5) * radius * 2.05
			var lift := radius + float(tier) * radius * 1.75
			var rod := _cylinder(radius, 7.0, steel, at + side * across + Vector3(0.0, lift, 0.0))
			rod.rotation = Vector3(PI * 0.5, turn, 0.0)


## A pencil, lying along the edge of the bench rather than across it. It is longer than the gap
## between the crowd and the near edge of the table, so pointed at the arena it would lie over it.
func _pencil(at: Vector3, wood: Material, lead: Material) -> void:
	var turn := PI * 0.5 + _rng.randf_range(-0.3, 0.3)
	var out := Vector3(sin(turn), 0.0, cos(turn))
	var shaft := _cylinder(0.45, 9.0, wood, at + Vector3(0.0, 0.45, 0.0))
	shaft.rotation = Vector3(PI * 0.5, turn, 0.0)
	var tip := _cylinder(0.32, 1.2, lead, at + Vector3(0.0, 0.45, 0.0) + out * 5.0)
	tip.rotation = shaft.rotation


## A steel rule, lying along the front of the bench. The near apron takes flat things only, and
## a rule is the flattest thing in a workshop.
func _rule(at: Vector3, steel: Material) -> void:
	var turn := PI * 0.5 + _rng.randf_range(-0.25, 0.25)
	_turned(_box(Vector3(12.0, 0.18, 0.9), steel, at + Vector3(0.0, 0.09, 0.0)), turn)


func _tape(at: Vector3, shell: Material, steel: Material) -> void:
	var turn := _squared()
	var out := Vector3(sin(turn), 0.0, cos(turn))
	_turned(_box(Vector3(4.4, 4.2, 2.6), shell, at + Vector3(0.0, 2.1, 0.0)), turn)
	_turned(_box(Vector3(1.8, 0.16, 4.0), steel, at + Vector3(0.0, 0.1, 0.0) + out * 3.2), turn)


# --- what is lying on the baize ----------------------------------------------


## Chips, stacked and lined up: a player's stack is squared off in front of them rather than
## strewn about the baize.
func _chip_stack(at: Vector3) -> void:
	var colors: Array[Color] = [Palette.CHIP_RED, Palette.CHIP_WHITE, room.trim, Palette.NEON_CYAN]
	var turn := _squared()
	var side := Vector3(cos(turn), 0.0, -sin(turn))
	var count := _rng.randi_range(2, 3)
	for stack: int in count:
		var ink: Color = colors[_rng.randi_range(0, colors.size() - 1)]
		var chips := surfaces.painted(ink)
		var foot := at + side * (float(stack) - float(count - 1) * 0.5) * 2.4
		for i: int in _rng.randi_range(5, 11):
			_cylinder(1.0, 0.28, chips, foot + Vector3(0.0, 0.14 + float(i) * 0.28, 0.0))


## A deck or three, boxed, squared up the way a box of cards is left on a table.
func _card_deck(at: Vector3) -> void:
	var box := surfaces.printed(Surfaces.CARD_BACK)
	var turn := _squared()
	for i: int in _rng.randi_range(1, 3):
		var lift := Vector3(0.0, 0.4 + float(i) * 0.82, 0.0)
		_turned(_box(Vector3(2.4, 0.8, 3.4), box, at + lift), turn + _rng.randf_range(-0.1, 0.1))


## A hand fanned out and left. Flat pictures rather than boxes: a card is a card face, and the
## thickness of one is a tenth of the mesh it would take to carry it.
func _fanned_cards(at: Vector3) -> void:
	var face := surfaces.printed(Surfaces.CARD_FACE)
	var turn := _rng.randf_range(0.0, TAU)
	for i: int in 4:
		var card := PlaneMesh.new()
		card.size = Vector2(2.6, 3.6)
		var lying := _put(card, face, at + Vector3(0.0, 0.02, 0.0))
		lying.rotation.y = turn + float(i) * 0.26
		lying.position += Vector3(sin(lying.rotation.y), 0.0, cos(lying.rotation.y)) * 1.1


func _dice(at: Vector3) -> void:
	var ivory := surfaces.painted(Palette.CHIP_WHITE)
	for i: int in 2:
		var spot := at + Vector3(_rng.randf_range(-1.4, 1.4), 0.45, _rng.randf_range(-1.4, 1.4))
		_turned(_box(Vector3.ONE * 0.9, ivory, spot), _rng.randf_range(0.0, TAU))


func _glass(at: Vector3) -> void:
	var glass := surfaces.painted(Color(0.82, 0.86, 0.9))
	var drink := surfaces.painted(Color(0.72, 0.38, 0.12))
	_cylinder(1.3, 0.24, glass, at + Vector3(0.0, 0.12, 0.0))
	_cylinder(1.0, 3.0, glass, at + Vector3(0.0, 1.6, 0.0))
	_cylinder(0.88, 1.5, drink, at + Vector3(0.0, 1.15, 0.0))


# --- what is standing about the yard -----------------------------------------


func _scaffold(at: Vector3, steel: Material) -> void:
	var turn := _rng.randf_range(-0.5, 0.5)
	var width := 6.0
	var tall := 9.0
	for side: float in [-1.0, 1.0]:
		for depth: float in [-1.0, 1.0]:
			var foot := at + Vector3(0.0, tall * 0.5, depth * 1.4)
			var post := _cylinder(0.16, tall, steel, foot)
			post.position += Vector3(cos(turn), 0.0, sin(turn)) * side * width * 0.5
	for height: float in [2.2, 5.2, 8.2]:
		_turned(_box(Vector3(width, 0.24, 0.24), steel, at + Vector3(0.0, height, -1.4)), -turn)
		_turned(_box(Vector3(width, 0.24, 0.24), steel, at + Vector3(0.0, height, 1.4)), -turn)
	var deck := surfaces.painted(room.table.lightened(0.28))
	_turned(_box(Vector3(width, 0.3, 3.0), deck, at + Vector3(0.0, 5.4, 0.0)), -turn)


func _barrier(at: Vector3) -> void:
	var turn := _squared()
	var out := Vector3(cos(turn), 0.0, -sin(turn))
	var warn := surfaces.painted(Color(0.92, 0.55, 0.12))
	var pale := surfaces.painted(Color(0.9, 0.9, 0.88))
	var dark := surfaces.painted(Color(0.22, 0.22, 0.24))
	for i: int in 5:
		var skin := warn if i % 2 == 0 else pale
		var spot := at + Vector3(0.0, 1.4, 0.0) + out * (float(i) - 2.0) * 1.2
		_turned(_box(Vector3(1.2, 1.2, 0.4), skin, spot), turn)
	for side: float in [-1.0, 1.0]:
		var foot := at + Vector3(0.0, 1.0, 0.0) + out * side * 3.0
		_turned(_box(Vector3(0.3, 2.0, 1.6), dark, foot), turn)


## Barrels, stood in a row and one stacked on top, the way a yard keeps them.
func _barrels(at: Vector3, paint: Material, steel: Material) -> void:
	var turn := _squared()
	var side := Vector3(cos(turn), 0.0, -sin(turn))
	var count := _rng.randi_range(2, 3)
	for i: int in count:
		_barrel(at + side * (float(i) - float(count - 1) * 0.5) * 2.1, paint, steel)
	if count > 2:
		_barrel(at + Vector3(0.0, 2.6, 0.0), paint, steel)


func _barrel(at: Vector3, paint: Material, steel: Material) -> void:
	_cylinder(1.0, 2.6, paint, at + Vector3(0.0, 1.3, 0.0))
	for height: float in [0.8, 1.8]:
		_cylinder(1.06, 0.2, steel, at + Vector3(0.0, height, 0.0))


func _bricks(at: Vector3, clay: Material) -> void:
	var turn := _squared()
	for row: int in _rng.randi_range(4, 8):
		for i: int in 4:
			var lift := Vector3(0.0, 0.3 + float(row) * 0.62, (float(i) - 1.5) * 1.1)
			var brick := _box(Vector3(2.6, 0.6, 1.0), clay, at + lift)
			brick.rotation.y = turn + float(row % 2) * PI * 0.5


func _pallets(at: Vector3, timber: Material) -> void:
	var turn := _squared()
	for i: int in _rng.randi_range(2, 5):
		var lift := 0.3 + float(i) * 0.5
		_turned(_box(Vector3(4.0, 0.2, 3.2), timber, at + Vector3(0.0, lift, 0.0)), turn)
		for side: float in [-1.0, 0.0, 1.0]:
			var bearer := at + Vector3(0.0, lift - 0.25, side * 1.3)
			_turned(_box(Vector3(4.0, 0.3, 0.5), timber, bearer), turn)


func _container(at: Vector3) -> void:
	var paint := Color(0.24, 0.42, 0.34) if _rng.randf() < 0.5 else Color(0.5, 0.3, 0.2)
	var shell := surfaces.painted(paint)
	var rib := surfaces.metal(Color(0.5, 0.52, 0.5))
	var turn := _squared()
	_turned(_box(Vector3(9.0, 3.4, 3.4), shell, at + Vector3(0.0, 1.7, 0.0)), turn)
	for i: int in 5:
		var spot := at + Vector3((float(i) - 2.0) * 1.8, 1.7, 0.0)
		_turned(_box(Vector3(0.3, 3.5, 3.5), rib, spot), turn)


## Cones, set out in a line the way cones are set out.
func _cones(at: Vector3) -> void:
	var cone := surfaces.painted(Color(0.94, 0.42, 0.1))
	var base := surfaces.painted(Color(0.2, 0.2, 0.22))
	var turn := _squared()
	var side := Vector3(cos(turn), 0.0, -sin(turn))
	var count := _rng.randi_range(3, 5)
	for i: int in count:
		var foot := at + side * (float(i) - float(count - 1) * 0.5) * 2.6
		_box(Vector3(1.4, 0.2, 1.4), base, foot + Vector3(0.0, 0.1, 0.0))
		_taper(0.5, 0.1, 1.8, cone, foot + Vector3(0.0, 1.0, 0.0))


func _floodlight(at: Vector3, steel: Material) -> void:
	var bulb := surfaces.neon(Color(1.0, 0.94, 0.78), 0.8)
	_cylinder(0.4, 18.0, steel, at + Vector3(0.0, 9.0, 0.0))
	_box(Vector3(3.0, 0.4, 3.0), steel, at + Vector3(0.0, 0.2, 0.0))
	var head := _box(Vector3(6.0, 1.6, 1.2), steel, at + Vector3(0.0, 17.6, 0.6))
	head.rotation.x = 0.35
	for i: int in 3:
		var spot := at + Vector3((float(i) - 1.0) * 2.0, 17.2, 1.2)
		var lamp := _box(Vector3(1.6, 1.2, 0.3), bulb, spot)
		lamp.rotation.x = 0.35


func _truck(at: Vector3, steel: Material) -> void:
	var paint := surfaces.painted(Color(0.72, 0.24, 0.2))
	var glass := surfaces.painted(Color(0.16, 0.2, 0.26))
	var bed := surfaces.painted(room.table.lightened(0.3))
	var rubber := surfaces.painted(Color(0.13, 0.13, 0.15))
	_box(Vector3(4.2, 3.0, 4.4), paint, at + Vector3(0.0, 2.6, -4.6))
	_box(Vector3(4.3, 1.4, 0.3), glass, at + Vector3(0.0, 3.4, -6.7))
	_box(Vector3(4.4, 0.6, 12.0), steel, at + Vector3(0.0, 1.4, 0.4))
	_box(Vector3(4.4, 1.0, 10.0), bed, at + Vector3(0.0, 2.0, 2.4))
	for side: float in [-1.0, 1.0]:
		_box(Vector3(0.4, 1.6, 10.0), bed, at + Vector3(side * 2.0, 3.0, 2.4))
		for z: float in [-5.0, 2.0, 4.6]:
			var wheel := _cylinder(1.3, 0.9, rubber, at + Vector3(side * 2.1, 1.3, z))
			wheel.rotation.z = PI * 0.5


# --- the parts everything is made of ----------------------------------------


## Half the table: the arena and its overhang together.
func _table() -> Vector2:
	return (arena.world_size() + Vector2.ONE * Arena.TABLE_OVERHANG) * 0.5


## Half the room: the table and the clearance round it that the walls stand in.
func _room_half() -> Vector2:
	return _table() + Vector2.ONE * ROOM_CLEAR


func _box(size: Vector3, skin: Material, at: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _put(mesh, skin, at)


func _cylinder(radius: float, height: float, skin: Material, at: Vector3) -> MeshInstance3D:
	return _taper(radius, radius, height, skin, at)


func _taper(
	bottom: float, top: float, height: float, skin: Material, at: Vector3
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 1
	return _put(mesh, skin, at)


func _put(mesh: Mesh, skin: Material, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = skin
	node.position = at
	add_child(node)
	return node


## Turns a prop about its own upright, which is what makes one hammer different from the next.
func _turned(node: MeshInstance3D, turn: float) -> MeshInstance3D:
	node.rotation.y = turn
	return node


## The shell casts no shadows. A wall thirty metres tall standing in a directional light throws
## the whole room into the dark, and the shadow map has the table to be spending itself on.
func _dim(node: MeshInstance3D) -> MeshInstance3D:
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node
