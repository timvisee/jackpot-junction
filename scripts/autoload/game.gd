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
const DRIVING_SCHOOL_SCENE := "res://scenes/tutorial/school/driving_school.tscn"
const WAITING_SCENE := "res://scenes/waiting/waiting_room.tscn"
## Where the achievements' toasts come up from, GAME.md 8.10: made from its path rather than named.
## Named here, an autoload, its class and the rooms it reaches into would be compiled with the
## autoloads, and a cycle among them set something up wrong without a word, which the online
## check under a round trip found.
const TOASTS := "res://scenes/achievements/achievement_toasts.gd"
## Frames a `--bench` run throws away before it starts counting: the shader compiles and the
## first arena build belong to loading rather than to running.
const BENCH_WARMUP := 120
## How long the sound has to let go of whatever was playing before the game ends, in seconds, see
## [method quit].
const QUIET_BEFORE_QUIT := 0.15
## How many times at most quitting stops what has started since and waits again, see [method quit].
const QUIET_ROUNDS := 4

## Whether this is a dedicated server or one of its games, GAME.md 9.3a: the server build, or the
## game started with `--server`. It plays to nobody, so it loads no sound at all: the build has
## none in it, see 10.5, and run from a checkout it leaves every sound file where it is, so the
## two are the same game. A test may set it.
static var serving := OS.has_feature("dedicated_server") or "--server" in OS.get_cmdline_user_args()

var settings := Settings.new()
## Whether the last thing anybody touched was the keyboard rather than a gamepad. Control
## hints for a player who is not pinned to one device follow this, GAME.md 8.3.
var last_input_keyboard := true
## Whether the last thing anybody touched was the mouse rather than keys or a pad, for the screens
## that draw a button's key on it only while keys or a pad are in hand, see [ButtonBinds].
var last_input_pointer := false
## The configuration the next match scene starts with.
var pending_config: MatchConfig
## Where the settings screen returns to.
var settings_return := TITLE_SCENE
## The Grand Prix being played, GAME.md 9.7, or null for a single map. Kept here because it runs
## across scenes: every map is a scene of its own.
var grand_prix: GrandPrix
## What the LAN games screen says as it comes up, once, see [method go_to_online], and the same for
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
	var own := settings_path_in(OS.get_cmdline_user_args())
	if not own.is_empty():
		settings.path = own
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
		elif arg == "--no-countdown":
			MatchRules.no_countdown = true
	ClearanceView.read_arguments(OS.get_cmdline_user_args())
	# A license, a stage, the Final Hand or a note on the floor, for a debug build to look at,
	# STORY.md 11.
	Story.read_arguments(OS.get_cmdline_user_args(), settings)
	# Every joker and power-up taken, for a debug build to look at the catalog, GAME.md 8.8.
	CatalogDialog.read_arguments(OS.get_cmdline_user_args(), settings)
	# Landmarks of the loyalty program won, for a debug build to look at what they pay, GAME.md 8.9.
	Loyalty.read_arguments(OS.get_cmdline_user_args(), settings)
	# Achievements earned or taken back, and toasts to look at, for a debug build, GAME.md 8.10.
	Achievements.read_arguments(OS.get_cmdline_user_args(), settings)


func _ready() -> void:
	settings.apply(get_tree())
	# What shows wherever nothing is drawn: between one scene and the next, and for the moment
	# quitting waits on the sounds, see [method quit]. The menus' own dark rather than the engine's
	# gray, which flashed up as the game went.
	RenderingServer.set_default_clear_color(MenuTheme.BACKGROUND)
	# Every control in the game wears the house's look, GAME.md 8.1a, set once here rather than
	# per screen.
	if not serving:
		HouseTheme.install()
		# The cursor slides from one control to the next rather than jumping, GAME.md 8.1a; not where
		# nothing is drawn.
		if not is_headless():
			add_child(FocusGlide.new())
			# A pad held over a way walks the cursor on, as a key held down does, GAME.md 4.2.
			add_child(PadRepeat.new())
			# An achievement earned comes up in a corner of whatever screen this is, GAME.md 8.10.
			add_child(load(TOASTS).new())
	add_child(FrameCounter.new())
	# A text box the phone's keyboard comes up over is shown over the keyboard, GAME.md 8.3.
	if TouchInput.enabled:
		KeyboardBar.add_to(self)
	# Closing the window is quitting, and goes the same way as the title's Quit, see [method quit].
	get_tree().auto_accept_quit = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()


## A phone's own Back, GAME.md 4.2: what B on a pad does, closing a question or a pane, backing out
## of a screen or out of the room's menu. Where B does nothing, in a room with no menu up, it opens
## the menu, the way the menu button in the corner does, since a phone has no other key for it; on
## the title, which nothing backs out of, it does nothing. It never quits the game outright.
func go_back() -> void:
	var viewport := get_viewport()
	var back := InputEventAction.new()
	back.action = &"ui_cancel"
	back.pressed = true
	viewport.push_input(back)
	var heard := viewport.is_input_handled()
	back = back.duplicate()
	back.pressed = false
	viewport.push_input(back)
	if not heard and not PauseMenu.is_open_in(get_tree()):
		PauseMenu.open_in(get_tree())


