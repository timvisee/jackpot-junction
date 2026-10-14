extends Joker
## Daredevil: a graze while the holder is wounded patches it up, GAME.md 7.3, unless something says
## nothing may, see [method KartLives.healable]: Scar Tissue still has the say.


func modify_graze_mult(kart: Kart, amount: float) -> float:
	if not kart.puppet and kart.is_wounded() and KartLives.healable(kart):
		kart.restore_life()
		went_off(kart, "PATCHED")
	return amount
