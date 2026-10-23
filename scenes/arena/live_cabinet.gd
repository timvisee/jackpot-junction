class_name LiveCabinet
extends StaticBody3D
## A live electrical cabinet, GAME.md 6.2: a run of `E` on a map, a yard's switch cabinet standing
## on the table, solid as a wall to everything, and live until it catches somebody. From the flag it
## charges for [constant CHARGE] seconds, a wall like any other, while the meter on its roof fills;
## then it is live, its beacon blinking, for as long as it takes a kart to touch it. That kart is
## electrocuted and dies there and then, as a kart that goes down a hole does: its lives and a
## respawn's protection spare it no more than they spare it a fall, though a shield takes the shock,
## up or, by Guardian Angel, in hand, and the kart lives, see [method shock]; the kill is whoever
## shoved it in inside the last couple of seconds, or nobody's, as a pit's is, 3.6. A kart already
## against it as it goes live is touching it. The shock spends the cabinet, and it charges again. A
## shot meets it as it meets a wall, stopping there or coming off with a bounce left in it, and
## throws a spark.
##
## Each cabinet keeps its own time, from the flag or from the last kart it caught, on the match's
## clock, see [method clock]. Whether a kart died of one is the host's to say, GAME.md 10.3, and so
## whether it caught one; a client spends its own cabinet from the word that a kart was killed by
## it, [signal Events.kart_killed], which every machine hears, or that a decoy was, so nothing of
## its own goes on the wire. A client that missed the word, having come in after it, has the cabinet
## live when it is charging, for what is left of one charge at most, and is right again after. A
## client driving its own kart meets the cabinet as it meets a wall, and is told of the death in the
## snapshot like any other; it never kills its own kart and so never has one to bring back to life.
## The zap, the arcs from the cabinet to the kart, the sparks, the beacon's flashing and the zap's
## sound, and the kart held in its shock, black and white and smoking, before it springs apart onto
## a scorch, see [KartShock], is shown on every screen from the same word.
##
## What it looks like is its room's, [method RoomStyle.live_cabinet], inside the box its collider
## is, its back to the wall it stands against and its door toward the box painted in front of it to
## keep clear, see [method facing] and [method keep_clear]; a room that builds none gets a plain
## one. Every room's wears the same meter and loose cable over its roof, and what the style names
## `Beacon` comes up as the meter fills, blinks slowly while it is live and flashes as it kills, see
## [CabinetLook].

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
## How long it charges, harmless, from the flag and after each kart it catches, GAME.md 6.2, in
## seconds of the match's clock: long enough to get past one that has just caught somebody, or to
## shove somebody else onto it, and short enough that a kart caught buys the room only a while.
const CHARGE := 10.0
## The kart's body as a cabinet meets it, a meter across and 1.6 m long, see `kart.tscn`; how close
## to the cabinet it has to be to be touching it, a hair, in meters; and how far from the cabinet's
## middle a kart's has to be before that is worth asking.
const KART := Vector2(1.0, 1.6)
const TOUCH := 0.05
const NEAR := 2.0
## How long before one goes live the bots keep off it as they keep off a hole, on top of how far
## ahead they play their driving, see [BotPits]: so a bot is never caught against one going live.
const BOT_LEAD := 0.5
## How loud the crackle it gives as it comes live is, in decibels: quiet, a map's detail.
const LIVE_DB := -6.0
## How long the beacon flashes as it kills.
const FLASH_TIME := 1.0
## How loud the zap is when a bullet rings the cabinet, quieter than the one that takes a kart.
const SHOT_ZAP_DB := -7.0
## The color of the arcs and sparks, a hot blue-white.
const SPARK := Color("#9FD4FF")
## The plain cabinet of a room with none of its own: safety yellow on a dark plinth, and the
## beacon's amber.
const INK := Color("#B0923A")
const DARK := Color("#2A2B2E")
const BEACON := Color("#D9822B")

