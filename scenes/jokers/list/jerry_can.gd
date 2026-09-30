extends Joker
## Jerry Can: the nitro tank refills four times as fast, and twice as fast again for every copy
## past the first.
##
## Nitro is scarce on purpose, GAME.md 4.1: ninety seconds for a full tank, so a match is a few
## boosts and a decision about when to spend them. This turns that into a tool a player can
## reach for, and it stacks with the hot table and with standing on the Junction.


static func factor(copies: int) -> int:
	return 2 + 2 * copies


func modify_kart_stats(stats: KartStats) -> void:
	var copies := stacked()
	if copies > 0:
		stats.nitro_recharge_seconds /= float(factor(copies))


func stack_values(copies: int) -> Dictionary:
	return {"times": "%dx" % factor(copies)}
