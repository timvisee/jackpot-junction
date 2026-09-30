extends Joker
## Aimbot: shots leave the barrel already turned part of the way toward the nearest enemy, so a
## near miss becomes a hit. The kart still has to point roughly the right way. A stack turns them
## further, up to 28° with three.

const AIM_DEG := 14.0
## How much further every copy past the first turns them.
const MORE_DEG := 7.0


static func aim_deg(copies: int) -> float:
	return AIM_DEG + MORE_DEG * (copies - 1)


func modify_cannon_stats(stats: CannonStats) -> void:
	var copies := stacked()
	if copies > 0:
		stats.auto_aim_deg = maxf(stats.auto_aim_deg, aim_deg(copies))


func stack_values(copies: int) -> Dictionary:
	return {"deg": "%d°" % roundi(aim_deg(copies))}
