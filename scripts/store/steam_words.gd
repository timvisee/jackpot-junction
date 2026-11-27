class_name SteamWords
extends RefCounted
## Words other players wrote, as the player is let see them, GAME.md 10.8: in a Steam build, names,
## kart plates and the names of games go through Steam's text filter as they come in from the
## wire or off the list of games, by this player's own Steam setting; anywhere else, as written.
## What the filter said of a word is kept, so a name read every frame asks Steam once.

## GodotSteam's TEXT_FILTERING_CONTEXT_*: a name, a player's or a game's, and anything else a player
## wrote for others to see.
const NAME := 3
const GAME_CONTENT := 1
## How many answers are kept before the lot is forgotten and asked again.
const MOST_KEPT := 512

static var _kept: Dictionary[String, String] = {}


## [param text] as the player is let see it, written by the account [param source], 0 for one not
## known, as a [param context]: Steam's filter's word for it, or the text itself without Steam.
static func heard(text: String, source := 0, context := NAME) -> String:
	if text.is_empty() or Store.steam == null:
		return text
	var key := "%d|%d|%s" % [context, source, text]
	if _kept.has(key):
		return _kept[key]
	var said := Store.steam.filter_text(context, source, text)
	if _kept.size() >= MOST_KEPT:
		_kept.clear()
	_kept[key] = said
	return said


## Every answer forgotten, for a Steam whose setting may have changed: a test's.
static func forget() -> void:
	_kept.clear()
