class_name Pot
extends RefCounted
## A kart's unbanked winnings: coins times mult, GAME.md 3.1. Draining at the Junction removes
## value continuously; the coin count shown is the ceiling of what is left, and mult is untouched
## until the pot is empty.

signal changed

var coins := 0
var mult := 1.0

## Part of the top coin that has already been drained, 0 <= _partial < mult.
var _partial := 0.0


## How far into the top coin a cash-out has got, for a client to show the same number as the
## host, GAME.md 10.3. A pot mid-drain is worth less than its coins times its mult, and that is
## exactly the moment everybody is watching it.
func partial() -> float:
	return _partial


func set_partial(amount: float) -> void:
	_partial = amount


func value() -> int:
	return floori(exact_value())


func exact_value() -> float:
	return maxf(coins * mult - _partial, 0.0)


func is_empty() -> bool:
	return coins <= 0


func add_coins(amount: int) -> void:
	coins += amount
	changed.emit()


## Takes up to [param amount] coins out of the pot, its mult left alone, and returns how many: a bet
## at the slot machine, GAME.md 3.15.
func take_coins(amount: int) -> int:
	var taken := clampi(amount, 0, coins)
	if taken > 0:
		coins -= taken
		_partial = minf(_partial, coins * mult)
		changed.emit()
	return taken


func add_mult(amount: float) -> void:
	mult += amount
	changed.emit()


func reset() -> void:
	coins = 0
	mult = 1.0
	_partial = 0.0
	changed.emit()


## Removes up to [param points] of value and returns how much was taken.
func drain(points: float) -> float:
	var total := exact_value()
	var taken := clampf(points, 0.0, total)
	var remaining := total - taken
	if remaining <= 0.0001:
		coins = 0
		_partial = 0.0
	else:
		coins = ceili(remaining / mult - 0.000001)
		_partial = maxf(coins * mult - remaining, 0.0)
	changed.emit()
	return taken
