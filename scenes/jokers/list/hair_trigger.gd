extends Joker
## Hair Trigger: Fire cooldown -30%. A stack adds to how often the cannon fires rather than
## cutting the cooldown again and again: every copy is the same three shots in seven more.

## How much more often one copy fires: 3/7 more is the cooldown times 0.7.
const MORE_SHOTS := 3.0 / 7.0


static func cooldown(copies: int) -> float:
	return 1.0 / (1.0 + MORE_SHOTS * copies)


func modify_cannon_stats(stats: CannonStats) -> void:
	var copies := stacked()
	if copies > 0:
		stats.fire_cooldown *= cooldown(copies)


func stack_values(copies: int) -> Dictionary:
	return {"cut": "-%d%%" % roundi((1.0 - cooldown(copies)) * 100.0)}
