class_name KartLives
extends RefCounted
## How many lives a kart has and whether they come back, GAME.md 3.6: the rules' own, and whatever
## its jokers add, see [method Joker.extra_lives]. Kept apart from the kart itself so that file
## stays about driving. A joker that adds a life brings it with it: picked up alive, the kart has
## that life at once, rather than finding itself wounded by a card meant to help.


## The most lives [param kart] has.
static func most(kart: Kart) -> int:
	var lives := kart.rules.lives
	for joker: Joker in kart.jokers.jokers:
		lives += joker.extra_lives()
	return lives


## Whether anything may patch [param kart] up while it lives, see [method Joker.blocks_healing].
static func healable(kart: Kart) -> bool:
	for joker: Joker in kart.jokers.jokers:
		if joker.blocks_healing():
			return false
	return true


## [param joker] has come into [param kart]'s hand, or gone out of it: the lives it brings come or
## go with it while the kart lives, and never down to none.
static func follow(kart: Kart, joker: Joker, joined: bool) -> void:
	if kart == null or not kart.alive or joker.extra_lives() == 0:
		return
	var change := joker.extra_lives() if joined else -joker.extra_lives()
	kart.lives = clampi(kart.lives + change, 1, most(kart))


## Whether a hit about to cost [param kart] a life, by [param cause], is taken by one of its jokers
## instead, see [method Joker.spares].
static func spared(kart: Kart, cause: StringName) -> bool:
	for joker: Joker in kart.jokers.jokers:
		if joker.spares(kart, cause):
			return true
	return false


## What [param kart]'s death takes with it out of its hand, before anything is dropped: never on the
## floor, see [method Joker.lost_on_death].
static func lose_on_death(kart: Kart) -> void:
	for joker: Joker in kart.jokers.jokers.duplicate():
		if joker.lost_on_death():
			kart.jokers.remove(joker)
