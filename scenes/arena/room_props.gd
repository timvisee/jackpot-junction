class_name RoomProps
extends RoomBuild
## What is lying about in a room, GAME.md 8.1. The room itself is [RoomShell]; this is the tools
## of whoever built the thing left on the bench, the chips and decks out on the baize, and the
## scaffolding, barriers and the truck standing about the yard.
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

## How a prop is turned where it stands: square with the table a degree or two off, which is what
## says somebody put it there rather than dropped it; thrown, for the things that were thrown;
## along the front edge of the bench, for what lies on the near apron; loose, for a tower run up
## in a hurry; and not turned at all, for what a room places by hand.
enum Turned { SQUARE, THROWN, ALONG, LOOSE, FLAT }

## How much the clutter crowds the near end of that range: the square of a flat random, which puts
## two thirds of it in the first half.
const CROWDING := 1.7
## How far out a prop has to be before it is allowed to be one of the big ones.
const CLOSE := 12.0
## The grid the clutter is set out on. Things put down by somebody line up with the edge of the
## table and roughly with each other; things dropped at random read as a spill whatever they are.
const SPACING := 4.0
## How many places a prop tries before it is given up on, and how much clear table is left round
## one so that two of them read as two rather than as a heap.
const TRIES := 40
const ELBOW := 0.7
## The patch of table each kind of prop covers and how it is turned on it. The patch is measured
## off the parts the prop is built from, in the prop's own frame: across it is the rectangle's
## width and along it -- the way a hammer's handle points -- is its height.
##
## Every place is found with these, so a hammer fifteen metres long asks for fifteen metres of
## bench and a glass asks for three. One patch of the same size for every prop is what left rod
## stock lying through a stack of chips and barrels standing in each other however many places
## were tried, and a round patch big enough to hold a prop whichever way it was turned costs nine
## times the table a hammer lying on it does.
const PATCH := {
	&"lamp": [Rect2(-3.4, -3.4, 6.8, 15.8), Turned.FLAT],
	&"vice": [Rect2(-2.2, -2.3, 4.4, 7.4), Turned.FLAT],
	&"rods": [Rect2(-1.3, -3.2, 2.6, 6.4), Turned.SQUARE],
	&"tape": [Rect2(-2.2, -1.3, 4.4, 6.5), Turned.SQUARE],
	&"tin": [Rect2(-3.4, -3.4, 6.8, 6.8), Turned.FLAT],
	&"hammer": [Rect2(-1.4, -5.8, 2.8, 14.7), Turned.SQUARE],
	&"planks": [Rect2(-3.1, -5.5, 6.2, 11.0), Turned.SQUARE],
	&"drill": [Rect2(-1.8, -4.5, 3.6, 14.0), Turned.SQUARE],
	&"mug": [Rect2(-2.6, -2.6, 5.2, 5.9), Turned.SQUARE],
	&"pencil": [Rect2(-0.5, -3.8, 1.0, 8.7), Turned.ALONG],
	&"rule": [Rect2(-5.0, -0.5, 10.0, 1.0), Turned.ALONG],
	&"pendant": [Rect2(-4.2, -4.2, 8.4, 8.4), Turned.FLAT],
	&"dice": [Rect2(-1.5, -0.7, 3.0, 1.4), Turned.THROWN],
	&"cards": [Rect2(-3.4, -3.4, 6.8, 6.8), Turned.THROWN],
	&"chips": [Rect2(-3.4, -1.1, 6.8, 2.2), Turned.SQUARE],
	&"deck": [Rect2(-1.4, -1.9, 2.8, 3.8), Turned.SQUARE],
	&"glass": [Rect2(-1.3, -1.3, 2.6, 2.6), Turned.FLAT],
	&"floodlight": [Rect2(-3.5, -2.5, 7.0, 5.0), Turned.FLAT],
	&"truck": [Rect2(-2.8, -6.4, 5.6, 12.8), Turned.FLAT],
	&"forklift": [Rect2(-2.0, -3.8, 4.0, 6.6), Turned.FLAT],
	&"tape_along": [Rect2(-3.2, -0.4, 6.4, 0.8), Turned.FLAT],
	&"tape_across": [Rect2(-0.4, -2.7, 0.8, 5.4), Turned.FLAT],
	&"cones": [Rect2(-4.0, -0.8, 8.0, 1.6), Turned.SQUARE],
	&"pallets": [Rect2(-2.1, -1.7, 4.2, 3.4), Turned.SQUARE],
	&"barrels": [Rect2(-3.2, -1.1, 6.4, 2.2), Turned.SQUARE],
	&"barrel_row": [Rect2(-1.1, -3.2, 2.2, 6.4), Turned.FLAT],
	&"scaffold": [Rect2(-3.1, -1.6, 6.2, 3.2), Turned.LOOSE],
	&"container": [Rect2(-4.2, -1.8, 8.4, 3.6), Turned.SQUARE],
	&"bricks": [Rect2(-1.4, -3.0, 2.8, 6.0), Turned.SQUARE],
	&"barrier": [Rect2(-3.2, -0.9, 6.4, 1.8), Turned.SQUARE],
	&"tyres": [Rect2(-1.7, -1.7, 3.4, 3.4), Turned.SQUARE],
	&"chest": [Rect2(-1.9, -1.0, 3.8, 2.0), Turned.SQUARE],
	&"jerry": [Rect2(-1.6, -0.9, 3.2, 1.8), Turned.SQUARE],
	&"work_bench": [Rect2(-5.5, -1.4, 11.0, 2.8), Turned.FLAT],
	&"lift": [Rect2(-2.6, -4.2, 5.2, 8.4), Turned.FLAT],
}
## How much further out the near apron starts than the flanks do. Small on purpose: the apron is
## the one band of table the camera looks straight across, so what is put there is the closest
## thing to the player in the whole room.
const APRON_CLEAR := 1.0

