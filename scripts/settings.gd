class_name Settings
extends RefCounted
## User settings from GAME.md 8.5, saved between sessions with ConfigFile: how this machine is set
## up, the picture, the sound, the controls and the lobby's choices, and which [Profile] is
## playing on it. What belongs to the person rather than the machine, their names, karts, ways to
## drive, license and servers, is the profile's, kept in a file of its own, and read and written
## here through the same names as ever, see [member profile].

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
## The tire marks, GAME.md 4.3: every kart's lasting, every kart's fading soon, only the karts of
## the players at this screen and fading soon as well, or none, and what each is called.
const MARKS_FULL := 0
const MARKS_SHORT := 1
const MARKS_MINE := 2
const MARKS_OFF := 3
const MARKS_NAMES: Array[String] = ["Full", "Short", "Mine", "Off"]
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
## 0 for not at all, up to [constant MusicSwell.MOST], starting from a gentle one.
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
## What the camera keeps the karts clear of, drawn over a match, see [ClearanceView]: the settings'
## Debug page's, in a debug build.
var show_clearance := false
## A phone or a tablet draws its room at four fifths of the screen's size to start with, and
## without the two passes below: a phone's card is the one that cannot spare them.
var render_scale := 0.8 if OS.has_feature("mobile") else 1.0
## One of [constant UPSCALERS].
var upscaler := UPSCALE_BILINEAR
## How the room is drawn, one of [constant RenderLook.LOOKS], GAME.md 8.1b: the tin and the
## table under the cel look, the toon light with a keyline over it, by default. A phone has the
## toon light without the pass over the frame, which its card pays the most for.
var look := "toon" if OS.has_feature("mobile") else "cel"
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
## The marks the rear wheels leave on the floor, GAME.md 4.3, one of the MARKS_ constants: fewer
## is less to draw and less on the floor, which a phone starts with. Marks a kart may no longer
## lay go at once.
var tire_marks := MARKS_SHORT if OS.has_feature("mobile") else MARKS_FULL
## How full the house is, one of [constant CROWD_SIZES]: the whole crowd, half of it, or nobody,
## which empties the stands and leaves the booth, GAME.md 8.5. The crowd is the most triangles on
## the screen by far and none of them are the match, 10.7, so a phone starts with half a house and
## a desktop with a full one. One setting, offered on the Video page and in Accessibility alike:
## it is both what a phone's card can afford and the busiest thing on screen that has nothing to
## do with the match.
var crowd_size := 0.5 if OS.has_feature("mobile") else 1.0
var screen_shake := true
var flash_reduction := false
## The gold frame gliding from one button to the next as the cursor moves, GAME.md 8.1a. On by
## default; off for anybody the motion bothers, and the focused button still wears its frame.
var cursor_glide := true
## 0 to 1 of the default aim assist, never more.
var aim_assist := 1.0
var rumble := true
## Dots ahead of the cannon showing where shots go.
var aim_guide := true
## How the aim guide is drawn, GAME.md 8.5: how many dots run out ahead, how big each is of its own
## size, how solid, and in which of [constant AIM_GUIDE_STYLES], the player's color by default.
var aim_guide_length := AimGuide.DOTS
var aim_guide_size := 1.0
var aim_guide_opacity := AimGuide.ALPHA
var aim_guide_style := 0
## The moving-head lights over the arena, GAME.md 8.1, and whether only a few of them light at
## once: three heads rather than six at the top of the meter. Each lit head is a light over the
## whole table, and a phone's renderer pays for every one on every pixel of it, GAME.md 10.7, so
## a phone starts with a few.
var disco_lights := true
var disco_few := OS.has_feature("mobile")
## The on-screen reminders of which button does what, GAME.md 8.3.
var control_hints := true
## How the speedometer counts, [constant SpeedUnits.KMH] or [constant SpeedUnits.MPH], once the
## player has chosen; empty until they do, when the system's locale says, see [method speed_unit].
var speed_unit_chosen := ""
## The drive and fire hint over a kart at the start of every map, GAME.md 3.8, rather than only the
## first room a seat plays in.
var always_drive_hints := false
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
## How many teams a match is split into, 0 for none, and whether teammates can hurt each other,
## GAME.md 3.14.
var teams := 0
var friendly_fire := false
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
## Whether karts level on points at the end of a Grand Prix play a showdown to settle it, GAME.md
## 9.7a, rather than going by maps won.
var grand_prix_tie_breaker := true
## Whether a map at the usual size is played as picked with more than four karts on it, GAME.md
## 6.3, rather than as its XL.
var small_maps := false
## Whether the match settings' two columns, The floor and House rules, are open rather than folded,
## GAME.md 9.6: folded the first time, so somebody new sees what the match is rather than every way
## of changing it, and as they were left after that.
var floor_open := false
var rules_open := false
## The order the achievements are listed in, GAME.md 8.10, see [enum AchievementsDialog.Order]:
## the machine's, whoever is playing.
var achievement_order := 0
## Whether the achievements' list leaves out those already earned, GAME.md 8.10: the machine's too.
var achievements_hide_earned := false
## The person playing at this machine, GAME.md 8.5: whose names, karts, license and servers the
## names below read and write, see [Profile]. Switched from the settings' Profiles page.
var profile := Profile.new()
## For this sitting alone, never saved: which profile each other seat at this screen plays as, by
## its id, or empty for a guest of the profile playing, kept in it. The first seat is always the
## profile playing. Gone at the title, see [method unlink_all], GAME.md 3.8.
var linked: Array[String] = ["", "", "", ""]
## What each local seat calls itself, how it dressed its kart and how it drives, its license and
## plate, how far through the driving school it got, and where it last played: the profile's.
var player_names: Array[String]:
	get:
		return profile.player_names
	set(value):
		profile.player_names = value
