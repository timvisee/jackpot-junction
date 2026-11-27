class_name SteamLobby
extends RefCounted
## A Steam game's lobby, GAME.md 10.8: how players find a game and come in. The host makes it, for
## anyone, for friends or for those invited alone, and says in it what the game is called, which
## version it is, how full and where it plays; a player joins it from the game, from Steam's friends
## list or by an invite, and connects to its owner, the host. The game itself is a session like any
## other, see [NetSession]; the lobby is only the way in, and goes with the session.

## The lobby is up, at the host.
signal made(lobby: int)
## In the lobby, at a player joining, with the host's account to connect to.
signal entered(lobby: int, host: int)
## It did not work, and why, for the room to say.
signal failed(why: String)
## Steam asks the game to join [param lobby]: an invite accepted, or Join game in the friends list.
signal asked(lobby: int)
## At a player who joined, the host has left the lobby: quit the game, or lost Steam, and the game
## with it.
signal host_left

## Who may come into a game, GAME.md 10.8: anybody, who finds it on the list of public games, every
## friend of the host's, or only those invited.
enum Who { ANYONE, FRIENDS, INVITE_ONLY }

## Steam's lobby types: for invites alone, for every friend, and listed for anybody.
const INVITE_ONLY := 0
const FRIENDS_ONLY := 1
const PUBLIC := 2
## Steam's lobby type for each [enum Who].
const TYPES: Array[int] = [PUBLIC, FRIENDS_ONLY, INVITE_ONLY]
## What each [enum Who] is called, for the choices that pick one.
const WHO_NAMES: Array[String] = ["Anyone", "Friends", "Invite only"]
## Steam's word for a lobby made, for one entered, and for somebody coming into one.
const RESULT_OK := 1
const ENTERED := 1
const CAME_IN := 1
## Steam's word for an account the player has blocked, GodotSteam's FRIEND_RELATION_IGNORED, and
## what it calls an account it knows nothing of yet.
const BLOCKED := 5
const UNKNOWN := "[unknown]"
## What the game says in its lobby: a key of its own, which is how its games are told from
## another's under Spacewar, where everybody's lobbies are, its version, and its minor version,
## the line, which is what Steam is asked for when it lists public games, 0.24.x playing 0.24.y.
const GAME_KEY := "game"
const GAME := "jackpot-junction"
const VERSION_KEY := "version"
const LINE_KEY := "line"
## What the host calls the game, how many play in it and how many may, the map it is on, empty in
## the lobby, and whether anybody may watch, for friends' lists.
const TITLE_KEY := "title"
const PLAYERS_KEY := "players"
const MOST_KEY := "most"
const MAP_KEY := "map"
const WATCHING_KEY := "watching"
## For the list of public games too, GAME.md 10.8: the host's name on Steam, which a stranger's
## Steam may not know yet; the bots playing; the colors of the people, by the color's number,
## "0,4,5"; how the game is played, "Grand Prix" or "Single map, 5 min"; and where the host is on
## Steam's network, for each player's Steam to tell its ping from without connecting.
const HOST_KEY := "host"
const BOTS_KEY := "bots"
const COLORS_KEY := "colors"
const MODE_KEY := "mode"
const PING_KEY := "ping"
## For a host who goes, GAME.md 10.8: the account hosting the game now, which a new host writes once
## its game is up for the others to follow it into, and the match and door the host plays by, for a
## new host to take on.
const HOSTED_KEY := "hosted"
const PLAN_KEY := "plan"

var api: Object
## The lobby this game is, or 0 for none, whether this machine hosts it, and at a player who
## joined, the account of the host it was joined at.
var id := 0
var hosting := false
var host_account := 0
## Who may come in, at the host, a [enum Who].
var who := Who.FRIENDS
## Whether the game is being handed to another host, GAME.md 10.8: the lobby is kept as the
## session closes, the next to close it being the next host's or the next game's.
var handing_over := false
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


## Makes a lobby for this game, hosted here, for [param most] at most, open to [param who].
func host(most: int, open_to: int = Who.FRIENDS) -> void:
	leave()
	hosting = true
	who = open_to as Who
	api.call(&"createLobby", type_of(who), most)


## Steam's lobby type for [param who], friends-only for anything unknown.
static func type_of(who: int) -> int:
	return TYPES[who] if who >= 0 and who < TYPES.size() else FRIENDS_ONLY


