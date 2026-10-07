class_name GrandPrix
extends RefCounted
## Play, GAME.md 9.7: a run of several maps with the same people in it, one after another.
##
## Dealt when the waiting room fills rather than when the lobby is left, so the maps are not known
## until everybody who is playing them is there. The host keeps it; every map is told which one of
## how many it is, so a client knows as well as the host whether a podium leads on or ends it.
##
## Each map is won the way a single one is, on banked chips, and pays points by place. The run is
## won on points. A seat is somebody for the whole run -- the same people and bots sit in the same
## seats on every map -- so the points are kept by seat.

## What each seat takes on to the next map of its jokers, GAME.md 9.7.
enum Keep { NONE, CHOOSE, RANDOM, ALL }

## Points for each place on a map, first to last.
const POINTS: Array[int] = [10, 7, 5, 3, 2, 1]

## The maps in the order they are played.
var playlist: Array[StringName] = []
## Which of them is being played, counting from 0.
var round := 0
## How every seat nobody is sitting in drives, in seat order, dealt once at the start and kept
## for every map: the same bots all the way through, see [FixedTraits].
var bots: Array[BotTrait] = []
## And how each of them is dressed, GAME.md 4.4, in the same order.
var bot_styles: Array = []
## Seat to what that seat did on each map so far, in playlist order: the place it finished, the
## points that paid, and what it banked.
var places: Dictionary[int, Array] = {}
var points: Dictionary[int, Array] = {}
var banked: Dictionary[int, Array] = {}
## The last map whose result is in, so a result said twice is counted once.
var scored_round := -1
## Whether this screen has moved on from the last map's podium to the run's. Each machine's own:
## it says what is being looked at here, not how the run stands.
var revealed := false
## What every seat takes on to the next map of the jokers it ends a map holding.
var keep := Keep.RANDOM
## Seat to the jokers a player held at the end of the map before, for [enum Keep] CHOOSE: the ones
## they choose from as the next map starts, see [JokerKeep]. A bot, and a player with only one,
## keeps theirs there and then instead.
var choosing: Dictionary[int, Array] = {}
## Seat to the jokers it takes on to the map about to start, worked out as the run moves on.
var carried: Dictionary[int, Array] = {}


## A Grand Prix of [param rounds] maps, dealt with [param rng] from [param maps], every map when
## that is empty, carrying [param keeping] of its jokers from each map to the next.
static func start(
	rounds: int,
	rng: RandomNumberGenerator,
	keeping: Keep = Keep.RANDOM,
	maps: Array[StringName] = []
) -> GrandPrix:
	var run := GrandPrix.new()
	run.playlist = deal(rounds, rng, maps)
	run.keep = keeping
	return run


## The maps for a run of [param rounds] out of [param maps], every map when that is empty: every
## map once before any of them comes round again, and never the same room twice running, since the
## whole point of a run of maps is the change of room. A map and its XL are the same room.
static func deal(
	rounds: int, rng: RandomNumberGenerator, maps: Array[StringName] = []
) -> Array[StringName]:
	var dealt: Array[StringName] = []
	var bag: Array[StringName] = []
	while dealt.size() < rounds:
		if bag.is_empty():
			bag = (maps if not maps.is_empty() else ArenaMaps.pool(true, true)).duplicate()
			for i: int in range(bag.size() - 1, 0, -1):
				var j := rng.randi_range(0, i)
				var held := bag[i]
				bag[i] = bag[j]
				bag[j] = held
		dealt.append(bag.pop_at(_next_in(bag, dealt)))
	return dealt


## Which map of [param bag] comes out next: one in another room than the last dealt, and of the
## rooms left the one with the most maps still in the bag, so the end of it is never a map and its
## XL with nowhere else to go. Otherwise the first of the bag, which is shuffled.
static func _next_in(bag: Array[StringName], dealt: Array[StringName]) -> int:
	if dealt.is_empty():
		return 0
	var last := ArenaMaps.family(dealt[-1])
	var chosen := 0
	var most := 0
	for i: int in bag.size():
		var room := ArenaMaps.family(bag[i])
		if room == last:
			continue
		var left := bag.filter(func(id: StringName) -> bool: return ArenaMaps.family(id) == room)
		if left.size() > most:
			most = left.size()
			chosen = i
	return chosen


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
	bot_styles.clear()
	for i: int in seats:
		bots.append(table.pick(rng, bots))
		bot_styles.append(KartStyle.random(rng).to_array())


## The table a map's bots are drawn from: the ones dealt at the start, in seat order.
func bot_table(table: BotTraitTable) -> BotTraitTable:
	return FixedTraits.of(
		table if table != null else load("res://data/ai/traits.tres"), bots, bot_styles
	)


## Works out what every seat takes on to the next map from what it ends this one holding: nothing,
## one at random, all of it, or, for a player choosing, the jokers to choose from as the next map
## starts. A bot choosing keeps one at random, having nobody to choose for it, and a player with
## one joker keeps that one: a choice of one is not a choice.
func hold_over(slots: Array[PlayerSlot], rng: RandomNumberGenerator) -> void:
	carried.clear()
	choosing.clear()
	for slot: PlayerSlot in slots:
		var held: Array[StringName] = []
		if slot.kart != null:
			held = slot.kart.jokers.ids()
		var going: Array = []
		match keep:
			Keep.ALL:
				going.assign(held)
			Keep.CHOOSE, Keep.RANDOM:
				if keep == Keep.CHOOSE and slot.is_human() and held.size() > 1:
					choosing[slot.index] = held.duplicate()
				elif not held.is_empty():
					going.append(held[rng.randi_range(0, held.size() - 1)])
		carried[slot.index] = going


