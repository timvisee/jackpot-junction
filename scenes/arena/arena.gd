class_name Arena
extends Node3D
## Builds the arena from an [ArenaLayout]: table, floor, walls, pads, zones and spawn points.
## Everything is a gray box for now; the art pass replaces meshes and materials, not structure.

## A crate broke; [param by_slot] gets the credit, -1 for nobody.
signal crate_broken(by_slot: int)
## A shooting target went down; the slot that shot it collects [param coins].
signal target_struck(by_slot: int, coins: int)

const FLOOR_THICKNESS := 0.2
const TABLE_OVERHANG := 38.0
## How far out past the far wall a hoarding stands, GAME.md 8.1, and how far along that edge
## from the middle: out by the corners, where the booth in the middle and the tanks beside it
## are not, and on the edge the camera has behind the table rather than out at the sides, which
## is off the screen.
const BILLBOARD_STANDOFF := 3.6
## How many small things are left lying on the floor of the arena itself, GAME.md 8.1.
const LITTER_COUNT := 12
## Tiles a side the floor and the table top are cut into on a phone's renderer, GAME.md 10.7:
## three, since a disco head's cone reaches across most of the table, so a finer cut spares few
## pixels a light and costs a draw call a tile.
const SLAB_TILES := 3
const BILLBOARD_ALONG := 0.85
const PAD_HEIGHT := 0.05
const PIT_COLOR := Color("#0B0B0E")
## How deep the pit shafts go below the floor, and the width of the dark rim around them.
const PIT_DEPTH := 1.1
const PIT_RIM := 0.09
const PIT_WALL_TOP := Color(0.13, 0.17, 0.14)
const PIT_RIM_COLOR := Color(0.1, 0.12, 0.11)

@export var layout: ArenaLayout

var grid: ArenaGrid
## The room this map is played in, GAME.md 8.1: what it is lit by and what it is made of. Read
## by the lighting, the crowd and every surface here.
var room: RoomLook
## What the room is made of: the materials every mesh here is built from.
var surfaces: Surfaces
## What the walls and the boxes inside the arena are made of, GAME.md 8.1.
var kit: RoomKit
## Whether the scenery is merged into as few meshes as it will go once it is built, GAME.md 8.1.
## Off in the tests that look at what a room is made of: after a bake there is nothing left to
## look at but the result.
var bake_scenery := true
## Whether this room builds itself the moment it enters the tree. A loader that means to put a
## progress bar up runs [method build_steps] itself instead, GAME.md 8.6.
var deferred_build := false
## Whether this is the story's Final Hand, STORY.md 8, which dresses the room the House's way.
var final_hand := Story.final_hand_on
var spawn_points: Array[Vector3] = []
var turbo_pads: Array[TurboPad] = []
var pits: Array[Pit] = []
var crates: Array[Crate] = []
var coin_pads: Array[CoinPad] = []
var power_pads: Array[PowerUpPad] = []
var flush_pads: Array[FlushPad] = []
var targets: Array[Target] = []
var joker_pads: Array[JokerPad] = []
var portals: Array[Portal] = []
## The pieces of wall that open and shut, GAME.md 9.4a, which the room running the map works.
var gates: Array[Gate] = []
## The cash-out pads, GAME.md 3.4: one on most maps, and one a room on the tutorial's, 9.4a.
var junctions: Array[JunctionPad] = []
## The first of them, or null, for whatever asks for the one.
var junction: JunctionPad:
	get:
		return junctions[0] if not junctions.is_empty() else null
## The moving-head lights over the table, driven by the match's excitement meter.
var disco: DiscoLights
## The people watching, GAME.md 8.1.
var crowd: Crowd
## The hoardings out past the far corners, GAME.md 8.1. A room that wants no dressing hides
## them, the same way it switches the crowd and the rig off.
var billboards: Node3D
var junction_position := Vector3.ZERO
var junction_radius := 2.5
var jackpot_zones: Array[JackpotZone] = []
var jackpot_positions: Array[Vector3] = []
var pickups: Node3D

## The scorch marks the walls are wearing, oldest first, GAME.md 8.3. Untyped, because a mark
## frees itself once it has faded and a typed array will not hand a freed instance back out.
var _marks: Array = []
var _rules: MatchRules
var _rng: RandomNumberGenerator


func _ready() -> void:
	Events.bullet_struck.connect(_on_bullet_struck)
	if layout != null and grid == null and not deferred_build:
		build()


func _exit_tree() -> void:
	if Events.bullet_struck.is_connected(_on_bullet_struck):
		Events.bullet_struck.disconnect(_on_bullet_struck)


