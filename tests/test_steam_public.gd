extends GdUnitTestSuite
## Public Steam games, GAME.md 10.8: the list Steam is asked for, of this game's minor version
## alone; how each game is read and how far away its host is; the games left off it; how many are
## playing; the order Play Online lists games in; and how a Steam game's row looks. Steam here is
## always [FakeSteam].

const STRANGER := 76561197960287950
const OTHER := 76561197960287951
const FRIEND := 76561197960287952

var _fake: FakeSteam
var _public: SteamPublic


func before_test() -> void:
	_fake = FakeSteam.new()
	_public = SteamPublic.new(_fake, _fake.account)


func _ours(extra := {}) -> Dictionary:
	var data := {
		SteamLobby.GAME_KEY: SteamLobby.GAME,
		SteamLobby.VERSION_KEY: GameVersion.current(),
		SteamLobby.LINE_KEY: SteamLobby.line_of(GameVersion.current()),
		SteamLobby.PLAYERS_KEY: "2",
		SteamLobby.MOST_KEY: "8",
		SteamLobby.BOTS_KEY: "2",
		SteamLobby.COLORS_KEY: "1,3",
		SteamLobby.MODE_KEY: "Single map, 5 min",
		SteamLobby.WATCHING_KEY: "1",
		SteamLobby.HOST_KEY: "Zed",
	}
	data.merge(extra, true)
	return data


func _listed(distance := SteamPublic.WORLDWIDE) -> Array[Dictionary]:
	var got: Array[Dictionary] = []
	_public.ask(distance, func(games: Array[Dictionary]) -> void: got.assign(games))
	return got


## Steam is asked for this game on this minor version only, as far as asked; each game is read off
## its lobby, its host named by what the lobby says while Steam does not know them.
func test_the_list_asks_for_this_game_and_line() -> void:
	var lobby := _fake.public_lobby(STRANGER, _ours())
	var older := _ours({SteamLobby.LINE_KEY: "0.1", SteamLobby.VERSION_KEY: "0.1.0"})
	_fake.public_lobby(OTHER, older)
	_fake.public_lobby(OTHER, {SteamLobby.GAME_KEY: "spacewar"})
	var games := _listed()
	assert_int(_fake.list_distance).is_equal(SteamPublic.WORLDWIDE)
	assert_array(games).has_size(1)
	var game: Dictionary = games[0]
	assert_int(game["steam_lobby"]).is_equal(lobby)
	assert_int(game["steam_host"]).is_equal(STRANGER)
	assert_str(GameList.title_of(game)).is_equal("Zed's game")
	assert_int(game["players"]).is_equal(2)
	assert_int(game["bots"]).is_equal(2)
	assert_array(game["colors"]).is_equal([1, 3])
	assert_bool(game["chips"]).is_true()
	assert_bool(game["lobby"]).is_true()
	assert_bool(game["friend"]).is_false()
	assert_str(GameList.describe(game)).is_equal("In the lobby · Single map, 5 min")


## A friends-only lobby, the player's own game and the game of anybody they blocked are never on
## the public list.
func test_some_games_are_never_listed() -> void:
	_fake.friends_lobby(STRANGER, _ours())
	_fake.public_lobby(_fake.account, _ours())
	_fake.public_lobby(OTHER, _ours())
	_fake.blocked = [OTHER]
	assert_array(_listed()).is_empty()


## Steam looks only as far as asked; a nearer search finds fewer games.
func test_distance_narrows_the_list() -> void:
	_fake.public_lobby(STRANGER, _ours(), SteamPublic.CLOSE)
	_fake.public_lobby(OTHER, _ours(), SteamPublic.FAR)
	assert_array(_listed(SteamPublic.NEAR)).has_size(1)
	assert_array(_listed(SteamPublic.FAR)).has_size(2)


## A second ask while one is out waits its turn, and both hear their answer.
func test_asks_wait_their_turn() -> void:
	_fake.lists_answer = false
	_fake.public_lobby(STRANGER, _ours())
	var first: Array[Dictionary] = []
	var second: Array[Dictionary] = []
	_public.ask(SteamPublic.NEAR, func(games: Array[Dictionary]) -> void: first.assign(games))
	_public.ask(SteamPublic.FAR, func(games: Array[Dictionary]) -> void: second.assign(games))
	assert_bool(_public.asking()).is_true()
	assert_int(_fake.calls.count("requestLobbyList %d" % SteamPublic.FAR)).is_equal(0)
	_fake.answer_list()
	assert_array(first).has_size(1)
	assert_int(_fake.calls.count("requestLobbyList %d" % SteamPublic.FAR)).is_equal(1)
	_fake.answer_list()
	assert_array(second).has_size(1)
	assert_bool(_public.asking()).is_false()


