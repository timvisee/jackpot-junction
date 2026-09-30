extends Node
## A dedicated server's hall, GAME.md 9.3a, started with `--server` after `--`: the door players
## come to for the list of games, see [ServerHall]. Started without the game's autoloads, see
## [GameTree], and asking as little of the machine as it can while nobody plays: a handful of
## frames a second, and no physics, since the games it starts are processes of their own.

## Frames a second: enough to answer a knock or a report within a tenth of a second, and nothing is
## drawn or simulated here to need more.
const FPS := 10


func _ready() -> void:
	var args := ServerArgs.of_this_process()
	Engine.max_fps = FPS
	OS.low_processor_usage_mode = true
	PhysicsServer3D.set_active(false)
	PhysicsServer2D.set_active(false)
	if DisplayServer.get_name() != "headless":
		push_warning("A server needs no window: start it with --headless")
	var problem := args.problem()
	if not problem.is_empty():
		printerr(problem)
		get_tree().quit(1)
		return
	# Where the list is heard, at the place a player's Play Online knocks, see [ServerLink]. The
	# game's own [Net] autoload is not here to hang it on.
	var net := Node.new()
	net.name = "Net"
	get_tree().root.add_child(net)
	var hall := ServerHall.new()
	hall.name = "Hall"
	hall.args = args
	hall.home = net
	add_child(hall)
	var error := hall.open()
	if error != OK:
		printerr("Could not open a server on port %d: %s" % [args.port, error_string(error)])
		get_tree().quit(1)
