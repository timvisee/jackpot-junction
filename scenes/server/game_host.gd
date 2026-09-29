extends Node
## One game of a dedicated server, GAME.md 9.3a, as the process the hall started it in comes up:
## the game proper, autoloads and all, hosting from the waiting room on, see [ServerGame].

## A tick a frame and not a frame faster, the rate its physics runs at.
const FPS := 60


func _ready() -> void:
	# Nothing a game of the server's does is anybody's to keep, and the settings of the machine it
	# runs on are not what it is played by: its host's are, see 9.3a.
	Game.settings = Settings.new()
	Game.settings.path = ""
	Engine.max_fps = FPS
	var game := ServerGame.new()
	game.name = "ServerGame"
	game.args = ServerArgs.read(OS.get_cmdline_user_args())
	get_tree().root.add_child.call_deferred(game)
