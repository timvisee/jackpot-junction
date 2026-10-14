class_name TieWords
extends RefCounted
## What put a row in its place among the rows level with it, GAME.md 3.8 and 9.7a, for the chip a
## slip prints on it. A tie a showdown settled says where its row finished that; any other says
## which tie-break decided it and what the row had of it, so nobody is left to wonder why the row
## above theirs on the same score is above it.

const TIE := "Tie"
const SHOWDOWN := "Showdown"
## What is left when everything the order goes by is level, and the seats decide.
const SEATS := "seat order"


## The chip for [param slot] on a map's slip ranked as [param standings], a title and a value, or
## empty for a slot level with nobody on what it banked: the kills, then the deaths, the map's
## tie-breaks of 3.8.
static func of_map(slot: PlayerSlot, standings: Array[PlayerSlot]) -> PackedStringArray:
	var level: Array[PlayerSlot] = []
	for other: PlayerSlot in standings:
		if other.banked == slot.banked:
			level.append(other)
	if level.size() < 2:
		return PackedStringArray()
	if _alone(level, slot, func(other: PlayerSlot) -> int: return other.kills):
		return PackedStringArray([TIE, counted(slot.kills, "kill", "kills")])
	var same: Array[PlayerSlot] = []
	for other: PlayerSlot in level:
		if other.kills == slot.kills:
			same.append(other)
	if _alone(same, slot, func(other: PlayerSlot) -> int: return other.deaths):
		return PackedStringArray([TIE, counted(slot.deaths, "death", "deaths")])
	return PackedStringArray([TIE, SEATS])


## The chip for [param seat] on the standings of [param run] among [param slots], a title and a
## value, or empty for a seat level with nobody on points: where it finished the run's showdown,
## and for a tie the showdown could not settle, or one never played, maps won and then banked over
## the run, the order of 9.7.
static func of_run(seat: int, run: GrandPrix, slots: Array[PlayerSlot]) -> PackedStringArray:
	var level: Array[PlayerSlot] = []
	for slot: PlayerSlot in slots:
		if not run.points.has(slot.index) or run.total(slot.index) != run.total(seat):
			continue
		# A teammate shares the points and is no tie, GAME.md 3.14: the sides are.
		if slot.index != seat and run.side_of(slot.index) == run.side_of(seat):
			continue
		level.append(slot)
	if level.size() < 2:
		return PackedStringArray()
	var title := TIE
	var placed := ""
	if run.showdown.has(seat):
		title = SHOWDOWN
		placed = ordinal(run.showdown_place(seat, slots))
		var together: Array[PlayerSlot] = []
		for slot: PlayerSlot in level:
			if run.lasted_of(slot.index) == run.lasted_of(seat):
				together.append(slot)
		if together.size() < 2:
			return PackedStringArray([title, placed])
		level = together
		placed += " · "
	var me := _seat_in(level, seat)
	if _alone(level, me, func(slot: PlayerSlot) -> int: return run.wins(slot.index)):
		var won := run.wins(seat)
		return PackedStringArray([title, placed + counted(won, "map won", "maps won")])
	var same: Array[PlayerSlot] = []
	for slot: PlayerSlot in level:
		if run.wins(slot.index) == run.wins(seat):
			same.append(slot)
	var banked := func(slot: PlayerSlot) -> int: return run.side_banked_over(slot.index)
	if _alone(same, me, banked):
		var chips := Loyalty.thousands(run.side_banked_over(seat))
		return PackedStringArray([title, placed + "%s banked" % chips])
	return PackedStringArray([title, placed + SEATS])


## [param count] of a thing, said as [param one] or [param many].
static func counted(count: int, one: String, many: String) -> String:
	return "%d %s" % [count, one if count == 1 else many]


## A place said the way a slip says it: 1st, 2nd, 3rd, 4th.
static func ordinal(place: int) -> String:
	match place:
		1:
			return "1st"
		2:
			return "2nd"
		3:
			return "3rd"
	return "%dth" % place


## Whether [param slot] is the only one of [param among] with what [param measure] says of it.
static func _alone(among: Array[PlayerSlot], slot: PlayerSlot, measure: Callable) -> bool:
	var mine: int = measure.call(slot)
	for other: PlayerSlot in among:
		if other != slot and measure.call(other) == mine:
			return false
	return true


static func _seat_in(among: Array[PlayerSlot], seat: int) -> PlayerSlot:
	for slot: PlayerSlot in among:
		if slot.index == seat:
			return slot
	return null
