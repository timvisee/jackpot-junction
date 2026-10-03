class_name LifetimeStats
extends RefCounted
## A profile's statistics over every match it has played, GAME.md 8.5: every count the results
## screen keeps, added up, see [PlayerStats]; the best of the few that are a best rather than a
## count; the kills; and how many maps and Grand Prix runs were played and won, and for how long.
## Only a match played to the whistle counts: leaving before it counts for nothing, and the
## driving school, the Garage and the lobby are not matches.

## Kept as the best a single match reached rather than added up.
const PEAKS: Array[StringName] = [&"biggest_bank", &"max_mult", &"best_banked"]

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
			["Nitro burned", &"nitro"],
			["Turbo pads", &"turbo_pads"],
			["Drift boosts", &"drift_boosts"],
		],
	],
	[
		"Fighting",
		[
			["Kills", &"kills"],
			["Deaths", &"deaths"],
			["Shots fired", &"bullets"],
			["Accuracy", &"accuracy"],
			["Rams", &"rams"],
			["Bounties collected", &"bounties"],
		],
	],
	[
		"Money",
		[
			["Chips picked up", &"coins"],
			["Chips lost", &"coins_lost"],
			["Cash-outs", &"banks"],
			["Biggest cash-out", &"biggest_bank"],
			["Most banked in a map", &"best_banked"],
			["Highest mult", &"max_mult"],
			["Royal Flushes", &"flushes"],
		],
	],
]


## Adds one map played to the end by [param slot] to [param profile]: its counts, its bests, its
## kills, whether it won the map, and [param seconds] of play.
static func add_map(profile: Profile, slot: PlayerSlot, won: bool, seconds: float) -> void:
	for key: StringName in PlayerStats.FIELDS:
		var value := slot.stats.value(key)
		if key in PEAKS:
			_peak(profile, key, value)
		else:
			_add(profile, key, value)
	_peak(profile, &"best_banked", float(slot.banked))
	_add(profile, &"kills", float(slot.kills))
	_add(profile, &"maps", 1.0)
	_add(profile, &"maps_won", 1.0 if won else 0.0)
	_add(profile, &"seconds", seconds)


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
