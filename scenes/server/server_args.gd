class_name ServerArgs
extends RefCounted
## How a dedicated server was started, GAME.md 9.3a: the game's own arguments after `--`, with
## `--server` among them. The port players connect to and how many games it holds at once, whose
## ports follow its own; and in a game the server has started, which one it is, the port it is
## played on and where the server hears from it.

## The port players connect to unless told otherwise, clear of a LAN game's 7777 and the 7779 LAN
## games are found on, so a server and a LAN game can share a machine.
const PORT := 7780
## How many games a server holds at once unless told otherwise. Each is a process of its own, a
## quarter of a gigabyte or so, see GAME.md 9.3a.
const GAMES := 8

## Whether the game is to be a dedicated server at all.
var server := false
var port := PORT
var games := GAMES
## In a game of the server's: its number, from 1, and where the server hears from it, a port on this
## machine, with the key its word is taken on. 0 in the server itself.
var game := 0
var report := 0
var key := ""


static func read(args: PackedStringArray) -> ServerArgs:
	var read := ServerArgs.new()
	for arg: String in args:
		var value := arg.get_slice("=", 1)
		if arg == "--server":
			read.server = true
		elif arg.begins_with("--port="):
			read.port = int(value) if value.is_valid_int() else -1
		elif arg.begins_with("--games="):
			read.games = int(value) if value.is_valid_int() else -1
		elif arg.begins_with("--game="):
			read.game = int(value)
		elif arg.begins_with("--report="):
			read.report = int(value)
		elif arg.begins_with("--key="):
			read.key = value
	return read


## Whether the game was started as a server.
static func asked() -> bool:
	return "--server" in OS.get_cmdline_user_args()


## What is wrong with the arguments, for the server to say before it gives up, or nothing.
func problem() -> String:
	if games < 1 or games > 100:
		return "--games must be between 1 and 100"
	if port < 1 or port + games > 65535:
		return "--port must leave room for its games' ports below 65536"
	return ""


## The ports the games are played on: the ones after the server's own.
func game_ports() -> Array[int]:
	var ports: Array[int] = []
	for i: int in games:
		ports.append(port + 1 + i)
	return ports
