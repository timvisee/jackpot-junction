class_name RoomKit
extends RefCounted
## What the things inside the arena are made of, GAME.md 8.1: the walls the karts drive between
## and the boxes they shoot. The shapes are the room's to decide, the way the colors are.
##
## The rule is that the play is untouched. A wall is the same block it always was and a box is
## the same cube: what a room adds is the top of the wall, which nothing drives through, and the
## way the box is put together, which is the same cube seen closer. A card room stacks its boxes
## out of deck packs, a workshop out of offcuts, a yard out of cement sacks; every wall gets a
## capping strip so that it reads as a block rather than as a slab, and some of them carry
## something small, up where it is out of the way.
##
## The cash-out pad is the same bargain. It is the same disc of the same size in the same place
## whatever room it is in, and a kart drives onto it and banks exactly as it always did; what the
## room decides is what is painted on it.

## The step on top of a wall: how much of the wall's height it takes and how far in from the side
## it stands. It is a shape rather than a line -- a block with a smaller block on it, the way a
## toy brick is molded -- because a strip laid into the top face of a wall shares a plane with
## the side of it and the two flicker against each other from every angle.
const STEP := 0.26
const STEP_INSET := 0.09
## How far the step sinks into the block under it, so that no two faces of the pair ever lie in
## the same plane.
const STEP_BITE := 0.02
## How thick the brass bead rolled along a tin wall's cap is.
const BEAD := 0.05
## How often a wall carries something on top of it, and how long a wall has to be to qualify.
const DRESSED_WALLS := 3
const LONG_ENOUGH := 2.0
## The neon round the top of a card room's pit, see [method _pit_neon]: a dark red, for the one
## thing on the table that kills, where the room's own neon is its pink and its blue, and only just
## lit, an edge to be found rather than a sign that shouts.
const PIT_NEON := Color(0.62, 0.12, 0.12)
const PIT_GLOW := 0.35
## How high something dropped on the floor of the arena may stand. Below this it is litter: a card
## face down on the baize, a washer on the bench, a scrap of paper in the yard. Nothing this low
## is in anybody's way, and a floor with nothing at all on it reads as a floor rather than as a
## place somebody has been.
const LITTER := 0.12
## How thick the paint on the cash-out pad is, and how far each layer of it stands over the one
## under. Paint on the floor rather than a thing standing on it: a kart drives straight over the
## middle of the pad every time it banks, so nothing here has any height worth the name.
const PAD := 0.05
const LAYER := 0.006
## How wide the rim that blinks is. Whatever a room paints on the pad stops short of it: the rim
## stands a little proud of the paint, and a face that ran under it was a face with its outside
## edge hidden by the one part of the pad that is not the room's to decide.
const RIM := 0.25
## How many pockets the wheel After Hours has and how many stripes go round the Yard's border.
## A real wheel has thirty-seven; this is short of that and well past the dozen and a half it
## started at, which read as a pie chart rather than as a wheel.
const POCKETS := 28
const STRIPES := 20

var room: RoomLook
var surfaces: Surfaces

## Seeded off the room, so a map is furnished the same way twice running.
var _rng := RandomNumberGenerator.new()


func _init(for_room: RoomLook, for_surfaces: Surfaces) -> void:
	room = for_room
	surfaces = for_surfaces
	_rng.seed = hash(room.id)


## The breakable box, built the way its room would have it. [param size] is the cube the collider
## uses: everything here stays inside it, so cover is the same shape whatever it is made of.
func crate(size: Vector3) -> Node3D:
	var holder := Node3D.new()
	holder.name = "Box"
	match room.id:
		&"after_hours":
			_deck_packs(holder, size)
		&"the_yard":
			_sacks(holder, size)
		&"garage":
			_part_boxes(holder, size)
		&"count_room":
			CountKit.drives(holder, size, surfaces, room)
		&"workbench":
			_card_tin(holder, size)
		_:
			_offcuts(holder, size)
	return holder


