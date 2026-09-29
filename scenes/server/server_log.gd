class_name ServerLog
extends RefCounted
## What a dedicated server writes down, GAME.md 9.3a: a line for everybody who comes and goes, in
## the server and in each of its games, and for every change in how each game stands, with the time
## and which game it was.


## A line of the log, from [param who], the server or one of its games.
static func line(who: String, text: String) -> String:
	return "%s %s: %s" % [Time.get_datetime_string_from_system(false, true), who, text]


static func say(who: String, text: String) -> void:
	print(line(who, text))


## [param names] as a list in words: "Ann", "Ann and Bo", "Ann, Bo and Cy".
static func listed(names: Array[String]) -> String:
	if names.size() <= 1:
		return "".join(names)
	return "%s and %s" % [", ".join(names.slice(0, names.size() - 1)), names[-1]]
