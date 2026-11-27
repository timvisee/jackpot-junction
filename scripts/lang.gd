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
## The fields of words packed for another machine by [method message] and [method message_n], each
## a name on the wire, GAME.md 10.3: the English, the plural's, the count, the values for the
## placeholders and the context. They stay as they are from version to version; a later one may
## add a field, which an earlier one leaves out, so a change to the words never needs a new
## protocol.
const WORDS := "words"
const MANY := "many"
const COUNT := "count"
const VALUES := "values"
const CONTEXT := "context"

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


## [param text] in [param locale], whatever language is spoken: for words the game hands Steam,
## which shows each player their own; English where [param locale] has no words for it.
static func t_in(locale: String, text: String, context := &"") -> String:
	var translation := TranslationServer.get_translation_object(locale)
	if locale == ENGLISH or translation == null or translation.locale != locale:
		return text
	var words := String(translation.get_message(text, context))
	return text if words.is_empty() else words


## Every language Steam is handed words in, by the name Steam gives it, with its locale: English
## and each other the game speaks, in the order of [constant STEAM_NAMES].
static func on_steam() -> Dictionary[String, String]:
	var known := spoken()
	var found: Dictionary[String, String] = {}
	for steam: String in STEAM_NAMES:
		if STEAM_NAMES[steam] in known:
			found[steam] = STEAM_NAMES[steam]
	return found


## [param one] or [param many] in the language spoken, as [param count] asks, for a static
## function, which has no [method Object.tr_n].
static func tn(one: String, many: String, count: int, context := &"") -> String:
	return TranslationServer.translate_plural(one, many, count, context)


## [param text] as it is, marked to be translated where it is shown rather than where it is
## written: words sent to another machine, which shows them in its own language with
## [method said], or kept for later. `make strings` finds it as it finds [method Object.tr]. Words
## with a value in them go with [method message] instead.
static func later(text: String, _context := &"") -> String:
	return text


## [param text] for another machine to say in its own language with [method said], with
## [param values] for the {placeholders} in it: the English and the values packed together, as a
## value put into the English here would make words nobody has a translation for, GAME.md 10.9.
## `make strings` finds [param text] as it finds [method Object.tr]. A value is said as
## [method said] says it: a number as the language writes one, words packed here said in turn, and
## anything else, a player's name, as it is.
static func message(text: String, values := {}, context := &"") -> String:
	return _packed({WORDS: text}, values, context)


## [param one] or [param many] for another machine to say as [param count] asks, see
## [method message]; {count} in either is [param count], written as the language writes it.
static func message_n(
	one: String, many: String, count: int, values := {}, context := &""
) -> String:
	return _packed({WORDS: one, MANY: many, COUNT: count}, values, context)


static func _packed(words: Dictionary, values: Dictionary, context: StringName) -> String:
	if not values.is_empty():
		words[VALUES] = values
	if not context.is_empty():
		words[CONTEXT] = String(context)
	return JSON.stringify(words)


## [param words] that came from another machine, or were kept for later, said in the language
## spoken: packed by [method message] or [method message_n], or English marked with [method later]
## and looked up as it is, which anything else that is not packed is too.
static func said(words: String) -> String:
	var packed := _unpacked(words)
	if packed.is_empty():
		return t(words)
	var context := StringName(str(packed.get(CONTEXT, "")))
	var values := {}
	var given: Variant = packed.get(VALUES, {})
	if given is Dictionary:
		for key: Variant in given:
			values[str(key)] = _value_said((given as Dictionary)[key])
	var text := str(packed[WORDS])
	if packed.has(MANY):
		var count := roundi(float(packed.get(COUNT, 0)))
		values[COUNT] = number(count)
		return tn(text, str(packed[MANY]), count, context).format(values)
	return t(text, context).format(values)


## [param words] as [method message] packed them, or empty for anything else.
static func _unpacked(words: String) -> Dictionary:
	if not words.begins_with("{"):
		return {}
	var json := JSON.new()
	if json.parse(words) != OK or not json.data is Dictionary:
		return {}
	var packed: Dictionary = json.data
	return packed if packed.get(WORDS) is String else {}


## A value for a placeholder, as [method said] says it. A number comes over the wire as JSON's, the
## same for 3 as for 3.0, so a whole one is written as a whole number.
static func _value_said(value: Variant) -> String:
	if value is float or value is int:
		var figure := float(value)
		if is_equal_approx(figure, roundf(figure)):
			return number(roundi(figure))
		return String.num(figure, 2).replace(".", Lang.t(".", &"decimal"))
	if value is String and not _unpacked(value).is_empty():
		return said(value)
	return str(value)


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
