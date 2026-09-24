class_name Settings
extends RefCounted
## User settings from GAME.md 8.5, saved between sessions with ConfigFile. Nothing else is
## persisted yet.

const DEFAULT_PATH := "user://settings.cfg"
const AIM_ASSIST_MAX := 1.0
## How big the menus and the HUD can be drawn, GAME.md 8.5, as a share of the size they were laid
## out at for a screen 1080 lines high. The 3D picture is not touched by it.
const UI_SCALES: Array[float] = [0.75, 0.9, 1.0, 1.25, 1.5, 1.75, 2.0]

## A UI scale for this run of the game alone, from `++ --ui-scale=1.5` on the command line, and 0
## for none: for trying a size out, or a phone's on a desktop, without it being saved over the
## player's own.
static var ui_scale_for_now := 0.0

var master_volume := 1.0
var music_volume := 0.8
var sfx_volume := 1.0
## The engine and tires of the karts themselves, on their own bus under the effects, GAME.md 8.4.
var kart_volume := 1.0
## Music switched off entirely, toggled with the mute key.
var music_muted := false
## Whether the music goes under water for a moment when a player at this screen dies, GAME.md 8.4.
var muffle_on_death := true
## A phone or a tablet plays full screen to start with, the system's own bars out of the way, since
## a game in a window is a game with the clock and the notifications over the top of it.
var fullscreen := OS.has_feature("mobile")
var vsync := true
var render_scale := 1.0
## One of [constant UI_SCALES]. A phone is held close, and a HUD laid out for a monitor across a
## desk is a HUD of things too small to press there, so a handheld starts at half as big again.
var ui_scale := 1.5 if OS.has_feature("mobile") else 1.0
## The two passes over the whole screen a room pays for, GAME.md 8.5. Both are worth what they
## cost on a card that can spare it and both are the first thing to give up on one that cannot:
## the bloom is about a tenth of the frame in The Vault, and the smoothing about a twentieth.
var bloom := true
var antialiasing := true
var screen_shake := true
var flash_reduction := false
## 0 to 1 of the default aim assist, never more.
var aim_assist := 1.0
var rumble := true
## Dots ahead of the cannon showing where shots go.
var aim_guide := true
## The moving-head lights over the arena, GAME.md 8.1.
var disco_lights := true
## The onlookers around the table and the stands they are on, GAME.md 8.1. The busiest thing on
## screen that has nothing to do with the match, so it is the first thing worth being able to
## turn off. On by default: the room is meant to be full.
var crowd := true
## The on-screen reminders of which button does what, GAME.md 8.3.
var control_hints := true
## The camera holding the whole arena instead of coming in on the karts, GAME.md 8.2. Off by
## default, because coming in is what makes a kart big enough to read; on, for a player who would
## rather have a picture that never moves than one that is close.
var fixed_camera := false
var stick_deadzone := 0.15
## Action name to the descriptors that replace its defaults.
var bindings: Dictionary = {}
## How long a map runs, in seconds, GAME.md 3.8.
var match_seconds := 300
var target_score := 3000
var bot_count := 3
var difficulty := "normal"
var item_set := "first"
## Which arena the lobby last picked, GAME.md 6.3.
var map := "lucky_crossing"
## Whether a kart's own shots hurt it, GAME.md 5.1.
var own_bullets_hurt := false
## Whether a match that runs out of clock goes to sudden death, GAME.md 3.13.
var overtime := true
## How many maps Play runs, GAME.md 9.7, and whether the host of an online room last chose a
## Grand Prix over a single map.
var grand_prix_maps := 3
var grand_prix := true
## What of their jokers players take from one map of a Grand Prix to the next, one of
## [enum GrandPrix.Keep]: one at random unless somebody chooses otherwise.
var grand_prix_jokers := 2
## What each local seat calls itself, GAME.md 3.8. An empty entry is a seat that never gave a
## name and will be handed a funny one when the match starts.
var player_names: Array[String] = ["", "", "", ""]
## How each local seat dressed its kart, GAME.md 4.4: four numbers each, a paint, a hat, a flag
## and a trail.
var kart_styles: Array = [
	PackedInt32Array([0, 0, 0, 0]),
	PackedInt32Array([0, 0, 0, 0]),
	PackedInt32Array([0, 0, 0, 0]),
	PackedInt32Array([0, 0, 0, 0]),
]
## Whether anybody has been round the test track yet, GAME.md 9.4. The first visit to the
## Garage goes there; every visit after it goes to the Garage proper.
var seen_test_track := false
var last_address := "127.0.0.1"
var last_port := 7777

