extends Joker
## Green Light: Turbo pads give +1 mult, every copy, given at once.


func on_turbo_pad(kart: Kart) -> void:
	var copies := stacked()
	if copies > 0:
		kart.jokers.pay_mult(self, float(copies), &"turbo")


func stack_values(copies: int) -> Dictionary:
	return {"mult": "+%d" % copies}