## A bullet landed on a wall. The mark is drawn from the event rather than by the bullet itself
## so that it appears on every screen: a client's bullets are dead reckoned and never touch
## anything, GAME.md 10.3, so they have nothing to leave a mark from.
func _on_bullet_struck(at: Vector3, normal: Vector3, color: Color) -> void:
	var kept: Array = []
	for mark: Variant in _marks:
		if is_instance_valid(mark):
			kept.append(mark)
	kept.append(BulletMark.spawn(self, at, normal, color))
	while kept.size() > BulletMark.MAX_MARKS:
		var oldest: Variant = kept.pop_front()
		if is_instance_valid(oldest):
			(oldest as Node).queue_free()
	_marks = kept


## Rebuilds every child from the layout, all in one go.
func build() -> void:
	for step: Callable in build_steps():
		step.call()


## The phases a room is built in, in order. Run one to a frame and a loading screen can say how
## far along it is, GAME.md 8.6; run the lot and it is the build it has always been. A room takes
## about a sixth of a second to put up, most of it the crowd and the baking of 8.1, which is long
## enough to be a hitch if it happens while something is already on the screen.
func build_steps() -> Array[Callable]:
	return [
		_clear_the_room,
		_add_table,
		_add_floor,
		_add_walls,
		_add_gates,
		_add_spawns,
		_add_coin_pads,
		_add_power_pads,
		_add_flush_pads,
		_add_targets,
		_add_joker_pads,
		_add_portals,
		_add_turbo_pads,
		_add_crates,
		_add_litter,
		_add_pits,
		_add_junction,
		_add_jackpots,
		_add_disco,
		_add_crowd,
		_add_billboards,
		_add_props,
	]


## The first phase: what the room is made of, and nothing of the last one left in it.
func _clear_the_room() -> void:
	grid = layout.parse()
	room = layout.room if layout.room != null else RoomLook.fallback()
	surfaces = Surfaces.new(room)
	kit = RoomKit.new(room, surfaces)
	for child: Node in get_children():
		child.queue_free()
	_marks.clear()
	spawn_points.clear()
	turbo_pads.clear()
	pits.clear()
	crates.clear()
	coin_pads.clear()
	power_pads.clear()
	flush_pads.clear()
	targets.clear()
	joker_pads.clear()
	portals.clear()
	gates.clear()
	junctions.clear()
	jackpot_zones.clear()
	jackpot_positions.clear()
	pickups = Node3D.new()
	pickups.name = "Pickups"
	add_child(pickups)


func _add_crowd() -> void:
	crowd = Crowd.add_to(self, world_size(), room)


## And whatever else the room has in it, GAME.md 8.1: its shell and its clutter, what the story
## has put up in it, STORY.md 6, and its slot machines, on the floor and on the rail, 3.15.
func _add_props() -> void:
	RoomProps.add_to(self)
	StoryDressing.add_to(self)
	SlotPad.add_to(self)
	RailMachines.add_to(self)


## Brings the economy to life: coin pads start spawning, crates drop chips, the Junction and one
## Jackpot zone start working. Called by the match once it has rules and a seeded generator.
func start_economy(
	rules: MatchRules, rng: RandomNumberGenerator, items: PowerUpTable, jokers: JokerCatalog = null
) -> void:
	_rules = rules
	_rng = rng
	for target: Target in targets:
		target.coins = rules.target_coins
	for pad: JokerPad in joker_pads:
		pad.start(rules, rng, pickups, jokers)
	for pad: CoinPad in coin_pads:
		pad.start(rules, rng, pickups)
	for pad: PowerUpPad in power_pads:
		pad.start(rules, rng, pickups, items)
	for crate: Crate in crates:
		crate.respawn_delay = rules.crate_respawn
		if not crate.destroyed.is_connected(_on_crate_destroyed):
			crate.destroyed.connect(_on_crate_destroyed.bind(crate))
	for pad: JunctionPad in junctions:
		pad.rules = rules
	for zone: JackpotZone in jackpot_zones:
		zone.rules = rules
		if not zone.emptied.is_connected(_on_jackpot_emptied):
			zone.emptied.connect(_on_jackpot_emptied)
	if not jackpot_zones.is_empty():
		activate_jackpot(rng.randi_range(0, jackpot_zones.size() - 1))


func activate_jackpot(index: int) -> void:
	for zone: JackpotZone in jackpot_zones:
		if zone.index == index:
			zone.activate()
		else:
			zone.deactivate()


## Scatters chips around a point. Dropped chips vanish after [param lifetime] seconds; 0 keeps them.
## A kart's dropped ones say which team it was on, [param team], GAME.md 3.14.
func spawn_chips(
	origin: Vector3,
	count: int,
	lifetime: float,
	gold_chance: float = 0.0,
	dropped: bool = false,
	team: int = -1
) -> Array[Chip]:
	var result: Array[Chip] = []
	for i: int in count:
		var chip := Chip.new()
		chip.gold = _rng.randf() < gold_chance
		chip.value = _rules.gold_chip_value if chip.gold else _rules.chip_value
		chip.dropped = dropped
		chip.dropped_team = team
		chip.lifetime = lifetime
		var angle := _rng.randf_range(0.0, TAU)
		var distance := _rng.randf_range(0.8, 3.2)
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * distance
		place_drop(chip, clamp_to_floor(origin + offset), origin)
		result.append(chip)
	return result


