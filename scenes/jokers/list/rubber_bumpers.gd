extends Joker
## Rubber Bumpers: your bullets bounce off walls once more. Stackable: two copies bounce twice.


func modify_cannon_stats(stats: CannonStats) -> void:
	stats.bounces += 1
