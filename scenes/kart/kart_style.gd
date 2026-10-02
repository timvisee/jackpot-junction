class_name KartStyle
extends RefCounted
## How a kart is dressed, GAME.md 4.4: a paint pattern, a hat, a flag and what it leaves behind
## it. All four are the player's to pick, none of them changes how the kart drives, and the
## player's color is still the player's color underneath all of it.
##
## Four small numbers rather than four resources, because a kart has to look the same on every
## screen and these ride the wire with the rest of the roster, GAME.md 10.3.

const PAINTS: Array[String] = ["Solid", "Stripes", "Checks", "Spots"]
const HATS: Array[String] = ["None", "Cap", "Top hat", "Crown", "Party", "Learner"]
const FLAGS: Array[String] = ["None", "Pennant", "Banner", "Checkered"]
const TRAILS: Array[String] = ["Smoke", "Sparks", "Confetti", "None"]
## The four in the order they are asked for, offered and sent.
const CHOICES: Array[Array] = [PAINTS, HATS, FLAGS, TRAILS]

var paint := 0
var hat := 0
var flag := 0
var trail := 0


## A dress drawn at random, for a bot, GAME.md 4.4: a part at a time from its choices, bar the
## crown, which the bounty's carrier wears, see 3.10, and which on a bot would read as a price on
## its head.
static func random(rng: RandomNumberGenerator) -> KartStyle:
	var style := KartStyle.new()
	style.paint = rng.randi_range(0, PAINTS.size() - 1)
	style.hat = rng.randi_range(0, HATS.size() - 2)
	if style.hat >= HATS.find("Crown"):
		style.hat += 1
	style.flag = rng.randi_range(0, FLAGS.size() - 1)
	style.trail = rng.randi_range(0, TRAILS.size() - 1)
	return style


## Reads four numbers back, from the wire or from the settings file, and drops anything that is
## not a choice this build has. An older machine sending a hat this one has never heard of is a
## kart with no hat, not a crash.
static func from_array(values: Variant) -> KartStyle:
	var style := KartStyle.new()
	var packed := PackedInt32Array(values) if values != null else PackedInt32Array()
	for i: int in mini(packed.size(), CHOICES.size()):
		var picked := packed[i] if packed[i] >= 0 and packed[i] < CHOICES[i].size() else 0
		match i:
			0:
				style.paint = picked
			1:
				style.hat = picked
			2:
				style.flag = picked
			3:
				style.trail = picked
	return style


func to_array() -> PackedInt32Array:
	return PackedInt32Array([paint, hat, flag, trail])


func duplicate_style() -> KartStyle:
	return KartStyle.from_array(to_array())
