extends Joker
## Deep Pockets: room for two more jokers, one of which it is standing in, every copy.

const SLOTS := 2


func modify_joker_slots(count: int) -> int:
	return count + SLOTS


func stack_values(copies: int) -> Dictionary:
	return {"slots": "+%d" % (SLOTS * copies)}
