class_name SteamPresence
extends Node
## What the Steam friends list says this player is doing, GAME.md 10.8: Steam's rich presence, read
## off the room being played once a second and told to Steam when it changes. A token per kind of
## place, `steam_display`, its words in docs/steam/rich_presence.vdf, which Steamworks keeps; the
## map, the Grand Prix's leg and the people playing as the keys its words are filled in from; and in
## a Steam game, the lobby, so friends in the same game are grouped. Made by [Game] from its path
## with Steam on, so nothing it names is compiled with the autoloads.

## How often the room is read, in seconds.
const EVERY := 1.0
## The tokens, as docs/steam/rich_presence.vdf has them, a test holding the two together.
const MENUS := "#Menus"
const GARAGE := "#Garage"
const SCHOOL := "#School"
const LOBBY := "#Lobby"
const MAP := "#Map"
const GRAND_PRIX := "#GrandPrix"
const SHOWDOWN := "#Showdown"
## What a token is called online, with the people playing in its words.
const ONLINE := "Online"
## What a map's own token is called after: `#Map_vault`.
const MAP_PREFIX := "#Map_"

var _since := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	_since += delta
	if _since < EVERY:
		return
	_since = 0.0
	if not Store.on():
		return
	var place := place_of(get_tree().current_scene)
	Store.steam.present(keys_for(place))
	# A Steam game's lobby says what the game is called and how full it is, GAME.md 10.8.
	if Store.steam.lobbies.hosting and Net.session != null and place.has("players"):
		(
			Store
			. steam
			. lobbies
			. describe(
				{
					SteamLobby.TITLE_KEY: Net.session.door.title,
					SteamLobby.PLAYERS_KEY: place["players"],
					SteamLobby.MOST_KEY: place["most"],
				}
			)
		)


func _exit_tree() -> void:
	if Store.on():
		Store.steam.present({})


## Where the player is, from [param scene], the room being played: its scene, and in a room with
## karts in it the map, the Grand Prix's leg out of how many, whether it is online, the people at
## the table and how many there may be, and the Steam lobby it is, if any.
static func place_of(scene: Node) -> Dictionary:
	var place := {"scene": scene.scene_file_path if scene != null else ""}
	var match_node: Match = scene.get("match_node") if scene != null else null
	if match_node == null or match_node.rules == null:
		return place
	place["map"] = match_node.rules.map
	place["leg"] = match_node.rules.round
	place["legs"] = match_node.rules.rounds
	place["online"] = Net.online()
	var players := 0
	for slot: PlayerSlot in match_node.slots:
		if slot.is_human():
			players += 1
	place["players"] = players
	place["most"] = Net.session.door.max_players if Net.session != null else NetDoor.MOST_PLAYERS
	place["lobby"] = Store.steam.lobby() if Store.on() else 0
	return place


## Steam's keys for [param place], GAME.md 10.8's table: the token and what fills it in.
static func keys_for(place: Dictionary) -> Dictionary:
	var scene: String = place.get("scene", "")
	var players := int(place.get("players", 0))
	var online := bool(place.get("online", false))
	var keys := {}
	if scene == Game.GARAGE_SCENE:
		keys["steam_display"] = GARAGE
	elif scene == Game.DRIVING_SCHOOL_SCENE or scene == Game.TUTORIAL_SCENE:
		keys["steam_display"] = SCHOOL
	elif scene == Game.WAITING_SCENE:
		keys["steam_display"] = LOBBY + (ONLINE if online else "")
		if online:
			keys["players"] = str(players)
			keys["most"] = str(int(place.get("most", NetDoor.MOST_PLAYERS)))
	elif scene == Game.MATCH_SCENE and place.has("map"):
		var map := StringName(place["map"])
		var token := MAP
		if map == ArenaMaps.SHOWDOWN:
			token = SHOWDOWN
		elif int(place.get("legs", 0)) > 0:
			token = GRAND_PRIX
			keys["leg"] = str(int(place.get("leg", 1)))
			keys["legs"] = str(int(place.get("legs", 0)))
		# Online, the people playing, when there is more than one of them.
		if online and players > 1:
			token += ONLINE
			keys["players"] = str(players)
		keys["steam_display"] = token
		keys["map"] = String(ArenaMaps.id_at(ArenaMaps.index_of(map)))
	else:
		keys["steam_display"] = MENUS
	var lobby := int(place.get("lobby", 0))
	if lobby != 0:
		keys["steam_player_group"] = str(lobby)
		keys["steam_player_group_size"] = str(maxi(players, 1))
	return keys
