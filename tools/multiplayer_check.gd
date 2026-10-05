extends SceneTree
## Starts the multiplayer check of tools/multiplayer_driver.gd. A script run with -s is compiled
## before the game's autoloads are there to be named, so this only waits for them and hands over
## to the driver, which is compiled once they are.
##
##   godot --headless --path . -s tools/multiplayer_check.gd -- --role=host --port=7851


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	# A room of eight has a driver of its own, see tools/eight_driver.gd.
	var eight := "--eight" in OS.get_cmdline_user_args()
	var driver: Node = (
		load("res://tools/%s.gd" % ("eight_driver" if eight else "multiplayer_driver")).new()
	)
	driver.name = "MultiplayerCheck"
	root.add_child(driver)
