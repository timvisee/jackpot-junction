class_name SteamFriends
extends RefCounted
## The Steam account's friends, as the game sees them, GAME.md 10.8: the Steam games of theirs
## there are to join, in the form [GameList] lists games in, read off each friend's lobby; and the
## friends online, to invite without Steam's overlay.

## Steam's friends of the account's own, rather than those it only shares a group with.
const IMMEDIATE := 4
## Steam's word for a friend who is offline.
const OFFLINE := 0

var api: Object
## The Steam app this game is, whose games of friends' are this one's.
var app := 0
## The lobbies asked about already, so each is asked about once while it is there.
var _asked: Dictionary[int, bool] = {}


func _init(steam_api: Object, app_id: int) -> void:
	api = steam_api
	app = app_id


## Every friend's Steam game of this one's there is to join, in the form [GameList] lists games in,
## as far as their lobbies have said: one that has said nothing yet is asked, and listed once it
## has.
func games() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for friend: int in _friends():
		var playing: Dictionary = api.call(&"getFriendGamePlayed", friend)
		var lobby := int(playing.get("lobby", 0))
		if int(playing.get("id", 0)) != app or lobby == 0:
			continue
		if str(api.call(&"getLobbyData", lobby, SteamLobby.GAME_KEY)) != SteamLobby.GAME:
			if not _asked.has(lobby):
				_asked[lobby] = true
				api.call(&"requestLobbyData", lobby)
			continue
		found.append(game_of(lobby, friend, str(api.call(&"getFriendPersonaName", friend))))
	return found


## The friend's game [param lobby], hosted by [param host] called [param host_name], as [GameList]
## lists games: what its lobby says of it.
func game_of(lobby: int, host: int, host_name: String) -> Dictionary:
	var data := func(key: String) -> String: return str(api.call(&"getLobbyData", lobby, key))
	var map: String = data.call(SteamLobby.MAP_KEY)
	return {
		"id": lobby & 0x7FFFFFFF,
		"title": data.call(SteamLobby.TITLE_KEY),
		"name": host_name,
		"lobby": map.is_empty(),
		"map": map,
		"players": int(data.call(SteamLobby.PLAYERS_KEY)),
		"most": int(data.call(SteamLobby.MOST_KEY)),
		"password": false,
		"version": data.call(SteamLobby.VERSION_KEY),
		"watching": data.call(SteamLobby.WATCHING_KEY) != "0",
		"steam_lobby": lobby,
		"steam_host": host,
	}


## The friends online, by account and name, for inviting without Steam's overlay.
func online() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for friend: int in _friends():
		if int(api.call(&"getFriendPersonaState", friend)) != OFFLINE:
			found.append({"id": friend, "name": str(api.call(&"getFriendPersonaName", friend))})
	found.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool: return a["name"].nocasecmp_to(b["name"]) < 0
	)
	return found


func _friends() -> Array[int]:
	var friends: Array[int] = []
	for index: int in int(api.call(&"getFriendCount", IMMEDIATE)):
		friends.append(int(api.call(&"getFriendByIndex", index, IMMEDIATE)))
	return friends
