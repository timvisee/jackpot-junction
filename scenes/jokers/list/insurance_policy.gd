extends Joker
## Insurance Policy: Bank 100% of your pot on death, and never drop any of it. The whole pot goes
## into the score and none of it onto the floor, and a ram lived through knocks nothing out of it.


func modify_death(_kart: Kart, death: DeathOutcome) -> void:
	death.bank_fraction = 1.0
	death.drop_fraction = 0.0


func modify_ram_knock(_kart: Kart, _fraction: float) -> float:
	return 0.0
