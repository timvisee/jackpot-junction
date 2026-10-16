extends GdUnitTestSuite
## What a Steam build shows of Steam, GAME.md 10.8: Play Online's box of friends' games and Host for
## friends, or why there is none; where a game is played, stamped; Invite friends in the menu of a
## Steam game, through Steam's dialog or the game's own list; Lobby settings for a Steam game; the
## overlay pausing a room of this machine's own; the version on the title. Steam here is always
## [FakeSteam].

const PLAY_ONLINE := preload("res://scenes/ui/play_online.tscn")
const TITLE := "res://scenes/ui/title.gd"
const FRIEND := 76561197960287931
const STRANGER := 76561197960287932

var _fake: FakeSteam
var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_steam_screens.cfg"
	Game.play_online_note = ""
	Game.play_online_reconnect = false
	_fake = FakeSteam.new()


func after_test() -> void:
	Store.steam = null
	Store.missing = ""
	Net.session = null
	Game.pending_config = null
	Settings.remove_files(Game.settings.path)
	Game.settings = _settings_were


func _steam() -> void:
	Store.steam = SteamStore.new(_fake)
	Store.steam.start(3141590)


## A friend in a game of this one's, its lobby having said what it is, and another friend in some
## other game.
func _a_friend_hosting() -> int:
	_fake.friends[FRIEND] = "Bo"
	_fake.friends[STRANGER] = "Cy"
	var lobby := (
		_fake
		. friends_lobby(
			FRIEND,
			{
				SteamLobby.GAME_KEY: SteamLobby.GAME,
				SteamLobby.VERSION_KEY: GameVersion.current(),
				SteamLobby.TITLE_KEY: "",
				SteamLobby.PLAYERS_KEY: "3",
				SteamLobby.MOST_KEY: "8",
				SteamLobby.MAP_KEY: "The Vault",
				SteamLobby.WATCHING_KEY: "1",
			}
		)
	)
	_fake.playing[FRIEND] = {"id": 3141590, "lobby": lobby}
	_fake.playing[STRANGER] = {"id": 440, "lobby": 99}
	return lobby


## Friends' games of this one's are listed as a game on the network is; a lobby that has not said
## what it is yet is asked, and the friends online are there to invite.
func test_friends_games_are_read_off_their_lobbies() -> void:
	_steam()
	var lobby := _a_friend_hosting()
	var games := Store.steam.friends.games()
	assert_array(games).has_size(1)
	assert_str(GameList.title_of(games[0])).is_equal("Bo's game")
	assert_str(GameList.describe(games[0])).is_equal("Playing The Vault · 3/8 players")
	assert_int(games[0]["steam_lobby"]).is_equal(lobby)
	assert_int(games[0]["steam_host"]).is_equal(FRIEND)
	var quiet := _fake.friends_lobby(FRIEND, {})
	_fake.playing[FRIEND] = {"id": 3141590, "lobby": quiet}
	assert_array(Store.steam.friends.games(100.0)).is_empty()
	assert_array(_fake.calls).contains(["requestLobbyData %d" % quiet])
	# Asked again only every few seconds, so a lobby's count and map stay current.
	var asked := func() -> int: return _fake.calls.count("requestLobbyData %d" % quiet)
	Store.steam.friends.games(101.0)
	assert_int(asked.call()).is_equal(1)
	Store.steam.friends.games(100.0 + SteamFriends.ASK_EVERY)
	assert_int(asked.call()).is_equal(2)
	_fake.online = [STRANGER]
	assert_array(Store.steam.friends.online()).is_equal([{"id": STRANGER, "name": "Cy"}])


## In a Steam build, Play Online opens on Steam friends' games, Host for friends under them, and the
## servers' box has room for fewer rows.
func test_play_online_has_a_tab_for_steam_friends() -> void:
	_steam()
	var lobby := _a_friend_hosting()
	var screen: Control = auto_free(PLAY_ONLINE.instantiate())
	var runner := scene_runner(screen)
	await runner.simulate_frames(10)
	screen.set("_friends_since", 100.0)
	await runner.simulate_frames(2)
	# Steam friends first, on a page of its own, the servers and the network on theirs, the tabs on
	# the box showing.
	assert_array(screen.tab_keys).is_equal([screen.STEAM_TAB, screen.SERVERS_TAB, screen.LAN_TAB])
	assert_str(screen.tab_showing()).is_equal(screen.STEAM_TAB)
	assert_bool(screen.steam_page.visible).is_true()
	assert_bool(screen.servers_page.visible).is_false()
	assert_bool(screen.lan.visible).is_false()
	assert_object(screen.tabs_row.get_parent()).is_same(screen.steam_box)
	assert_str(screen.steam_box.link.text).is_equal("Host for friends")
	assert_int(screen.friends_games.get_child_count()).is_equal(1)
	assert_str(screen.friends_games.row_text(lobby & 0x7FFFFFFF)).contains("Bo's game")
	# Turned to Servers, which is kept for next time; Invite only kept too.
	screen.show_tab(screen.SERVERS_TAB)
	assert_bool(screen.steam_page.visible).is_false()
	assert_bool(screen.servers_page.visible).is_true()
	assert_str(Game.settings.play_online_tab).is_equal(screen.SERVERS_TAB)
	screen.invite_only_button.button_pressed = true
	assert_bool(Game.settings.lobby_invite_only).is_true()
	var again: Control = auto_free(PLAY_ONLINE.instantiate())
	runner = scene_runner(again)
	await runner.simulate_frames(5)
	assert_str(again.tab_showing()).is_equal(again.SERVERS_TAB)
	assert_bool(again.invite_only_button.button_pressed).is_true()


