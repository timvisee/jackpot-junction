extends Joker
## Flush Draw: two cards of a suit are enough to make the hand Suited in it, GAME.md 7.3.

const NEEDED := 2


func modify_suited(count: int) -> int:
	return mini(count, NEEDED)