## The room this clutter is lying about in, built alongside it.
var shell: RoomShell
## Every prop the room put down: what it is, where it stands, how far it reaches from there and
## which of this node's children it is made of. Kept rather than thrown away so that the rule of
## 8.1 -- nothing is put down inside anything else -- can be checked rather than hoped for.
var laid_out: Array[Dictionary] = []

## The patches the props have taken, squared off.
var _taken: Array[Rect2] = []
## The square patches somebody else spoke for before the clutter arrived: the booth the crowd
## keeps and the hoardings beside it. Squares, because that is the shape of them.
var _boxes: Array[Rect2] = []


## Dresses [param for_arena]'s room and returns the holder everything went into.
static func add_to(for_arena: Arena) -> RoomProps:
	var props := RoomProps.new()
	props._stand_in(for_arena, "Props")
	props.shell = RoomShell.add_to(for_arena)
	props._build()
	return props


func _build() -> void:
	_rng.seed = hash(room.id)
	if arena.crowd != null:
		_boxes.append_array(arena.crowd.taken_bays())
	match room.id:
		&"after_hours":
			_card_room()
		&"the_yard":
			_yard()
		&"garage":
			_garage()
		_:
			_workbench()
	# And the lot of it, the room it stands in as well, goes into as few meshes as it will go,
	# GAME.md 8.1: none of it moves and none of it is ever hidden on its own, so a chip does not
	# need a draw call of its own.
	if arena.bake_scenery:
		Bake.merge(self)
		Bake.merge(shell)


# --- the rooms ---------------------------------------------------------------


## A bench against a workshop wall: the table's own edge and legs, a pegboard over it, and the
## tools of whoever built the thing lying where they were put down.
func _workbench() -> void:
	shell.enclose(Color(0.15, 0.13, 0.12), Color(0.26, 0.22, 0.18), 32.0, 80.0)
	shell.skirt(room.table.darkened(0.32), 2.4)
	shell.legs(room.table.darkened(0.42))
	# A painted wall rather than more of the bench. A board in the table's own colour is a board
	# nobody can tell is there, which is what the back of this room was.
	var board := shell.backboard(24.0, Color(0.4, 0.38, 0.34))
	shell.pegboard(board)
	shell.calendar(board)
	var half := arena.world_size() * 0.5
	_lay(
		&"lamp",
		Vector3(-(half.x + 12.0), TOP, -(half.y + 10.0)),
		func(at: Vector3, _turn: float) -> void: _bench_lamp(at),
		true
	)
	_lay(
		&"vice",
		Vector3(-(half.x + 9.0), TOP, half.y * 0.25),
		func(at: Vector3, _turn: float) -> void: _vice(at),
		true
	)
	var timber := surfaces.painted(room.table.lightened(0.16))
	var steel := surfaces.metal(Color(0.64, 0.66, 0.7))
	# Rod stock is painted rather than metal: there is nothing in a dim workshop for a metal to
	# reflect, so a metal bar the size of this one reads as a black bar.
	var stock := surfaces.painted(Color(0.7, 0.72, 0.76))
	var handle := surfaces.painted(Color(0.58, 0.27, 0.16))
	var brass := surfaces.painted(Color(0.85, 0.78, 0.12))
	var tinplate := surfaces.painted(Color(0.76, 0.78, 0.82))
	var casing := surfaces.painted(Color(0.87, 0.66, 0.16))
	var china := surfaces.painted(Color(0.87, 0.88, 0.91))
	var pencil := surfaces.painted(Color(0.9, 0.72, 0.2))
	_ring(
		22,
		{
			&"rods": func(at: Vector3, turn: float) -> void: _rods(at, turn, stock),
			&"tape": func(at: Vector3, turn: float) -> void: _tape(at, turn, brass, steel),
			&"tin": func(at: Vector3, _turn: float) -> void: _tin(at, tinplate, steel),
		},
		{
			&"hammer": func(at: Vector3, turn: float) -> void: _hammer(at, turn, steel, handle),
			&"planks": func(at: Vector3, turn: float) -> void: _planks(at, turn, timber),
			&"drill": func(at: Vector3, turn: float) -> void: _drill(at, turn, casing, steel),
			&"mug": func(at: Vector3, turn: float) -> void: _mug(at, turn, china),
		}
	)
	_apron(
		4,
		{
			&"pencil": func(at: Vector3, turn: float) -> void: _pencil(at, turn, pencil, steel),
			&"rods": func(at: Vector3, turn: float) -> void: _rods(at, turn, stock),
			&"rule": func(at: Vector3, turn: float) -> void: _rule(at, turn, stock),
		}
	)


## A card room after hours: the baize is the floor, a rope line runs behind the crowd, and what
## the house plays with is left out around the table.
func _card_room() -> void:
	var wall := shell.enclose(Color(0.1, 0.045, 0.06), Color(0.17, 0.06, 0.09), 32.0, 80.0)
	shell.drape(wall)
	shell.pictures(wall)
	shell.skirt(room.table.darkened(0.34), 2.4)
	shell.legs(room.table.darkened(0.46))
	shell.rope_line()
	var half := arena.world_size() * 0.5
	for side: float in [-1.0, 1.0]:
		_lay(
			&"pendant",
			Vector3(side * half.x * 0.62, TOP, -(half.y + 10.0)),
			func(at: Vector3, _turn: float) -> void: _pendant(at),
			true
		)
	_ring(
		20,
		{&"dice": _dice, &"cards": _fanned_cards, &"chips": _chip_stack},
		{
			&"deck": _card_deck,
			&"glass": func(at: Vector3, _turn: float) -> void: _glass(at),
			&"chips": _chip_stack
		}
	)
	# More of it on the near apron than the other rooms put there, and most of it cards: a hand
	# fanned out on the baize is the one thing in here worth having close to the camera.
	_apron(4, {&"cards": _fanned_cards})
	_apron(2, {&"cards": _fanned_cards, &"dice": _dice})


