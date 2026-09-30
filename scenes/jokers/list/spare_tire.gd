extends Joker
## Spare Tire: One more life, GAME.md 3.6, and patching up fills it too. The death that finally
## takes the last of them takes the tire with it, gone rather than dropped. Every copy is a life
## of its own, and one death takes every tire.


func extra_lives() -> int:
	return 1


func lost_on_death() -> bool:
	return true


func stack_values(copies: int) -> Dictionary:
	return {"lives": "Two more lives" if copies == 2 else "One more life"}
