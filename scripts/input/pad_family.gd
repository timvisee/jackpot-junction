class_name PadFamily
extends RefCounted
## Which family of gamepad a pad is, GAME.md 8.3, so a hint draws the buttons printed on the pad in
## the player's hands: an Xbox pad's lettered buttons, a PlayStation pad's four shapes and L1 to R2,
## a Nintendo pad's letters, which stand where an Xbox pad's other letters do, and ZL and ZR.
##
## The engine reads every pad by where its buttons are, so the button at the bottom of the four is
## the same button to the game on all of them; only what is printed on it differs. Told apart by
## the maker's USB id, and by the pad's name where a pad does not say, as on a phone. Any other pad,
## and the pad of a player who has not touched one yet, is a generic pad: its buttons named and
## drawn as an Xbox pad's, the layout the engine names its buttons after and most other pads print
## on theirs, where a picture of the whole pad shows no maker's. A debug build started
## with `++ --pad=playstation`, `--pad=playstation4`, `--pad=nintendo`, `--pad=xbox` or
## `--pad=generic` draws every pad as that family, for trying one without the pad.

enum Family { GENERIC, XBOX, PLAYSTATION, PLAYSTATION_4, NINTENDO }

## The makers' USB ids, and Sony's pads with a Share button rather than the DualSense's Create:
## the DualShock 4, both models and its wireless adapter, and the PS3's, which is nearest to it.
const SONY := 0x054C
const NINTENDO := 0x057E
const MICROSOFT := 0x045E
const SHARE_PADS: Array[int] = [0x05C4, 0x09CC, 0x0BA0, 0x0268]
## Words in a pad's name that say its family, for a pad whose maker's id does not, in the order
## they are looked for.
const NAMED: Array[Array] = [
	["dualsense", Family.PLAYSTATION],
	["ps5", Family.PLAYSTATION],
	["dualshock", Family.PLAYSTATION_4],
	["ps4", Family.PLAYSTATION_4],
	["ps3", Family.PLAYSTATION_4],
	["playstation", Family.PLAYSTATION],
	["sony", Family.PLAYSTATION],
	["nintendo", Family.NINTENDO],
	["switch", Family.NINTENDO],
	["joy-con", Family.NINTENDO],
	["pro controller", Family.NINTENDO],
	["xbox", Family.XBOX],
	["x-box", Family.XBOX],
	["xinput", Family.XBOX],
]
## What each family calls the buttons the engine names an Xbox pad's way, see
## [method InputActions.event_text]; a name left out is the same on that family's pads. A
## PlayStation pad's four are named for their shapes and drawn as them, see [InputGlyph].
const WORDS: Dictionary[Family, Dictionary] = {
	Family.PLAYSTATION:
	{
		"A": "Cross",
		"B": "Circle",
		"X": "Square",
		"Y": "Triangle",
		"LB": "L1",
		"RB": "R1",
		"LT": "L2",
		"RT": "R2",
		"LS": "L3",
		"RS": "R3",
		"View": "Create",
		"Menu": "Options",
		"Home": "PS",
		"Share": "Mute",
	},
	Family.PLAYSTATION_4:
	{
		"A": "Cross",
		"B": "Circle",
		"X": "Square",
		"Y": "Triangle",
		"LB": "L1",
		"RB": "R1",
		"LT": "L2",
		"RT": "R2",
		"LS": "L3",
		"RS": "R3",
		"View": "Share",
		"Menu": "Options",
		"Home": "PS",
	},
	Family.NINTENDO:
	{
		"A": "B",
		"B": "A",
		"X": "Y",
		"Y": "X",
		"LB": "L",
		"RB": "R",
		"LT": "ZL",
		"RT": "ZR",
		"View": "−",
		"Menu": "+",
		"Share": "Capture",
	},
}
## What `--pad=` says for each family.
const ASKED: Dictionary[String, Family] = {
	"generic": Family.GENERIC,
	"xbox": Family.XBOX,
	"playstation": Family.PLAYSTATION,
	"playstation4": Family.PLAYSTATION_4,
	"nintendo": Family.NINTENDO,
}

