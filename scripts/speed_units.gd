class_name SpeedUnits
extends RefCounted
## How the speedometer counts, GAME.md 8.3 and 8.5: kilometers an hour or miles an hour. The player
## chooses in the settings; until they do, the country of the system's locale says, mph only where
## the roads are signed in miles an hour. A locale with no country in it, English on its own say,
## says nothing either way, and that is km/h: English is spoken on a great many roads signed in
## kilometers. Where the system keeps its measures apart from its language, as Linux does in
## LC_MEASUREMENT, those are the ones asked: a machine in English with Dutch measures counts in
## km/h.

const KMH := "kmh"
const MPH := "mph"
## What the HUD writes beside the number, see [SpeedDial].
const KMH_WORD := "KM/H"
const MPH_WORD := "MPH"
## Miles in a kilometer.
const MILES_PER_KM := 0.621371
## The countries and territories whose roads are signed in miles an hour, by their ISO 3166 code:
## the United States and its territories, the United Kingdom, its Crown Dependencies and overseas
## territories that drive in miles, Liberia, and the Caribbean states that kept them.
const MPH_COUNTRIES: Array[String] = [
	"US",
	"PR",
	"GU",
	"VI",
	"AS",
	"MP",
	"UM",
	"GB",
	"IM",
	"JE",
	"GG",
	"AI",
	"VG",
	"KY",
	"MS",
	"TC",
	"FK",
	"SH",
	"LR",
	"AG",
	"BS",
	"BZ",
	"DM",
	"GD",
	"KN",
	"LC",
	"VC",
]


## Whether the system's locale, [param locale] as the system names it, "en_US", "en-GB",
## "en_US.UTF-8", is of a country whose roads are signed in miles an hour. False for one that names
## no country.
static func locale_uses_mph(locale: String) -> bool:
	var named := locale.get_slice(".", 0).get_slice("@", 0).replace("-", "_")
	var parts := named.split("_", false)
	for i: int in range(1, parts.size()):
		var part := parts[i].to_upper()
		# The country is the part of two letters; a script, "Latn", or a region, "419", is not.
		if part.length() == 2 and part.to_lower() != part:
			return part in MPH_COUNTRIES
	return false


## The locale the system's measures are in: LC_ALL, then LC_MEASUREMENT, then LANG, as POSIX
## looks for a category, where the system has them, and otherwise the system's own locale.
static func system_locale() -> String:
	for named: String in ["LC_ALL", "LC_MEASUREMENT", "LANG"]:
		var value := OS.get_environment(named).strip_edges()
		if not value.is_empty() and value != "C" and value != "POSIX":
			return value
	return OS.get_locale()


## The unit [param chosen] says, or where nothing is chosen the one [param locale] says.
static func resolve(chosen: String, locale: String) -> String:
	if chosen == KMH or chosen == MPH:
		return chosen
	return MPH if locale_uses_mph(locale) else KMH


## [param kmh], kilometers an hour, in [param unit].
static func from_kmh(kmh: float, unit: String) -> float:
	return kmh * MILES_PER_KM if unit == MPH else kmh


## What is written beside the number for [param unit].
static func word(unit: String) -> String:
	return MPH_WORD if unit == MPH else KMH_WORD
