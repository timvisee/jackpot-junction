class_name JokerCatalog
extends Resource
## Every joker in the game, and the draw for a respawn offer: weighted by rarity, without
## repeats, never one the player already holds.

@export var jokers: Array[Joker] = []


func by_id(id: StringName) -> Joker:
	for joker: Joker in jokers:
		if joker.id == id:
			return joker
	return null


func offer(rng: RandomNumberGenerator, count: int, exclude: Array[StringName]) -> Array[Joker]:
	var pool: Array[Joker] = []
	for joker: Joker in jokers:
		if joker.id not in exclude:
			pool.append(joker)
	var result: Array[Joker] = []
	while result.size() < count and not pool.is_empty():
		var weights: PackedFloat32Array = []
		for joker: Joker in pool:
			weights.append(joker.weight())
		var picked := pool[rng.rand_weighted(weights)]
		result.append(picked)
		pool.erase(picked)
	return result
