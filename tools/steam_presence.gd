extends SceneTree
## Writes what the Steam friends list says, GAME.md 10.8, into docs/steam: a file of the presence's
## words for each language the game speaks, from [SteamPresence]. Run whenever a token or a map
## comes or goes, or the words change in any language; test_steam_presence fails until it is.
##
##   godot --headless --path . -s tools/steam_presence.gd
##
## `make steam-presence` runs it so. A script run with -s is compiled before the game's autoloads
## are there to be named, so it reaches SteamPresence, which names them, by path.

const PRESENCE := "res://scripts/store/steam_presence.gd"


func _initialize() -> void:
	var presence: GDScript = load(PRESENCE)
	var folder: String = presence.get(&"FOLDER")
	var files: Dictionary = presence.call(&"files")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for name: String in files:
		var file := FileAccess.open(folder.path_join(name), FileAccess.WRITE)
		if file == null:
			push_error("Could not write %s" % folder.path_join(name))
			quit(1)
			return
		file.store_string(files[name])
		print("Wrote ", folder.path_join(name))
	quit()
