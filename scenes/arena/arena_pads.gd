class_name ArenaPads
extends RefCounted
## The House's pieces on an arena's floor, GAME.md 8.1c: the coin pads, the item pads, the turbo
## plates and the Jackpots' tiles, put down where the map's grid says and the same in every room,
## each with whatever the room's kit adds over it. Built for [Arena] as the room goes up, one kind
## at a time, and baked into as few meshes as they will go, GAME.md 10.7.
##
## The pads are inked in the floor's own color a shade or two off it, see [Inlay], and told apart
## by their shapes and how light they are rather than by colors of their own: gold coin pads,
## magenta item pads and cyan turbo plates were the brightest things on the table and the nearest
## to the players' gold, pink and cyan, which are what the table is for, GAME.md 8.1a. What lies
## on a pad, the chip, the die or the item box, is what is bright.

## How high the inlays lie over the floor: a hair, paint rather than a thing standing on it.
const LIFT := 0.012
## A coin pad is a chip let into the floor: its face, its rim and the notches round the rim, out
## to these radii, each a shade lighter than the floor by these shares.
const CHIP := 0.5
const CHIP_FACE := 0.38
const CHIP_NOTCHES := 8
const FACE_SHADE := 0.05
const RIM_SHADE := 0.16
const NOTCH_SHADE := 0.3
## An item pad is a ticket let into the floor, as the House's tickets are, GAME.md 8.1a: this far
## across from its middle to its corners, bitten in at them by this much, its edge this wide, and
## its face and its edge each a shade lighter than the floor.
const TICKET := 0.6
const TICKET_NOTCH := 0.16
const TICKET_EDGE := 0.07
const TICKET_SHADE := 0.06
const EDGE_SHADE := 0.2
## A turbo pad is a dark plate let into the floor with a pale arrow on each cell of it: the plate
## in this far from the section's edge and a shade darker than the floor, and the arrows the floor
## this far toward the room's marking ink, the one pad whose mark has to say which way it goes.
const PLATE_IN := 0.08
const PLATE_SHADE := -0.3
const ARROW_INK := 0.5
## A spawn point is a ring on the floor, out to these radii, a shade lighter than it.
const SEAT := 0.5
const SEAT_IN := 0.42
const SEAT_SHADE := 0.12


## The coin pads of 3.2, onto [param arena]'s floor and into its [member Arena.coin_pads].
static func coin_pads(arena: Arena) -> void:
	var pads := Node3D.new()
	pads.name = "CoinPads"
	arena.add_child(pads)
	var surfaces := arena.surfaces
	for i: int in arena.grid.coin_pads.size():
		var pad := CoinPad.new()
		pad.name = "CoinPad%d" % i
		pad.position = arena.grid.cell_center(arena.grid.coin_pads[i])
		var chip := Inlay.new(LIFT)
		chip.disc(Vector2.ZERO, CHIP_FACE, surfaces.ground(FACE_SHADE))
		chip.ring(
			Vector2.ZERO,
			CHIP_FACE,
			CHIP,
			surfaces.ground(RIM_SHADE),
			CHIP_NOTCHES,
			surfaces.ground(NOTCH_SHADE)
		)
		pad.add_child(chip.node(surfaces.inlaid()))
		pads.add_child(pad)
		arena.coin_pads.append(pad)
	if arena.bake_scenery:
		Bake.merge(pads)


## The item pads of 7.1, onto [param arena]'s floor and into its [member Arena.power_pads].
static func power_pads(arena: Arena) -> void:
	var pads := Node3D.new()
	pads.name = "PowerPads"
	arena.add_child(pads)
	var surfaces := arena.surfaces
	for i: int in arena.grid.power_pads.size():
		var pad := PowerUpPad.new()
		pad.name = "PowerUpPad%d" % i
		pad.position = arena.grid.cell_center(arena.grid.power_pads[i])
		var corner := Vector2.ONE * TICKET
		var ticket := Inlay.new(LIFT)
		var inside := Inlay.ticket(corner, TICKET_NOTCH, TICKET_EDGE)
		ticket.band(Inlay.ticket(corner, TICKET_NOTCH), inside, surfaces.ground(EDGE_SHADE))
		ticket.fill(inside, surfaces.ground(TICKET_SHADE))
		pad.add_child(ticket.node(surfaces.inlaid()))
		pads.add_child(pad)
		arena.power_pads.append(pad)
	if arena.bake_scenery:
		Bake.merge(pads)