var kart_styles: Array:
	get:
		return profile.kart_styles
	set(value):
		profile.kart_styles = value
var drive_modes: Array[String]:
	get:
		return profile.drive_modes
	set(value):
		profile.drive_modes = value
var tutorial_done: bool:
	get:
		return profile.tutorial_done
	set(value):
		profile.tutorial_done = value
var license_number: String:
	get:
		return profile.license_number
	set(value):
		profile.license_number = value
var license_date: String:
	get:
		return profile.license_date
	set(value):
		profile.license_date = value
var license_holder: String:
	get:
		return profile.license_holder
	set(value):
		profile.license_holder = value
var license_endorsements: PackedStringArray:
	get:
		return profile.license_endorsements
	set(value):
		profile.license_endorsements = value
var license_plate: String:
	get:
		return profile.license_plate
	set(value):
		profile.license_plate = value
var last_address: String:
	get:
		return profile.last_address
	set(value):
		profile.last_address = value
var last_port: int:
	get:
		return profile.last_port
	set(value):
		profile.last_port = value
var last_server: String:
	get:
		return profile.last_server
	set(value):
		profile.last_server = value
var last_server_port: int:
	get:
		return profile.last_server_port
	set(value):
		profile.last_server_port = value
## The dedicated servers the player keeps a list of, GAME.md 9.3a, see [ServerList]: the profile's.
var servers: Array[Dictionary]:
	get:
		return profile.servers
	set(value):
		profile.servers = value
## How many may play in a LAN game this machine hosts, its own players included, GAME.md 9.6.
## Kept for next time; the password is not, so one forgotten is never a later lobby locked.
var lobby_players := NetDoor.DEFAULT_PLAYERS
## Whether anybody may come to watch such a game, and whether they may without its password.
var lobby_watchers := true
var lobby_watch_free := false
## Whether a Steam game this machine hosts is for those invited alone rather than every friend,
## GAME.md 10.8; kept too. And which of Play Online's tabs was last up, by name: Steam friends,
## Servers or LAN, see play_online.gd.
var lobby_invite_only := false
var play_online_tab := ""
## What such a game is called, empty for its host's name, see [member NetDoor.title]; kept too.
var lobby_title := ""

var path := DEFAULT_PATH
## The profile the file names as the one playing, which it goes on naming while a profile that is
## never written plays, the demo's, GAME.md 9.8.
var named := "1"
## The profiles linked to seats, read once.
var _linked_profiles: Dictionary[String, Profile] = {}


func load_from_disk() -> void:
	var file := ConfigFile.new()
	var read := not path.is_empty() and SafeFile.read(file, path) == OK
	if read:
		load_machine(file)
	# A file from before profiles names none, and starts the first one afresh: nothing of who
	# played is carried over from it, GAME.md 8.5.
	var active := str(file.get_value("profile", "active", "1")) if read else "1"
	named = active if not active.is_empty() else "1"
	profile = Profile.at(profiles_dir(), named)
	# The first profile of a machine new to the game, a color of its own picked for it.
	if profile.made_new:
		profile.pick_a_color()


