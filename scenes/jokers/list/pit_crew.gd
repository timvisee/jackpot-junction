extends Joker
## Pit Crew: a turbo pad puts half a tank of nitro back, and all of it with two, GAME.md 7.3, but
## not more often than once in three seconds: with Burnout every drift boost is a turbo pad, and a
## tank filled at every one of those would be a tank never empty, which nitro is not meant to be,
## GAME.md 4.1. A Clubs card, for a hand that drives.

## How much of a tank each copy puts back, and how long after one it waits before the next.
const SHARE := 0.5
const REST := 3.0

## Seconds until it fills the tank again.
var _resting := 0.0


func on_step(_kart: Kart, delta: float) -> int:
	_resting = maxf(_resting - delta, 0.0)
	return 0


func on_turbo_pad(kart: Kart) -> void:
	var copies := stacked()
	if copies <= 0 or kart.puppet or _resting > 0.0 or kart.nitro_charge >= 1.0:
		return
	_resting = REST
	kart.refill_nitro(SHARE * copies)
	went_off(kart, "PIT STOP")


func stack_values(copies: int) -> Dictionary:
	return {"share": "half" if copies <= 1 else "all"}


func went_off_words(times: int) -> String:
	return "Filled your tank once" if times == 1 else "Filled your tank %d times" % times
