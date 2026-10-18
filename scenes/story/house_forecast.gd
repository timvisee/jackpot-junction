class_name HouseForecast
extends Node
## The House's forecast at the Final Hand, STORY.md 8.2 and GAME.md 6.3: where it expects every
## kart to be a second and a half from now, if it keeps on as it is going, and what it does about it
## in three acts by the match clock. The forecast itself is worked out on every machine, from how
## each kart has been moving there, for whatever shows it, see [HouseWatch]; what the House does
## with it is the host's, as every turret and pickup is: from anticipation on a rack rises where a
## kart's forecast ends, see [HouseRack], now and then the House's turret in its place, see
## [HouseTurret], and from convergence the models follow the line of a person at the table, a little
## behind them. The whistle puts all of it away.

enum Act { NONE, OBSERVATION, ANTICIPATION, CONVERGENCE }

## Where in the match each act begins, as a share of its clock.
const ACTS: Array[float] = [0.3, 0.5, 0.75]
## How far ahead the House forecasts a kart, in seconds, and in how many steps; how much of its
## turn a kart is forecast to keep from one step to the next, as a driver winds a corner off, and
## the most it is forecast to turn, in radians a second.
const AHEAD := 1.5
const STEPS := 12
const TURN_KEPT := 0.88
const TURN_MOST := 3.0
## How much of a tick's turning goes into the turn a kart is forecast to keep: a little, since a
## kart's heading jitters from one tick to the next.
const TURN_SMOOTH := 0.08
## How fast a kart has to be going to be going anywhere, in meters a second, and how far its
## forecast has to reach for a rack to be raised at it.
const MOVING := 2.0
const REACH_LEAST := 4.0
## A kart that moved further than this in a tick was put somewhere, not driven there.
const JUMP := 3.0
## How often a rack is raised at a person's kart and at a model's, in seconds, give or take a share.
const EVERY := 4.0
const MODEL_EVERY := 6.0
const JITTER := 0.25
const RETRY := 0.3
## One rack in this many raised at a person is the House's turret instead, and at convergence.
const TURRET_ONE_IN := 4
const TURRET_LATE_ONE_IN := 3
## How close a kart may be to a tile as a rack is raised on it.
const CLEAR := 1.8
## The line a person drove, as the models follow it: a point every so often, and how much is kept.
const TRAIL_STEP := 0.1
const TRAIL_KEEP := 4.5
## How far behind their person the models drive at convergence's start and at the whistle, and how
## much further each model after the first, in seconds.
const LAG_FROM := 3.0
const LAG_TO := 1.0
const LAG_EACH := 0.5


## How a kart has been moving as this machine saw it.
class Motion:
	var at := Vector3.INF
	var velocity := Vector3.ZERO
	var heading := 0.0
	var turn := 0.0


## A rack standing, and the cells it closes to the bots while it is up.
class Standing:
	var rack: HouseRack
	var cells: Array[Vector2i] = []
	var blocked := false


var match_node: Match
var rng := RandomNumberGenerator.new()
## The act the match is in, as this machine reads its clock.
var act := Act.NONE

var _motion: Dictionary[int, Motion] = {}
var _raise_left: Dictionary[int, float] = {}
var _trails: Dictionary[int, PackedVector3Array] = {}
var _trail_left := 0.0
var _standing: Array[Standing] = []
var _turrets: Array[HouseTurret] = []


## The forecast for [param in_match].
static func add_to(in_match: Match) -> HouseForecast:
	var forecast := HouseForecast.new()
	forecast.name = "HouseForecast"
	forecast.match_node = in_match
	forecast.rng.seed = hash(Time.get_ticks_usec())
	in_match.add_child(forecast)
	return forecast


## How far through [param in_match] its clock is, 0 to 1, and 1 in overtime.
static func share_of(in_match: Match) -> float:
	var whole := in_match.rules.duration if in_match.rules != null else 0.0
	if whole <= 0.0:
		return 0.0
	return clampf(1.0 - in_match.time_left / whole, 0.0, 1.0)


## The act [param in_match] is in by its clock: none before the first or once it is not running.
static func act_of(in_match: Match) -> Act:
	if not in_match.is_running() or in_match.rules == null or not in_match.rules.timed:
		return Act.NONE
	var share := share_of(in_match)
	var reached := Act.NONE
	for i: int in ACTS.size():
		if share >= ACTS[i]:
			reached = (i + 1) as Act
	return reached


