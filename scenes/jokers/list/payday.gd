extends Joker
## Payday: a coin every second, wherever you are and whatever you are doing.

## Seconds between coins.
const INTERVAL := 1.0

var _left := INTERVAL


func on_step(kart: Kart, delta: float) -> int:
	_left -= delta
	while _left <= 0.0:
		_left += INTERVAL
		kart.collect_coins(1, null)
	return 0
