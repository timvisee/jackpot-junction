extends Joker
## Tight Grip: Your pot never spills. A death drops none of its coins and a killer takes none of
## them, and a ram lived through knocks none out; what a death banks of the pot is still the
## usual share of it, all of it with Insurance Policy.


func modify_death(_kart: Kart, death: DeathOutcome) -> void:
	death.sealed = true


func modify_ram_knock(_kart: Kart, _fraction: float) -> float:
	return 0.0
