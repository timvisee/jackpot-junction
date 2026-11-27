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
## What Steam answers for a machine that is none of its own, GodotSteam's `SteamHardwareType`:
## anything else is a Steam Deck, a Steam Machine or a Steam Frame, in that order, see
## [constant ViewChoices.STEAM_DECK].
const NOT_STEAM_HARDWARE := 0
## How the overlay opens a store page, GodotSteam's OverlayToStoreFlag: just the page, nothing
## added to the cart.
const OVERLAY_TO_STORE := 0
## What the overlay is asked to open of somebody's, GodotSteam's word for their profile.
const PROFILE := "steamid"

## For the tests alone: a Steam game played over ENet on this port of this machine instead of
## over Steam's network, so a host and a friend can play one in a test, see [SteamPeer].
static var loopback_port := 0

## GodotSteam's `Steam`, or a stand-in for it.
var api: Object
## The Steam app started as, and the account playing, its SteamID64, once started.
var app := 0
var account := 0
## The lobby of the Steam game being played, the way players come in, the account's friends, and
## the games anybody may join, GAME.md 10.8.
var lobbies: SteamLobby
var friends: SteamFriends
var public: SteamPublic

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
## What the timeline's bar and tooltip say now, GAME.md 10.8, so Steam is told only a change: the
## game mode, 0 before any, and the words, empty for none.
var _mode := 0
var _tooltip := ""
## Told whenever the account's DLC may have changed while the game runs, see [method watch_dlc].
var _dlc_told := Callable()


func _init(steam_api: Object) -> void:
	api = steam_api


## Whether Steam starts the game itself as [param app_id], having been started outside it, in which
## case this one is to quit at once, GAME.md 10.8.
func restart_through_steam(app_id: int) -> bool:
	return bool(api.call(&"restartAppIfNecessary", app_id))


## Starts Steam as [param app_id], always named rather than taken from the environment: a game run
## from an editor that Steam started is otherwise the editor's app. GodotSteam runs Steam's
## callbacks itself every frame. Says why it did not start, in English, since it starts before there
## is a language to say it in, see [member Store.missing], or nothing once it has.
func start(app_id: int) -> String:
	var answer: Dictionary = api.call(&"steamInitEx", app_id, true)
	var status := int(answer.get("status", -1))
	if status != STARTED:
		push_warning("Steam did not start: %s (%d)" % [answer.get("verbal", ""), status])
		if status == NO_CLIENT:
			return Lang.later("Steam isn't running")
		if status == OLD_CLIENT:
			return Lang.later("Steam needs updating")
		return Lang.later("Steam did not start")
	app = app_id
	account = int(api.call(&"getSteamID"))
	lobbies = SteamLobby.new(api)
	friends = SteamFriends.new(api, app)
	public = SteamPublic.new(api, account)
	# Where this machine is on Steam's network is measured from the start, for a host to say it in
	# its lobby and a player to tell a host's ping by, GAME.md 10.8.
	api.call(&"initRelayNetworkAccess")
	# And Steam's filter readied for the words other players wrote, see [SteamWords].
	api.call(&"initFilterText")
	return ""


## [param text], words the account [param source] wrote, as Steam's text filter lets the player see
## them, GAME.md 10.8, by their own Steam setting; [param context] is GodotSteam's
## TEXT_FILTERING_CONTEXT_*, a name or game content.
func filter_text(context: int, source: int, text: String) -> String:
	return str(api.call(&"filterText", context, source, text))


## Tells Steam the player played with the account [param other], GAME.md 10.8, for Steam's list of
## recent players, where Steam's own Report and Block are.
func played_with(other: int) -> void:
	if other != 0 and other != account:
		api.call(&"setPlayedWith", other)


## Which of Steam's own machines the game runs on, see [constant NOT_STEAM_HARDWARE].
func hardware() -> int:
	return int(api.call(&"isRunningOnSteamHardware"))


## The account's name on Steam.
func persona() -> String:
	return str(api.call(&"getPersonaName"))


## The language the player has the game in on Steam, by Steam's name for it: "english", "dutch".
func language() -> String:
	return str(api.call(&"getCurrentGameLanguage"))


## The name on Steam of the account [param account], somebody in the same lobby or a friend.
func persona_of(account: int) -> String:
	return PlayerNames.clean(str(api.call(&"getFriendPersonaName", account)))


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


## A moment marked on the timeline of Steam's game recording, GAME.md 10.8, [param offset] seconds
## from now, a moment past being less than 0: its words, its icon on Steam's list or one uploaded
## for the game, how far up it is drawn when the timeline is crowded, 0 to 1000, and whether Steam
## offers a clip of it, [constant Timeline.CLIP_FEATURED] and the rest. Steam's handle for it.
func timeline_mark(
	title: String, description: String, icon: String, priority: int, offset: float, clip: int
) -> int:
	var args := [title, description, icon, priority, offset, clip]
	return int(api.callv(&"addInstantaneousTimelineEvent", args))


## A stretch of the timeline marked whole, GAME.md 10.8: as [method timeline_mark], begun
## [param offset] seconds from now and [param lasting] seconds long.
func timeline_span(
	title: String,
	description: String,
	icon: String,
	priority: int,
	offset: float,
	lasting: float,
	clip: int,
) -> int:
	var args := [title, description, icon, priority, offset, lasting, clip]
	return int(api.callv(&"addRangeTimelineEvent", args))


