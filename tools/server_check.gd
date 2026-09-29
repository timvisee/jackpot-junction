extends SceneTree
## Starts the dedicated server check of tools/server_driver.gd. A script run with -s is compiled
## before the game's autoloads are there to be named, so this only waits for them and hands over
## to the driver, which is compiled once they are.
##
##   godot --headless --path . -s tools/server_check.gd -- --role=maker --port=7990


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	var driver: Node = load("res://tools/server_driver.gd").new()
	driver.name = "ServerCheck"
	root.add_child(driver)
