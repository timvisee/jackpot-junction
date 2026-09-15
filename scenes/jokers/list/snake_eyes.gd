extends Joker
## Snake Eyes: Start every life with mult 3, but grazes give nothing.


func on_respawn(kart: Kart) -> void:
	kart.pot.mult = maxf(kart.pot.mult, 3.0)


func modify_graze_mult(_kart: Kart, _amount: float) -> float:
	return 0.0