## Drops a fixed power-up on the floor, for example from a dead kart.
func spawn_floor_item(origin: Vector3, item: PowerUp, lifetime: float) -> ItemBox:
	var box := ItemBox.new()
	box.fixed_item = item
	box.lifetime = lifetime
	var angle := _rng.randf_range(0.0, TAU)
	var distance := _rng.randf_range(1.6, 2.8)
	place_drop(
		box, clamp_to_floor(origin + Vector3(cos(angle), 0.0, sin(angle)) * distance), origin
	)
	return box


## Drops a joker on the floor, for example from a dead kart or the joker menu.
func spawn_floor_joker(origin: Vector3, joker: Joker, lifetime: float) -> FloorJoker:
	var card := FloorJoker.new()
	card.joker = joker
	card.lifetime = lifetime
	var angle := _rng.randf_range(0.0, TAU)
	var distance := _rng.randf_range(1.8, 3.0)
	place_drop(
		card, clamp_to_floor(origin + Vector3(cos(angle), 0.0, sin(angle)) * distance), origin
	)
	return card


## True when a point on the floor is over one of the holes, so anything dropped there falls in.
func is_over_pit(point: Vector3) -> bool:
	for rect: Rect2i in grid.pits:
		var center := grid.rect_center(rect)
		var half := grid.rect_size(rect) * 0.5
		if absf(point.x - center.x) <= half.x and absf(point.z - center.z) <= half.y:
			return true
	return false


## Puts a freshly dropped pickup down, sending it into the hole if that is where it landed.
## Puts a pickup on the floor. Given a [param thrown_from] it is thrown clear of that point
## rather than simply appearing there, GAME.md 8.3, which is what a kart bursting or a crate
## breaking looks like from outside.
func place_drop(pickup: Pickup, at: Vector3, thrown_from: Vector3 = Vector3.INF) -> void:
	pickup.position = at
	pickups.add_child(pickup)
	if is_over_pit(at):
		pickup.fall_into_pit()
	elif thrown_from != Vector3.INF:
		pickup.throw_from(thrown_from)


func clamp_to_floor(point: Vector3) -> Vector3:
	var half := world_size() * 0.5 - Vector2.ONE * (grid.cell_size + 0.5)
	return Vector3(clampf(point.x, -half.x, half.x), 0.0, clampf(point.z, -half.y, half.y))


func _on_crate_destroyed(by_slot: int, crate: Crate) -> void:
	crate_broken.emit(by_slot)
	var count := _rng.randi_range(_rules.crate_drop_min, _rules.crate_drop_max)
	spawn_chips(
		Vector3(crate.global_position.x, 0.0, crate.global_position.z),
		count,
		0.0,
		_rules.crate_gold_chance
	)


func _on_jackpot_emptied(zone: JackpotZone) -> void:
	Events.jackpot_emptied.emit(zone.index)
	if jackpot_zones.size() > 1:
		activate_jackpot((zone.index + 1) % jackpot_zones.size())
	else:
		zone.activate()


func world_size() -> Vector2:
	return grid.world_size()


## Bounding box of the playable area including the walls, for camera framing.
func bounds() -> AABB:
	var size := world_size()
	return AABB(
		Vector3(-size.x * 0.5, 0.0, -size.y * 0.5), Vector3(size.x, layout.wall_height, size.y)
	)


## Hoardings out past the far corners, GAME.md 8.1: the boards a hall like this one sells to
## whoever will pay for them. Two of the house's advertisements are drawn as the room goes up, so
## a run of matches is not the same two posters over and over, from a set that grows with the
## story, see [StoryBoards]. The crowd leaves each one a bay, since a board put up to be read with
## a band of people standing in front of it is a board nobody reads.
func _add_billboards() -> void:
	billboards = Node3D.new()
	billboards.name = "Billboards"
	add_child(billboards)
	var draw := RandomNumberGenerator.new()
	draw.randomize()
	var ads := StoryBoards.pick(Story.stage_here(), final_hand, draw)
	var profile := Game.settings.profile
	for i: int in 2:
		var ad: Array = ads[i % ads.size()]
		var at := _billboard_spot(i)
		var board := Billboard.add_to(billboards, at, Vector3.ZERO, room)
		board.panel(Vector2(0.0, -0.78), Vector2(Billboard.WIDTH - 1.0, 0.2), ad[2], true)
		board.words(StoryFill.fill(ad[0], profile), Vector2(0.0, 0.45), 0.92, ad[2])
		board.words(
			StoryFill.fill(ad[1], profile), Vector2(0.0, -0.3), 0.4, Color(0.86, 0.88, 0.94)
		)
		var bay := Rect2(at.x - Billboard.WIDTH * 0.5, at.z - 1.6, Billboard.WIDTH, 3.2)
		if crowd != null:
			crowd.keep_clear(bay)


