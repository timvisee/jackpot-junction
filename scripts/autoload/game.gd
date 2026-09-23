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
const WAITING_SCENE := "res://scenes/waiting/waiting_room.tscn"
## The two practice rooms, GAME.md 9.4. They are one scene on two maps, a portal apart.
const ROOM_GARAGE := &"garage"
const ROOM_TRACK := &"test_track"
## Frames a `--bench` run throws away before it starts counting: the shader compiles and the
## first arena build belong to loading rather than to running.
const BENCH_WARMUP := 120

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
## Frames to run for a `--bench=<n>` measurement, and what has been seen of it so far. The clock
## starts after the warm-up, so the shader compiles and the first arena build do not count.
var _bench_frames := 0
var _bench_seen := 0
var _bench_started := 0


func _init() -> void:
	InputActions.register_defaults()
	settings.load_from_disk()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			_screenshot_path = arg.get_slice("=", 1)
		elif arg.begins_with("--frames="):
			_screenshot_frames = int(arg.get_slice("=", 1))
		elif arg.begins_with("--bench="):
			_bench_frames = int(arg.get_slice("=", 1))


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
	if _bench_frames > 0:
		_step_bench()
	if _screenshot_path.is_empty():
		return
	_frames += 1
	if _frames == _screenshot_frames:
		var image := get_viewport().get_texture().get_image()
		var error := image.save_png(_screenshot_path)
		print("screenshot %s: %s" % [_screenshot_path, error_string(error)])
		get_tree().quit()


## Development aid: with `++ --bench=<n>`, runs that many frames and prints the frame rate over
## them, then quits. A number rather than an impression, so a change that costs frames is caught
## while it is being made rather than in a play session.
func _step_bench() -> void:
	_bench_seen += 1
	if _bench_seen == BENCH_WARMUP:
		_bench_started = Time.get_ticks_usec()
		return
	if _bench_seen < _bench_frames:
		return
	var seconds := float(Time.get_ticks_usec() - _bench_started) / 1000000.0
	var frames := _bench_frames - BENCH_WARMUP
	# The draw calls go with the frame rate: a frame rate that has dropped tells you something is
	# wrong and this says whether the answer is on the CPU, handing the card a thousand things to
	# draw, or on the GPU drawing them.
	var calls := RenderingServer.get_rendering_info(
		RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME
	)
	var objects := RenderingServer.get_rendering_info(
		RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME
	)
	print(
		(
			"bench %d frames in %.2fs: %.1f fps, %d draw calls, %d objects"
			% [frames, seconds, float(frames) / maxf(seconds, 0.001), calls, objects]
		)
	)
	get_tree().quit()


static func version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "dev"))


## True when running without a display, as in tests and CI.
static func is_headless() -> bool:
	return DisplayServer.get_name() == "headless"


## Leaving for a menu hangs up. The connection outlives a scene now, GAME.md 10.3, so walking
## out of a match no longer takes it down by itself: somebody has to say so, and these three are
## every way out there is.
func go_to_title() -> void:
	Net.close()
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)


func go_to_lobby() -> void:
	Net.close()
	get_tree().change_scene_to_file(LOBBY_SCENE)


func go_to_online() -> void:
	Net.close()
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


## The room everybody waits in before a match, GAME.md 9.6. The configuration it was given is the
## one the arena is built from once everybody in the room is ready, so it is kept rather than
## asked for again.
func go_to_waiting(config: MatchConfig) -> void:
	pending_config = config
	get_tree().paused = false
	get_tree().change_scene_to_file(WAITING_SCENE)