## The forecast from [param at], going at [param velocity] and turning at [param turn] radians a
## second: its points over the next [param seconds], the first where it is. Meeting a wall of
## [param grid] it is turned along it, as a kart is, going on at what of its speed lies along the
## wall; in a corner it stops. Only the first point for a kart going nowhere.
static func project(
	at: Vector3, velocity: Vector3, turn: float, seconds: float, grid: ArenaGrid
) -> PackedVector3Array:
	var here := Vector3(at.x, 0.0, at.z)
	var points := PackedVector3Array([here])
	var flat := Vector2(velocity.x, velocity.z)
	var speed := flat.length()
	if speed < MOVING or seconds <= 0.0:
		return points
	var heading := flat.angle()
	var step := AHEAD / float(STEPS)
	var steps := ceili(seconds / step)
	var turning := clampf(turn, -TURN_MOST, TURN_MOST)
	for i: int in steps:
		var dt := minf(step, seconds - float(i) * step)
		heading += turning * dt
		turning *= TURN_KEPT
		var going := Vector3(cos(heading), 0.0, sin(heading)) * speed
		var next := here + going * dt
		if grid != null and _walled(grid, next):
			var along_x := Vector3(going.x, 0.0, 0.0)
			var along_z := Vector3(0.0, 0.0, going.z)
			var first := along_x if absf(going.x) >= absf(going.z) else along_z
			var second := along_z if first == along_x else along_x
			going = Vector3.ZERO
			for along: Vector3 in [first, second]:
				if along.length() >= MOVING and not _walled(grid, here + along * dt):
					going = along
					break
			if going == Vector3.ZERO:
				break
			heading = atan2(going.z, going.x)
			speed = going.length()
			turning = 0.0
			next = here + going * dt
		points.append(next)
		here = next
	return points


static func _walled(grid: ArenaGrid, point: Vector3) -> bool:
	var cell := grid.cell_of(point)
	if cell.x < 0 or cell.y < 0 or cell.x >= grid.width or cell.y >= grid.height:
		return true
	var glyph := grid.glyph(cell)
	return glyph == ArenaGrid.WALL or glyph == ArenaGrid.GATE


## [param kart]'s forecast, [constant AHEAD] seconds of it, from how it has been moving here.
func line_of(kart: Kart, seconds := AHEAD) -> PackedVector3Array:
	if kart == null:
		return PackedVector3Array()
	var motion: Motion = _motion.get(kart.slot)
	var velocity := motion.velocity if motion != null else Vector3.ZERO
	var turn := motion.turn if motion != null else 0.0
	var grid := match_node.arena.grid if match_node.arena != null else null
	return project(kart.global_position, velocity, turn, seconds, grid)


## Where [param kart] is forecast to be [param seconds] from now.
func ahead_of(kart: Kart, seconds: float) -> Vector3:
	var line := line_of(kart, seconds)
	return line[line.size() - 1] if not line.is_empty() else Vector3.INF


func _physics_process(delta: float) -> void:
	if match_node == null or match_node.arena == null or delta <= 0.0:
		return
	_track(delta)
	act = act_of(match_node)
	if match_node.puppet:
		return
	_record(delta)
	if act >= Act.ANTICIPATION:
		_raise_all(delta)
	elif not _standing.is_empty() or not _turrets.is_empty():
		_put_away()
	_close_roads()
	_lead()


func _exit_tree() -> void:
	_put_away()
	_close_roads()
	for slot: PlayerSlot in match_node.slots if match_node != null else []:
		var brain := _brain_of(slot)
		if brain != null:
			brain.led.let_go()


