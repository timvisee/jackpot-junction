extends Joker
## Carbon Copy: When your death drops a joker, a copy goes on the floor and the card stays in your
## hand, GAME.md 7.3, Carbon Copy itself among them. A card thrown away from the hand is thrown
## away all the same.


func copies_drops() -> bool:
	return true


func went_off_words(times: int) -> String:
	return "Copied your cards once" if times == 1 else "Copied your cards %d times" % times