## A wall, as it is seen: the block itself, the step on top of it and, on some of them, whatever
## the room leaves up there. The collider is the arena's and is the full box, so what a kart
## drives into is the shape it was before any of this.
func wall(size: Vector3, index: int) -> Node3D:
	var holder := Node3D.new()
	holder.name = "Wall"
	# The Count Room's walls are its racks, STORY.md 3.9, and nothing is left on top of them.
	if room.id == &"count_room":
		CountKit.rack(holder, size, surfaces, room)
		if index % DRESSED_WALLS == 1 and maxf(size.x, size.z) >= LONG_ENOUGH:
			CountKit.patch_cable(holder, size, surfaces, _rng)
		# And on others one left on the floor at the rack's foot, in any of the cables' colors.
		if index % DRESSED_WALLS == 2 and maxf(size.x, size.z) >= LONG_ENOUGH:
			CountKit.floor_cable(holder, size, surfaces, _rng)
		return holder
	var step := size.y * STEP
	var block := Vector3(size.x, size.y - step, size.z)
	# Pressed tin with the House's band printed round it, under a rolled brass cap, GAME.md 8.1b.
	_box(holder, block, surfaces.tin(room.wall, room.wall_print), Vector3(0.0, -step * 0.5, 0.0))
	var inset := minf(STEP_INSET, minf(size.x, size.z) * 0.2)
	var top := Vector3(size.x - inset * 2.0, step + STEP_BITE, size.z - inset * 2.0)
	var sits := (size.y - step - STEP_BITE) * 0.5 + STEP_BITE * 0.5
	_box(holder, top, surfaces.sheet(room.wall.lightened(0.06)), Vector3(0.0, sits, 0.0))
	_beads(holder, top, sits)
	if index % DRESSED_WALLS != 0 or maxf(size.x, size.z) < LONG_ENOUGH:
		return holder
	var along := Vector3(1.0, 0.0, 0.0) if size.x > size.z else Vector3(0.0, 0.0, 1.0)
	var run := maxf(size.x, size.z) * 0.5 - 0.6
	var at := along * _rng.randf_range(-run, run) + Vector3(0.0, size.y * 0.5, 0.0)
	match room.id:
		&"after_hours":
			_chips(holder, at)
		&"the_yard":
			_cone(holder, at)
		_:
			_bolts(holder, at)
	return holder


## What is waiting at the bottom of a pit, GAME.md 8.1, and what the room paints round the top of
## it. A hole in the floor with nothing in it is a hole; a hole with something in it is a reason
## to stay out of it, which is what a pit is for.
##
## Nothing here is in the way. The pit kills whatever falls in before any of it is touched, and
## all of it sits below the floor.
func pit(into: Node3D, size: Vector2) -> void:
	if room.id == &"count_room":
		CountKit.lifted_tiles(into, size, surfaces, _rng)
		return
	var spike := _spike_ink()
	var rows := maxi(int(size.y / 0.42), 3)
	var columns := maxi(int(size.x / 0.42), 3)
	for row: int in rows:
		for column: int in columns:
			var at := Vector3(
				(float(column) - float(columns - 1) * 0.5) * size.x / float(columns),
				-Arena.PIT_DEPTH,
				(float(row) - float(rows - 1) * 0.5) * size.y / float(rows)
			)
			var tall := _rng.randf_range(0.5, 0.78) * Arena.PIT_DEPTH
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.0
			mesh.bottom_radius = _rng.randf_range(0.08, 0.12)
			mesh.height = tall
			mesh.radial_segments = 6
			mesh.rings = 1
			_put(into, mesh, spike, at + Vector3(0.0, tall * 0.5, 0.0))
	if room.id == &"the_yard":
		_pit_hazard(into, size)
	elif room.id == &"after_hours":
		_pit_neon(into, size)


## What a room's spikes are made of: rusted rebar in the yard, bright nails on the bench, and
## whatever the dark under a card table is made of in the card room.
func _spike_ink() -> Material:
	match room.id:
		&"after_hours":
			return surfaces.painted(Color(0.16, 0.12, 0.13))
		&"the_yard":
			return surfaces.painted(Color(0.46, 0.26, 0.16))
		&"garage":
			return surfaces.metal(Color(0.34, 0.33, 0.3))
		_:
			return surfaces.metal(Color(0.62, 0.64, 0.68))