var path := DEFAULT_PATH


func load_from_disk() -> void:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return
	master_volume = file.get_value("audio", "master", master_volume)
	music_volume = file.get_value("audio", "music", music_volume)
	sfx_volume = file.get_value("audio", "sfx", sfx_volume)
	kart_volume = file.get_value("audio", "kart", kart_volume)
	music_muted = file.get_value("audio", "music_muted", music_muted)
	muffle_on_death = file.get_value("audio", "muffle_on_death", muffle_on_death)
	fullscreen = file.get_value("video", "fullscreen", fullscreen)
	vsync = file.get_value("video", "vsync", vsync)
	render_scale = file.get_value("video", "render_scale", render_scale)
	ui_scale = clampf(file.get_value("video", "ui_scale", ui_scale), UI_SCALES[0], UI_SCALES[-1])
	bloom = file.get_value("video", "bloom", bloom)
	antialiasing = file.get_value("video", "antialiasing", antialiasing)
	screen_shake = file.get_value("accessibility", "screen_shake", screen_shake)
	flash_reduction = file.get_value("accessibility", "flash_reduction", flash_reduction)
	aim_assist = clampf(
		file.get_value("accessibility", "aim_assist", aim_assist), 0.0, AIM_ASSIST_MAX
	)
	rumble = file.get_value("accessibility", "rumble", rumble)
	aim_guide = file.get_value("accessibility", "aim_guide", aim_guide)
	disco_lights = file.get_value("accessibility", "disco_lights", disco_lights)
	crowd = file.get_value("accessibility", "crowd", crowd)
	control_hints = file.get_value("accessibility", "control_hints", control_hints)
	fixed_camera = file.get_value("accessibility", "fixed_camera", fixed_camera)
	stick_deadzone = file.get_value("controls", "stick_deadzone", stick_deadzone)
	bindings = file.get_value("controls", "bindings", {})
	# Kept in minutes until a map could be shorter than one; a file from then is read in minutes.
	match_seconds = file.get_value(
		"lobby", "match_seconds", int(file.get_value("lobby", "match_minutes", 5)) * 60
	)
	target_score = file.get_value("lobby", "target_score", target_score)
	bot_count = file.get_value("lobby", "bot_count", bot_count)
	difficulty = file.get_value("lobby", "difficulty", difficulty)
	item_set = file.get_value("lobby", "item_set", item_set)
	map = file.get_value("lobby", "map", map)
	own_bullets_hurt = file.get_value("lobby", "own_bullets_hurt", own_bullets_hurt)
	overtime = file.get_value("lobby", "overtime", overtime)
	grand_prix_maps = file.get_value("lobby", "grand_prix_maps", grand_prix_maps)
	grand_prix = file.get_value(
		"lobby", "grand_prix", file.get_value("lobby", "online_grand_prix", grand_prix)
	)
	grand_prix_jokers = file.get_value("lobby", "grand_prix_jokers", grand_prix_jokers)
	var stored: Array = file.get_value("lobby", "player_names", [])
	for i: int in mini(stored.size(), player_names.size()):
		player_names[i] = PlayerNames.clean(str(stored[i]))
	var dressed: Array = file.get_value("lobby", "kart_styles", [])
	for i: int in mini(dressed.size(), kart_styles.size()):
		kart_styles[i] = KartStyle.from_array(dressed[i]).to_array()
	seen_test_track = file.get_value("progress", "seen_test_track", seen_test_track)
	last_address = file.get_value("online", "address", last_address)
	last_port = file.get_value("online", "port", last_port)


