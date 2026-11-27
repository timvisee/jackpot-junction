extends GdUnitTestSuite
## Quick Play, GAME.md 10.8: which public games it may join and which it tries first; asking Steam
## close by, then farther, then once more after a moment; a game found joined, one with somebody the
## player blocked passed over, and a game started with bots when there is none; Cancel; the game it
## starts; its button first on the Steam tab; and its lobby going by itself once half of it is
## ready. Steam here is always [FakeSteam].

const PLAY_ONLINE := preload("res://scenes/ui/play_online.tscn")
const WAITING_SCENE := preload("res://scenes/waiting/waiting_room.tscn")
const FRIEND := 76561197960287931
const STRANGER := 76561197960287970
const OTHER := 76561197960287971

var _fake: FakeSteam
var _settings_were: Settings
var _joined: Array[MatchConfig] = []
var _hosted: Array[MatchConfig] = []


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_quick_play.cfg"
	_fake = FakeSteam.new()
	_joined.clear()
	_hosted.clear()


func after_test() -> void:
	Store.steam = null
	Game.pending_config = null
	get_tree().paused = false
	Net.close()
	Settings.remove_files(Game.settings.path)
	Game.settings = _settings_were


func _steam() -> void:
	Store.steam = SteamStore.new(_fake)
	Store.steam.start(3141590)


func _ours(extra := {}) -> Dictionary:
	var data := {
		SteamLobby.GAME_KEY: SteamLobby.GAME,
		SteamLobby.VERSION_KEY: GameVersion.current(),
		SteamLobby.LINE_KEY: SteamLobby.line_of(GameVersion.current()),
		SteamLobby.PLAYERS_KEY: "2",
		SteamLobby.MOST_KEY: "8",
		SteamLobby.COLORS_KEY: "1,2",
		SteamLobby.PING_KEY: "fra",
	}
	data.merge(extra, true)
	return data


## Quick Play on a screen of its own, going nowhere: what it would join or host is kept.
func _quick() -> QuickPlay:
	var screen: Control = auto_free(Control.new())
	add_child(screen)
	var quick := QuickPlay.add_to(screen)
	quick.join_game = func(config: MatchConfig) -> void: _joined.append(config)
	quick.host_game = func(config: MatchConfig) -> void: _hosted.append(config)
	quick.wait_most = 0.05
	quick.starting_for = 0.05
	return quick


func _game(players: int, ping: int, friend := false, lobby := true) -> Dictionary:
	return {
		"title": "",
		"name": "P%d" % ping,
		"players": players,
		"most": 8,
		"chips": true,
		"ping": ping,
		"friend": friend,
		"lobby": lobby,
		"password": false,
	}


## A game it may join has a seat for the player and a ping of 100 ms at most; a game nobody could
## tell the ping of only from a search close by.
func test_which_games_fit() -> void:
	var full := _game(8, 20)
	var almost := _game(7, 20)
	var slow := _game(2, QuickPlay.MOST_PING + 1)
	var unknown := _game(2, SteamPublic.NO_PING)
	var fits := QuickPlay.fitting([full, almost, slow, unknown], false)
	assert_array(fits).is_equal([almost])
	assert_array(QuickPlay.fitting([unknown], true)).is_equal([unknown])


## A friend's first, then one under 50 ms, then the most people, then a lobby before a map, then the
## lowest ping.
func test_which_game_first() -> void:
	var busy_far := _game(5, 80)
	var quiet_near := _game(1, 20)
	var busy_near := _game(4, 30)
	var friend_far := _game(1, 90, true)
	var mid_map := _game(4, 25, false, false)
	var order := QuickPlay.ranked([busy_far, quiet_near, busy_near, friend_far, mid_map])
	assert_array(order).is_equal([friend_far, busy_near, mid_map, quiet_near, busy_far])


## The game it starts: open to anyone, a quick match, the Standard preset at the profile's table,
## normal bots making up four karts.
func test_the_game_it_starts() -> void:
	var config := QuickPlay.config()
	assert_bool(config.quick_play).is_true()
	assert_bool(config.steam).is_true()
	assert_str(config.online).is_equal("host")
	assert_int(config.lobby_who).is_equal(SteamLobby.Who.ANYONE)
	assert_int(config.rounds).is_equal(0)
	assert_int(config.make_up).is_equal(MatchConfig.MAKE_UP)
	assert_str(config.difficulty).is_equal("normal")
	assert_float(config.duration).is_equal(300.0)
	assert_int(config.target_score).is_equal(3000)
	assert_bool(config.overtime).is_true()
	assert_int(config.table).is_equal(Game.settings.profile.table_opened())
	assert_array(ArenaMaps.pool(true, false)).contains([config.map])


## A game close by is joined at once, Steam asked close by and no farther.
func test_a_game_close_by_is_joined() -> void:
	_steam()
	_fake.pings["fra"] = 30
	var lobby := _fake.public_lobby(STRANGER, _ours({SteamLobby.HOST_KEY: "Zed"}))
	var quick := _quick()
	quick.start()
	assert_bool(quick.dialog.is_open()).is_true()
	assert_int(_joined.size()).is_equal(1)
	assert_int(_joined[0].steam_lobby).is_equal(lobby)
	assert_int(_joined[0].steam_host).is_equal(STRANGER)
	assert_str(_joined[0].steam_name).is_equal("Zed")
	assert_array(_fake.calls).contains(["requestLobbyList %d" % SteamPublic.NEAR])
	assert_array(_fake.calls).not_contains(["requestLobbyList %d" % SteamPublic.FAR])
	assert_bool(quick.is_busy()).is_false()


