extends Joker
## Odometer: a coin for every twenty meters driven.
##
## Measured the same way the results screen measures it, GAME.md 3.8: ground speed times the
## tick, so reversing counts and sitting still does not. A stack pays a coin more for every copy.

## Meters per coin.
const PER_COIN := 20.0

var _driven := 0.0


func on_step(kart: Kart, delta: float) -> int:
	var copies := stacked()
	if copies <= 0:
		return 0
	_driven += kart.motor.speed() * delta
	while _driven >= PER_COIN:
		_driven -= PER_COIN
		kart.collect_coins(copies, null)
	return 0


func stack_values(copies: int) -> Dictionary:
	return {"coins": counted(copies, "coin", "coins")}
