extends Joker
## Loose Change, one of Kit's cards, STORY.md 6.3: the chips the kart drops never fade back to the
## House, and it drops half again as many. "What they don't pick up isn't theirs."

const MORE := 1.5


func modify_death(_kart: Kart, death: DeathOutcome) -> void:
	death.drop_fraction = minf(death.drop_fraction * MORE, 1.0)
	death.drop_max = ceili(float(death.drop_max) * MORE)
	death.chips_stay = true
