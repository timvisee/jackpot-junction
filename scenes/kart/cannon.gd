class_name Cannon
extends RefCounted
## Fires bullets for one kart: cooldown, live bullet limit and spread. The [BulletSystem] owns
## the bullets; the cannon only keeps track of which of its shots are still flying.

var stats: CannonStats
var cooldown_left := 0.0

var _live: Array[Bullet] = []


func _init(cannon_stats: CannonStats) -> void:
	stats = cannon_stats


func step(delta: float) -> void:
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	_prune()


func live_count() -> int:
	_prune()
	return _live.size()


func can_fire() -> bool:
	return cooldown_left <= 0.0 and live_count() < stats.max_live_bullets


## Spawns one shot's bullets from [param origin] along [param direction] and starts the cooldown.
func fire(
	system: BulletSystem, owner_slot: int, origin: Vector3, direction: Vector3, color: Color
) -> Array[Bullet]:
	cooldown_left = stats.fire_cooldown
	var count := maxi(stats.spread_count, 1)
	var bullets: Array[Bullet] = []
	for i: int in count:
		var angle := 0.0
		if count > 1:
			var half := deg_to_rad(stats.spread_angle_deg) * 0.5
			angle = lerpf(-half, half, float(i) / float(count - 1))
		var bullet := system.spawn(
			owner_slot, origin, direction.rotated(Vector3.UP, angle), stats, color
		)
		_live.append(bullet)
		bullets.append(bullet)
	return bullets


func _prune() -> void:
	var alive: Array[Bullet] = []
	for bullet: Bullet in _live:
		if is_instance_valid(bullet) and not bullet.is_dead():
			alive.append(bullet)
	_live = alive