func _on_lobby_created(result: int, lobby: int) -> void:
	if not hosting or id != 0:
		return
	if result != RESULT_OK:
		hosting = false
		failed.emit("Steam could not make the game: %d" % result)
		return
	id = lobby
	var version := GameVersion.current()
	describe({GAME_KEY: GAME, VERSION_KEY: version, LINE_KEY: line_of(version)})
	describe({HOSTED_KEY: str(api.call(&"getSteamID"))})
	made.emit(lobby)


## The lobby this machine is in taken over as its new host, GAME.md 10.8, Steam having made it the
## owner: open to whoever the old host had it open to, and said to be hosted here once the game is.
func take_over(open_to: int) -> void:
	hosting = true
	host_account = 0
	who = open_to as Who


## The game hosted here said to be up, GAME.md 10.8, for the others to follow into.
func hosted_here() -> void:
	describe({HOSTED_KEY: str(api.call(&"getSteamID"))})


## The lobby handed to [param account], at the host, GAME.md 10.8, for it to host the game next.
func hand_to(account: int) -> void:
	if id != 0 and hosting and account != 0:
		api.call(&"setLobbyOwner", id, account)


## The minor version [param version] belongs to, "0.24" of "0.24.1", which every version of it
## plays, see [method GameVersion.compatible].
static func line_of(version: String) -> String:
	var parts := version.split(".")
	return "%s.%s" % [parts[0], parts[1]] if parts.size() >= 2 else version


## Says [param data] in the lobby, each key that changed, at the host.
func describe(data: Dictionary) -> void:
	if id == 0 or not hosting:
		return
	for key: String in data:
		var value := str(data[key])
		if str(api.call(&"getLobbyData", id, key)) != value:
			api.call(&"setLobbyData", id, key, value)


## The host's lobby opened to [param who], GAME.md 10.8, from Lobby settings.
func set_who(open_to: int) -> void:
	if id != 0 and hosting:
		who = open_to as Who
		api.call(&"setLobbyType", id, type_of(who))


## Joins [param lobby], a game found on a list or a friend's; [signal entered] once in, [signal
## failed] if not.
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
	var owner := int(api.call(&"getLobbyOwner", lobby))
	# A host the player has blocked on Steam is somebody they are not to play with, GAME.md 10.8.
	if why.is_empty() and blocked(owner):
		why = "That game can't be joined"
	if not why.is_empty():
		api.call(&"leaveLobby", lobby)
		failed.emit(why)
		return
	id = lobby
	host_account = owner
	entered.emit(lobby, host_account)


## Whether the account [param account] is in [param lobby], one this machine is in.
func has_member(lobby: int, account: int) -> bool:
	for index: int in int(api.call(&"getNumLobbyMembers", lobby)):
		if int(api.call(&"getLobbyMemberByIndex", lobby, index)) == account:
			return true
	return false


## Whether anybody in [param lobby], one this machine is in, is somebody the player has blocked on
## Steam, GAME.md 10.8.
func anybody_blocked(lobby: int) -> bool:
	for index: int in int(api.call(&"getNumLobbyMembers", lobby)):
		if blocked(int(api.call(&"getLobbyMemberByIndex", lobby, index))):
			return true
	return false


## Whether the player has blocked [param account] on Steam, GAME.md 10.8.
func blocked(account: int) -> bool:
	return account != 0 and int(api.call(&"getFriendRelationship", account)) == BLOCKED


## Somebody came into the lobby or went: the host going, at a player who joined, is the game over,
## said at once rather than left for the connection to give up on, GAME.md 10.8.
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


## The player whose game [param lobby] is, as Steam names them, for a question: whoever asked by
## it, or the lobby's owner, or, for a stranger's game Steam does not know the host of yet, the name
## the host said in it.
func host_of(lobby: int) -> String:
	var friend := int(_said.get(lobby, 0))
	if friend == 0:
		friend = int(api.call(&"getLobbyOwner", lobby))
	var named := str(api.call(&"getFriendPersonaName", friend)) if friend != 0 else ""
	if named.is_empty() or named == UNKNOWN:
		named = str(api.call(&"getLobbyData", lobby, HOST_KEY))
	return named


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