## The ping is Steam's estimate from where the host says it is, or none when nobody can tell; the
## player's own place is said only once Steam has measured it.
func test_ping_from_where_the_host_is() -> void:
	_fake.pings["fra"] = 31
	_fake.public_lobby(STRANGER, _ours({SteamLobby.PING_KEY: "fra"}))
	_fake.public_lobby(OTHER, _ours({SteamLobby.PING_KEY: "atl"}))
	var games := _listed()
	var pings: Array[int] = []
	for game: Dictionary in games:
		pings.append(int(game["ping"]))
	pings.sort()
	assert_array(pings).is_equal([SteamPublic.NO_PING, 31])
	assert_int(_public.ping_of("")).is_equal(SteamPublic.NO_PING)
	assert_str(_public.here()).is_equal("ams")
	_fake.here = ""
	assert_str(_public.here()).is_empty()
	var bytes := PackedByteArray([1, 2])
	assert_array(Array(SteamPublic.bytes_in({"age": 3, "where": bytes}))).is_equal([1, 2])
	assert_array(Array(SteamPublic.bytes_in(null))).is_empty()


## How many play the game right now, as Steam counts them.
func test_the_count() -> void:
	_fake.players_now = 140
	var heard: Array[int] = []
	_public.counted.connect(func(players: int) -> void: heard.append(players))
	_public.count()
	assert_array(heard).is_equal([140])
	assert_int(_public.players_now).is_equal(140)


## Friends' games first, then the lowest ping, games nobody could tell the ping of after those, and
## a full game last of all; a friend's public game is listed once.
func test_the_order_play_online_lists_games_in() -> void:
	var game := func(title: String, ping: int, friend := false, players := 1) -> Dictionary:
		return {
			"title": title,
			"name": "",
			"ping": ping,
			"friend": friend,
			"chips": true,
			"players": players,
			"most": 4,
			"steam_lobby": title.hash(),
		}
	var near: Dictionary = game.call("Near", 20)
	var far: Dictionary = game.call("Far", 140)
	var unknown: Dictionary = game.call("Unknown", SteamPublic.NO_PING)
	var full: Dictionary = game.call("Full", 5, false, 4)
	var friend: Dictionary = game.call("Mine", 180, true)
	var listed := SteamPage.merged([friend], [far, full, unknown, near, friend])
	var titles: Array[String] = []
	for each: Dictionary in listed:
		titles.append(str(each["title"]))
	assert_array(titles).is_equal(["Mine", "Near", "Far", "Unknown", "Full"])


## The ping's bars: four for a near host, one red past 200 ms, none for no ping at all.
func test_the_ping_bars() -> void:
	assert_int(GameSeats.bars_for(20)).is_equal(4)
	assert_int(GameSeats.bars_for(80)).is_equal(3)
	assert_int(GameSeats.bars_for(150)).is_equal(2)
	assert_int(GameSeats.bars_for(GameSeats.SLOW)).is_equal(1)
	assert_int(GameSeats.bars_for(900)).is_equal(1)
	assert_int(GameSeats.bars_for(SteamPublic.NO_PING)).is_equal(0)


## A Steam game's row: its words on the left, seats and ping at the end, Friend after its name, the
## whole said for a screen reader; a full one cannot be joined and can still be watched.
func test_a_steam_games_row() -> void:
	var list: GameList = auto_free(GameList.new())
	var friend := SteamPublic.read(_fake, _fake.public_lobby(FRIEND, _ours()), FRIEND, "Bo")
	friend["friend"] = true
	friend["ping"] = 24
	var full := SteamPublic.read(_fake, _fake.public_lobby(OTHER, _ours()), OTHER, "Cy")
	full["players"] = 8
	full["map"] = "Crossfire, map 2 of 3"
	full["lobby"] = false
	add_child(list)
	list.show_games([friend, full], null)
	var join := list.find_child("Join%d" % int(friend["id"]), true, false) as Button
	assert_object(join.find_child("Seats", true, false)).is_not_null()
	assert_object(join.find_child("FriendTag", true, false)).is_not_null()
	assert_bool(join.disabled).is_false()
	assert_str(list.row_text(int(friend["id"]))).is_equal(
		"Bo's game FRIEND\nIn the lobby · Single map, 5 min"
	)
	assert_str(join.accessibility_description).contains("2 of 8 players, 2 bots, 24 ms")
	var full_join := list.find_child("Join%d" % int(full["id"]), true, false) as Button
	assert_bool(full_join.disabled).is_true()
	assert_object(full_join.find_child("FullTag", true, false)).is_not_null()
	assert_str(list.row_text(int(full["id"]))).contains("Playing Crossfire, map 2 of 3")
	var watch := list.find_child("Watch%d" % int(full["id"]), true, false) as Button
	assert_bool(watch.disabled).is_false()
	assert_bool(GameList.is_full(full)).is_true()
	assert_bool(GameList.is_full({"players": 8, "most": 8})).is_false()


## What a host's lobby says of how the game is played.
func test_the_mode_a_lobby_says() -> void:
	var config := MatchConfig.new()
	config.rounds = 0
	config.duration = 300.0
	assert_str(SteamPresence.mode_of(config)).is_equal("Single map, 5 min")
	config.rounds = 3
	config.teams = 2
	assert_str(SteamPresence.mode_of(config)).is_equal("Grand Prix · Teams")
	config.final_hand = true
	config.teams = 0
	assert_str(SteamPresence.mode_of(config)).is_equal("Final Hand")
	assert_str(SteamPresence.mode_of(null)).is_empty()
