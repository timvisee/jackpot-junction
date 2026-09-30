extends Joker
## Scar Tissue: One more life, GAME.md 3.6, but nothing patches it up while it lives: neither the
## Junction nor a kill heals it, and only coming back brings its lives back. Every copy is a
## life of its own.


func extra_lives() -> int:
	return 1


func blocks_healing() -> bool:
	return true


func stack_values(copies: int) -> Dictionary:
	return {"lives": "Two more lives" if copies == 2 else "One more life"}
