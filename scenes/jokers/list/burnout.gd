extends Joker
## Burnout: every drift carried to its boost counts as a turbo pad for the holder's jokers, GAME.md
## 7.3: Green Light pays for a drift, a driving hand's way into mult.


func on_drift_boost(kart: Kart) -> void:
	for joker: Joker in kart.jokers.in_play:
		if joker != self:
			joker.on_turbo_pad(kart)
	went_off(kart, "")


func went_off_words(times: int) -> String:
	return (
		"Made a turbo pad of a drift once" if times == 1 else "Made %d turbo pads of drifts" % times
	)