## The machine's part of the settings in [param file], GAME.md 8.5: everything but the profiles.
func load_machine(file: ConfigFile) -> void:
	master_volume = file.get_value("audio", "master", master_volume)
	music_volume = file.get_value("audio", "music", music_volume)
	sfx_volume = file.get_value("audio", "sfx", sfx_volume)
	kart_volume = file.get_value("audio", "kart", kart_volume)
	music_swell = MusicSwell.read(float(file.get_value("audio", "music_swell", music_swell)))
	music_muted = file.get_value("audio", "music_muted", music_muted)
	muffle_on_death = file.get_value("audio", "muffle_on_death", muffle_on_death)
	fullscreen = file.get_value("video", "fullscreen", fullscreen)
	vsync = file.get_value("video", "vsync", vsync)
	var limit := int(file.get_value("video", "frame_limit", frame_limit))
	frame_limit = limit if limit in FRAME_LIMITS else frame_limit
	show_fps = file.get_value("video", "show_fps", show_fps)
	show_clearance = file.get_value("debug", "show_clearance", show_clearance)
	render_scale = file.get_value("video", "render_scale", render_scale)
	var upscaled := str(file.get_value("video", "upscaler", upscaler))
	upscaler = upscaled if upscaled in UPSCALERS else upscaler
	var looked := str(file.get_value("video", "look", look))
	look = looked if looked in RenderLook.LOOKS else look
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
	# On or off, before there was a choice of how many.
	var marked: Variant = file.get_value("video", "tire_marks", tire_marks)
	if marked is bool:
		tire_marks = MARKS_FULL if marked else MARKS_OFF
	elif marked is int and int(marked) >= 0 and int(marked) < MARKS_NAMES.size():
		tire_marks = marked
	var housed := float(file.get_value("video", "crowd_size", crowd_size))
	crowd_size = housed if housed in CROWD_SIZES else crowd_size
	# The crowd was a switch of its own before it was a size, and a crowd switched off stays off.
	if not bool(file.get_value("accessibility", "crowd", true)):
		crowd_size = 0.0
	screen_shake = file.get_value("accessibility", "screen_shake", screen_shake)
	flash_reduction = file.get_value("accessibility", "flash_reduction", flash_reduction)
	cursor_glide = file.get_value("accessibility", "cursor_glide", cursor_glide)
	aim_assist = clampf(
		file.get_value("accessibility", "aim_assist", aim_assist), 0.0, AIM_ASSIST_MAX
	)
	rumble = file.get_value("accessibility", "rumble", rumble)
	aim_guide = file.get_value("accessibility", "aim_guide", aim_guide)
	aim_guide_length = clampi(
		int(file.get_value("accessibility", "aim_guide_length", aim_guide_length)),
		AimGuide.FEWEST,
		AimGuide.MOST
	)
	aim_guide_size = clampf(
		float(file.get_value("accessibility", "aim_guide_size", aim_guide_size)),
		AimGuide.SMALLEST,
		AimGuide.BIGGEST
	)
	aim_guide_opacity = clampf(
		float(file.get_value("accessibility", "aim_guide_opacity", aim_guide_opacity)),
		AimGuide.FAINTEST,
		1.0
	)
	aim_guide_style = clampi(
		int(file.get_value("accessibility", "aim_guide_style", aim_guide_style)),
		0,
		AimGuide.STYLES.size() - 1
	)
	disco_lights = file.get_value("accessibility", "disco_lights", disco_lights)
	disco_few = file.get_value("accessibility", "disco_few", disco_few)
	control_hints = file.get_value("accessibility", "control_hints", control_hints)
	speed_unit_chosen = str(file.get_value("accessibility", "speed_unit", ""))
	if speed_unit_chosen not in [SpeedUnits.KMH, SpeedUnits.MPH]:
		speed_unit_chosen = ""
	always_drive_hints = file.get_value("accessibility", "always_drive_hints", always_drive_hints)
	color_vision = str(file.get_value("accessibility", "color_vision", color_vision))
	if color_vision not in VISIONS:
		color_vision = ""
	fixed_camera = file.get_value("accessibility", "fixed_camera", fixed_camera)
	stick_deadzone = file.get_value("controls", "stick_deadzone", stick_deadzone)
	touch_layout = file.get_value("controls", "touch_layout", touch_layout)
	if touch_layout not in [TOUCH_SLIDER, TOUCH_BUTTONS]:
		touch_layout = TOUCH_SLIDER
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
	teams = int(file.get_value("lobby", "teams", teams))
	friendly_fire = bool(file.get_value("lobby", "friendly_fire", friendly_fire))
	grand_prix_maps = file.get_value("lobby", "grand_prix_maps", grand_prix_maps)
	grand_prix = file.get_value(
		"lobby", "grand_prix", file.get_value("lobby", "online_grand_prix", grand_prix)
	)
	grand_prix_jokers = file.get_value("lobby", "grand_prix_jokers", grand_prix_jokers)
	grand_prix_normal = file.get_value("lobby", "grand_prix_normal", grand_prix_normal)
	grand_prix_xl = file.get_value("lobby", "grand_prix_xl", grand_prix_xl)
	grand_prix_tie_breaker = file.get_value(
		"lobby", "grand_prix_tie_breaker", grand_prix_tie_breaker
	)
	small_maps = file.get_value("lobby", "small_maps", small_maps)
	floor_open = bool(file.get_value("lobby", "floor_open", floor_open))
	rules_open = bool(file.get_value("lobby", "rules_open", rules_open))
	achievement_order = int(file.get_value("achievements", "order", achievement_order))
	achievements_hide_earned = bool(
		file.get_value("achievements", "hide_earned", achievements_hide_earned)
	)
	lobby_players = clampi(
		int(file.get_value("online", "lobby_players", lobby_players)),
		NetDoor.FEWEST_PLAYERS,
		NetDoor.MOST_PLAYERS
	)
	lobby_watchers = bool(file.get_value("online", "lobby_watchers", lobby_watchers))
	lobby_watch_free = bool(file.get_value("online", "lobby_watch_free", lobby_watch_free))
	lobby_invite_only = bool(file.get_value("online", "lobby_invite_only", lobby_invite_only))
	play_online_tab = str(file.get_value("online", "play_online_tab", play_online_tab))
	lobby_title = PlayerNames.clean(
		str(file.get_value("online", "lobby_title", lobby_title)), PlayerNames.TITLE_LENGTH
	)


