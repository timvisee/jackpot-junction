extends Joker
## Royal Court: coming back with +1 mult for every Cursed joker held, GAME.md 7.3. Played after the
## curses' own terms, so a Snake Eyes hand comes back at mult 3 and adds to it, and High Roller
## doubles it as it doubles every gain.


func on_respawn(kart: Kart) -> void:
	if kart.puppet:
		return
	var cursed := 0
	for joker: Joker in kart.jokers.jokers:
		if joker.kind == Kind.CURSED:
			cursed += 1
	if cursed > 0:
		kart.jokers.pay_mult(self, float(cursed), &"royal_court")
		went_off(kart, Lang.later("%s MULT") % ("+%d" % cursed))


func went_off_words(times: int) -> String:
	return told(tr_n("Held court once", "Held court %d times", times), times)