## Where a room stands its hoardings, GAME.md 8.1. Every hall sells the same two boards and every
## hall hangs them somewhere else: the workshop puts one out on a flank, the card room keeps both
## in close over the far rail, and the yard sets them wide apart along the back. What none of them
## does is put one where the clock goes, which is the middle of the far edge.
func _billboard_spot(index: int) -> Vector3:
	var half := world_size() * 0.5
	var side := -1.0 if index == 0 else 1.0
	match room.id:
		&"after_hours":
			# Well out from the middle: the clock board of 8.3 hangs near the center of this edge,
			# and a hoarding a few meters off it stands in the shot behind it.
			var along := half.x * 0.82 * side
			return Vector3(along, 0.0, -(half.y + BILLBOARD_STANDOFF))
		&"the_yard":
			var wide := half.x * 0.98 * side
			return Vector3(wide, 0.0, -(half.y + BILLBOARD_STANDOFF + 1.4))
		_:
			# One on the far edge and one out on the left flank, turned to face the table.
			if index == 0:
				return Vector3(-half.x * 0.55, 0.0, -(half.y + BILLBOARD_STANDOFF))
			return Vector3(half.x + BILLBOARD_STANDOFF + 1.0, 0.0, -half.y * 0.35)


func _add_table() -> void:
	var half := (world_size() + Vector2.ONE * TABLE_OVERHANG) * 0.5
	var table := _slab_with_holes(half, -FLOOR_THICKNESS, 0.5, _pit_rects(), surfaces.surround())
	table.name = "Table"
	add_child(table)


## The felt, with the pits cut out so the shafts below show through as real holes. It lies on
## the table and has nothing under it to throw a shadow on, GAME.md 10.7; the table does.
func _add_floor() -> void:
	var floor_mesh := _slab_with_holes(
		world_size() * 0.5, 0.0, FLOOR_THICKNESS, _pit_rects(), surfaces.floor_top()
	)
	floor_mesh.name = "Floor"
	for part: MeshInstance3D in floor_mesh.get_children():
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(floor_mesh)


## World-space footprints of the pits on the XZ plane.
func _pit_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for rect: Rect2i in grid.pits:
		var center := grid.rect_center(rect)
		var size2 := grid.rect_size(rect)
		result.append(Rect2(Vector2(center.x, center.z) - size2 * 0.5, size2))
	return result


## A slab centered on the origin whose top face at [param top] has [param holes] cut out, with
## sides down to [param thickness] below and no bottom. The top is split along every hole edge
## into cells; cells inside a hole are left out.
##
## On a phone's renderer the top is also cut into [method _slab_tiles] a side, GAME.md 10.7: that
## renderer lights each mesh by every light whose reach touches it, so a pixel of a slab that is
## one mesh pays for every lamp and disco head in the room, and a pixel of a tile pays for the
## lights that reach the tile. The desktop's renderer sorts lights by screen tile itself and
## gains nothing from the cut, so it keeps the slab whole and its draw calls.
func _slab_with_holes(
	half: Vector2, top: float, thickness: float, holes: Array[Rect2], skin: StandardMaterial3D
) -> Node3D:
	var tiles := _slab_tiles()
	var xs: Array[float] = [-half.x, half.x]
	var zs: Array[float] = [-half.y, half.y]
	for hole: Rect2 in holes:
		xs.append_array([hole.position.x, hole.end.x])
		zs.append_array([hole.position.y, hole.end.y])
	for i: int in range(1, tiles):
		xs.append(lerpf(-half.x, half.x, float(i) / float(tiles)))
		zs.append(lerpf(-half.y, half.y, float(i) / float(tiles)))
	xs.sort()
	zs.sort()
	var tops: Dictionary[Vector2i, SurfaceTool] = {}
	for i: int in xs.size() - 1:
		for j: int in zs.size() - 1:
			var x0 := xs[i]
			var x1 := xs[i + 1]
			var z0 := zs[j]
			var z1 := zs[j + 1]
			if x1 - x0 < 0.001 or z1 - z0 < 0.001:
				continue
			var center := Vector2((x0 + x1) * 0.5, (z0 + z1) * 0.5)
			var inside := false
			for hole: Rect2 in holes:
				if hole.has_point(center):
					inside = true
					break
			if inside:
				continue
			var tile := Vector2i(
				clampi(int((center.x + half.x) / (half.x * 2.0) * tiles), 0, tiles - 1),
				clampi(int((center.y + half.y) / (half.y * 2.0) * tiles), 0, tiles - 1)
			)
			if not tops.has(tile):
				tops[tile] = SurfaceTool.new()
				tops[tile].begin(Mesh.PRIMITIVE_TRIANGLES)
			_quad(
				tops[tile],
				Vector3(x0, top, z0),
				Vector3(x1, top, z0),
				Vector3(x1, top, z1),
				Vector3(x0, top, z1),
				Vector3.UP
			)
	var skirt := SurfaceTool.new()
	skirt.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bottom := top - thickness
	var corners: Array[Vector3] = [
		Vector3(-half.x, top, -half.y),
		Vector3(half.x, top, -half.y),
		Vector3(half.x, top, half.y),
		Vector3(-half.x, top, half.y),
	]
	for i: int in 4:
		var a := corners[i]
		var b := corners[(i + 1) % 4]
		var outward := Vector3(a.z - b.z, 0.0, b.x - a.x).normalized()
		_quad(skirt, a, b, Vector3(b.x, bottom, b.z), Vector3(a.x, bottom, a.z), outward)
	skin.cull_mode = BaseMaterial3D.CULL_DISABLED
	var slab := Node3D.new()
	for tile: Vector2i in tops:
		var part := MeshInstance3D.new()
		part.name = "Tile%d_%d" % [tile.x, tile.y]
		part.mesh = tops[tile].commit()
		part.material_override = skin
		slab.add_child(part)
	var sides := MeshInstance3D.new()
	sides.name = "Skirt"
	sides.mesh = skirt.commit()
	sides.material_override = skin
	slab.add_child(sides)
	return slab


