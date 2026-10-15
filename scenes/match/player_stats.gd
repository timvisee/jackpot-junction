class_name PlayerStats
extends RefCounted
## What a kart got up to during a match, GAME.md 3.8: counted by the match and shown on the
## results screen as up to three awards per player, each earned by doing enough of a thing, and
## dealt in finishing order from the most interesting down, see [method deal]. Score and kills are
## always shown and live on the slot instead.

## How interesting an award is, GAME.md 3.8: a feat few manage, a thing done well, a thing done a
## lot, and a ribbing, which is dealt last and never to the winner.
enum Tier { RIBBING = 1, BUSY = 2, SKILL = 3, HEADLINE = 4 }
## A feat is anybody's who did it often enough; a contest only the one who did it most, the one
## placed higher where two are level.
enum Kind { FEAT, CONTEST }

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
	&"overtakes",
	&"hits",
	&"match_points",
	&"coins_dropped",
	&"rams",
	&"longest_drift",
	&"best_streak",
	&"parries",
	&"biggest_pot",
	&"suited_spades",
	&"suited_hearts",
	&"suited_diamonds",
	&"suited_clubs",
]
## Worked out from the others rather than counted, and so not on the wire: of the shots fired,
## how many landed on somebody, as a percentage.
const DERIVED: Array[StringName] = [&"accuracy"]
## Counted only for one of those, and no award of its own: a hit is a shot on target.
const BEHIND_DERIVED: Array[StringName] = [&"hits"]
## Counted for the Statistics page of GAME.md 8.5 alone, with no award of their own: the longest
## drift in seconds, the most kills in one life, bullets shot down, the biggest pot carried and how
## often the hand went Suited in each suit, GAME.md 7.3.
const RECORD_ONLY: Array[StringName] = [
	&"longest_drift",
	&"best_streak",
	&"parries",
	&"biggest_pot",
	&"suited_spades",
	&"suited_hearts",
	&"suited_diamonds",
	&"suited_clubs",
]
## How many shots a player has to have fired before their accuracy says anything. One lucky shot
## is not a marksman.
const ACCURACY_SHOTS := 10
## Stats that tell much the same story, of which a player is given at most one award: the coins in
## a pot at a death are most of the coins it drops there.
const SAME_STORY: Array[Array] = [[&"coins_lost", &"coins_dropped"]]

