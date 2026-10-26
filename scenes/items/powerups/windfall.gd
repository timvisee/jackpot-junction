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
	var amount := int(round(coins * kart.coin_bonus))
	kart.collect_coins(amount, null)
	if Game.is_headless():
		return
	# The pile landing, GAME.md 7.1: a scatter of gold and the count floating up off the kart into
	# the pot climbing in the corner, so it is plain that coins went in and how many, see
	# [FloatingText] and [Burst].
	var at := kart.global_position
	Burst.spawn(kart.get_parent(), at + Vector3(0.0, 0.4, 0.0), Palette.CHIP_GOLD, 0.8, 18)
	FloatingText.spawn(kart.get_parent(), at, "+%d" % amount, Palette.CHIP_GOLD, 56, 1.4)
