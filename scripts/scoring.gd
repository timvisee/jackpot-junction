class_name Scoring
extends RefCounted
## Pure scoring maths from GAME.md 3.1, 3.4, 3.5 and 3.6. No scene nodes, so every function is
## unit tested against the tables in the design.

const LN2 := 0.6931471805599453


## Pot value: coins times mult, rounded down.
static func pot_value(coins: int, mult: float) -> int:
	return floori(coins * mult)


## Points banked when a kart dies with this pot.
static func death_bank(coins: int, mult: float, fraction: float) -> int:
	return floori(fraction * coins * mult)


## Chips scattered on the floor when a kart dies with this many coins.
static func death_drop(coins: int, fraction: float, max_drop: int) -> int:
	return mini(floori(fraction * coins), max_drop)


## Drain rate after [param t] seconds on the pad: r0 * 2^(t / d).
static func bank_rate(t: float, r0: float, d: float) -> float:
	return r0 * pow(2.0, t / d)


## Points drained between [param t0] and [param t1] seconds on the pad, in closed form.
static func banked_between(t0: float, t1: float, r0: float, d: float) -> float:
	return r0 * d / LN2 * (pow(2.0, t1 / d) - pow(2.0, t0 / d))


## Seconds on the pad needed to bank [param value] from a standing start.
static func time_to_bank(value: float, r0: float, d: float) -> float:
	return d * log(1.0 + value * LN2 / (r0 * d)) / LN2
