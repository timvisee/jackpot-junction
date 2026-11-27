extends GdUnitTestSuite
## What a Steam build shows of Steam, GAME.md 10.8: Play Online's box of Steam games and Host a game
## with who may join, or why there is none; where a game is played, stamped; Invite friends in the
## menu of a Steam game, through Steam's dialog or the game's own list; Lobby settings for a Steam
## game; the overlay pausing a room of this machine's own; the version on the title. Steam here is
## always [FakeSteam].

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


## In a Steam build, Play Online opens on Steam games, friends' and strangers' public ones in one
## box, with Host a game and who may join under them.
func test_play_online_has_a_tab_for_steam_games() -> void:
	_steam()
	var lobby := _a_friend_hosting()
	var stranger := 76561197960287977
	var data := {
		SteamLobby.GAME_KEY: SteamLobby.GAME,
		SteamLobby.VERSION_KEY: GameVersion.current(),
		SteamLobby.LINE_KEY: SteamLobby.line_of(GameVersion.current()),
		SteamLobby.HOST_KEY: "Zed",
		SteamLobby.PLAYERS_KEY: "1",
		SteamLobby.MOST_KEY: "8",
		SteamLobby.COLORS_KEY: "2",
	}
	var public := _fake.public_lobby(stranger, data)
	_fake.players_now = 140
	var screen: Control = auto_free(PLAY_ONLINE.instantiate())
	var runner := scene_runner(screen)
	await runner.simulate_frames(10)
	# Steam first, on a page of its own, the servers and the network on theirs, the tabs on the box
	# showing.
	assert_array(screen.tab_keys).is_equal([screen.STEAM_TAB, screen.SERVERS_TAB, screen.LAN_TAB])
	assert_str(screen.tab_showing()).is_equal(screen.STEAM_TAB)
	assert_bool(screen.steam_page.visible).is_true()
	assert_bool(screen.servers_page.visible).is_false()
	assert_bool(screen.lan.visible).is_false()
	var page: SteamPage = screen.steam_page
	assert_object(screen.tabs_row.get_parent()).is_same(page.box)
	assert_str(page.box.link.text).is_equal("Host a game")
	# The friend's game first, the stranger's public one after it; how many play said over them.
	assert_int(page.games.get_child_count()).is_equal(2)
	assert_str(page.games.row_text(lobby & 0x7FFFFFFF)).contains("Bo's game")
	assert_str(page.games.row_text(public & 0x7FFFFFFF)).contains("Zed's game")
	assert_str(page.games.get_child(0).find_child("Join*", true, false).name).is_equal(
		"Join%d" % (lobby & 0x7FFFFFFF)
	)
	assert_str(page.line.text).starts_with("140 playing now.")
	# Turned to Servers, which is kept for next time; who may join kept too.
	screen.show_tab(screen.SERVERS_TAB)
	assert_bool(screen.steam_page.visible).is_false()
	assert_bool(screen.servers_page.visible).is_true()
	assert_str(Game.settings.play_online_tab).is_equal(screen.SERVERS_TAB)
	page.who_button.select(SteamLobby.Who.ANYONE)
	page.who_button.item_selected.emit(SteamLobby.Who.ANYONE)
	assert_int(Game.settings.lobby_who).is_equal(SteamLobby.Who.ANYONE)
	assert_int(SteamJoins.host_config().lobby_who).is_equal(SteamLobby.Who.ANYONE)
	var again: Control = auto_free(PLAY_ONLINE.instantiate())
	runner = scene_runner(again)
	await runner.simulate_frames(5)
	assert_str(again.tab_showing()).is_equal(again.SERVERS_TAB)
	assert_int(again.steam_page.who_button.selected).is_equal(SteamLobby.Who.ANYONE)


## Fewer than enough playing is not said: a small number would advertise an empty game.
func test_a_small_count_is_not_said() -> void:
	_steam()
	_fake.players_now = SteamPublic.COUNT_FROM - 1
	var screen: Control = auto_free(PLAY_ONLINE.instantiate())
	var runner := scene_runner(screen)
	await runner.simulate_frames(5)
	assert_str((screen.steam_page as SteamPage).line.text).is_equal(SteamPage.LINE)


## Without Steam the box is not there at all; with Steam wanted and not running, it says so.
func test_play_online_without_steam() -> void:
	var screen: Control = auto_free(PLAY_ONLINE.instantiate())
	var runner := scene_runner(screen)
	await runner.simulate_frames(5)
	assert_object(screen.steam_page).is_null()
	assert_array(screen.tab_keys).is_equal([screen.SERVERS_TAB, screen.LAN_TAB])
	assert_bool(screen.servers_page.visible).is_true()
	Store.missing = "Steam isn't running"
	var wanting: Control = auto_free(PLAY_ONLINE.instantiate())
	runner = scene_runner(wanting)
	await runner.simulate_frames(5)
	var page: SteamPage = wanting.steam_page
	assert_object(page).is_not_null()
	assert_bool(page.box.link.visible).is_false()
	assert_bool(page.host_button.disabled).is_true()
	assert_bool(page.who_button.disabled).is_true()
	var words := (page.games.get_child(0) as Label).text
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