## The black and yellow round the top of a yard's pit, painted on the floor rather than standing
## on it: the one marking on the floor that is a warning rather than a decoration.
func _pit_hazard(into: Node3D, size: Vector2) -> void:
	var black := surfaces.marking(Color(0.11, 0.11, 0.12))
	var yellow := surfaces.marking(Color(0.93, 0.76, 0.12))
	var band := 0.34
	var step := 0.44
	for side: int in 4:
		var along := side % 2 == 0
		# The two runs across take the corners and the two down stop short of them, so no two
		# blocks of it stand in the same place.
		var span := (size.x + band * 2.0) if along else size.y
		var count := maxi(int(span / step), 2)
		for i: int in count:
			var offset := (float(i) + 0.5) * span / float(count) - span * 0.5
			var out := (
				((size.y if along else size.x) * 0.5 + band * 0.5) * (1.0 if side < 2 else -1.0)
			)
			var at := Vector3(offset, 0.006, out) if along else Vector3(out, 0.006, offset)
			var size3 := (
				Vector3(span / float(count), 0.01, band)
				if along
				else Vector3(band, 0.01, span / float(count))
			)
			_box(into, size3, black if i % 2 == 0 else yellow, at)


## A thin red neon round the top of a card room's pit. That room is lit by one lamp over a dark
## table, and a dark hole in dark felt out past the lamp's brightest was a hole nobody could see
## until they were in it; the room's own light, the neon, says where the edge is.
func _pit_neon(into: Node3D, size: Vector2) -> void:
	var lit := surfaces.neon(PIT_NEON, PIT_GLOW)
	var band := 0.06
	for side: int in 4:
		var along := side % 2 == 0
		var out := ((size.y if along else size.x) + band) * 0.5 * (1.0 if side < 2 else -1.0)
		var at := Vector3(0.0, 0.008, out) if along else Vector3(out, 0.008, 0.0)
		var run := (
			Vector3(size.x + band * 2.0, 0.012, band) if along else Vector3(band, 0.012, size.y)
		)
		_box(into, run, lit, at)


## A few small things dropped on the floor the karts drive on, GAME.md 8.1. Flat enough to be
## driven over without noticing and small enough to be missed at a glance, which is the point.
## Only empty floor takes any: nothing lands on a pad, in a pit or under a wall.
func litter(into: Node3D, grid: ArenaGrid, count: int) -> void:
	# Nobody has ever been in the Count Room to drop anything, STORY.md 3.9.
	if room.id == &"count_room":
		return
	var dropped := 0
	for attempt: int in count * 14:
		if dropped >= count:
			return
		var cell := Vector2i(
			_rng.randi_range(1, grid.width - 2), _rng.randi_range(1, grid.height - 2)
		)
		if grid.glyph(cell) != ArenaGrid.FLOOR:
			continue
		var at := grid.cell_center(cell)
		at.y = 0.0
		at += Vector3(_rng.randf_range(-0.3, 0.3), 0.0, _rng.randf_range(-0.3, 0.3))
		_dropped(into, at)
		dropped += 1


## What a room leaves on its own floor.
func _dropped(into: Node3D, at: Vector3) -> void:
	match room.id:
		&"after_hours":
			if _rng.randf() < 0.6:
				_stray_card(into, at)
			else:
				_stray_chip(into, at)
		&"the_yard":
			_stray_scrap(into, at)
		_:
			_stray_washer(into, at)


## A card somebody dropped, face up or face down.
func _stray_card(into: Node3D, at: Vector3) -> void:
	var faces := Surfaces.CARD_FACES
	var picture: Texture2D = faces[_rng.randi_range(0, faces.size() - 1)]
	if _rng.randf() < 0.35:
		picture = Surfaces.card_back()
	var card := PlaneMesh.new()
	card.size = Vector2(0.44, 0.62)
	var lying := _put(into, card, surfaces.printed(picture), at + Vector3(0.0, 0.012, 0.0))
	lying.rotation.y = _rng.randf_range(0.0, TAU)


func _stray_chip(into: Node3D, at: Vector3) -> void:
	var colors: Array[Color] = [Palette.CHIP_RED, Palette.CHIP_WHITE, room.trim]
	var ink: Color = colors[_rng.randi_range(0, colors.size() - 1)]
	var chips := surfaces.printed(Surfaces.CHIP_FACE, ink)
	_cylinder(into, 0.17, 0.05, chips, at + Vector3(0.0, 0.025, 0.0))


## A scrap of paper, blown against something and left there.
func _stray_scrap(into: Node3D, at: Vector3) -> void:
	var paper := surfaces.painted(Color(0.78, 0.76, 0.7))
	var scrap := _box(into, Vector3(0.4, 0.03, 0.3), paper, at + Vector3(0.0, 0.015, 0.0))
	scrap.rotation.y = _rng.randf_range(0.0, TAU)


