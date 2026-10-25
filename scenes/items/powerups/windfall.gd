class_name WindfallPowerUp
extends PowerUp
## Windfall, GAME.md 7.1: a lump of coins straight into your pot, larger the further behind you are,
## GAME.md 3.16. A trailing player's boxes lean toward it, so it is the catch-up player's find -- a
## pile of coins to close the gap with in one go.

@export var coins := 250


func facts() -> Array[PackedStringArray]:
	return [fact("Coins", "%d+" % coins)]


func activate(kart: Kart) -> void:
	# Scaled by the catch-up bonus the kart carries, GAME.md 3.16, so it pays a trailing player more.
	kart.collect_coins(int(round(coins * kart.coin_bonus)), null)
