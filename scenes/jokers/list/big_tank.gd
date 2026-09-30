extends Joker
## Big Tank: +2 max live bullets, every copy.

const BULLETS := 2


func modify_cannon_stats(stats: CannonStats) -> void:
	stats.max_live_bullets += BULLETS


func stack_values(copies: int) -> Dictionary:
	return {"bullets": "+%d" % (BULLETS * copies)}
