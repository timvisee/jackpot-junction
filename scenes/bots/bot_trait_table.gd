class_name BotTraitTable
extends Resource
## The traits bots can get, drawn by weight.

@export var entries: Array[BotTrait] = []


func pick(rng: RandomNumberGenerator) -> BotTrait:
	var weights: PackedFloat32Array = []
	for entry: BotTrait in entries:
		weights.append(maxf(entry.weight, 0.0))
	return entries[rng.rand_weighted(weights)]


func by_id(id: StringName) -> BotTrait:
	for entry: BotTrait in entries:
		if entry.id == id:
			return entry
	return null
