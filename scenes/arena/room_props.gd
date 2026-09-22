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

## How much the clutter crowds the near end of that range: the square of a flat random, which puts
## two thirds of it in the first half.
const CROWDING := 1.7
## How far out a prop has to be before it is allowed to be one of the big ones.
const CLOSE := 12.0
## The grid the clutter is set out on. Things put down by somebody line up with the edge of the
## table and roughly with each other; things dropped at random read as a spill whatever they are.
const SPACING := 4.0
## The patch of table a prop takes for itself, and how many places it will try before it settles
## for one it has to share. Two stacks of chips in the same square metre read as one broken stack.
##
## Two sizes of patch, because there are two sizes of prop: a bundle of rod stock is a bay, a
## stack of boards is nearly twice one, and a small patch round a long thing is a long thing
## lying through whatever was put down next to it.
const BAY := 8.0
const BIG_BAY := 13.0
const TRIES := 12
## How much further out the near apron starts than the flanks do.
const APRON_CLEAR := 3.0

## The room this clutter is lying about in, built alongside it.
var shell: RoomShell

## What is already standing out here: the booth, the hoardings and whatever else asked the crowd
## for a patch, plus every prop put down since. Nothing is placed on top of anything in it.
var _taken: Array[Rect2] = []


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
		# Grown by half a bay: the patches the crowd keeps are the footprints of the things in
		# them, and a prop that only just misses a hoarding still reads as one growing out of it.
		for bay: Rect2 in arena.crowd.taken_bays():
			_taken.append(bay.grow(BAY * 0.5))
	match room.id:
		&"after_hours":
			_card_room()
		&"the_yard":
			_yard()
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
	var lamp := Vector3(-(half.x + 12.0), TOP, -(half.y + 10.0))
	_bench_lamp(lamp)
	_claim(lamp + Vector3(0.0, 0.0, 5.0), Vector2(10.0, 16.0))
	var vice := Vector3(-(half.x + 9.0), TOP, half.y * 0.25)
	_vice(vice)
	_claim(vice, Vector2(8.0, 8.0))
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
	var wall := shell.enclose(Color(0.1, 0.045, 0.06), Color(0.17, 0.06, 0.09), 32.0, 80.0)
	shell.drape(wall)
	shell.pictures(wall)
	shell.skirt(room.table.darkened(0.34), 2.4)
	shell.legs(room.table.darkened(0.46))
	shell.rope_line()
	var half := arena.world_size() * 0.5
	for side: float in [-1.0, 1.0]:
		var hung := Vector3(side * half.x * 0.62, TOP, -(half.y + 10.0))
		_pendant(hung)
		_claim(hung, Vector2(9.0, 9.0))
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
	for side: float in [-1.0, 1.0]:
		var mast := Vector3(side * half.x * 0.8, TOP, -(half.y + 11.0))
		_floodlight(mast, steel)
		_claim(mast, Vector2(8.0, 8.0))
	var truck := Vector3(-(half.x + 9.0), TOP, half.y * 0.1)
	_truck(truck, steel)
	_claim(truck, Vector2(9.0, 17.0))
	var lift := Vector3(half.x + 8.0, TOP, -half.y * 0.45)
	_forklift(lift)
	_claim(lift, Vector2(8.0, 12.0))
	for side: float in [-1.0, 1.0]:
		var line := Vector3(side * half.x * 0.55, TOP, -(half.y + 6.5))
		_hazard_tape(line, 6.0, 0.0)
		_claim(line, Vector2(7.0, 4.0))
	var across := Vector3(-(half.x + 7.0), TOP, half.y * 0.55)
	_hazard_tape(across, 5.0, PI * 0.5)
	_claim(across, Vector2(4.0, 6.0))
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


## [param count] places round the far side and the two flanks of the table, past the crowd and
## short of the edge.
func _ring(count: int) -> Array[Vector3]:
	var half := arena.world_size() * 0.5
	var out: Array[Vector3] = []
	for i: int in count:
		var spot := Vector3.ZERO
		for attempt: int in TRIES:
			var away := _lined(NEAR + (FAR - NEAR) * pow(_rng.randf(), CROWDING))
			var along := _rng.randf_range(-0.95, 0.95)
			# Three out of five go behind the arena. The camera looks down the table, so that is
			# the side a player sees for most of a match; the flanks are only ever glimpsed.
			match i % 5:
				0, 1, 2:
					spot = Vector3(_lined(along * half.x), TOP, -(half.y + minf(away, BACK_FAR)))
				3:
					spot = Vector3(half.x + away, TOP, _lined(_flank() * (half.y + NEAR)))
				_:
					spot = Vector3(-(half.x + away), TOP, _lined(_flank() * (half.y + NEAR)))
			if _free(spot):
				break
		out.append(_claimed(spot))
	return out


## How far down a flank a prop may stand. The back of the table is fair game and the middle of
## it is fine, but the near corners are beside the camera rather than behind it, and something
## five metres tall there is in the corner of the picture the whole match.
func _flank() -> float:
	return _rng.randf_range(-1.0, 0.25)


## Whether nothing has been put down in [param at]'s own patch yet. The shell's own patches count
## as well, so nothing ends up standing in a fence or through a hoarding.
func _free(at: Vector3) -> bool:
	var bay := _bay(at)
	for other: Rect2 in _taken:
		if other.intersects(bay):
			return false
	for other: Rect2 in shell.taken:
		if other.intersects(bay):
			return false
	return true


