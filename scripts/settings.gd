class_name Settings
extends RefCounted
## User settings from GAME.md 8.5, saved between sessions with ConfigFile. Nothing else is
## persisted yet.

const DEFAULT_PATH := "user://settings.cfg"
const AIM_ASSIST_MAX := 1.0
## How big the menus and the HUD can be drawn, GAME.md 8.5, as a share of the size they were laid
## out at for a screen 1080 lines high. The 3D picture is not touched by it.
const UI_SCALES: Array[float] = [0.75, 0.9, 1.0, 1.25, 1.5, 1.75, 2.0]
## How many samples the edges of a room are taken at, GAME.md 8.5, none among them.
const MSAA_SAMPLES: Array[int] = [0, 2, 4, 8]
## The smoothing pass over the whole finished picture: none, FXAA or SMAA.
const SMOOTH_OFF := "off"
const SMOOTH_FXAA := "fxaa"
const SMOOTH_SMAA := "smaa"
const SMOOTHINGS: Array[String] = [SMOOTH_OFF, SMOOTH_FXAA, SMOOTH_SMAA]
## How a room drawn under the screen's size, at a render scale below 100%, is brought up to it: the
## plain stretch, or AMD's FSR 1 or FSR 2. FSR 2 needs the desktop's renderer; a phone's gets
## FSR 1 in its place.
const UPSCALE_BILINEAR := "bilinear"
const UPSCALE_FSR := "fsr"
const UPSCALE_FSR2 := "fsr2"
## The sizes of house the crowd setting offers, as a share of the people who would have come,
## and what each is called: all of them, half, or nobody at all.
const CROWD_SIZES: Array[float] = [1.0, 0.5, 0.0]
const CROWD_NAMES: Array[String] = ["Full", "Half", "Off"]
const UPSCALERS: Array[String] = [UPSCALE_BILINEAR, UPSCALE_FSR, UPSCALE_FSR2]
## The shadows the room's sun and lamp cast: none, or drawn into smaller maps with hard edges, or
## into the big ones with soft edges. Low is what a phone's renderer does of its own accord, and
## high what a desktop's does.
const SHADOWS_OFF := "off"
const SHADOWS_LOW := "low"
const SHADOWS_HIGH := "high"
const SHADOW_LEVELS: Array[String] = [SHADOWS_OFF, SHADOWS_LOW, SHADOWS_HIGH]
## The most frames a second the game draws, GAME.md 8.5, 0 for as many as it can: 30 for a phone
## to last longer on its battery, and the refresh rates screens come in.
const FRAME_LIMITS: Array[int] = [0, 30, 60, 120, 144]
const TOUCH_SLIDER := "slider"
const TOUCH_BUTTONS := "buttons"
const TOUCH_LAYOUTS: Array[String] = [TOUCH_SLIDER, TOUCH_BUTTONS]
## The two ways to drive, GAME.md 4.2: simple, where the stick says which way on the screen to go
## and the kart takes itself there, and advanced, a wheel and two pedals.
const DRIVE_SIMPLE := "simple"
const DRIVE_ADVANCED := "advanced"
const DRIVE_MODES: Array[String] = [DRIVE_SIMPLE, DRIVE_ADVANCED]
## The kinds of color blindness the player colors can be drawn for, GAME.md 8.5, empty being none.
const VISIONS: Array[String] = ["", "protanopia", "deuteranopia", "tritanopia"]

## A UI scale for this run of the game alone, from `++ --ui-scale=1.5` on the command line, and 0
## for none: for trying a size out, or a phone's on a desktop, without it being saved over the
## player's own.
static var ui_scale_for_now := 0.0
## Whether this run draws as many frames as it can whatever the limit says, for `++ --bench`: a
## measurement of the frame rate is no measurement held at the player's limit.
static var uncapped_for_now := false