func save_to_disk() -> Error:
	# Settings with no file are never written, nor their profiles, see [method profiles_dir].
	if path.is_empty():
		return OK
	# A Steam account's folder is there to write in from its first save, GAME.md 10.8.
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := ConfigFile.new()
	write_machine(file)
	if not profile.transient:
		named = profile.id
	file.set_value("profile", "active", named)
	# Beside wherever these settings are written now, which a test sets after making them.
	var folder := profiles_dir()
	profile.path = folder.path_join(profile.id + ".cfg") if not folder.is_empty() else ""
	profile.save_to_disk()
	for each: Profile in _linked_profiles.values():
		each.save_to_disk()
	return SafeFile.save(file, path)


## The machine's part of the settings into [param file], GAME.md 8.5: everything but the profiles,
## as [method load_machine] reads it back.
func write_machine(file: ConfigFile) -> void:
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
	file.set_value("debug", "show_clearance", show_clearance)
	file.set_value("video", "render_scale", render_scale)
	file.set_value("video", "upscaler", upscaler)
	file.set_value("video", "shadows", shadows)
	file.set_value("video", "look", look)
	file.set_value("video", "ui_scale", ui_scale)
	file.set_value("video", "bloom", bloom)
	file.set_value("video", "msaa", msaa)
	file.set_value("video", "screen_smoothing", screen_smoothing)
	file.set_value("video", "tire_marks", tire_marks)
	file.set_value("video", "crowd_size", crowd_size)
	file.set_value("accessibility", "screen_shake", screen_shake)
	file.set_value("accessibility", "flash_reduction", flash_reduction)
	file.set_value("accessibility", "cursor_glide", cursor_glide)
	file.set_value("accessibility", "aim_assist", aim_assist)
	file.set_value("accessibility", "rumble", rumble)
	file.set_value("accessibility", "aim_guide", aim_guide)
	file.set_value("accessibility", "aim_guide_length", aim_guide_length)
	file.set_value("accessibility", "aim_guide_size", aim_guide_size)
	file.set_value("accessibility", "aim_guide_opacity", aim_guide_opacity)
	file.set_value("accessibility", "aim_guide_style", aim_guide_style)
	file.set_value("accessibility", "disco_lights", disco_lights)
	file.set_value("accessibility", "disco_few", disco_few)
	# Kept beside the size for a build from before the two were one, which reads only this.
	file.set_value("accessibility", "crowd", crowd_size > 0.0)
	file.set_value("accessibility", "control_hints", control_hints)
	if not speed_unit_chosen.is_empty():
		file.set_value("accessibility", "speed_unit", speed_unit_chosen)
	file.set_value("accessibility", "always_drive_hints", always_drive_hints)
	file.set_value("accessibility", "color_vision", color_vision)
	file.set_value("accessibility", "fixed_camera", fixed_camera)
	file.set_value("controls", "stick_deadzone", stick_deadzone)
	file.set_value("controls", "touch_layout", touch_layout)
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
	file.set_value("lobby", "teams", teams)
	file.set_value("lobby", "friendly_fire", friendly_fire)
	file.set_value("lobby", "grand_prix_maps", grand_prix_maps)
	file.set_value("lobby", "grand_prix", grand_prix)
	file.set_value("lobby", "grand_prix_jokers", grand_prix_jokers)
	file.set_value("lobby", "grand_prix_normal", grand_prix_normal)
	file.set_value("lobby", "grand_prix_xl", grand_prix_xl)
	file.set_value("lobby", "grand_prix_tie_breaker", grand_prix_tie_breaker)
	file.set_value("lobby", "small_maps", small_maps)
	file.set_value("lobby", "floor_open", floor_open)
	file.set_value("lobby", "rules_open", rules_open)
	file.set_value("achievements", "order", achievement_order)
	file.set_value("achievements", "hide_earned", achievements_hide_earned)
	file.set_value("online", "lobby_players", lobby_players)
	file.set_value("online", "lobby_watchers", lobby_watchers)
	file.set_value("online", "lobby_watch_free", lobby_watch_free)
	file.set_value("online", "lobby_invite_only", lobby_invite_only)
	file.set_value("online", "play_online_tab", play_online_tab)
	file.set_value("online", "lobby_title", lobby_title)