## Without Steam the box is not there at all; with Steam wanted and not running, it says so.
func test_play_online_without_steam() -> void:
	var screen: Control = auto_free(PLAY_ONLINE.instantiate())
	var runner := scene_runner(screen)
	await runner.simulate_frames(5)
	assert_object(screen.steam_box).is_null()
	assert_array(screen.tab_keys).is_equal([screen.SERVERS_TAB, screen.LAN_TAB])
	assert_bool(screen.servers_page.visible).is_true()
	Store.missing = "Steam isn't running"
	var wanting: Control = auto_free(PLAY_ONLINE.instantiate())
	runner = scene_runner(wanting)
	await runner.simulate_frames(5)
	assert_object(wanting.steam_box).is_not_null()
	assert_bool(wanting.steam_box.link.visible).is_false()
	assert_bool(wanting.host_button.disabled).is_true()
	var words := (wanting.friends_games.get_child(0) as Label).text
	assert_str(words).is_equal("Steam isn't running")


## Where a game is played, in a word and a line: Steam among friends, a server by name, or LAN.
func test_the_stamp_says_where_a_game_is_played() -> void:
	var config := MatchConfig.new()
	config.online = "join"
	assert_array(Array(NetStamp.words_for(config))).is_equal(["LAN", "THIS NETWORK"])
	config.server = "example.com:7777"
	config.server_name = "Main Street"
	assert_array(Array(NetStamp.words_for(config))).is_equal(["SERVER", "MAIN STREET"])
	config.steam = true
	assert_array(Array(NetStamp.words_for(config))).is_equal(["STEAM", "FRIENDS"])
	var stamp: NetStamp = auto_free(NetStamp.new())
	stamp.show_for(config)
	assert_bool(stamp.visible).is_true()
	config.online = ""
	stamp.show_for(config)
	assert_bool(stamp.visible).is_false()


## Invite goes through Steam's dialog with the overlay up, and the game's own list without it,
## which invites a friend once.
func test_invite_friends() -> void:
	_steam()
	_fake.friends[FRIEND] = "Bo"
	_fake.online = [FRIEND]
	Store.steam.lobbies.host(14)
	var invites: SteamInvites = auto_free(SteamInvites.new())
	add_child(invites)
	invites.open()
	var bo := invites.find_child("Invite*", true, false) as Button
	assert_str(bo.text).is_equal("Bo")
	bo.pressed.emit()
	assert_array(_fake.invited).is_equal([FRIEND])
	assert_bool(bo.disabled).is_true()


## A Steam game's Lobby settings have no password and say whether it is for those invited alone,
## which goes to Steam and is kept.
func test_lobby_settings_of_a_steam_game() -> void:
	_steam()
	Store.steam.lobbies.host(14)
	Net.session = NetSession.new()
	Game.pending_config = SteamJoins.host_config(false)
	var pane: LobbySettings = auto_free(LobbySettings.new())
	add_child(pane)
	pane.open()
	var invite_only := pane.find_child("InviteOnly", true, false) as CheckButton
	assert_bool(invite_only.is_visible_in_tree()).is_true()
	invite_only.button_pressed = true
	assert_bool(Game.settings.lobby_invite_only).is_true()
	assert_array(_fake.calls).contains(
		["setLobbyType %d %d" % [Store.steam.lobby(), SteamLobby.INVITE_ONLY]]
	)
	# Invite friends first, the cursor on it: Steam's dialog with the overlay up, the game's own
	# list in the pane's place without it, and back to the pane from there.
	var invite := pane.find_child("InviteFriends", true, false) as Button
	assert_bool(invite.is_visible_in_tree()).is_true()
	await await_idle_frame()
	assert_object(get_viewport().gui_get_focus_owner()).is_same(invite)
	invite.pressed.emit()
	assert_array(_fake.calls).contains(["activateGameOverlayInviteDialog %d" % Store.steam.lobby()])
	_fake.overlay = false
	invite.pressed.emit()
	assert_bool(pane.visible).is_false()
	var invites: Node = null
	for child: Node in pane.get_parent().get_children():
		if child is SteamInvites:
			invites = child
	assert_bool((invites as Control).visible).is_true()
	(invites as SteamInvites).closed.emit()
	assert_bool(pane.visible).is_true()
	assert_bool((invites as Control).visible).is_false()
	Net.session.free()
	Net.session = null
	pane.open()
	assert_bool(invite_only.is_visible_in_tree()).is_false()
	assert_bool(invite.is_visible_in_tree()).is_false()


## Steam's overlay pauses a room of this machine's own, never one online, and never the menus.
func test_the_overlay_pauses_a_room_here() -> void:
	var menu := Node.new()
	assert_bool(SteamJoins.pauses_for_the_overlay(null, false)).is_false()
	assert_bool(SteamJoins.pauses_for_the_overlay(menu, false)).is_false()
	assert_bool(SteamJoins.pauses_for_the_overlay(menu, true)).is_false()
	menu.free()


## The title's corner says a Steam build is one.
func test_the_version_says_steam() -> void:
	var title: GDScript = load(TITLE)
	assert_str(title.version_words(false)).is_equal("v%s" % Game.version())
	assert_str(title.version_words(true)).is_equal("v%s · Steam" % Game.version())


## In a Steam game the host sees everybody's name on Steam beside where they stand.
func test_manage_players_says_the_steam_name() -> void:
	assert_str(ManagePlayers.with_steam_name("Playing", "")).is_equal("Playing")
	assert_str(ManagePlayers.with_steam_name("Playing", "bo_92")).is_equal(
		"Playing · bo_92 on Steam"
	)
	_steam()
	_fake.friends[FRIEND] = "bo_92"
	assert_str(Store.steam.persona_of(FRIEND)).is_equal("bo_92")
	assert_int(SteamPeer.new(ENetMultiplayerPeer.new()).account_of(2)).is_equal(0)
