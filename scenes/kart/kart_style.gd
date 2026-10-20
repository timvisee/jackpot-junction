class_name KartStyle
extends RefCounted
## How a kart is dressed, GAME.md 4.4: a paint pattern, a hat, a flag, what it leaves behind it, a
## frame round its plate, the marks its tires leave and the body it is built in. All of them are
## the player's to pick, none of them changes how the kart drives, and the player's color is still
## the player's color underneath all of it. The first few of each are everybody's; the rest are won
## in the loyalty program, 8.9, see [constant EVERYBODY].
##
## Small numbers rather than resources, because a kart has to look the same on every screen and
## these ride the wire with the rest of the roster, GAME.md 10.3.

const PAINTS: Array[String] = [
	"Solid",
	"Stripes",
	"Checks",
	"Spots",
	"Card suits",
	"Racing stripes",
	"Flames",
	"Patchwork",
	"Graph paper",
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
	"Fez",
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
	"Magnet",
]
const TRAILS: Array[String] = [
	"Smoke", "Sparks", "Confetti", "None", "Poker chips", "Afterburn", "Pencil"
]
const FRAMES: Array[String] = ["None", "Gold"]
const MARKS: Array[String] = ["Plain", "Chalk", "Dashed", "Pencil"]
## The bodies a kart is built in, GAME.md 4.4 and 8.1b, each the model its name in lower case
## names, see [method KartVisuals.body_of]: the racer everybody drives, and three the loyalty
## program pays. Every body is the same kart to play, over the same chassis and the same collider.
const BODIES: Array[String] = ["Racer", "Woodie", "Streamliner", "Microcar"]
## Every part in the order they are asked for, offered and sent, at the lobby's stalls of 4.4 and
## in the kart dialog of 4.4a. The body last, a part of its own rather than of the dress: the
## stalls leave it to the dialog, a finish never shows on it, and Dressed to the Nines does not
## count it, 8.10.
const CHOICES: Array[Array] = [PAINTS, HATS, FLAGS, TRAILS, FRAMES, MARKS, BODIES]
## The body's part, the last of [constant CHOICES].
const BODY := 6
## Each part as the loyalty program's landmarks name it, see [member LoyaltyLandmark.dress_part].
const PARTS: Array[StringName] = [&"paint", &"hat", &"flag", &"trail", &"frame", &"marks", &"body"]
## Which of each part's choices everybody has, GAME.md 4.4: most of the ones the game always had,
## and the plain one of each new kind, the racer of the bodies. The rest a profile wins, 8.9, among
## them four the game always had: Checks, the top hat, the checkered flag and confetti.
const EVERYBODY: Array[Array] = [[0, 1, 3], [0, 1, 3, 4, 5], [0, 1, 2], [0, 1, 3], [0], [0], [0]]
## How often a kart of the demo for a booth wears a piece in an edition's finish, GAME.md 9.8, never
## more than one piece, and how often each finish is the one, Foil, Holographic and Polychrome in
## [constant Loyalty.FINISHES] order: rare, as editions are in play, and the higher the rarer.
const DEMO_EDITION := 0.15
const DEMO_FINISHES: Array[float] = [0.7, 0.25, 0.05]

var paint := 0
var hat := 0
var flag := 0
var trail := 0
var frame := 0
var marks := 0
var body := 0
## The finish each part is worn in, in [constant CHOICES] order, 0 for none and then the finishes
## of the loyalty program's editions, GAME.md 8.9: a sheen over the piece, seen on every screen.
## None on the body, whose paint's finish is its sheen.
var finishes := PackedInt32Array([0, 0, 0, 0, 0, 0, 0])


## A dress drawn at random, for a bot, GAME.md 4.4: a part at a time from what everybody has, bar
## the crown, which the bounty's carrier wears, see 3.10, and which on a bot would read as a price
## on its head. Its body is the racer, everybody's.
static func random(rng: RandomNumberGenerator) -> KartStyle:
	var style := KartStyle.new()
	style.paint = _any(rng, 0)
	style.hat = _any(rng, 1, HATS.find("Crown"))
	style.flag = _any(rng, 2)
	style.trail = _any(rng, 3)
	return style


## A dress drawn at random from everything there is, GAME.md 9.8, for the demo for a booth's karts:
## every part from all of its choices, won ones too, the bodies among them, and now and then one
## piece of dress in an edition's finish, see [constant DEMO_EDITION]; never the crown, as for a
## bot.
static func dressed_up(rng: RandomNumberGenerator) -> KartStyle:
	var style := KartStyle.new()
	var crown := HATS.find("Crown")
	var picked := PackedInt32Array()
	for part: int in CHOICES.size():
		var count: int = CHOICES[part].size()
		var index := rng.randi_range(0, count - 1)
		while part == 1 and index == crown:
			index = rng.randi_range(0, count - 1)
		picked.append(index)
	style.paint = picked[0]
	style.hat = picked[1]
	style.flag = picked[2]
	style.trail = picked[3]
	style.frame = picked[4]
	style.marks = picked[5]
	style.body = picked[BODY]
	var dressed: Array[int] = []
	for part: int in BODY:
		if picked[part] > 0:
			dressed.append(part)
	if not dressed.is_empty() and rng.randf() < DEMO_EDITION:
		var part := dressed[rng.randi_range(0, dressed.size() - 1)]
		style.finishes[part] = 1 + rng.rand_weighted(PackedFloat32Array(DEMO_FINISHES))
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
## leave the rest plain: a profile from before the bodies drives the racer.
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
	style.body = read[BODY]
	# The finishes after the choices, as many as were sent, none for a plain part.
	for i: int in CHOICES.size():
		var at := CHOICES.size() + i
		if at < packed.size() and read[i] > 0:
			style.finishes[i] = clampi(packed[at], 0, Loyalty.FINISHES.size())
	return style


## The choices, and after them the finishes where there are any: a style with none is a number for
## each part.
func to_array() -> PackedInt32Array:
	var values := PackedInt32Array([paint, hat, flag, trail, frame, marks, body])
	for finish_of: int in finishes:
		if finish_of > 0:
			values.append_array(finishes)
			break
	return values


## The finish [param part] is worn in, 0 for none.
func finish(part: int) -> int:
	return finishes[part] if part >= 0 and part < finishes.size() else 0


func duplicate_style() -> KartStyle:
	return KartStyle.from_array(to_array())
