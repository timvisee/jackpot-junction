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


## One joker of [param min_rarity] or better, weighted as usual within what is left. Used by the
## table throwing cards onto the floor once the room is hot, GAME.md 3.11: nothing common comes
## out that way.
func quality(rng: RandomNumberGenerator, min_rarity: int) -> Joker:
	var pool: Array[Joker] = []
	var weights: PackedFloat32Array = []
	for joker: Joker in jokers:
		if joker.rarity >= min_rarity:
			pool.append(joker)
			weights.append(joker.weight())
	return pool[rng.rand_weighted(weights)] if not pool.is_empty() else null


func offer(rng: RandomNumberGenerator, count: int, exclude: Array[StringName]) -> Array[Joker]:
	var pool: Array[Joker] = []
	for joker: Joker in jokers:
		if joker.room_for(exclude.count(joker.id)):
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