## Half to start with: at full the game came on loud enough to make anybody reach for the
## volume, and the slider has the room to go up for anybody who wants it.
var master_volume := 0.5
var music_volume := 0.8
var sfx_volume := 1.0
## The engine and tires of the karts themselves, on their own bus under the effects, GAME.md 8.4.
var kart_volume := 1.0
## How much louder the music gets at the hottest the room gets, GAME.md 8.5, see [MusicSwell]:
## 0 for not at all, up to [constant MusicSwell.MOST], starting from the swell it always had.
var music_swell := MusicSwell.NORMAL
## Music switched off entirely, toggled with the mute key.
var music_muted := false
## Whether the music goes under water for a moment when a player at this screen dies, GAME.md 8.4.
var muffle_on_death := true
## A phone or a tablet plays full screen to start with, the system's own bars out of the way, since
## a game in a window is a game with the clock and the notifications over the top of it; and so
## does a released game on a desktop, which is a game somebody sat down to play. A build of this
## checkout, from the editor or a debug export, starts in a window, beside whatever it is being
## worked on with.
var fullscreen := OS.has_feature("mobile") or OS.has_feature("template_release")
var vsync := true
## One of [constant FRAME_LIMITS].
var frame_limit := 0
## The frame rate in the corner of every screen, see [FrameCounter].
var show_fps := false
## A phone or a tablet draws its room at four fifths of the screen's size to start with, and
## without the two passes below: a phone's card is the one that cannot spare them.
var render_scale := 0.8 if OS.has_feature("mobile") else 1.0
## One of [constant UPSCALERS].
var upscaler := UPSCALE_BILINEAR
## One of [constant SHADOW_LEVELS].
var shadows := SHADOWS_LOW if OS.has_feature("mobile") else SHADOWS_HIGH
## One of [constant UI_SCALES]. A phone is held close, and a HUD laid out for a monitor across a
## desk is a HUD of things too small to press there, so a handheld starts at half as big again.
var ui_scale := 1.5 if OS.has_feature("mobile") else 1.0
## The two passes over the whole screen a room pays for, GAME.md 8.5, the bloom and the
## multisampled edges. Both are worth what they cost on a card that can spare it and both are the
## first thing to give up on one that cannot: the bloom is about a tenth of the frame in The Vault,
## and the multisampling about a twentieth. A phone or a tablet smooths its edges with the cheap
## pass over the finished picture instead, for about a third of the price: something has to keep a
## room of straight lines from crawling.
var bloom := not OS.has_feature("mobile")
## One of [constant MSAA_SAMPLES], and one of [constant SMOOTHINGS].
var msaa := 0 if OS.has_feature("mobile") else 2
var screen_smoothing := SMOOTH_FXAA if OS.has_feature("mobile") else SMOOTH_OFF
## The marks the rear wheels leave on the floor, GAME.md 4.3. Off, none are laid, and whatever is
## down already goes at once.
var tire_marks := true
## How full the house is, one of [constant CROWD_SIZES]: the whole crowd, half of it, or nobody,
## which empties the stands and leaves the booth, GAME.md 8.5. The crowd is the most triangles on
## the screen by far and none of them are the match, 10.7, so a phone starts with half a house and
## a desktop with a full one. One setting, offered on the Video page and in Accessibility alike:
## it is both what a phone's card can afford and the busiest thing on screen that has nothing to
## do with the match.
var crowd_size := 0.5 if OS.has_feature("mobile") else 1.0
var screen_shake := true
var flash_reduction := false
## 0 to 1 of the default aim assist, never more.
var aim_assist := 1.0
var rumble := true
## Dots ahead of the cannon showing where shots go.
var aim_guide := true
## The moving-head lights over the arena, GAME.md 8.1, and whether only a few of them light at
## once: three heads rather than six at the top of the meter. Each lit head is a light over the
## whole table, and a phone's renderer pays for every one on every pixel of it, GAME.md 10.7, so
## a phone starts with a few.
var disco_lights := true
var disco_few := OS.has_feature("mobile")
## The on-screen reminders of which button does what, GAME.md 8.3.
var control_hints := true
## The player colors drawn for a kind of color blindness, one of [constant VISIONS].
var color_vision := ""
## The camera holding the whole arena instead of coming in on the karts, GAME.md 8.2. Off by
## default, because coming in is what makes a kart big enough to read; on, for a player who would
## rather have a picture that never moves than one that is close.
var fixed_camera := false
var stick_deadzone := 0.15
## How a touch screen drives, GAME.md 4.2: [constant TOUCH_SLIDER], one slider under the right thumb
## for nitro, gas, brake and drift, or [constant TOUCH_BUTTONS], a round button for each.
var touch_layout := TOUCH_SLIDER
## How each local seat drives, GAME.md 4.2, one of [constant DRIVE_MODES], or empty for a seat
## nobody has asked yet, which drives the advanced way until somebody does.
var drive_modes: Array[String] = ["", "", "", ""]
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
## How many jokers a hand holds, GAME.md 3.7.
var joker_slots := 5
## How many maps Play runs, GAME.md 9.7, and whether the host of an online room last chose a
## Grand Prix over a single map.
var grand_prix_maps := 3
var grand_prix := true
## What of their jokers players take from one map of a Grand Prix to the next, one of
## [enum GrandPrix.Keep]: the one each player picks, unless somebody chooses otherwise.
var grand_prix_jokers: int = GrandPrix.Keep.CHOOSE
## Which sizes of map a Grand Prix deals from, GAME.md 9.7: the usual ones, the XL ones, or both.
var grand_prix_normal := true
var grand_prix_xl := true
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
## Whether the tutorial of GAME.md 9.4a has been finished, and whether it has been offered, which
## the first Play does once.
var tutorial_done := false
var tutorial_offered := false
## The driver license the tutorial ends on, GAME.md 9.4a: its number and the day it was issued,
## empty until it has been, so the card reads the same every time it is looked at.
var license_number := ""
var license_date := ""
var last_address := "127.0.0.1"
var last_port := 7777
## The dedicated server Play Online last connected to, GAME.md 9.3a, and connects to again as it
## comes up. Empty until there has been one.
var last_server := ""
var last_server_port := ServerArgs.PORT
## How many may play in a LAN game this machine hosts, its own players included, GAME.md 9.6.
## Kept for next time; the password is not, so one forgotten is never a later lobby locked.
var lobby_players := NetDoor.MOST_PLAYERS
## Whether anybody may come to watch such a game, and whether they may without its password.
var lobby_watchers := true
var lobby_watch_free := false