## Each award, by the field it is for: its title, what it says of one and of more, the least of it
## that earns it, its tier, a feat or a contest, and whether that least is a total, which grows and
## shrinks with how long the map ran, see [constant MINIMUMS_FOR], rather than a peak or a share.
const AWARDS: Dictionary[StringName, Array] = {
	&"bullets":
	["Trigger Happy", "%d shot fired", "%d shots fired", 80.0, Tier.BUSY, Kind.CONTEST, true],
	&"coins_lost":
	["Butterfingers", "%d chip lost", "%d chips lost", 300.0, Tier.RIBBING, Kind.CONTEST, true],
	&"coins":
	[
		"Vacuum Cleaner",
		"%d chip picked up",
		"%d chips picked up",
		500.0,
		Tier.BUSY,
		Kind.CONTEST,
		true
	],
	&"jokers":
	["Card Shark", "%d joker taken", "%d jokers taken", 8.0, Tier.BUSY, Kind.CONTEST, true],
	&"driven":
	["Road Warrior", "%.0f m driven", "%.0f m driven", 1200.0, Tier.BUSY, Kind.CONTEST, true],
	&"drifted":
	[
		"Sideways Specialist",
		"%.0f m drifted",
		"%.0f m drifted",
		150.0,
		Tier.SKILL,
		Kind.CONTEST,
		true
	],
	&"grazes": ["Close Shave", "%d graze", "%d grazes", 5.0, Tier.SKILL, Kind.CONTEST, true],
	&"banks":
	["Regular Customer", "%d cash-out", "%d cash-outs", 15.0, Tier.BUSY, Kind.CONTEST, true],
	&"biggest_bank":
	[
		"Big Spender",
		"%d in one cash-out",
		"%d in one cash-out",
		1000.0,
		Tier.HEADLINE,
		Kind.FEAT,
		false
	],
	&"items": ["Gadgeteer", "%d item used", "%d items used", 5.0, Tier.BUSY, Kind.CONTEST, true],
	&"nitro":
	["Nitro Junkie", "%.1f s of nitro", "%.1f s of nitro", 15.0, Tier.BUSY, Kind.CONTEST, true],
	&"turbo_pads":
	["Pad Hopper", "%d turbo pad", "%d turbo pads", 10.0, Tier.BUSY, Kind.CONTEST, true],
	&"max_mult":
	[
		"Multiplier Maniac",
		"x%.1f peak mult",
		"x%.1f peak mult",
		6.0,
		Tier.SKILL,
		Kind.CONTEST,
		false
	],
	&"crates":
	["Demolition Crew", "%d crate broken", "%d crates broken", 10.0, Tier.BUSY, Kind.CONTEST, true],
	&"targets":
	[
		"Sharpshooter",
		"%d target knocked down",
		"%d targets knocked down",
		3.0,
		Tier.HEADLINE,
		Kind.FEAT,
		false
	],
	&"bomb_kills":
	["Pyrotechnician", "%d bomb kill", "%d bomb kills", 2.0, Tier.HEADLINE, Kind.FEAT, false],
	&"flushes": ["Royal Flush", "%d flush", "%d flushes", 2.0, Tier.HEADLINE, Kind.FEAT, false],
	&"bounties":
	[
		"Bounty Hunter",
		"%d bounty collected",
		"%d bounties collected",
		2.0,
		Tier.HEADLINE,
		Kind.FEAT,
		false
	],
	&"lives_restored":
	[
		"Comeback Kid",
		"%d life patched up",
		"%d lives patched up",
		5.0,
		Tier.SKILL,
		Kind.CONTEST,
		true
	],
	&"pit_deaths":
	["Spelunker", "%d pit fall", "%d pit falls", 3.0, Tier.RIBBING, Kind.CONTEST, true],
	&"self_kills":
	["Own Goal", "%d self kill", "%d self kills", 1.0, Tier.RIBBING, Kind.CONTEST, false],
	&"deaths": ["Crash Test Dummy", "%d death", "%d deaths", 8.0, Tier.RIBBING, Kind.CONTEST, true],
	&"jackpot_chips":
	[
		"Vault Cracker",
		"%d chip out of the Jackpot",
		"%d chips out of the Jackpot",
		200.0,
		Tier.HEADLINE,
		Kind.FEAT,
		false
	],
	&"drift_boosts":
	[
		"Power Slide",
		"%d drift carried to the boost",
		"%d drifts carried to the boost",
		5.0,
		Tier.SKILL,
		Kind.CONTEST,
		true
	],
	&"pads_taken":
	[
		"Card Counter",
		"%d flush pad taken",
		"%d flush pads taken",
		25.0,
		Tier.SKILL,
		Kind.CONTEST,
		true
	],
	&"oil_spins":
	["Banana Skin", "%d spin on oil", "%d spins on oil", 3.0, Tier.RIBBING, Kind.CONTEST, true],
	&"overtakes":
	[
		"Last Word",
		"%d place taken in sudden death",
		"%d places taken in sudden death",
		1.0,
		Tier.HEADLINE,
		Kind.FEAT,
		false
	],
	&"match_points":
	[
		"Knocking on the Door",
		"%d match point",
		"%d match points",
		2.0,
		Tier.HEADLINE,
		Kind.FEAT,
		false
	],
	&"coins_dropped":
	["Piggy Bank", "%d chip dropped", "%d chips dropped", 80.0, Tier.RIBBING, Kind.CONTEST, true],
	&"rams":
	["Battering Ram", "%d player rammed", "%d players rammed", 3.0, Tier.SKILL, Kind.CONTEST, true],
	&"accuracy":
	[
		"Marksman",
		"%.0f%% of shots on target",
		"%.0f%% of shots on target",
		50.0,
		Tier.SKILL,
		Kind.CONTEST,
		false
	],
}
## Where each of those is kept in an award's entry.
const TITLE := 0
const SAID_ONE := 1
const SAID_MORE := 2
const LEAST := 3
const TIER := 4
const KIND := 5
const TOTAL := 6
## How long a map the least of a total is for, in seconds: a map half as long asks half as many
## shots of a Trigger Happy, and the most and least it is ever scaled by.
const MINIMUMS_FOR := 300.0
const SCALED_LEAST := 0.2
const SCALED_MOST := 4.0
## How many shots a Marksman has to have fired: a share of a few is luck.
const MARKSMAN_SHOTS := 15
## How much further than anybody else a Road Warrior has to have driven, since everybody drives.
const ROAD_LEAD := 1.2

