extends Joker
## Comeback: Respawn with mult equal to half your mult at death, rounded up.

var _mult_at_death := 1.0


func on_death(kart: Kart) -> void:
	_mult_at_death = kart.pot.mult


func on_respawn(kart: Kart) -> void:
	kart.pot.mult = maxf(kart.pot.mult, ceilf(_mult_at_death * 0.5))
