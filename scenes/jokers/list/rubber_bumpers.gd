extends Joker
## Rubber Bumpers: Your bullets bounce one extra time.


func modify_cannon_stats(stats: CannonStats) -> void:
	stats.bounces += 1