## A yard between warehouse walls: an apron of concrete, hoarding along the back, floodlights over
## it and the things a yard has standing about in it.
func _yard() -> void:
	var wall := shell.enclose(Color(0.13, 0.13, 0.12), Color(0.25, 0.24, 0.22), 3.4, 46.0)
	shell.facade(wall)
	shell.sign(wall)
	shell.skirt(room.table.darkened(0.22), 3.2)
	shell.hoarding()
	shell.crowd_fence()
	shell.apron_markings()
	var steel := surfaces.metal(Color(0.72, 0.74, 0.78))
	var timber := surfaces.painted(room.table.lightened(0.26))
	var half := arena.world_size() * 0.5
	var rust := surfaces.painted(Color(0.78, 0.44, 0.14))
	var clay := surfaces.painted(Color(0.56, 0.29, 0.22))
	for side: float in [-1.0, 1.0]:
		var mast := Vector3(side * half.x * 0.8, TOP, -(half.y + 11.0))
		_lay(
			&"floodlight",
			mast,
			func(at: Vector3, _turn: float) -> void: _floodlight(at, steel),
			true
		)
	var truck := Vector3(-(half.x + 9.0), TOP, half.y * 0.1)
	_lay(&"truck", truck, func(at: Vector3, _turn: float) -> void: _truck(at, steel), true)
	_lay(
		&"forklift",
		Vector3(half.x + 8.0, TOP, -half.y * 0.45),
		func(at: Vector3, _turn: float) -> void: _forklift(at),
		true
	)
	for side: float in [-1.0, 1.0]:
		var line := Vector3(side * half.x * 0.55, TOP, -(half.y + 6.5))
		_lay(
			&"tape_along",
			line,
			func(at: Vector3, _turn: float) -> void: _hazard_tape(at, 6.0, 0.0),
			true
		)
	# Down the far flank rather than the near one, which is where the truck is parked.
	# A stack in against the fence on either flank, and side-on to it. Barrels are the one thing
	# in a yard a player wants to see and the one the dealing kept pushing out past the crowd: a
	# row of them broadside is six metres across, which is three more table than there is between
	# the back of the stands and where the clutter is allowed to start, so the only place one
	# could be dealt was out where nobody looks. Turned along the fence it is two metres across
	# and fits in beside the truck and the forklift.
	for drums: Vector3 in [
		Vector3(-(half.x + 9.5), TOP, -half.y * 1.05),
		Vector3(half.x + 9.5, TOP, -half.y * 1.25),
	]:
		_lay(
			&"barrel_row",
			drums,
			func(at: Vector3, _turn: float) -> void: _barrels(at, PI * 0.5, rust, steel),
			true
		)
	var across := Vector3(half.x + 7.0, TOP, half.y * 0.55)
	_lay(
		&"tape_across",
		across,
		func(at: Vector3, _turn: float) -> void: _hazard_tape(at, 5.0, PI * 0.5),
		true
	)
	_ring(
		22,
		{
			&"cones": _cones,
			&"pallets": func(at: Vector3, turn: float) -> void: _pallets(at, turn, timber),
			&"barrels": func(at: Vector3, turn: float) -> void: _barrels(at, turn, rust, steel),
		},
		{
			&"scaffold": func(at: Vector3, turn: float) -> void: _scaffold(at, turn, steel),
			&"container": _container,
			&"bricks": func(at: Vector3, turn: float) -> void: _bricks(at, turn, clay),
			&"barrier": _barrier,
		}
	)
	_apron(
		4,
		{
			&"cones": _cones,
			&"pallets": func(at: Vector3, turn: float) -> void: _pallets(at, turn, timber)
		}
	)


## The workshop the practice rooms of GAME.md 9.4 are in: a bay marked out on the floor of a place
## that fixes karts, with the doors at the back of it and the trade's own clutter round the walls.
##
## A floor rather than a table, and the one room with nobody watching, so its clutter comes right
## up to the bay. The eight metres the other rooms keep clear is the room the stands need; with no
## stands in it that band is bare concrete, and a room nobody is in reads as a room somebody has
## been cleared out of.
func _garage() -> void:
	clutter_from = 3.0
	# And the crowd's own patches go with it. It is built and then switched off in here, so what
	# it asked for is ground kept clear for people who never arrive.
	_boxes.clear()
	var wall := shell.enclose(Color(0.12, 0.125, 0.14), Color(0.28, 0.29, 0.31), 3.0, 40.0)
	shell.facade(wall)
	shell.sign(wall)
	shell.skirt(room.table.darkened(0.2), 2.6)
	var steel := surfaces.metal(Color(0.66, 0.68, 0.72))
	var timber := surfaces.painted(room.table.lightened(0.3))
	var rubber := surfaces.painted(Color(0.1, 0.1, 0.11))
	var rust := surfaces.painted(Color(0.74, 0.4, 0.13))
	var stock := surfaces.painted(Color(0.7, 0.72, 0.76))
	var tinplate := surfaces.painted(Color(0.78, 0.8, 0.84))
	var paint := surfaces.painted(Color(0.72, 0.18, 0.16))
	var half := arena.world_size() * 0.5
	# The bench along the back of the bay and the lift beside it: the two things a garage is built
	# round, and the two a player will see every time they come in here.
	_lay(
		&"work_bench",
		Vector3(0.0, TOP, -(half.y + 6.0)),
		func(at: Vector3, _turn: float) -> void: _work_bench(at, timber, steel, tinplate),
		true
	)
	_lay(
		&"lift",
		Vector3(half.x + 6.5, TOP, -(half.y + 4.0)),
		func(at: Vector3, _turn: float) -> void: _lift(at, steel, paint),
		true
	)
	_ring(
		20,
		{
			&"tyres": func(at: Vector3, turn: float) -> void: _tyres(at, turn, rubber, steel),
			&"chest": func(at: Vector3, turn: float) -> void: _chest(at, turn, paint, steel),
			&"jerry": func(at: Vector3, turn: float) -> void: _jerry(at, turn, rust, tinplate),
		},
		{
			&"barrels": func(at: Vector3, turn: float) -> void: _barrels(at, turn, rust, steel),
			&"pallets": func(at: Vector3, turn: float) -> void: _pallets(at, turn, timber),
			&"rods": func(at: Vector3, turn: float) -> void: _rods(at, turn, stock),
			&"tyres": func(at: Vector3, turn: float) -> void: _tyres(at, turn, rubber, steel),
		}
	)
	_apron(4, {&"jerry": func(at: Vector3, turn: float) -> void: _jerry(at, turn, rust, tinplate)})


