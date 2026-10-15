extends Joker
## Lucky Charm: the holder's slot machine pulls pay a step better, GAME.md 3.15 and 7.3: a pair
## pays as three of a kind does, and three of a kind as three sevens. A Diamonds card, for a hand
## that lives on its chips.


func modify_slot_pays(kart: Kart, pays: int) -> int:
	var better := pays
	if pays == SlotPad.PAIR_PAY:
		better = SlotPad.THREE_PAY
	elif pays == SlotPad.THREE_PAY:
		better = SlotPad.SEVENS_PAY
	if better != pays:
		went_off(kart, "LUCKY")
	return better


func went_off_words(times: int) -> String:
	return "Sweetened a pull once" if times == 1 else "Sweetened %d pulls" % times
