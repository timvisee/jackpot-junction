extends Joker
## Glass Jackpot: Completed cash-outs pay 150%, but dying drops all your chips and 2 jokers.


func modify_bank_payout(_kart: Kart, multiplier: float) -> float:
	return multiplier * 1.5


func modify_death(_kart: Kart, death: DeathOutcome) -> void:
	death.drop_fraction = 1.0
	death.drop_max = 999
	death.joker_drop_chance = 1.0
	death.joker_drop_count = 2
