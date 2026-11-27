class_name Credits
extends RefCounted
## Who made what in Jackpot Junction, GAME.md 8.5: the AI models that made the game, and everything
## in it somebody else made. The About page reads it; THIRD_PARTY.md is the full record, with the
## files and the terms, and a test holds the two to each other.

## Where the game lives.
const REPOSITORY := "https://github.com/timvisee/jackpot-junction"
## The game's pages to get it from: its store page on Steam, see STEAM.md, and itch.io's, ITCH.md.
const STEAM := "https://store.steampowered.com/app/5652730"
const ITCH := "https://timvisee.itch.io/jackpot-junction"
## The models that made it, in the order they worked on it, all of them Anthropic's.
const MODELS: Array[String] = ["Claude Fable 5.1", "Claude Opus 5", "Claude Opus 5.5"]
## What the game is built with and from: what it is, who made it, on what terms, and where. And so
## a build lists only what it holds, see [method in_this_build]: `files`, the res:// paths of it,
## one of which a build that holds it has; `steam`, for what only a Steam build has, GAME.md 10.8;
## and `music`, for music, which a build from the public repository alone does not have, see
## [constant Audio.TRACKS]. Without any of the three it is in every build. And for the notices,
## see [Licenses]: `license`, the key in [method Engine.get_license_info] of the terms' text, and
## `copyright`, the lines of it, as the license files beside the files give them, without the
## word Copyright.
const THINGS: Array[Dictionary] = [
	{
		"what": "Godot Engine",
		"who": "Juan Linietsky, Ariel Manzur and contributors",
		"terms": "MIT license",
		"where": "godotengine.org",
	},
	{
		"what": "Casino Audio, Impact Sounds, Interface Sounds and RPG Audio",
		"who": "Kenney Vleugels",
		"terms": "CC0",
		"where": "kenney.nl",
		"files":
		[
			"res://assets/audio/sfx/chip-lay-1.ogg",
			"res://assets/audio/sfx/impactGeneric_light_000.ogg",
			"res://assets/audio/sfx/click_001.ogg",
			"res://assets/audio/sfx/bookOpen.ogg",
		],
		"license": "CC0-1.0",
	},
	{
		"what": "Electronic Music Pack Vol. 8",
		"who": "Ovani Sound",
		"terms": "Ovani Sound license",
		"where": "ovanisound.com",
		"music": true,
	},
	{
		"what": "Racing Sound Pack",
		"who": "Cascadia Games",
		"terms": "Cascadia Games license",
		"where": "cascadiagames.itch.io",
		"files": ["res://assets/audio/kart/engine_loop.ogg"],
	},
	{
		"what": "Barlow typeface",
		"who": "Jeremy Tribby and the Barlow Project Authors",
		"terms": "SIL Open Font License 1.1",
		"where": "github.com/jpt/barlow",
		"files":
		[
			"res://assets/fonts/Barlow-Medium.ttf",
			"res://assets/fonts/BarlowCondensed-Black.ttf",
			"res://assets/fonts/BarlowCondensed-ExtraBold.ttf",
			"res://assets/fonts/BarlowSemiCondensed-SemiBold.ttf",
		],
		"license": "OFL-1.1",
		"copyright": ["2017 The Barlow Project Authors (https://github.com/jpt/barlow)"],
	},
	{
		"what": "Inter typeface, for the letters Barlow does not draw",
		"who": "Rasmus Andersson and the Inter Project Authors",
		"terms": "SIL Open Font License 1.1",
		"where": "rsms.me/inter",
		"files": ["res://assets/fonts/Inter-Regular.ttf"],
		"license": "OFL-1.1",
		"copyright": ["2020 The Inter Project Authors (https://github.com/rsms/inter)"],
	},
	{
		"what": "Homemade Apple typeface, for a signature",
		"who": "Font Diner",
		"terms": "Apache License 2.0",
		"where": "fonts.google.com/specimen/Homemade+Apple",
		"files": ["res://assets/fonts/HomemadeApple-Regular.ttf"],
		"license": "Apache-2.0",
		# Its license file is the license alone; the line is the font's own, from its name table.
		"copyright": ["2010 Font Diner, Inc."],
	},
	{
		"what": "Caveat typeface, for notes in pencil",
		"who": "The Caveat Project Authors",
		"terms": "SIL Open Font License 1.1",
		"where": "github.com/googlefonts/caveat",
		"files": ["res://assets/fonts/Caveat-Variable.ttf"],
		"license": "OFL-1.1",
		"copyright": ["2014 The Caveat Project Authors (https://github.com/googlefonts/caveat)"],
	},
	{
		"what": "Kalam typeface, for another hand",
		"who": "Indian Type Foundry",
		"terms": "SIL Open Font License 1.1",
		"where": "fonts.google.com/specimen/Kalam",
		"files": ["res://assets/fonts/Kalam-Regular.ttf"],
		"license": "OFL-1.1",
		"copyright": ["2014, Indian Type Foundry (info@indiantypefoundry.com)"],
	},
	{
		"what": "Patrick Hand typeface, for a third hand",
		"who": "Patrick Wagesreiter",
		"terms": "SIL Open Font License 1.1",
		"where": "fonts.google.com/specimen/Patrick+Hand",
		"files": ["res://assets/fonts/PatrickHand-Regular.ttf"],
		"license": "OFL-1.1",
		"copyright": ["2010-2012 Patrick Wagesreiter (mail@patrickwagesreiter.at)"],
	},
	{
		"what": "Reenie Beanie typeface, for a line scratched with a point",
		"who": "James Grieshaber",
		"terms": "SIL Open Font License 1.1",
		"where": "fonts.google.com/specimen/Reenie+Beanie",
		"files": ["res://assets/fonts/ReenieBeanie-Regular.ttf"],
		"license": "OFL-1.1",
		"copyright": ["2010, James Grieshaber (james@typeco.com)"],
	},
	{
		"what": "Permanent Marker typeface, for a marker pen",
		"who": "Font Diner",
		"terms": "Apache License 2.0",
		"where": "fonts.google.com/specimen/Permanent+Marker",
		"files": ["res://assets/fonts/PermanentMarker-Regular.ttf"],
		"license": "Apache-2.0",
		# As Homemade Apple's: the font's own line, from its name table.
		"copyright": ["2010 Font Diner, Inc."],
	},
	{
		"what": "Courier Prime typeface, for everything typed",
		"who": "Alan Dague-Greene and the Courier Prime Project Authors",
		"terms": "SIL Open Font License 1.1",
		"where": "github.com/quoteunquoteapps/CourierPrime",
		"files": ["res://assets/fonts/CourierPrime-Regular.ttf"],
		"license": "OFL-1.1",
		"copyright":
		[
			(
				"2015 The Courier Prime Project Authors"
				+ " (https://github.com/quoteunquoteapps/CourierPrime)"
			),
		],
	},
	{
		"what": "IM FELL English typeface, for an old book",
		"who": "Igino Marini",
		"terms": "SIL Open Font License 1.1",
		"where": "iginomarini.com/fell",
		"files": ["res://assets/fonts/IMFellEnglish-Regular.ttf"],
		"license": "OFL-1.1",
		"copyright": ["2010, Igino Marini (mail@iginomarini.com)"],
	},
	{
		"what": "Free Controller Prompts, the pads on How to hold the wheel",
		"who": 'Nicolae "Xelu" Berbece',
		"terms": "CC0 1.0",
		"where": "thoseawesomeguys.com/prompts",
		"files":
		[
			"res://assets/controllers/xbox_series.png",
			"res://assets/controllers/playstation_5.png",
			"res://assets/controllers/playstation_4.png",
		],
		"license": "CC0-1.0",
	},
	{
		"what": "The Steam Deck's drawings, on How to hold the wheel",
		"who": "Valve Corporation",
		"terms": "offered for a game's input callouts",
		"where": "partner.steamgames.com/doc/steamhardware/steamdeck/svg",
		"steam": true,
	},
	{
		# In every build: the game draws the tap from its path in GlyphArt, which every build has.
		"what": "Material Symbols, the tap",
		"who": "Google",
		"terms": "Apache License 2.0",
		"where": "fonts.google.com/icons",
		"license": "Apache-2.0",
		# Google publishes them under the license alone, with no line of whose they are.
		"copyright": [],
	},
	{
		"what": "gdUnit4, the tests' framework",
		"who": "Mike Schulze",
		"terms": "MIT license",
		"where": "github.com/MikeSchulze/gdUnit4",
		# Never exported, so only a game run from the project credits it.
		"files": ["res://addons/gdUnit4/plugin.gd"],
		"license": "Expat",
		"copyright": ["2023 Mike Schulze"],
	},
	{
		"what": "GodotSteam, the way to Steam",
		"who": "GP Garcia, Chris Ridenour and contributors",
		"terms": "MIT license",
		"where": "godotsteam.com",
		"steam": true,
		"license": "Expat",
		"copyright": ["2015-Current, GP Garcia, Chris Ridenour, and Contributors"],
	},
	{
		"what": "Steamworks SDK",
		"who": "Valve Corporation",
		"terms": "Steamworks SDK Access Agreement",
		"where": "partner.steamgames.com",
		"steam": true,
	},
]
## The engine singleton GodotSteam brings, [constant Store.SINGLETON]: named here so that the hall
## of a dedicated server, which has none of the game's autoloads, can read this without Store.
const STEAM_SINGLETON := &"Steam"


