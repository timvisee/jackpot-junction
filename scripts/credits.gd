class_name Credits
extends RefCounted
## Who made what in Jackpot Junction, GAME.md 8.5: the AI models that made the game, and everything
## in it somebody else made. The About page reads it; THIRD_PARTY.md is the full record, with the
## files and the terms, and a test holds the two to each other.

## Where the game lives.
const REPOSITORY := "https://github.com/timvisee/jackpot-junction"
## The models that made it, in the order they worked on it, all of them Anthropic's.
const MODELS: Array[String] = ["Claude Fable 5.1", "Claude Opus 5", "Claude Opus 5.5"]
## What the game is built with and from: what it is, who made it, on what terms, and where.
const THINGS: Array[Dictionary] = [
	{
		"what": "Godot Engine",
		"who": "Juan Linietsky, Ariel Manzur and contributors",
		"terms": "MIT license",
		"where": "godotengine.org",
	},
	{
		"what": "Car Kit, Casino Audio, Impact Sounds and Interface Sounds",
		"who": "Kenney Vleugels",
		"terms": "CC0",
		"where": "kenney.nl",
	},
	{
		"what": "Electronic Music Pack Vol. 8",
		"who": "Ovani Sound",
		"terms": "Ovani Sound license",
		"where": "ovanisound.com",
	},
	{
		"what": "Racing Sound Pack",
		"who": "Cascadia Games",
		"terms": "Cascadia Games license",
		"where": "cascadiagames.itch.io",
	},
	{
		"what": "Inter typeface",
		"who": "Rasmus Andersson and the Inter Project Authors",
		"terms": "SIL Open Font License 1.1",
		"where": "rsms.me/inter",
	},
	{
		"what": "Homemade Apple typeface, the signature on the driver license",
		"who": "Font Diner",
		"terms": "Apache License 2.0",
		"where": "fonts.google.com/specimen/Homemade+Apple",
	},
	{
		"what": "Material Symbols, the tap",
		"who": "Google",
		"terms": "Apache License 2.0",
		"where": "fonts.google.com/icons",
	},
	{
		"what": "gdUnit4, the tests' framework",
		"who": "Mike Schulze",
		"terms": "MIT license",
		"where": "github.com/MikeSchulze/gdUnit4",
	},
]


## The models, written out as a list in a sentence: "A, B and C".
static func models_in_words() -> String:
	if MODELS.size() == 1:
		return MODELS[0]
	return "%s and %s" % [", ".join(MODELS.slice(0, MODELS.size() - 1)), MODELS[-1]]
