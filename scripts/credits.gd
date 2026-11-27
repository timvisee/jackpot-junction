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
## The models that made it, in the order they worked on it, all of them Anthropic's. NO_TRANSLATE:
## their names.
const MODELS: Array[String] = ["Claude Fable 5.1", "Claude Opus 5", "Claude Opus 5.5"]
## LXGW WenKai's own line, too long for one of the table's. NO_TRANSLATE: the license file's.
const WENKAI_COPYRIGHT := (
	"2021-2026 LXGW (https://github.com/lxgw/LxgwWenKai), with Reserved Font Name"
	+ " '霞鹜', '霞鶩', '落霞孤鹜', '落霞孤鶩' and 'LXGW'"
)

## What the game is built with and from: what it is, who made it, on what terms, and where. And so
## a build lists only what it holds, see [method in_this_build]: `files`, the res:// paths of it,
## one of which a build that holds it has; `steam`, for what only a Steam build has, GAME.md 10.8;
## and `music`, for music, which a build from the public repository alone does not have, see
## [constant Audio.TRACKS]. Without any of the three it is in every build. And for the notices,
## see [Licenses]: `license`, the key in [method Engine.get_license_info] of the terms' text, and
## `copyright`, the lines of it, as the license files beside the files give them, without the
## word Copyright. What it is and its terms are shown through tr() where they are more than a
## name; the names of people, things and places are left as they are, and so are the notices'
## keys and lines, which are the license files' own.
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
		"license": "CC0-1.0",  # NO_TRANSLATE
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
		"license": "OFL-1.1",  # NO_TRANSLATE
		"copyright": ["2017 The Barlow Project Authors (https://github.com/jpt/barlow)"],
	},
	{
		"what": "Inter typeface, for the letters Barlow does not draw",
		"who": "Rasmus Andersson and the Inter Project Authors",
		"terms": "SIL Open Font License 1.1",
		"where": "rsms.me/inter",
		"files": ["res://assets/fonts/Inter-Regular.ttf"],
		"license": "OFL-1.1",  # NO_TRANSLATE
		"copyright": ["2020 The Inter Project Authors (https://github.com/rsms/inter)"],
	},
	{
		"what": "Homemade Apple typeface, for a signature",
		"who": "Font Diner",
		"terms": "Apache License 2.0",
		"where": "fonts.google.com/specimen/Homemade+Apple",
		"files": ["res://assets/fonts/HomemadeApple-Regular.ttf"],
		"license": "Apache-2.0",  # NO_TRANSLATE
		# Its license file is the license alone; the line is the font's own, from its name table.
		"copyright": ["2010 Font Diner, Inc."],  # NO_TRANSLATE
	},
	{
		"what": "Caveat typeface, for notes in pencil",
		"who": "The Caveat Project Authors",
		"terms": "SIL Open Font License 1.1",
		"where": "github.com/googlefonts/caveat",
		"files": ["res://assets/fonts/Caveat-Variable.ttf"],
		"license": "OFL-1.1",  # NO_TRANSLATE
		"copyright": ["2014 The Caveat Project Authors (https://github.com/googlefonts/caveat)"],
	},
	{
		"what": "Kalam typeface, for another hand",
		"who": "Indian Type Foundry",
		"terms": "SIL Open Font License 1.1",
		"where": "fonts.google.com/specimen/Kalam",
		"files": ["res://assets/fonts/Kalam-Regular.ttf"],
		"license": "OFL-1.1",  # NO_TRANSLATE
		"copyright": ["2014, Indian Type Foundry (info@indiantypefoundry.com)"],  # NO_TRANSLATE
	},
	{
		"what": "Patrick Hand typeface, for a third hand",
		"who": "Patrick Wagesreiter",
		"terms": "SIL Open Font License 1.1",
		"where": "fonts.google.com/specimen/Patrick+Hand",
		"files": ["res://assets/fonts/PatrickHand-Regular.ttf"],
		"license": "OFL-1.1",  # NO_TRANSLATE
		"copyright": ["2010-2012 Patrick Wagesreiter (mail@patrickwagesreiter.at)"],  # NO_TRANSLATE
	},
	{
		"what": "Reenie Beanie typeface, for a line scratched with a point",
		"who": "James Grieshaber",
		"terms": "SIL Open Font License 1.1",
		"where": "fonts.google.com/specimen/Reenie+Beanie",
		"files": ["res://assets/fonts/ReenieBeanie-Regular.ttf"],
		"license": "OFL-1.1",  # NO_TRANSLATE
		"copyright": ["2010, James Grieshaber (james@typeco.com)"],  # NO_TRANSLATE
	},
	{
		"what": "Permanent Marker typeface, for a marker pen",
		"who": "Font Diner",
		"terms": "Apache License 2.0",
		"where": "fonts.google.com/specimen/Permanent+Marker",
		"files": ["res://assets/fonts/PermanentMarker-Regular.ttf"],
		"license": "Apache-2.0",  # NO_TRANSLATE
		# As Homemade Apple's: the font's own line, from its name table.
		"copyright": ["2010 Font Diner, Inc."],  # NO_TRANSLATE
	},
	{
		"what": "Courier Prime typeface, for everything typed",
		"who": "Alan Dague-Greene and the Courier Prime Project Authors",
		"terms": "SIL Open Font License 1.1",
		"where": "github.com/quoteunquoteapps/CourierPrime",
		"files": ["res://assets/fonts/CourierPrime-Regular.ttf"],
		"license": "OFL-1.1",  # NO_TRANSLATE
		"copyright":
		[
			(
				"2015 The Courier Prime Project Authors"  # NO_TRANSLATE
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
		"license": "OFL-1.1",  # NO_TRANSLATE
		"copyright": ["2010, Igino Marini (mail@iginomarini.com)"],  # NO_TRANSLATE
	},
	{
		"what": "Noto Sans SC typeface, for Chinese beside Barlow",
		"who": "Adobe and Google",
		"terms": "SIL Open Font License 1.1",
		"where": "fonts.google.com/noto/specimen/Noto+Sans+SC",
		"files":
		[
			"res://assets/fonts/chinese/NotoSansSC-Medium.ttf",
			"res://assets/fonts/chinese/NotoSansSC-Bold.ttf",
			"res://assets/fonts/chinese/NotoSansSC-Black.ttf",
		],
		"license": "OFL-1.1",  # NO_TRANSLATE
		"copyright":
		[
			"2014-2021 Adobe (http://www.adobe.com/), with Reserved Font Name 'Source'",  # NO_TRANSLATE
		],
	},
	{
		"what": "Noto Serif SC typeface, for Chinese typed",
		"who": "Adobe and Google",
		"terms": "SIL Open Font License 1.1",
		"where": "fonts.google.com/noto/specimen/Noto+Serif+SC",
		"files": ["res://assets/fonts/chinese/NotoSerifSC-Regular.ttf"],
		"license": "OFL-1.1",  # NO_TRANSLATE
		"copyright": ["2012 Google Inc. All Rights Reserved."],  # NO_TRANSLATE
	},
	{
		"what": "ZCOOL XiaoWei typeface, for Chinese in an old book",
		"who": "Li Dawei and ZCOOL",
		"terms": "SIL Open Font License 1.1",
		"where": "fonts.google.com/specimen/ZCOOL+XiaoWei",
		"files": ["res://assets/fonts/chinese/ZCOOLXiaoWei-Regular.ttf"],
		"license": "OFL-1.1",  # NO_TRANSLATE
		"copyright":
		[
			(
				"2018 The ZCOOL XiaoWei Project Authors"  # NO_TRANSLATE
				+ " (https://github.com/googlefonts/zcool-xiaowei/)"
			),
		],
	},
	{
		"what": "LXGW WenKai typeface, for Chinese in pencil",
		"who": "LXGW and the Klee Project Authors",
		"terms": "SIL Open Font License 1.1",
		"where": "github.com/lxgw/LxgwWenKai",
		"files": ["res://assets/fonts/chinese/WenKai-Regular.ttf"],
		"license": "OFL-1.1",  # NO_TRANSLATE
		"copyright":
		[
			WENKAI_COPYRIGHT,
			"2020 The Klee Project Authors (https://github.com/fontworks-fonts/Klee)",  # NO_TRANSLATE
		],
	},
	{
		"what": "Xiaolai typeface, for Chinese in another hand",
		"who": "LXGW and Nozomi Seto",
		"terms": "SIL Open Font License 1.1",
		"where": "github.com/lxgw/kose-font",
		"files": ["res://assets/fonts/chinese/Xiaolai-Regular.ttf"],
		"license": "OFL-1.1",  # NO_TRANSLATE
		"copyright":
		[
			"2020-2024 LXGW (https://github.com/lxgw/kose-font)",  # NO_TRANSLATE
			"2014 Nozomi Seto (https://ja.osdn.net/projects/setofont/)",  # NO_TRANSLATE
		],
	},
	{
		"what": "Long Cang typeface, for Chinese in a third hand and scratched",
		"who": "Chen Xiaomin",
		"terms": "SIL Open Font License 1.1",
		"where": "fonts.google.com/specimen/Long+Cang",
		"files": ["res://assets/fonts/chinese/LongCang-Regular.ttf"],
		"license": "OFL-1.1",  # NO_TRANSLATE
		"copyright":
		[
			"2018 The Long Cang Project Authors (https://github.com/googlefonts/longcang)",  # NO_TRANSLATE
		],
	},
	{
		"what": "Zhi Mang Xing typeface, for a signature in Chinese",
		"who": "Wei Zhimang",
		"terms": "SIL Open Font License 1.1",
		"where": "fonts.google.com/specimen/Zhi+Mang+Xing",
		"files": ["res://assets/fonts/chinese/ZhiMangXing-Regular.ttf"],
		"license": "OFL-1.1",  # NO_TRANSLATE
		"copyright":
		[
			(
				"2018 The Zhi Mang Xing Project Authors"  # NO_TRANSLATE
				+ " (https://github.com/googlefonts/zhimangxing)"
			),
		],
	},
	{
		"what": "ZCOOL KuaiLe typeface, for Chinese in marker",
		"who": "Liu Bingke, Yang Kang and Wu Shaojie",
		"terms": "SIL Open Font License 1.1",
		"where": "fonts.google.com/specimen/ZCOOL+KuaiLe",
		"files": ["res://assets/fonts/chinese/ZCOOLKuaiLe-Regular.ttf"],
		"license": "OFL-1.1",  # NO_TRANSLATE
		"copyright":
		[
			(
				"2018 The ZCOOL KuaiLe Project Authors"  # NO_TRANSLATE
				+ " (https://github.com/googlefonts/zcool-kuaile)"
			),
		],
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
		"license": "CC0-1.0",  # NO_TRANSLATE
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
		"license": "Apache-2.0",  # NO_TRANSLATE
		# Google publishes them under the license alone, with no line of whose they are.
		"copyright": [],  # NO_TRANSLATE
	},
	{
		"what": "gdUnit4, the tests' framework",
		"who": "Mike Schulze",
		"terms": "MIT license",
		"where": "github.com/MikeSchulze/gdUnit4",
		# Never exported, so only a game run from the project credits it.
		"files": ["res://addons/gdUnit4/plugin.gd"],
		"license": "Expat",  # NO_TRANSLATE
		"copyright": ["2023 Mike Schulze"],  # NO_TRANSLATE
	},
	{
		"what": "GodotSteam, the way to Steam",
		"who": "GP Garcia, Chris Ridenour and contributors",
		"terms": "MIT license",
		"where": "godotsteam.com",
		"steam": true,
		"license": "Expat",  # NO_TRANSLATE
		"copyright": ["2015-Current, GP Garcia, Chris Ridenour, and Contributors"],  # NO_TRANSLATE
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


## The models, written out as a list in a sentence in the language spoken: "A, B and C".
static func models_in_words() -> String:
	return Lang.listed(MODELS)
