class_name ServerArgs
extends RefCounted
## How a dedicated server was started, GAME.md 9.3a: the game's own arguments after `--`, with
## `--server` among them. The port players connect to, how many games it holds at once and the ports
## those are played on, which follow its own unless given, the name players see it by and the
## password they need to come in; and in a game the server has started, which one it is, the port
## it is played on and where the server hears from it.
##
## The server's settings may be given in the environment too, `JJ_PORT`, `JJ_GAMES`,
## `JJ_GAME_PORTS`, `JJ_NAME`, `JJ_PASSWORD`, `JJ_WEB_PORT` and `JJ_SITE`, which is how a container
## is told, see docker/compose.yaml. An argument on the command line has the last word over the
## same setting in the environment.

## The port players connect to unless told otherwise: the one a LAN game is hosted on, so a server
## is found where players already look. A LAN game on the server's own machine takes another.
const PORT := 7777
## How many games a server holds at once unless told otherwise. Each is a process of its own, a
## quarter of a gigabyte or so, see GAME.md 9.3a.
const GAMES := 8
## The most games a server holds at once, whatever it is told.
const MOST_GAMES := 100
## Each of the environment's settings, and the argument it stands for.
const ENVIRONMENT: Dictionary[String, String] = {
	"JJ_PORT": "--port",
	"JJ_GAMES": "--games",
	"JJ_GAME_PORTS": "--game-ports",
	"JJ_NAME": "--name",
	"JJ_PASSWORD": "--password",
	"JJ_WEB_PORT": "--web-port",
	"JJ_SITE": "--site",
}
## The longest password a server takes, the same as a lobby's, [constant NetDoor.PASSWORD_LENGTH].
const PASSWORD_LENGTH := 64

## Whether the game is to be a dedicated server at all: `--server`, or the dedicated server build,
## GAME.md 10.5, which is nothing else.
var server := OS.has_feature("dedicated_server")
var port := PORT
var games := GAMES
## The first and last of the ports games are played on, from `--game-ports=7778-7785`, or 0 for the
## ones after [member port]; -1 for a range that could not be read.
var first_game_port := 0
var last_game_port := 0
## What players see the server called, from `--name="Friday night"`, cleaned the way a game's name
## is; empty for none, and then it is its address.
var name := ""
## What players have to give to come in, from `--password=` or `JJ_PASSWORD`, GAME.md 9.3a: to see
## the server's games and make one, and to join one of them at its own port; empty for nobody asked.
## A game the server starts has it too, in the environment it is started with, see [ServerHall].
var password := ""
## The TCP port a browser reaches the server's web page on, see [ServerWeb], from `--web-port=` or
## `JJ_WEB_PORT`: -1 to serve it on [member port]'s number, the default, or 0 for no page at all.
var web_port := -1
## A link the web page points players at to get the game, from `--site=` or `JJ_SITE`, beside the
## itch.io and source links it always carries; empty for none of the operator's own.
var site := ""
## In a game of the server's: its number, from 1, and where the server hears from it, a port on this
## machine, with the key its word is taken on. 0 in the server itself.
var game := 0
var report := 0
var key := ""
## Whether [member games] was given rather than left to its default.
var _games_given := false


## This process's own: its environment, see [constant ENVIRONMENT], and its arguments over it.
static func of_this_process() -> ServerArgs:
	var environment := {}
	for name: String in ENVIRONMENT:
		if OS.has_environment(name):
			environment[name] = OS.get_environment(name)
	return read(OS.get_cmdline_user_args(), environment)