## The cabinet's number in its arena, the same on every machine.
var index := -1
## The ground it stands on, see [method footprint], for the bots.
var ground := Rect2()
var _match: Match
var _played := 0.0
## When it was last spent on the match's clock: at the flag, or as it caught a kart.
var _spent_at := 0.0
var _flash_left := 0.0
var _look: CabinetLook
var _dice := RandomNumberGenerator.new()


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
		cabinet.ground = footprint(grid, run)
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
	var node := get_parent()
	while node != null and not node is Match:
		node = node.get_parent()
	_match = node as Match
	_dice.randomize()
	Events.kart_killed.connect(_on_kart_killed)
	Events.cabinet_discharged.connect(_on_discharged)
	Events.decoy_destroyed.connect(_on_decoy_destroyed)
	Events.bullet_struck.connect(_on_shot)


func _exit_tree() -> void:
	if Events.kart_killed.is_connected(_on_kart_killed):
		Events.kart_killed.disconnect(_on_kart_killed)
	if Events.cabinet_discharged.is_connected(_on_discharged):
		Events.cabinet_discharged.disconnect(_on_discharged)
	if Events.decoy_destroyed.is_connected(_on_decoy_destroyed):
		Events.decoy_destroyed.disconnect(_on_decoy_destroyed)
	if Events.bullet_struck.is_connected(_on_shot):
		Events.bullet_struck.disconnect(_on_shot)


## Builds the look, its room's [param style] first, and what it shows of its cycle over it, the
## meter and the cable at the end of it nearer the camera, see [CabinetLook]. Baked once dressed
## when [param bake] says, as a box is.
func dress(style: RoomStyle, surfaces: Surfaces, bake := true) -> void:
	var look := Node3D.new()
	look.name = "Look"
	add_child(look)
	if style == null or not style.live_cabinet(look, SIZE):
		_plain(look, surfaces)
	# The end of it toward the camera: whichever of its own ends the table's near edge is past.
	var near := 1.0 if basis.x.z >= -0.5 else -1.0
	CabinetLook.lay(look, near)
	_look = CabinetLook.new(self, look, near, surfaces)
	if bake:
		Bake.merge(look)


## How long it has been charging, in seconds of the match's clock: charging below
## [constant CHARGE], live from it until it catches a kart.
func charged_for() -> float:
	return _played - _spent_at


## Whether it is live just now, and kills what touches it.
func live() -> bool:
	return charged_for() >= CHARGE


## Whether it is live now or goes live within [param seconds].
func live_within(seconds: float) -> bool:
	return charged_for() + seconds >= CHARGE


## Spends it: it caught a kart, and charges again from now.
func spend() -> void:
	_spent_at = _played


## Has it charged for [param seconds] already, live from [constant CHARGE] on: for the tests and
## the warm-up.
func charge_for(seconds: float) -> void:
	_spent_at = _played - seconds


## The clock the cabinets of [param match_node] charge by, in seconds of play, from [param was] a
## tick of [param delta] ago: in a timed match outside overtime, how much of the match's clock has
## run, nought before the flag, which a client is told thirty times a second with the rest of the
## match, 10.3, so every machine has a cabinet charging and live together with nothing of its own on
## the wire; in overtime, or in a match with no clock while it is played, run on from there by each
## machine, which then differ by no more than the word that overtime began took to arrive. Without
## a match, run on.
static func clock(match_node: Match, was: float, delta: float) -> float:
	if match_node == null:
		return was + delta
	if match_node.rules.timed and match_node.state != Match.State.OVERTIME:
		return match_node.rules.duration - match_node.time_left
	var running := [Match.State.PLAYING, Match.State.LAST_CALL, Match.State.OVERTIME]
	return was + delta if match_node.state in running else was


func _physics_process(delta: float) -> void:
	var was_live := live()
	_played = clock(_match, _played, delta)
	# A clock gone back is a match begun again: charging from its flag.
	if _played < _spent_at:
		_spent_at = 0.0
	# Coming live, it says so, a short and quiet crackle, on every screen.
	if live() and not was_live and is_inside_tree() and not Game.is_headless():
		Audio.play_sfx(&"cabinet_live", LIVE_DB, 0.08)
	if live() and _match != null and not _match.puppet:
		_shock_touching()


