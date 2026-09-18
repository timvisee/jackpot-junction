class_name JokerTick
extends RefCounted
## The jokers that do something of their own accord every tick rather than answering an event,
## GAME.md 7.3: the ones that pay a coin, climb the mult, or trickle a pot into the bank. Kept
## out of [Match] the way [MatchStats] is, so that file stays about running a match.
##
## Host-only, like everything that decides the score. A client is told what its pot and its
## banked total are in the snapshot, GAME.md 10.3, and a client that also paid itself would be
## corrected back down thirty times a second.


## One tick for every kart's jokers. Returns whether any of them banked points, which is worth
## knowing because banked points can end the match.
static func step(slots: Array[PlayerSlot], delta: float) -> bool:
	var paid := false
	for slot: PlayerSlot in slots:
		var kart := slot.kart
		if kart == null or not kart.is_active():
			continue
		var banked := 0
		for joker: Joker in kart.jokers.jokers:
			banked += joker.on_step(kart, delta)
		if banked > 0:
			slot.banked += banked
			Events.bank_tick.emit(slot.index, banked)
			paid = true
	return paid