## Where the profiles are kept: a folder beside the settings file, or none for settings that are
## never written. Beside a player's own, [constant DEFAULT_PATH] or a Steam account's, GAME.md 10.8,
## it is `profiles`.
func profiles_dir() -> String:
	if path.is_empty():
		return ""
	if _players_own(path):
		return path.get_base_dir().path_join("profiles")
	return path.get_basename() + ".profiles"


## Whether the settings at [param at] are a player's own, [constant DEFAULT_PATH] or a Steam
## account's, rather than a test's or a tool's: they are called settings.cfg wherever they are.
static func _players_own(at: String) -> bool:
	return at.get_file() == DEFAULT_PATH.get_file()


## Every profile kept, the one playing among them, in the order they were made.
func profiles() -> Array[Profile]:
	var found: Array[Profile] = [profile]
	var folder := profiles_dir()
	var ids: Array[int] = []
	var kept := not folder.is_empty() and DirAccess.dir_exists_absolute(folder)
	for file: String in DirAccess.get_files_at(folder) if kept else []:
		# One whose file was lost between being set aside and its new one put in its place is
		# kept all the same, as its backup, see [SafeFile].
		var kept_as := file.trim_suffix(SafeFile.BACKUP)
		if kept_as.get_extension() == "cfg" and kept_as.get_basename().is_valid_int():
			if int(kept_as.get_basename()) not in ids:
				ids.append(int(kept_as.get_basename()))
	ids.sort()
	for number: int in ids:
		var id := str(number)
		if id != profile.id:
			# A linked one as its seat has it, so nothing done to it here is lost on the next save.
			found.append(
				_linked_profiles[id] if _linked_profiles.has(id) else Profile.at(folder, id)
			)
	found.sort_custom(func(a: Profile, b: Profile) -> bool: return int(a.id) < int(b.id))
	return found


