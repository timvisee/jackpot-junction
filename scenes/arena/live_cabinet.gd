class_name LiveCabinet
extends StaticBody3D
## A live electrical cabinet, GAME.md 6.2: `E` on a map, a yard's switch cabinet standing on the
## table, solid as a wall to everything, and live. A kart that touches it is electrocuted and dies
## there and then, as a kart that goes down a hole does: its lives, its shield and a respawn's
## protection spare it no more than they spare it a fall, and the kill is whoever shoved it in
## inside the last couple of seconds, or nobody's, as a pit's is, 3.6. A shot meets it as it meets
## a wall, stopping there or coming off with a bounce left in it, and throws a spark.
##
## Whether a kart died of it is the host's to say, GAME.md 10.3. A client driving its own kart
## meets the cabinet as it meets a wall, and is told of the death in the snapshot like any other;
## it never kills its own kart and so never has one to bring back to life. The zap, the arcs from
## the cabinet to the kart, the sparks, the beacon's flashing and the crack, is shown on every
## screen from the word that a kart was killed by one, [signal Events.kart_killed], which every
## machine hears.
##
## What it looks like is its room's, [method RoomStyle.live_cabinet], inside the box its collider
## is, its back to the wall it stands against and its door toward the box painted in front of it to
## keep clear, see [method facing] and [method keep_clear]; a room that builds none gets a plain
## one. Whatever the style names `Beacon` pulses while it is live and
## flashes as it kills.

## What a kart killed by one is killed by, as the kill feed and everything else that names a death
## names it.
const CAUSE := &"shock"
## The box a kart meets: a cabinet a meter wide, its face to one side, and a little over the height
## of the walls.
const SIZE := Vector3(1.0, 1.2, 0.6)
## The box painted in front of its door, in cells across the door and out from it.
const BOX := Vector2(3.0, 2.0)
## How far off the wall behind it a cabinet stands, in meters.
const FLUSH := 0.01
## How far from its footprint a kart's death by a cabinet counts as this one's, for the zap, in
## meters: a cabinet's victim dies against it, and a client's picture of it is a little behind.
const ZAP_REACH := 2.5
## The beacon: how long a pulse takes while it is live, how bright it is at the dark and the light
## of one, and how bright and how long it flashes as it kills.
const PULSE := 1.8
const DIM := 0.25
const LIT := 1.1
const FLASH := 4.0
const FLASH_TIME := 1.0
const STROBE := 14.0
## The color of the arcs and sparks, a hot blue-white.
const SPARK := Color("#9FD4FF")
## The plain cabinet of a room with none of its own: safety yellow on a dark plinth, and the
## beacon's amber.
const INK := Color("#B0923A")
const DARK := Color("#2A2B2E")
const BEACON := Color("#D9822B")

## The cabinet's number in its arena, the same on every machine.
var index := -1

var _beacons: Array[StandardMaterial3D] = []
var _rest: Array[float] = []
var _clock := 0.0
var _flash_left := 0.0


## A cabinet for every run of `E` of [param arena]'s grid, into its [member Arena.cabinets], each
## in the middle of its run with its back to the wall beside it and its door the other way, see
## [method facing] and [method middle].
static func add_to(arena: Arena) -> void:
	var holder := Node3D.new()
	holder.name = "Cabinets"
	arena.add_child(holder)
	var grid := arena.grid
	for i: int in grid.cabinets.size():
		var run := grid.cabinets[i]
		var cabinet := LiveCabinet.new()
		cabinet.name = "Cabinet%d" % i
		cabinet.index = i
		cabinet.position = middle(grid, run)
		var door := facing(grid, run)
		cabinet.rotation.y = atan2(float(door.x), float(door.y))
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = SIZE
		shape.shape = box
		shape.position = Vector3(0.0, SIZE.y * 0.5, 0.0)
		cabinet.add_child(shape)
		cabinet.dress(arena.kit.style, arena.surfaces, arena.bake_scenery)
		holder.add_child(cabinet)
		arena.cabinets.append(cabinet)


## The way the door of the cabinet on the run of cells [param run] of [param grid] faces, a step
## across the grid: away from the wall it stands with its back to, the first of left, right, up
## and down that is wall all along the run, as a yard puts a cabinet up against a wall; free of
## any, toward the near side, the camera's, where the box in front of it fits that way, see
## [method keep_clear], and the far side where not.
static func facing(grid: ArenaGrid, run: Rect2i) -> Vector2i:
	var back := _back(grid, run)
	if back != Vector2i.ZERO:
		return -back
	return Vector2i.DOWN if _all_floor(grid, _box_toward(run, Vector2i.DOWN)) else Vector2i.UP


