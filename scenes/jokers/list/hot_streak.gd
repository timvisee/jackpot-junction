extends Joker
## Hot Streak: the mult climbs on its own, half a point every ten seconds on the floor.
##
## Mult is the half of the pot that multiplies, so this compounds with everything else a player
## is doing rather than adding to it. A mult that has been left alone to climb for a minute is
## worth driving across the arena to shoot, which is the point. A stack climbs by half a point
## more for every copy, at the same moments.

## Seconds between gains.
const INTERVAL := 10.0
const AMOUNT := 0.5

var _left := INTERVAL


func on_step(kart: Kart, delta: float) -> int:
	var copies := stacked()
	if copies <= 0:
		return 0
	_left -= delta
	while _left <= 0.0:
		_left += INTERVAL
		kart.jokers.pay_mult(self, AMOUNT * copies, &"hot_streak")
	return 0


func stack_values(copies: int) -> Dictionary:
	return {"mult": "+" + figure(AMOUNT * copies)}
