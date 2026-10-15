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

## Spacewar's own achievements, which a debug build gives a few of the game's under app 480, so
## Steam's pop-up can be seen before the game has an app of its own, GAME.md 10.8.
const SPACEWAR_NAMES: Dictionary[StringName, String] = {
	&"street_legal": "ACH_WIN_ONE_GAME",
	&"honor_roll": "ACH_WIN_100_GAMES",
	&"flawless": "ACH_HEAVY_FIRE",
	&"beat_the_house": "ACH_TRAVEL_FAR_ACCUM",
	&"clean_sweep": "ACH_TRAVEL_FAR_SINGLE",
}
## What a bar's statistic is called after its achievement's name, GAME.md 10.8.
const STAT_SUFFIX := "_COUNT"
## How long after the last change Steam is told, and how often at most, in seconds: Steam asks not
## to be told every second.
const QUIET := 1.0
const EVERY := 5.0
## How many batches an achievement Steam would not take is offered in.
const TRIES := 5

## For the tests alone: a Steam game played over ENet on this port of this machine instead of
## over Steam's network, so a host and a friend can play one in a test, see [SteamPeer].
static var loopback_port := 0

## GodotSteam's `Steam`, or a stand-in for it.
var api: Object
## The Steam app started as, and the account playing, its SteamID64, once started.
var app := 0
var account := 0
## The lobby of the Steam game being played, the way friends come in, GAME.md 10.8.
var lobbies: SteamLobby

## What the next batch tells Steam: achievements by their names on Steam, with the batches each has
## left, and statistics with their counts; and what Steam has been told of each statistic.
var _due_achievements: Dictionary[String, int] = {}
var _due_stats: Dictionary[String, int] = {}
var _told_stats: Dictionary[String, int] = {}
var _changed_at := -INF
var _flushed_at := -INF
var _waiting := false
var _checked := false
## What Steam's rich presence says now, key by key, GAME.md 10.8.
var _presence: Dictionary = {}


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
	lobbies = SteamLobby.new(api)
	return ""


## The account's name on Steam.
func persona() -> String:
	return str(api.call(&"getPersonaName"))


## The name [param id] has on Steam, GAME.md 8.10: its id in capitals; under Spacewar, in a debug
## build, one of Spacewar's few for the few in [constant SPACEWAR_NAMES]; empty for none.
func name_of(id: StringName) -> String:
	if app == Store.SPACEWAR:
		return SPACEWAR_NAMES.get(id, "") if OS.is_debug_build() else ""
	return String(id).to_upper()


## The statistic Steam draws [param id]'s bar from, GAME.md 10.8, or empty under Spacewar, which has
## none of the game's.
func stat_of(id: StringName) -> String:
	return "" if app == Store.SPACEWAR else String(id).to_upper() + STAT_SUFFIX


## Steam is to hear that [param id] is earned, with the next batch.
func earned(id: StringName) -> void:
	var name := name_of(id)
	if name.is_empty() or _due_achievements.has(name):
		return
	_due_achievements[name] = TRIES
	_due()


## Steam is to hear that [param id]'s bar has come to [param count], with the next batch, unless it
## knows as much already: a store is only ever told of more.
func counted(id: StringName, count: int) -> void:
	var name := stat_of(id)
	if name.is_empty() or count <= _told_stats.get(name, 0):
		return
	_due_stats[name] = count
	_due()


## Tells Steam everything due, now, GAME.md 10.8: each achievement it does not have yet and each
## bar further along than it knows, then has it keep them, which is when its own pop-up comes up.
## What Steam would not take yet, being still busy reading the account as the game starts, is
## offered again with the next few batches.
func flush() -> void:
	_flushed_at = _now()
	if not _checked:
		_checked = true
		_check_list()
	var kept := false
	for name: String in _due_achievements.keys():
		var known: Dictionary = api.call(&"getAchievement", name)
		if bool(known.get("achieved", false)) or bool(api.call(&"setAchievement", name)):
			kept = kept or not bool(known.get("achieved", false))
			_due_achievements.erase(name)
		else:
			_due_achievements[name] -= 1
			if _due_achievements[name] <= 0:
				push_warning("Steam would not take the achievement %s" % name)
				_due_achievements.erase(name)
	for name: String in _due_stats.keys():
		var count: int = _due_stats[name]
		if count <= int(api.call(&"getStatInt", name)):
			_told_stats[name] = count
		elif bool(api.call(&"setStatInt", name, count)):
			_told_stats[name] = count
			kept = true
		else:
			push_warning("Steam would not take the statistic %s" % name)
		_due_stats.erase(name)
	if kept:
		api.call(&"storeStats")
	if not _due_achievements.is_empty():
		_due()


