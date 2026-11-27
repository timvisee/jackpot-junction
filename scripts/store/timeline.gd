class_name Timeline
extends RefCounted
## The timeline of Steam's game recording, GAME.md 10.8: the moments of a match marked on it, each
## with an icon, and each Grand Prix a game phase of it, tagged with its mode, its maps and how it
## went. What every moment is drawn with is kept here, as GAME.md 10.8's table has it; [SteamStore]
## tells Steam, and with no Steam all of it goes nowhere. [TimelineRecord] hears the moments of a
## match, [SteamTimeline] where the game is.

## Steam's game modes, which color the timeline's bar: playing, waiting in a lobby, in the menus,
## and a loading screen.
const PLAYING := 1
const STAGING := 2
const MENUS := 3
const LOADING := 4
## Whether Steam offers a clip of a moment: never, maybe, or first of all.
const CLIP_NONE := 1
const CLIP_STANDARD := 2
const CLIP_FEATURED := 3
## Every moment the game marks, by GAME.md 10.8's table: its icon, how far up it is drawn when the
## timeline is crowded, 0 to 1000, and whether Steam offers a clip of it. An icon named `steam_` is
## Steam's own, its color after it; `jj_` one of the game's own, uploaded to Steamworks, see
## docs/STEAM.md.
const MARKS: Dictionary[StringName, Array] = {
	&"won_map": ["steam_trophy_yellow", 900, CLIP_FEATURED],
	&"won_grand_prix": ["steam_starburst_yellow", 950, CLIP_FEATURED],
	&"royal_flush": ["jj_royal_flush", 850, CLIP_FEATURED],
	&"three_sevens": ["jj_777", 850, CLIP_FEATURED],
	&"run_of_kills": ["steam_combat_red", 800, CLIP_FEATURED],
	&"payment_interrupted": ["steam_explosion_red", 800, CLIP_FEATURED],
	&"bounty_collected": ["steam_crown_yellow", 750, CLIP_FEATURED],
	&"last_one_standing": ["steam_person_yellow", 800, CLIP_FEATURED],
	&"took_the_lead": ["steam_bolt_yellow", 750, CLIP_FEATURED],
	&"winning_cash_out": ["steam_chest_green", 700, CLIP_FEATURED],
	&"final_hand": ["steam_star_purple", 1000, CLIP_FEATURED],
	&"kill": ["steam_attack", 300, CLIP_NONE],
	&"death": ["steam_death_red", 250, CLIP_NONE],
	&"cash_out": ["steam_purchase_green", 300, CLIP_NONE],
	&"match_point": ["steam_flag_orange", 600, CLIP_STANDARD],
	&"jackpot": ["steam_chest_yellow", 500, CLIP_STANDARD],
	&"streak": ["steam_bolt_orange", 550, CLIP_STANDARD],
	&"bounty_on_you": ["steam_crown_orange", 450, CLIP_NONE],
	&"hand": ["jj_cards", 450, CLIP_STANDARD],
	&"trade_kill": ["steam_transfer", 300, CLIP_NONE],
	&"slot_win": ["steam_gem_yellow", 350, CLIP_NONE],
	&"placed": ["steam_flag", 400, CLIP_NONE],
	&"bet_won": ["steam_ribbon_purple", 300, CLIP_NONE],
	&"showdown": ["steam_combat_orange", 600, CLIP_STANDARD],
	&"lesson": ["steam_completed_green", 500, CLIP_STANDARD],
	&"last_call": ["steam_timer_yellow", 400, CLIP_NONE],
	&"overtime": ["steam_caution_red", 650, CLIP_STANDARD],
}
## The game's own icons, uploaded to Steamworks under these names, docs/STEAM.md.
const OWN_ICONS: Array[String] = ["jj_royal_flush", "jj_777", "jj_cards"]
## A number in Steam's own icons, 0 to 99: a place, drawn as its figure.
const NUMBER_ICON := "steam_%d"  # NO_TRANSLATE
const MOST_NUMBER := 99
## The groups a game phase's tags are shown in, and its one line of words, shown through tr() as
## they are told to Steam, whose timeline shows them.
const MODE_GROUP := "Mode"
const MAPS_GROUP := "Maps"
const RESULT_GROUP := "Result"
const SCORE_GROUP := "Score"
## What a phase's tags are drawn with, the result's by how it went.
const MODE_ICON := "steam_flag"
const MAP_ICON := "steam_bookmark"
const WON_ICON := "steam_trophy_yellow"
const TAG_PRIORITY := 500