## The family every pad is drawn as in a debug build started with `--pad=`, or -1.
static var pretend := -1
## Counts up whenever what [method shown] or [method of_device] answer may have changed, so a glyph
## looks again only then rather than asking about its pad every frame, see [InputGlyph].
static var epoch := 0

## The pad touched last, see [method touched], and its family; the families of the pads asked
## about, by the engine's id for each, until one comes or goes, see [method forget].
static var _last_pad := -1
static var _shown := Family.GENERIC
static var _known: Dictionary[int, Family] = {}


static func _static_init() -> void:
	if not OS.is_debug_build():
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--pad="):
			pretend = ASKED.get(arg.get_slice("=", 1), -1)


## The family of the pad the player last touched, which a hint for a player who reads every device
## draws, GAME.md 8.3; a generic pad's before any pad has been touched.
static func shown() -> Family:
	return pretend as Family if pretend >= 0 else _shown


## The family of the pad [param device] is; for [constant DeviceInput.ANY] or the keyboard, the one
## [method shown] says.
static func of_device(device: int) -> Family:
	if pretend >= 0:
		return pretend as Family
	if device < 0:
		return _shown
	if _known.has(device):
		return _known[device]
	# A pad the engine has not got, a seat's own that was unplugged, say: nothing to ask about.
	if not Input.get_connected_joypads().has(device):
		return Family.GENERIC
	_known[device] = of_pad(Input.get_joy_info(device), Input.get_joy_name(device))
	return _known[device]


## The family of a pad the engine tells [param info] of, see [method Input.get_joy_info], and
## calls [param named].
static func of_pad(info: Dictionary, named: String) -> Family:
	var maker := int(str(info.get("vendor_id", "0")))
	var product := int(str(info.get("product_id", "0")))
	if maker == SONY:
		return Family.PLAYSTATION_4 if product in SHARE_PADS else Family.PLAYSTATION
	if maker == NINTENDO:
		return Family.NINTENDO
	if maker == MICROSOFT:
		return Family.XBOX
	var words := ("%s %s" % [named, info.get("raw_name", "")]).to_lower()
	for each: Array in NAMED:
		if words.contains(each[0]):
			return each[1]
	return Family.GENERIC


## What [param family] calls the button the engine names [param xbox], an Xbox pad's name for it;
## for -1, the family [method shown] says.
static func word(xbox: String, family: int = -1) -> String:
	var drawn := shown() if family < 0 else family as Family
	if lettered(drawn):
		return xbox
	return WORDS[drawn].get(xbox, xbox)


## Whether [param family] has an Xbox pad's lettered buttons, in the colors everybody knows.
static func lettered(family: Family) -> bool:
	return family in [Family.GENERIC, Family.XBOX]


## Whether [param family] draws its four buttons under the thumb as the PlayStation's shapes.
static func shapes(family: Family) -> bool:
	return family in [Family.PLAYSTATION, Family.PLAYSTATION_4]


## The pad [param device] was just touched, see [method DeviceInput.touched].
static func touched(device: int) -> void:
	if device < 0 or device == _last_pad:
		return
	_last_pad = device
	_look_again()


## A pad came or went: the engine may give its id to another pad, so every family is asked again.
static func forget() -> void:
	_known.clear()
	if _last_pad >= 0 and not Input.get_connected_joypads().has(_last_pad):
		_last_pad = -1
	_look_again()
	epoch += 1


## Back as the game starts, for a test.
static func reset() -> void:
	_known.clear()
	_last_pad = -1
	_shown = Family.GENERIC
	epoch += 1


static func _look_again() -> void:
	var was := _shown
	_shown = Family.GENERIC if _last_pad < 0 else of_device(_last_pad)
	if _shown != was:
		epoch += 1
