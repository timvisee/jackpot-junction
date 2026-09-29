class_name GameTree
extends SceneTree
## The game's main loop: Godot's own scene tree, with one thing decided before anything else is
## loaded, see project.godot. A dedicated server's hall, GAME.md 9.3a, started with `--server` and
## no game of its own to run, needs none of the game: its settings, its sound, its events and its
## connection are for playing. Its autoloads bring most of the game in with them, a hundred
## megabytes and more of it, for a process that only answers the door, so the hall is started
## without them. Its games, each the game proper in a process of its own, keep them.


func _init() -> void:
	if not ServerArgs.runs_the_hall():
		return
	for setting: Dictionary in ProjectSettings.get_property_list():
		var name: String = setting["name"]
		if name.begins_with("autoload/"):
			ProjectSettings.set_setting(name, null)