## A Steam game's Lobby settings have no password and say who may join, as the lobby is open now,
## which goes to Steam and is kept.
func test_lobby_settings_of_a_steam_game() -> void:
	_steam()
	Game.settings.lobby_who = SteamLobby.Who.FRIENDS
	Store.steam.lobbies.host(14, SteamLobby.Who.ANYONE)
	Net.session = NetSession.new()
	Game.pending_config = SteamJoins.host_config(SteamLobby.Who.ANYONE)
	var pane: LobbySettings = auto_free(LobbySettings.new())
	add_child(pane)
	pane.open()
	var who := pane.find_child("WhoCanJoin", true, false) as OptionButton
	assert_bool(who.is_visible_in_tree()).is_true()
	assert_int(who.selected).is_equal(SteamLobby.Who.ANYONE)
	who.select(SteamLobby.Who.INVITE_ONLY)
	who.item_selected.emit(SteamLobby.Who.INVITE_ONLY)
	assert_int(Game.settings.lobby_who).is_equal(SteamLobby.Who.INVITE_ONLY)
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
	assert_bool(who.is_visible_in_tree()).is_false()
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


## In a Steam game, Profile beside each of the others in Manage players opens their Steam profile in
## Steam's overlay; the host's own rows have none, and nor does a game with no overlay or no Steam.
func test_manage_players_opens_a_steam_profile() -> void:
	_steam()
	assert_bool(ManagePlayers._profiles()).is_false()
	Net.session = NetSession.new()
	Game.pending_config = SteamJoins.host_config(false)
	assert_bool(ManagePlayers._profiles()).is_true()
	var pane: SteamRows = auto_free(SteamRows.new())
	add_child(pane)
	var bo := pane._row({"name": "Bo", "color": Color.RED, "seat": 1, "peer": 2})
	var profile := bo.find_child("Profile", true, false) as Button
	assert_str(profile.text).is_equal("Profile")
	profile.pressed.emit()
	assert_array(_fake.calls).contains(["activateGameOverlayToUser steamid %d" % FRIEND])
	var me := pane._row({"name": "Ann", "color": Color.BLUE, "seat": 0, "me": true})
	assert_object(me.find_child("Profile", true, false)).is_null()
	_fake.overlay = false
	assert_bool(ManagePlayers._profiles()).is_false()
	var unseen := pane._row({"name": "Bo", "color": Color.RED, "seat": 1, "peer": 2})
	assert_object(unseen.find_child("Profile", true, false)).is_null()
	for row: Node in [bo, me, unseen]:
		row.free()
	Net.session.free()
	Net.session = null


## Manage players with every other player on Steam as [constant FRIEND].
class SteamRows:
	extends ManagePlayers

	func _account(_guest: Dictionary) -> int:
		return FRIEND


## The search field keeps to the friends whose names have what is typed in them, any case; the list
## stays as tall; a friend invited stays invited however the search goes.
func test_invite_friends_can_be_searched() -> void:
	_steam()
	for each: Array in [[FRIEND, "Bo"], [STRANGER, "bobcat"], [76561197960287933, "Cy"]]:
		_fake.friends[each[0]] = each[1]
		_fake.online.append(each[0])
	Store.steam.lobbies.host(14)
	var invites: SteamInvites = auto_free(SteamInvites.new())
	add_child(invites)
	invites.open()
	var names := func() -> Array[String]:
		var found: Array[String] = []
		for row: Node in invites.find_child("Friends", true, false).get_children():
			if row is Button and not row.is_queued_for_deletion():
				found.append((row as Button).text)
		return found
	assert_array(names.call()).is_equal(["Bo", "bobcat", "Cy"])
	var search := invites.find_child("Search", true, false) as LineEdit
	var tall := (
		(invites.find_child("Friends", true, false).get_parent() as Control).custom_minimum_size.y
	)
	search.text = "BO"
	search.text_changed.emit(search.text)
	assert_array(names.call()).is_equal(["Bo", "bobcat"])
	(invites.find_child("Invite*", true, false) as Button).pressed.emit()
	assert_array(_fake.invited).is_equal([FRIEND])
	search.text = ""
	search.text_changed.emit(search.text)
	assert_array(names.call()).is_equal(["Bo" + SteamInvites.INVITED, "bobcat", "Cy"])
	(
		assert_float(
			(
				(invites.find_child("Friends", true, false).get_parent() as Control)
				. custom_minimum_size
				. y
			)
		)
		. is_equal(tall)
	)
	search.text = "zed"
	search.text_changed.emit(search.text)
	assert_array(names.call()).is_empty()
