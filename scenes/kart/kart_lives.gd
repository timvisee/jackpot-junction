class_name KartLives
extends RefCounted
## How many lives a kart has and whether they come back, GAME.md 3.6: the rules' own, and whatever
## its jokers add, see [method Joker.extra_lives]. Kept apart from the kart itself so that file
## stays about driving. A joker that adds a life brings it with it: picked up alive, the kart has
## that life at once, rather than finding itself wounded by a card meant to help.


## The most lives [param kart] has.
static func most(kart: Kart) -> int:
	var lives := kart.rules.lives
	for joker: Joker in kart.jokers.in_play:
		lives += joker.extra_lives()
	return lives


## Whether anything may patch [param kart] up while it lives, see [method Joker.blocks_healing].
static func healable(kart: Kart) -> bool:
	for joker: Joker in kart.jokers.in_play:
		if joker.blocks_healing():
			return false
	return true


## [param kart]'s hand has changed, the most lives it had [param before]: the lives a card brings
## come or go with it while the kart lives, and never down to none. An Understudy brings the
## lives of the card it copies, GAME.md 7.3.
static func follow(kart: Kart, before: int) -> void:
	if kart == null or not kart.alive:
		return
	var now := most(kart)
	if now != before:
		kart.lives = clampi(kart.lives + now - before, 1, now)


## Whether [param bullet] gets through [param kart]'s moment of grace after a wound, GAME.md 3.6:
## its shooter holding Double Tap, and as much of the grace gone as the shooter's bullets wait out,
## 7.3. Never through spawn protection, nor into a kart that is not there to be hit.
static func tapped(kart: Kart, bullet: Bullet) -> bool:
	if not kart.alive or kart.falling or kart.coasting or kart.protection_left > 0.0:
		return false
	if kart.hurt_left <= 0.0 or bullet.owner_slot == kart.slot:
		return false
	var shooter := Kart.of_slot(kart.get_tree(), bullet.owner_slot)
	if shooter == null:
		return false
	var share := 1.0
	for joker: Joker in shooter.jokers.in_play:
		share = joker.modify_wound_grace(share)
	var grace := kart.rules.hurt_protection
	return share < 1.0 and grace - kart.hurt_left >= grace * share


## Whether a hit about to cost [param kart] a life, by [param cause], is taken by one of its jokers
## instead, see [method Joker.spares].
static func spared(kart: Kart, cause: StringName) -> bool:
	for joker: Joker in kart.jokers.in_play:
		if joker.spares(kart, cause):
			return true
	return false


## What [param kart]'s death takes with it out of its hand, before anything is dropped: never on the
## floor, see [method Joker.lost_on_death].
static func lose_on_death(kart: Kart) -> void:
	for joker: Joker in kart.jokers.jokers.duplicate():
		if joker.lost_on_death():
			joker.used_up(kart, "LOST")
			kart.jokers.remove(joker)
