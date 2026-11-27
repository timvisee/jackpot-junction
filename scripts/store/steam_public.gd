class_name SteamPublic
extends RefCounted
## Steam games anybody may join, GAME.md 10.8: the list Steam keeps of public lobbies, asked for
## games of this game on this minor version alone, read off each lobby in the form [GameList] lists
## games in; how far away each host is, Steam's estimate of the ping from where the host says it is
## on Steam's network, made without connecting; and how many people are playing the game right now.
## One list is asked for at a time, as Steam answers one at a time; a second ask waits its turn.

## A list of games has come back, for whoever asked: [param games].
signal listed(games: Array[Dictionary])
## How many are playing the game on Steam right now, as Steam has counted them.
signal counted(players: int)

## How far Steam looks for games, GodotSteam's LOBBY_DISTANCE_FILTER_*: the player's region, it and
## those next to it, about half the world, or the whole of it.
const CLOSE := 0
const NEAR := 1
const FAR := 2
const WORLDWIDE := 3
## Steam's word for a lobby's value being the one asked for.
const EQUAL := 0
## The most games one list holds.
const MOST_LISTED := 50
## How often Play Online asks for the list again, and for how many are playing, in seconds: Steam
## asks not to be asked every frame.
const ASK_EVERY := 5.0
const COUNT_EVERY := 30.0
## How many have to be playing for Play Online to say so, GAME.md 10.8: fewer would advertise an
## empty game.
const COUNT_FROM := 50
## A ping nobody could tell.
const NO_PING := -1
## Steam's word for a count it answered.
const COUNTED := 1

var api: Object
## The account playing, whose own games are never on its list.
var account := 0
## How many are playing right now, as last counted, or -1 before Steam has said.
var players_now := -1

## Whether a list is being asked for, and the asks waiting their turn, each the distance and who
## hears the answer.
var _asking := false
var _waiting: Array[Array] = []
var _told := Callable()


func _init(steam_api: Object, own := 0) -> void:
	api = steam_api
	account = own
	for wiring: Array in [
		[&"lobby_match_list", _on_lobby_match_list],
		[&"number_of_current_players", _on_number_of_current_players],
	]:
		if api.has_signal(wiring[0]):
			api.connect(wiring[0], wiring[1])


## Asks Steam for the public games of this game's minor version as far as [param distance], see
## [constant NEAR] and the rest; [param told] hears the games, and [signal listed] says them too.
func ask(distance := WORLDWIDE, told := Callable()) -> void:
	if _asking:
		_waiting.append([distance, told])
		return
	_asking = true
	_told = told
	var line := SteamLobby.line_of(GameVersion.current())
	api.call(&"addRequestLobbyListStringFilter", SteamLobby.GAME_KEY, SteamLobby.GAME, EQUAL)
	api.call(&"addRequestLobbyListStringFilter", SteamLobby.LINE_KEY, line, EQUAL)
	api.call(&"addRequestLobbyListDistanceFilter", distance)
	api.call(&"addRequestLobbyListResultCountFilter", MOST_LISTED)
	api.call(&"requestLobbyList")


## Whether a list is being asked for now.
func asking() -> bool:
	return _asking


func _on_lobby_match_list(lobbies: Array) -> void:
	var games: Array[Dictionary] = []
	for each: Variant in lobbies:
		var lobby := int(each)
		var owner := int(api.call(&"getLobbyOwner", lobby))
		# The player's own game, and the games of anybody they have blocked, GAME.md 10.8, are not
		# theirs to join.
		if owner == account or _blocked(owner):
			continue
		var data := func(key: String) -> String: return str(api.call(&"getLobbyData", lobby, key))
		var why := SteamLobby.refusal(
			data.call(SteamLobby.GAME_KEY), data.call(SteamLobby.VERSION_KEY)
		)
		if not why.is_empty():
			continue
		var host_name := str(api.call(&"getFriendPersonaName", owner))
		if host_name.is_empty() or host_name == SteamLobby.UNKNOWN:
			host_name = data.call(SteamLobby.HOST_KEY)
		var game := read(api, lobby, owner, host_name)
		game["ping"] = ping_of(str(game["where"]))
		games.append(game)
	var told := _told
	_told = Callable()
	_asking = false
	if told.is_valid():
		told.call(games)
	listed.emit(games)
	if not _waiting.is_empty():
		var next: Array = _waiting.pop_front()
		ask(next[0], next[1])


func _blocked(account_of: int) -> bool:
	return (
		account_of != 0
		and int(api.call(&"getFriendRelationship", account_of)) == SteamLobby.BLOCKED
	)


## The Steam game [param lobby], hosted by the account [param host] called [param host_name], as
## [GameList] lists games: what its lobby says of it.
static func read(api: Object, lobby: int, host: int, host_name: String) -> Dictionary:
	var data := func(key: String) -> String: return str(api.call(&"getLobbyData", lobby, key))
	var map: String = data.call(SteamLobby.MAP_KEY)
	var said_colors: String = data.call(SteamLobby.COLORS_KEY)
	var colors: Array[int] = []
	for color: String in said_colors.split(",", false):
		if color.is_valid_int():
			colors.append(int(color))
	return {
		"id": lobby & 0x7FFFFFFF,
		"title": data.call(SteamLobby.TITLE_KEY),
		"name": host_name,
		"lobby": map.is_empty(),
		"map": map,
		"players": int(data.call(SteamLobby.PLAYERS_KEY)),
		"most": int(data.call(SteamLobby.MOST_KEY)),
		"bots": int(data.call(SteamLobby.BOTS_KEY)),
		"colors": colors,
		"chips": not said_colors.is_empty(),
		"mode": data.call(SteamLobby.MODE_KEY),
		"password": false,
		"version": data.call(SteamLobby.VERSION_KEY),
		"watching": data.call(SteamLobby.WATCHING_KEY) != "0",
		"where": data.call(SteamLobby.PING_KEY),
		"ping": NO_PING,
		"friend": false,
		"steam_lobby": lobby,
		"steam_host": host,
	}


## How long a packet takes to the host who says it is at [param where] on Steam's network and
## back, in milliseconds, as Steam estimates it from here; [constant NO_PING] where it cannot tell.
func ping_of(where: String) -> int:
	if where.is_empty():
		return NO_PING
	var location := bytes_in(api.call(&"parsePingLocationString", where))
	if location.is_empty():
		return NO_PING
	var ping := int(api.call(&"estimatePingTimeFromLocalHost", location))
	return ping if ping >= 0 else NO_PING


## Where this machine is on Steam's network, as a host says it in its lobby, or empty until Steam
## has measured it.
func here() -> String:
	var location := bytes_in(api.call(&"getLocalPingLocation"))
	return "" if location.is_empty() else str(api.call(&"convertPingLocationToString", location))


## The location in what GodotSteam answers with: the one value of it that is one.
static func bytes_in(answer: Variant) -> PackedByteArray:
	if answer is PackedByteArray:
		return answer
	if answer is Dictionary:
		for value: Variant in (answer as Dictionary).values():
			if value is PackedByteArray and not (value as PackedByteArray).is_empty():
				return value
	return PackedByteArray()


## Asks Steam how many are playing the game right now; [signal counted] says once it has answered.
func count() -> void:
	api.call(&"getNumberOfCurrentPlayers")


func _on_number_of_current_players(success: int, players: int) -> void:
	if success != COUNTED:
		return
	players_now = players
	counted.emit(players)
