extends Joker
## Green Light: Turbo pads give +1 mult.


func on_turbo_pad(kart: Kart) -> void:
	kart.gain_mult(1.0, &"turbo")