func _stray_washer(into: Node3D, at: Vector3) -> void:
	var steel := surfaces.metal(Color(0.66, 0.68, 0.72))
	if _rng.randf() < 0.5:
		_cylinder(into, 0.13, 0.04, steel, at + Vector3(0.0, 0.02, 0.0))
		return
	var screw := _cylinder(into, 0.05, 0.42, steel, at + Vector3(0.0, 0.05, 0.0))
	screw.rotation = Vector3(PI * 0.5, _rng.randf_range(0.0, TAU), 0.0)


# --- the boxes ---------------------------------------------------------------


## A card room's cover: sealed packs of cards out of the store cupboard, stacked two by two and
## three high, with the house's band round each one.
func _deck_packs(into: Node3D, size: Vector3) -> void:
	var pack := Vector3(size.x * 0.46, size.y * 0.3, size.z * 0.46)
	var band := Vector3(pack.x * 1.02, pack.y * 0.22, pack.z * 1.02)
	var gold := surfaces.painted(room.trim)
	var wrap := surfaces.printed(Surfaces.card_back())
	for tier: int in 3:
		for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			var at := Vector3(
				corner.x * pack.x * 0.52,
				-size.y * 0.5 + pack.y * (float(tier) + 0.5),
				corner.y * pack.z * 0.52
			)
			_box(into, pack, wrap, at)
			_box(into, band, gold, at)


## A workshop's cover: offcuts of the same board the table is made of, stacked and squared off.
## Boxes of parts, taped shut and stacked the way a delivery is left against a wall: what the
## garage takes cover behind is whatever came in last week and has not been put away.
func _part_boxes(into: Node3D, size: Vector3) -> void:
	var card := surfaces.painted(Color(0.62, 0.48, 0.34))
	var tape := surfaces.painted(Color(0.84, 0.78, 0.62))
	var rows := 3
	for i: int in rows:
		var deep := size.z * (0.94 - float(i) * 0.12)
		var wide := size.x * (0.94 - float(i) * 0.12)
		var lift := -size.y * 0.5 + size.y * (float(i) + 0.5) / float(rows)
		var box := Vector3(wide, size.y / float(rows) * 0.9, deep)
		_box(into, box, card, Vector3(0.0, lift, 0.0))
		# The tape stands a whisker proud of the carton on every face it crosses. Flush with the
		# sides it shared a plane with them, and two faces in one plane fight over the same
		# pixels: a pale line down the side of every box, flickering as the camera moved.
		var strip := Vector3(wide * 0.16, box.y * 1.04, deep * 1.04)
		_box(into, strip, tape, Vector3(0.0, lift, 0.0))


func _offcuts(into: Node3D, size: Vector3) -> void:
	var count := 4
	var thick := size.y / float(count)
	for i: int in count:
		var ink := room.wall_edge.lightened(0.12) if i % 2 == 0 else room.wall_edge.darkened(0.2)
		# Every other board is laid the other way about, which is how a pile of offcuts ends up.
		var across := i % 2 == 0
		# Short of the cube on every side: a board is turned a little as it goes down, and one the
		# full width of the box would have its corners outside the cover it is.
		var plank := (
			Vector3(size.x * 0.94, thick, size.z * 0.8)
			if across
			else Vector3(size.x * 0.8, thick, size.z * 0.94)
		)
		var at := Vector3(0.0, -size.y * 0.5 + thick * (float(i) + 0.5), 0.0)
		var board := _box(into, plank, surfaces.painted(ink), at)
		board.rotation.y = _rng.randf_range(-0.05, 0.05)


## A sealed tin of the House's cards, GAME.md 8.1b: a printed tin box in the room's band color
## with a cream band round it, and a lid pressed over it a hair wider, its brass rim rolled.
func _card_tin(into: Node3D, size: Vector3) -> void:
	var body := Vector3(size.x * 0.88, size.y * 0.78, size.z * 0.88)
	var printed := surfaces.tin(room.wall_print, room.wall)
	_box(into, body, printed, Vector3(0.0, -size.y * 0.5 + body.y * 0.5, 0.0))
	var lid := Vector3(size.x * 0.92, size.y * 0.2, size.z * 0.92)
	var top := size.y * 0.5 - lid.y * 0.5
	_box(into, lid, surfaces.sheet(room.wall_print.darkened(0.15)), Vector3(0.0, top, 0.0))
	var seal := CylinderMesh.new()
	seal.top_radius = minf(size.x, size.z) * 0.22
	seal.bottom_radius = seal.top_radius
	seal.height = 0.02
	seal.radial_segments = 16
	seal.rings = 1
	_put(into, seal, surfaces.brass(room.trim), Vector3(0.0, size.y * 0.5 - 0.012, 0.0))
	into.rotation.y = _rng.randf_range(-0.04, 0.04)


