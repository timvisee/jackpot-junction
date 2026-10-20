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
## is, its face toward the box painted in front of it to keep clear, see [method keep_clear]; a room
## that builds none gets a plain one. Whatever the style names `Beacon` pulses while it is live and
## flashes as it kills.

## What a kart killed by one is killed by, as the kill feed and everything else that names a death
## names it.
const CAUSE := &"shock"
## The box a kart meets: a cabinet a meter wide, its face to one side, and a little over the height
## of the walls.
const SIZE := Vector3(1.0, 1.2, 0.6)
## The box painted in front of its face, in cells across and deep.
const BOX := Vector2i(3, 2)
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


## A cabinet for every `E` of [param arena]'s grid, into its [member Arena.cabinets], each turned to
## face the box in front of it, see [method faces_near].
static func add_to(arena: Arena) -> void:
	var holder := Node3D.new()
	holder.name = "Cabinets"
	arena.add_child(holder)
	var grid := arena.grid
	for i: int in grid.cabinets.size():
		var cell := grid.cabinets[i]
		var cabinet := LiveCabinet.new()
		cabinet.name = "Cabinet%d" % i
		cabinet.index = i
		cabinet.position = grid.cell_center(cell)
		cabinet.rotation.y = 0.0 if faces_near(grid, cell) else PI
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = SIZE
		shape.shape = box
		shape.position = Vector3(0.0, SIZE.y * 0.5, 0.0)
		cabinet.add_child(shape)
		cabinet.dress(arena.kit.style, arena.surfaces, arena.bake_scenery)
		holder.add_child(cabinet)
		arena.cabinets.append(cabinet)


## Whether the cabinet on [param cell] faces the near side, toward the camera: where the box in
## front of it fits that way, see [method keep_clear], and the far side where it does not.
static func faces_near(grid: ArenaGrid, cell: Vector2i) -> bool:
	return _all_floor(grid, _box_toward(cell, 1))


## The box of cells in front of the face of the cabinet on [param cell] of [param grid], to be kept
## clear and painted so: [constant BOX] across and deep, its middle cell's column the cabinet's.
static func keep_clear(grid: ArenaGrid, cell: Vector2i) -> Rect2i:
	return _box_toward(cell, 1 if faces_near(grid, cell) else -1)


static func _box_toward(cell: Vector2i, way: int) -> Rect2i:
	var left := cell.x - BOX.x / 2
	var top := cell.y + 1 if way > 0 else cell.y - BOX.y
	return Rect2i(left, top, BOX.x, BOX.y)


static func _all_floor(grid: ArenaGrid, box: Rect2i) -> bool:
	for y: int in range(box.position.y, box.end.y):
		for x: int in range(box.position.x, box.end.x):
			if x < 0 or y < 0 or x >= grid.width or y >= grid.height:
				return false
			if grid.glyph(Vector2i(x, y)) != ArenaGrid.FLOOR:
				return false
	return true


## The ground the cabinet on [param cell] of [param grid] stands on, in meters across the floor,
## x and z: what a kart touching is a kart killed, see [BotPits].
static func footprint(grid: ArenaGrid, cell: Vector2i) -> Rect2:
	var middle := grid.cell_center(cell)
	var half := Vector2(SIZE.x, SIZE.z) * 0.5
	return Rect2(Vector2(middle.x, middle.z) - half, half * 2.0)


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
