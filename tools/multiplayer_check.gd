extends SceneTree
## Starts the multiplayer check of tools/multiplayer_driver.gd. A script run with -s is compiled
## before the game's autoloads are there to be named, so this only waits for them and hands over
## to the driver, which is compiled once they are.
##
##   godot --headless --path . -s tools/multiplayer_check.gd -- --role=host --port=7811


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	var driver: Node = load("res://tools/multiplayer_driver.gd").new()
	driver.name = "MultiplayerCheck"
	root.add_child(driver)
