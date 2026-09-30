extends Joker
## Scar Tissue: One more life, GAME.md 3.6, but nothing patches it up while it lives: neither the
## Junction nor a kill heals it, and only coming back brings its lives back.


func extra_lives() -> int:
	return 1


func blocks_healing() -> bool:
	return true