## Electrocutes every kart touching it while it is live, on the machine whose word that is: a kart
## driven into it is caught as it hits, see [KartCollisions], and this catches one that was against
## it already as it went live, which runs into nothing.
func _shock_touching() -> void:
	for node: Node in FrameGroups.of(get_tree(), &"karts"):
		var kart := node as Kart if is_instance_valid(node) else null
		if kart == null or not kart.alive:
			continue
		if global_position.distance_to(kart.global_position) > NEAR:
			continue
		if _match.is_ancestor_of(kart) and touching(kart):
			shock(kart)


## Whether [param kart]'s body is against the cabinet's, flat, within [constant TOUCH]: the two
## boxes tried against each other along the sides of both.
func touching(kart: Kart) -> bool:
	var there := global_transform.affine_inverse() * kart.global_transform
	var middle := Vector2(there.origin.x, there.origin.z)
	var across := Vector2(there.basis.x.x, there.basis.x.z).normalized()
	var along := Vector2(there.basis.z.x, there.basis.z.z).normalized()
	var mine := Vector2(SIZE.x, SIZE.z) * 0.5 + Vector2.ONE * TOUCH
	var its := KART * 0.5
	for axis: Vector2 in [Vector2.RIGHT, Vector2.DOWN, across, along]:
		var reach := its.x * absf(across.dot(axis)) + its.y * absf(along.dot(axis))
		reach += mine.x * absf(axis.x) + mine.y * absf(axis.y)
		if absf(middle.dot(axis)) > reach:
			return false
	return true


## [param kart] touched the cabinet, on the machine whose word it is, the host's or one playing on
## its own: while it is live, it is electrocuted, and the kill is whoever shoved it in lately, or
## nobody's, as a pit's is, see [method Kart._step_fall], and the cabinet is spent; while it
## charges, it has hit a wall. A kart rolling out the end of a match is touched by nothing; one
## already dead or going down a hole is beyond it.
func shock(kart: Kart) -> void:
	if not live() or not kart.alive or kart.falling or kart.coasting:
		return
	var now := Time.get_ticks_msec() * 0.001
	var window := kart.rules.bump_attribution_window if kart.rules != null else 0.0
	var pusher := kart.last_bump_slot if now - kart.last_bump_time <= window else -1
	spend()
	# A shield takes the shock, held or, by Guardian Angel, in hand, and the cabinet is spent on it.
	if kart.shielded or (not kart.is_decoy() and KartLives.spared(kart, CAUSE)):
		if kart.shielded:
			kart.pop_shield()
		Events.cabinet_discharged.emit(kart.slot)
		return
	kart.die(CAUSE, pusher)


## Whether the beacon is flashing just now, for the tests.
func flashing() -> bool:
	return _flash_left > 0.0


## What it shows of its cycle, for the tests.
func look() -> CabinetLook:
	return _look


## The zap on every screen: arcs from the cabinet to [param at], sparks there, and the beacon
## flashing.
func zap(at: Vector3) -> void:
	_flash_left = FLASH_TIME
	if not is_inside_tree() or Game.is_headless():
		return
	var top := global_position + Vector3(0.0, SIZE.y * 0.85, 0.0)
	ZapArc.spawn(get_parent(), top, at + Vector3(0.0, 0.45, 0.0), SPARK)
	Burst.spawn(get_parent(), at, SPARK, 0.55, 14)
	ZapArc.over(get_parent(), at, SPARK, _dice, 3)
	# The flash of it, a small flare of the spark's blue off the floor where the kart was.
	var flare := SpawnRing.spawn(get_parent(), at, SPARK)
	flare.scale = Vector3.ONE * 0.45


func _on_kart_killed(victim: int, _killer: int, cause: StringName) -> void:
	if cause == CAUSE and is_inside_tree():
		_caught(Kart.of_slot(get_tree(), victim))


## The word that [param slot]'s shield took a shock, on every machine: by this cabinet if the kart
## is beside it. A client's cabinet is spent from it, the host's having been as it touched, and the
## zap shown, the kart living through it.
func _on_discharged(slot: int) -> void:
	if not is_inside_tree():
		return
	var kart := Kart.of_slot(get_tree(), slot)
	if kart == null or _reach_of(kart.global_position) > ZAP_REACH:
		return
	if _match != null and _match.puppet:
		spend()
	zap(kart.global_position)