var path := DEFAULT_PATH


func load_from_disk() -> void:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return
	master_volume = file.get_value("audio", "master", master_volume)
	music_volume = file.get_value("audio", "music", music_volume)
	sfx_volume = file.get_value("audio", "sfx", sfx_volume)
	kart_volume = file.get_value("audio", "kart", kart_volume)
	music_swell = clampf(
		float(file.get_value("audio", "music_swell", music_swell)), MusicSwell.OFF, MusicSwell.MOST
	)
	music_muted = file.get_value("audio", "music_muted", music_muted)
	muffle_on_death = file.get_value("audio", "muffle_on_death", muffle_on_death)
	fullscreen = file.get_value("video", "fullscreen", fullscreen)
	vsync = file.get_value("video", "vsync", vsync)
	var limit := int(file.get_value("video", "frame_limit", frame_limit))
	frame_limit = limit if limit in FRAME_LIMITS else frame_limit
	show_fps = file.get_value("video", "show_fps", show_fps)
	render_scale = file.get_value("video", "render_scale", render_scale)
	var upscaled := str(file.get_value("video", "upscaler", upscaler))
	upscaler = upscaled if upscaled in UPSCALERS else upscaler
	var shadowed := str(file.get_value("video", "shadows", shadows))
	shadows = shadowed if shadowed in SHADOW_LEVELS else shadows
	ui_scale = clampf(file.get_value("video", "ui_scale", ui_scale), UI_SCALES[0], UI_SCALES[-1])
	bloom = file.get_value("video", "bloom", bloom)
	# Kept as one switch, Edge smoothing, until the multisampling and the pass over the picture
	# could each be picked: on was the multisampling, off the pass.
	if file.has_section_key("video", "antialiasing"):
		var smoothed: bool = file.get_value("video", "antialiasing")
		msaa = 2 if smoothed else 0
		screen_smoothing = SMOOTH_OFF if smoothed else SMOOTH_FXAA
	var samples := int(file.get_value("video", "msaa", msaa))
	msaa = samples if samples in MSAA_SAMPLES else msaa
	var smoothing := str(file.get_value("video", "screen_smoothing", screen_smoothing))
	screen_smoothing = smoothing if smoothing in SMOOTHINGS else screen_smoothing
	tire_marks = file.get_value("video", "tire_marks", tire_marks)
	var housed := float(file.get_value("video", "crowd_size", crowd_size))
	crowd_size = housed if housed in CROWD_SIZES else crowd_size
	# The crowd was a switch of its own before it was a size, and a crowd switched off stays off.
	if not bool(file.get_value("accessibility", "crowd", true)):
		crowd_size = 0.0
	screen_shake = file.get_value("accessibility", "screen_shake", screen_shake)
	flash_reduction = file.get_value("accessibility", "flash_reduction", flash_reduction)
	aim_assist = clampf(
		file.get_value("accessibility", "aim_assist", aim_assist), 0.0, AIM_ASSIST_MAX
	)
	rumble = file.get_value("accessibility", "rumble", rumble)
	aim_guide = file.get_value("accessibility", "aim_guide", aim_guide)
	disco_lights = file.get_value("accessibility", "disco_lights", disco_lights)
	disco_few = file.get_value("accessibility", "disco_few", disco_few)
	control_hints = file.get_value("accessibility", "control_hints", control_hints)
	color_vision = str(file.get_value("accessibility", "color_vision", color_vision))
	if color_vision not in VISIONS:
		color_vision = ""
	fixed_camera = file.get_value("accessibility", "fixed_camera", fixed_camera)
	stick_deadzone = file.get_value("controls", "stick_deadzone", stick_deadzone)
	touch_layout = file.get_value("controls", "touch_layout", touch_layout)
	if touch_layout not in [TOUCH_SLIDER, TOUCH_BUTTONS]:
		touch_layout = TOUCH_SLIDER
	var driving: Array = file.get_value("controls", "drive_modes", [])
	for i: int in mini(driving.size(), drive_modes.size()):
		drive_modes[i] = str(driving[i]) if str(driving[i]) in DRIVE_MODES else ""
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
	joker_slots = int(file.get_value("lobby", "joker_slots", joker_slots))
	overtime = file.get_value("lobby", "overtime", overtime)
	grand_prix_maps = file.get_value("lobby", "grand_prix_maps", grand_prix_maps)
	grand_prix = file.get_value(
		"lobby", "grand_prix", file.get_value("lobby", "online_grand_prix", grand_prix)
	)
	grand_prix_jokers = file.get_value("lobby", "grand_prix_jokers", grand_prix_jokers)
	grand_prix_normal = file.get_value("lobby", "grand_prix_normal", grand_prix_normal)
	grand_prix_xl = file.get_value("lobby", "grand_prix_xl", grand_prix_xl)
	var stored: Array = file.get_value("lobby", "player_names", [])
	for i: int in mini(stored.size(), player_names.size()):
		player_names[i] = PlayerNames.clean(str(stored[i]))
	var dressed: Array = file.get_value("lobby", "kart_styles", [])
	for i: int in mini(dressed.size(), kart_styles.size()):
		kart_styles[i] = KartStyle.from_array(dressed[i]).to_array()
	tutorial_done = bool(file.get_value("progress", "tutorial_done", tutorial_done))
	tutorial_offered = bool(file.get_value("progress", "tutorial_offered", tutorial_offered))
	license_number = str(file.get_value("progress", "license_number", license_number))
	license_date = str(file.get_value("progress", "license_date", license_date))
	last_address = file.get_value("online", "address", last_address)
	last_port = file.get_value("online", "port", last_port)
	last_server = str(file.get_value("online", "server", last_server))
	last_server_port = int(file.get_value("online", "server_port", last_server_port))
	lobby_players = clampi(
		int(file.get_value("online", "lobby_players", lobby_players)),
		NetDoor.FEWEST_PLAYERS,
		NetDoor.MOST_PLAYERS
	)
	lobby_watchers = bool(file.get_value("online", "lobby_watchers", lobby_watchers))
	lobby_watch_free = bool(file.get_value("online", "lobby_watch_free", lobby_watch_free))


