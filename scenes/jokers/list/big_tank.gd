extends Joker
## Big Tank: +1 max live bullet.


func modify_cannon_stats(stats: CannonStats) -> void:
	stats.max_live_bullets += 1
