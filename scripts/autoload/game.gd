extends Node
## Global game wiring. Autoloaded as `Game`.
##
## Registers the input map before any scene runs, owns the saved settings, and moves between
## the title, the lobby, the settings and the match.

const TITLE_SCENE := "res://scenes/ui/title.tscn"
const SETTINGS_SCENE := "res://scenes/ui/settings_screen.tscn"
const MATCH_SCENE := "res://scenes/match/match_scene.tscn"
const ONLINE_SCENE := "res://scenes/ui/online.tscn"
const PLAY_ONLINE_SCENE := "res://scenes/ui/play_online.tscn"
const SERVER_GAMES_SCENE := "res://scenes/ui/server_games.tscn"
const GARAGE_SCENE := "res://scenes/garage/garage.tscn"
const TUTORIAL_SCENE := "res://scenes/tutorial/tutorial.tscn"
const WAITING_SCENE := "res://scenes/waiting/waiting_room.tscn"
## Frames a `--bench` run throws away before it starts counting: the shader compiles and the
## first arena build belong to loading rather than to running.
const BENCH_WARMUP := 120
## How long the sound has to let go of whatever was playing before the game ends, in seconds, see
## [method quit].
const QUIET_BEFORE_QUIT := 0.15

## Whether this is a dedicated server or one of its games, GAME.md 9.3a: the server build, or the
## game started with `--server`. It plays to nobody, so it loads no sound at all: the build has
## none in it, see 10.5, and run from a checkout it leaves every sound file where it is, so the
## two are the same game. A test may set it.
static var serving := OS.has_feature("dedicated_server") or "--server" in OS.get_cmdline_user_args()

var settings := Settings.new()
## Whether the last thing anybody touched was the keyboard rather than a gamepad. Control
## hints for a player who is not pinned to one device follow this, GAME.md 8.3.
var last_input_keyboard := true
## The configuration the next match scene starts with.
var pending_config: MatchConfig
## Where the settings screen returns to.
var settings_return := TITLE_SCENE
## The Grand Prix being played, GAME.md 9.7, or null for a single map. Kept here because it runs
## across scenes: every map is a scene of its own.
var grand_prix: GrandPrix
## What the Play LAN screen says as it comes up, once, see [method go_to_online], and the same for
## Play Online, see [method go_to_play_online], and whether Play Online connects again by itself.
var online_note := ""
var play_online_note := ""
var play_online_reconnect := false

var _screenshot_path := ""
var _screenshot_frames := 8
var _frames := 0
## Frames to run for a `--bench=<n>` measurement, and what has been seen of it so far. The clock
## starts after the warm-up, so the shader compiles and the first arena build do not count.
var _quitting := false
## Development aid: with `++ --run-frames=<n>`, quits after that many frames the way a player
## quits, see [method quit], which the engine's own --quit-after does not. tools/smoke runs on it.
var _run_frames := 0
var _bench_frames := 0
var _bench_seen := 0
var _bench_started := 0


func _init() -> void:
	InputActions.register_defaults()
	settings.load_from_disk()
	TouchInput.detect(OS.get_cmdline_user_args())
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			_screenshot_path = arg.get_slice("=", 1)
		elif arg.begins_with("--frames="):
			_screenshot_frames = int(arg.get_slice("=", 1))
		elif arg.begins_with("--run-frames="):
			_run_frames = int(arg.get_slice("=", 1))
		elif arg.begins_with("--bench="):
			_bench_frames = int(arg.get_slice("=", 1))
			Settings.uncapped_for_now = true
		elif arg.begins_with("--ui-scale="):
			Settings.ui_scale_for_now = clampf(float(arg.get_slice("=", 1)), 0.5, 3.0)


func _ready() -> void:
	settings.apply(get_tree())
	add_child(FrameCounter.new())
	# Closing the window is quitting, and goes the same way as the title's Quit, see [method quit].
	get_tree().auto_accept_quit = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()


## Ends the game, from the title's Quit, the window closing, or a server's game once it is over.
## A sound still playing as the engine shuts down is left behind, and the engine says so as it
## exits: a warning of instances leaked and an error of resources still in use, four and two for
## every sound, which after a game online was the music and a few effects. So the room goes and
## every sound is stopped first, and the mixer is given [constant QUIET_BEFORE_QUIT] to let go of
## them. Frames are no measure of that: the mixer keeps a clock of its own, and without a screen a
## frame is far shorter than one of its turns.
func quit(code := 0) -> void:
	if _quitting:
		return
	_quitting = true
	var tree := get_tree()
	if tree.current_scene != null:
		tree.current_scene.queue_free()
	for kind: String in ["AudioStreamPlayer", "AudioStreamPlayer2D", "AudioStreamPlayer3D"]:
		for player: Node in tree.root.find_children("*", kind, true, false):
			player.call("stop")
	await tree.create_timer(QUIET_BEFORE_QUIT, true, false, true).timeout
	tree.quit(code)


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
	if _run_frames > 0:
		_run_frames -= 1
		if _run_frames == 0:
			quit()
	if _screenshot_path.is_empty():
		return
	_frames += 1
	if _frames == _screenshot_frames:
		var image := get_viewport().get_texture().get_image()
		var error := image.save_png(_screenshot_path)
		print("screenshot %s: %s" % [_screenshot_path, error_string(error)])
		quit()


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
	quit()


static func version() -> String:
	return GameVersion.current()