func save_to_disk() -> Error:
	var file := ConfigFile.new()
	file.set_value("audio", "master", master_volume)
	file.set_value("audio", "music", music_volume)
	file.set_value("audio", "sfx", sfx_volume)
	file.set_value("audio", "kart", kart_volume)
	file.set_value("audio", "music_swell", music_swell)
	file.set_value("audio", "music_muted", music_muted)
	file.set_value("audio", "muffle_on_death", muffle_on_death)
	file.set_value("video", "fullscreen", fullscreen)
	file.set_value("video", "vsync", vsync)
	file.set_value("video", "frame_limit", frame_limit)
	file.set_value("video", "show_fps", show_fps)
	file.set_value("video", "render_scale", render_scale)
	file.set_value("video", "upscaler", upscaler)
	file.set_value("video", "shadows", shadows)
	file.set_value("video", "ui_scale", ui_scale)
	file.set_value("video", "bloom", bloom)
	file.set_value("video", "msaa", msaa)
	file.set_value("video", "screen_smoothing", screen_smoothing)
	file.set_value("video", "tire_marks", tire_marks)
	file.set_value("video", "crowd_size", crowd_size)
	file.set_value("accessibility", "screen_shake", screen_shake)
	file.set_value("accessibility", "flash_reduction", flash_reduction)
	file.set_value("accessibility", "aim_assist", aim_assist)
	file.set_value("accessibility", "rumble", rumble)
	file.set_value("accessibility", "aim_guide", aim_guide)
	file.set_value("accessibility", "disco_lights", disco_lights)
	file.set_value("accessibility", "disco_few", disco_few)
	# Kept beside the size for a build from before the two were one, which reads only this.
	file.set_value("accessibility", "crowd", crowd_size > 0.0)
	file.set_value("accessibility", "control_hints", control_hints)
	file.set_value("accessibility", "color_vision", color_vision)
	file.set_value("accessibility", "fixed_camera", fixed_camera)
	file.set_value("controls", "stick_deadzone", stick_deadzone)
	file.set_value("controls", "touch_layout", touch_layout)
	file.set_value("controls", "drive_modes", drive_modes)
	file.set_value("controls", "bindings", bindings)
	file.set_value("lobby", "match_seconds", match_seconds)
	file.set_value("lobby", "target_score", target_score)
	file.set_value("lobby", "bot_count", bot_count)
	file.set_value("lobby", "difficulty", difficulty)
	file.set_value("lobby", "item_set", item_set)
	file.set_value("lobby", "map", map)
	file.set_value("lobby", "own_bullets_hurt", own_bullets_hurt)
	file.set_value("lobby", "joker_slots", joker_slots)
	file.set_value("lobby", "overtime", overtime)
	file.set_value("lobby", "grand_prix_maps", grand_prix_maps)
	file.set_value("lobby", "grand_prix", grand_prix)
	file.set_value("lobby", "grand_prix_jokers", grand_prix_jokers)
	file.set_value("lobby", "grand_prix_normal", grand_prix_normal)
	file.set_value("lobby", "grand_prix_xl", grand_prix_xl)
	file.set_value("lobby", "player_names", player_names)
	file.set_value("lobby", "kart_styles", kart_styles)
	file.set_value("progress", "tutorial_done", tutorial_done)
	file.set_value("progress", "tutorial_offered", tutorial_offered)
	file.set_value("progress", "license_number", license_number)
	file.set_value("progress", "license_date", license_date)
	file.set_value("online", "address", last_address)
	file.set_value("online", "port", last_port)
	file.set_value("online", "server", last_server)
	file.set_value("online", "server_port", last_server_port)
	file.set_value("online", "lobby_players", lobby_players)
	file.set_value("online", "lobby_watchers", lobby_watchers)
	file.set_value("online", "lobby_watch_free", lobby_watch_free)
	return file.save(path)


