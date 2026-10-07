class_name BotTraitTable
extends Resource
## The traits bots can get, drawn by weight.

@export var entries: Array[BotTrait] = []


## A trait drawn by weight from the ones dealt least among [param taken], the ways of driving the
## other bots in the room already have, GAME.md 9.1: each comes round once before any comes round
## twice, so a room of seven bots has every one of them and one again.
func pick(rng: RandomNumberGenerator, taken: Array[BotTrait] = []) -> BotTrait:
	var dealt: Array[int] = []
	for entry: BotTrait in entries:
		dealt.append(taken.count(entry))
	var fewest: int = dealt.min() if not dealt.is_empty() else 0
	var weights: PackedFloat32Array = []
	var total := 0.0
	for i: int in entries.size():
		weights.append(maxf(entries[i].weight, 0.0) if dealt[i] == fewest else 0.0)
		total += weights[i]
	if total <= 0.0:
		for i: int in entries.size():
			weights[i] = maxf(entries[i].weight, 0.0)
	return entries[rng.rand_weighted(weights)]


## How the bot just handed a trait by [method pick] dresses its kart, GAME.md 4.4: at random,
## unless the table says otherwise.
func dress(rng: RandomNumberGenerator) -> KartStyle:
	return KartStyle.random(rng)


## What the bot just handed a trait by [method pick] is called, GAME.md 3.8: a robot's name drawn
## from [param seed] that none of [param taken] has, unless the table says otherwise.
func bot_name(seed: int, taken: Array[String] = []) -> String:
	return PlayerNames.pick_bot(seed, taken)


func by_id(id: StringName) -> BotTrait:
	for entry: BotTrait in entries:
		if entry.id == id:
			return entry
	return null
