class_name JokerCatalog
extends Resource
## Every joker in the game, and the draw for a respawn offer: weighted by rarity, without
## repeats, never one the player already holds, and now and then one of the hand's own suit.

## How often a respawn offer deals one card from the suit the hand holds most of, GAME.md 7.3.
const LEAN := 0.5

@export var jokers: Array[Joker] = []
## The jokers a table deals, by id, GAME.md 8.9: offers and the floor's draws come from these alone,
## while every joker is still known by its id. Empty for all of them, as a catalog off the disk is.
var deck: Array[StringName] = []


## A catalog that knows every joker this one does and deals only [param ids].
func dealing(ids: Array[StringName]) -> JokerCatalog:
	var dealt := JokerCatalog.new()
	dealt.jokers = jokers
	dealt.deck = ids
	return dealt


## Whether [param joker] is one this catalog deals: never one of Kit's cards, which only the story
## deals, see [KitCards].
func deals(joker: Joker) -> bool:
	return not joker.contraband and (deck.is_empty() or joker.id in deck)


## The House's own cards, every joker but Kit's, STORY.md 6.3: what its catalog prints.
func printed() -> Array[Joker]:
	var house: Array[Joker] = []
	for joker: Joker in jokers:
		if not joker.contraband:
			house.append(joker)
	return house


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
		if joker.rarity >= min_rarity and deals(joker):
			pool.append(joker)
			weights.append(joker.weight())
	return pool[rng.rand_weighted(weights)] if not pool.is_empty() else null


## [param count] jokers for a hand holding [param exclude], weighted by rarity, without repeats.
## Half the time one of them is dealt from [param lean], the suit the hand holds most of, GAME.md
## 7.3, and goes in among the others anywhere; none for a lean of -1, nor from a suit with nothing
## left to deal.
func offer(
	rng: RandomNumberGenerator, count: int, exclude: Array[StringName], lean := -1
) -> Array[Joker]:
	var pool: Array[Joker] = []
	for joker: Joker in jokers:
		if joker.room_for(exclude.count(joker.id)) and deals(joker):
			pool.append(joker)
	var leaned: Joker = null
	if lean >= 0 and count > 0 and rng.randf() < LEAN:
		var suited := pool.filter(func(card: Joker) -> bool: return card.suit == lean)
		if not suited.is_empty():
			leaned = _weighted(rng, suited)
			pool.erase(leaned)
	var result: Array[Joker] = []
	var wanted := count - (1 if leaned != null else 0)
	while result.size() < wanted and not pool.is_empty():
		var picked := _weighted(rng, pool)
		result.append(picked)
		pool.erase(picked)
	if leaned != null:
		result.insert(rng.randi_range(0, result.size()), leaned)
	return result


static func _weighted(rng: RandomNumberGenerator, pool: Array) -> Joker:
	var weights: PackedFloat32Array = []
	for joker: Joker in pool:
		weights.append(joker.weight())
	return pool[rng.rand_weighted(weights)]
