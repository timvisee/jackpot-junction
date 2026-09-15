extends Joker
## Slipstream: Grazes give +1 mult instead of +0.5.


func modify_graze_mult(_kart: Kart, amount: float) -> float:
	return 1.0 if amount > 0.0 else amount
