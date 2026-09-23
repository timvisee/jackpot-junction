class_name GrandPrix
extends RefCounted
## Play, GAME.md 9.7: a run of several maps with the same people in it, one after another.
##
## Dealt when the waiting room fills rather than when the lobby is left, so the maps are not known
## until everybody who is playing them is there. The host keeps it; every map is told which one of
## how many it is, so a client knows as well as the host whether a podium leads on or ends it.

## The maps in the order they are played.
var playlist: Array[StringName] = []
## Which of them is being played, counting from 0.
var round := 0
## How every seat nobody is sitting in drives, in seat order, dealt once at the start and kept
## for every map: the same bots all the way through, see [FixedTraits].
var bots: Array[BotTrait] = []


## A Grand Prix of [param rounds] maps, dealt with [param rng].
static func start(rounds: int, rng: RandomNumberGenerator) -> GrandPrix:
	var run := GrandPrix.new()
	run.playlist = deal(rounds, rng)
	return run


## The maps for a run of [param rounds]: every map once before any of them comes round again, and
## never the same one twice running, since the whole point of a run of maps is the change of room.
static func deal(rounds: int, rng: RandomNumberGenerator) -> Array[StringName]:
	var dealt: Array[StringName] = []
	var bag: Array[StringName] = []
	while dealt.size() < rounds:
		if bag.is_empty():
			bag = ArenaMaps.IDS.duplicate()
			for i: int in range(bag.size() - 1, 0, -1):
				var j := rng.randi_range(0, i)
				var held := bag[i]
				bag[i] = bag[j]
				bag[j] = held
			if not dealt.is_empty() and bag.size() > 1 and bag[0] == dealt[-1]:
				bag.append(bag.pop_front())
		dealt.append(bag.pop_front())
	return dealt


func current_map() -> StringName:
	return playlist[round]


## Whether the map being played is the last one.
func is_last() -> bool:
	return round >= playlist.size() - 1


## On to the next map. The last one stays the last.
func advance() -> void:
	round = mini(round + 1, playlist.size() - 1)


## Deals the bots for the whole run: [param seats] of them, the bots asked for and the seats kept
## for players at other machines, which drive as bots until they are taken and again if their
## player leaves. The bots are chosen once, here, and not again for the rest of it.
func deal_bots(table: BotTraitTable, seats: int, rng: RandomNumberGenerator) -> void:
	bots.clear()
	for i: int in seats:
		bots.append(table.pick(rng))


## The table a map's bots are drawn from: the ones dealt at the start, in seat order.
func bot_table(table: BotTraitTable) -> BotTraitTable:
	return FixedTraits.of(table if table != null else load("res://data/ai/traits.tres"), bots)


## Tells a match which map of how many it is, see [member MatchRules.round].
func label(rules: MatchRules) -> void:
	rules.round = round + 1
	rules.rounds = playlist.size()
