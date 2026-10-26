class_name BoomerangPowerUp
extends PowerUp
## Boomerang, GAME.md 5.3: the next few shots fly out a way, then curve back to the kart that threw
## them, see [member CannonStats.returns], and may catch a kart on the way out and again on the way
## home. A shot that works the space behind a target as well as in front of one.

@export var shots := 5
@export var speed := 16.0
@export var cooldown := 0.55
@export var out_range := 8.0
@export var lifetime := 3.5


func facts() -> Array[PackedStringArray]:
	return [
		fact("Shots", str(shots)),
		fact("Range", meters(out_range)),
	]


func activate(kart: Kart) -> void:
	var stats: CannonStats = kart.cannon_stats.duplicate()
	stats.kind = &"boomerang"
	stats.returns = true
	stats.bullet_speed = speed
	stats.fire_cooldown = cooldown
	stats.bullet_radius = 0.2
	stats.lifetime = lifetime
	stats.aim_assist = false
	# How far it flies out before turning back; the bullet reads it from here, see
	# [method Bullet._return_step].
	stats.aim_assist_range = out_range
	stats.max_live_bullets = maxi(kart.cannon_stats.max_live_bullets, 2)
	kart.cannon.set_override(stats, shots)
