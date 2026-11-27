class_name Licenses
extends RefCounted
## The notices a build carries, GAME.md 8.5 and 9.3a: Godot's own license, the copyright and license
## of every piece Godot carries inside it, and of the game's own third-party pieces, see [Credits],
## then each license's text once. Godot's guide asks a game for its MIT text; the pieces are
## "compatible with, but not covered by" it, and some ask for their own notice in every copy, as
## FreeType's credit line, the BSD lines of libvorbis, and the Apache-2.0 text of Mbed TLS.
##
## The About page shows them in a fold, a dedicated server on its web page, and `--licenses` prints
## them. Everything comes from the engine's own table, [method Engine.get_copyright_info] and
## [method Engine.get_license_info], so it follows the engine on each upgrade, less what no build of
## this game carries, see [constant NOT_SHIPPED] and [constant PLATFORMS]. Safe in a dedicated
## server's hall, which has none of the game's autoloads.

## Prints the notices and quits, in the game and in a dedicated server, see boot.gd.
const FLAG := "--licenses"
## The pieces of Godot that are in no build of a game, by name, each with why: Godot 4.7.2's build
## files leave them out of export templates. A test holds each name to the engine's list, so an
## upgrade that renames or drops one says so. NO_TRANSLATE: the engine's names and notes for us.
const NOT_SHIPPED := {
	"Linux AppStream Metadata File": "the editor's Linux package metadata, built into nothing",
	"Godot Engine logo": "the logo's artwork in Godot's source tree, built into nothing",
	"Betsy": "texture compression on import; in templates only with betsy_export_templates",
	"Convection Texture Tools Stand-Alone Kernels":
	"texture compression on import; in templates only with cvtt_export_templates",
	"Joint Non-Local Means (JNLM) denoiser":
	"the lightmapper's, lightmapper_rd: editor builds only",
	"xatlas": "UV unwrapping for lightmaps, xatlas_unwrap: editor builds only",
	"doctest": "Godot's own unit tests, built with tests=yes only",
	"DroidSans font": "the editor's, built by editor/themes",
	"Inter font": "the editor's copy, built by editor/themes; the game credits its own Inter",
	"JetBrains Mono font": "the editor's code font, built by editor/themes",
	"Noto Sans font": "the editor's, built by editor/themes",
	"Vazirmatn font": "the editor's, built by editor/themes",
}
## The pieces of Godot that only some platforms' builds carry, by name, with the names
## [method OS.get_name] gives those platforms, as Godot 4.7.2's platform build files have them.
## NO_TRANSLATE: names.
const PLATFORMS := {
	"AccessKit": ["Windows", "macOS", "Linux"],
	"SDL": ["Windows", "macOS", "Linux", "iOS", "visionOS"],
	"hidapi": ["Windows", "macOS", "Linux", "iOS", "visionOS"],
	"ANGLE": ["Windows", "macOS"],
	"D3D12 Memory Allocator": ["Windows"],
	"DirectX Headers": ["Windows"],
	"NVIDIA NVAPI (minimal excerpt)": ["Windows"],
	"mingw-std-threads": ["Windows"],
	"metal-cpp": ["macOS", "iOS", "visionOS"],
	"SPIRV-Cross": ["macOS", "iOS", "visionOS"],
	"The Android Open Source Project": ["Android"],
	"ProcessPhoenix": ["Android"],
	"Swappy": ["Android"],
	"libjingle": ["Android"],
	"Wayland core protocol": ["Linux"],
	"Wayland protocols": ["Linux"],
	"Mesa Wayland protocols": ["Linux"],
}
## Words a piece's license joins its keys with, "Apache-2.0 or Expat", which are no key.
const JOINS: Array[String] = ["and", "or"]


## The pieces of Godot a build for [param os] carries, this platform's but in a test, as
## [method Engine.get_copyright_info] gives them: each a name and its parts, each part its
## copyright lines and its license. Godot itself is not among them, its license being shown whole.
static func pieces(os := OS.get_name()) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for piece: Dictionary in Engine.get_copyright_info():
		var name: String = piece["name"]
		if name == "Godot Engine" or NOT_SHIPPED.has(name):
			continue
		if PLATFORMS.has(name) and not (PLATFORMS[name] as Array).has(os):
			continue
		out.append(piece)
	return out


