class_name PlayerNames
extends RefCounted
## What the players are called, GAME.md 3.8. Everybody may set a name of 1 to 16 characters, and
## anybody who does not is handed one off the list below, which is the whole reason the list is
## funny: a room of P1, P2, P3 and P4 says nothing about anybody, and the results screen at the
## end of a match is a list of names.

const MAX_LENGTH := 16
## What an empty name box says. Not the name anybody will be given, which is drawn at the
## whistle and would be a lie in a box: just the word for what goes here.
const PLACEHOLDER := "Player"
## Square brackets are dropped from a name because the standings and the kill feed are drawn with
## BBCode, and a name is a name rather than markup.
const FORBIDDEN := ["[", "]", "\n", "\t", "\r"]
## Handed out to anybody who never gave a name, in the order they are drawn. Deliberately silly:
## the alternative a player is being spared is being called P3 for five minutes.
const NAMES: Array[String] = [
	"Turbo Trout",
	"Sir Crashalot",
	"Nitro Noodle",
	"Bumper Betty",
	"Drift Muffin",
	"Skid Marky",
	"Chip Chomper",
	"Wheelie Wanda",
	"Double Down Dan",
	"Lucky Lug Nut",
	"Grease Monkey",
	"Pot Roast",
	"Full Tilt Fern",
	"Cash Splash",
	"Jackpot Jerry",
	"Slot Machine",
	"Handbrake Hal",
	"Coin Gremlin",
	"Mult Muncher",
	"Oil Slick Rick",
	"Bank Run Bob",
	"Spin Cycle",
	"Ricochet Rita",
	"Tyre Fire",
	"Curb Feeler",
	"Wager Wendy",
	"Ante Up Annie",
	"Pit Stop Pip",
	"Hot Streak Hank",
	"Snake Eyes Sam",
	"Loose Change",
	"Roulette Ron",
	"Fender Bender",
	"Gear Grinder",
	"Rusty Bucket",
	"Tail Light Tim",
	"Donut Duchess",
	"Penny Pincher",
]


## A name as it will be shown: trimmed, on one line, no markup, and no longer than the limit.
## Returns an empty string for anything that was only whitespace, which counts as no name given.
static func clean(text: String) -> String:
	var kept := ""
	for character: String in text:
		if character not in FORBIDDEN:
			kept += character
	return kept.substr(0, MAX_LENGTH).strip_edges()


## One off the list that nobody in [param taken] is already using, drawn with [param rng] so a
## match seeded the same way names everybody the same way. Falls back to a numbered one in the
## impossible case that the whole list is in use.
static func pick(rng: RandomNumberGenerator, taken: Array[String] = []) -> String:
	var free: Array[String] = []
	for name: String in NAMES:
		if name not in taken:
			free.append(name)
	if free.is_empty():
		return "Player %d" % (taken.size() + 1)
	return free[rng.randi_range(0, free.size() - 1)]
