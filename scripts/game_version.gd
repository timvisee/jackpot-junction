class_name GameVersion
extends RefCounted
## Which version of the game this is, and which others it plays with, GAME.md 10.3. On its own,
## apart from [Game] and [NetDoor], because a dedicated server's hall asks both questions and loads
## nothing else of the game, see [GameTree].


## This game's version, from project.godot.
static func current() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "dev"))


## Whether a game at [param theirs] can play with one at [param mine]: the same major and minor
## version, whatever the patch. A patch release fixes things without changing what goes over the
## wire; anything else may well change it, and two games that disagree about what a snapshot says
## do not fail politely.
static func compatible(mine: String, theirs: String) -> bool:
	var a := mine.split(".")
	var b := theirs.split(".")
	if a.size() < 2 or b.size() < 2:
		return mine == theirs
	return a[0] == b[0] and a[1] == b[1]
