class_name Lang
extends RefCounted
## The languages the game speaks, GAME.md 10.9. Every word is written in English, the source
## language, and goes through [method Object.tr] where it is written, or [method t] from a static
## function; each other language is a gettext file in [constant FOLDER] that the engine loads at
## start, made from the words the code holds by `make strings`. A language with no word for
## something says it in English.
##
## Which language is spoken is the player's choice in the settings, or with none chosen the one
## Steam is set to for the game, or else the system's. It is applied once, at start and again when
## it is chosen; nothing drawn already is drawn again, so whatever is on screen is built again.

## English, the language every word is written in and the one spoken with no other.
const ENGLISH := "en"
## Each language the game knows, by its locale, named as it names itself, in the order the settings
## list them. A language is offered only once its translation is in the project, see
## [method spoken]. NO_TRANSLATE: each is named in its own language whatever is spoken.
const NAMES: Dictionary[String, String] = {
	ENGLISH: "English",
	"nl": "Nederlands",
	"zh_CN": "简体中文",
}
## The locale of each language by the name Steam gives it, as Steam says which one its player has
## the game in.
const STEAM_NAMES: Dictionary[String, String] = {
	"english": ENGLISH,
	"dutch": "nl",
	"schinese": "zh_CN",
}
## Where the translations are kept, a gettext .po file for each language named by its locale.
const FOLDER := "res://data/locale"

## The locale of the language spoken now.
static var current := ENGLISH


## The languages there are a translation into, English first, by locale.
static func spoken() -> Array[String]:
	var loaded := TranslationServer.get_loaded_locales()
	var found: Array[String] = []
	for locale: String in NAMES:
		if locale == ENGLISH or locale in loaded:
			found.append(locale)
	return found


## The language to speak: [param chosen] if the game speaks it, or with none chosen the one Steam
## says, [param steam] as Steam names it, or else the system's [param system] locale, by its
## language alone where its country has no translation of its own; English if the game speaks
## none of them. Chinese is matched by script, Simplified for the mainland and Singapore, as
## Taiwan, Hong Kong and Macau read Traditional. [param known] stands in for [method spoken].
static func resolve(
	chosen: String, steam: String, system: String, known: Array[String] = []
) -> String:
	if known.is_empty():
		known = spoken()
	if chosen in known:
		return chosen
	for wanted: String in [STEAM_NAMES.get(steam, ""), system]:
		var locale := _matched(wanted, known)
		if not locale.is_empty():
			return locale
	return ENGLISH


static func _matched(wanted: String, known: Array[String]) -> String:
	var parts := wanted.replace("-", "_").get_slice(".", 0).split("_")
	var language := parts[0].to_lower()
	if language.is_empty():
		return ""
	if language == "zh":
		var simplified := true
		for part: String in parts.slice(1):
			if part.to_upper() in ["TW", "HK", "MO", "HANT"]:  # NO_TRANSLATE
				simplified = false
		return "zh_CN" if simplified and "zh_CN" in known else ""
	for locale: String in known:
		if locale.get_slice("_", 0) == language:
			return locale
	return ""


## Speaks [param locale] from now on.
static func apply(locale: String) -> void:
	current = locale if locale in NAMES else ENGLISH
	TranslationServer.set_locale(current)


## What [param locale] is called, in itself.
static func name_of(locale: String) -> String:
	return NAMES.get(locale, locale)


## [param text] in the language spoken, for a static function, which has no [method Object.tr];
## [param context] tells apart two meanings of the same English word.
static func t(text: String, context := &"") -> String:
	return TranslationServer.translate(text, context)


## [param one] or [param many] in the language spoken, as [param count] asks, for a static
## function, which has no [method Object.tr_n].
static func tn(one: String, many: String, count: int, context := &"") -> String:
	return TranslationServer.translate_plural(one, many, count, context)


## [param text] as it is, marked to be translated where it is shown rather than where it is
## written: words sent to another machine, which shows them in its own language, or kept for
## later. `make strings` finds it as it finds [method Object.tr].
static func later(text: String, _context := &"") -> String:
	return text


## [param value] with its thousands set apart as the language spoken sets them: 1,204,388 in
## English, 1.204.388 in Dutch.
static func number(value: int) -> String:
	var digits := str(absi(value))
	var mark := Lang.t(",", &"thousands")
	var grouped := ""
	while digits.length() > 3:
		grouped = mark + digits.right(3) + grouped
		digits = digits.left(digits.length() - 3)
	return ("-" if value < 0 else "") + digits + grouped


## [param value] to [param places] decimal places, with the decimal mark of the language spoken:
## 1.5 in English, 1,5 in Dutch.
static func decimal(value: float, places := 1) -> String:
	return (("%." + str(places) + "f") % value).replace(".", Lang.t(".", &"decimal"))


## [param place] as a place is written, in capitals as the House prints it: 1ST, 2ND, 3RD, 4TH,
## 11TH in English, 1E and 2E in Dutch. Lower it for a place in a sentence.
static func ordinal(place: int) -> String:
	# TRANSLATORS: A place at a table, in capitals: 1ST, 2ND, 3RD, 4TH, 11TH; lowered in a sentence.
	var forms: Array[String] = [
		Lang.t("%dTH", &"ordinal"),
		Lang.t("%dST", &"ordinal"),
		Lang.t("%dND", &"ordinal"),
		Lang.t("%dRD", &"ordinal"),
	]
	var form := 0
	if (place % 100 < 11 or place % 100 > 13) and place % 10 <= 3:
		form = place % 10
	return forms[form] % place


## The picture at [param path] with its words in the language spoken: the one the art tools drew
## for it beside it, <name>.<locale>.png, see tools/baked_words.py, or the picture itself.
static func picture(path: String) -> Texture2D:
	var own := "%s.%s.%s" % [path.get_basename(), current, path.get_extension()]
	return load(own if current != ENGLISH and ResourceLoader.exists(own) else path)


## [param items] as a list in a sentence: "a", "a and b", "a, b and c".
static func listed(items: Array) -> String:
	if items.is_empty():
		return ""
	if items.size() == 1:
		return str(items[0])
	var before: Array[String] = []
	for item: Variant in items.slice(0, -1):
		before.append(str(item))
	var joined := Lang.t(", ", &"list").join(before)
	return Lang.t("{some} and {last}").format({"some": joined, "last": str(items[-1])})