## How many tiles a side the top of a slab is cut into: one on the desktop's renderer, which
## gains nothing from the cut, and [constant SLAB_TILES] on a phone's, see [method
## _slab_with_holes].
static func _slab_tiles() -> int:
	return 1 if Settings.full_renderer() else SLAB_TILES


## Two triangles for the quad a, b, c, d with one normal; both faces render, so winding is free.
##
## Each corner carries a UV taken from where it is on the table, in meters, so the felt and the
## boards are mapped flat and in world scale without the three texture reads a triplanar costs,
## GAME.md 8.1. Everything here lies flat or stands on an edge, which is what makes that work.
func _quad(
	st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3
) -> void:
	st.set_normal(normal)
	for vertex: Vector3 in [a, b, c, a, c, d]:
		st.set_uv(_world_uv(vertex, normal))
		st.add_vertex(vertex)


## Where a point sits on its own surface, in meters: along the floor for anything flat, and along
## the edge for the sides of a slab.
static func _world_uv(vertex: Vector3, normal: Vector3) -> Vector2:
	if absf(normal.y) > 0.5:
		return Vector2(vertex.x, vertex.z)
	if absf(normal.x) > 0.5:
		return Vector2(vertex.z, vertex.y)
	return Vector2(vertex.x, vertex.y)


## Two triangles for a quad with a color per corner, for the shaded pit shafts.
func _colored_quad(
	st: SurfaceTool, corners: Array[Vector3], colors: Array[Color], normal: Vector3
) -> void:
	st.set_normal(normal)
	for index: int in [0, 1, 2, 0, 2, 3]:
		st.set_color(colors[index])
		st.add_vertex(corners[index])


func _add_walls() -> void:
	var walls := Node3D.new()
	walls.name = "Walls"
	add_child(walls)
	for i: int in grid.walls.size():
		var rect := grid.walls[i]
		var size2 := grid.rect_size(rect)
		var size := Vector3(size2.x, layout.wall_height, size2.y)
		var body := StaticBody3D.new()
		body.name = "Wall%d" % i
		body.collision_layer = Layers.WORLD
		body.collision_mask = 0
		body.position = grid.rect_center(rect) + Vector3(0.0, layout.wall_height * 0.5, 0.0)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		# The block, its step and whatever the room puts up there, GAME.md 8.1.
		body.add_child(kit.wall(size, i))
		walls.add_child(body)
	# Every wall in the room is the same handful of materials and none of them ever moves.
	if bake_scenery:
		Bake.merge(walls)


## A gate for every run of G cells, GAME.md 9.4a, see [ArenaGates].
func _add_gates() -> void:
	gates = ArenaGates.build(self)


## The gate standing on [param cell], or null.
func gate_at(cell: Vector2i) -> Gate:
	for gate: Gate in gates:
		if cell in gate.cells:
			return gate
	return null


## The spawn points a match of [param karts] karts uses, GAME.md 6.3: the corners while they hold
## everybody, and all of them past that.
func spawns_for(karts: int) -> Array[Vector3]:
	var corners := grid.corner_spawns
	return spawn_points if karts > corners or corners <= 0 else spawn_points.slice(0, corners)


## The spawn points, and their discs on the floor, see [SpawnPads].
func _add_spawns() -> void:
	SpawnPads.add_to(self)