## A new profile, kept at once, or null when there are [constant Profile.MOST] already.
func new_profile() -> Profile:
	var kept := profiles()
	if kept.size() >= Profile.MOST:
		return null
	var number := 1
	for each: Profile in kept:
		number = maxi(number, int(each.id) + 1)
	var made := Profile.at(profiles_dir(), str(number))
	# Named after the Steam account playing, in a Steam build, GAME.md 10.8.
	made.player_names[0] = Store.persona()
	made.pick_a_color()
	made.save_to_disk()
	return made


## Plays as the profile kept as [param id] from now on, the one playing saved first.
func switch_profile(id: String) -> void:
	if id == profile.id:
		return
	profile.save_to_disk()
	profile = Profile.at(profiles_dir(), id)
	save_to_disk()
	# The store hears everything the profile switched to has earned, GAME.md 8.10.
	Store.tell_all(profile)


## Throws the profile kept as [param id] away, file and all. Never the one playing, nor one a seat
## plays as.
func delete_profile(id: String) -> bool:
	if id == profile.id or id in linked or profiles_dir().is_empty():
		return false
	return SafeFile.remove(profiles_dir().path_join(id + ".cfg")) == OK


## The settings file at [param at] and the profiles kept beside it, gone, for a test that wrote
## them. Never a player's own, whatever a test asks, nor a Steam account's.
static func remove_files(at: String) -> void:
	if at.is_empty() or _players_own(at):
		push_error("Settings.remove_files: the player's own settings are not a test's to remove")
		return
	var settings := Settings.new()
	settings.path = at
	var folder := settings.profiles_dir()
	if not folder.is_empty() and DirAccess.dir_exists_absolute(folder):
		for file: String in DirAccess.get_files_at(folder):
			DirAccess.remove_absolute(folder.path_join(file))
		DirAccess.remove_absolute(folder)
	SafeFile.remove(at)


## How the speedometer counts, GAME.md 8.5: as the player chose, or as the system's locale says,
## see [SpeedUnits].
func speed_unit() -> String:
	return SpeedUnits.resolve(speed_unit_chosen, SpeedUnits.system_locale())


## How the local seat [param seat] drives, one of [constant DRIVE_MODES]: its linked profile's way,
## or its own.
func drive_mode(seat: int) -> String:
	var own := seat_profile(seat)
	if own != null:
		return own.drive_modes[0] if not own.drive_modes[0].is_empty() else DRIVE_ADVANCED
	if seat < 0 or seat >= drive_modes.size() or drive_modes[seat].is_empty():
		return DRIVE_ADVANCED
	return drive_modes[seat]


## [param seat] drives [param mode] from now on, kept in its linked profile or in this one.
func set_drive_mode(seat: int, mode: String) -> void:
	var own := seat_profile(seat)
	if own != null:
		own.drive_modes[0] = mode
	elif seat >= 0 and seat < drive_modes.size():
		drive_modes[seat] = mode


## Whether [param seat]'s simple driving works the pedals by itself, GAME.md 4.2: its linked
## profile's say, or its own. Off to start with.
func auto_throttle(seat: int) -> bool:
	var own := seat_profile(seat)
	if own != null:
		return own.auto_throttle[0]
	var kept := profile.auto_throttle
	return seat >= 0 and seat < kept.size() and kept[seat]


## [param seat]'s simple driving works the pedals by itself from now on, or not, kept in its linked
## profile or in this one.
func set_auto_throttle(seat: int, on: bool) -> void:
	var own := seat_profile(seat)
	if own != null:
		own.auto_throttle[0] = on
	elif seat >= 0 and seat < profile.auto_throttle.size():
		profile.auto_throttle[seat] = on


## The profile linked to [param seat], GAME.md 3.8, or null for the first seat and a guest.
func seat_profile(seat: int) -> Profile:
	if seat <= 0 or seat >= linked.size() or linked[seat].is_empty():
		return null
	var id := linked[seat]
	if not _linked_profiles.has(id):
		_linked_profiles[id] = Profile.at(profiles_dir(), id)
	return _linked_profiles[id]


## The profiles [param seat] may be linked to: every one kept but the one playing and those linked
## to other seats.
func linkable(seat: int) -> Array[Profile]:
	var free: Array[Profile] = []
	for each: Profile in profiles():
		if each.id != profile.id and (each.id not in linked or linked[seat] == each.id):
			free.append(each)
	return free


