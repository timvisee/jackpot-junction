extends Joker
## Tailslide: a coin for every eight meters driven sideways.
##
## The same meters the results screen counts as drifted, GAME.md 3.8, and they come at a price:
## a drift is slower than a straight line and has to be held through a corner to be worth
## anything. So they are worth more than ordinary ones. A stack pays a coin more for every copy.

## Meters drifted per coin.
const PER_COIN := 8.0

var _drifted := 0.0


func on_step(kart: Kart, delta: float) -> int:
	var copies := stacked()
	if copies <= 0 or not kart.motor.drifting:
		return 0
	_drifted += kart.motor.speed() * delta
	while _drifted >= PER_COIN:
		_drifted -= PER_COIN
		kart.jokers.pay_chips(self, copies)
	return 0


func stack_values(copies: int) -> Dictionary:
	return {"coins": counted(copies, "chip", "chips")}
