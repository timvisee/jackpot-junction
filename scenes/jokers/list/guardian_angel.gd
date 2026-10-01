extends Joker
## Guardian Angel: A hit about to cost you a life uses the Shield or the Bullet Wipe you hold to
## take it instead, GAME.md 7.3: the moment it lands rather than before, so the item is never spent
## on a shot that would have missed. A Shield takes any hit, going up and popping at once; a
## Bullet Wipe only a shot, which it wipes with every other bullet near you. An item still being
## rolled for, off a pad, is not in your hand yet.


func spares(kart: Kart, cause: StringName) -> bool:
	var item := kart.held_item
	if item == null or kart.item_reveal_left > 0.0:
		return false
	if item is ShieldPowerUp:
		kart.use_item()
		kart.pop_shield()
	elif item is BulletWipePowerUp and cause in [&"bullet", &"turret"]:
		kart.use_item()
	else:
		return false
	went_off(kart, "GUARDED")
	return true
