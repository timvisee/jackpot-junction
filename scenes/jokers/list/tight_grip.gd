extends Joker
## Tight Grip: Your pot never spills. A death drops none of its coins and a killer takes none of
## them, and a ram lived through knocks none out; what a death banks of the pot is still the
## usual share of it, all of it with Insurance Policy.


func modify_death(_kart: Kart, death: DeathOutcome) -> void:
	death.sealed = true


## A death or a ram with coins in the pot would have spilled some, and the card says it kept them,
## GAME.md 8.3. A ram is only asked about with coins in the pot.
func on_death(kart: Kart) -> void:
	if kart.pot.coins > 0:
		went_off(kart, "GRIPPED")


func modify_ram_knock(kart: Kart, fraction: float) -> float:
	if fraction > 0.0:
		went_off(kart, "GRIPPED")
	return 0.0


func went_off_words(times: int) -> String:
	return "Kept your pot shut once" if times == 1 else "Kept your pot shut %d times" % times