func _add_coin_pads() -> void:
	var pads := Node3D.new()
	pads.name = "CoinPads"
	add_child(pads)
	for i: int in grid.coin_pads.size():
		var pad := CoinPad.new()
		pad.name = "CoinPad%d" % i
		pad.position = grid.cell_center(grid.coin_pads[i])
		var disc := _disc_mesh(0.45, room.trim)
		disc.position = Vector3(0.0, PAD_HEIGHT * 0.5, 0.0)
		pad.add_child(disc)
		pad.add_child(_pad_rim(0.5))
		pads.add_child(pad)
		coin_pads.append(pad)
	if bake_scenery:
		Bake.merge(pads)


func _add_power_pads() -> void:
	var pads := Node3D.new()
	pads.name = "PowerPads"
	add_child(pads)
	for i: int in grid.power_pads.size():
		var pad := PowerUpPad.new()
		pad.name = "PowerUpPad%d" % i
		pad.position = grid.cell_center(grid.power_pads[i])
		var disc := _disc_mesh(0.6, Palette.NEON_MAGENTA)
		disc.position = Vector3(0.0, PAD_HEIGHT * 0.5, 0.0)
		disc.material_override = surfaces.neon(Palette.NEON_MAGENTA, 0.35)
		pad.add_child(disc)
		pad.add_child(_pad_rim(0.66, 0.07))
		pads.add_child(pad)
		power_pads.append(pad)
	if bake_scenery:
		Bake.merge(pads)


func _add_targets() -> void:
	var holder := Node3D.new()
	holder.name = "Targets"
	add_child(holder)
	for i: int in grid.targets.size():
		var target := Target.new()
		target.name = "Target%d" % i
		target.position = grid.cell_center(grid.targets[i])
		target.struck.connect(_on_target_struck)
		holder.add_child(target)
		targets.append(target)


func _add_joker_pads() -> void:
	var holder := Node3D.new()
	holder.name = "JokerPads"
	add_child(holder)
	for i: int in grid.joker_pads.size():
		var pad := JokerPad.new()
		pad.name = "JokerPad%d" % i
		pad.position = grid.cell_center(grid.joker_pads[i])
		holder.add_child(pad)
		joker_pads.append(pad)


func _on_target_struck(target: Target, by_slot: int) -> void:
	target_struck.emit(by_slot, target.coins)


func _add_flush_pads() -> void:
	var pads := Node3D.new()
	pads.name = "FlushPads"
	add_child(pads)
	for i: int in grid.flush_pads.size():
		var pad := FlushPad.new()
		pad.name = "FlushPad%d" % i
		pad.index = i
		pad.size = grid.cell_size
		pad.group = grid.region_of(grid.flush_pads[i])
		pad.position = grid.cell_center(grid.flush_pads[i])
		pads.add_child(pad)
		flush_pads.append(pad)
	# A pad's four frame bars wear its one material, which is what it recolors, so they bake to
	# one mesh a pad and still take the color, GAME.md 10.7.
	if bake_scenery:
		Bake.merge(pads)


func _add_turbo_pads() -> void:
	var pads := Node3D.new()
	pads.name = "TurboPads"
	add_child(pads)
	# A section of pads side by side is one pad, so the line between two of them launches as
	# surely as the middle of either, see [TurboPad]; each cell of it still wears a plate.
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
		for y: int in range(section.position.y, section.end.y):
			for x: int in range(section.position.x, section.end.x):
				_add_turbo_plate(pad, grid.cell_center(Vector2i(x, y)) - pad.position)
		pads.add_child(pad)
		turbo_pads.append(pad)
	if bake_scenery:
		Bake.merge(pads)


## One cell of a turbo pad at [param at] on [param pad]: a dark plate set into the felt with a lit
## face on it, rather than a flat cyan square, since the frame is what makes it read as a fitting,
## GAME.md 8.1, and the arrow it launches along.
func _add_turbo_plate(pad: TurboPad, at: Vector3) -> void:
	var frame := _box_mesh(Vector3(grid.cell_size, PAD_HEIGHT, grid.cell_size), room.lane)
	frame.position = at + Vector3(0.0, PAD_HEIGHT * 0.5, 0.0)
	pad.add_child(frame)
	var plate := _box_mesh(
		Vector3(grid.cell_size * 0.82, PAD_HEIGHT, grid.cell_size * 0.82), Palette.NEON_CYAN
	)
	plate.material_override = surfaces.neon(Palette.NEON_CYAN, 0.4)
	plate.position = at + Vector3(0.0, PAD_HEIGHT * 0.9, 0.0)
	pad.add_child(plate)
	var arrow := _arrow_mesh(Palette.CHIP_WHITE)
	arrow.position = at + Vector3(0.0, PAD_HEIGHT + 0.03, 0.0)
	# Fittings set into the felt throw no shadow anybody sees, GAME.md 10.7.
	frame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arrow.look_at_from_position(arrow.position, arrow.position + pad.direction, Vector3.UP)
	pad.add_child(arrow)
	kit.turbo(pad, at, grid.cell_size)


