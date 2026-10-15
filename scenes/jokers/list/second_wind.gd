extends Joker
## Second Wind: coming back fills the tank and sets a Boost running, GAME.md 7.3, the Boost of 7.1
## with its ram and all: a Hearts card's way into a drive.

const BOOST: PowerUp = preload("res://data/powerups/boost.tres")


func on_respawn(kart: Kart) -> void:
	if kart.puppet:
		return
	kart.refill_nitro(1.0)
	var running := kart.effects.size()
	BOOST.activate(kart)
	# Named as a Boost used is, so the HUD of 8.3 says what is running.
	for i: int in range(running, kart.effects.size()):
		kart.effects[i].display_name = BOOST.display_name
		kart.effects[i].color = BOOST.color
	went_off(kart, "REFUELED")


func went_off_words(times: int) -> String:
	return "Refueled you once" if times == 1 else "Refueled you %d times" % times