## A stack of tyres, which is the one shape that says garage on its own. Worn down to the rim on
## the top one, the way a stack waiting to go out for scrap is.
func _tyres(at: Vector3, turn: float, rubber: Material, steel: Material) -> void:
	var high := _rng.randi_range(3, 5)
	for i: int in high:
		var lift := 0.34 + float(i) * 0.62
		_turned(_cylinder(1.5, 0.6, rubber, at + Vector3(0.0, lift, 0.0)), turn)
	_turned(
		_cylinder(0.78, 0.66, steel, at + Vector3(0.0, 0.34 + float(high - 1) * 0.62, 0.0)), turn
	)


## A rolling tool chest: a box of drawers on castors with a lid that has been left up.
func _chest(at: Vector3, turn: float, paint: Material, steel: Material) -> void:
	_turned(_box(Vector3(3.4, 2.6, 1.6), paint, at + Vector3(0.0, 1.5, 0.0)), turn)
	var out := Vector3(sin(turn), 0.0, cos(turn))
	for i: int in 3:
		var line := at + Vector3(0.0, 0.8 + float(i) * 0.72, 0.0) + out * 0.82
		_turned(_box(Vector3(3.0, 0.14, 0.12), steel, line), turn)
	_turned(_box(Vector3(3.6, 0.22, 1.8), steel, at + Vector3(0.0, 2.9, 0.0)), turn)
	for side: float in [-1.0, 1.0]:
		var across := Vector3(cos(turn), 0.0, -sin(turn)) * side * 1.3
		_turned(_cylinder(0.2, 0.2, steel, at + Vector3(0.0, 0.2, 0.0) + across), turn)


## A can or three of oil, squared off against something the way cans are left.
func _jerry(at: Vector3, turn: float, tin: Material, cap: Material) -> void:
	var across := Vector3(cos(turn), 0.0, -sin(turn))
	var count := _rng.randi_range(2, 3)
	for i: int in count:
		var foot := at + across * (float(i) - float(count - 1) * 0.5) * 1.15
		_turned(_box(Vector3(0.95, 1.5, 0.6), tin, foot + Vector3(0.0, 0.75, 0.0)), turn)
		_turned(_cylinder(0.16, 0.3, cap, foot + Vector3(0.0, 1.62, 0.0)), turn)


## The bench along the back of the bay: a top on legs with a vice on one end and tins along it.
func _work_bench(at: Vector3, timber: Material, steel: Material, tin: Material) -> void:
	_box(Vector3(11.0, 0.45, 2.4), timber, at + Vector3(0.0, 2.4, 0.0))
	for side: float in [-1.0, 1.0]:
		for depth: float in [-1.0, 1.0]:
			var leg := at + Vector3(side * 4.9, 1.1, depth * 0.9)
			_box(Vector3(0.35, 2.2, 0.35), steel, leg)
	_box(Vector3(11.0, 1.1, 0.25), timber, at + Vector3(0.0, 3.2, -1.1))
	for i: int in 3:
		var tin_at := at + Vector3(-3.4 + float(i) * 1.5, 3.05, 0.2)
		_cylinder(0.42, 0.85, tin, tin_at)
	_box(Vector3(1.4, 0.9, 1.0), steel, at + Vector3(4.2, 3.05, 0.0))


## The two-post lift a garage is built round, with nothing on it: the posts, the arms folded in
## and the plate they stand on.
func _lift(at: Vector3, steel: Material, paint: Material) -> void:
	_box(Vector3(4.6, 0.3, 7.6), steel, at + Vector3(0.0, 0.15, 0.0))
	for side: float in [-1.0, 1.0]:
		_box(Vector3(0.9, 6.4, 0.9), paint, at + Vector3(side * 1.9, 3.2, 0.0))
		for depth: float in [-1.0, 1.0]:
			var arm := at + Vector3(side * 1.9, 1.3, depth * 1.7)
			_box(Vector3(0.45, 0.4, 3.0), steel, arm)
	_box(Vector3(4.6, 0.5, 0.7), paint, at + Vector3(0.0, 6.4, 0.0))


# --- the shell ---------------------------------------------------------------


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


## Two lamps hung over the far side of a card room, out past the rope. They are what the room is
## dressed with rather than what it is lit by -- the light over the table is the table's own --
## but a bulb in the dark is worth having where the eye has nothing else to land on.
func _pendant(at: Vector3) -> void:
	var brass := surfaces.painted(room.trim.darkened(0.45))
	var high := 11.0
	_cylinder(0.2, 14.0, brass, at + Vector3(0.0, high + 7.0, 0.0))
	_taper(4.2, 1.0, 3.4, brass, at + Vector3(0.0, high, 0.0))
	_cylinder(3.4, 0.4, surfaces.neon(room.lamp_color, 0.45), at + Vector3(0.0, high - 1.6, 0.0))


## Tape across something nobody should walk into: two posts and a run of black and yellow between
## them, the way a yard cordons off whatever it has just dropped.
func _hazard_tape(at: Vector3, length: float, turn: float) -> void:
	var post := surfaces.metal(Color(0.5, 0.52, 0.5))
	var black := surfaces.painted(Color(0.12, 0.12, 0.13))
	var yellow := surfaces.painted(Color(0.93, 0.76, 0.12))
	var out := Vector3(cos(turn), 0.0, -sin(turn))
	var tall := 1.15
	for side: float in [-1.0, 1.0]:
		_cylinder(0.08, tall, post, at + Vector3(0.0, tall * 0.5, 0.0) + out * side * length * 0.5)
	var count := maxi(int(length / 0.9), 3)
	for i: int in count:
		var skin := black if i % 2 == 0 else yellow
		var span := length / float(count)
		var where := (
			at + Vector3(0.0, tall * 0.92, 0.0) + out * ((float(i) + 0.5) * span - length * 0.5)
		)
		var strip := _box(Vector3(span, 0.16, 0.05), skin, where)
		strip.rotation.y = turn


