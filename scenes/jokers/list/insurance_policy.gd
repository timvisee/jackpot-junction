extends Joker
## Insurance Policy: Bank 100% of your pot on death.


func modify_death(_kart: Kart, death: DeathOutcome) -> void:
	death.bank_fraction = 1.0
