class_name PowerUpTable
extends Resource
## The set of power-ups a pad can hand out, drawn by weight.

@export var entries: Array[PowerUp] = []


## Draws one item by weight. With a [param bias] above zero, GAME.md 3.16, each item's weight is
## raised by that share of its [member PowerUp.power] above one, so a trailing player leans toward
## the heavy hitters, see [CatchUp].
func pick(rng: RandomNumberGenerator, bias := 0.0) -> PowerUp:
	var weights: PackedFloat32Array = []
	for entry: PowerUp in entries:
		var weight := maxf(entry.weight, 0.0)
		if bias > 0.0:
			weight *= maxf(1.0 + bias * (entry.power - 1.0), 0.0)
		weights.append(weight)
	return entries[rng.rand_weighted(weights)]
