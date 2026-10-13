class_name Showdown
extends RefCounted
## A showdown, GAME.md 9.7a: the karts level on points at the end of a Grand Prix, on the Showdown
## map of 6.3, settling it the way a table settles a tie, by who is still there at the end. Sudden
## death from the flag, on a clock, with no money in the room and the same hand for everybody, and
## everybody not in it sitting it out. A match on that map is one, so a debug build's quick match
## on it is a showdown for the whole room.
##
## Kept out of [Match] the way [MatchEnd] is: what a showdown changes about a match, and the order
## it ends in.

## Seconds on the clock. A room that small with items in it is meant to be over well inside it.
const SECONDS := 120.0
## How many jokers every kart in it holds, all of them the same ones.
const HAND := 3
## The item with nothing to pull in a room with no money in it.
const LEFT_OUT_ITEM := &"chip_magnet"
## Which spawn point each kart in it takes, in the order they are in it: the corners across the
## diagonals first, so two karts start as far apart as the room allows, then the ones past them.
const SPAWN_ORDER: Array[int] = [0, 3, 1, 2, 4, 5, 6, 7]
## Seconds a broken crate stays broken: for good, so the cover wears away as the fight goes on.
const NEVER := 1.0e9


## Whether [param rules] are a showdown's.
static func is_on(rules: MatchRules) -> bool:
	return rules != null and rules.showdown()


## Dresses [param match_node] for a showdown before it starts, when its map is the showdown's: its
## rules a copy as a showdown plays them, and its items less the one with nothing to pull. On the
## host and a client alike, since a client keeps the numbers the host does not send.
static func dress(match_node: Match) -> void:
	if not is_on(match_node.rules):
		return
	match_node.rules = dressed(match_node.rules)
	if match_node.power_ups != null:
		match_node.power_ups = items(match_node.power_ups)


## [param rules] as a showdown plays them, a copy: nobody comes back, the clock runs out on a
## whistle rather than on sudden death, nobody banks anything, crates drop nothing and stay broken,
## and no bounty is called, no joker thrown onto the floor and none offered.
static func dressed(rules: MatchRules) -> MatchRules:
	var copy: MatchRules = rules.duplicate()
	copy.timed = true
	copy.duration = SECONDS
	# Never: the room is at the top from the flag, see [method Match.in_the_finale].
	copy.last_call_duration = -1.0
	copy.overtime = false
	copy.target_score = 1 << 30
	copy.offer_jokers = false
	copy.bounties = false
	copy.wild_joker_level = 1 << 20
	copy.crate_drop_min = 0
	copy.crate_drop_max = 0
	copy.crate_gold_chance = 0.0
	copy.crate_respawn = NEVER
	return copy


## [param table] less the item that pulls chips in, of which there are none.
static func items(table: PowerUpTable) -> PowerUpTable:
	var kept := PowerUpTable.new()
	for entry: PowerUp in table.entries:
		if entry.id != LEFT_OUT_ITEM:
			kept.entries.append(entry)
	return kept if not kept.entries.is_empty() else table


## Whether [param seat] is in the fight: every seat when the rules name none.
static func fights(rules: MatchRules, seat: int) -> bool:
	return rules.fighters.is_empty() or seat in rules.fighters


## Sets the karts out once they are on the floor, the host's or this machine's alone: each kart in
## the fight on a spawn point of its own, in the order of [constant SPAWN_ORDER], everybody else
## sitting it out, and the same hand dealt to all of them.
static func set_up(match_node: Match) -> void:
	if not is_on(match_node.rules):
		return
	var arena := match_node.arena
	var placed := 0
	for slot: PlayerSlot in match_node.slots:
		if not fights(match_node.rules, slot.index):
			sit_out(match_node, slot)
			continue
		var point := arena.spawn_points[SPAWN_ORDER[placed % SPAWN_ORDER.size()]]
		placed += 1
		slot.kart.global_position = point
		slot.kart.face(arena.junction_position - point)
	deal_hand(match_node)


## [param slot] sits the showdown out, GAME.md 9.7a: its kart is kept, so its seat is the seat the
## run knows it by, but it is not alive, not seen, not in anybody's way and never comes back, and
## the camera leaves it out.
static func sit_out(match_node: Match, slot: PlayerSlot) -> void:
	slot.benched = true
	var kart := slot.kart
	kart.alive = false
	kart.collision_layer = 0
	kart.collision_mask = 0
	kart.visible = false
	kart.enable_sound(false)
	if match_node.camera_rig != null:
		match_node.camera_rig.targets.erase(kart)


## Somebody sitting down in a seat nobody had, part way through a showdown, watches the rest of it:
## they were never level on points with anybody.
static func seat_joined(match_node: Match, slot: PlayerSlot) -> void:
	if is_on(match_node.rules):
		sit_out(match_node, slot)


## Three jokers dealt at random from the table's deck, the same three to every kart in the fight,
## GAME.md 9.7a: only those that do something in a fight, see [member Joker.fights].
static func deal_hand(match_node: Match) -> Array[Joker]:
	var pool: Array[Joker] = []
	for joker: Joker in match_node.joker_catalog.jokers:
		if joker.fights and match_node.joker_catalog.deals(joker):
			pool.append(joker)
	var hand: Array[Joker] = []
	while hand.size() < HAND and not pool.is_empty():
		hand.append(pool.pop_at(match_node.rng.randi_range(0, pool.size() - 1)))
	for slot: PlayerSlot in match_node.slots:
		if slot.benched or slot.kart == null:
			continue
		for joker: Joker in hand:
			if slot.kart.jokers.can_take(joker) and not slot.kart.jokers.is_full():
				slot.kart.jokers.add(joker)
	return hand


## [param slot] is out, GAME.md 9.7a: the moment it went, which ranks it under everybody who
## lasted longer. The physics tick, so karts that go out together are level on it.
static func went_out(match_node: Match, slot: PlayerSlot) -> void:
	if is_on(match_node.rules) and slot.out_at < 0:
		slot.out_at = Engine.get_physics_frames()


## The order a showdown stands in, best first, for [method Match.standings]: the karts still in by
## lives left, then the karts out, the last one out first, then everybody sitting it out. Karts out
## in the same moment go by kills, then seat.
static func ahead(a: PlayerSlot, b: PlayerSlot) -> bool:
	if a.benched != b.benched:
		return b.benched
	if a.out_at != b.out_at:
		if a.out_at < 0 or b.out_at < 0:
			return a.out_at < 0
		return a.out_at > b.out_at
	if a.out_at < 0 and _lives(a) != _lives(b):
		return _lives(a) > _lives(b)
	if a.kills != b.kills:
		return a.kills > b.kills
	return a.index < b.index


## How long each kart in the fight lasted, for the run to settle on, see
## [member GrandPrix.showdown]: the tick it went out on, or for a kart still standing as it ends,
## more than any of those and its lives on top.
static func lasted(match_node: Match) -> Dictionary[int, int]:
	var result: Dictionary[int, int] = {}
	for slot: PlayerSlot in match_node.slots:
		if slot.benched:
			continue
		result[slot.index] = slot.out_at if slot.out_at >= 0 else GrandPrix.STOOD + _lives(slot)
	return result


## The karts in the fight still in it.
static func left(match_node: Match) -> int:
	var count := 0
	for slot: PlayerSlot in match_node.slots:
		if not slot.benched and slot.out_at < 0:
			count += 1
	return count


static func _lives(slot: PlayerSlot) -> int:
	return slot.kart.lives if slot.kart != null and slot.kart.alive else 0
