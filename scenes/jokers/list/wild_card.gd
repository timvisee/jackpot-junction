extends Joker
## Wild Card: Respawn offers 5 jokers instead of 3, and two more for every copy past the first.
## Two at most, since seven is as many as the pick has room for on a phone.

## How many more every copy offers, on top of the match's three.
const MORE := 2


func modify_offer_count(count: int) -> int:
	return count + MORE


func stack_values(copies: int) -> Dictionary:
	return {"offers": "%d" % (3 + MORE * copies)}