## Nothing close by: farther. A game with somebody in it the player blocked is passed over for the
## next one.
func test_farther_and_past_the_blocked() -> void:
	_steam()
	_fake.pings["fra"] = 40
	_fake.pings["nyc"] = 90
	var blocked := _fake.public_lobby(STRANGER, _ours({SteamLobby.PLAYERS_KEY: "5"}), 2)
	_fake.lobbies[blocked]["members"].append(OTHER)
	_fake.blocked = [OTHER]
	var other := _fake.public_lobby(OTHER + 1, _ours({SteamLobby.PING_KEY: "nyc"}), 2)
	var quick := _quick()
	quick.start()
	assert_array(_fake.calls).contains(["requestLobbyList %d" % SteamPublic.FAR])
	assert_array(_fake.calls).contains(["leaveLobby %d" % blocked])
	assert_int(_joined.size()).is_equal(1)
	assert_int(_joined[0].steam_lobby).is_equal(other)


## Nothing anywhere: a moment, Steam asked once more, and a game started with bots, said first.
func test_none_anywhere_starts_one() -> void:
	_steam()
	var quick := _quick()
	quick.start()
	assert_int(_fake.calls.count("requestLobbyList %d" % SteamPublic.FAR)).is_equal(1)
	await await_millis(200)
	assert_int(_fake.calls.count("requestLobbyList %d" % SteamPublic.FAR)).is_equal(2)
	assert_str(quick.dialog._line.text).is_equal(QuickPlay.STARTING)
	await await_millis(200)
	assert_int(_hosted.size()).is_equal(1)
	assert_bool(_hosted[0].quick_play).is_true()
	assert_bool(quick.is_busy()).is_false()


## Cancel stops it, whatever it was doing, and nothing is joined or started.
func test_cancel() -> void:
	_steam()
	_fake.lists_answer = false
	var quick := _quick()
	quick.start()
	assert_bool(quick.is_busy()).is_true()
	quick.cancel_button.pressed.emit()
	assert_bool(quick.is_busy()).is_false()
	_fake.answer_list()
	await await_millis(200)
	assert_array(_joined).is_empty()
	assert_array(_hosted).is_empty()


## Quick Play is the Steam tab's first button, with the cursor, and the box's link starts it too.
func test_quick_play_on_the_steam_tab() -> void:
	_steam()
	_fake.lists_answer = false
	var screen: Control = auto_free(PLAY_ONLINE.instantiate())
	var runner := scene_runner(screen)
	await runner.simulate_frames(10)
	var page: SteamPage = screen.steam_page
	assert_str(page.quick_button.text).is_equal("Quick Play")
	assert_object(get_viewport().gui_get_focus_owner()).is_same(page.quick_button)
	assert_str(page.box.link.text).is_equal(SteamPage.START_ONE)
	page.box.link.pressed.emit()
	assert_bool(page.quick.is_busy()).is_true()
	assert_bool(page.quick.dialog.is_open()).is_true()
	# Back cancels it rather than leaving the screen.
	screen._back()
	assert_bool(page.quick.is_busy()).is_false()


## A Quick Play game's lobby goes by itself once half of it is ready, counted down over the pad;
## not before half are, and not in any other lobby.
func test_its_lobby_goes_once_half_are_ready() -> void:
	Game.pending_config = MatchConfig.new()
	var room: Node3D = auto_free(WAITING_SCENE.instantiate())
	var runner := scene_runner(room)
	await runner.simulate_frames(45, 17)
	var ready_room: ReadyRoom = room.ready_room
	if ready_room.everybody_ready.is_connected(room._begin):
		ready_room.everybody_ready.disconnect(room._begin)
	if room.host_settings != null:
		room.host_settings.close()
	var match_node: Match = room.get_node("Match")
	match_node._join_with_input(PlayerInput.new(1, 1))
	var went := {"count": 0}
	ready_room.everybody_ready.connect(func() -> void: went["count"] += 1)
	var kart := match_node.slots[0].kart
	kart.global_position = match_node.arena.junction.global_position
	kart.velocity = Vector3.ZERO
	kart.motor.velocity = Vector3.ZERO
	kart.protection_left = 0.0
	await runner.simulate_frames(int(ReadyRoom.CHARGE_TIME * 60.0) + 20, 17)
	assert_int(ready_room.ready_count()).is_equal(1)
	assert_float(ready_room.starting_in).is_equal(-1.0)
	match_node.rules.quick_start = true
	await runner.simulate_frames(30, 17)
	assert_float(ready_room.starting_in).is_less(ReadyRoom.HALF_WAIT)
	assert_float(ready_room.starting_in).is_greater(0.0)
	assert_str(ready_room._said).contains("STARTS IN")
	ready_room.starting_in = 0.05
	await runner.simulate_frames(10, 17)
	assert_int(went["count"]).is_equal(1)
