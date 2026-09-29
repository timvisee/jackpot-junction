extends Joker
## Insurance Policy: Bank all that is left of your pot on death. What spills onto the floor still
## spills, see Tight Grip for keeping it; the rest goes into the score whole rather than halved.


func modify_death(_kart: Kart, death: DeathOutcome) -> void:
	death.bank_fraction = 1.0
