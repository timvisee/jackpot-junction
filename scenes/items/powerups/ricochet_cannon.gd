class_name RicochetCannonPowerUp
extends PowerUp
## Ricochet Cannon: the next shots bounce one extra time and fly faster.

@export var shots := 8
@export var extra_bounces := 1
@export var speed_multiplier := 1.25


func activate(kart: Kart) -> void:
	var stats: CannonStats = kart.cannon_stats.duplicate()
	stats.bounces += extra_bounces
	stats.bullet_speed *= speed_multiplier
	kart.cannon.set_override(stats, shots)