## [param args] as a server reads them, over [param environment]'s settings by the names in
## [constant ENVIRONMENT]. An empty setting is no setting, the way a compose file leaves one out.
static func read(args: PackedStringArray, environment := {}) -> ServerArgs:
	var read := ServerArgs.new()
	var given := PackedStringArray()
	for name: String in ENVIRONMENT:
		var value := str(environment.get(name, "")).strip_edges()
		if not value.is_empty():
			given.append("%s=%s" % [ENVIRONMENT[name], value])
	given.append_array(args)
	for arg: String in given:
		var value := arg.get_slice("=", 1)
		if arg == "--server":
			read.server = true
		elif arg.begins_with("--port="):
			read.port = int(value) if value.is_valid_int() else -1
		elif arg.begins_with("--games="):
			read.games = int(value) if value.is_valid_int() else -1
			read._games_given = true
		elif arg.begins_with("--game-ports="):
			read._read_game_ports(value)
		elif arg.begins_with("--name="):
			# All of it: a name may have an equals sign in it.
			read.name = PlayerNames.clean(arg.trim_prefix("--name="), PlayerNames.TITLE_LENGTH)
		elif arg.begins_with("--password="):
			read.password = arg.trim_prefix("--password=").strip_edges().left(PASSWORD_LENGTH)
		elif arg.begins_with("--web-port="):
			read.web_port = int(value) if value.is_valid_int() else -2
		elif arg.begins_with("--site="):
			read.site = arg.trim_prefix("--site=").strip_edges().left(PASSWORD_LENGTH * 4)
		elif arg.begins_with("--game="):
			read.game = int(value)
		elif arg.begins_with("--report="):
			read.report = int(value)
		elif arg.begins_with("--key="):
			read.key = value
	# A range with room for fewer than the games there would be is that many games, unless they were
	# asked for, which is then a problem to say.
	if read.first_game_port > 0 and not read._games_given:
		read.games = clampi(read.last_game_port - read.first_game_port + 1, 1, GAMES)
	return read


## Whether this process is a dedicated server's hall: `--server`, and no game of its own to run,
## see [GameTree].
static func runs_the_hall() -> bool:
	var args := read(OS.get_cmdline_user_args())
	return args.server and args.game <= 0


## What is wrong with the arguments, for the server to say before it gives up, or nothing. Each
## names the environment's setting as well as the argument, since either may have said it.
func problem() -> String:
	if games < 1 or games > MOST_GAMES:
		return "--games (JJ_GAMES) must be between 1 and %d" % MOST_GAMES
	if port < 1 or port > 65535:
		return "--port (JJ_PORT) must be a port, 1 to 65535"
	if first_game_port == 0 and port + games > 65535:
		return "--port (JJ_PORT) must leave room for its games' ports below 65536"
	if web_port != -1 and (web_port < 0 or web_port > 65535):
		return "--web-port (JJ_WEB_PORT) must be a port, 1 to 65535, or 0 for no page"
	return _range_problem() if first_game_port != 0 else ""


## The TCP port the web page is served on, see [member web_port]: the game's own port when it was
## left to the default, the port given, or 0 for no page.
func web() -> int:
	return port if web_port == -1 else web_port


## What is wrong with the range of ports the games are to be played on, or nothing.
func _range_problem() -> String:
	if first_game_port < 1 or last_game_port > 65535 or first_game_port > last_game_port:
		return "--game-ports (JJ_GAME_PORTS) must be the first and last port, such as 7778-7785"
	if port >= first_game_port and port <= last_game_port:
		return "--game-ports (JJ_GAME_PORTS) must leave out the server's own port, %d" % port
	var room := last_game_port - first_game_port + 1
	if games > room:
		return (
			"--games (JJ_GAMES) is %d, but --game-ports (JJ_GAME_PORTS) has only %d ports"
			% [games, room]
		)
	return ""


## The ports the games are played on: those of the range given, or else the ones after the
## server's own.
func game_ports() -> Array[int]:
	var first := first_game_port if first_game_port > 0 else port + 1
	var ports: Array[int] = []
	for i: int in games:
		ports.append(first + i)
	return ports


## `7778-7785`, or `7778` for the one.
func _read_game_ports(value: String) -> void:
	var ends := value.split("-")
	var first := ends[0].strip_edges()
	var last := ends[-1].strip_edges()
	if ends.size() > 2 or not first.is_valid_int() or not last.is_valid_int():
		first_game_port = -1
		last_game_port = -1
		return
	first_game_port = int(first)
	last_game_port = int(last)
