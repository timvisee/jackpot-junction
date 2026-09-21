class_name Arena
extends Node3D
## Builds the arena from an [ArenaLayout]: table, floor, walls, pads, zones and spawn points.
## Everything is a grey box for now; the art pass replaces meshes and materials, not structure.

## A crate broke; [param by_slot] gets the credit, -1 for nobody.
signal crate_broken(by_slot: int)
## A shooting target went down; the slot that shot it collects [param coins].
signal target_struck(by_slot: int, coins: int)

const FLOOR_THICKNESS := 0.2
const TABLE_OVERHANG := 30.0
## How far out past the far wall a hoarding stands, GAME.md 8.1, and how far along that edge
## from the middle: out by the corners, where the booth in the middle and the tanks beside it
## are not, and on the edge the camera has behind the table rather than out at the sides, which
## is off the screen.
const BILLBOARD_STANDOFF := 3.6
const BILLBOARD_ALONG := 0.85
const PAD_HEIGHT := 0.05
const PIT_COLOR := Color("#0B0B0E")
## How deep the pit shafts go below the floor, and the width of the dark rim around them.
const PIT_DEPTH := 1.1
const PIT_RIM := 0.09
const PIT_WALL_TOP := Color(0.13, 0.17, 0.14)
const PIT_RIM_COLOR := Color(0.1, 0.12, 0.11)
const JUNCTION_BASE_COLOR := Color("#1E1E24")

@export var layout: ArenaLayout

var grid: ArenaGrid
## The room this map is played in, GAME.md 8.1: what it is lit by and what it is made of. Read
## by the lighting, the crowd and every surface here.
var room: RoomLook
## What the room is made of: the materials every mesh here is built from.
var surfaces: Surfaces
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
var junction: JunctionPad
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
	if layout != null and grid == null:
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


## Rebuilds every child from the layout.
func build() -> void:
	grid = layout.parse()
	room = layout.room if layout.room != null else RoomLook.fallback()
	surfaces = Surfaces.new(room)
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
	jackpot_zones.clear()
	jackpot_positions.clear()
	pickups = Node3D.new()
	pickups.name = "Pickups"
	add_child(pickups)
	_add_table()
	_add_floor()
	_add_walls()
	_add_spawns()
	_add_coin_pads()
	_add_power_pads()
	_add_flush_pads()
	_add_targets()
	_add_joker_pads()
	_add_portals()
	_add_turbo_pads()
	_add_crates()
	_add_pits()
	_add_junction()
	_add_jackpots()
	_add_disco()
	crowd = Crowd.add_to(self, world_size(), room)
	_add_billboards()


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
		if not crate.destroyed.is_connected(_on_crate_destroyed):
			crate.destroyed.connect(_on_crate_destroyed.bind(crate))
	if junction != null:
		junction.rules = rules
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
func spawn_chips(
	origin: Vector3, count: int, lifetime: float, gold_chance: float = 0.0, dropped: bool = false
) -> Array[Chip]:
	var result: Array[Chip] = []
	for i: int in count:
		var chip := Chip.new()
		chip.gold = _rng.randf() < gold_chance
		chip.value = _rules.gold_chip_value if chip.gold else _rules.chip_value
		chip.dropped = dropped
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
		var centre := grid.rect_center(rect)
		var half := grid.rect_size(rect) * 0.5
		if absf(point.x - centre.x) <= half.x and absf(point.z - centre.z) <= half.y:
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
## whoever will pay for them. Two of [constant Billboard.ADS] are drawn as the room goes up, so
## a run of matches is not the same two posters over and over. The crowd leaves each one a bay,
## since a board put up to be read with a band of people standing in front of it is a board
## nobody reads.
func _add_billboards() -> void:
	billboards = Node3D.new()
	billboards.name = "Billboards"
	add_child(billboards)
	var half := world_size() * 0.5
	var ads := Billboard.ADS.duplicate()
	ads.shuffle()
	for i: int in 2:
		var ad: Array = ads[i % ads.size()]
		var side := -1.0 if i == 0 else 1.0
		var at := Vector3(side * half.x * BILLBOARD_ALONG, 0.0, -(half.y + BILLBOARD_STANDOFF))
		var board := Billboard.add_to(billboards, at, Vector3.ZERO, room)
		board.panel(Vector2(0.0, -0.78), Vector2(Billboard.WIDTH - 1.0, 0.2), ad[2], true)
		board.words(ad[0], Vector2(0.0, 0.45), 0.92, ad[2])
		board.words(ad[1], Vector2(0.0, -0.3), 0.4, Color(0.86, 0.88, 0.94))
		var bay := Rect2(at.x - Billboard.WIDTH * 0.5, at.z - 1.6, Billboard.WIDTH, 3.2)
		if crowd != null:
			crowd.keep_clear(bay)


