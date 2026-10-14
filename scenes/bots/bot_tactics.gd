class_name BotTactics
extends RefCounted
## What a bot makes of a shot that does not fly straight off its nose, and of somewhere to hide,
## GAME.md 9.1: Backfire's shots out of the back while the brake is held, 7.3; bullets that bounce
## off the walls, Rubber Bumpers' and the Ricochet Cannon's, taken off a wall at a kart round it and
## never fired square into a wall that would send one back where its own shots hurt it; and cover
## from a kart with a line on it, in a fight there is no coming back from, the showdown of 9.7a.
## Asked by its [BotBrain], at the pace it thinks for anything that looks about the room.

## How near a shot bounced off a wall has to pass the mark for a bot to take it, and the fan of
## ways off its aim it looks along for one: so far either side, in so many steps a side.
const BANK_MISS := 0.7
const BANK_FAN := 0.6
const BANK_STEPS := 5
## The furthest a bounced shot is worth looking along, there and back.
const BANK_REACH := 24.0
## How near a wall square in front of the muzzle stops a bot whose bullets bounce and hurt their
## owner from firing: the shot would come straight back at it. How square counts as square.
const BOUNCE_BACK := 4.0
const SQUARE := 0.7
## Cover: how far a bot looks for it, how many places it tries, how near one it has arrived, how
## long it stays once there, how long before it hides again, and how far either side of a place
## the threat must not see, a kart's half width.
const COVER_RANGE := 9.0
const COVER_TRIES := 40
const COVER_ARRIVED := 1.0
const COVER_STAY := 2.0
const COVER_AGAIN := 4.0
const COVER_WIDTH := 0.45

var brain: BotBrain
## Where the bot is hiding, [constant Vector3.INF] while it is not, see [method think_cover].
var cover := Vector3.INF
## The way, flat, a shot off a wall reaches the mark from here, or zero for none, see
## [method think_bank].
var bank_way := Vector3.ZERO
## How long the bot stays in cover once there, and how long until it may hide again.
var _cover_left := 0.0
var _cover_wait := 0.0
var _ray := PhysicsRayQueryParameters3D.new()


func _init(of: BotBrain) -> void:
	brain = of
	_ray.collision_mask = Layers.WORLD


## Where the cannon points this tick, flat: down the nose, or out of the back with Backfire and the
## brake held, see [method KartAim.direction].
func aim() -> Vector3:
	var way := KartAim.direction(brain.kart)
	way.y = 0.0
	return way.normalized()


## Whether to hold the brake for a shot out of the back at [param to_mark], holding Backfire,
## GAME.md 7.3: the mark behind, within [param cone] of the tail, and the cannon ready, so the
## brake is held for a shot and never for nothing.
func backfire(to_mark: Vector3, cone: float) -> bool:
	var kart := brain.kart
	if not kart.jokers.has(&"backfire") or kart.cannon.current_stats().free_aim:
		return false
	var tail := -kart.motor.forward_vector()
	return absf(tail.signed_angle_to(to_mark, Vector3.UP)) <= cone and kart.cannon.can_fire()


## Whether a shot now would come straight back off a wall at the bot: its bullets bounce, its own
## shots hurt it, GAME.md 3.8, and a wall stands square in front of the muzzle, near.
func bounces_back() -> bool:
	var kart := brain.kart
	if not kart.rules.own_bullets_hurt or kart.cannon.current_stats().bounces <= 0:
		return false
	var way := aim()
	_ray.from = _eye(kart.global_position)
	_ray.to = _ray.from + way * BOUNCE_BACK
	var hit := _space().intersect_ray(_ray)
	return not hit.is_empty() and (hit["normal"] as Vector3).dot(-way) > SQUARE


## At the pace the bot thinks: the way, off its aim by no more than [constant BANK_FAN], a shot
## would take to come off one wall onto [param mark_at], a kart it cannot see, see [member
## bank_way]. None for bullets that do not bounce, nor for a mark in sight, [param seen], which
## is shot straight.
func think_bank(mark_at: Vector3, seen: bool) -> void:
	bank_way = Vector3.ZERO
	var stats := brain.kart.cannon.current_stats()
	if seen or stats.bounces <= 0:
		return
	var from := _eye(brain.kart.global_position)
	var reach := minf(stats.bullet_speed * stats.lifetime, BANK_REACH)
	var forward := aim()
	# Nearest the aim first, either side in turn, so the least turning takes it.
	for step: int in BANK_STEPS * 2 + 1:
		var side := ceili(step * 0.5) * (1 if step % 2 == 1 else -1)
		var way := forward.rotated(Vector3.UP, BANK_FAN * side / BANK_STEPS)
		if _banks(from, way, _eye(mark_at), reach):
			bank_way = way
			return


