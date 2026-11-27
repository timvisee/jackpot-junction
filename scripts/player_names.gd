class_name PlayerNames
extends RefCounted
## What the players are called, GAME.md 3.8. Everybody may set a name of 1 to 16 letters, a Chinese
## character, twice as wide, counting as two, see [method width], and
## anybody who does not is handed one off the list below, which is the whole reason the list is
## funny: a room of P1, P2, P3 and P4 says nothing about anybody, and the results screen at the
## end of a match is a list of names.

const MAX_LENGTH := 16
## The longest a game's name may be, or a dedicated server's, GAME.md 9.3: a row of a list of games
## each, cleaned the way a player's name is.
const TITLE_LENGTH := 32
## What an empty name box says, shown through tr(). Not the name anybody will be given, which is
## drawn at the whistle and would be a lie in a box: just the word for what goes here.
const PLACEHOLDER := "Player"
## Square brackets are dropped from a name because the standings and the kill feed are drawn with
## BBCode, and a name is a name rather than markup.
const FORBIDDEN := ["[", "]", "\n", "\t", "\r"]
## Handed out to anybody who never gave a name, in the order they are drawn. Deliberately silly:
## the alternative a player is being spared is being called P3 for five minutes. Each is shown
## through tr() as it is handed out, see [method pick], and is that player's name from then on.
# TRANSLATORS: A silly name handed to a player who gave none; at most 16 letters, a Chinese
# character counting as two.
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
	"Chip Gremlin",
	"Mult Muncher",
	"Oil Slick Rick",
	"Bank Run Bob",
	"Spin Cycle",
	"Ricochet Rita",
	"Tire Fire",
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
## Handed out to the bots and to nobody else, GAME.md 3.8: what a kart full of gears gets called,
## robot slang and worse, so a bot is told from a player at a glance down the standings. Each is
## shown through tr() as it is handed out, as [constant NAMES] are.
# TRANSLATORS: A bot's name, robot slang; at most 16 letters, a Chinese character
# counting as two.
const BOT_NAMES: Array[String] = [
	"Clanker",
	"Rusty",
	"Tin Can",
	"Droid",
	"Rust Bucket",
	"Bolt Bucket",
	"Scrap Heap",
	"Chrome Dome",
	"Sprocket",
	"Clunker",
	"Clank Sinatra",
	"Tin Can Tony",
	"Rusty Bolts",
	"Droid Rage",
	"Servo Steve",
	"Gearbox Gary",
	"Circuit Breaker",
	"Beep Boop",
	"Toaster",
	"Unit 404",
	"Wind-Up Wendy",
	"Cog Blimey",
	"Robo Rita",
	"Nuts N Bolts",
]
## Handed out to somebody watching a LAN game, GAME.md 10.3, who is not driving anything: names
## from the furniture they are sat on and the seat they have in the stands, so a name under an
## emote floating up the screen says it is from somebody watching before anybody reads the rim.
## Each is shown through tr() as it is handed out, as [constant NAMES] are.
# TRANSLATORS: The name of somebody watching, from what they sit on; at most 16 letters, a
# Chinese character counting as two.
const WATCHER_NAMES: Array[String] = [
	"Couch Potato",
	"Couch Critic",
	"Couch Surfer",
	"Sofa So Good",
	"Sofa Sofia",
	"Cushion Carl",
	"Armchair Ace",
	"Recliner Rita",
	"Beanbag Barry",
	"Ottoman Otto",
	"Loveseat Lou",
	"Futon Fred",
	"Settee Betty",
	"Chaise Chase",
	"Deckchair Dee",
	"Lawn Chair Lars",
	"Hammock Hank",
	"Stool Pigeon",
	"Barstool Bill",
	"Stool Stu",
	"Bench Warmer",
	"Bleacher Bob",
	"Seat Filler",
	"Front Row Fran",
	"Nosebleed Ned",
	"Back Seat Betty",
	"Box Seat Boris",
	"Cheap Seats Chad",
	"Ringside Rosa",
	"Popcorn Pam",
	"Snack Stacker",
	"Remote Hogger",
	"Pillow Fort Phil",
]

## Names held by people who are in the game but not in its match, a LAN game's watchers, GAME.md
## 10.3, so nobody who sits down is handed one of them. Kept by [NetDoor].
static var held_elsewhere: Array[String] = []


## A name as it will be shown: trimmed, on one line, no markup, and no wider than [param longest]
## letters, see [method width]. Returns an empty string for anything that was only whitespace,
## which counts as no name given.
static func clean(text: String, longest := MAX_LENGTH) -> String:
	var kept := ""
	for character: String in text:
		if character not in FORBIDDEN:
			kept += character
	return cut(kept, longest).strip_edges()


## How many letters wide [param text] is: a Chinese, Japanese or Korean character is about twice
## as wide as a letter and counts as two, so a name of them fills its plate no wider than one of
## letters, GAME.md 10.9.
static func width(text: String) -> int:
	var wide := 0
	for i: int in text.length():
		wide += 2 if Lang.wide(text.unicode_at(i)) else 1
	return wide


## [param text] up to [param longest] letters wide, see [method width], and no further.
static func cut(text: String, longest: int) -> String:
	var wide := 0
	for i: int in text.length():
		wide += 2 if Lang.wide(text.unicode_at(i)) else 1
		if wide > longest:
			return text.left(i)
	return text


## Keeps [param box] to [param longest] letters, see [method width]: a character typed past them is
## not taken, as one past its length is not.
static func hold(box: LineEdit, longest: int) -> void:
	box.max_length = longest
	box.text_changed.connect(
		func(typed: String) -> void:
			if width(typed) > longest:
				var caret := box.caret_column
				box.text = cut(typed, longest)
				box.caret_column = mini(caret, box.text.length())
	)


## One off the list that nobody in [param taken] is already using, drawn with [param rng] so a
## match seeded the same way names everybody the same way. Falls back to a numbered one in the
## impossible case that the whole list is in use. In the language spoken as it is handed out, and
## never translated again after: it is the player's name from then on, as one typed is.
static func pick(rng: RandomNumberGenerator, taken: Array[String] = []) -> String:
	return _pick_from(NAMES, Lang.t("Player %d"), rng, taken)


## One of [constant WATCHER_NAMES] that nobody in [param taken] has, for somebody watching.
static func pick_watcher(rng: RandomNumberGenerator, taken: Array[String] = []) -> String:
	return _pick_from(WATCHER_NAMES, Lang.t("Watcher %d"), rng, taken)


## One of [param names], each in the language spoken, that nobody has, or [param fallback]
## numbered past [param taken].
static func _pick_from(
	names: Array[String], fallback: String, rng: RandomNumberGenerator, taken: Array[String]
) -> String:
	var free: Array[String] = []
	for name: String in names:
		var said := Lang.t(name)
		if said not in taken and said not in held_elsewhere:
			free.append(said)
	if free.is_empty():
		return fallback % (taken.size() + 1)
	return free[rng.randi_range(0, free.size() - 1)]


## A bot's name off [constant BOT_NAMES] that nobody in [param taken] has, drawn from [param seed]
## so a match seeded the same way names its bots the same way, without moving the draws that name
## the players.
static func pick_bot(seed: int, taken: Array[String] = []) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return _pick_from(BOT_NAMES, Lang.t("Bot %d"), rng, taken)
