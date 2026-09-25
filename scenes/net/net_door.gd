class_name NetDoor
extends RefCounted
## Who a host lets into its game, GAME.md 10.3, and what somebody it turns away is told. A client
## knocks with its version and whether it has come to watch; the host lets it in on a version it
## plays with and with a seat for it, or a place in the stands for somebody watching. Kept apart
## from [NetSession] so that file stays about the connection rather than the door.

## How many clients may play, on top of the host, and how many may watch on top of them, with no
## kart of their own.
const MAX_CLIENTS := 3
const MAX_WATCHERS := 4


## Whether a game at [param theirs] can play with one at [param mine], GAME.md 10.3: the same
## major and minor version, whatever the patch. A patch release fixes things without changing
## what goes over the wire; anything else may well change it, and two games that disagree about
## what a snapshot says do not fail politely.
static func compatible(mine: String, theirs: String) -> bool:
	var a := mine.split(".")
	var b := theirs.split(".")
	if a.size() < 2 or b.size() < 2:
		return mine == theirs
	return a[0] == b[0] and a[1] == b[1]


## What a client says about itself as it knocks: its version, whether it has come to watch, and
## what it is called, which is all the host has to go on for somebody watching.
static func knock(version: String, watching: bool, named: String) -> Dictionary:
	return {"version": version, "watch": watching, "name": named}


## The host's answer to a client that said [param words]. [param no_seat] is whether the room it is
## in has no seat left, [param players] how many clients play here already and [param watchers]
## how many watch.
static func answer(
	version: String, words: Dictionary, no_seat: bool, players: int, watchers: int
) -> Dictionary:
	var playable := compatible(version, str(words.get("version", "?")))
	var watch := bool(words.get("watch", false))
	var full := no_seat or players >= MAX_CLIENTS
	if watch:
		full = watchers >= MAX_WATCHERS
	return {"version": version, "welcome": playable and not full, "full": full, "watch": watch}


## What a client with [param version] turned away with the host's [param words] is told.
static func refusal(version: String, words: Dictionary) -> String:
	var theirs := str(words.get("version", "?"))
	if not compatible(version, theirs):
		return "Wrong version: the host has %s, you have %s" % [theirs, version]
	if bool(words.get("full", false)):
		if bool(words.get("watch", false)):
			return "As many are watching as the match can take"
		return "The match is full"
	return "The host turned you away"