# --- where the clutter goes --------------------------------------------------


## Puts [param count] props round the far side and the two flanks of the table, past the crowd
## and short of the edge. [param near] is what may stand close to the arena and [param far] what
## has to keep its distance; each is a kind of prop and the way to build one.
##
## A prop that finds nowhere of its own to stand is left out rather than put down in something
## else. One thing fewer in a full room beats two of them in one place, and putting it down
## anyway is what the rooms were doing every time a place ran out.
func _ring(count: int, near: Dictionary, far: Dictionary) -> void:
	var half := arena.world_size() * 0.5
	var near_deal := _deal(near.size(), count)
	var far_deal := _deal(far.size(), count)
	# Each deck is dealt from its own place in the shuffle rather than from the slot number, so a
	# room that has three slots for big things deals the first three big things rather than the
	# third, the ninth and the thirteenth -- which is how a yard ended up with no barrels in it.
	var near_next := 0
	var far_next := 0
	for i: int in count:
		# Three out of five go behind the arena. The camera looks down the table, so that is the
		# side a player sees for most of a match; the flanks are only ever glimpsed. Which band a
		# prop belongs to is settled before the prop is, because the band is what decides whether
		# it may be one of the big ones: behind the arena is all within ten metres of the wall by
		# the time it clears the crowd, so the big things go down a flank and out past that.
		var behind := i % 5 < 3
		var big := not behind and i % 2 == 1
		var kinds := far if big else near
		var kind: StringName = kinds.keys()[far_deal[far_next] if big else near_deal[near_next]]
		if big:
			far_next += 1
		else:
			near_next += 1
		for attempt: int in TRIES:
			if _lay(kind, _spot(half, i, big), kinds[kind]):
				break


## A place to try: behind the arena for the first three of every five and down a flank for the
## other two, and out past [constant CLOSE] if it is one of the big ones.
func _spot(half: Vector2, index: int, big: bool) -> Vector3:
	var away := clutter_from + (FAR - clutter_from) * pow(_rng.randf(), CROWDING)
	if big:
		away = CLOSE + (FAR - CLOSE) * _rng.randf()
	if index % 5 < 3:
		var along := _rng.randf_range(-0.95, 0.95)
		return Vector3(_lined(along * half.x), TOP, -(half.y + minf(away, BACK_FAR)))
	var side := 1.0 if index % 5 == 3 else -1.0
	return Vector3(side * (half.x + away), TOP, _lined(_flank() * (half.y + clutter_from)))


## How far down a flank a prop may stand. The back of the table is fair game and the middle of
## it is fine, but the near corners are beside the camera rather than behind it, and something
## five metres tall there is in the corner of the picture the whole match.
func _flank() -> float:
	return _rng.randf_range(-1.0, 0.25)


## Whether [param box] is table nothing has spoken for. The shell's own runs and the patches the
## crowd keeps count as well, so nothing ends up standing in a fence or growing out of a hoarding.
func _free(box: Rect2) -> bool:
	for other: Rect2 in _taken:
		if other.intersects(box):
			return false
	for other: Rect2 in _boxes:
		if other.intersects(box):
			return false
	for other: Rect2 in shell.taken:
		if other.intersects(box):
			return false
	return true


## Where [param patch] lands when a prop is put down at [param at] turned by [param turn]: the
## smallest square-on rectangle round the turned patch, which for anything standing square with
## the table is very nearly the patch itself.
func _ground(patch: Rect2, at: Vector3, turn: float) -> Rect2:
	var out := Vector2(sin(turn), cos(turn))
	var across := Vector2(cos(turn), -sin(turn))
	var here := Vector2(at.x, at.z)
	var box := Rect2(here, Vector2.ZERO)
	for corner: int in 4:
		var local := patch.position + patch.size * Vector2(float(corner & 1), float(corner >> 1))
		box = box.expand(here + across * local.x + out * local.y)
	return box.grow(ELBOW)


## Puts a prop of [param kind] down at [param at], turned the way its kind is turned, and says
## whether it went. Everything a room puts out goes through here, so what a room has is what the
## list says it has. A dealt prop that finds the table taken is left out rather than put down in
## something else; [param by_hand] is for the handful a room places itself and means to have.
func _lay(kind: StringName, at: Vector3, build: Callable, by_hand := false) -> bool:
	var turn := _turn_of(PATCH[kind][1])
	var box := _ground(PATCH[kind][0], at, turn)
	if not by_hand and not _free(box):
		return false
	var from := get_child_count()
	build.call(at, turn)
	_taken.append(box)
	laid_out.append({"kind": kind, "box": box, "from": from, "to": get_child_count(), "turn": turn})
	return true


## The angle a prop of [param style] is turned to.
func _turn_of(style: int) -> float:
	match style:
		Turned.THROWN:
			return _rng.randf_range(0.0, TAU)
		Turned.ALONG:
			return PI * 0.5 + _rng.randf_range(-0.28, 0.28)
		Turned.LOOSE:
			return _rng.randf_range(-0.5, 0.5)
		Turned.FLAT:
			return 0.0
		_:
			return _squared()


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


## [param count] props on the near apron, where the camera looks across. Only things that lie
## flat go here, and one that finds nowhere is left out the same way the ring leaves one out.
func _apron(count: int, kinds: Dictionary) -> void:
	var half := arena.world_size() * 0.5
	var deal := _deal(kinds.size(), count)
	for i: int in count:
		var kind: StringName = kinds.keys()[deal[i]]
		for attempt: int in TRIES:
			var along := _lined(_rng.randf_range(-1.0, 1.0) * (half.x + FAR))
			# Further out than the flanks: a pencil is longer than it is far from the wall.
			var away := (
				clutter_from
				+ APRON_CLEAR
				+ (FAR - clutter_from - APRON_CLEAR) * pow(_rng.randf(), CROWDING)
			)
			var spot := Vector3(along, TOP, half.y + _lined(away))
			if _lay(kind, spot, kinds[kind]):
				break


