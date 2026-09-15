extends Joker
## High Roller: All mult gains are doubled, but death banks 0%.


func modify_mult_gain(_kart: Kart, amount: float, _reason: StringName) -> float:
	return amount * 2.0


func modify_death(_kart: Kart, death: DeathOutcome) -> void:
	death.bank_fraction = 0.0
