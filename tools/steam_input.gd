extends SceneTree
## Writes the game's actions for Steam Input, GAME.md 10.8, into data/steam/input: the action
## manifest and the layout each kind of controller starts on, from [SteamActions]. Run whenever an
## action comes or goes, or a pad's default button changes; test_steam_actions fails until it is.
##
##   godot --headless --path . -s tools/steam_input.gd
##
## `make steam-input` runs it so. A script run with -s is compiled before the game's autoloads are
## there to be named, so it reaches SteamActions by path.

const ACTIONS := "res://scripts/input/steam_actions.gd"


func _initialize() -> void:
	var actions: GDScript = load(ACTIONS)
	var folder: String = actions.get(&"FOLDER")
	var files: Dictionary = actions.call(&"files")
	for name: String in files:
		var file := FileAccess.open(folder.path_join(name), FileAccess.WRITE)
		if file == null:
			push_error("Could not write %s" % folder.path_join(name))
			quit(1)
			return
		file.store_string(files[name])
		print("Wrote ", folder.path_join(name))
	quit()