# --- what is lying on the bench ----------------------------------------------


func _hammer(at: Vector3, turn: float, steel: Material, handle: Material) -> void:
	var out := Vector3(sin(turn), 0.0, cos(turn))
	_turned(_box(Vector3(1.2, 1.2, 11.5), handle, at + Vector3(0.0, 0.6, 0.0)), turn)
	_turned(_box(Vector3(2.8, 2.6, 4.6), steel, at + Vector3(0.0, 1.3, 0.0) + out * 6.6), turn)


func _planks(at: Vector3, turn: float, timber: Material) -> void:
	for i: int in _rng.randi_range(2, 3):
		var lift := Vector3(_rng.randf_range(-0.6, 0.6), 0.6 + float(i) * 1.2, 0.0)
		var plank := _box(Vector3(5.0, 1.2, 11.0), timber, at + lift)
		plank.rotation.y = turn + _rng.randf_range(-0.04, 0.04)


func _drill(at: Vector3, turn: float, shell: Material, steel: Material) -> void:
	var out := Vector3(sin(turn), 0.0, cos(turn))
	_turned(_box(Vector3(3.6, 4.0, 9.0), shell, at + Vector3(0.0, 4.2, 0.0)), turn)
	_turned(_box(Vector3(3.0, 5.6, 3.6), shell, at + Vector3(0.0, 2.8, 0.0) - out * 2.2), turn)
	var bit := _cylinder(0.4, 5.0, steel, at + Vector3(0.0, 4.6, 0.0) + out * 7.0)
	bit.rotation = Vector3(PI * 0.5, turn, 0.0)


func _tin(at: Vector3, paint: Material, steel: Material) -> void:
	_cylinder(3.2, 6.2, paint, at + Vector3(0.0, 3.1, 0.0))
	_cylinder(3.4, 0.5, steel, at + Vector3(0.0, 6.2, 0.0))


func _mug(at: Vector3, turn: float, china: Material) -> void:
	var out := Vector3(sin(turn), 0.0, cos(turn))
	_cylinder(2.6, 5.6, china, at + Vector3(0.0, 2.8, 0.0))
	_turned(_box(Vector3(0.8, 2.6, 0.8), china, at + Vector3(0.0, 3.4, 0.0) + out * 2.9), turn)


## A bundle of rod stock: three down, two nestled on top, all pointing the same way. Scattered
## singly they read as a spill rather than as something stacked against the day it is wanted.
func _rods(at: Vector3, turn: float, steel: Material) -> void:
	var side := Vector3(cos(turn), 0.0, -sin(turn))
	var radius := 0.42
	var rows: Array[int] = [3, 2]
	for tier: int in rows.size():
		var count: int = rows[tier]
		for i: int in count:
			var across := (float(i) - float(count - 1) * 0.5) * radius * 2.05
			var lift := radius + float(tier) * radius * 1.75
			var rod := _cylinder(radius, 6.4, steel, at + side * across + Vector3(0.0, lift, 0.0))
			rod.rotation = Vector3(PI * 0.5, turn, 0.0)


## A pencil, lying along the edge of the bench rather than across it. It is longer than the gap
## between the crowd and the near edge of the table, so pointed at the arena it would lie over it.
func _pencil(at: Vector3, turn: float, wood: Material, lead: Material) -> void:
	var out := Vector3(sin(turn), 0.0, cos(turn))
	var shaft := _cylinder(0.45, 7.6, wood, at + Vector3(0.0, 0.45, 0.0))
	shaft.rotation = Vector3(PI * 0.5, turn, 0.0)
	var tip := _cylinder(0.32, 1.2, lead, at + Vector3(0.0, 0.45, 0.0) + out * 4.3)
	tip.rotation = shaft.rotation


## A steel rule, lying along the front of the bench. The near apron takes flat things only, and
## a rule is the flattest thing in a workshop.
func _rule(at: Vector3, turn: float, steel: Material) -> void:
	_turned(_box(Vector3(10.0, 0.18, 0.9), steel, at + Vector3(0.0, 0.09, 0.0)), turn)


func _tape(at: Vector3, turn: float, shell: Material, steel: Material) -> void:
	var out := Vector3(sin(turn), 0.0, cos(turn))
	_turned(_box(Vector3(4.4, 4.2, 2.6), shell, at + Vector3(0.0, 2.1, 0.0)), turn)
	_turned(_box(Vector3(1.8, 0.16, 4.0), steel, at + Vector3(0.0, 0.1, 0.0) + out * 3.2), turn)


# --- what is lying on the baize ----------------------------------------------


## Chips, stacked and lined up: a player's stack is squared off in front of them rather than
## strewn about the baize.
func _chip_stack(at: Vector3, turn: float) -> void:
	var colors: Array[Color] = [Palette.CHIP_RED, Palette.CHIP_WHITE, room.trim, Palette.NEON_CYAN]
	var side := Vector3(cos(turn), 0.0, -sin(turn))
	var count := _rng.randi_range(2, 3)
	for stack: int in count:
		var ink: Color = colors[_rng.randi_range(0, colors.size() - 1)]
		var chips := surfaces.printed(Surfaces.CHIP_FACE, ink)
		var foot := at + side * (float(stack) - float(count - 1) * 0.5) * 2.4
		for i: int in _rng.randi_range(5, 11):
			_cylinder(1.0, 0.28, chips, foot + Vector3(0.0, 0.14 + float(i) * 0.28, 0.0))


