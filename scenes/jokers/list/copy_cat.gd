extends Joker
## Copy Cat: one more copy of the card just before it in the hand, GAME.md 7.3, even past that
## card's most: a fourth Hair Trigger, a third Spare Tire. Only a card that stacks; after any other,
## or first in the hand, it does nothing. The copy is played by the hand, see [method
## JokerHolder._restack], and follows whichever card is just before it now.


func stands_in_for(before: Array[Joker]) -> Joker:
	if before.is_empty():
		return null
	var last: Joker = before.back()
	return last if last.stackable else null


## Its words, and in a hand the card it is copying, its name set apart as a stack's numbers are, or
## that it copies nothing.
func describe(copies := 1, mark := "%s", details := false) -> String:
	var said := super(copies, mark, details)
	if not in_hand:
		return said
	if standing_for == null:
		return said + " Copying nothing: the card before it does not stack."
	return said + " Copying %s." % (mark % standing_for.display_name)
