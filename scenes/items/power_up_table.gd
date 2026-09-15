class_name PowerUpTable
extends Resource
## The set of power-ups a pad can hand out, drawn by weight.

@export var entries: Array[PowerUp] = []


func pick(rng: RandomNumberGenerator) -> PowerUp:
	var weights: PackedFloat32Array = []
	for entry: PowerUp in entries:
		weights.append(maxf(entry.weight, 0.0))
	return entries[rng.rand_weighted(weights)]
