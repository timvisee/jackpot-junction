extends Joker
## Pickpocket: Kills move 50% of the victim's coins into your pot; the victim drops none.


func on_victim_death(_killer: Kart, _victim: Kart, death: DeathOutcome) -> void:
	death.steal_fraction = 0.5
	death.drop_fraction = 0.0