## A stretch of the timeline begun now and left open, GAME.md 10.8, until [method timeline_close]
## ends it: as [method timeline_mark]. Steam's handle for it.
func timeline_open(
	title: String, description: String, icon: String, priority: int, clip: int
) -> int:
	var args := [title, description, icon, priority, 0.0, clip]
	return int(api.callv(&"startRangeTimelineEvent", args))


## Ends the open stretch [param handle] now, GAME.md 10.8.
func timeline_close(handle: int) -> void:
	api.call(&"endRangeTimelineEvent", handle, 0.0)


## The timeline's bar colored as [param mode], [constant Timeline.PLAYING] and the rest, GAME.md
## 10.8; nothing said to Steam when it already is.
func timeline_mode(mode: int) -> void:
	if mode == _mode:
		return
	_mode = mode
	api.call(&"setTimelineGameMode", mode)


## What the timeline says along itself of where the player is, GAME.md 10.8: [param words], or
## nothing for none; nothing said to Steam when it already says so.
func timeline_tooltip(words: String) -> void:
	if words == _tooltip:
		return
	_tooltip = words
	if words.is_empty():
		api.call(&"clearTimelineTooltip", 0.0)
	else:
		api.call(&"setTimelineTooltip", words, 0.0)


## A game phase of the recording begun, GAME.md 10.8, called [param id] for good.
func phase_start(id: String) -> void:
	api.call(&"startGamePhase")
	api.call(&"setGamePhaseID", id)


## The game phase being recorded ended, GAME.md 10.8.
func phase_end() -> void:
	api.call(&"endGamePhase")


## A tag on the game phase being recorded, GAME.md 10.8: [param words] in the group [param group],
## with [param icon], kept beside any other tag of the group.
func phase_tag(words: String, icon: String, group: String, priority: int) -> void:
	api.call(&"addGamePhaseTag", words, icon, group, priority)


## What the game phase being recorded says under [param group], GAME.md 10.8: [param words], the
## last said being the one shown.
func phase_attribute(group: String, words: String, priority: int) -> void:
	api.call(&"setGamePhaseAttribute", group, words, priority)


## Whether the account owns the DLC [param dlc] and has it installed, GAME.md 10.8.
func owns(dlc: int) -> bool:
	return bool(api.call(&"isDLCInstalled", dlc))


## Opens the store page of [param app], a DLC as well, in Steam's overlay, GAME.md 10.8.
func show_store(app: int) -> void:
	api.call(&"activateGameOverlayToStore", app, OVERLAY_TO_STORE)


## Whether Steam's overlay can come up over the game, GAME.md 10.8: not in a game started from the
## editor.
func overlay_on() -> bool:
	return bool(api.call(&"isOverlayEnabled"))


## Opens the Steam profile of the account [param account] in Steam's overlay, GAME.md 10.8.
func show_profile(account: int) -> void:
	api.call(&"activateGameOverlayToUser", PROFILE, account)


## [param told] called whenever the account's DLC may have changed while the game runs, GAME.md
## 10.8: a DLC installed, as one just bought in the overlay is, and the overlay closed, where one
## may have been bought.
func watch_dlc(told: Callable) -> void:
	_dlc_told = told
	for wiring: Array in [
		[&"dlc_installed", _on_dlc_installed], [&"overlay_toggled", _on_overlay_toggled]
	]:
		if api.has_signal(wiring[0]) and not api.is_connected(wiring[0], wiring[1]):
			api.connect(wiring[0], wiring[1])


## Steam Input started, to be asked which pad stands behind a pad it shows the game in its place,
## GAME.md 8.3. Nothing else of it is used: the game reads its pads itself.
func watch_pads() -> void:
	api.call(&"inputInit", false)


## The family of the pad behind Steam Input's pad [param index], see [PadFamily], or -1 where Steam
## does not say. The engine's index is Steam's for its pad, or the pad's handle itself.
func pad_family(index: int) -> int:
	var handle: int = api.call(&"getControllerForGamepadIndex", index)
	if handle == 0:
		handle = index
	var type: int = api.call(&"getInputTypeForHandle", handle)
	return PadFamily.STEAM_TYPES.get(type, -1)


func _on_dlc_installed(_dlc: int) -> void:
	_dlc_told.call()


func _on_overlay_toggled(active: bool, _by_user := false, _app := 0) -> void:
	if not active:
		_dlc_told.call()


## Whether Steam's keyboard on the screen is the way to type here, GAME.md 10.8: on Steam's own
## hardware, a Steam Deck, a Steam Machine or a Steam Frame, and wherever Steam is in Big Picture.
## Asked each time, since Steam can go into Big Picture and out again while the game plays.
func keyboard_here() -> bool:
	if hardware() != NOT_STEAM_HARDWARE:
		return true
	return bool(api.call(&"isSteamInBigPictureMode"))


## Steam's floating keyboard put up over the game, GAME.md 10.8, of the kind [param kind], Steam's
## `FloatingGamepadTextInputMode`, and clear of the box at [param rect], in the window's pixels.
## It types into the game as keys do. Says whether Steam put it up.
func show_keyboard(kind: int, rect: Rect2i) -> bool:
	var at := rect.position
	return bool(
		api.call(&"showFloatingGamepadTextInput", kind, at.x, at.y, rect.size.x, rect.size.y)
	)


## Steam's floating keyboard put away again.
func hide_keyboard() -> void:
	api.call(&"dismissFloatingGamepadTextInput")


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
