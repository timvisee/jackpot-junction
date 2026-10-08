class_name KartStyle
extends RefCounted
## How a kart is dressed, GAME.md 4.4: a paint pattern, a hat, a flag, what it leaves behind it, a
## frame round its plate and the marks its tires leave. All of them are the player's to pick, none
## of them changes how the kart drives, and the player's color is still the player's color
## underneath all of it. The first few of each are everybody's; the rest are won in the loyalty
## program, 8.9, see [constant EVERYBODY].
##
## Small numbers rather than resources, because a kart has to look the same on every screen and
## these ride the wire with the rest of the roster, GAME.md 10.3.

const PAINTS: Array[String] = [
	"Solid", "Stripes", "Checks", "Spots", "Card suits", "Racing stripes", "Flames", "Patchwork"
]
const HATS: Array[String] = [
	"None",
	"Cap",
	"Top hat",
	"Crown",
	"Party",
	"Learner",
	"Dealer's visor",
	"Fedora",
	"Shark fin",
	"Ear defenders",
	"Horns",
	"Traffic cone",
	"Hard hat",
	"Welding goggles",
	"Paper hat",
]
const FLAGS: Array[String] = [
	"None",
	"Pennant",
	"Banner",
	"Checkered",
	"Ace of spades",
	"Windsock",
	"Tape measure",
	"Fuzzy dice",
	"Kit's rag",
]
const TRAILS: Array[String] = [
	"Smoke", "Sparks", "Confetti", "None", "Poker chips", "Afterburn", "Pencil"
]
const FRAMES: Array[String] = ["None", "Gold"]
const MARKS: Array[String] = ["Plain", "Chalk", "Dashed"]
## Every part in the order they are asked for, offered and sent: the stalls of 4.4 dress the first
## four, and the Showroom of 8.9 the rest.
const CHOICES: Array[Array] = [PAINTS, HATS, FLAGS, TRAILS, FRAMES, MARKS]
## Each part as the loyalty program's landmarks name it, see [member LoyaltyLandmark.dress_part].
const PARTS: Array[StringName] = [&"paint", &"hat", &"flag", &"trail", &"frame", &"marks"]
## Which of each part's choices everybody has, GAME.md 4.4: most of the ones the game always had,
## and the plain one of each new kind. The rest a profile wins, 8.9, among them four the game
## always had: Checks, the top hat, the checkered flag and confetti.
const EVERYBODY: Array[Array] = [[0, 1, 3], [0, 1, 3, 4, 5], [0, 1, 2], [0, 1, 3], [0], [0]]

var paint := 0
var hat := 0
var flag := 0
var trail := 0
var frame := 0
var marks := 0


## A dress drawn at random, for a bot, GAME.md 4.4: a part at a time from what everybody has, bar
## the crown, which the bounty's carrier wears, see 3.10, and which on a bot would read as a price
## on its head.
static func random(rng: RandomNumberGenerator) -> KartStyle:
	var style := KartStyle.new()
	style.paint = _any(rng, 0)
	style.hat = _any(rng, 1, HATS.find("Crown"))
	style.flag = _any(rng, 2)
	style.trail = _any(rng, 3)
	return style


## One of what everybody has of [param part], at random, never [param but].
static func _any(rng: RandomNumberGenerator, part: int, but := -1) -> int:
	var open: Array = EVERYBODY[part].filter(func(index: int) -> bool: return index != but)
	return open[rng.randi_range(0, open.size() - 1)]


## Whether the choice [param index] of [param part] is one a player may wear who has won
## [param dress], the names [method Loyalty.unlocks_of] gives: everybody's, or one won.
static func allowed(part: int, index: int, dress: PackedStringArray) -> bool:
	if part < 0 or part >= CHOICES.size() or index < 0 or index >= CHOICES[part].size():
		return false
	return index in EVERYBODY[part] or won_name(part, index) in dress


## The name a won choice goes by among [method Loyalty.unlocks_of]'s, "hat:Fedora".
static func won_name(part: int, index: int) -> String:
	return "%s:%s" % [PARTS[part], CHOICES[part][index]]


## The choice of [param part] after [param index] that a player who has won [param dress] may
## wear, round to the first again past the last.
static func next(part: int, index: int, dress: PackedStringArray) -> int:
	var count: int = CHOICES[part].size()
	var at := index
	for i: int in count:
		at = (at + 1) % count
		if allowed(part, at, dress):
			return at
	return 0


## Reads the numbers back, from the wire or from the settings file, and drops anything that is not
## a choice this build has. Fewer numbers than parts, as the settings kept before more parts came,
## leave the rest plain.
static func from_array(values: Variant) -> KartStyle:
	var style := KartStyle.new()
	var packed := PackedInt32Array(values) if values != null else PackedInt32Array()
	var read := PackedInt32Array()
	read.resize(CHOICES.size())
	for i: int in mini(packed.size(), CHOICES.size()):
		read[i] = packed[i] if packed[i] >= 0 and packed[i] < CHOICES[i].size() else 0
	style.paint = read[0]
	style.hat = read[1]
	style.flag = read[2]
	style.trail = read[3]
	style.frame = read[4]
	style.marks = read[5]
	return style


func to_array() -> PackedInt32Array:
	return PackedInt32Array([paint, hat, flag, trail, frame, marks])


func duplicate_style() -> KartStyle:
	return KartStyle.from_array(to_array())
