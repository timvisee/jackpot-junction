class_name Teams
extends RefCounted
## Team play, GAME.md 3.14: the karts split into two, three or four sides, the suits of a deck,
## that bank into one score together and win or lose together. Whatever asks whether two karts are
## on one side asks here, so friendly fire, the aim, the bots and the scores all give one answer.
##
## A team is a number, its place in the suits' order; -1 is every kart for itself, which is how a
## match without teams plays and how anything owned by nobody, a pad no kart holds, stands.

## The suits in the order teams are dealt: two teams are Hearts and Spades.
const NAMES: Array[String] = ["Hearts", "Spades", "Diamonds", "Clubs"]
## Each suit's slot in the palette, GAME.md 8.1: Hearts red, Spades purple, Diamonds blue and Clubs
## green. Slots rather than colors, so a palette for color blindness, 8.5, changes them too.
const COLORS: Array[int] = [0, 4, 1, 3]
## How many teams a match may be split into, none first.
const COUNTS: Array[int] = [0, 2, 3, 4]


## The palette slot [param team] is painted in.
static func color_index(team: int) -> int:
	return COLORS[posmod(team, COLORS.size())]


static func color(team: int) -> Color:
	return Palette.player_color(color_index(team))


static func name_of(team: int) -> String:
	return NAMES[posmod(team, NAMES.size())]


## Whether [param a] and [param b] are one team. -1 is on nobody's side, its own included.
static func same(a: int, b: int) -> bool:
	return a >= 0 and a == b


## Whether what belongs to [param slot] on [param team] and what belongs to [param other_slot] on
## [param other_team] are on one side: one kart's own, its bullets, bomb, turret or decoy, or
## teammates'. Who may hurt, aim at, graze or contest whom, GAME.md 3.14.
static func allied(slot: int, team: int, other_slot: int, other_team: int) -> bool:
	return slot == other_slot or same(team, other_team)


## Whether [param kart] is spared what [param by_slot] on [param by_team] does to it, GAME.md 3.14:
## a teammate's shot, blast or ram, with friendly fire off. A kart's own are the lobby's rule for
## its own bullets, 3.8, and not this.
static func spares(by_slot: int, by_team: int, kart: Kart) -> bool:
	return not kart.rules.friendly_fire and by_slot != kart.slot and same(by_team, kart.team)


## The team of [param thing] on the floor: a kart's, a turret's or a bomb's, and -1 for whatever
## is nobody's, a box or a shooting target.
static func of(thing: Object) -> int:
	var team: Variant = thing.get("team")
	return team if team is int else -1


## Whether [param a] and [param b] are two karts of one team, rather than one kart.
static func teammates(a: PlayerSlot, b: PlayerSlot) -> bool:
	return a != b and same(a.team, b.team)


## How many of [param slots] are on each of [param count] teams.
static func sizes(slots: Array[PlayerSlot], count: int) -> Array[int]:
	var result: Array[int] = []
	result.resize(maxi(count, 0))
	result.fill(0)
	for slot: PlayerSlot in slots:
		if slot.team >= 0 and slot.team < result.size():
			result[slot.team] += 1
	return result


## The team with fewest karts in [param slots], the first of those tied in the suits' order, for
## somebody sitting down, GAME.md 3.14; -1 with teams off.
static func smallest(slots: Array[PlayerSlot], count: int) -> int:
	return _least(sizes(slots, count))


## How many karts the biggest team in [param slots] has, at least one: what a team's target is
## multiplied by, GAME.md 3.14.
static func biggest(slots: Array[PlayerSlot]) -> int:
	var most := 1
	for size: int in sizes(slots, COLORS.size()):
		most = maxi(most, size)
	return most


## A team for each of [param total] seats of a match split into [param count] teams, GAME.md 3.14.
## [param wanted] says which team some of them asked for, in seat order, -1 for none; everybody else
## is seated on the smallest team as they come, after everybody who asked. People come before bots
## in seat order, so the bots go to whatever teams are short.
static func deal(wanted: Array[int], count: int, total: int) -> Array[int]:
	var result: Array[int] = []
	result.resize(total)
	result.fill(-1)
	if count <= 0:
		return result
	var counted: Array[int] = []
	counted.resize(count)
	counted.fill(0)
	for i: int in mini(wanted.size(), total):
		if wanted[i] >= 0 and wanted[i] < count:
			result[i] = wanted[i]
			counted[wanted[i]] += 1
	for i: int in total:
		if result[i] < 0:
			result[i] = _least(counted)
			counted[result[i]] += 1
	return result


## The team [param slot] of [param slots] is seated on at the flag: [param dealt]'s, by its index,
## or the smallest of [param count] teams for a seat nobody dealt. -1 with teams off.
static func seat(slots: Array[PlayerSlot], dealt: Array[int], index: int, count: int) -> int:
	if count <= 0:
		return -1
	if index < dealt.size() and dealt[index] >= 0 and dealt[index] < count:
		return dealt[index]
	return smallest(slots, count)


## [param team]'s bank, GAME.md 3.14: what its karts banked between them.
static func bank(slots: Array[PlayerSlot], team: int) -> int:
	var total := 0
	for slot: PlayerSlot in slots:
		if slot.team == team:
			total += slot.banked
	return total


## The karts of [param slots] on [param team], in seat order.
static func members(slots: Array[PlayerSlot], team: int) -> Array[PlayerSlot]:
	var result: Array[PlayerSlot] = []
	for slot: PlayerSlot in slots:
		if slot.team == team:
			result.append(slot)
	return result


## The teams of [param slots] that have karts, ranked as the results rank them, GAME.md 3.14: the
## most banked, then the most kills between its karts, then the fewest deaths. Level all the way,
## the first in the suits' order.
static func standings(slots: Array[PlayerSlot]) -> Array[int]:
	var totals: Dictionary[int, Vector3i] = {}
	for slot: PlayerSlot in slots:
		if slot.team < 0:
			continue
		var was: Vector3i = totals.get(slot.team, Vector3i.ZERO)
		totals[slot.team] = was + Vector3i(slot.banked, slot.kills, slot.deaths)
	var ranked: Array[int] = []
	ranked.assign(totals.keys())
	ranked.sort_custom(
		func(a: int, b: int) -> bool:
			var left: Vector3i = totals[a]
			var right: Vector3i = totals[b]
			if left.x != right.x:
				return left.x > right.x
			if left.y != right.y:
				return left.y > right.y
			if left.z != right.z:
				return left.z < right.z
			return a < b
	)
	return ranked


## The index of the smallest of [param counted], the first of those tied; -1 for none.
static func _least(counted: Array[int]) -> int:
	var best := -1
	for i: int in counted.size():
		if best < 0 or counted[i] < counted[best]:
			best = i
	return best
