class_name RoomKit
extends RefCounted
## What the things inside the arena are made of, GAME.md 8.1: the walls the karts drive between
## and the boxes they shoot. The shapes are the room's to decide, the way the colours are.
##
## The rule is that the play is untouched. A wall is the same block it always was and a box is
## the same cube: what a room adds is the top of the wall, which nothing drives through, and the
## way the box is put together, which is the same cube seen closer. A card room stacks its boxes
## out of deck packs, a workshop out of offcuts, a yard out of cement sacks; every wall gets a
## capping strip so that it reads as a block rather than as a slab, and some of them carry
## something small, up where it is out of the way.

## The step on top of a wall: how much of the wall's height it takes and how far in from the side
## it stands. It is a shape rather than a line -- a block with a smaller block on it, the way a
## toy brick is moulded -- because a strip laid into the top face of a wall shares a plane with
## the side of it and the two flicker against each other from every angle.
const STEP := 0.26
const STEP_INSET := 0.09
## How far the step sinks into the block under it, so that no two faces of the pair ever lie in
## the same plane.
const STEP_BITE := 0.02
## How often a wall carries something on top of it, and how long a wall has to be to qualify.
const DRESSED_WALLS := 3
const LONG_ENOUGH := 2.0
## How high something dropped on the floor of the arena may stand. Below this it is litter: a card
## face down on the baize, a washer on the bench, a scrap of paper in the yard. Nothing this low
## is in anybody's way, and a floor with nothing at all on it reads as a floor rather than as a
## place somebody has been.
const LITTER := 0.12

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
		_:
			_offcuts(holder, size)
	return holder


## A wall, as it is seen: the block itself, the step on top of it and, on some of them, whatever
## the room leaves up there. The collider is the arena's and is the full box, so what a kart
## drives into is the shape it was before any of this.
func wall(size: Vector3, index: int) -> Node3D:
	var holder := Node3D.new()
	holder.name = "Wall"
	var step := size.y * STEP
	var block := Vector3(size.x, size.y - step, size.z)
	_box(holder, block, surfaces.painted(room.wall), Vector3(0.0, -step * 0.5, 0.0))
	var inset := minf(STEP_INSET, minf(size.x, size.z) * 0.2)
	var top := Vector3(size.x - inset * 2.0, step + STEP_BITE, size.z - inset * 2.0)
	var sits := (size.y - step - STEP_BITE) * 0.5 + STEP_BITE * 0.5
	_box(holder, top, surfaces.painted(_step_ink()), Vector3(0.0, sits, 0.0))
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


## What a room's spikes are made of: rusted rebar in the yard, bright nails on the bench, and
## whatever the dark under a card table is made of in the card room.
func _spike_ink() -> Material:
	match room.id:
		&"after_hours":
			return surfaces.painted(Color(0.16, 0.12, 0.13))
		&"the_yard":
			return surfaces.painted(Color(0.46, 0.26, 0.16))
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
		var span := (size.x if along else size.y) + band * 2.0
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


## A few small things dropped on the floor the karts drive on, GAME.md 8.1. Flat enough to be
## driven over without noticing and small enough to be missed at a glance, which is the point.
## Only empty floor takes any: nothing lands on a pad, in a pit or under a wall.
func litter(into: Node3D, grid: ArenaGrid, count: int) -> void:
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
		picture = Surfaces.CARD_BACK
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
	var wrap := surfaces.printed(Surfaces.CARD_BACK)
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


# --- the parts ---------------------------------------------------------------


## What the step on top of a wall is made of: the wall's own edge colour, except in the card
## room, where the rail round a table is brass.
##
## It is never the colour of the floor, whatever the room is. A wall is cover and the floor is
## not, and the first thing a player reads at speed is which is which.
func _step_ink() -> Color:
	if room.id == &"after_hours":
		return room.trim.darkened(0.42)
	return room.wall_edge.darkened(0.16)


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