## Takes a patch of [param span] round [param at] for something placed by hand rather than by the
## ring: the lamp over the bench, the truck, the floodlights. Anything put down afterwards goes
## somewhere else.
func _claim(at: Vector3, span: Vector2) -> void:
	_taken.append(Rect2(at.x - span.x * 0.5, at.z - span.y * 0.5, span.x, span.y))


## Takes [param at]'s patch, so the next thing goes somewhere else, and hands the place back.
func _claimed(at: Vector3) -> Vector3:
	_taken.append(_bay(at))
	return at


func _bay(at: Vector3) -> Rect2:
	var span := BAY if _close(at) else BIG_BAY
	return Rect2(at.x - span * 0.5, at.z - span * 0.5, span, span)


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
		var spot := Vector3.ZERO
		for attempt: int in TRIES:
			var along := _lined(_rng.randf_range(-1.0, 1.0) * (half.x + FAR))
			# Further out than the flanks: a pencil is longer than it is far from the wall.
			var away := (
				NEAR + APRON_CLEAR + (FAR - NEAR - APRON_CLEAR) * pow(_rng.randf(), CROWDING)
			)
			spot = Vector3(along, TOP, half.y + _lined(away))
			if _free(spot):
				break
		out.append(_claimed(spot))
	return out


# --- what is lying on the bench ----------------------------------------------


func _hammer(at: Vector3, steel: Material, handle: Material) -> void:
	var turn := _squared()
	var out := Vector3(sin(turn), 0.0, cos(turn))
	_turned(_box(Vector3(1.2, 1.2, 11.5), handle, at + Vector3(0.0, 0.6, 0.0)), turn)
	_turned(_box(Vector3(2.8, 2.6, 4.6), steel, at + Vector3(0.0, 1.3, 0.0) + out * 6.6), turn)


func _planks(at: Vector3, timber: Material) -> void:
	var turn := _squared()
	for i: int in _rng.randi_range(2, 3):
		var lift := Vector3(_rng.randf_range(-0.6, 0.6), 0.6 + float(i) * 1.2, 0.0)
		var plank := _box(Vector3(5.0, 1.2, 11.0), timber, at + lift)
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
			var rod := _cylinder(radius, 6.4, steel, at + side * across + Vector3(0.0, lift, 0.0))
			rod.rotation = Vector3(PI * 0.5, turn, 0.0)


## A pencil, lying along the edge of the bench rather than across it. It is longer than the gap
## between the crowd and the near edge of the table, so pointed at the arena it would lie over it.
func _pencil(at: Vector3, wood: Material, lead: Material) -> void:
	var turn := PI * 0.5 + _rng.randf_range(-0.3, 0.3)
	var out := Vector3(sin(turn), 0.0, cos(turn))
	var shaft := _cylinder(0.45, 7.6, wood, at + Vector3(0.0, 0.45, 0.0))
	shaft.rotation = Vector3(PI * 0.5, turn, 0.0)
	var tip := _cylinder(0.32, 1.2, lead, at + Vector3(0.0, 0.45, 0.0) + out * 4.3)
	tip.rotation = shaft.rotation


## A steel rule, lying along the front of the bench. The near apron takes flat things only, and
## a rule is the flattest thing in a workshop.
func _rule(at: Vector3, steel: Material) -> void:
	var turn := PI * 0.5 + _rng.randf_range(-0.25, 0.25)
	_turned(_box(Vector3(10.0, 0.18, 0.9), steel, at + Vector3(0.0, 0.09, 0.0)), turn)


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
		var chips := surfaces.printed(Surfaces.CHIP_FACE, ink)
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
	var turn := _rng.randf_range(0.0, TAU)
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


## A pair of dice, pips and all. Drawn rather than printed: a box maps one picture across its
## six faces in pieces, so a die with a texture on it wears a quarter of a pip on each corner.
func _dice(at: Vector3) -> void:
	var ivory := surfaces.painted(Palette.CHIP_WHITE)
	var spots := surfaces.painted(Color(0.16, 0.14, 0.15))
	var size := 0.9
	for i: int in 2:
		var spot := (
			at + Vector3(_rng.randf_range(-1.4, 1.4), size * 0.5, _rng.randf_range(-1.4, 1.4))
		)
		var turn := _rng.randf_range(0.0, TAU)
		_turned(_box(Vector3.ONE * size, ivory, spot), turn)
		# Five on the face that is looked at, which is the only one a camera over a table sees.
		for pip: Vector2 in [
			Vector2(-1, -1), Vector2(1, -1), Vector2(0, 0), Vector2(-1, 1), Vector2(1, 1)
		]:
			var across := Vector3(pip.x, 0.0, pip.y) * size * 0.26
			var on_top := spot + Vector3(0.0, size * 0.5, 0.0) + across.rotated(Vector3.UP, turn)
			_box(Vector3(size * 0.16, size * 0.06, size * 0.16), spots, on_top)


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
	_turned(_box(Vector3(8.4, 3.4, 3.4), shell, at + Vector3(0.0, 1.7, 0.0)), turn)
	for i: int in 5:
		var spot := at + Vector3((float(i) - 2.0) * 1.8, 1.7, 0.0)
		_turned(_box(Vector3(0.3, 3.5, 3.5), rib, spot), turn)


## Cones, set out in a line the way cones are set out.
func _cones(at: Vector3) -> void:
	var cone := surfaces.painted(Color(0.94, 0.42, 0.1))
	var base := surfaces.painted(Color(0.2, 0.2, 0.22))
	var turn := _squared()
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