func _add_table() -> void:
	var half := (world_size() + Vector2.ONE * TABLE_OVERHANG) * 0.5
	var table := _slab_with_holes(half, -FLOOR_THICKNESS, 0.5, _pit_rects(), surfaces.surround())
	table.name = "Table"
	add_child(table)


## The felt, with the pits cut out so the shafts below show through as real holes.
func _add_floor() -> void:
	var floor_mesh := _slab_with_holes(
		world_size() * 0.5, 0.0, FLOOR_THICKNESS, _pit_rects(), surfaces.floor_top()
	)
	floor_mesh.name = "Floor"
	add_child(floor_mesh)


## World-space footprints of the pits on the XZ plane.
func _pit_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for rect: Rect2i in grid.pits:
		var centre := grid.rect_center(rect)
		var size2 := grid.rect_size(rect)
		result.append(Rect2(Vector2(centre.x, centre.z) - size2 * 0.5, size2))
	return result


## A slab centred on the origin whose top face at [param top] has [param holes] cut out, with
## sides down to [param thickness] below and no bottom. The top is split along every hole edge
## into cells; cells inside a hole are left out.
func _slab_with_holes(
	half: Vector2, top: float, thickness: float, holes: Array[Rect2], skin: StandardMaterial3D
) -> MeshInstance3D:
	var xs: Array[float] = [-half.x, half.x]
	var zs: Array[float] = [-half.y, half.y]
	for hole: Rect2 in holes:
		xs.append_array([hole.position.x, hole.end.x])
		zs.append_array([hole.position.y, hole.end.y])
	xs.sort()
	zs.sort()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in xs.size() - 1:
		for j: int in zs.size() - 1:
			var x0 := xs[i]
			var x1 := xs[i + 1]
			var z0 := zs[j]
			var z1 := zs[j + 1]
			if x1 - x0 < 0.001 or z1 - z0 < 0.001:
				continue
			var centre := Vector2((x0 + x1) * 0.5, (z0 + z1) * 0.5)
			var inside := false
			for hole: Rect2 in holes:
				if hole.has_point(centre):
					inside = true
					break
			if inside:
				continue
			_quad(
				st,
				Vector3(x0, top, z0),
				Vector3(x1, top, z0),
				Vector3(x1, top, z1),
				Vector3(x0, top, z1),
				Vector3.UP
			)
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
		_quad(st, a, b, Vector3(b.x, bottom, b.z), Vector3(a.x, bottom, a.z), outward)
	var instance := MeshInstance3D.new()
	instance.mesh = st.commit()
	skin.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = skin
	return instance


## Two triangles for the quad a, b, c, d with one normal; both faces render, so winding is free.
func _quad(
	st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3
) -> void:
	st.set_normal(normal)
	for vertex: Vector3 in [a, b, c, a, c, d]:
		st.add_vertex(vertex)


## Two triangles for a quad with a colour per corner, for the shaded pit shafts.
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
		body.add_child(_box_mesh(size, room.wall))
		walls.add_child(body)


func _add_spawns() -> void:
	for i: int in grid.spawns.size():
		var position := grid.cell_center(grid.spawns[i])
		spawn_points.append(position)
		var marker := Marker3D.new()
		marker.name = "Spawn%d" % i
		marker.position = position
		add_child(marker)
		var disc := _disc_mesh(0.5, room.marking)
		disc.position = Vector3(0.0, PAD_HEIGHT * 0.5, 0.0)
		marker.add_child(disc)


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
		pad.letter = FlushPad.LETTERS[i % FlushPad.LETTERS.size()]
		pad.size = grid.cell_size
		pad.position = grid.cell_center(grid.flush_pads[i])
		pads.add_child(pad)
		flush_pads.append(pad)


