extends Node
## Global game wiring. Autoloaded as `Game`.
##
## Registers the input map before any scene runs, owns the saved settings, and moves between
## the title, the lobby, the settings and the match.

const TITLE_SCENE := "res://scenes/ui/title.tscn"
const LOBBY_SCENE := "res://scenes/ui/lobby.tscn"
const SETTINGS_SCENE := "res://scenes/ui/settings_screen.tscn"
const MATCH_SCENE := "res://scenes/match/match_scene.tscn"

var settings := Settings.new()
## The configuration the next match scene starts with.
var pending_config: MatchConfig
## Where the settings screen returns to.
var settings_return := TITLE_SCENE

var _screenshot_path := ""
var _screenshot_frames := 8
var _frames := 0


func _init() -> void:
	InputActions.register_defaults()
	settings.load_from_disk()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			_screenshot_path = arg.get_slice("=", 1)
		elif arg.begins_with("--frames="):
			_screenshot_frames = int(arg.get_slice("=", 1))


func _ready() -> void:
	settings.apply(get_tree())


## Development aid: with `++ --screenshot=<png> [--frames=<n>]` on the command line, saves the
## viewport after that many frames and quits. Needs a display.
func _process(_delta: float) -> void:
	if _screenshot_path.is_empty():
		return
	_frames += 1
	if _frames == _screenshot_frames:
		var image := get_viewport().get_texture().get_image()
		var error := image.save_png(_screenshot_path)
		print("screenshot %s: %s" % [_screenshot_path, error_string(error)])
		get_tree().quit()


static func version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "dev"))


## True when running without a display, as in tests and CI.
static func is_headless() -> bool:
	return DisplayServer.get_name() == "headless"


func go_to_title() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)


func go_to_lobby() -> void:
	get_tree().change_scene_to_file(LOBBY_SCENE)


func go_to_settings(return_to: String = TITLE_SCENE) -> void:
	settings_return = return_to
	get_tree().change_scene_to_file(SETTINGS_SCENE)


func start_match(config: MatchConfig) -> void:
	pending_config = config
	get_tree().change_scene_to_file(MATCH_SCENE)
