extends Joker
## Aimbot: shots leave the barrel already turned part of the way toward the nearest enemy, so a
## near miss becomes a hit. The kart still has to point roughly the right way.

const AIM_DEG := 14.0


func modify_cannon_stats(stats: CannonStats) -> void:
	stats.auto_aim_deg = maxf(stats.auto_aim_deg, AIM_DEG)
