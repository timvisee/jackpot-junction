extends Joker
## Toll Booth: Whenever another kart completes a cash-out, you bank 5% of it.


func on_other_bank_completed(_kart: Kart, _other_slot: int, total: int) -> int:
	return floori(total * 0.05)
