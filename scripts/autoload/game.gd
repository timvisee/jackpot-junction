extends Node
## Global game wiring. Autoloaded as `Game`.
##
## Registers the input map before any scene runs, owns the saved settings, and moves between
## the title, the lobby, the settings and the match.

const TITLE_SCENE := "res://scenes/ui/title.tscn"
const LOBBY_SCENE := "res://scenes/ui/lobby.tscn"
const SETTINGS_SCENE := "res://scenes/ui/settings_screen.tscn"
const MATCH_SCENE := "res://scenes/match/match_scene.tscn"
const ONLINE_SCENE := "res://scenes/ui/online.tscn"
const GARAGE_SCENE := "res://scenes/garage/garage.tscn"
## The two practice rooms, GAME.md 9.4. They are one scene on two maps, a portal apart.
const ROOM_GARAGE := &"garage"
const ROOM_TRACK := &"test_track"

var settings := Settings.new()
## Whether the last thing anybody touched was the keyboard rather than a gamepad. Control
## hints for a player who is not pinned to one device follow this, GAME.md 8.3.
var last_input_keyboard := true
## The configuration the next match scene starts with.
var pending_config: MatchConfig
## Where the settings screen returns to.
var settings_return := TITLE_SCENE
## Which of the two practice rooms the Garage scene builds.
var garage_room := ROOM_GARAGE

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


## Watches every event, without swallowing any, purely to know which scheme to draw hints in.
func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		last_input_keyboard = true
	elif event is InputEventJoypadButton:
		last_input_keyboard = false
	elif event is InputEventJoypadMotion:
		# Sticks drift, so only a real push counts as picking the pad up.
		if absf((event as InputEventJoypadMotion).axis_value) > 0.5:
			last_input_keyboard = false


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


func go_to_online() -> void:
	get_tree().change_scene_to_file(ONLINE_SCENE)


## The practice rooms, GAME.md 9.4. Called with a room by the portal in the other one.
func go_to_garage(room: StringName = ROOM_GARAGE) -> void:
	garage_room = room
	get_tree().paused = false
	get_tree().change_scene_to_file(GARAGE_SCENE)


## The way in from the title, GAME.md 9.4: the very first visit is the test track, which teaches
## the controls, and every visit after it is the Garage proper. Either room has a portal to the
## other, so nothing is locked away by going once.
func enter_garage() -> void:
	go_to_garage(next_garage_room())


## Which room that is, and the note that somebody has now been. Apart from the going, so it can
## be asked without a scene change.
func next_garage_room() -> StringName:
	if settings.seen_test_track:
		return ROOM_GARAGE
	settings.seen_test_track = true
	settings.save_to_disk()
	return ROOM_TRACK


func go_to_settings(return_to: String = TITLE_SCENE) -> void:
	settings_return = return_to
	get_tree().change_scene_to_file(SETTINGS_SCENE)


func start_match(config: MatchConfig) -> void:
	pending_config = config
	get_tree().change_scene_to_file(MATCH_SCENE)