## [param seat] plays as the profile kept as [param id] from now on, or as a guest again for an
## empty one. Never the first seat, never the profile playing, never one another seat has.
func link_seat(seat: int, id: String) -> bool:
	if seat <= 0 or seat >= linked.size():
		return false
	if not id.is_empty() and (id == profile.id or (id in linked and linked[seat] != id)):
		return false
	linked[seat] = id
	return true


## Every seat back to being a guest, as at the title.
func unlink_all() -> void:
	if not _linked_profiles.is_empty():
		save_to_disk()
	linked = ["", "", "", ""]
	_linked_profiles.clear()


## What [param seat] is called: its linked profile's first player, or its own entry.
func seat_name(seat: int) -> String:
	var own := seat_profile(seat)
	if own != null:
		return own.player_names[0]
	return player_names[seat] if seat >= 0 and seat < player_names.size() else ""


func set_seat_name(seat: int, named: String) -> void:
	var own := seat_profile(seat)
	if own != null:
		own.player_names[0] = named
	elif seat >= 0 and seat < player_names.size():
		player_names[seat] = named


## How [param seat]'s kart is dressed: its linked profile's first kart, or its own; undressed for
## a seat past the last.
## With the finishes the seat's profile has moved its pieces up to after the choices, GAME.md
## 8.9; the finishes are the profile's, never kept with the style.
func seat_style(seat: int) -> PackedInt32Array:
	var own := seat_profile(seat)
	if own != null:
		return Loyalty.with_finishes(own, PackedInt32Array(own.kart_styles[0]))
	if seat < 0 or seat >= kart_styles.size():
		return PackedInt32Array()
	return Loyalty.with_finishes(profile, PackedInt32Array(kart_styles[seat]))


## Keeps [param style]'s choices, its finishes being the profile's.
func set_seat_style(seat: int, style: PackedInt32Array) -> void:
	var kept := style.slice(0, KartStyle.CHOICES.size())
	var own := seat_profile(seat)
	if own != null:
		own.kart_styles[0] = kept
	elif seat >= 0 and seat < kart_styles.size():
		kart_styles[seat] = kept


## [param seat]'s favorite color, GAME.md 3.8: its linked profile's first seat's, or its own in
## the profile playing; -1 for none.
func seat_color(seat: int) -> int:
	var own := seat_profile(seat)
	if own != null:
		return own.colors[0]
	return profile.colors[seat] if seat >= 0 and seat < profile.colors.size() else -1


func set_seat_color(seat: int, color: int) -> void:
	var own := seat_profile(seat)
	if own != null:
		own.colors[0] = color
	elif seat >= 0 and seat < profile.colors.size():
		profile.colors[seat] = color


## Every seat's favorite color, links and all, for a match's configuration.
func seat_colors() -> Array[int]:
	var picked: Array[int] = []
	for seat: int in player_names.size():
		picked.append(seat_color(seat))
	return picked


## What [param seat]'s kart wears on its back, as the wire says it: "L" before a license, or the
## plate; its linked profile's, or the profile playing's, whose guests wear its plate.
func seat_plate(seat: int) -> String:
	var own := seat_profile(seat)
	var whose := own if own != null else profile
	return "L" if whose.license_number.is_empty() else whose.license_plate


## Each seat's name and dress, links and all, for a match's configuration.
func seat_names() -> Array[String]:
	var names: Array[String] = []
	for seat: int in player_names.size():
		names.append(seat_name(seat))
	return names


func seat_styles() -> Array:
	var styles: Array = []
	for seat: int in kart_styles.size():
		styles.append(seat_style(seat))
	return styles


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
		var game := tree.root.get_node_or_null("Game")
		if game != null:
			RenderLook.of(game).use(look)


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


## The aim guide drawn as it is to start with, GAME.md 8.5: its length, size, opacity and color;
## its switch left as it is.
func reset_aim_guide() -> void:
	aim_guide_length = AimGuide.DOTS
	aim_guide_size = 1.0
	aim_guide_opacity = AimGuide.ALPHA
	aim_guide_style = 0


## Whether the aim guide is drawn as it is to start with, see [method reset_aim_guide].
func aim_guide_as_at_first() -> bool:
	return (
		aim_guide_length == AimGuide.DOTS
		and is_equal_approx(aim_guide_size, 1.0)
		and is_equal_approx(aim_guide_opacity, AimGuide.ALPHA)
		and aim_guide_style == 0
	)


func _set_bus(bus: StringName, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(index, linear <= 0.0001)