## True when running without a display, as in tests and CI.
static func is_headless() -> bool:
	return DisplayServer.get_name() == "headless"


## Leaving for a menu hangs up. The connection outlives a scene now, GAME.md 10.3, so walking
## out of a match no longer takes it down by itself: somebody has to say so, and these three are
## every way out there is.
func go_to_title() -> void:
	Net.close()
	grand_prix = null
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)


## Play on this machine, GAME.md 3.8: straight into the lobby, the waiting room of 9.6, with the
## match settings up over it and anybody else here joining in it with their join button. Back
## from [param from], a map, everybody who was playing it here comes with it, as who they were.
func go_to_lobby(from: Match = null) -> void:
	Net.close()
	var config := MatchConfig.from_settings(settings)
	if from != null:
		config.take_locals(from)
		# And every seat past theirs keeps its own name and dress for whoever sits down in it.
		for seat: int in range(config.human_names.size(), settings.player_names.size()):
			config.human_names.append(settings.player_names[seat])
			config.human_styles.append(settings.kart_styles[seat])
	go_to_waiting(config)


## Play LAN, GAME.md 9.3, saying [param note] on it if there is something to say about why it is
## up again: a wrong password, say.
func go_to_online(note := "") -> void:
	Net.close()
	grand_prix = null
	online_note = note
	get_tree().paused = false
	get_tree().change_scene_to_file(ONLINE_SCENE)


## Play Online, GAME.md 9.3a, the screen that connects to a dedicated server, saying [param note]
## on it if there is something to say about why it is up again: the server gone, say.
func go_to_play_online(note := "") -> void:
	Net.close()
	grand_prix = null
	play_online_note = note
	play_online_reconnect = false
	get_tree().paused = false
	get_tree().change_scene_to_file(PLAY_ONLINE_SCENE)


## The games on the server Play Online has just connected to, over the connection it made there.
func go_to_server_games() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(SERVER_GAMES_SCENE)


## Back to the games of the server a game was on, [param note] saying why: Play Online connects to
## it again by itself, as the list was left for the game, and goes on to them.
func back_to_the_server(note := "") -> void:
	go_to_play_online(note)
	play_online_reconnect = true


## Back to the menu the room was reached from, once it is over for this machine, [param why] saying
## why: the games of the dedicated server it was on, GAME.md 9.3a, and the title for anything else.
func back_to_the_menu(why := "") -> void:
	if pending_config != null and not pending_config.server.is_empty():
		back_to_the_server(why)
	else:
		go_to_title()


## The Garage, GAME.md 9.4: from the title, and from the portal at the end of the tutorial.
func go_to_garage() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(GARAGE_SCENE)


## The tutorial, GAME.md 9.4a: from the title, its offer on the first Play, and the Garage's portal.
func go_to_tutorial() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TUTORIAL_SCENE)


func go_to_settings(return_to: String = TITLE_SCENE) -> void:
	settings_return = return_to
	get_tree().change_scene_to_file(SETTINGS_SCENE)


func start_match(config: MatchConfig) -> void:
	pending_config = config
	get_tree().change_scene_to_file(MATCH_SCENE)


## On to the next map of the Grand Prix, GAME.md 9.7: the same people, the same bots and the same
## settings on the next arena in the playlist, and whatever jokers the run lets everybody take on
## from [param from], the map just finished. Online the host says so first and everybody goes.
func next_map(from: Match = null) -> void:
	if _asked_of_the_server(&"next"):
		return
	if grand_prix != null and from != null and not grand_prix.is_last():
		grand_prix.hold_over(from.slots, from.rng)
	var next := next_map_config()
	if next == null:
		return
	if Net.hosting():
		Net.session.begin_the_match()
	start_match(next)


## The configuration the next map is built from, or null when there is no next map to build.
func next_map_config() -> MatchConfig:
	if grand_prix == null or grand_prix.is_last() or pending_config == null:
		return null
	grand_prix.advance()
	pending_config.map = grand_prix.current_map()
	return pending_config


## The room everybody waits in before a match, GAME.md 9.6. The configuration it was given is the
## one the arena is built from once everybody in the room is ready, so it is kept rather than
## asked for again.
## After an online match, the host takes everybody back to the waiting room, GAME.md 9.6: the
## clients are told first, and this machine follows with the configuration the match was built
## from, so its own players come back with it and the host's choices are where they were left.
func back_to_the_room() -> void:
	if _asked_of_the_server(&"lobby"):
		return
	if Net.hosting():
		Net.session.back_to_the_room()
	go_to_waiting(pending_config if pending_config != null else MatchConfig.new())


## The same people again on the same map, GAME.md 3.8, from the podium of [param match_node].
func rematch(match_node: Match) -> void:
	if not _asked_of_the_server(&"rematch"):
		match_node.rematch()


## At a client with the host's say, GAME.md 9.3a, the room is the dedicated server's to take
## [param where], and it takes everybody, this machine with them: asked rather than gone.
func _asked_of_the_server(where: StringName) -> bool:
	if Net.session == null or Net.session.is_host:
		return false
	Net.session.host_controls.go(where)
	return true


func go_to_waiting(config: MatchConfig) -> void:
	# A Grand Prix starts in the waiting room and ends before anybody is back in it.
	grand_prix = null
	pending_config = config
	get_tree().paused = false
	get_tree().change_scene_to_file(WAITING_SCENE)