## The license keys that [param things], credits as [constant Credits.THINGS] has them, and
## [param of], pieces as [method pieces] gives them, name, each once and in order, but a key with
## no text in the engine's table, as "public-domain".
static func keys(things: Array[Dictionary], of: Array[Dictionary]) -> PackedStringArray:
	var texts := Engine.get_license_info()
	var named := PackedStringArray()
	for thing: Dictionary in things:
		if thing.has("license"):
			named.append(thing["license"])
	for piece: Dictionary in of:
		for part: Dictionary in piece["parts"]:
			named.append_array(keys_in(part["license"]))
	var out := PackedStringArray()
	for key: String in named:
		if texts.has(key) and not out.has(key):
			out.append(key)
	out.sort()
	return out


## The keys in one license as the engine writes it: "Apache-2.0 or Expat" is two.
static func keys_in(license: String) -> PackedStringArray:
	var out := PackedStringArray()
	for word: String in license.split(" ", false):
		if not JOINS.has(word):
			out.append(word)
	return out


## What a license is called where it is shown, a key or the engine's words for a piece's: as it is,
## but Expat said as the MIT license it is.
static func title(license: String) -> String:
	return license.replace("Expat", "MIT (Expat)")


## [param lines] of copyright as the engine and [Credits] keep them, without the word, each with it.
static func copyright(lines: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for line: String in lines:
		out.append("Copyright %s" % line)  # NO_TRANSLATE
	return out


## Every notice as plain text, for `--licenses`: the game's own terms and where its source is, what
## of [param things] carries terms, Godot's license, its pieces, and each license's text once. In
## English, as the console is, GAME.md 10.9; "Copyright" and the licenses' names are the notices'
## own in every language.
static func text(things: Array[Dictionary]) -> String:
	var of := pieces()
	var out := PackedStringArray()
	out.append("Jackpot Junction %s, licenses" % GameVersion.current())  # NO_TRANSLATE
	out.append("")
	out.append(own_terms())
	out.append("Source: %s" % Credits.REPOSITORY)  # NO_TRANSLATE
	out.append("")
	out.append("== Made with ==")  # NO_TRANSLATE
	for thing: Dictionary in things:
		if thing["what"] == "Godot Engine":  # NO_TRANSLATE
			continue
		# NO_TRANSLATE
		out.append(
			"%s, by %s, %s, %s" % [thing["what"], thing["who"], thing["terms"], thing["where"]]
		)
		for line: String in copyright(thing.get("copyright", [])):
			out.append("  " + line)
		if thing.has("license"):
			out.append("  License: %s" % title(thing["license"]))  # NO_TRANSLATE
	out.append("")
	out.append("== Godot Engine ==")  # NO_TRANSLATE
	out.append(Engine.get_license_text())
	out.append("== Inside Godot Engine ==")  # NO_TRANSLATE
	for piece: Dictionary in of:
		out.append(piece["name"])
		for part: Dictionary in piece["parts"]:
			for line: String in copyright(part["copyright"]):
				out.append("  " + line)
			out.append("  License: %s" % title(part["license"]))  # NO_TRANSLATE
	var texts := Engine.get_license_info()
	for key: String in keys(things, of):
		out.append("")
		out.append("== License: %s ==" % title(key))  # NO_TRANSLATE
		out.append(texts[key])
	return "\n".join(out)


## The game's own terms in a sentence; where its source is, [constant Credits.REPOSITORY], goes on
## a line of its own.
static func own_terms() -> String:
	# NO_TRANSLATE: the console's and a dedicated server's page's, which are English, GAME.md 10.9.
	return (
		"Jackpot Junction is free software under the GNU General Public License 3.0, and the assets"
		+ " made for it are under CC-BY-4.0."
	)
