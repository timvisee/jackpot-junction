class_name SpreadCannonPowerUp
extends PowerUp
## Spread Cannon: the next shots fire a fan of bullets.

@export var shots := 6
@export var bullets_per_shot := 3
@export var spread_angle_deg := 20.0


func activate(kart: Kart) -> void:
	var stats: CannonStats = kart.cannon_stats.duplicate()
	stats.spread_count = bullets_per_shot
	stats.spread_angle_deg = spread_angle_deg
	kart.cannon.set_override(stats, shots)
