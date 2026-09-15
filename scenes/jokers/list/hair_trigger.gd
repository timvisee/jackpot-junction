extends Joker
## Hair Trigger: Fire cooldown -30%.


func modify_cannon_stats(stats: CannonStats) -> void:
	stats.fire_cooldown *= 0.7
