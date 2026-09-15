extends Joker
## Getaway Driver: Junction drain ramps twice as fast.


func modify_bank_doubling(_kart: Kart, doubling: float) -> float:
	return doubling * 0.5
