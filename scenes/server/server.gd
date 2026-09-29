extends Node
## A dedicated server, GAME.md 9.3a, started with `--server` after `--`: the hall players come to,
## see [ServerHall], or with `--game` one of the games the hall has started in a process of its own,
## see [ServerGame]. Meant to run headless, on a machine of its own.

## Frames a second: the hall only answers the door and reads its games' reports, while a game runs
## its room at the rate its physics does, a tick a frame, and not a frame faster.
const HALL_FPS := 30
const GAME_FPS := 60


func _ready() -> void:
	var args := ServerArgs.read(OS.get_cmdline_user_args())
	# Nothing a server does is anybody's to keep, and the settings of the machine it runs on are
	# not what its games are played by: every game's are its host's, see 9.3a.
	Game.settings = Settings.new()
	Game.settings.path = ""
	if args.game > 0:
		Engine.max_fps = GAME_FPS
		var game := ServerGame.new()
		game.name = "ServerGame"
		game.args = args
		get_tree().root.add_child.call_deferred(game)
		return
	Engine.max_fps = HALL_FPS
	if DisplayServer.get_name() != "headless":
		push_warning("A server needs no window: start it with --headless")
	var problem := args.problem()
	if not problem.is_empty():
		printerr(problem)
		get_tree().quit(1)
		return
	var hall := ServerHall.new()
	hall.name = "Hall"
	hall.args = args
	add_child(hall)
	var error := hall.open()
	if error != OK:
		printerr("Could not open a server on port %d: %s" % [args.port, error_string(error)])
		get_tree().quit(1)
