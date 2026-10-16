class_name SteamLobby
extends RefCounted
## A Steam game's lobby, GAME.md 10.8: how Steam friends find a game and come in. The host makes
## it, friends-only or invite-only, and says in it what the game is called, which version it is
## and how full; a friend joins it from the game, from Steam's friends list or by an invite, and
## connects to its owner, the host. The game itself is a session like any other, see [NetSession];
## the lobby is only the way in, and goes with the session.

## The lobby is up, at the host.
signal made(lobby: int)
## In the lobby, at a friend, with the host's account to connect to.
signal entered(lobby: int, host: int)
## It did not work, and why, for the room to say.
signal failed(why: String)
## Steam asks the game to join [param lobby]: an invite accepted, or Join game in the friends list.
signal asked(lobby: int)
## At a friend, the host has left the lobby: quit the game, or lost Steam, and the game with it.
signal host_left

## Steam's lobby types: for invites alone, and for every friend.
const INVITE_ONLY := 0
const FRIENDS_ONLY := 1
## Steam's word for a lobby made, for one entered, and for somebody coming into one.
const RESULT_OK := 1
const ENTERED := 1
const CAME_IN := 1
## What the game says in its lobby: a key of its own, which is how its games are told from
## another's under Spacewar, where everybody's lobbies are, and its version.
const GAME_KEY := "game"
const GAME := "jackpot-junction"
const VERSION_KEY := "version"
## What the host calls the game, how many play in it and how many may, the map it is on, empty in
## the lobby, and whether anybody may watch, for friends' lists.
const TITLE_KEY := "title"
const PLAYERS_KEY := "players"
const MOST_KEY := "most"
const MAP_KEY := "map"
const WATCHING_KEY := "watching"

var api: Object
## The lobby this game is, or 0 for none, whether this machine hosts it, and at a friend, the
## account of the host it was joined at.
var id := 0
var hosting := false
var host_account := 0
## The friend who asked, by the lobby, for the word in a question, see [method host_of].
var _said: Dictionary = {}


func _init(steam_api: Object) -> void:
	api = steam_api
	for wiring: Array in [
		[&"lobby_created", _on_lobby_created],
		[&"lobby_joined", _on_lobby_joined],
		[&"join_requested", _on_join_requested],
		[&"lobby_chat_update", _on_lobby_chat_update],
	]:
		if api.has_signal(wiring[0]):
			api.connect(wiring[0], wiring[1])


## Makes a lobby for this game, hosted here, for [param most] at most: friends-only, or
## [param invite_only].
func host(most: int, invite_only := false) -> void:
	leave()
	hosting = true
	api.call(&"createLobby", INVITE_ONLY if invite_only else FRIENDS_ONLY, most)


func _on_lobby_created(result: int, lobby: int) -> void:
	if not hosting or id != 0:
		return
	if result != RESULT_OK:
		hosting = false
		failed.emit("Steam could not make the game: %d" % result)
		return
	id = lobby
	describe({GAME_KEY: GAME, VERSION_KEY: GameVersion.current()})
	made.emit(lobby)


## Says [param data] in the lobby, each key that changed, at the host.
func describe(data: Dictionary) -> void:
	if id == 0 or not hosting:
		return
	for key: String in data:
		var value := str(data[key])
		if str(api.call(&"getLobbyData", id, key)) != value:
			api.call(&"setLobbyData", id, key, value)


## The host's lobby made for invites alone, [param invite_only], or for every friend, GAME.md 10.8.
func set_invite_only(invite_only: bool) -> void:
	if id != 0 and hosting:
		api.call(&"setLobbyType", id, INVITE_ONLY if invite_only else FRIENDS_ONLY)


## Joins [param lobby], a friend's game; [signal entered] once in, [signal failed] if not.
func join(lobby: int) -> void:
	leave()
	api.call(&"joinLobby", lobby)


func _on_lobby_joined(lobby: int, _permissions: int, _locked: bool, response: int) -> void:
	if hosting or id != 0:
		return
	if response != ENTERED:
		failed.emit("Could not get into the game on Steam")
		return
	var why := refusal(
		str(api.call(&"getLobbyData", lobby, GAME_KEY)),
		str(api.call(&"getLobbyData", lobby, VERSION_KEY))
	)
	if not why.is_empty():
		api.call(&"leaveLobby", lobby)
		failed.emit(why)
		return
	id = lobby
	host_account = int(api.call(&"getLobbyOwner", lobby))
	entered.emit(lobby, host_account)


## Somebody came into the lobby or went: the host going, at a friend, is the game over, said at
## once rather than left for the connection to give up on, GAME.md 10.8.
func _on_lobby_chat_update(lobby: int, changed: int, _making_change: int, state: int) -> void:
	var the_host := host_account != 0 and changed == host_account
	if lobby == id and not hosting and the_host and state != CAME_IN:
		host_left.emit()


## Why a lobby saying [param game] and [param version] is not one to join here, or nothing.
static func refusal(game: String, version: String) -> String:
	if game != GAME:
		return "That is not a Jackpot Junction game"
	if not GameVersion.compatible(GameVersion.current(), version):
		return "That game is version %s, and this one is %s" % [version, GameVersion.current()]
	return ""


func _on_join_requested(lobby: int, friend: int) -> void:
	_said[lobby] = friend
	asked.emit(lobby)


## The friend whose game [param lobby] is, as Steam names them, for a question: whoever asked by
## it, or the lobby's owner.
func host_of(lobby: int) -> String:
	var friend := int(_said.get(lobby, 0))
	if friend == 0:
		friend = int(api.call(&"getLobbyOwner", lobby))
	return str(api.call(&"getFriendPersonaName", friend)) if friend != 0 else ""


## Opens Steam's invite dialog over the game, for this lobby, GAME.md 10.8. False when Steam's
## overlay is off, as it is in a game started from the editor.
func invite() -> bool:
	if id == 0 or not bool(api.call(&"isOverlayEnabled")):
		return false
	api.call(&"activateGameOverlayInviteDialog", id)
	return true


## Invites [param friend] to this lobby without the overlay, from the game's own list.
func invite_friend(friend: int) -> bool:
	return id != 0 and bool(api.call(&"inviteUserToLobby", id, friend))


## Leaves the lobby, with the session: a host's goes with it.
func leave() -> void:
	if id != 0:
		api.call(&"leaveLobby", id)
	id = 0
	hosting = false
	host_account = 0
