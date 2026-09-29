extends Node
## The first scene, and only for a frame: on the way to the title, or with `--server` to a
## dedicated server, GAME.md 9.3a, its hall or one of its games. A scene of its own rather than the
## title, so that the hall, started without the game's autoloads, see [GameTree], never loads the
## title and all of the game the title would bring in with it.

const TITLE := "res://scenes/ui/title.tscn"
const HALL := "res://scenes/server/server.tscn"
const GAME := "res://scenes/server/game_host.tscn"


func _ready() -> void:
	var args := ServerArgs.read(OS.get_cmdline_user_args())
	var first := TITLE
	if args.server:
		first = GAME if args.game > 0 else HALL
	get_tree().change_scene_to_file.call_deferred(first)