func save_to_disk() -> Error:
	var file := ConfigFile.new()
	file.set_value("audio", "master", master_volume)
	file.set_value("audio", "music", music_volume)
	file.set_value("audio", "sfx", sfx_volume)
	file.set_value("audio", "kart", kart_volume)
	file.set_value("audio", "music_muted", music_muted)
	file.set_value("audio", "muffle_on_death", muffle_on_death)
	file.set_value("video", "fullscreen", fullscreen)
	file.set_value("video", "vsync", vsync)
	file.set_value("video", "render_scale", render_scale)
	file.set_value("video", "ui_scale", ui_scale)
	file.set_value("video", "bloom", bloom)
	file.set_value("video", "antialiasing", antialiasing)
	file.set_value("accessibility", "screen_shake", screen_shake)
	file.set_value("accessibility", "flash_reduction", flash_reduction)
	file.set_value("accessibility", "aim_assist", aim_assist)
	file.set_value("accessibility", "rumble", rumble)
	file.set_value("accessibility", "aim_guide", aim_guide)
	file.set_value("accessibility", "disco_lights", disco_lights)
	file.set_value("accessibility", "crowd", crowd)
	file.set_value("accessibility", "control_hints", control_hints)
	file.set_value("accessibility", "fixed_camera", fixed_camera)
	file.set_value("controls", "stick_deadzone", stick_deadzone)
	file.set_value("controls", "bindings", bindings)
	file.set_value("lobby", "match_seconds", match_seconds)
	file.set_value("lobby", "target_score", target_score)
	file.set_value("lobby", "bot_count", bot_count)
	file.set_value("lobby", "difficulty", difficulty)
	file.set_value("lobby", "item_set", item_set)
	file.set_value("lobby", "map", map)
	file.set_value("lobby", "own_bullets_hurt", own_bullets_hurt)
	file.set_value("lobby", "overtime", overtime)
	file.set_value("lobby", "grand_prix_maps", grand_prix_maps)
	file.set_value("lobby", "grand_prix", grand_prix)
	file.set_value("lobby", "grand_prix_jokers", grand_prix_jokers)
	file.set_value("lobby", "player_names", player_names)
	file.set_value("lobby", "kart_styles", kart_styles)
	file.set_value("progress", "seen_test_track", seen_test_track)
	file.set_value("online", "address", last_address)
	file.set_value("online", "port", last_port)
	return file.save(path)


## Pushes every setting into the engine: buses, window, input map.
func apply(tree: SceneTree) -> void:
	apply_audio()
	apply_input()
	if not DisplayServer.get_name() == "headless":
		apply_video(tree)


func apply_audio() -> void:
	_set_bus(Buses.MASTER, master_volume)
	_set_bus(Buses.MUSIC, music_volume)
	_set_bus(Buses.SFX, sfx_volume)
	_set_bus(Buses.KART, kart_volume)
	var music := AudioServer.get_bus_index(Buses.MUSIC)
	if music >= 0 and music_muted:
		AudioServer.set_bus_mute(music, true)


func apply_video(tree: SceneTree) -> void:
	var mode := (
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
	var wanted := DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	if DisplayServer.window_get_vsync_mode() != wanted:
		DisplayServer.window_set_vsync_mode(wanted)
	if tree != null and tree.root != null:
		tree.root.scaling_3d_scale = clampf(render_scale, 0.5, 1.0)
		# Every menu and the HUD, drawn bigger or smaller; the room behind them stays as sharp.
		tree.root.content_scale_factor = ui_scale_for_now if ui_scale_for_now > 0.0 else ui_scale
		tree.root.msaa_3d = Viewport.MSAA_2X if antialiasing else Viewport.MSAA_DISABLED
		# Something has to keep the edges of a room of straight lines from crawling. Off the
		# multisampling, the cheap screen-space pass does it for about a third of the price.
		tree.root.screen_space_aa = (
			Viewport.SCREEN_SPACE_AA_DISABLED if antialiasing else Viewport.SCREEN_SPACE_AA_FXAA
		)


## Registers the default input map, then the player's rebindings and dead zone on top.
func apply_input() -> void:
	InputActions.register_defaults()
	for action: String in bindings:
		var descriptors: Array = bindings[action]
		var name := StringName(action)
		if not InputMap.has_action(name):
			continue
		InputMap.action_erase_events(name)
		for descriptor: Dictionary in descriptors:
			InputMap.action_add_event(name, InputActions.make_event(descriptor))
	for action: StringName in InputActions.STICK_ACTIONS:
		InputMap.action_set_deadzone(action, stick_deadzone)


## Records the current input map for an action as an override.
func remember_binding(action: StringName) -> void:
	bindings[String(action)] = InputActions.descriptors(action)


func reset_bindings() -> void:
	bindings = {}
	apply_input()


func _set_bus(bus: StringName, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(index, linear <= 0.0001)
