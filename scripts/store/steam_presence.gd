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
	# A Steam game's lobby says what the game is called, how full it is, and where, GAME.md 10.8.
	var lobbies := Store.steam.lobbies
	if lobbies.hosting and Net.session != null and place.has("players"):
		var said := lobby_says(get_tree().current_scene, Net.session, Game.pending_config)
		said[SteamLobby.HOST_KEY] = Store.steam.persona()
		said[SteamLobby.PING_KEY] = Store.steam.public.here()
		lobbies.describe(said)


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


## What the lobby of the Steam game hosted in [param scene] over [param session] says of it, for
## the lists of games, GAME.md 10.8: its name, the people in it, their colors and how many may play,
## the bots, the map with how far into a Grand Prix it is, empty in the lobby, how it is played, as
## [param config] has it, and whether anybody may watch.
static func lobby_says(scene: Node, session: NetSession, config: MatchConfig) -> Dictionary:
	var match_node: Match = scene.get("match_node") if scene != null else null
	var in_match := scene != null and scene.scene_file_path == Game.MATCH_SCENE
	var colors: PackedStringArray = []
	var bots := 0
	if match_node != null:
		for slot: PlayerSlot in match_node.slots:
			if slot.is_human():
				colors.append(str(slot.color_index))
			elif in_match:
				bots += 1
	if not in_match and config != null:
		# In the lobby the bots are still to come: as many as the match settings ask for, as far as
		# there are seats for them.
		bots = clampi(config.bot_count, 0, maxi(config.seats - colors.size(), 0))
	var door := session.door
	return {
		SteamLobby.TITLE_KEY: door.title,
		SteamLobby.PLAYERS_KEY: colors.size(),
		SteamLobby.MOST_KEY: door.max_players,
		SteamLobby.COLORS_KEY: ",".join(colors),
		SteamLobby.BOTS_KEY: bots,
		SteamLobby.MAP_KEY: LanBeacon.map_of(session) if in_match else "",
		SteamLobby.MODE_KEY: mode_of(config),
		SteamLobby.WATCHING_KEY: "1" if door.watchers_allowed else "0",
	}


## How the game [param config] sets up is played, in a few words for the lists of games: "Grand
## Prix", "Single map, 5 min", with "Teams" after it for a game of teams.
static func mode_of(config: MatchConfig) -> String:
	if config == null:
		return ""
	var mode := "Final Hand" if config.final_hand else "Grand Prix"
	if not config.final_hand and config.rounds <= 0:
		mode = "Single map, %d min" % roundi(config.duration / 60.0)
	return mode + (" · Teams" if config.teams > 0 else "")


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