func _add_turbo_pads() -> void:
	var pads := Node3D.new()
	pads.name = "TurboPads"
	add_child(pads)
	for i: int in grid.turbo_pads.size():
		var cell := grid.turbo_pads[i]
		var pad := TurboPad.new()
		pad.name = "TurboPad%d" % i
		pad.direction = grid.turbo_direction(cell)
		pad.half_size = grid.cell_size * 0.5
		pad.position = grid.cell_center(cell)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(grid.cell_size, 1.0, grid.cell_size)
		shape.shape = box
		shape.position = Vector3(0.0, 0.5, 0.0)
		pad.add_child(shape)
		# A dark plate set into the felt with a lit face on it, rather than a flat cyan square:
		# the frame is what makes it read as a fitting, GAME.md 8.1.
		var frame := _box_mesh(Vector3(grid.cell_size, PAD_HEIGHT, grid.cell_size), room.lane)
		frame.position = Vector3(0.0, PAD_HEIGHT * 0.5, 0.0)
		pad.add_child(frame)
		var plate := _box_mesh(
			Vector3(grid.cell_size * 0.82, PAD_HEIGHT, grid.cell_size * 0.82), Palette.NEON_CYAN
		)
		plate.material_override = surfaces.neon(Palette.NEON_CYAN, 0.4)
		plate.position = Vector3(0.0, PAD_HEIGHT * 0.9, 0.0)
		pad.add_child(plate)
		var arrow := _arrow_mesh(Palette.CHIP_WHITE)
		arrow.position = Vector3(0.0, PAD_HEIGHT + 0.03, 0.0)
		arrow.look_at_from_position(arrow.position, arrow.position + pad.direction, Vector3.UP)
		pad.add_child(arrow)
		pads.add_child(pad)
		turbo_pads.append(pad)


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
		crate.add_child(_box_mesh(size, room.wall_edge))
		container.add_child(crate)
		crates.append(crate)


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
		box.size = Vector3(size2.x * 0.7, 1.0, size2.y * 0.7)
		shape.shape = box
		shape.position = Vector3(0.0, 0.5, 0.0)
		pit.add_child(shape)
		pit.add_child(_pit_shaft(size2))
		holes.add_child(pit)
		pits.append(pit)


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
	var rect := grid.junction
	if rect.size == Vector2i.ZERO:
		return
	var size2 := grid.rect_size(rect)
	junction_position = grid.rect_center(rect)
	junction_radius = minf(size2.x, size2.y) * 0.5
	var pad := JunctionPad.new()
	pad.name = "JunctionPad"
	pad.radius = junction_radius
	pad.position = junction_position
	add_child(pad)
	junction = pad
	# The roundel, GAME.md 8.1: a dark floor set into the felt, a ring of the room's metal round
	# the middle of it and another round the outside, with the neon on the rim. Flat black with
	# one pink ring read as a hole in the table.
	var base := _disc_mesh(junction_radius, JUNCTION_BASE_COLOR)
	base.position = Vector3(0.0, PAD_HEIGHT * 0.5, 0.0)
	pad.add_child(base)
	var inner := _disc_mesh(junction_radius * 0.52, room.lane)
	inner.position = Vector3(0.0, PAD_HEIGHT * 0.8, 0.0)
	pad.add_child(inner)
	pad.add_child(_pad_rim(junction_radius * 0.56, 0.1))
	pad.add_child(_pad_rim(junction_radius - 0.26, 0.12))
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = junction_radius - 0.25
	torus.outer_radius = junction_radius
	ring.mesh = torus
	# Its own material, not the shared one: the ring blinks and the magenta pads must not.
	var ring_material := surfaces.neon(Palette.NEON_MAGENTA)
	ring_material.albedo_color = Palette.NEON_MAGENTA
	ring_material.emission_enabled = true
	ring_material.emission = Palette.NEON_MAGENTA
	ring_material.emission_energy_multiplier = 0.0
	ring.material_override = ring_material
	pad.ring_material = ring_material
	ring.position = Vector3(0.0, PAD_HEIGHT + 0.02, 0.0)
	pad.add_child(ring)


func _add_disco() -> void:
	disco = DiscoLights.new()
	disco.name = "DiscoLights"
	add_child(disco)
	disco.setup(world_size())


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
		zone.add_child(tile)
		var trim := _box_mesh(Vector3(size2.x * 0.8, PAD_HEIGHT, size2.y * 0.8), room.trim)
		trim.position = Vector3(0.0, PAD_HEIGHT * 1.1, 0.0)
		zone.add_child(trim)
		zones.add_child(zone)
		jackpot_zones.append(zone)


## Painted, which is what nearly everything in an arena is. The felt and the table ask the room
## for their own materials; everything else is a block of colour with paint on it.
func _material(color: Color) -> StandardMaterial3D:
	return surfaces.painted(color)


func _box_mesh(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _material(color)
	return instance


## A thin ring of the room's metal, laid round a pad at [param radius]. A disc of colour on the
## felt reads as a sticker; the same disc with a rim round it reads as something set into the
## table, GAME.md 8.1.
func _pad_rim(radius: float, thickness := 0.06) -> MeshInstance3D:
	var torus := TorusMesh.new()
	torus.inner_radius = radius - thickness
	torus.outer_radius = radius
	torus.rings = 24
	var rim := MeshInstance3D.new()
	rim.mesh = torus
	rim.material_override = surfaces.metal(room.trim)
	rim.position = Vector3(0.0, PAD_HEIGHT * 0.9, 0.0)
	return rim


func _disc_mesh(radius: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = PAD_HEIGHT
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	# A pad is paint on the floor rather than a thing standing on it.
	instance.material_override = surfaces.marking(color)
	return instance


## A flat arrow pointing along -Z, the forward direction of look_at.
func _arrow_mesh(color: Color) -> MeshInstance3D:
	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.6, 0.6, 0.05)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = surfaces.marking(color)
	# The prism points up along +Y; lay it flat so the tip points along -Z.
	instance.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	var pivot := MeshInstance3D.new()
	pivot.add_child(instance)
	return pivot