## How every kart has been moving: how fast, which way and how fast it is turning, smoothed over a
## few ticks, from where it is from one tick to the next.
func _track(delta: float) -> void:
	for slot: PlayerSlot in match_node.slots:
		var kart := slot.kart
		if kart == null:
			continue
		var motion: Motion = _motion.get(slot.index)
		if motion == null:
			motion = Motion.new()
			_motion[slot.index] = motion
		var now := Vector3(kart.global_position.x, 0.0, kart.global_position.z)
		if not motion.at.is_finite() or now.distance_to(motion.at) > JUMP or not kart.alive:
			motion.at = now
			motion.velocity = Vector3.ZERO
			motion.turn = 0.0
			continue
		motion.velocity = motion.velocity.lerp((now - motion.at) / delta, 0.35)
		motion.at = now
		var flat := Vector2(motion.velocity.x, motion.velocity.z)
		if flat.length() < MOVING:
			motion.turn = lerpf(motion.turn, 0.0, 0.2)
			continue
		var heading := flat.angle()
		var turned := angle_difference(motion.heading, heading) / delta
		motion.heading = heading
		motion.turn = lerpf(motion.turn, clampf(turned, -TURN_MOST, TURN_MOST), TURN_SMOOTH)


## The line each person at the table drives, for the models to follow at convergence.
func _record(delta: float) -> void:
	_trail_left -= delta
	if _trail_left > 0.0:
		return
	_trail_left += TRAIL_STEP
	var keep := ceili(TRAIL_KEEP / TRAIL_STEP)
	for slot: PlayerSlot in match_node.slots:
		if slot.input is BotInput or slot.kart == null:
			continue
		var trail: PackedVector3Array = _trails.get(slot.index, PackedVector3Array())
		if not slot.kart.is_active():
			trail.clear()
		else:
			trail.append(Vector3(slot.kart.global_position.x, 0.0, slot.kart.global_position.z))
			if trail.size() > keep:
				trail = trail.slice(trail.size() - keep)
		_trails[slot.index] = trail


## A rack, or now and then the House's turret, at every kart whose turn it is.
func _raise_all(delta: float) -> void:
	for slot: PlayerSlot in match_node.slots:
		if slot.kart == null:
			continue
		var model := slot.input is BotInput
		var left: float = _raise_left.get(slot.index, rng.randf_range(0.2, 1.0) * EVERY)
		left -= delta
		if left <= 0.0:
			if slot.kart.is_active() and _raise_at(slot, model):
				var every := MODEL_EVERY if model else EVERY
				left = every * rng.randf_range(1.0 - JITTER, 1.0 + JITTER)
			else:
				left = RETRY
		_raise_left[slot.index] = left


## A rack where [param slot]'s forecast ends, across the road it is on, or the House's turret in
## its place for a person's kart; whether one went up. The far half of the forecast is tried from
## its end back, for the first tile one may rise on.
func _raise_at(slot: PlayerSlot, model: bool) -> bool:
	var line := line_of(slot.kart)
	if line.size() < 3 or line[0].distance_to(line[line.size() - 1]) < REACH_LEAST:
		return false
	var grid := match_node.arena.grid
	for i: int in range(line.size() - 1, line.size() / 2, -1):
		var cell := grid.cell_of(line[i])
		if not _free(cell):
			continue
		var one_in := TURRET_LATE_ONE_IN if act == Act.CONVERGENCE else TURRET_ONE_IN
		if not model and rng.randi_range(1, one_in) == 1:
			_turret_at(cell, slot)
			return true
		var going := line[i] - line[i - 1]
		var cells := _across(cell, line[i], going)
		var middle := Vector3.ZERO
		for each: Vector2i in cells:
			middle += grid.cell_center(each)
		middle /= float(cells.size())
		var across := Vector2.ONE * grid.cell_size
		if cells.size() == 2:
			across = Vector2(cells[1] - cells[0]).abs() * grid.cell_size + across
		var height := match_node.arena.layout.wall_height if match_node.arena.layout else 1.0
		var standing := Standing.new()
		standing.rack = HouseRack.raise(
			match_node, middle, across, slot.index, match_node.arena, height
		)
		standing.cells = cells
		_standing.append(standing)
		return true
	return false


## The cells a rack at [param cell] stands on: that one and the next across the way the kart is
## [param going], on the side [param point] is nearer, where that one is free too.
func _across(cell: Vector2i, point: Vector3, going: Vector3) -> Array[Vector2i]:
	var middle := match_node.arena.grid.cell_center(cell)
	var side := Vector2i.ZERO
	if absf(going.x) >= absf(going.z):
		side = Vector2i(0, 1 if point.z >= middle.z else -1)
	else:
		side = Vector2i(1 if point.x >= middle.x else -1, 0)
	var cells: Array[Vector2i] = [cell]
	if _free(cell + side):
		cells.append(cell + side)
	elif _free(cell - side):
		cells.append(cell - side)
	return cells