## How the local seat [param seat] drives, one of [constant DRIVE_MODES].
func drive_mode(seat: int) -> String:
	if seat < 0 or seat >= drive_modes.size() or drive_modes[seat].is_empty():
		return DRIVE_ADVANCED
	return drive_modes[seat]


## Whether the first seat has said how it drives yet, which the first Play asks, GAME.md 4.2.
func has_chosen_driving() -> bool:
	return not drive_modes[0].is_empty()


## The first answer to how to drive, for every seat that has not given one of its own.
func choose_driving(mode: String) -> void:
	for i: int in drive_modes.size():
		if drive_modes[i].is_empty():
			drive_modes[i] = mode


## Pushes every setting into the engine: buses, window, input map.
func apply(tree: SceneTree) -> void:
	apply_audio()
	apply_input()
	Palette.vision = color_vision
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
	Engine.max_fps = 0 if uncapped_for_now else frame_limit
	var wanted := DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	if DisplayServer.window_get_vsync_mode() != wanted:
		DisplayServer.window_set_vsync_mode(wanted)
	if tree != null and tree.root != null:
		tree.root.scaling_3d_scale = clampf(render_scale, 0.5, 1.0)
		tree.root.scaling_3d_mode = scaling_mode()
		_apply_shadows(tree)
		# Every menu and the HUD, drawn bigger or smaller; the room behind them stays as sharp.
		tree.root.content_scale_factor = ui_scale_for_now if ui_scale_for_now > 0.0 else ui_scale
		var multisampled: Array[Viewport.MSAA] = [
			Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X, Viewport.MSAA_8X
		]
		tree.root.msaa_3d = multisampled[maxi(MSAA_SAMPLES.find(msaa), 0)]
		var passes: Array[Viewport.ScreenSpaceAA] = [
			Viewport.SCREEN_SPACE_AA_DISABLED,
			Viewport.SCREEN_SPACE_AA_FXAA,
			Viewport.SCREEN_SPACE_AA_SMAA,
		]
		tree.root.screen_space_aa = passes[maxi(SMOOTHINGS.find(screen_smoothing), 0)]