func _add_crates() -> void:
	var container := Node3D.new()
	container.name = "Crates"
	add_child(container)
	var size := Vector3(1.0, 1.0, 1.0)
	for i: int in grid.crates.size():
		var crate := Crate.new()
		crate.name = "Crate%d" % i
		crate.position = grid.cell_center(grid.crates[i]) + Vector3(0.0, 0.5, 0.0)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		crate.add_child(shape)
		crate.add_child(kit.crate(size))
		container.add_child(crate)
		crates.append(crate)
		# A box is two dozen little boxes and goes off the floor as one thing, so it is baked as
		# one thing. Across boxes it cannot be: they are broken one at a time.
		if bake_scenery:
			Bake.merge(crate)


## What has been dropped on the floor and left there, GAME.md 8.1. Baked as it is built: a card
## lying on the baize is two triangles, and there is no reason for any of them to be a draw call.
func _add_litter() -> void:
	var dropped := Node3D.new()
	dropped.name = "Litter"
	add_child(dropped)
	kit.litter(dropped, grid, LITTER_COUNT)
	if bake_scenery:
		Bake.merge(dropped)


func _add_pits() -> void:
	var holes := Node3D.new()
	holes.name = "Pits"
	add_child(holes)
	for i: int in grid.pits.size():
		var rect := grid.pits[i]
		var size2 := grid.rect_size(rect)
		var pit := Pit.new()
		pit.name = "Pit%d" % i
		pit.position = grid.rect_center(rect)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(size2.x * Pit.TRIGGER_SHARE, 1.0, size2.y * Pit.TRIGGER_SHARE)
		shape.shape = box
		shape.position = Vector3(0.0, 0.5, 0.0)
		pit.add_child(shape)
		pit.add_child(_pit_shaft(size2))
		# And whatever the room keeps at the bottom of one, GAME.md 8.1.
		kit.pit(pit, size2)
		holes.add_child(pit)
		pits.append(pit)
	if bake_scenery:
		Bake.merge(holes)


## The inside of a pit: four walls shading from the felt's edge into black, a black bottom well
## below the floor, and a dark rim on the floor around the opening so the edge reads.
func _pit_shaft(size2: Vector2) -> MeshInstance3D:
	var hx := size2.x * 0.5
	var hz := size2.y * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rim: Array[Vector3] = [
		Vector3(-hx, 0.0, -hz), Vector3(hx, 0.0, -hz), Vector3(hx, 0.0, hz), Vector3(-hx, 0.0, hz)
	]
	var floor_colors: Array[Color] = [PIT_WALL_TOP, PIT_WALL_TOP, PIT_COLOR, PIT_COLOR]
	for i: int in 4:
		var a: Vector3 = rim[i]
		var b: Vector3 = rim[(i + 1) % 4]
		var inward := Vector3(b.z - a.z, 0.0, a.x - b.x).normalized()
		var wall: Array[Vector3] = [
			a, b, Vector3(b.x, -PIT_DEPTH, b.z), Vector3(a.x, -PIT_DEPTH, a.z)
		]
		_colored_quad(st, wall, floor_colors, inward)
		var lip_a := a - inward * PIT_RIM
		var lip_b := b - inward * PIT_RIM
		var lip: Array[Vector3] = [
			lip_a + Vector3.UP * 0.004,
			lip_b + Vector3.UP * 0.004,
			b + Vector3.UP * 0.004,
			a + Vector3.UP * 0.004
		]
		var lip_colors: Array[Color] = [PIT_RIM_COLOR, PIT_RIM_COLOR, PIT_RIM_COLOR, PIT_RIM_COLOR]
		_colored_quad(st, lip, lip_colors, Vector3.UP)
	var bottom: Array[Vector3] = []
	for corner: Vector3 in rim:
		bottom.append(Vector3(corner.x, -PIT_DEPTH, corner.z))
	var black: Array[Color] = [PIT_COLOR, PIT_COLOR, PIT_COLOR, PIT_COLOR]
	_colored_quad(st, bottom, black, Vector3.UP)
	var shaft := MeshInstance3D.new()
	shaft.name = "Shaft"
	shaft.mesh = st.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	shaft.material_override = material
	return shaft


## The cash-out pad, where the map has one. A map may not: the test track in 9.4 is a road with
## corners on it and nothing to bank, and a pad of no size in the corner of it is worse than no
## pad at all. Everything that reaches for [member junction] checks for it.
## The ways out of a practice room, GAME.md 9.4. The arena only puts them down; where one leads
## is the room's business.
func _add_portals() -> void:
	for cell: Vector2i in grid.portals:
		var pad := Portal.new()
		pad.name = "Portal%d" % portals.size()
		pad.position = grid.cell_center(cell)
		add_child(pad)
		portals.append(pad)