## Whether anybody starts the next map choosing which joker to keep.
func has_choices() -> bool:
	return not choosing.is_empty()


## Hands every seat of a map that has just started the jokers it carried on from the one before,
## and opens the pick for anybody who is to choose which of theirs to keep, see [JokerKeep]. A seat
## kept for a client is still a bot here; its pick waits for the client to sit down in it.
func deal_jokers(match_node: Match) -> void:
	for slot: PlayerSlot in match_node.slots:
		if slot.kart == null:
			continue
		for id: StringName in carried.get(slot.index, []):
			var joker := match_node.joker_catalog.by_id(id)
			if joker != null and not slot.kart.jokers.is_full():
				slot.kart.jokers.add(joker)
		var options: Array[Joker] = []
		for id: StringName in choosing.get(slot.index, []):
			var joker := match_node.joker_catalog.by_id(id)
			if joker != null:
				options.append(joker)
		if options.size() > 1:
			JokerKeep.open(slot, options)
		elif options.size() == 1 and not slot.kart.jokers.is_full():
			slot.kart.jokers.add(options[0])


## Tells a match which map of how many it is, see [member MatchRules.round].
func label(rules: MatchRules) -> void:
	rules.round = round + 1
	rules.rounds = playlist.size()
	rules.keep_jokers = keep


## Scores the map being played from its [param standings], best first. Once per map: the host says
## the match is over more than once, and a map is only worth its points the one time.
func score(standings: Array[PlayerSlot]) -> void:
	if scored_round >= round:
		return
	scored_round = round
	for place: int in standings.size():
		var seat := standings[place].index
		for record: Dictionary in [places, points, banked]:
			if not record.has(seat):
				record[seat] = []
		places[seat].append(place + 1)
		points[seat].append(POINTS[place] if place < POINTS.size() else 0)
		banked[seat].append(standings[place].banked)


## Points [param seat] has so far, or over the first [param maps] maps of the run.
func total(seat: int, maps := -1) -> int:
	var sum := 0
	for earned: int in _first(points, seat, maps):
		sum += earned
	return sum


## Maps [param seat] has won so far, or over the first [param maps] maps.
func wins(seat: int, maps := -1) -> int:
	return _first(places, seat, maps).count(1)


## [param slots] best first on points so far, or on the first [param maps] maps. Level on points,
## the one who won more maps is ahead, then the one who banked more over the whole run: a tie on
## points between a player who won a map and one who never did is not a tie anybody watching
## would call even.
func standings(slots: Array[PlayerSlot], maps := -1) -> Array[PlayerSlot]:
	var ranked := slots.duplicate()
	ranked.sort_custom(func(a: PlayerSlot, b: PlayerSlot) -> bool: return _ahead(a, b, maps))
	return ranked


## How many places [param seat] has gone up the standings on the last map scored: positive for up,
## negative for down, 0 for neither or when there is no map before it to have moved from.
func moved(seat: int, slots: Array[PlayerSlot]) -> int:
	var scored := scored_round + 1
	if scored < 2:
		return 0
	var now := _place_of(seat, standings(slots, scored))
	var before := _place_of(seat, standings(slots, scored - 1))
	return before - now


func _place_of(seat: int, ranked: Array[PlayerSlot]) -> int:
	for place: int in ranked.size():
		if ranked[place].index == seat:
			return place
	return ranked.size()


func _ahead(a: PlayerSlot, b: PlayerSlot, maps: int) -> bool:
	if total(a.index, maps) != total(b.index, maps):
		return total(a.index, maps) > total(b.index, maps)
	if wins(a.index, maps) != wins(b.index, maps):
		return wins(a.index, maps) > wins(b.index, maps)
	var a_banked := _banked(a.index, maps)
	var b_banked := _banked(b.index, maps)
	if a_banked != b_banked:
		return a_banked > b_banked
	return a.index < b.index


func _banked(seat: int, maps := -1) -> int:
	var sum := 0
	for chips: int in _first(banked, seat, maps):
		sum += chips
	return sum


## A seat's record for the first [param maps] maps of the run, or all of it for -1.
func _first(record: Dictionary[int, Array], seat: int, maps: int) -> Array:
	var all: Array = record.get(seat, [])
	return all if maps < 0 else all.slice(0, maps)


## The run as a client needs it for its podiums: the playlist, where it has got to, and the scores.
func to_wire() -> Dictionary:
	return {
		"playlist": playlist,
		"round": round,
		"scored": scored_round,
		"places": places,
		"points": points,
		"banked": banked,
	}


static func from_wire(data: Dictionary) -> GrandPrix:
	var run := GrandPrix.new()
	for id: Variant in data.get("playlist", []):
		run.playlist.append(StringName(id))
	run.round = int(data.get("round", 0))
	run.scored_round = int(data.get("scored", -1))
	for field: String in ["places", "points", "banked"]:
		var record: Dictionary[int, Array] = run.get(field)
		var sent: Dictionary = data.get(field, {})
		for seat: Variant in sent:
			record[int(seat)] = Array(sent[seat])
	return run