## How big the shadow maps are and how soft their edges, from [member shadows]. Off, the lights
## cast none at all, see [method ArenaEnvironment.dress], and the maps are left at their smaller
## size.
func _apply_shadows(tree: SceneTree) -> void:
	var high := shadows == SHADOWS_HIGH
	var size := 4096 if high else 2048
	var edges := (
		RenderingServer.SHADOW_QUALITY_SOFT_LOW if high else RenderingServer.SHADOW_QUALITY_HARD
	)
	if tree.root.positional_shadow_atlas_size != size:
		RenderingServer.directional_shadow_atlas_set_size(size, true)
		tree.root.positional_shadow_atlas_size = size
	RenderingServer.directional_soft_shadow_filter_set_quality(edges)
	RenderingServer.positional_soft_shadow_filter_set_quality(edges)


## How the room is brought up to the screen's size, from [member upscaler]: FSR 2 only where the
## renderer has it, the desktop's, and FSR 1 in its place anywhere else.
func scaling_mode() -> Viewport.Scaling3DMode:
	match upscaler:
		UPSCALE_FSR:
			return Viewport.SCALING_3D_MODE_FSR
		UPSCALE_FSR2:
			if full_renderer():
				return Viewport.SCALING_3D_MODE_FSR2
			return Viewport.SCALING_3D_MODE_FSR
	return Viewport.SCALING_3D_MODE_BILINEAR


## Whether the room is drawn by the desktop's renderer, Forward+, rather than the lighter one a
## phone or a tablet has, which has no FSR 2, no ambient occlusion and no temporal smoothing.
static func full_renderer() -> bool:
	return RenderingServer.get_current_rendering_method() == "forward_plus"


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