func _add_junction() -> void:
	for i: int in grid.junctions.size():
		var rect := grid.junctions[i]
		var size2 := grid.rect_size(rect)
		var pad := JunctionPad.new()
		pad.name = "JunctionPad" if i == 0 else "JunctionPad%d" % i
		pad.radius = minf(size2.x, size2.y) * 0.5
		pad.position = grid.rect_center(rect)
		add_child(pad)
		junctions.append(pad)
		if i == 0:
			junction_position = pad.position
			junction_radius = pad.radius
		# What is painted on it is the room's, GAME.md 8.1: a roulette wheel let into the baize
		# After Hours, a hazard border in the Yard, a machined plate on the bench. The rim that
		# blinks is not, since the hint of 3.4 says the same thing wherever it is said.
		pad.ring_material = kit.junction(pad, pad.radius)
		# A face made of twenty flat pieces is twenty things to draw for a disc two meters across,
		# and none of it moves or is ever hidden on its own.
		if bake_scenery:
			Bake.merge(pad)


## The middle of the Junction nearest [param point], or the map's middle with none: where a bot
## goes to bank, which on a map of rooms is its own room's.
func junction_near(point: Vector3) -> Vector3:
	var best := Vector3.ZERO
	var best_distance := INF
	for pad: JunctionPad in junctions:
		var distance := pad.position.distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best = pad.position
	return best


## Whether [param kart] is banking on any Junction.
func banking(kart: Kart) -> bool:
	for pad: JunctionPad in junctions:
		if pad.is_banking(kart):
			return true
	return false


func _add_disco() -> void:
	disco = DiscoLights.new()
	disco.name = "DiscoLights"
	add_child(disco)
	disco.setup(world_size(), room.disco_colors)


func _add_jackpots() -> void:
	var zones := Node3D.new()
	zones.name = "JackpotZones"
	add_child(zones)
	for i: int in grid.jackpots.size():
		var rect := grid.jackpots[i]
		var size2 := grid.rect_size(rect)
		var position := grid.rect_center(rect)
		jackpot_positions.append(position)
		var zone := JackpotZone.new()
		zone.name = "JackpotZone%d" % i
		zone.index = i
		zone.size = size2
		zone.position = position
		var tile := _box_mesh(Vector3(size2.x, PAD_HEIGHT, size2.y), room.lane)
		tile.position = Vector3(0.0, PAD_HEIGHT * 0.5, 0.0)
		tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		zone.add_child(tile)
		var trim := _box_mesh(Vector3(size2.x * 0.8, PAD_HEIGHT, size2.y * 0.8), room.trim)
		trim.position = Vector3(0.0, PAD_HEIGHT * 1.1, 0.0)
		trim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		zone.add_child(trim)
		kit.jackpot(zone, size2)
		zones.add_child(zone)
		jackpot_zones.append(zone)
	# The tiles and their trims across every zone; a zone's own pole, bulbs and counter each
	# wear a material of their own and stay where they are.
	if bake_scenery:
		Bake.merge(zones)


## Painted, which is what nearly everything in an arena is. The felt and the table ask the room
## for their own materials; everything else is a block of color with paint on it.
func _material(color: Color) -> StandardMaterial3D:
	return surfaces.painted(color)


func _box_mesh(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _material(color)
	return instance


## A thin ring of the room's metal, laid round a pad at [param radius]. A disc of color on the
## felt reads as a sticker; the same disc with a rim round it reads as something set into the
## table, GAME.md 8.1.
func _pad_rim(radius: float, thickness := 0.06) -> MeshInstance3D:
	var torus := TorusMesh.new()
	torus.inner_radius = radius - thickness
	torus.outer_radius = radius
	torus.rings = 24
	# A tube a few centimeters thick: eight sides round it are as many as anybody sees, where
	# the thirty-two a torus comes with were a thousand triangles a rim, GAME.md 10.7.
	torus.ring_segments = 8
	var rim := MeshInstance3D.new()
	rim.mesh = torus
	rim.material_override = surfaces.metal(room.trim)
	rim.position = Vector3(0.0, PAD_HEIGHT * 0.9, 0.0)
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return rim


func _disc_mesh(radius: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = PAD_HEIGHT
	mesh.radial_segments = 32
	mesh.rings = 1
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	# A pad is paint on the floor rather than a thing standing on it, and paint casts nothing.
	instance.material_override = surfaces.marking(color)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


## A flat arrow pointing along -Z, the forward direction of look_at.
func _arrow_mesh(color: Color) -> MeshInstance3D:
	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.6, 0.6, 0.05)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = surfaces.marking(color)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The prism points up along +Y; lay it flat so the tip points along -Z.
	instance.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	var pivot := MeshInstance3D.new()
	pivot.add_child(instance)
	return pivot
