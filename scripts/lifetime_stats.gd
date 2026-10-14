class_name LifetimeStats
extends RefCounted
## A profile's statistics over every match it has played, GAME.md 8.5: every count the results
## screen keeps, added up, see [PlayerStats]; the best of the few that are a best rather than a
## count; the kills; and how many maps and Grand Prix runs were played and won, and for how long.
## Only a match played to the whistle counts as a map: leaving before it counts for nothing. The
## driving school is no match either, but what is done in it counts, see [method add_play]; the
## Garage and the lobby count nothing.

## Kept as the best a single match reached rather than added up.
const PEAKS: Array[StringName] = [
	&"biggest_bank", &"max_mult", &"best_banked", &"longest_drift", &"best_streak", &"biggest_pot"
]
## The kills and the seconds in a share, see [method share_of], beside the slot's own counts.
const SHARE_KILLS := &"_kills"
const SHARE_SECONDS := &"_seconds"

## The Statistics page, GAME.md 8.5: its groups, each a title and its lines, each line what it is
## called and the statistic it reads, see [method value_of].
const GROUPS: Array[Array] = [
	[
		"Games",
		[
			["Maps played", &"maps"],
			["Maps won", &"maps_won"],
			["Grand Prix played", &"grand_prix"],
			["Grand Prix won", &"grand_prix_won"],
			["Time played", &"seconds"],
		],
	],
	[
		"Driving",
		[
			["Distance driven", &"driven"],
			["Distance drifted", &"drifted"],
			["Longest drift", &"longest_drift"],
			["Nitro burned", &"nitro"],
			["Turbo pads", &"turbo_pads"],
			["Drift boosts", &"drift_boosts"],
		],
	],
	[
		"Fighting",
		[
			["Kills", &"kills"],
			["Best kill streak", &"best_streak"],
			["Shots fired", &"bullets"],
			["Accuracy", &"accuracy"],
			["Near misses", &"grazes"],
			["Bullets shot down", &"parries"],
			["Rams", &"rams"],
			["Bomb kills", &"bomb_kills"],
			["Bounties collected", &"bounties"],
			["Lives patched up", &"lives_restored"],
			["Crates broken", &"crates"],
		],
	],
	[
		"Money",
		[
			["Chips picked up", &"coins"],
			["Chips out of the Jackpot", &"jackpot_chips"],
			["Cash-outs", &"banks"],
			["Biggest cash-out", &"biggest_bank"],
			["Most banked in a map", &"best_banked"],
			["Biggest pot carried", &"biggest_pot"],
			["Highest mult", &"max_mult"],
			["Match points", &"match_points"],
		],
	],
	[
		"Cards",
		[
			["Jokers taken", &"jokers"],
			["Power-ups used", &"items"],
			["Flush pads taken", &"pads_taken"],
			["Royal Flushes", &"flushes"],
		],
	],
	[
		"Mishaps",
		[
			["Deaths", &"deaths"],
			["Chips lost", &"coins_lost"],
			["Chips dropped", &"coins_dropped"],
			["Pit falls", &"pit_deaths"],
			["Own goals", &"self_kills"],
			["Spins on oil", &"oil_spins"],
		],
	],
]


## Adds one map played to the end by [param slot] to [param profile]: what was done in it, see
## [method add_play], and whether it won the map.
static func add_map(
	profile: Profile, slot: PlayerSlot, won: bool, seconds: float, since: Dictionary = {}
) -> void:
	add_play(profile, slot, seconds, since)
	_add(profile, &"maps", 1.0)
	_add(profile, &"maps_won", 1.0 if won else 0.0)


## Adds what [param slot] did to [param profile] without a map played: its counts, its bests, its
## kills and [param seconds] of play. The driving school's, GAME.md 8.5, and every map's. Only what
## came after [param since], a share already counted or one somebody else had in the slot before,
## see [method share_of].
static func add_play(
	profile: Profile, slot: PlayerSlot, seconds: float, since: Dictionary = {}
) -> void:
	for key: StringName in PlayerStats.FIELDS:
		var value := slot.stats.value(key)
		if key in PEAKS:
			_peak(profile, key, value)
		else:
			_add(profile, key, value - float(since.get(key, 0.0)))
	_peak(profile, &"best_banked", float(slot.banked))
	_add(profile, &"kills", float(slot.kills) - float(since.get(SHARE_KILLS, 0.0)))
	_add(profile, &"seconds", seconds - float(since.get(SHARE_SECONDS, 0.0)))


## What [param slot] has done as it stands, [param seconds] into the room, for a later
## [method add_play] to count only what came after it.
static func share_of(slot: PlayerSlot, seconds: float) -> Dictionary:
	var share := {}
	for key: StringName in PlayerStats.FIELDS:
		share[key] = slot.stats.value(key)
	share[SHARE_KILLS] = float(slot.kills)
	share[SHARE_SECONDS] = seconds
	return share


## [param key] of [param profile]'s statistics as it will be once what [param slot] has done since
## [param since] is added, see [method add_play]: for the loyalty program to know a count reached in
## the middle of a map, GAME.md 8.9. A count only a whole map adds, maps played and won, is as kept.
static func live_value(
	profile: Profile, slot: PlayerSlot, key: StringName, since: Dictionary
) -> float:
	var kept := value_of(profile, key)
	if key == &"best_banked":
		return maxf(kept, float(slot.banked))
	if key in PEAKS:
		return maxf(kept, slot.stats.value(key))
	if key in PlayerStats.FIELDS:
		return kept + slot.stats.value(key) - float(since.get(key, 0.0))
	if key == &"kills":
		return kept + float(slot.kills) - float(since.get(SHARE_KILLS, 0.0))
	return kept


## Adds one Grand Prix run played to its last map to [param profile], and whether it was won.
static func add_grand_prix(profile: Profile, won: bool) -> void:
	_add(profile, &"grand_prix", 1.0)
	_add(profile, &"grand_prix_won", 1.0 if won else 0.0)


## [param key] of [param profile]'s statistics as the page shows it.
static func shown(profile: Profile, key: StringName) -> String:
	var value := value_of(profile, key)
	match key:
		&"driven", &"drifted":
			return "%.1f km" % (value / 1000.0)
		&"seconds":
			var minutes := roundi(value / 60.0)
			return (
				"%d h %02d min" % [minutes / 60, minutes % 60]
				if minutes >= 60
				else "%d min" % minutes
			)
		&"nitro":
			return "%d s" % roundi(value)
		&"longest_drift":
			return "%.1f s" % value
		&"accuracy":
			return "%d%%" % roundi(value) if value >= 0.0 else "-"
		&"max_mult":
			return "×%s" % String.num(value, 1)
	return str(roundi(value))


## [param key] of [param profile]'s statistics, worked out where it is not counted: accuracy is the
## share of shots that landed, below zero before there are enough to say.
static func value_of(profile: Profile, key: StringName) -> float:
	if key == &"accuracy":
		var shots := float(profile.stats.get(&"bullets", 0.0))
		if shots < PlayerStats.ACCURACY_SHOTS:
			return -1.0
		return float(profile.stats.get(&"hits", 0.0)) / shots * 100.0
	return float(profile.stats.get(key, 0.0))


static func _add(profile: Profile, key: StringName, amount: float) -> void:
	profile.stats[key] = float(profile.stats.get(key, 0.0)) + amount


static func _peak(profile: Profile, key: StringName, value: float) -> void:
	profile.stats[key] = maxf(float(profile.stats.get(key, 0.0)), value)