## Ticks the bot's time in cover once it is there, and until it may hide again.
func step(delta: float) -> void:
	_cover_wait = maxf(_cover_wait - delta, 0.0)
	if cover == Vector3.INF:
		return
	if brain.kart.global_position.distance_to(cover) < COVER_ARRIVED:
		_cover_left -= delta
	if _cover_left <= 0.0:
		cover = Vector3.INF
		_cover_wait = COVER_AGAIN


## At the pace the bot thinks: somewhere near to hide from [param threat], GAME.md 9.7a, while the
## threat has a line on the bot in a showdown and the bot is the worse off of the two, wounded,
## with fewer lives, or every shot it has in the air; kept until it has stayed there a while, see
## [method step]. [constant Vector3.INF] for none.
func think_cover(threat: Kart) -> Vector3:
	if cover != Vector3.INF or threat == null or _cover_wait > 0.0:
		return cover
	var kart := brain.kart
	if not brain.match_node.rules.showdown():
		return cover
	var worse := kart.is_wounded() or kart.lives < threat.lives or kart.cannon.is_full()
	if not worse or not brain.has_line_of_sight(threat.global_position):
		return cover
	cover = _hiding_place(threat.global_position)
	_cover_left = COVER_STAY
	# Nowhere to hide: not looked for again at once.
	if cover == Vector3.INF:
		_cover_wait = COVER_AGAIN
	return cover


## Whether a shot from [param from] along [param way] comes off the first wall it meets, not a
## crate, which breaks it, onto [param mark] within [param reach] all told, nothing in between.
func _banks(from: Vector3, way: Vector3, mark: Vector3, reach: float) -> bool:
	_ray.from = from
	_ray.to = from + way * reach
	var hit := _space().intersect_ray(_ray)
	if hit.is_empty() or hit["collider"] is Crate:
		return false
	var at: Vector3 = hit["position"]
	var normal: Vector3 = hit["normal"]
	normal = Vector3(normal.x, 0.0, normal.z).normalized()
	var off := way.bounce(normal)
	var along := (mark - at).dot(off)
	if along <= 0.0 or along > reach - from.distance_to(at):
		return false
	if (at + off * along).distance_to(mark) > BANK_MISS:
		return false
	_ray.from = at + normal * 0.05
	_ray.to = at + off * along
	return _space().intersect_ray(_ray).is_empty()


## The nearest open place within [constant COVER_RANGE] no nearer the threat at [param threat_at]
## than the bot is, that the threat cannot see any of a kart's width of, or [constant Vector3.INF].
func _hiding_place(threat_at: Vector3) -> Vector3:
	var nav: ArenaNav = brain.match_node.nav
	var here := nav.world_to_cell(brain.kart.global_position)
	var reach := ceili(COVER_RANGE / nav.grid.cell_size)
	var cells: Array[Vector2i] = []
	for dy: int in range(-reach, reach + 1):
		for dx: int in range(-reach, reach + 1):
			var cell := here + Vector2i(dx, dy)
			if Vector2(dx, dy).length() * nav.grid.cell_size <= COVER_RANGE and _open(nav, cell):
				cells.append(cell)
	cells.sort_custom(
		func(a: Vector2i, b: Vector2i) -> bool:
			return (a - here).length_squared() < (b - here).length_squared()
	)
	var near := brain.kart.global_position.distance_to(threat_at)
	var tried := 0
	for cell: Vector2i in cells:
		var at := nav.grid.cell_center(cell)
		if at.distance_to(threat_at) < near - 1.0:
			continue
		if _hidden(_eye(threat_at), _eye(at)):
			return at
		tried += 1
		if tried >= COVER_TRIES:
			break
	return Vector3.INF


## Whether a kart can stand in [param cell]: in the room, not a wall or a hole, and not a crate's,
## which a showdown's paths go through, see [Showdown], but no kart stands in.
func _open(nav: ArenaNav, cell: Vector2i) -> bool:
	if not nav.astar.is_in_boundsv(cell) or nav.is_blocked(cell):
		return false
	return nav.grid.rows[cell.y][cell.x] != ArenaGrid.CRATE


## Whether nothing of a kart standing at [param at] can be seen from [param eye]: its middle and
## either side of it.
func _hidden(eye: Vector3, at: Vector3) -> bool:
	var side := (at - eye).normalized().cross(Vector3.UP) * COVER_WIDTH
	for offset: Vector3 in [Vector3.ZERO, side, -side]:
		_ray.from = eye
		_ray.to = at + offset
		if _space().intersect_ray(_ray).is_empty():
			return false
	return true


## [param point] at the height bullets fly at.
static func _eye(point: Vector3) -> Vector3:
	return Vector3(point.x, BotBrain.BULLET_HEIGHT, point.z)


func _space() -> PhysicsDirectSpaceState3D:
	return brain.kart.get_world_3d().direct_space_state
