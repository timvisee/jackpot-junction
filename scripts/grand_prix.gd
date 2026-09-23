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

## Points for each place on a map, first to last.
const POINTS: Array[int] = [10, 7, 5, 3, 2, 1]

## The maps in the order they are played.
var playlist: Array[StringName] = []
## Which of them is being played, counting from 0.
var round := 0
## How every seat nobody is sitting in drives, in seat order, dealt once at the start and kept
## for every map: the same bots all the way through, see [FixedTraits].
var bots: Array[BotTrait] = []
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


## Points [param seat] has so far.
func total(seat: int) -> int:
	var sum := 0
	for earned: int in points.get(seat, []):
		sum += earned
	return sum


## Maps [param seat] has won so far.
func wins(seat: int) -> int:
	return places.get(seat, []).count(1)


## [param slots] best first on points so far. Level on points, the one who won more maps is ahead,
## then the one who banked more over the whole run: a tie on points between a player who won a map
## and one who never did is not a tie anybody watching would call even.
func standings(slots: Array[PlayerSlot]) -> Array[PlayerSlot]:
	var ranked := slots.duplicate()
	ranked.sort_custom(_ahead)
	return ranked


func _ahead(a: PlayerSlot, b: PlayerSlot) -> bool:
	if total(a.index) != total(b.index):
		return total(a.index) > total(b.index)
	if wins(a.index) != wins(b.index):
		return wins(a.index) > wins(b.index)
	var a_banked := _banked(a.index)
	var b_banked := _banked(b.index)
	if a_banked != b_banked:
		return a_banked > b_banked
	return a.index < b.index


func _banked(seat: int) -> int:
	var sum := 0
	for chips: int in banked.get(seat, []):
		sum += chips
	return sum


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
