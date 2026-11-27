class_name Store
extends RefCounted
## The small layer of GAME.md 8.10 and 10.8 between the game and the store a build is made for:
## Steam in a Steam build, or from a checkout with `--steam`, and nobody in any other, which is
## every build on GitHub. Whatever the game tells a store goes through here, and with no store it
## goes nowhere. This is the switch and the start; [SteamStore] is Steam itself.

## Where a Steam build keeps the Steam app it is, written by `make steam-export` from STEAM_APP_ID
## and never committed.
const APP_FILE := "res://data/steam/app.cfg"
## Valve's Spacewar, which every Steam account may run: the app the game plays as until it has
## one of its own.
const SPACEWAR := 480
## GodotSteam's engine singleton, taken by its name so that no script names the class: a GitHub
## checkout has no such class, and a script naming it would not even parse there.
const SINGLETON := &"Steam"
## The bars a store draws no bar of, GAME.md 10.8: Know Every Street's target is the nearest
## district's, and moves.
const NO_BAR: Array[StringName] = [&"know_every_street"]
## A DLC's store page on the web, for a build with no overlay to open it in.
const STORE_PAGE := "https://store.steampowered.com/app/%d"
## Steam Input's controllers as the game's pads, GAME.md 10.8, by path: [SteamPads].
const STEAM_PADS := "res://scripts/store/steam_pads.gd"
## Where Steam names the controllers it reads for a game it starts, for the engine to leave them
## alone, see tools/steam-run; and what a run with Steam Input that has none says, in the log.
const IGNORED_ENV := "SDL_GAMECONTROLLER_IGNORE_DEVICES"
# The log's, NO_TRANSLATE.
const TWICE := (
	"Steam Input reads the controllers, but neither Steam nor make steam-run started the game, so"
	+ " the engine reads them too and each press may come twice"
)

## Steam, once started, or null: none wanted, none in this build, or none answering.
static var steam: SteamStore
## Why there is no Steam where one was wanted, for the screens that offer what Steam does, or
## empty: in English, as it is known before the settings say which language to speak, and
## translated where it is shown.
static var missing := ""
## Whether Steam is starting the game again itself, GAME.md 10.8, so this one quits at once.
static var restarting := false
## The lobby of a friend's game Steam started this game to join, `+connect_lobby <id>` on its
## command line, GAME.md 10.8, until it is joined; 0 for none.
static var asked_lobby := 0
## Steam started in the demo for a booth for its controllers alone, GAME.md 9.8, or null: Steam
## keeps the controllers from the engine for a game it starts with Steam Input on, so the demo
## reads them through Steam as the game does. Nothing else of Steam's is asked of it, achievements,
## presence, lobbies or the store, the demo's profile being nobody's.
static var for_pads: SteamStore


## Whether the game wants Steam, GAME.md 10.8: a Steam export, [param steam_build], or
## `--steam` among [param args], the game's own arguments; never with `--no-steam`, never when
## [param serving], a dedicated server or one of its games, and never in the demo for a booth,
## [param demo].
static func wanted(args: PackedStringArray, steam_build: bool, serving: bool, demo: bool) -> bool:
	if "--no-steam" in args or serving or demo:
		return false
	return steam_build or "--steam" in args


## Starts Steam when the game wants it, see [method wanted], from [Game] before the settings are
## read, since where they are read from depends on the account. An export with an app of its own,
## started outside Steam, is started again by Steam instead, [member restarting]. With no Steam,
## or none answering, the game plays on without it and [member missing] says why.
static func start(args: PackedStringArray, serving: bool) -> void:
	steam = null
	for_pads = null
	missing = ""
	restarting = false
	if not wanted(args, OS.has_feature("steam"), serving, Demo.on):
		var build := OS.has_feature("steam")
		if pads_wanted(args, build, serving, Demo.on, OS.get_environment(IGNORED_ENV)):
			_start_for_pads()
		return
	if not Engine.has_singleton(SINGLETON):
		missing = Lang.later("This build has no Steam in it")
		push_warning("Steam was asked for, but GodotSteam is not here: make steam-addon")
		return
	var app := app_id()
	var store := SteamStore.new(Engine.get_singleton(SINGLETON))
	if OS.has_feature("template") and app != SPACEWAR and store.restart_through_steam(app):
		restarting = true
		return
	missing = store.start(app)
	if missing.is_empty():
		steam = store
		asked_lobby = lobby_in(OS.get_cmdline_args())
		store.watch_dlc(recheck_supporter)
		# Which pad stands behind a pad Steam Input shows the game, for its buttons, GAME.md 8.3.
		store.watch_pads()
		PadFamily.behind_steam = store.pad_family


