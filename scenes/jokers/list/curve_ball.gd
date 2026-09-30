extends Joker
## Curve Ball: bullets bend hard toward enemies, further out, and keep bending after a bounce.
## Set as floors rather than multipliers, so the joker works even with the assist setting at zero.
## A stack bends them faster, up to 300°/s with three: a turn short of a full circle in a second,
## and a bullet only ever bends toward an enemy in the cone ahead of it, so none goes round in one.

const CONE_DEG := 55.0
const RANGE := 22.0
const TURN_RATE_DEG := 150.0
## How much faster every copy past the first bends them.
const MORE_TURN_DEG := 75.0


static func turn_rate_deg(copies: int) -> float:
	return TURN_RATE_DEG + MORE_TURN_DEG * (copies - 1)


func modify_cannon_stats(stats: CannonStats) -> void:
	var copies := stacked()
	if copies <= 0:
		return
	stats.aim_assist = true
	stats.aim_assist_cone_deg = maxf(stats.aim_assist_cone_deg, CONE_DEG)
	stats.aim_assist_range = maxf(stats.aim_assist_range, RANGE)
	stats.aim_assist_turn_rate_deg = maxf(stats.aim_assist_turn_rate_deg, turn_rate_deg(copies))
	stats.assist_after_bounce = true


func stack_values(copies: int) -> Dictionary:
	return {"turn": "%d°" % roundi(turn_rate_deg(copies))}
