extends Joker
## Insurance Policy: Bank all that is left of your pot on death. What spills onto the floor still
## spills, see Tight Grip for keeping it; the rest goes into the score whole rather than halved.


func modify_death(_kart: Kart, death: DeathOutcome) -> void:
	death.bank_fraction = 1.0


## A death with something in the pot banks all of it, which its card says, GAME.md 8.3. Here
## rather than in [method modify_death], which the whistle asks as well.
func on_death(kart: Kart) -> void:
	if not kart.pot.is_empty():
		went_off(kart, "INSURED")
