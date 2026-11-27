class_name TableCards
extends RefCounted
## The table's cards, GAME.md 3.17: the features of a match that can be dealt onto the table or
## left off it, each a playing card in the match settings, face up for on and face down for off.
## Everything else, driving, shooting, the chips, the pot and the Junction, is always on.
##
## A table is a number, a bit for each card, so it goes over the wire with the rest of the rules,
## see [member MatchRules.table]. A card that is off takes its pieces off the map before the room is
## built, [method clear_grid], and whatever it switches off in the rules, see
## [method MatchConfig.rules], so nothing in the match has to ask about it twice.
##
## The cards are in the order the House opens them for a new profile, 8.9a: power-ups from the
## first map, then one more after each map played to the whistle.

enum Card { ITEMS, JACKPOT, JOKERS, FLUSH, TRICKS, SLOTS, BOUNTY, SUITS }

## Every card, the whole floor.
const ALL := (1 << 8) - 1
## The table of a profile that has played nothing yet, and of the Penny table preset.
const FIRST := 1 << Card.ITEMS
## What each card is called, on its face and wherever it is named, shown through tr().
const NAMES: Array[String] = [
	"Power-ups",
	"Jackpot",
	"Jokers",
	"Royal Flush",
	"Room tricks",
	"Slot machines",
	"Bounty",
	"Suits & hands",
]
## The one line each card says of itself, in the words the game prints wherever the card is shown
## new: on the payout slip's coupon and on the loading screen, 8.6; shown through tr().
const LINES: Array[String] = [
	"Grab a box, then press the item button to use what was in it.",
	"A pile of chips grows on the Jackpot. Park on it alone to scoop it up.",
	"Each time you go down, pick 1 of 3 cards that bend the rules for you.",
	"Drive over the four suit pads. Each pays while it's yours; all four is a flush.",
	"Each room has tricks of its own: bumpers, belts, magnets, needles and more.",
	"Roll onto a machine with chips in your pot to bet some of them.",
	"A price goes on a runaway leader. Take them out to collect.",
	"Three jokers of one suit pay a bonus; more of them make poker hands.",
]
## The map glyphs, GAME.md 6.3, each card takes off the floor while it is off: they become floor.
## The laser tripwires go with either of theirs, being a room's trick that calls a bounty.
const GLYPHS: Array[String] = ["P", "K", "", "F", "@E=MNWL", "$", "L", ""]  # NO_TRANSLATE
## The cards Roulette deals from, 3.17: power-ups are always on the table, and Suits & hands come
## with Jokers rather than on their own.
const DEALT: Array[int] = [
	Card.JACKPOT, Card.JOKERS, Card.FLUSH, Card.TRICKS, Card.SLOTS, Card.BOUNTY
]
## How many of [constant DEALT] Roulette deals a map.
const DEAL := 3
## The jokers that do nothing but bend the suits, left out of a deck without Suits & hands.
const SUITS_ONLY: Array[StringName] = [&"flush_draw"]


static func bit(card: int) -> int:
	return 1 << card


## Whether [param table] holds [param card].
static func has(table: int, card: int) -> bool:
	return table & bit(card) != 0


## [param table] with [param card] put on it, or taken off it.
static func with(table: int, card: int, on: bool) -> int:
	return table | bit(card) if on else table & ~bit(card)


## The cards on [param table], in order.
static func cards_of(table: int) -> Array[int]:
	var cards: Array[int] = []
	for card: int in Card.size():
		if has(table, card):
			cards.append(card)
	return cards


## [param table] as it can be played: Suits & hands are nothing without the Jokers they are of.
static func playable(table: int) -> int:
	return table if has(table, Card.JOKERS) else with(table, Card.SUITS, false)


## After how many maps played to the whistle the House opens [param card] for a profile, 8.9a:
## power-ups from the start, then one card a map in the order of [enum Card].
static func opens_after(card: int) -> int:
	return card


## The cards the House has opened for a profile that has played [param maps] maps to the whistle,
## as a table.
static func opened_by(maps: int) -> int:
	var table := 0
	for card: int in Card.size():
		if opens_after(card) <= maps:
			table |= bit(card)
	return table


## The card the House opened as the map played [param maps] maps in ended, or -1 for a map that
## opened none.
static func opened_at(maps: int) -> int:
	return maps if maps > 0 and maps < Card.size() else -1


## The glyphs [param table] takes off the map, the ones of every card that is off.
static func glyphs_off(table: int) -> String:
	var off := ""
	for card: int in Card.size():
		if not has(table, card):
			for glyph: String in GLYPHS[card]:
				if glyph not in off:
					off += glyph
	return off


## [param rows] of a map with every glyph in [param off] made floor, GAME.md 6.3.
static func clear_grid(rows: PackedStringArray, off: String) -> PackedStringArray:
	if off.is_empty():
		return rows
	var cleared: PackedStringArray = []
	for row: String in rows:
		for glyph: String in off:
			row = row.replace(glyph, ".")
		cleared.append(row)
	return cleared


## A table Roulette deals from [param deck], 3.17: power-ups, and [constant DEAL] of the deck's
## other cards drawn with [param rng]; Suits & hands with Jokers where the deck holds them.
static func deal(deck: int, rng: RandomNumberGenerator) -> int:
	var pool: Array[int] = []
	for card: int in DEALT:
		if has(deck, card):
			pool.append(card)
	for i: int in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := pool[i]
		pool[i] = pool[j]
		pool[j] = swap
	var table := bit(Card.ITEMS) & deck
	for card: int in pool.slice(0, DEAL):
		table |= bit(card)
	if has(table, Card.JOKERS) and has(deck, Card.SUITS):
		table |= bit(Card.SUITS)
	return table


## The cards of [param table] by name in the language spoken, in order, joined for fine print.
static func names_of(table: int, joiner := " · ") -> String:
	var names: PackedStringArray = []
	for card: int in cards_of(table):
		names.append(Lang.t(NAMES[card]))
	return joiner.join(names)
