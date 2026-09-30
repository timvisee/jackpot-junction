extends Joker
## Toll Booth: Whenever another kart completes a cash-out, you bank 15% of it, and 10% more of it
## for every copy past the first.

const SHARE := 0.15
const MORE_SHARE := 0.10


static func share(copies: int) -> float:
	return SHARE + MORE_SHARE * (copies - 1)


func on_other_bank_completed(_kart: Kart, _other_slot: int, total: int) -> int:
	var copies := stacked()
	return floori(total * share(copies)) if copies > 0 else 0


func stack_values(copies: int) -> Dictionary:
	return {"share": "%d%%" % roundi(share(copies) * 100.0)}
