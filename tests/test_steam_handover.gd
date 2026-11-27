extends GdUnitTestSuite
## A Steam game handed to a new host as its host goes, GAME.md 10.8: what the host keeps in the
## lobby for the next host to take the game on with; a player whose host went waiting for the next
## and following them in, or hosting the game themselves when Steam made them its owner; the lobby
## kept the whole way; giving up; and the lobby handed on by Make host. Steam here is always
## [FakeSteam].

const OLD_HOST := 76561197960287931
const NEXT := 76561197960287932

var _fake: FakeSteam
var _handover: HostHandover
var _went: Array[MatchConfig] = []
var _gave_up: Array[String] = []


func before_test() -> void:
	_fake = FakeSteam.new()
	Store.steam = SteamStore.new(_fake)
	Store.steam.start(3141590)
	_handover = HostHandover.new()
	_handover.go_on = func(config: MatchConfig) -> void: _went.append(config)
	_handover.give_up_to = func(why: String) -> void: _gave_up.append(why)
	add_child(_handover)
	_went.clear()
	_gave_up.clear()


func after_test() -> void:
	_handover.free()
	if Net.session != null:
		Net.close()
	Store.steam = null
	Game.pending_config = null


## A plan the old host kept in its lobby: a quick match of 3 minutes, bots making up four, the
## door of a game called Friday Karts for six, open to anyone.
func _plan() -> String:
	var config := MatchConfig.new()
	config.duration = 180.0
	config.make_up = MatchConfig.MAKE_UP
	config.quick_play = true
	config.final_hand = true
	var door := NetDoor.new()
	door.title = "Friday Karts"
	door.max_players = 6
	door.password = "secret"
	return MatchResume.plan_of(config, door, SteamLobby.Who.ANYONE)


## A client of the old host's game, in its lobby, with the plan in it.
func _a_client() -> NetSession:
	var data := {
		SteamLobby.GAME_KEY: SteamLobby.GAME, SteamLobby.VERSION_KEY: GameVersion.current()
	}
	data[SteamLobby.PLAN_KEY] = _plan()
	data[SteamLobby.HOSTED_KEY] = str(OLD_HOST)
	var lobby := _fake.friends_lobby(OLD_HOST, data)
	_fake.lobbies[lobby]["members"].append(NEXT)
	_fake.friends[NEXT] = "Bo"
	Store.steam.lobbies.join(lobby)
	Game.pending_config = SteamJoins.join_config(lobby, OLD_HOST, "Kit")
	return Net.open(null)


## What the host keeps in its lobby is what a new host takes the game on with, but for the story's
## Final Hand, which is its dealer's, and a password, which a Steam game has none of.
func test_the_plan_a_new_host_takes_on() -> void:
	var lobby := _fake.friends_lobby(OLD_HOST, {SteamLobby.PLAN_KEY: _plan()})
	var config := HostHandover.rehost_config(_fake, lobby)
	assert_bool(config.rehost).is_true()
	assert_str(config.online).is_equal("host")
	assert_bool(config.steam).is_true()
	assert_float(config.duration).is_equal(180.0)
	assert_int(config.make_up).is_equal(MatchConfig.MAKE_UP)
	assert_bool(config.quick_play).is_true()
	assert_bool(config.final_hand).is_false()
	assert_int(config.lobby_who).is_equal(SteamLobby.Who.ANYONE)
	assert_str(str(config.door_plan["title"])).is_equal("Friday Karts")
	assert_int(int(config.door_plan["max_players"])).is_equal(6)
	assert_bool(config.door_plan.has("password")).is_false()
	# A lobby saying nothing: the next host's own settings, still a game taken on.
	var bare := HostHandover.rehost_config(_fake, _fake.friends_lobby(OLD_HOST, {}))
	assert_bool(bare.rehost).is_true()
	assert_int(bare.lobby_who).is_equal(SteamLobby.Who.FRIENDS)