## A deck or three, boxed, squared up the way a box of cards is left on a table.
func _card_deck(at: Vector3, turn: float) -> void:
	var box := surfaces.printed(Surfaces.CARD_BACK)
	for i: int in _rng.randi_range(1, 3):
		var lift := Vector3(0.0, 0.4 + float(i) * 0.82, 0.0)
		_turned(_box(Vector3(2.4, 0.8, 3.4), box, at + lift), turn + _rng.randf_range(-0.1, 0.1))


## A hand fanned out and left. Flat pictures rather than boxes: a card is a card face, and the
## thickness of one is a tenth of the mesh it would take to carry it.
func _fanned_cards(at: Vector3, turn: float) -> void:
	for i: int in 4:
		# A suit each. A hand of four of the same card is not a hand.
		var suit: Texture2D = Surfaces.CARD_FACES[_rng.randi_range(
			0, Surfaces.CARD_FACES.size() - 1
		)]
		var face := surfaces.printed(suit)
		var card := PlaneMesh.new()
		card.size = Vector2(2.6, 3.6)
		# Each one a finger higher than the last. Four pictures in one plane is four pictures
		# fighting over the same pixels, which is what a fanned hand was doing.
		var lying := _put(card, face, at + Vector3(0.0, 0.03 + float(i) * 0.04, 0.0))
		lying.rotation.y = turn + float(i) * 0.26
		lying.position += Vector3(sin(lying.rotation.y), 0.0, cos(lying.rotation.y)) * 1.1


## A pair of dice, pips and all. Drawn rather than printed: a box maps one picture across its six
## faces in pieces, so a die with a texture on it wears a quarter of a pip on each corner.
##
## Every face carries its own number and opposite faces come to seven, the way a die is made, so
## the one on top is whatever it was thrown as and the two you can see from the side agree with
## it. The face on the table is left off: nothing can see it, and it is six pips nobody will ever
## count.
func _dice(at: Vector3, turn: float) -> void:
	var ivory := surfaces.painted(Palette.CHIP_WHITE)
	var spots := surfaces.painted(Color(0.16, 0.14, 0.15))
	var size := 0.9
	# Thrown together and come to rest apart. They were dropped at their own random offsets, which
	# every so often put the two of them in the same place; now they are set down either side of
	# one, far enough apart that no corner of a die can reach the other however either one landed.
	# A cube turned about its upright reaches half its diagonal, so twice that is the closest two
	# of them can be and still be two.
	var side := Vector3(cos(turn), 0.0, -sin(turn))
	var apart := size * sqrt(2.0) * 1.3
	for i: int in 2:
		var spot := at + side * (float(i) - 0.5) * apart + Vector3(0.0, size * 0.5, 0.0)
		_die(spot, size, ivory, spots)


## One die: the cube, and the pips on the five faces that can be seen.
func _die(at: Vector3, size: float, ivory: Material, spots: Material) -> void:
	var turn := _rng.randf_range(0.0, TAU)
	_turned(_box(Vector3.ONE * size, ivory, at), turn)
	# The number on top is thrown; the four round the side are what is left, in pairs that come to
	# seven so that no two opposite faces ever show the same thing.
	var top := _rng.randi_range(1, 6)
	var rest: Array[int] = []
	for number: int in range(1, 7):
		if number != top and number != 7 - top:
			rest.append(number)
	var first: int = rest[0]
	var second: int = rest[1] if rest[1] != 7 - first else rest[2]
	var faces: Array[int] = [top, first, second, 7 - first, 7 - second]
	var out: Array[Vector3] = [
		Vector3.UP, Vector3.FORWARD, Vector3.RIGHT, Vector3.BACK, Vector3.LEFT
	]
	for i: int in faces.size():
		_pips(at, size, out[i].rotated(Vector3.UP, turn), faces[i], turn, spots)


## The pips of one face, laid out the way a die lays them out: corners, then the middle, then the
## two halfway up the sides for a six.
func _pips(
	at: Vector3, size: float, out: Vector3, number: int, turn: float, spots: Material
) -> void:
	var places: Array[Vector2] = []
	if number % 2 == 1:
		places.append(Vector2.ZERO)
	if number > 1:
		places.append(Vector2(-1.0, -1.0))
		places.append(Vector2(1.0, 1.0))
	if number > 3:
		places.append(Vector2(1.0, -1.0))
		places.append(Vector2(-1.0, 1.0))
	if number == 6:
		places.append(Vector2(-1.0, 0.0))
		places.append(Vector2(1.0, 0.0))
	# Two axes across the face, whichever way it is pointing.
	var across := Vector3.UP.cross(out)
	if across.length() < 0.01:
		across = Vector3.RIGHT.rotated(Vector3.UP, turn)
	across = across.normalized()
	var down := out.cross(across).normalized()
	var pip := size * 0.13
	for place: Vector2 in places:
		var on_face := out * (size * 0.5) + (across * place.x + down * place.y) * size * 0.26
		var mark := _box(Vector3(pip, pip, pip), spots, at + on_face - out * pip * 0.3)
		mark.rotation.y = turn


func _glass(at: Vector3) -> void:
	var glass := surfaces.painted(Color(0.82, 0.86, 0.9))
	var drink := surfaces.painted(Color(0.72, 0.38, 0.12))
	_cylinder(1.3, 0.24, glass, at + Vector3(0.0, 0.12, 0.0))
	_cylinder(1.0, 3.0, glass, at + Vector3(0.0, 1.6, 0.0))
	_cylinder(0.88, 1.5, drink, at + Vector3(0.0, 1.15, 0.0))


# --- what is standing about the yard -----------------------------------------


func _scaffold(at: Vector3, turn: float, steel: Material) -> void:
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


