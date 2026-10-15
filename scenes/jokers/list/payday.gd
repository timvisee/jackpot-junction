extends Joker
## Payday: a coin every second, wherever you are and whatever you are doing, and one more for
## every copy past the first, all at once.

## Seconds between coins.
const INTERVAL := 1.0

var _left := INTERVAL


func on_step(kart: Kart, delta: float) -> int:
	var copies := stacked()
	if copies <= 0:
		return 0
	_left -= delta
	while _left <= 0.0:
		_left += INTERVAL
		kart.jokers.pay_chips(self, copies)
	return 0


func stack_values(copies: int) -> Dictionary:
	return {"coins": counted(copies, "chip", "chips")}
