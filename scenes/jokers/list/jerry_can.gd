extends Joker
## Jerry Can: the nitro tank refills four times as fast.
##
## Nitro is scarce on purpose, GAME.md 4.1: ninety seconds for a full tank, so a match is a few
## boosts and a decision about when to spend them. This turns that into a tool a player can
## reach for, and it stacks with the hot table and with standing on the Junction.


func modify_kart_stats(stats: KartStats) -> void:
	stats.nitro_recharge_seconds /= 4.0
