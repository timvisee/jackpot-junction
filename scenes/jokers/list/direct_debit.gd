extends Joker
## Direct Debit: five points of the pot bank themselves every second, wherever the kart is.
##
## The pot is the half of the score that can be taken off you, GAME.md 3.6, and the Junction is
## the only place to make it safe. This makes a little of it safe without going there, slowly
## enough that it is no substitute for a cash-out. It takes value and leaves the mult alone, so
## a streak keeps building while the coins it was built on drain away. A stack banks five points
## more a second for every copy.

## Points of pot value banked per second.
const RATE := 5.0

## The part of a point already drained but not yet worth banking.
var _carry := 0.0


func on_step(kart: Kart, delta: float) -> int:
	var copies := stacked()
	if copies <= 0 or kart.pot.is_empty():
		return 0
	_carry += kart.pot.drain(RATE * copies * delta)
	var points := floori(_carry)
	_carry -= float(points)
	return points


func banks_on_step() -> bool:
	return true


func stack_values(copies: int) -> Dictionary:
	return {"points": "%d" % roundi(RATE * copies)}
