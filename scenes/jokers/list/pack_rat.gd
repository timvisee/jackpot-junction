extends Joker
## Pack Rat: room to carry one more item in reserve per copy, GAME.md 7.3. A kart holding one may
## take an extra from a box and queue it; it comes up as the one in hand is used. Its presence is
## read off the hand by [KartItems], so it needs no hook of its own, only the words on its card.

const SLOTS := 1


func stack_values(copies: int) -> Dictionary:
	return {"items": "+%d" % (SLOTS * copies)}