## In a debug build with an app of its own, says what Steam's list of achievements and the game's
## each lack, GAME.md 10.8, once: a name not set up on Steamworks is one Steam never takes.
func _check_list() -> void:
	if not OS.is_debug_build() or app == Store.SPACEWAR:
		return
	var steam_names: Array[String] = []
	for index: int in int(api.call(&"getNumAchievements")):
		steam_names.append(str(api.call(&"getAchievementName", index)))
	var missing: Array[String] = []
	for each: Achievement in Achievements.all():
		if each.store_name() not in steam_names:
			missing.append(each.store_name())
		steam_names.erase(each.store_name())
	if not missing.is_empty() or not steam_names.is_empty():
		push_warning(
			(
				"Steam's achievements and the game's differ: not on Steam %s, on Steam only %s"
				% [", ".join(missing), ", ".join(steam_names)]
			)
		)


## Steam's rich presence made [param keys], GAME.md 10.8: each key that changed set, each one gone
## cleared, and nothing said to Steam when nothing changed.
func present(keys: Dictionary) -> void:
	for key: String in _presence.keys():
		if not keys.has(key):
			api.call(&"setRichPresence", key, "")
			_presence.erase(key)
	for key: String in keys:
		if _presence.get(key, "") != keys[key]:
			api.call(&"setRichPresence", key, keys[key])
			_presence[key] = keys[key]


## The Steam lobby the game being played is, GAME.md 10.8, or 0 for none.
func lobby() -> int:
	return lobbies.id if lobbies != null else 0


## A connection hosting a Steam game for [param most] peers, GAME.md 10.8: GodotSteam's, which Steam
## friends reach by this account, passing on what one client says to another as ENet's does; or
## null. Nothing of the network's is named here: this is compiled with the autoloads.
func host_peer(most: int) -> MultiplayerPeer:
	if loopback_port != 0:
		var enet := ENetMultiplayerPeer.new()
		return enet if enet.create_server(loopback_port, most) == OK else null
	var peer := _steam_peer()
	if peer == null or int(peer.call(&"create_host", 0)) != OK:
		return null
	return peer


## A connection to the Steam game the account [param host] hosts, or null.
func client_peer(host: int) -> MultiplayerPeer:
	if loopback_port != 0:
		var enet := ENetMultiplayerPeer.new()
		return enet if enet.create_client("127.0.0.1", loopback_port) == OK else null
	var peer := _steam_peer()
	if peer == null or int(peer.call(&"create_client", host, 0)) != OK:
		return null
	return peer


## GodotSteam's connection, made by name, sending at once rather than gathering small packets up,
## and relaying between clients as ENet's connection does.
static func _steam_peer() -> MultiplayerPeer:
	var peer := ClassDB.instantiate(&"SteamMultiplayerPeer") as MultiplayerPeer
	if peer == null:
		return null
	peer.call(&"set_server_relay", true)
	peer.call(&"set_no_nagle", true)
	return peer


## Takes back every achievement and statistic of the account on Steam, for a debug build trying
## them out, GAME.md 10.8.
func clear_all() -> void:
	api.call(&"resetAllStats", true)
	api.call(&"storeStats")
	_told_stats.clear()


## A batch is due: a second after the last change, and at most every five seconds.
func _due() -> void:
	_changed_at = _now()
	if _waiting:
		return
	_waiting = true
	_wait()


func _wait() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		_waiting = false
		return
	var at := maxf(_changed_at + QUIET, _flushed_at + EVERY)
	tree.create_timer(maxf(at - _now(), 0.05), true, false, true).timeout.connect(_on_wait)


func _on_wait() -> void:
	if _now() < maxf(_changed_at + QUIET, _flushed_at + EVERY) - 0.01:
		_wait()
		return
	_waiting = false
	flush()


static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