## Whether the demo for a booth, [param demo], wants Steam for its controllers alone, see
## [member for_pads]: Steam as the game would want it but for the demo, and the controllers kept
## from the engine, as Steam names them in [param ignored], [constant IGNORED_ENV]; none for a demo
## of a GitHub build, or one started outside Steam, which reads its controllers itself.
static func pads_wanted(
	args: PackedStringArray, steam_build: bool, serving: bool, demo: bool, ignored: String
) -> bool:
	if not demo or ignored.is_empty():
		return false
	return wanted(args, steam_build, serving, false)


## Steam started for the demo's controllers, see [member for_pads]: never started again by Steam,
## which would start it without `--demo`, and nothing more asked of it once it answers.
static func _start_for_pads() -> void:
	if not Engine.has_singleton(SINGLETON):
		return
	var store := SteamStore.new(Engine.get_singleton(SINGLETON))
	if not store.start(app_id()).is_empty():
		return
	for_pads = store
	store.watch_pads()
	PadFamily.behind_steam = store.pad_family


## The Steam its controllers are read through: the game's, or the demo's for them alone.
static func _input_steam() -> SteamStore:
	return steam if steam != null else for_pads


## Whether Steam Input reads the controllers for the game, GAME.md 10.8 "Steam Input": with Steam
## on, as the player has it in the settings, [param setting], unless this run says otherwise,
## `--steam-input` or `--no-steam-input` among [param args], the game's own arguments. In the demo
## on Steam's controllers alone, [member for_pads], always, there being no other way to them.
static func steam_input_wanted(args: PackedStringArray, setting: bool) -> bool:
	if _input_steam() == null or "--no-steam-input" in args:
		return false
	return setting or for_pads != null or "--steam-input" in args


## Steam Input started for the game, [param game], or stopped, as [param on] says, GAME.md 10.8:
## its controllers come as pads, or go. Nothing without Steam.
static func use_steam_input(game: Node, on: bool) -> void:
	var running := game.get_node_or_null(^"SteamPads")
	var reading := _input_steam()
	if on and running == null and reading != null:
		game.add_child(load(STEAM_PADS).new(reading.api))
		# A checkout's run that neither Steam nor `make steam-run` started, from the editor say.
		if not OS.has_feature("template") and not OS.has_environment(IGNORED_ENV):
			push_warning(TWICE)
	elif not on and running != null:
		# Out of the way at once, for it to be started again before the frame is out.
		running.name = "SteamPadsGoing"
		running.queue_free()


## The lobby `+connect_lobby <id>` among [param args], Godot's own arguments, names: Steam starts
## the game with it for a friend's game joined from the friends list or an invite accepted, the
## game not running yet. 0 for none.
static func lobby_in(args: PackedStringArray) -> int:
	var at := args.find("+connect_lobby")
	if at < 0 or at + 1 >= args.size() or not args[at + 1].is_valid_int():
		return 0
	return args[at + 1].to_int()


## Whether the account owns the supporter pack, GAME.md 10.8: Steam's word, asked every time and
## never saved, for the DLC the build names in [param path], [constant APP_FILE]. Never with no
## Steam or no DLC named, which every build is until the pack is made, M19's S8.
static func owns_supporter_pack(path := APP_FILE) -> bool:
	if steam == null:
		return false
	var dlc := supporter_dlc(path)
	return dlc != 0 and steam.owns(dlc)


## Whether the supporter pack is offered here, GAME.md 10.8: in a Steam build, or one started with
## `--steam`, that names the pack's DLC in [param path], [constant APP_FILE]. A build whose DLC is
## not set yet has no store page to send a player to, so it hangs none of the pieces locked.
static func offers_supporter_pack(path := APP_FILE) -> bool:
	return (steam != null or OS.has_feature("steam")) and supporter_dlc(path) != 0


## The supporter pack's DLC, from [param path], [constant APP_FILE]; 0 for none named.
static func supporter_dlc(path := APP_FILE) -> int:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return 0
	return int(file.get_value("steam", "supporter_dlc", 0))


## Opens the supporter pack's store page, GAME.md 10.8, in Steam's overlay where there is one, else
## in the browser; Steam is asked again once the overlay closes, see [method recheck_supporter].
## False with no pack to open, as in a build whose DLC is not set yet.
static func open_supporter() -> bool:
	Supporter.store_asked += 1
	var dlc := supporter_dlc()
	if dlc == 0 or Supporter.dry:
		return false
	if steam != null:
		steam.show_store(dlc)
	else:
		OS.shell_open(STORE_PAGE % dlc)
	return true


