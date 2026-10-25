class_name RailgunPowerUp
extends PowerUp
## Railgun, GAME.md 5.3: the next few shots are fast bolts that run clean through karts and crates
## in a line, see [member CannonStats.pierce], and punch through one wall, not stopping on the first
## of anything. No homing: a straight, committed shot that rewards lining enemies up.

@export var shots := 5
@export var speed := 40.0
@export var cooldown := 0.7
@export var pierce := 3
@export var wall_pierce := 1
@export var lifetime := 2.0


func facts() -> Array[PackedStringArray]:
	return [
		fact("Shots", str(shots)),
		fact("Pierces", str(pierce)),
		fact("Speed", percent(speed / 17.0)),
	]


func activate(kart: Kart) -> void:
	var stats: CannonStats = kart.cannon_stats.duplicate()
	stats.kind = &"railgun"
	stats.pierce = pierce
	stats.wall_pierce = wall_pierce
	stats.bullet_speed = speed
	stats.fire_cooldown = cooldown
	stats.bullet_radius = 0.1
	stats.lifetime = lifetime
	stats.aim_assist = false
	stats.max_live_bullets = maxi(kart.cannon_stats.max_live_bullets, 2)
	kart.cannon.set_override(stats, shots)
