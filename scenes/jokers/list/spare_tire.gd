extends Joker
## Spare Tire: One more life, GAME.md 3.6, and patching up fills it too. The death that finally
## takes the last of them takes the tire with it, gone rather than dropped.


func extra_lives() -> int:
	return 1


func lost_on_death() -> bool:
	return true