## Steam asked again whether the supporter pack is owned, GAME.md 10.8, for when it was bought while
## the game runs: whenever a DLC is installed and whenever the overlay closes, see
## [method SteamStore.watch_dlc]; the DLC as [param path], [constant APP_FILE], names it.
static func recheck_supporter(path := APP_FILE) -> void:
	Supporter.set_owned(owns_supporter_pack(path))


## The Steam app this build is, from [param path], [constant APP_FILE], or [constant SPACEWAR]
## with none.
static func app_id(path := APP_FILE) -> int:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return SPACEWAR
	return int(file.get_value("steam", "app_id", SPACEWAR))


## Whether Steam is there to be told things.
static func on() -> bool:
	return steam != null


## The account's name on Steam, as a seat may be called, for a profile made in a Steam build,
## GAME.md 10.8; empty with no Steam.
static func persona() -> String:
	return PlayerNames.clean(steam.persona()) if steam != null else ""


## The language the player has the game in on Steam, by Steam's name for it; empty with no Steam.
static func language() -> String:
	return steam.language() if steam != null else ""


## Which of Steam's own machines the game runs on, [constant SteamStore.NOT_STEAM_HARDWARE] for
## none or with no Steam.
static func hardware() -> int:
	var any := _input_steam()
	return any.hardware() if any != null else SteamStore.NOT_STEAM_HARDWARE


## Where the Steam account playing keeps its settings, its profiles beside them, GAME.md 10.8, the
## GitHub build's copied in the first time; empty with no Steam.
static func settings_path() -> String:
	if steam == null:
		return ""
	var path := SteamSaves.settings_path(steam.account)
	SteamSaves.bring_over(path)
	return path


## [param profile] has earned [param id], GAME.md 8.10: the store hears of it if it is the profile
## playing, and never of a linked seat's.
static func earned(profile: Profile, id: StringName) -> void:
	if steam != null and _playing(profile):
		steam.earned(id)


## Everything [param profile] has earned, and how far along its bars are, told to the store again,
## GAME.md 8.10: as the game starts and as the profile is switched to. A store is only ever told of
## more, so a profile with less takes nothing away there.
static func tell_all(profile: Profile) -> void:
	if steam == null or not _playing(profile):
		return
	for each: Achievement in Achievements.all():
		if profile.achievements.has(each.id):
			steam.earned(each.id)
	bars(profile)


## How far along [param profile]'s bars are, told to the store as statistics, GAME.md 10.8, when it
## is the profile playing.
static func bars(profile: Profile) -> void:
	if steam == null or not _playing(profile):
		return
	for each: Achievement in Achievements.all():
		if each.bar and each.id not in NO_BAR:
			steam.counted(each.id, Achievements.progress(profile, each).x)


## Whatever the store is still to be told, told now: at the whistle and on the way out.
static func flush() -> void:
	if steam != null:
		steam.flush()


## Whether [param profile] is the profile playing, GAME.md 8.10, whose achievements are the store
## account's: the machine's, the seat everybody else links beside.
static func _playing(profile: Profile) -> bool:
	return profile != null and not profile.transient and profile == Game.settings.profile


## A friend's game Steam started this game to join, GAME.md 10.8, asked for once the title is up
## and the shaders have compiled. Says whether there was one.
static func join_asked_at_launch() -> bool:
	if steam == null or asked_lobby == 0:
		return false
	var lobby := asked_lobby
	asked_lobby = 0
	steam.lobbies.asked.emit(lobby)
	return true


## Whether the game being played is a Steam game, GAME.md 10.8, hosted or joined.
static func steam_game() -> bool:
	return (
		steam != null and Net.online() and Game.pending_config != null and Game.pending_config.steam
	)


## Whether the game hosted here is a public Steam game, open to anyone, GAME.md 10.8.
static func public_game() -> bool:
	if not steam_game() or not steam.lobbies.hosting:
		return false
	return steam.lobbies.who == SteamLobby.Who.ANYONE


## Whether the player has blocked the account [param account] on Steam, GAME.md 10.8: never with
## no Steam, nor for no account.
static func blocked(account: int) -> bool:
	return steam != null and steam.lobbies != null and steam.lobbies.blocked(account)


## The game being played is over for this machine: a Steam game's lobby is left, GAME.md 10.8, but
## while the game is handed to another host, which keeps it once.
static func left_game() -> void:
	if steam != null and steam.lobbies != null:
		if steam.lobbies.handing_over:
			steam.lobbies.handing_over = false
			return
		steam.lobbies.leave()
