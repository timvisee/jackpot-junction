extends Joker
## Burnout: every drift carried to its boost counts as a turbo pad for the holder's jokers, GAME.md
## 7.3: Green Light pays for a drift, a driving hand's way into mult.


func on_drift_boost(kart: Kart) -> void:
	for joker: Joker in kart.jokers.in_play:
		if joker != self:
			joker.on_turbo_pad(kart)
