extends SceneTree
## Starts the multiplayer check of tools/multiplayer_driver.gd. A script run with -s is compiled
## before the game's autoloads are there to be named, so this only waits for them and hands over
## to the driver, which is compiled once they are.
##
##   godot --headless --path . -s tools/multiplayer_check.gd -- --role=host --port=7851


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	# A room of eight has a driver of its own, see tools/eight_driver.gd, and so does the Final
	# Hand online, tools/house_driver.gd.
	var args := OS.get_cmdline_user_args()
	var named := "multiplayer_driver"
	if "--eight" in args:
		named = "eight_driver"
	elif "--house" in args:
		named = "house_driver"
	var driver: Node = load("res://tools/%s.gd" % named).new()
	driver.name = "MultiplayerCheck"
	root.add_child(driver)
