extends SceneTree
## Starts the dedicated server check of tools/server_driver.gd. A script run with -s is compiled
## before the game's autoloads are there to be named, so this only waits for them and hands over
## to the driver, which is compiled once they are.
##
##   godot --headless --path . -s tools/server_check.gd -- --role=maker --port=7990


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	# The Final Hand at a dedicated server has a driver of its own, tools/server_house_driver.gd.
	var house := "--house" in OS.get_cmdline_user_args()
	var driver: Node = load(
		"res://tools/%s.gd" % ("server_house_driver" if house else "server_driver")
	).new()
	driver.name = "ServerCheck"
	root.add_child(driver)
