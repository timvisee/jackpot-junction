extends GdUnitTestSuite
## A Steam game's lobby, GAME.md 10.8: made by the host and saying what the game is, joined by a
## friend, refused for another game or another version, asked for by Steam, invited to, left. And
## a friend's game joined when Steam asks: at once at the menus, asked first anywhere else. Steam
## here is always [FakeSteam].

const FRIEND := 76561197960287931

var _fake: FakeSteam
var _lobbies: SteamLobby


func before_test() -> void:
	_fake = FakeSteam.new()
	_lobbies = SteamLobby.new(_fake)


func after_test() -> void:
	Store.steam = null
	Store.asked_lobby = 0


## The host's lobby is up, friends-only or for invites alone, saying the game and its version;
## told again, only what changed goes to Steam.
func test_the_host_makes_a_lobby_that_says_what_it_is() -> void:
	var made: Array[int] = []
	_lobbies.made.connect(func(lobby: int) -> void: made.append(lobby))
	_lobbies.host(14)
	assert_array(made).has_size(1)
	assert_int(_lobbies.id).is_equal(made[0])
	assert_bool(_lobbies.hosting).is_true()
	assert_array(_fake.calls).contains(["createLobby %d 14" % SteamLobby.FRIENDS_ONLY])
	assert_str(_fake.getLobbyData(made[0], SteamLobby.GAME_KEY)).is_equal(SteamLobby.GAME)
	assert_str(_fake.getLobbyData(made[0], SteamLobby.VERSION_KEY)).is_equal(GameVersion.current())
	_lobbies.describe({SteamLobby.PLAYERS_KEY: 2})
	assert_str(_fake.getLobbyData(made[0], SteamLobby.PLAYERS_KEY)).is_equal("2")
	_lobbies.leave()
	assert_int(_lobbies.id).is_equal(0)
	assert_array(_fake.calls).contains(["leaveLobby %d" % made[0]])
	_lobbies.host(14, true)
	assert_array(_fake.calls).contains(["createLobby %d 14" % SteamLobby.INVITE_ONLY])


## A friend's game of this version is entered, its owner the host to connect to.
func test_a_friends_game_is_entered() -> void:
	var lobby := _fake.friends_lobby(FRIEND, _ours())
	var entered: Array[int] = []
	_lobbies.entered.connect(func(at: int, host: int) -> void: entered.append_array([at, host]))
	_lobbies.join(lobby)
	assert_array(entered).is_equal([lobby, FRIEND])
	assert_int(_lobbies.id).is_equal(lobby)
	assert_bool(_lobbies.hosting).is_false()


## Another game's lobby, or one of a version this game cannot play with, is left again with why.
func test_another_game_or_version_is_refused() -> void:
	var why: Array[String] = []
	_lobbies.failed.connect(func(said: String) -> void: why.append(said))
	_lobbies.join(_fake.friends_lobby(FRIEND, {SteamLobby.GAME_KEY: "spacewar"}))
	assert_str(why[0]).contains("not a Jackpot Junction game")
	var older := _ours()
	older[SteamLobby.VERSION_KEY] = "0.1.0"
	_lobbies.join(_fake.friends_lobby(FRIEND, older))
	assert_str(why[1]).contains("version 0.1.0")
	assert_int(_lobbies.id).is_equal(0)
	_lobbies.join(424242)
	assert_str(why[2]).contains("Could not get into")


## Steam asking to join is said, with the friend who asked by name.
func test_steam_asking_is_heard() -> void:
	var lobby := _fake.friends_lobby(FRIEND, _ours())
	_fake.friends[FRIEND] = "Bo"
	var asked: Array[int] = []
	_lobbies.asked.connect(func(at: int) -> void: asked.append(at))
	_fake.join_requested.emit(lobby, FRIEND)
	assert_array(asked).is_equal([lobby])
	assert_str(_lobbies.host_of(lobby)).is_equal("Bo")


## Invite opens Steam's own dialog, or says it cannot when the overlay is off; a friend from the
## game's own list is invited without it.
func test_invites() -> void:
	assert_bool(_lobbies.invite()).is_false()
	_lobbies.host(14)
	assert_bool(_lobbies.invite()).is_true()
	assert_array(_fake.calls).contains(["activateGameOverlayInviteDialog %d" % _lobbies.id])
	_fake.overlay = false
	assert_bool(_lobbies.invite()).is_false()
	assert_bool(_lobbies.invite_friend(FRIEND)).is_true()
	assert_array(_fake.invited).is_equal([FRIEND])


## Steam starts the game with `+connect_lobby <id>` for a friend's game.
func test_the_launch_names_the_lobby() -> void:
	assert_int(Store.lobby_in(PackedStringArray(["--path", "."]))).is_equal(0)
	assert_int(Store.lobby_in(PackedStringArray(["+connect_lobby", "1097752410"]))).is_equal(
		1097752410
	)
	assert_int(Store.lobby_in(PackedStringArray(["+connect_lobby"]))).is_equal(0)
	assert_bool(Store.join_asked_at_launch()).is_false()


## What joining would leave: nothing at the menus, a match, another online game or a room.
func test_what_joining_leaves() -> void:
	var menu := Node.new()
	menu.scene_file_path = Game.TITLE_SCENE
	assert_str(SteamJoins.busy_with(menu, false)).is_empty()
	assert_str(SteamJoins.busy_with(menu, true)).is_equal("game")
	assert_str(SteamJoins.busy_with(null, false)).is_empty()
	menu.scene_file_path = Game.MATCH_SCENE
	assert_str(SteamJoins.busy_with(menu, false)).is_equal("match")
	menu.free()


## The configurations a Steam game is hosted and joined with.
func test_the_configurations() -> void:
	var joining := SteamJoins.join_config(77, FRIEND, "Bo", true)
	assert_bool(joining.steam).is_true()
	assert_str(joining.online).is_equal("join")
	assert_bool(joining.watching).is_true()
	assert_int(joining.steam_lobby).is_equal(77)
	assert_int(joining.steam_host).is_equal(FRIEND)
	assert_str(joining.steam_name).is_equal("Bo")
	var hosting := SteamJoins.host_config(true)
	assert_bool(hosting.steam).is_true()
	assert_str(hosting.online).is_equal("host")
	assert_bool(hosting.invite_only).is_true()


## Joining asks Steam for the lobby and waits on its answer, which here never comes, since the
## answer changes the scene; Stay on a question leaves everything as it was.
func test_a_friends_game_is_joined_when_steam_asks() -> void:
	_fake.answers = false
	Store.steam = SteamStore.new(_fake)
	Store.steam.start(Store.SPACEWAR)
	var joins: SteamJoins = auto_free(SteamJoins.new())
	var waited: Array[String] = []
	joins.wait_on = func(note: String) -> void: waited.append(note)
	add_child(joins)
	var lobby := _fake.friends_lobby(FRIEND, _ours())
	_fake.friends[FRIEND] = "Bo"
	joins.join(lobby)
	assert_array(waited).is_equal(["Joining Bo's game on Steam..."])
	assert_array(_fake.calls).contains(["joinLobby %d" % lobby])
	assert_object(joins.question()).is_null()
	joins._ask("Leave this match to join Bo?", lobby)
	assert_str(joins.question().said()).contains("join Bo")
	joins.question().no_button().pressed.emit()
	assert_object(joins.question()).is_null()


func _ours() -> Dictionary:
	return {SteamLobby.GAME_KEY: SteamLobby.GAME, SteamLobby.VERSION_KEY: GameVersion.current()}