## The way to the wall the cabinet on [param run] stands against, or none: the side every cell
## beside the run is wall on.
static func _back(grid: ArenaGrid, run: Rect2i) -> Vector2i:
	for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if _walled(grid, run, side):
			return side
	return Vector2i.ZERO


static func _walled(grid: ArenaGrid, run: Rect2i, side: Vector2i) -> bool:
	var along := Vector2i(absi(side.y), absi(side.x))
	var first := (
		run.position + Vector2i(maxi(side.x, 0), maxi(side.y, 0)) * (run.size - Vector2i.ONE)
	)
	for k: int in maxi(run.size.x * along.x, run.size.y * along.y):
		var next := first + along * k + side
		if next.x < 0 or next.y < 0 or next.x >= grid.width or next.y >= grid.height:
			return false
		if grid.glyph(next) != ArenaGrid.WALL:
			return false
	return true


## Whether the word painted in front of the cabinet on [param run] reads the right way up from the
## camera, which it does unless the door faces away from it, see [method YardStyle.house_word].
static func lettered(grid: ArenaGrid, run: Rect2i) -> bool:
	return facing(grid, run) != Vector2i.UP


## Where the cabinet on [param run] stands, on the floor: in the middle of its run, flush against
## the wall at its back, a centimeter off it, or in the middle of the run with none. A run of two
## along a wall two cells long puts it in the middle of that wall.
static func middle(grid: ArenaGrid, run: Rect2i) -> Vector3:
	var back := _back(grid, run)
	var deep := Vector2(run.size) * grid.cell_size * 0.5
	var off := absf(deep.x * back.x + deep.y * back.y) - SIZE.z * 0.5 - FLUSH
	return grid.rect_center(run) + Vector3(float(back.x), 0.0, float(back.y)) * off


## The box in front of the door of the cabinet on [param run] of [param grid] to be kept clear and
## painted so, in cells from the grid's corner: [constant BOX] across the door, its middle in line
## with the cabinet's, and out from the face of the run.
static func keep_clear(grid: ArenaGrid, run: Rect2i) -> Rect2:
	return _box_toward(run, facing(grid, run))


static func _box_toward(run: Rect2i, door: Vector2i) -> Rect2:
	var across := Vector2(absi(door.y), absi(door.x))
	var out := Vector2(door)
	var half := Vector2(run.size) * 0.5
	var face := Vector2(run.position) + half + out * absf(half.x * out.x + half.y * out.y)
	var one := face - across * BOX.x * 0.5
	var other := face + out * BOX.y + across * BOX.x * 0.5
	return Rect2(one, Vector2.ZERO).expand(other)


## The cells [param box], in cells from the grid's corner, lies over, any part of them.
static func cells_under(box: Rect2) -> Rect2i:
	var low := Vector2i(floori(box.position.x + 0.001), floori(box.position.y + 0.001))
	var high := Vector2i(ceili(box.end.x - 0.001), ceili(box.end.y - 0.001))
	return Rect2i(low, high - low)


static func _all_floor(grid: ArenaGrid, box: Rect2) -> bool:
	var cells := cells_under(box)
	for y: int in range(cells.position.y, cells.end.y):
		for x: int in range(cells.position.x, cells.end.x):
			if x < 0 or y < 0 or x >= grid.width or y >= grid.height:
				return false
			if grid.glyph(Vector2i(x, y)) != ArenaGrid.FLOOR:
				return false
	return true


## The ground the cabinet on [param run] of [param grid] stands on, in meters across the floor,
## x and z, turned as it stands: what a kart touching is a kart killed, see [BotPits].
static func footprint(grid: ArenaGrid, run: Rect2i) -> Rect2:
	var at := middle(grid, run)
	var door := facing(grid, run)
	var half := Vector2(SIZE.x, SIZE.z) * 0.5
	if door.x != 0:
		half = Vector2(half.y, half.x)
	return Rect2(Vector2(at.x, at.z) - half, half * 2.0)


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0
	add_to_group(&"cabinets")
	Events.kart_killed.connect(_on_kart_killed)
	Events.bullet_struck.connect(_on_shot)


func _exit_tree() -> void:
	if Events.kart_killed.is_connected(_on_kart_killed):
		Events.kart_killed.disconnect(_on_kart_killed)
	if Events.bullet_struck.is_connected(_on_shot):
		Events.bullet_struck.disconnect(_on_shot)


## Builds the look, its room's [param style] first, and gives each beacon a material of its own to
## pulse and flash. Baked once dressed when [param bake] says, as a box is.
func dress(style: RoomStyle, surfaces: Surfaces, bake := true) -> void:
	var look := Node3D.new()
	look.name = "Look"
	add_child(look)
	if style == null or not style.live_cabinet(look, SIZE):
		_plain(look, surfaces)
	_own_beacons(look)
	if bake:
		Bake.merge(look)