## A yard's cover: sacks on a pallet, the top one landed crooked.
func _sacks(into: Node3D, size: Vector3) -> void:
	var base := Vector3(size.x, size.y * 0.12, size.z)
	var timber := surfaces.painted(room.table.lightened(0.24))
	_box(into, base, timber, Vector3(0.0, -size.y * 0.5 + base.y * 0.5, 0.0))
	var sack := Vector3(size.x * 0.82, size.y * 0.28, size.z * 0.74)
	var paper := surfaces.painted(room.wall_edge.lightened(0.05))
	for i: int in 3:
		var at := Vector3(0.0, -size.y * 0.5 + base.y + sack.y * (float(i) + 0.5), 0.0)
		var bag := _box(into, sack, paper, at)
		bag.rotation.y = _rng.randf_range(-0.22, 0.22)


# --- what stands on top of a wall --------------------------------------------


## A short stack of chips, left on the rail by somebody watching.
func _chips(into: Node3D, at: Vector3) -> void:
	var colors: Array[Color] = [Palette.CHIP_RED, Palette.CHIP_WHITE, room.trim]
	for i: int in _rng.randi_range(3, 6):
		var ink: Color = colors[_rng.randi_range(0, colors.size() - 1)]
		var chip := _cylinder(into, 0.16, 0.05, surfaces.painted(ink), at)
		chip.position += Vector3(0.0, 0.025 + float(i) * 0.05, 0.0)


## A cone, stood on the barrier where it will not be driven into.
func _cone(into: Node3D, at: Vector3) -> void:
	var orange := surfaces.painted(Color(0.94, 0.42, 0.1))
	_box(into, Vector3(0.28, 0.04, 0.28), surfaces.painted(Color(0.2, 0.2, 0.22)), at)
	var body := CylinderMesh.new()
	body.top_radius = 0.02
	body.bottom_radius = 0.11
	body.height = 0.34
	body.radial_segments = 8
	body.rings = 1
	_put(into, body, orange, at + Vector3(0.0, 0.19, 0.0))


## A handful of bolts, put down on the block and never picked up again.
func _bolts(into: Node3D, at: Vector3) -> void:
	var steel := surfaces.metal(Color(0.64, 0.66, 0.7))
	for i: int in _rng.randi_range(3, 5):
		var spot := at + Vector3(_rng.randf_range(-0.3, 0.3), 0.03, _rng.randf_range(-0.2, 0.2))
		var bolt := _cylinder(into, 0.035, 0.22, steel, spot)
		bolt.rotation = Vector3(PI * 0.5, _rng.randf_range(0.0, TAU), 0.0)


## The face of the cash-out pad of 3.4, painted on [param into] out to [param radius]: a roulette
## wheel let into the baize After Hours, a hazard border in the Yard, a machined plate on the
## bench. Nothing here is in the way of anything; the pad is the arena's and is untouched.
##
## Returns the material of the rim that blinks. The hint of 3.4 is the one part of the pad that
## moves and it says the same thing in every room, so every room hands back the same rim and the
## pad drives it without knowing which room it is standing in.
func junction(into: Node3D, radius: float) -> StandardMaterial3D:
	match room.id:
		&"after_hours":
			_wheel(into, radius)
		&"workbench":
			# The House's tin roulette spinner, GAME.md 8.1b: the wheel, with a pointer on its
			# spindle the way a tin toy's spinner has one.
			_wheel(into, radius)
			_pointer(into, radius)
		&"the_yard":
			_hazard_pad(into, radius)
		&"count_room":
			CountKit.processor(into, radius, surfaces)
		_:
			_plate(into, radius)
	return _blinking_rim(into, radius)


## Whatever the room builds on a Jackpot's tile of [param size]: in the Count Room a bank of
## memory, STORY.md 3.9; elsewhere nothing past the tile and its trim.
func jackpot(into: Node3D, size: Vector2) -> void:
	if room.id == &"count_room":
		CountKit.memory(into, size, surfaces, room)