## Ends the game, from the title's Quit, the window closing, or a server's game once it is over.
## A sound still playing as the engine shuts down is left behind, and the engine says so as it
## exits: a warning of instances leaked and an error of resources still in use, four and two for
## every sound, which after a game online was the music and a few effects. So the room goes and
## every sound is stopped first, and the mixer is given [constant QUIET_BEFORE_QUIT] to let go of
## them. Frames are no measure of that: the mixer keeps a clock of its own, and without a screen a
## frame is far shorter than one of its turns.
##
## A sound started in the meantime is stopped and waited out in turn, a few times at most: the room
## only goes at the end of the frame it is asked to, and a rocket of a podium's fireworks bursting
## in it before then still bangs, which left that bang behind at exit.
func quit(code := 0) -> void:
	if _quitting:
		return
	_quitting = true
	var tree := get_tree()
	if tree.current_scene != null:
		tree.current_scene.queue_free()
	_silence(tree)
	for _round: int in QUIET_ROUNDS:
		await tree.create_timer(QUIET_BEFORE_QUIT, true, false, true).timeout
		if not _silence(tree):
			break
	tree.quit(code)


## Stops every sound playing in [param tree], and says whether any was.
static func _silence(tree: SceneTree) -> bool:
	var any := false
	for kind: String in ["AudioStreamPlayer", "AudioStreamPlayer2D", "AudioStreamPlayer3D"]:
		for player: Node in tree.root.find_children("*", kind, true, false):
			any = any or bool(player.get("playing"))
			player.call("stop")
	return any


## Watches every event, without swallowing any, to know which scheme to draw hints in and which
## device was used last, see [member DeviceInput.recent]. Heard after the room's own handlers,
## being early in the tree: a pad's press that sits somebody down is theirs, not the last thing
## the player before them touched.
func _input(event: InputEvent) -> void:
	heard(event)


## [param event] was touched, for [method _input], and for anything that spends an event before
## it gets here, as the title's opening does, see [TitleIntro].
func heard(event: InputEvent) -> void:
	last_input_pointer = ButtonBinds.pointer_after(event, last_input_pointer)
	if event is InputEventKey or event is InputEventMouseButton:
		last_input_keyboard = true
		DeviceInput.touched(DeviceInput.KEYBOARD)
	elif event is InputEventJoypadButton:
		last_input_keyboard = false
		DeviceInput.touched(event.device)
	elif event is InputEventJoypadMotion:
		# Sticks drift, so only a real push counts as picking the pad up.
		if absf((event as InputEventJoypadMotion).axis_value) > 0.5:
			last_input_keyboard = false
			DeviceInput.touched(event.device)


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


## The settings file named by `--settings=<path>` among [param args], GAME.md 10.2, for running
## with a fresh or a particular one: a `user://` path, an absolute one, or a bare name, which goes
## in the user directory. Empty for none.
static func settings_path_in(args: PackedStringArray) -> String:
	for arg: String in args:
		if not arg.begins_with("--settings="):
			continue
		var given := arg.get_slice("=", 1).strip_edges()
		if given.is_empty():
			return ""
		if given.contains("://") or given.is_absolute_path():
			return given
		return "user://" + given
	return ""


static func version() -> String:
	return GameVersion.current()


## True when running without a display, as in tests and CI.
static func is_headless() -> bool:
	return DisplayServer.get_name() == "headless"


## Whether this run is a tool's rather than a player's: a screenshot, a smoke run or a bench,
## which want the screen they asked for as it settles rather than any opening on the way to it.
func is_scripted() -> bool:
	return not _screenshot_path.is_empty() or _run_frames > 0 or _bench_frames > 0


## Leaving for a menu hangs up. The connection outlives a scene now, GAME.md 10.3, so walking
## out of a match no longer takes it down by itself: somebody has to say so, and these three are
## every way out there is.
func go_to_title() -> void:
	Net.close()
	grand_prix = null
	# What was done in the room left goes into everybody's profile first, the profiles sat in at
	# other seats too, GAME.md 8.5; then whoever sat in as another profile is a guest again, 3.8.
	get_tree().call_group(MatchRecord.GROUP, &"leave")
	settings.unlink_all()
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
			config.human_names.append(settings.seat_name(seat))
			config.human_styles.append(settings.seat_style(seat))
	go_to_waiting(config)


## LAN games, GAME.md 9.3, saying [param note] on it if there is something to say about why it is
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


## The tutorial, GAME.md 9.4a, which opens on the driving school: from the title, its offer on the
## first Play, and the Garage's portal.
func go_to_tutorial() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(DRIVING_SCHOOL_SCENE)


## The driving test itself, GAME.md 9.4a: the tutorial's rooms, from the end of the school's theory.
func go_to_driving_test() -> void:
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


## The configuration the next map is built from, or null when there is no next map to build. After
## the last, a run that ends level goes on to its showdown, GAME.md 9.7a.
func next_map_config() -> MatchConfig:
	if grand_prix == null or pending_config == null:
		return null
	if grand_prix.is_last():
		if not grand_prix.begin_showdown():
			return null
		pending_config.map = ArenaMaps.SHOWDOWN
		return pending_config
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
