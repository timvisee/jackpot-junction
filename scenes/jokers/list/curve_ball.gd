extends Joker
## Curve Ball: bullets bend hard toward enemies, further out, and keep bending after a bounce.
## Set as floors rather than multipliers, so the joker works even with the assist setting at zero.

const CONE_DEG := 55.0
const RANGE := 22.0
const TURN_RATE_DEG := 150.0


func modify_cannon_stats(stats: CannonStats) -> void:
	stats.aim_assist = true
	stats.aim_assist_cone_deg = maxf(stats.aim_assist_cone_deg, CONE_DEG)
	stats.aim_assist_range = maxf(stats.aim_assist_range, RANGE)
	stats.aim_assist_turn_rate_deg = maxf(stats.aim_assist_turn_rate_deg, TURN_RATE_DEG)
	stats.assist_after_bounce = true