## Whatever the room builds over a turbo pad's cell at [param at]: in the Count Room a cooling
## vent's slats, STORY.md 3.9; elsewhere nothing past the plate and its arrow.
func turbo(into: Node3D, at: Vector3, cell: float) -> void:
	if room.id == &"count_room":
		CountKit.vent(into, at, cell, surfaces)


## A roulette wheel let into the baize: a ring of red and black pockets round a brass turret,
## with the green zero among them and the cross of the spindle over the middle.
func _wheel(into: Node3D, radius: float) -> void:
	var timber := surfaces.marking(Color(0.23, 0.12, 0.09))
	var red := surfaces.marking(Palette.CHIP_RED)
	var black := surfaces.marking(Color(0.08, 0.08, 0.1))
	var green := surfaces.marking(Color(0.1, 0.44, 0.26))
	var brass := surfaces.metal(room.trim)
	_disc(into, radius, timber, PAD * 0.5, PAD)
	var deep := radius * 0.44
	var out := radius - RIM - deep * 0.5
	for i: int in POCKETS:
		var turn := TAU * float(i) / float(POCKETS)
		var ink := green if i == 0 else (red if i % 2 == 1 else black)
		# One pocket a hair over the next, so that where two of them meet on the circle there is
		# a lip rather than two flat faces in one plane fighting over the same pixels.
		var lift := PAD + LAYER + (LAYER * 0.25 if i % 2 == 1 else 0.0)
		var at := Vector3(sin(turn), 0.0, cos(turn)) * out
		# Cut from the arc it sits on rather than from the radius, so the ring stays closed
		# whatever it is divided into.
		var wide := TAU * out / float(POCKETS) * 1.12
		var pocket := _box(into, Vector3(wide, 0.01, deep), ink, at + _up(lift))
		pocket.rotation.y = turn
	_disc(into, radius * 0.48, surfaces.marking(room.trim.darkened(0.55)), PAD + LAYER * 2.0)
	# The spindle: a cross of brass over the middle, which is the shape that says wheel.
	for i: int in 2:
		var bar := _box(
			into, Vector3(radius * 0.07, 0.01, radius * 0.9), brass, _up(PAD + LAYER * 3.0)
		)
		bar.rotation.y = PI * 0.25 + PI * 0.5 * float(i)
	_disc(into, radius * 0.14, brass, PAD + LAYER * 4.0)


## A tin spinner's pointer over the wheel's spindle: a red arrow pressed from sheet, its tail at
## the middle and its head out over the pockets.
func _pointer(into: Node3D, radius: float) -> void:
	var tin := surfaces.sheet(Palette.CHIP_RED)
	var lift := _up(PAD + LAYER * 5.0)
	var turn := -PI * 0.7
	var along := Vector3(sin(turn), 0.0, cos(turn))
	var shaft := _box(
		into, Vector3(radius * 0.08, 0.02, radius * 0.6), tin, lift + along * radius * 0.28
	)
	shaft.rotation.y = turn
	for side: float in [-1.0, 1.0]:
		var barb := _box(
			into, Vector3(radius * 0.07, 0.02, radius * 0.24), tin, lift + along * radius * 0.6
		)
		barb.rotation.y = turn + side * 0.55
		barb.position += Vector3(cos(turn), 0.0, -sin(turn)) * side * radius * 0.05
	_cylinder(into, radius * 0.07, 0.04, surfaces.brass(room.trim), lift)


## Concrete with a hazard border round it, the way a yard marks the one square of floor everybody
## is meant to drive into, and the bay lines of a loading bay inside that.
func _hazard_pad(into: Node3D, radius: float) -> void:
	var concrete := surfaces.marking(Color(0.44, 0.43, 0.4))
	var black := surfaces.marking(Color(0.11, 0.11, 0.12))
	var yellow := surfaces.marking(Color(0.93, 0.76, 0.12))
	_disc(into, radius, concrete, PAD * 0.5, PAD)
	var band := radius * 0.24
	var out := radius - RIM - band * 0.5
	for i: int in STRIPES:
		var turn := TAU * float(i) / float(STRIPES)
		var lift := PAD + LAYER + (LAYER * 0.25 if i % 2 == 1 else 0.0)
		var at := Vector3(sin(turn), 0.0, cos(turn)) * out
		# A shade wider than the arc it sits on, so the border is a border rather than a dashed
		# line: where two stripes overlap the lip above decides it and neither flickers.
		var wide := TAU * out / float(STRIPES) * 1.12
		var stripe := _box(
			into, Vector3(wide, 0.01, band), black if i % 2 == 0 else yellow, at + _up(lift)
		)
		stripe.rotation.y = turn
	# Bare concrete inside the border. Two painted bay lines were tried across it and read as a
	# parking space rather than as the one square of floor everybody is driving at: the border is
	# what says that, and the lines argued with it.
	_disc(into, out - band * 0.5, surfaces.marking(Color(0.36, 0.35, 0.33)), PAD + LAYER * 2.0)