func _barrier(at: Vector3, turn: float) -> void:
	var out := Vector3(cos(turn), 0.0, -sin(turn))
	var warn := surfaces.painted(Color(0.93, 0.76, 0.12))
	var pale := surfaces.painted(Color(0.13, 0.13, 0.14))
	var dark := surfaces.painted(Color(0.22, 0.22, 0.24))
	for i: int in 5:
		var skin := warn if i % 2 == 0 else pale
		var spot := at + Vector3(0.0, 1.4, 0.0) + out * (float(i) - 2.0) * 1.2
		_turned(_box(Vector3(1.2, 1.2, 0.4), skin, spot), turn)
	for side: float in [-1.0, 1.0]:
		var foot := at + Vector3(0.0, 1.0, 0.0) + out * side * 3.0
		_turned(_box(Vector3(0.3, 2.0, 1.6), dark, foot), turn)


## Barrels, stood in a row and one stacked on top, the way a yard keeps them.
func _barrels(at: Vector3, turn: float, paint: Material, steel: Material) -> void:
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


func _bricks(at: Vector3, turn: float, clay: Material) -> void:
	var out := Vector3(sin(turn), 0.0, cos(turn))
	for row: int in _rng.randi_range(4, 8):
		for i: int in 4:
			var lift := Vector3(0.0, 0.3 + float(row) * 0.62, 0.0)
			var brick := _box(
				Vector3(2.6, 0.6, 1.0), clay, at + lift + out * (float(i) - 1.5) * 1.1
			)
			brick.rotation.y = turn + float(row % 2) * PI * 0.5


func _pallets(at: Vector3, turn: float, timber: Material) -> void:
	var out := Vector3(sin(turn), 0.0, cos(turn))
	for i: int in _rng.randi_range(2, 5):
		var lift := 0.3 + float(i) * 0.5
		_turned(_box(Vector3(4.0, 0.2, 3.2), timber, at + Vector3(0.0, lift, 0.0)), turn)
		for side: float in [-1.0, 0.0, 1.0]:
			var bearer := at + Vector3(0.0, lift - 0.25, 0.0) + out * side * 1.3
			_turned(_box(Vector3(4.0, 0.3, 0.5), timber, bearer), turn)


func _container(at: Vector3, turn: float) -> void:
	var paint := Color(0.24, 0.42, 0.34) if _rng.randf() < 0.5 else Color(0.5, 0.3, 0.2)
	var shell := surfaces.painted(paint)
	var rib := surfaces.metal(Color(0.5, 0.52, 0.5))
	var across := Vector3(cos(turn), 0.0, -sin(turn))
	_turned(_box(Vector3(8.4, 3.4, 3.4), shell, at + Vector3(0.0, 1.7, 0.0)), turn)
	for i: int in 5:
		var spot := at + Vector3(0.0, 1.7, 0.0) + across * (float(i) - 2.0) * 1.8
		_turned(_box(Vector3(0.3, 3.5, 3.5), rib, spot), turn)


## Cones, set out in a line the way cones are set out.
func _cones(at: Vector3, turn: float) -> void:
	var cone := surfaces.painted(Color(0.94, 0.42, 0.1))
	var base := surfaces.painted(Color(0.2, 0.2, 0.22))
	var side := Vector3(cos(turn), 0.0, -sin(turn))
	var count := _rng.randi_range(3, 4)
	for i: int in count:
		var foot := at + side * (float(i) - float(count - 1) * 0.5) * 2.2
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


## The forklift, parked nose out the way a yard parks one: a counterweight body, a mast with two
## uprights, forks on the floor in front of it and a cage over the seat.
func _forklift(at: Vector3) -> void:
	var paint := surfaces.painted(Color(0.92, 0.64, 0.1))
	var steel := surfaces.metal(Color(0.5, 0.52, 0.54))
	var rubber := surfaces.painted(Color(0.13, 0.13, 0.15))
	_box(Vector3(2.2, 1.5, 3.4), paint, at + Vector3(0.0, 1.05, 0.6))
	_box(Vector3(1.8, 0.9, 1.2), paint, at + Vector3(0.0, 1.9, 1.5))
	for side: float in [-1.0, 1.0]:
		_box(Vector3(0.18, 3.4, 0.18), steel, at + Vector3(side * 0.8, 1.7, -1.2))
		_box(Vector3(0.14, 2.6, 0.14), steel, at + Vector3(side * 0.95, 2.9, 1.3))
		_box(Vector3(0.28, 0.14, 2.0), steel, at + Vector3(side * 0.55, 0.12, -2.2))
		for z: float in [-0.6, 1.9]:
			var wheel := _cylinder(0.5, 0.42, rubber, at + Vector3(side * 1.0, 0.5, z))
			wheel.rotation.z = PI * 0.5
	_box(Vector3(2.0, 0.12, 2.0), steel, at + Vector3(0.0, 4.2, 1.3))


## The flatbed parked by the crowd: a chassis, a cab on the front of it, a bed behind that and
## six wheels. Every part sits on the one under it rather than inside it.
func _truck(at: Vector3, steel: Material) -> void:
	var paint := surfaces.painted(Color(0.72, 0.24, 0.2))
	var glass := surfaces.painted(Color(0.16, 0.2, 0.26))
	var bed := surfaces.painted(room.table.lightened(0.3))
	var rubber := surfaces.painted(Color(0.13, 0.13, 0.15))
	_box(Vector3(4.4, 0.6, 12.0), steel, at + Vector3(0.0, 1.4, 0.0))
	_box(Vector3(4.2, 3.0, 4.0), paint, at + Vector3(0.0, 3.2, -4.0))
	_box(Vector3(4.3, 1.2, 0.2), glass, at + Vector3(0.0, 3.8, -6.05))
	_box(Vector3(4.4, 0.4, 7.6), bed, at + Vector3(0.0, 1.9, 2.0))
	_box(Vector3(4.4, 1.4, 0.3), bed, at + Vector3(0.0, 2.8, -1.85))
	for side: float in [-1.0, 1.0]:
		_box(Vector3(0.3, 1.4, 7.6), bed, at + Vector3(side * 2.05, 2.8, 2.0))
		for z: float in [-4.2, 2.6, 5.0]:
			var wheel := _cylinder(1.3, 0.9, rubber, at + Vector3(side * 2.3, 1.3, z))
			wheel.rotation.z = PI * 0.5
