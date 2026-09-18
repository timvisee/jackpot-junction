extends Joker
## Hot Streak: the mult climbs on its own, half a point every ten seconds on the floor.
##
## Mult is the half of the pot that multiplies, so this compounds with everything else a player
## is doing rather than adding to it. A mult that has been left alone to climb for a minute is
## worth driving across the arena to shoot, which is the point.

## Seconds between gains.
const INTERVAL := 10.0
const AMOUNT := 0.5

var _left := INTERVAL


func on_step(kart: Kart, delta: float) -> int:
	_left -= delta
	while _left <= 0.0:
		_left += INTERVAL
		kart.gain_mult(AMOUNT, &"hot_streak")
	return 0
