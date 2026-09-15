extends Joker
## Green Light: Turbo pads give +0.5 mult.


func on_turbo_pad(kart: Kart) -> void:
	kart.gain_mult(0.5, &"turbo")
