class_name SupporterArt
extends RefCounted
## The Steam supporter pack's dress for its store page's pictures, GAME.md 10.8, docs/STEAM.md "The
## supporter pack": the outfits its karts wear in the capsules, the description's row of karts and
## the screenshots, each piece by its name, see [method style_of]. Nothing here ships: the dev
## scenes that take the pictures share it, see supporter_art_export.gd, the playground's
## `--dress=supporter` and readme_shots.gd.

## Outfits of the pack's pieces, part by part, a piece by its name or a part's number, and with
## "starlit" the part whose piece is worn in Starlight: every piece of the pack among them.
const OUTFITS: Array[Dictionary] = [
	{"paint": "Night sky", "hat": "Lighthouse", "flag": "Pinwheel", "trail": "Prism", "body": 1},
	{"paint": 6, "hat": "Halo", "flag": "Lantern", "trail": "Stardust", "body": 3},
	{"paint": 4, "hat": "House of cards", "flag": 4, "trail": "Prism", "body": 2},
	{"paint": "Night sky", "hat": "Lucky cat", "flag": "Lantern", "trail": "Stardust", "body": 0},
	{"paint": 7, "hat": "Tip jar", "flag": "Pinwheel", "trail": "Prism", "starlit": 1, "body": 2},
	{"paint": 3, "hat": "Halo", "flag": "Pinwheel", "trail": "Stardust", "body": 1},
	{"paint": "Night sky", "hat": "House of cards", "flag": "Lantern", "trail": 2, "body": 3},
	{"paint": 5, "hat": "Lighthouse", "flag": "Lantern", "trail": "Stardust", "body": 0},
]


## [param named], an outfit as [constant OUTFITS] has one, as a kart's dress.
static func style_of(named: Dictionary) -> KartStyle:
	var style := KartStyle.new()
	for part: String in named:
		var piece: Variant = named[part]
		if part == "starlit":
			style.finishes[int(piece)] = Loyalty.STARLIGHT
		elif piece is String:
			style.set(part, KartStyle.CHOICES[KartStyle.PARTS.find(StringName(part))].find(piece))
		else:
			style.set(part, piece)
	return style


## [param named] as the fields of a kart's dress, for what dresses a kart from a dictionary.
static func fields_of(named: Dictionary) -> Dictionary:
	var style := style_of(named)
	var fields := {"finishes": style.finishes}
	for part: StringName in KartStyle.PARTS:
		fields[String(part)] = style.get(part)
	return fields


## The first [param count] outfits, round again past the last, as the numbers a match is dressed
## by, see [method Match.start].
static func dresses(count: int) -> Array:
	var dressed: Array = []
	for i: int in count:
		dressed.append(style_of(OUTFITS[i % OUTFITS.size()]).to_array())
	return dressed