## The turbo pads, onto [param arena]'s floor and into its [member Arena.turbo_pads]. A section
## of pads side by side is one pad, so the line between two of them launches as surely as the
## middle of either, see [TurboPad]; it is one plate with an arrow on each of its cells.
static func turbo_pads(arena: Arena) -> void:
	var grid := arena.grid
	var pads := Node3D.new()
	pads.name = "TurboPads"
	arena.add_child(pads)
	var sections := grid.turbo_sections()
	for i: int in sections.size():
		var section := sections[i]
		var pad := TurboPad.new()
		pad.name = "TurboPad%d" % i
		pad.direction = grid.turbo_direction(section.position)
		pad.half_extents = grid.rect_size(section) * 0.5
		pad.position = grid.rect_center(section)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		var extent := grid.rect_size(section)
		box.size = Vector3(extent.x, 1.0, extent.y)
		shape.shape = box
		shape.position = Vector3(0.0, 0.5, 0.0)
		pad.add_child(shape)
		_turbo_plate(arena, pad, section)
		pads.add_child(pad)
		arena.turbo_pads.append(pad)
	if arena.bake_scenery:
		Bake.merge(pads)


## The plate of [param pad], over its cells of [param section]: a plate let into the felt, darker
## than it, and an arrow on each cell the way it launches, paler than it, GAME.md 8.1c.
static func _turbo_plate(arena: Arena, pad: TurboPad, section: Rect2i) -> void:
	var grid := arena.grid
	var surfaces := arena.surfaces
	var plate := Inlay.new(LIFT)
	var extent := grid.rect_size(section)
	plate.rect(Rect2(-extent * 0.5, extent).grow(-PLATE_IN), surfaces.ground(PLATE_SHADE))
	# The arrows a hair over the plate they lie on, rather than in its plane fighting it.
	var arrows := Inlay.new(LIFT * 1.5)
	var way := Vector2(pad.direction.x, pad.direction.z)
	for y: int in range(section.position.y, section.end.y):
		for x: int in range(section.position.x, section.end.x):
			var at := grid.cell_center(Vector2i(x, y)) - pad.position
			var middle := Vector2(at.x, at.z)
			arrows.arrow(
				middle,
				way,
				grid.cell_size * 0.56,
				grid.cell_size * 0.5,
				arena.room.felt.lerp(arena.room.marking, ARROW_INK)
			)
			arena.kit.turbo(pad, at, grid.cell_size)
	pad.add_child(plate.node(surfaces.inlaid()))
	pad.add_child(arrows.node(surfaces.inlaid()))


## The Jackpots of 3.5, onto [param arena]'s floor and into its [member Arena.jackpot_zones]:
## each a tile with whatever its room builds over it.
static func jackpots(arena: Arena) -> void:
	var grid := arena.grid
	var zones := Node3D.new()
	zones.name = "JackpotZones"
	arena.add_child(zones)
	for i: int in grid.jackpots.size():
		var rect := grid.jackpots[i]
		var size2 := grid.rect_size(rect)
		var position := grid.rect_center(rect)
		arena.jackpot_positions.append(position)
		var zone := JackpotZone.new()
		zone.name = "JackpotZone%d" % i
		zone.index = i
		zone.size = size2
		zone.position = position
		var tile := box(arena, Vector3(size2.x, Arena.PAD_HEIGHT, size2.y), arena.room.lane)
		tile.position = Vector3(0.0, Arena.PAD_HEIGHT * 0.5, 0.0)
		tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		zone.add_child(tile)
		var trim := box(
			arena, Vector3(size2.x * 0.8, Arena.PAD_HEIGHT, size2.y * 0.8), arena.room.trim
		)
		trim.position = Vector3(0.0, Arena.PAD_HEIGHT * 1.1, 0.0)
		trim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		zone.add_child(trim)
		arena.kit.jackpot(zone, size2)
		zones.add_child(zone)
		arena.jackpot_zones.append(zone)
	# The tiles and their trims across every zone; a zone's own pole, bulbs and counter each
	# wear a material of their own and stay where they are.
	if arena.bake_scenery:
		Bake.merge(zones)


## A block of [param color] paint [param size] across, centered on its middle.
static func box(arena: Arena, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = arena.surfaces.painted(color)
	return instance


## A spawn point's mark at [param at] under [param into]: a ring let into the floor, a shade
## lighter than it, so a seat is found without being the brightest thing on the table.
static func seat(arena: Arena, into: Node3D) -> void:
	var ring := Inlay.new(LIFT)
	ring.ring(Vector2.ZERO, SEAT_IN, SEAT, arena.surfaces.ground(SEAT_SHADE))
	into.add_child(ring.node(arena.surfaces.inlaid()))
