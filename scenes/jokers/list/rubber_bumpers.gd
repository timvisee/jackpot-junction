extends Joker
## Rubber Bumpers: your bullets bounce off walls once more, every copy: two copies bounce twice.


func modify_cannon_stats(stats: CannonStats) -> void:
	stats.bounces += 1


func stack_values(copies: int) -> Dictionary:
	return {"more": times(copies)}