var values: Dictionary[StringName, float] = {}


## The count of hands gone Suited in [param suit], one of [enum Joker.Suit] but wild.
static func suited_field(suit: int) -> StringName:
	return StringName("suited_%s" % JokerSuits.name_of(suit).to_lower())


func _init() -> void:
	for field: StringName in FIELDS:
		values[field] = 0.0


func add(field: StringName, amount: float = 1.0) -> void:
	values[field] += amount


func peak(field: StringName, value: float) -> void:
	values[field] = maxf(values[field], value)


func value(field: StringName) -> float:
	if field == &"accuracy":
		var fired := values[&"bullets"]
		return 100.0 * values[&"hits"] / fired if fired >= ACCURACY_SHOTS else 0.0
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


## The awards on a map's slip, GAME.md 3.8: for each of [param order], the players in their
## finishing order, up to [param count] [title, words] pairs, after a map of [param seconds]. Only
## what earns one is worth one: an award's least, see [constant AWARDS], a contest led, and a
## ribbing never the winner's. They are dealt in finishing order, the winner taking the most
## interesting of theirs, then the second, and round again, each title once on the slip, so a feat
## two players earned is the higher placed one's.
static func deal(order: Array[PlayerStats], seconds: float, count := 3) -> Array[Array]:
	var scale := clampf(seconds / MINIMUMS_FOR, SCALED_LEAST, SCALED_MOST) if seconds > 0.0 else 1.0
	var wanted: Array[Array] = []
	var dealt: Array[Array] = []
	var told: Array[Array] = []
	for place: int in order.size():
		wanted.append(_wanted(order, place, scale))
		dealt.append([])
		told.append([])
	var given: Array[StringName] = []
	for each_round: int in count:
		for place: int in order.size():
			for entry: Array in wanted[place]:
				var field: StringName = entry[1]
				var mine: Array[StringName] = []
				mine.assign(told[place])
				if field in given or _told_already(field, mine):
					continue
				given.append(field)
				told[place].append(field)
				dealt[place].append(said(field, float(entry[2])))
				break
	return dealt


## The [title, words] of the award for [param field] at [param value], one or more of it.
static func said(field: StringName, value: float) -> Array:
	var award: Array = AWARDS[field]
	var words: String = award[SAID_ONE] if is_equal_approx(value, 1.0) else award[SAID_MORE]
	return [award[TITLE], words % value]


## The least of [param field] that earns its award after a map [param scale] as long as the
## minimums are for.
static func least_of(field: StringName, scale := 1.0) -> float:
	var award: Array = AWARDS[field]
	var least: float = award[LEAST]
	return maxf(least * scale, 1.0) if award[TOTAL] else least


## What the player at [param place] in [param order] has earned, the most interesting first:
## [interest, field, value]. Its tier first, then how far over its least.
static func _wanted(order: Array[PlayerStats], place: int, scale: float) -> Array:
	var mine := order[place]
	var wanted: Array = []
	for field: StringName in AWARDS:
		var award: Array = AWARDS[field]
		var value := mine.value(field)
		var least := least_of(field, scale)
		if value <= 0.0 or value < least:
			continue
		if field == &"accuracy" and mine.value(&"bullets") < MARKSMAN_SHOTS:
			continue
		if award[TIER] == Tier.RIBBING and place == 0:
			continue
		if award[KIND] == Kind.CONTEST and not _leads(order, place, field):
			continue
		var interest := float(award[TIER]) * 10.0 + minf(value / least, 9.9)
		wanted.append([interest, field, value])
	wanted.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	return wanted


## Whether the player at [param place] in [param order] leads [param field]: more of it than
## anybody, or level with nobody placed above; a Road Warrior by [constant ROAD_LEAD].
static func _leads(order: Array[PlayerStats], place: int, field: StringName) -> bool:
	var value := order[place].value(field)
	for other: int in order.size():
		if other == place:
			continue
		var theirs := order[other].value(field) * (ROAD_LEAD if field == &"driven" else 1.0)
		if theirs > value or (is_equal_approx(theirs, value) and other < place):
			return false
	return true


## Whether an award already given, one of [param told], tells [param field]'s story, see
## [constant SAME_STORY].
static func _told_already(field: StringName, told: Array[StringName]) -> bool:
	for story: Array in SAME_STORY:
		if field in story:
			for other: StringName in story:
				if other != field and other in told:
					return true
	return false