## Whether a rack may rise on [param cell]: open floor with nothing on it, no rack or turret of the
## House's on it or beside it, and no kart on it or about to be.
func _free(cell: Vector2i) -> bool:
	var grid := match_node.arena.grid
	if cell.x < 1 or cell.y < 1 or cell.x >= grid.width - 1 or cell.y >= grid.height - 1:
		return false
	if grid.glyph(cell) != ArenaGrid.FLOOR:
		return false
	for standing: Standing in _standing:
		for taken: Vector2i in standing.cells:
			if absi(taken.x - cell.x) <= 1 and absi(taken.y - cell.y) <= 1:
				return false
	for turret: HouseTurret in _turrets:
		if is_instance_valid(turret) and grid.cell_of(turret.global_position) == cell:
			return false
	var middle := grid.cell_center(cell)
	for slot: PlayerSlot in match_node.slots:
		if slot.kart != null and slot.kart.alive:
			var at := Vector3(slot.kart.global_position.x, 0.0, slot.kart.global_position.z)
			if at.distance_to(middle) < CLEAR + grid.cell_size * 0.5:
				return false
	return true


## The House's turret on [param cell], at [param slot]'s forecast.
func _turret_at(cell: Vector2i, slot: PlayerSlot) -> void:
	var turret := HouseTurret.new()
	turret.name = "HouseTurret"
	turret.target = slot.index
	turret.forecast = self
	turret.bullet_system = match_node.bullets
	match_node.add_child(turret)
	var at := match_node.arena.grid.cell_center(cell)
	turret.global_position = at
	var toward := slot.kart.global_position - at
	turret.rotation.y = atan2(-toward.x, -toward.z)
	_turrets.append(turret)


## The racks' cells closed to the bots while they stand, and open again once they are going down
## or gone.
func _close_roads() -> void:
	var nav := match_node.nav
	for i: int in range(_standing.size() - 1, -1, -1):
		var standing := _standing[i]
		var up := is_instance_valid(standing.rack) and standing.rack.is_solid()
		if up != standing.blocked and nav != null:
			for cell: Vector2i in standing.cells:
				nav.set_cell_blocked(cell, up)
			standing.blocked = up
		if not is_instance_valid(standing.rack):
			_standing.remove_at(i)
	for i: int in range(_turrets.size() - 1, -1, -1):
		if not is_instance_valid(_turrets[i]):
			_turrets.remove_at(i)


## Every rack and turret down into the floor, as at the whistle.
func _put_away() -> void:
	for standing: Standing in _standing:
		if is_instance_valid(standing.rack):
			standing.rack.sink()
	for turret: HouseTurret in _turrets:
		if is_instance_valid(turret):
			turret.destroy()


## How far behind their person the models drive at this point of [param in_match], in seconds:
## the first of them, and with [param last] the last of the Final Hand's.
static func behind_at(in_match: Match, last := false) -> float:
	var share := clampf((share_of(in_match) - ACTS[2]) / 0.25, 0.0, 1.0)
	return lerpf(LAG_FROM, LAG_TO, share) + (LAG_EACH * float(FinalHand.BOTS - 1) if last else 0.0)


## At convergence each model drives the line of a person at the table, shared out among them in
## turn, a little behind them, the gap closing as the whistle comes, see [BotLed]; and otherwise
## goes its own way.
func _lead() -> void:
	var people: Array[PlayerSlot] = []
	for slot: PlayerSlot in match_node.slots:
		if not slot.input is BotInput and slot.kart != null and slot.kart.is_active():
			people.append(slot)
	var behind := behind_at(match_node)
	var model := 0
	for slot: PlayerSlot in match_node.slots:
		var brain := _brain_of(slot)
		if brain == null:
			continue
		if act != Act.CONVERGENCE or people.is_empty():
			brain.led.let_go()
			continue
		var person := people[model % people.size()]
		var lag := behind + LAG_EACH * float(model / people.size())
		var trail: PackedVector3Array = _trails.get(person.index, PackedVector3Array())
		brain.led.follow(trail, TRAIL_STEP, lag, person.kart)
		model += 1


static func _brain_of(slot: PlayerSlot) -> BotBrain:
	if not slot.input is BotInput or slot.kart == null:
		return null
	return slot.kart.get_node_or_null("Brain") as BotBrain
