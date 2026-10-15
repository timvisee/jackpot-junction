class_name SteamStore
extends RefCounted
## Steam, through GodotSteam, GAME.md 10.8: the one script that talks to it. GodotSteam's
## singleton is held as a plain [Object] and called by name, so this compiles with no GodotSteam
## in the project at all; the tests hand it a [FakeSteam] instead, and so never talk to Steam.

## What starting Steam answers, GodotSteam's `status`: started, no Steam client running, or a
## client too old for this game's SDK.
const STARTED := 0
const NO_CLIENT := 2
const OLD_CLIENT := 3

## GodotSteam's `Steam`, or a stand-in for it.
var api: Object
## The Steam app started as, and the account playing, its SteamID64, once started.
var app := 0
var account := 0


func _init(steam_api: Object) -> void:
	api = steam_api


## Whether Steam starts the game itself as [param app_id], having been started outside it, in which
## case this one is to quit at once, GAME.md 10.8.
func restart_through_steam(app_id: int) -> bool:
	return bool(api.call(&"restartAppIfNecessary", app_id))


## Starts Steam as [param app_id], always named rather than taken from the environment: a game run
## from an editor that Steam started is otherwise the editor's app. GodotSteam runs Steam's
## callbacks itself every frame. Says why it did not start, or nothing once it has.
func start(app_id: int) -> String:
	var answer: Dictionary = api.call(&"steamInitEx", app_id, true)
	var status := int(answer.get("status", -1))
	if status != STARTED:
		push_warning("Steam did not start: %s (%d)" % [answer.get("verbal", ""), status])
		if status == NO_CLIENT:
			return "Steam isn't running"
		if status == OLD_CLIENT:
			return "Steam needs updating"
		return "Steam did not start"
	app = app_id
	account = int(api.call(&"getSteamID"))
	return ""


## The account's name on Steam.
func persona() -> String:
	return str(api.call(&"getPersonaName"))
