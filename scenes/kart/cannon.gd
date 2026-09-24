class_name Cannon
extends RefCounted
## Fires bullets for one kart: cooldown, live bullet limit and spread. The [BulletSystem] owns
## the bullets; the cannon only keeps track of which of its shots are still flying. A cannon
## power-up can override the stats for a number of trigger pulls.

var stats: CannonStats
var cooldown_left := 0.0
## What the power-up that set the override was called, what color it is drawn in and how many
## shots it started with, so the HUD of 8.3 can say what is loaded without knowing what any one
## power-up does. Filled in by the kart as the item is played.
var override_name := ""
var override_color := Color.WHITE
var override_item := &""
var override_total := 0

var _live: Array[Bullet] = []
var _override: CannonStats
var _override_shots := 0


func _init(cannon_stats: CannonStats) -> void:
	stats = cannon_stats


func step(delta: float) -> void:
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	_prune()


func live_count() -> int:
	_prune()
	return _live.size()


func can_fire() -> bool:
	return cooldown_left <= 0.0 and live_count() < current_stats().max_live_bullets


## The stats in force: a cannon power-up's override while it has shots left, else the kart's own.
func current_stats() -> CannonStats:
	return _override if _override != null and _override_shots > 0 else stats


## Replaces the cannon's stats for the next [param shots] trigger pulls.
func set_override(override: CannonStats, shots: int) -> void:
	_override = override
	_override_shots = shots
	override_total = shots


func clear_override() -> void:
	_override = null
	_override_shots = 0
	override_name = ""
	override_item = &""
	override_total = 0


func override_shots_left() -> int:
	return _override_shots if _override != null else 0


## Spawns one shot's bullets from [param origin] along [param direction] and starts the cooldown.
func fire(
	system: BulletSystem,
	owner_slot: int,
	origin: Vector3,
	direction: Vector3,
	color: Color,
	from: Vector3 = Vector3.INF
) -> Array[Bullet]:
	var active := current_stats()
	cooldown_left = active.fire_cooldown
	var count := maxi(active.spread_count, 1)
	var bullets: Array[Bullet] = []
	for i: int in count:
		var angle := 0.0
		if count > 1:
			var half := deg_to_rad(active.spread_angle_deg) * 0.5
			angle = lerpf(-half, half, float(i) / float(count - 1))
		var bullet := system.spawn(
			owner_slot, origin, direction.rotated(Vector3.UP, angle), active, color, from
		)
		_live.append(bullet)
		bullets.append(bullet)
	if _override != null and _override_shots > 0:
		_override_shots -= 1
		if _override_shots == 0:
			_override = null
	return bullets


## The trigger pulled without a bullet, for a client predicting its own shot, GAME.md 10.3. The
## cannon goes on cooldown here and the bullet itself comes from the host: whether a shot lives
## depends on somebody else's bullet this machine only knows about a round trip late, so a
## predicted bullet would often be one that never was, and unfiring one is worse than waiting.
func pull_dry() -> void:
	var active := current_stats()
	cooldown_left = active.fire_cooldown
	if _override != null and _override_shots > 0:
		_override_shots -= 1
		if _override_shots == 0:
			_override = null


func _prune() -> void:
	var alive: Array[Bullet] = []
	for bullet: Bullet in _live:
		if is_instance_valid(bullet) and not bullet.is_dead():
			alive.append(bullet)
	_live = alive