## The host gone: the session closed with the lobby kept, the dialog up, and once the next host's
## game is up, in after them.
func test_a_player_follows_the_next_host() -> void:
	var session := _a_client()
	var lobby := Store.steam.lobby()
	assert_bool(_handover.take(session)).is_true()
	assert_bool(_handover.dialog.is_open()).is_true()
	assert_str(_handover.dialog._title.text).is_equal("Kit left")
	await await_idle_frame()
	assert_object(Net.session).is_null()
	assert_int(Store.steam.lobby()).is_equal(lobby)
	assert_array(_fake.calls).not_contains(["leaveLobby %d" % lobby])
	# Steam makes Bo the owner; until Bo's game is up, nobody goes anywhere.
	_fake.lobbies[lobby]["owner"] = NEXT
	await await_idle_frame()
	assert_array(_went).is_empty()
	assert_str(_handover.dialog._line.text).is_equal("Migrating host to Bo...")
	_fake.lobbies[lobby]["data"][SteamLobby.HOSTED_KEY] = str(NEXT)
	await await_idle_frame()
	assert_array(_went).has_size(1)
	assert_str(_went[0].online).is_equal("join")
	assert_int(_went[0].steam_host).is_equal(NEXT)
	assert_int(_went[0].steam_lobby).is_equal(lobby)
	assert_bool(_handover.is_handing_over()).is_false()
	assert_bool(_handover.dialog.visible).is_false()


## Steam makes this player the owner: the game hosted here afresh, as the lobby says.
func test_the_next_host_takes_it_on() -> void:
	var session := _a_client()
	var lobby := Store.steam.lobby()
	_handover.take(session)
	await await_idle_frame()
	_fake.lobbies[lobby]["owner"] = _fake.account
	await await_idle_frame()
	assert_array(_went).has_size(1)
	assert_bool(_went[0].rehost).is_true()
	assert_bool(_went[0].quick_play).is_true()
	assert_bool(Store.steam.lobbies.hosting).is_true()
	assert_int(Store.steam.lobbies.who).is_equal(SteamLobby.Who.ANYONE)
	Store.steam.lobbies.hosted_here()
	assert_str(_fake.getLobbyData(lobby, SteamLobby.HOSTED_KEY)).is_equal(str(_fake.account))


## Leave, or nobody taking it on: the lobby left, and back to Play Online saying the game is over.
func test_giving_up() -> void:
	var session := _a_client()
	var lobby := Store.steam.lobby()
	_handover.take(session)
	await await_idle_frame()
	# The host still in the lobby: this machine lost its connection rather than the host going.
	_handover.leave_button.pressed.emit()
	assert_array(_gave_up).is_equal(["The connection to the game was lost"])
	assert_array(_fake.calls).contains(["leaveLobby %d" % lobby])
	assert_bool(_handover.is_handing_over()).is_false()
	# Not a Steam game's client, nothing to take.
	assert_bool(_handover.take(null)).is_false()


## The host gone from the lobby and nobody taking it on: the game is over, saying who left.
func test_giving_up_once_the_host_is_gone() -> void:
	var session := _a_client()
	var lobby := Store.steam.lobby()
	_fake.lobbies[lobby]["members"].erase(OLD_HOST)
	_handover.take(session)
	await await_idle_frame()
	_handover.give_up()
	assert_array(_gave_up).is_equal(["Kit left, so the game is over."])


## Make host: the lobby handed to the player, the game's session closed with the lobby kept, and
## this machine following them as the others do.
func test_make_host_hands_the_lobby_on() -> void:
	Game.pending_config = SteamJoins.host_config()
	Store.steam.lobbies.host(8, SteamLobby.Who.FRIENDS)
	var lobby := Store.steam.lobby()
	Net.open(null).is_host = true
	_handover.hand_to(NEXT)
	assert_array(_fake.calls).contains(["setLobbyOwner %d %d" % [lobby, NEXT]])
	assert_bool(_handover.is_handing_over()).is_true()
	await await_idle_frame()
	assert_object(Net.session).is_null()
	assert_array(_fake.calls).not_contains(["leaveLobby %d" % lobby])
	_fake.lobbies[lobby]["data"][SteamLobby.HOSTED_KEY] = str(NEXT)
	await await_idle_frame()
	assert_array(_went).has_size(1)
	assert_int(_went[0].steam_host).is_equal(NEXT)
