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

## Steam, once started, or null: none wanted, none in this build, or none answering.
static var steam: SteamStore
## Why there is no Steam where one was wanted, for the screens that offer what Steam does, or
## empty.
static var missing := ""
## Whether Steam is starting the game again itself, GAME.md 10.8, so this one quits at once.
static var restarting := false


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
	missing = ""
	restarting = false
	if not wanted(args, OS.has_feature("steam"), serving, Demo.on):
		return
	if not Engine.has_singleton(SINGLETON):
		missing = "This build has no Steam in it"
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