## A steel inspection plate let into the bench: a machined face, a ring of bolt heads round it and
## a turned center, which is what a workshop puts on the floor where something is meant to stand.
func _plate(into: Node3D, radius: float) -> void:
	var steel := surfaces.metal(Color(0.3, 0.31, 0.34))
	var bright := surfaces.metal(Color(0.78, 0.8, 0.84))
	var shadowed := surfaces.marking(Color(0.11, 0.11, 0.13))
	_disc(into, radius, steel, PAD * 0.5, PAD)
	var bolt := radius * 0.1
	for i: int in 12:
		var turn := TAU * float(i) / 12.0
		var at := Vector3(sin(turn), 0.0, cos(turn)) * (radius - RIM - bolt)
		_cylinder(into, bolt, 0.012, bright, at + _up(PAD + LAYER))
		_cylinder(into, bolt * 0.42, 0.014, shadowed, at + _up(PAD + LAYER * 1.6))
	_disc(into, radius * 0.62, surfaces.metal(room.trim), PAD + LAYER)
	_disc(into, radius * 0.5, steel, PAD + LAYER * 2.0)
	_disc(into, radius * 0.16, bright, PAD + LAYER * 3.0)


## The rim that blinks, and the material that drives it. Built here rather than asked of the room,
## whose neon is cached and shared by color: this one changes color and brightness every frame,
## and anything else wearing the same neon would blink along with it.
func _blinking_rim(into: Node3D, radius: float) -> StandardMaterial3D:
	var lit := StandardMaterial3D.new()
	lit.albedo_color = Palette.NEON_MAGENTA
	lit.emission_enabled = true
	lit.emission = Palette.NEON_MAGENTA
	lit.emission_energy_multiplier = 0.0
	lit.roughness = 0.4
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.25
	torus.outer_radius = radius
	# A flat band on the plate: eight sides round its tube, GAME.md 10.7.
	torus.rings = 48
	torus.ring_segments = 8
	var rim := _put(into, torus, lit, _up(PAD + 0.02))
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return lit


## Straight up by [param lift], which is the only direction anything on the pad is ever offset in.
func _up(lift: float) -> Vector3:
	return Vector3(0.0, lift, 0.0)


## A flat disc of paint [param radius] across, standing [param lift] over the floor.
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


# --- the parts ---------------------------------------------------------------


## What the step on top of a wall is made of: the wall's own edge color, except in the card
## room, where the rail round a table is brass.
##
## It is never the color of the floor, whatever the room is. A wall is cover and the floor is
## not, and the first thing a player reads at speed is which is which.
## The rolled brass beads along a tin wall's cap, GAME.md 8.1b, one down each long edge of it.
func _beads(holder: Node3D, top: Vector3, sits: float) -> void:
	var along_x := top.x >= top.z
	var length := maxf(top.x, top.z)
	var across := minf(top.x, top.z) * 0.5
	var rolled := surfaces.brass(_step_ink())
	for side: float in [-1.0, 1.0]:
		var mesh := CylinderMesh.new()
		mesh.top_radius = BEAD
		mesh.bottom_radius = BEAD
		mesh.height = length
		mesh.radial_segments = 6
		mesh.rings = 1
		var at := Vector3(0.0, sits + top.y * 0.5, 0.0)
		if along_x:
			at.z = side * across
		else:
			at.x = side * across
		var bead := _put(holder, mesh, rolled, at)
		bead.rotation = Vector3(0.0, 0.0, PI * 0.5) if along_x else Vector3(PI * 0.5, 0.0, 0.0)


func _step_ink() -> Color:
	if room.id == &"after_hours":
		return room.trim.darkened(0.3)
	return room.trim.darkened(0.2)


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