## [param kart] touched the cabinet, on the machine whose word it is, the host's or one playing on
## its own: it is electrocuted, and the kill is whoever shoved it in lately, or nobody's, as a
## pit's is, see [method Kart._step_fall]. A kart rolling out the end of a match is touched by
## nothing; one already dead or going down a hole is beyond it.
func shock(kart: Kart) -> void:
	if not kart.alive or kart.falling or kart.coasting:
		return
	var now := Time.get_ticks_msec() * 0.001
	var window := kart.rules.bump_attribution_window if kart.rules != null else 0.0
	var pusher := kart.last_bump_slot if now - kart.last_bump_time <= window else -1
	kart.die(CAUSE, pusher)


## Whether the beacon is flashing just now, for the tests.
func flashing() -> bool:
	return _flash_left > 0.0


## The zap on every screen: arcs from the cabinet to [param at], sparks there, and the beacon
## flashing.
func zap(at: Vector3) -> void:
	_flash_left = FLASH_TIME
	if not is_inside_tree() or Game.is_headless():
		return
	var top := global_position + Vector3(0.0, SIZE.y * 0.85, 0.0)
	ZapArc.spawn(get_parent(), top, at + Vector3(0.0, 0.45, 0.0), SPARK)
	Burst.spawn(get_parent(), at, SPARK, 0.55, 14)
	# The flash of it, a small flare of the spark's blue off the floor where the kart was.
	var flare := SpawnRing.spawn(get_parent(), at, SPARK)
	flare.scale = Vector3.ONE * 0.45


func _on_kart_killed(victim: int, _killer: int, cause: StringName) -> void:
	if cause != CAUSE or not is_inside_tree():
		return
	var kart := Kart.of_slot(get_tree(), victim)
	if kart == null:
		return
	var at := kart.global_position
	if _reach_of(at) <= ZAP_REACH:
		zap(at)


## A shot landing on the cabinet throws a spark off it, on every machine from the same word.
func _on_shot(at: Vector3, _normal: Vector3, _color: Color) -> void:
	if not is_inside_tree() or Game.is_headless() or _reach_of(at) > 0.25:
		return
	Burst.spawn(get_parent(), at, SPARK, 0.25, 5)


## How far [param at] is from the cabinet's footprint, flat, in meters.
func _reach_of(at: Vector3) -> float:
	var local := to_local(Vector3(at.x, global_position.y, at.z))
	var half := Vector2(SIZE.x, SIZE.z) * 0.5
	var flat := Vector2(local.x, local.z)
	return flat.distance_to(flat.clamp(-half, half))


func _process(delta: float) -> void:
	_clock += delta
	_flash_left = maxf(_flash_left - delta, 0.0)
	var glow := lerpf(DIM, LIT, 0.5 + 0.5 * sin(_clock * TAU / PULSE))
	if _flash_left > 0.0:
		glow = FLASH if fmod(_clock * STROBE, 1.0) < 0.5 else DIM
	for i: int in _beacons.size():
		_beacons[i].emission_energy_multiplier = _rest[i] * glow


## Gives every part named Beacon under [param node] a material of this cabinet's own.
func _own_beacons(node: Node) -> void:
	for child: Node in node.get_children():
		_own_beacons(child)
		var part := child as MeshInstance3D
		if part == null or not String(part.name).begins_with("Beacon"):
			continue
		var worn := part.material_override as StandardMaterial3D
		if worn == null:
			continue
		var own := worn.duplicate() as StandardMaterial3D
		own.emission_enabled = true
		part.material_override = own
		_beacons.append(own)
		_rest.append(own.emission_energy_multiplier)


## The plain cabinet of a room with none of its own: a safety-yellow box on a dark plinth, a
## black hazard band round its foot, and the beacon on its roof.
func _plain(look: Node3D, surfaces: Surfaces) -> void:
	var plinth := 0.1
	var dark := surfaces.painted(DARK)
	ToyParts.box(look, Vector3(SIZE.x, plinth, SIZE.z), dark, Vector3(0.0, plinth * 0.5, 0.0))
	var body := Vector3(SIZE.x - 0.06, SIZE.y - plinth - 0.16, SIZE.z - 0.06)
	var body_at := plinth + body.y * 0.5
	ToyParts.box(look, body, surfaces.painted(INK), Vector3(0.0, body_at, 0.0))
	var cap := Vector3(0.24, 0.05, 0.24)
	ToyParts.box(look, cap, dark, Vector3(0.0, plinth + body.y + cap.y * 0.5, 0.0))
	var lamp := surfaces.neon(BEACON, 0.6)
	var beacon := ToyParts.cylinder(look, 0.08, 0.1, lamp, Vector3(0.0, SIZE.y - 0.05, 0.0), 8)
	beacon.name = "Beacon"