## The game phase being recorded, by what it is a phase of, empty for none, and the maps tagged on
## it so far.
static var _phase := ""
static var _maps: Array[String] = []


## Marks the moment [param id] of [constant MARKS] now, as [param title] over [param description],
## words in the language spoken, which Steam's timeline shows as they are, in its icon or [param
## icon] in its place. Steam's handle for it, 0 with no Steam.
static func mark(id: StringName, title: String, description := "", icon := "") -> int:
	if not Store.on():
		return 0
	var drawn: Array = MARKS[id]
	var shown: String = icon if not icon.is_empty() else drawn[0]
	return Store.steam.timeline_mark(title, description, shown, drawn[1], 0.0, drawn[2])


## Marks the stretch [param id] of [constant MARKS] whole, begun [param began_ago] seconds ago and
## ending now, as [param title] over [param description]. Steam's handle for it, 0 with no Steam.
static func span(id: StringName, title: String, description: String, began_ago: float) -> int:
	if not Store.on():
		return 0
	var drawn: Array = MARKS[id]
	var lasting := maxf(began_ago, 0.0)
	return Store.steam.timeline_span(
		title, description, drawn[0], drawn[1], -lasting, lasting, drawn[2]
	)


## Begins the stretch [param id] of [constant MARKS] now, left open until [method close] ends it.
## Steam's handle for it, 0 with no Steam.
static func open(id: StringName, title: String, description := "") -> int:
	if not Store.on():
		return 0
	var drawn: Array = MARKS[id]
	return Store.steam.timeline_open(title, description, drawn[0], drawn[1], drawn[2])


## Ends the stretch [param handle] now; nothing for 0, a stretch never begun.
static func close(handle: int) -> void:
	if handle != 0 and Store.on():
		Store.steam.timeline_close(handle)


## The icon of the place [param place], 1st and on: Steam's figure for it.
static func place_icon(place: int) -> String:
	return NUMBER_ICON % clampi(place, 0, MOST_NUMBER)


## The game phase of [param key], a Grand Prix or a map played alone, begun unless it is the one
## being recorded already, the one before it ended first; tagged with [param modes], what kind of
## play it is, in the language spoken.
static func begin_phase(key: String, modes: Array[String]) -> void:
	if key == _phase or not Store.on():
		return
	end_phase()
	_phase = key
	_maps.clear()
	Store.steam.phase_start("%s-%d" % [key, int(Time.get_unix_time_from_system())])
	for mode: String in modes:
		Store.steam.phase_tag(mode, MODE_ICON, Lang.t(MODE_GROUP), TAG_PRIORITY)


## [param map], its name in the language spoken, tagged on the game phase being recorded, once
## however often it is played in it.
static func phase_map(map: String) -> void:
	if _phase.is_empty() or map in _maps or not Store.on():
		return
	_maps.append(map)
	Store.steam.phase_tag(map, MAP_ICON, Lang.t(MAPS_GROUP), TAG_PRIORITY)


## How the game phase being recorded went, [param place] of [param sides], with [param score] for
## its line, in the language spoken: tagged "Won" or the place, and the line "3,120 points · 1st of
## 4".
static func phase_result(place: int, sides: int, score: String) -> void:
	if _phase.is_empty() or not Store.on():
		return
	var placed := ordinal(place)
	var won := place == 1
	var icon := WON_ICON if won else place_icon(place)
	# TRANSLATORS: How a game went, tagged on Steam's recording of it: won, or else the place.
	var result := Lang.t("Won") if won else placed
	Store.steam.phase_tag(result, icon, Lang.t(RESULT_GROUP), TAG_PRIORITY)
	var line := Lang.t("{score} · {place} of {sides}")
	line = line.format({"score": score, "place": placed, "sides": sides})
	Store.steam.phase_attribute(Lang.t(SCORE_GROUP), line, TAG_PRIORITY)


## Ends the game phase being recorded, if any.
static func end_phase() -> void:
	if _phase.is_empty():
		return
	_phase = ""
	_maps.clear()
	if Store.on():
		Store.steam.phase_end()


## What the game phase being recorded is a phase of, empty for none.
static func phase() -> String:
	return _phase


## A place in words, in the language spoken: 1st, 2nd, 3rd, 4th and on.
static func ordinal(place: int) -> String:
	# TRANSLATORS: A place in a race, 4th, and so for every number but those ending 1st, 2nd, 3rd.
	var words := Lang.t("%dth")
	if place % 100 < 11 or place % 100 > 13:
		match place % 10:
			1:
				words = Lang.t("%dst")
			2:
				words = Lang.t("%dnd")
			3:
				words = Lang.t("%drd")
	return words % place
