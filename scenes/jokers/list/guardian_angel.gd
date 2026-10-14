extends Joker
## Guardian Angel: A hit about to cost you a life uses the Shield or the Bullet Wipe you hold to
## take it instead, GAME.md 7.3: the moment it lands rather than before, so the item is never spent
## on a shot that would have missed. A Shield takes any hit, going up and popping at once; a
## Bullet Wipe only a shot, which it wipes with every other bullet near you. An item still being
## rolled for, off a pad, is not in your hand yet.


## Whether the item [param kart] has in hand is one this spends on a hit: a Shield or a Bullet
## Wipe, settled rather than still being rolled for.
static func spends_held(kart: Kart) -> bool:
	var item := kart.held_item
	if item == null or kart.item_reveal_left > 0.0:
		return false
	return item is ShieldPowerUp or item is BulletWipePowerUp


## Whether [param kart] holds this and an item it would spend, so the item it shows beside the kart
## is marked as going off by itself, see [ItemTag].
static func guards(kart: Kart) -> bool:
	return kart.jokers != null and kart.jokers.has(&"guardian_angel") and spends_held(kart)


func spares(kart: Kart, cause: StringName) -> bool:
	if not spends_held(kart):
		return false
	var item := kart.held_item
	if item is ShieldPowerUp:
		kart.use_item()
		kart.pop_shield()
	elif item is BulletWipePowerUp and cause in [&"bullet", &"turret"]:
		kart.use_item()
	else:
		return false
	went_off(kart, "GUARDED")
	return true


func went_off_words(times: int) -> String:
	return "Saved you once" if times == 1 else "Saved you %d times" % times
