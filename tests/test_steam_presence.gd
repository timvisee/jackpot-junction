extends GdUnitTestSuite
## What the Steam friends list says, GAME.md 10.8: the token for each kind of place, the keys it is
## filled in from, Steam told only what changed, and the words Steamworks keeps holding every token
## the game sets.

const WORDS := "res://docs/steam/rich_presence.vdf"
const WAITING_SCENE := preload("res://scenes/waiting/waiting_room.tscn")

var _settings_were: Settings


func after_test() -> void:
	Store.steam = null
	Game.pending_config = null
	get_tree().paused = false
	if _settings_were != null:
		Settings.remove_files(Game.settings.path)
		Game.settings = _settings_were
		_settings_were = null


## A real room read for where the player is: a lobby on this machine, its map and its people.
func test_a_real_room_is_read() -> void:
	Game.pending_config = MatchConfig.new()
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_steam_presence.cfg"
	var room: Node3D = auto_free(WAITING_SCENE.instantiate())
	var runner := scene_runner(room)
	await runner.simulate_frames(45, 17)
	if room.ready_room.everybody_ready.is_connected(room._begin):
		room.ready_room.everybody_ready.disconnect(room._begin)
	var place := SteamPresence.place_of(room)
	assert_str(place["scene"]).is_equal(Game.WAITING_SCENE)
	assert_bool(place["online"]).is_false()
	assert_int(place["players"]).is_greater_equal(1)
	assert_int(place["lobby"]).is_equal(0)
	assert_str(_display(place)).is_equal("#Lobby")


## The menus, the Garage and the school, each a token of its own; anything else is the menus.
func test_the_rooms_without_a_map() -> void:
	assert_dict(SteamPresence.keys_for({"scene": Game.TITLE_SCENE})).is_equal(
		{"steam_display": "#Menus"}
	)
	assert_str(_display({"scene": Game.GARAGE_SCENE})).is_equal("#Garage")
	assert_str(_display({"scene": Game.DRIVING_SCHOOL_SCENE})).is_equal("#School")
	assert_str(_display({"scene": Game.TUTORIAL_SCENE})).is_equal("#School")
	assert_str(_display({"scene": Game.SETTINGS_SCENE})).is_equal("#Menus")
	assert_str(_display({})).is_equal("#Menus")


## A lobby here says nothing more; online, how full it is.
func test_the_lobby() -> void:
	assert_dict(SteamPresence.keys_for({"scene": Game.WAITING_SCENE, "players": 2})).is_equal(
		{"steam_display": "#Lobby"}
	)
	var online := {"scene": Game.WAITING_SCENE, "online": true, "players": 3, "most": 8}
	assert_dict(SteamPresence.keys_for(online)).is_equal(
		{"steam_display": "#LobbyOnline", "players": "3", "most": "8"}
	)


## A map, a Grand Prix's leg and a showdown; online with more than one person, the people too.
func test_the_maps() -> void:
	var single := {"scene": Game.MATCH_SCENE, "map": &"vault", "legs": 0, "players": 1}
	assert_dict(SteamPresence.keys_for(single)).is_equal({"steam_display": "#Map", "map": "vault"})
	var leg := {"scene": Game.MATCH_SCENE, "map": &"crossfire_xl", "leg": 2, "legs": 5}
	assert_dict(SteamPresence.keys_for(leg)).is_equal(
		{"steam_display": "#GrandPrix", "map": "crossfire_xl", "leg": "2", "legs": "5"}
	)
	var showdown := {"scene": Game.MATCH_SCENE, "map": &"showdown", "leg": 6, "legs": 5}
	assert_str(_display(showdown)).is_equal("#Showdown")
	var online := {
		"scene": Game.MATCH_SCENE, "map": &"vault", "online": true, "players": 4, "lobby": 42
	}
	(
		assert_dict(SteamPresence.keys_for(online))
		. is_equal(
			{
				"steam_display": "#MapOnline",
				"map": "vault",
				"players": "4",
				"steam_player_group": "42",
				"steam_player_group_size": "4",
			}
		)
	)
	online["players"] = 1
	assert_str(_display(online)).is_equal("#Map")


## Steam is told what changed and nothing else, and a key gone is cleared.
func test_steam_hears_only_what_changed() -> void:
	var fake := FakeSteam.new()
	var store := SteamStore.new(fake)
	store.present({"steam_display": "#Map", "map": "vault"})
	var told := fake.calls.size()
	store.present({"steam_display": "#Map", "map": "vault"})
	assert_int(fake.calls.size()).is_equal(told)
	store.present({"steam_display": "#Menus"})
	assert_dict(fake.presence).is_equal({"steam_display": "#Menus"})
	store.present({})
	assert_dict(fake.presence).is_empty()


## Every token the game sets, and every map's, is in the words Steamworks keeps.
func test_every_token_has_words() -> void:
	var words := FileAccess.get_file_as_string(WORDS)
	assert_str(words).is_not_empty()
	var tokens: Array[String] = []
	for base: String in [SteamPresence.MAP, SteamPresence.GRAND_PRIX, SteamPresence.SHOWDOWN]:
		tokens.append_array([base, base + SteamPresence.ONLINE])
	(
		tokens
		. append_array(
			[
				SteamPresence.MENUS,
				SteamPresence.GARAGE,
				SteamPresence.SCHOOL,
				SteamPresence.LOBBY,
				SteamPresence.LOBBY + SteamPresence.ONLINE,
			]
		)
	)
	for map: StringName in ArenaMaps.IDS:
		tokens.append(SteamPresence.MAP_PREFIX + String(map))
	for token: String in tokens:
		assert_str(words).override_failure_message("no words for %s" % token).contains(
			'"%s"' % token
		)


func _display(place: Dictionary) -> String:
	return SteamPresence.keys_for(place).get("steam_display", "")
