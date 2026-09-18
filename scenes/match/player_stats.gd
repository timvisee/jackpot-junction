class_name PlayerStats
extends RefCounted
## What a kart got up to during a match, GAME.md 3.8: counted by the match and shown on the
## results screen as up to three awards per player, picked for how much they stand out from the
## others. Score and kills are always shown and live on the slot instead.

## Field order is the wire format for snapshots.
const FIELDS: Array[StringName] = [
	&"bullets",
	&"coins_lost",
	&"coins",
	&"jokers",
	&"driven",
	&"drifted",
	&"grazes",
	&"banks",
	&"biggest_bank",
	&"items",
	&"nitro",
	&"turbo_pads",
	&"max_mult",
	&"crates",
	&"targets",
	&"bomb_kills",
	&"flushes",
	&"bounties",
	&"lives_restored",
	&"pit_deaths",
	&"self_kills",
	&"deaths",
	&"jackpot_chips",
	&"drift_boosts",
	&"pads_taken",
	&"oil_spins",
]

## Award title and value format per field.
const AWARDS: Dictionary[StringName, Array] = {
	&"bullets": ["Trigger Happy", "%d shots fired"],
	&"coins_lost": ["Butterfingers", "%d coins lost"],
	&"coins": ["Vacuum Cleaner", "%d coins picked up"],
	&"jokers": ["Card Shark", "%d jokers taken"],
	&"driven": ["Road Warrior", "%.0f m driven"],
	&"drifted": ["Sideways Specialist", "%.0f m drifted"],
	&"grazes": ["Close Shave", "%d grazes"],
	&"banks": ["Regular Customer", "%d cash-outs"],
	&"biggest_bank": ["Big Spender", "%d in one cash-out"],
	&"items": ["Gadgeteer", "%d items used"],
	&"nitro": ["Nitro Junkie", "%.1f s of nitro"],
	&"turbo_pads": ["Pad Hopper", "%d turbo pads"],
	&"max_mult": ["Multiplier Maniac", "x%.1f peak mult"],
	&"crates": ["Demolition Crew", "%d crates broken"],
	&"targets": ["Sharpshooter", "%d targets knocked down"],
	&"bomb_kills": ["Pyrotechnician", "%d bomb kills"],
	&"flushes": ["Royal Flush", "%d flushes"],
	&"bounties": ["Bounty Hunter", "%d bounties collected"],
	&"lives_restored": ["Comeback Kid", "%d lives patched up"],
	&"pit_deaths": ["Spelunker", "%d pit falls"],
	&"self_kills": ["Own Goal", "%d self kills"],
	&"deaths": ["Crash Test Dummy", "%d deaths"],
	&"jackpot_chips": ["Vault Cracker", "%d chips out of the Jackpot"],
	&"drift_boosts": ["Power Slide", "%d drifts carried to the boost"],
	&"pads_taken": ["Card Counter", "%d flush pads taken"],
	&"oil_spins": ["Banana Skin", "%d spins on oil"],
}

var values: Dictionary[StringName, float] = {}


func _init() -> void:
	for field: StringName in FIELDS:
		values[field] = 0.0


func add(field: StringName, amount: float = 1.0) -> void:
	values[field] += amount


func peak(field: StringName, value: float) -> void:
	values[field] = maxf(values[field], value)


func value(field: StringName) -> float:
	return values[field]


## Packed rather than a plain array, for the wire. A generic array writes a type tag beside every
## number and these go out thirty times a second for every player: as floats in a packed array
## the same figures cost a third of what they did. Single precision is ample for a tally nobody
## reads to more than a decimal place.
func to_array() -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(FIELDS.size())
	for i: int in FIELDS.size():
		result[i] = values[FIELDS[i]]
	return result


func from_array(data: Variant) -> void:
	var packed: PackedFloat32Array = (
		data if data is PackedFloat32Array else PackedFloat32Array(data)
	)
	for i: int in mini(packed.size(), FIELDS.size()):
		values[FIELDS[i]] = packed[i]


## Up to [param count] awards for [param mine] among [param everyone], as [title, text] pairs.
## A stat is worth an award when it is above zero and stands out against the others: stats this
## player leads come first, ordered by how far ahead of the others' average they are; when there
## are not enough of those, the stats they come closest to leading fill the rest.
static func awards(mine: PlayerStats, everyone: Array[PlayerStats], count: int = 3) -> Array:
	var scored: Array = []
	for field: StringName in FIELDS:
		var value := mine.values[field]
		if value <= 0.0:
			continue
		var best_other := 0.0
		var total_others := 0.0
		var others := 0
		for other: PlayerStats in everyone:
			if other == mine:
				continue
			best_other = maxf(best_other, other.values[field])
			total_others += other.values[field]
			others += 1
		var mean_others := total_others / maxf(others, 1)
		var leads := others == 0 or value > best_other
		var standout := minf(value / maxf(mean_others, 0.001), 10.0)
		var score := standout if leads else 0.2 * value / maxf(best_other, 0.001)
		scored.append([score, field, value])
	scored.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var result: Array = []
	for entry: Array in scored.slice(0, count):
		var award: Array = AWARDS[entry[1]]
		result.append([award[0], award[1] % entry[2]])
	return result
