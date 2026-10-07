class_name SpreadCannonPowerUp
extends PowerUp
## Spread Cannon: the next shots fire a fan of bullets.
##
## The live bullet limit counts bullets rather than trigger pulls, so it scales with the fan.
## Left alone, one fan of three would fill a three-bullet allowance and the cannon would
## refuse the next pull until that fan had expired.

@export var shots := 6
@export var bullets_per_shot := 3
@export var spread_angle_deg := 20.0


func facts() -> Array[PackedStringArray]:
	return [
		fact("Shots", str(shots)),
		fact("Bullets a shot", str(bullets_per_shot)),
		fact("Fan", "%s°" % Joker.figure(spread_angle_deg))
	]


func activate(kart: Kart) -> void:
	var stats: CannonStats = kart.cannon_stats.duplicate()
	stats.spread_count = bullets_per_shot
	stats.spread_angle_deg = spread_angle_deg
	stats.max_live_bullets = kart.cannon_stats.max_live_bullets * bullets_per_shot
	kart.cannon.set_override(stats, shots)