## What this build is made with, see [constant THINGS]: what it holds the files of, what only a
## Steam build has where this is one, carrying GodotSteam, and music only where this build has
## that maker's tracks. Safe in a dedicated server's hall, GAME.md 9.3a, which has no autoloads: it
## asks the Audio node for the music where there is one, and the hall, with none, has no music.
## [param of] is what to choose from, all of [constant THINGS] but in a test.
static func in_this_build(of: Array[Dictionary] = THINGS) -> Array[Dictionary]:
	var steam := Engine.has_singleton(STEAM_SINGLETON)
	var audio := (Engine.get_main_loop() as SceneTree).root.get_node_or_null(^"Audio")
	var things: Array[Dictionary] = []
	for thing: Dictionary in of:
		if thing.get("steam", false) and not steam:
			continue
		if thing.get("music", false):
			if audio == null or not audio.call(&"has_music_by", thing["who"]):
				continue
		if thing.has("files") and not (thing["files"] as Array).any(holds):
			continue
		things.append(thing)
	return things


## Whether this build holds the file at [param path]: a resource, imported or not, or a plain file
## packed as it is.
static func holds(path: String) -> bool:
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)


## The models, written out as a list in a sentence: "A, B and C".
static func models_in_words() -> String:
	if MODELS.size() == 1:
		return MODELS[0]
	return "%s and %s" % [", ".join(MODELS.slice(0, MODELS.size() - 1)), MODELS[-1]]