## A decoy electrocuted, GAME.md 7.2, which spends a cabinet as a kart does: the one of
## [param owner_slot]'s decoys beside this cabinet, if any is.
func _on_decoy_destroyed(owner_slot: int, _by_slot: int, cause: StringName) -> void:
	if cause != CAUSE or not is_inside_tree():
		return
	for node: Node in FrameGroups.of(get_tree(), &"karts"):
		var decoy := node as Kart if is_instance_valid(node) else null
		if decoy != null and decoy.is_decoy() and decoy.slot == owner_slot:
			if _reach_of(decoy.global_position) <= ZAP_REACH:
				_caught(decoy)
				return


## The word that [param kart] was electrocuted, on every machine: by this cabinet if it died beside
## it. A client's cabinet is spent from it, the host's having been as it caught the kart, see
## [method shock], and the zap shown. A client's kart is held in its shock from it too, the host's
## having been as it died, see [method Kart.die]; one the snapshot has sprung apart already is left
## the smoke and the scorch.
func _caught(kart: Kart) -> void:
	if kart == null:
		return
	var at := kart.global_position
	if _reach_of(at) > ZAP_REACH:
		return
	if _match != null and _match.puppet:
		spend()
	zap(at)
	if kart.puppet:
		KartShock.take(kart, kart.alive)


## A shot landing on the cabinet throws a spark off it, on every machine from the same word: a crack
## and an arc down the cabinet to where it struck, but no charge spent, GAME.md 6.2, so a bullet
## rings the live cabinet without setting it off, see [method zap] and [method spend].
func _on_shot(at: Vector3, _normal: Vector3, _color: Color) -> void:
	if not is_inside_tree() or Game.is_headless() or _reach_of(at) > 0.25:
		return
	var top := global_position + Vector3(0.0, SIZE.y * 0.85, 0.0)
	ZapArc.crackle(get_parent(), top, at + Vector3(0.0, 0.3, 0.0), SPARK)
	Burst.spawn(get_parent(), at, SPARK, 0.3, 7)
	Audio.play_sfx(&"zap", SHOT_ZAP_DB, 0.0)


## How far [param at] is from the cabinet's footprint, flat, in meters.
func _reach_of(at: Vector3) -> float:
	var local := to_local(Vector3(at.x, global_position.y, at.z))
	var half := Vector2(SIZE.x, SIZE.z) * 0.5
	var flat := Vector2(local.x, local.z)
	return flat.distance_to(flat.clamp(-half, half))


func _process(delta: float) -> void:
	_flash_left = maxf(_flash_left - delta, 0.0)
	if _look != null and not Game.is_headless():
		_look.step(delta, charged_for(), _flash_left)


## The plain cabinet of a room with none of its own: a safety-yellow box on a dark plinth, a
## black hazard band round its foot, and the beacon on its roof, which is where every room's is,
## see [constant CabinetLook.ROOF].
func _plain(look: Node3D, surfaces: Surfaces) -> void:
	var plinth := 0.1
	var dark := surfaces.painted(DARK)
	ToyParts.box(look, Vector3(SIZE.x, plinth, SIZE.z), dark, Vector3(0.0, plinth * 0.5, 0.0))
	var body := Vector3(SIZE.x - 0.06, CabinetLook.ROOF - plinth, SIZE.z - 0.06)
	var body_at := plinth + body.y * 0.5
	ToyParts.box(look, body, surfaces.painted(INK), Vector3(0.0, body_at, 0.0))
	var cap := Vector3(0.24, 0.05, 0.24)
	ToyParts.box(look, cap, dark, Vector3(0.0, plinth + body.y + cap.y * 0.5, 0.0))
	var lamp := surfaces.neon(BEACON, 0.6)
	var beacon := ToyParts.cylinder(look, 0.08, 0.1, lamp, Vector3(0.0, SIZE.y - 0.05, 0.0), 8)
	beacon.name = "Beacon"
