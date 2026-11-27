extends GdUnitTestSuite
## Managing players in a Steam game, GAME.md 10.8: words other players wrote, through Steam's text
## filter; somebody kicked from a public game, or blocked by its host, kept out; the players muted
## on a screen; Players for everybody, with Profile and Mute and only the host's Kick; and Steam
## told who was played with. Steam here is always [FakeSteam].

const FRIEND := 76561197960287931
const STRANGER := 76561197960287960

var _fake: FakeSteam


func before_test() -> void:
	_fake = FakeSteam.new()
	SteamWords.forget()
	Muted.clear()


func after_test() -> void:
	Store.steam = null
	if Net.session != null:
		Net.session.free()
	Net.session = null
	Game.pending_config = null
	SteamWords.forget()
	Muted.clear()


func _steam() -> void:
	Store.steam = SteamStore.new(_fake)
	Store.steam.start(3141590)


## In a Steam game, joined: what [method Store.steam_game] asks for.
func _in_a_steam_game() -> NetSession:
	_steam()
	Net.session = NetSession.new()
	Game.pending_config = SteamJoins.join_config(77, FRIEND, "Bo")
	return Net.session


## Without Steam, words are as written; with it, through Steam's filter by the player's own setting,
## each asked once.
func test_words_go_through_steams_filter() -> void:
	assert_str(SteamWords.heard("darn kart")).is_equal("darn kart")
	_steam()
	_fake.rude = ["darn"]
	assert_str(SteamWords.heard("darn kart", STRANGER)).is_equal("**** kart")
	assert_str(SteamWords.heard("")).is_empty()
	_fake.rude = []
	# Kept from the first time.
	assert_str(SteamWords.heard("darn kart", STRANGER)).is_equal("**** kart")
	SteamWords.forget()
	assert_str(SteamWords.heard("darn kart", STRANGER)).is_equal("darn kart")


## A game's name and its host's on the list go through the filter too.
func test_a_games_name_is_filtered() -> void:
	_steam()
	_fake.rude = ["darn"]
	var game := {"title": "darn karts", "name": "Zed", "steam_host": STRANGER}
	assert_str(GameList.title_of(game)).is_equal("**** karts")
	game["title"] = ""
	game["name"] = "darnZed"
	assert_str(GameList.title_of(game)).is_equal("****Zed's game")


## Somebody kept out, kicked from a public game or blocked on Steam by its host, is told they cannot
## join it; the name a client knocks with goes through the host's filter.
func test_the_door_keeps_out_the_barred() -> void:
	var door := NetDoor.new()
	var room := {"no_seat": false, "players": 1, "humans": 1, "watchers": 0, "barred": true}
	var words := NetDoor.knock(GameVersion.current(), false, "Cy", "")
	var answered := door.answer(GameVersion.current(), 5, words, room)
	assert_bool(answered["welcome"]).is_false()
	assert_str(NetDoor.refusal(GameVersion.current(), answered)).is_equal(
		"You can't join this game"
	)
	_steam()
	_fake.rude = ["darn"]
	room["barred"] = false
	room["account"] = STRANGER
	words = NetDoor.knock(GameVersion.current(), false, "darnCy", "")
	answered = door.answer(GameVersion.current(), 6, words, room)
	assert_bool(answered["welcome"]).is_true()
	assert_str(door.names[6]).is_equal("****Cy")


## Blocked on Steam is blocked here; no Steam, or no account, blocks nobody.
func test_blocked_on_steam() -> void:
	assert_bool(Store.blocked(STRANGER)).is_false()
	_steam()
	_fake.blocked = [STRANGER]
	assert_bool(Store.blocked(STRANGER)).is_true()
	assert_bool(Store.blocked(FRIEND)).is_false()
	assert_bool(Store.blocked(0)).is_false()


## A public game is a Steam game hosted here open to anyone.
func test_a_public_game() -> void:
	assert_bool(Store.public_game()).is_false()
	_steam()
	Net.session = NetSession.new()
	Game.pending_config = SteamJoins.host_config(SteamLobby.Who.FRIENDS)
	Store.steam.lobbies.host(8, SteamLobby.Who.FRIENDS)
	assert_bool(Store.public_game()).is_false()
	Store.steam.lobbies.set_who(SteamLobby.Who.ANYONE)
	assert_bool(Store.public_game()).is_true()


## What is asked before a kick says whether they can come back.
func test_kick_words() -> void:
	assert_str(ManagePlayers.kick_words("Bo", false)[1]).is_equal(
		"Bo goes back to the title, and can join again."
	)
	assert_str(ManagePlayers.kick_words("Bo", false, true)[1]).is_equal(
		"Bo goes back to the title, and can't join this game again."
	)


## Every row's chip says the seat in the room, as the corner of the screen does: a guest's own too,
## not the number of their seat at their machine, which is for Kick. And off Steam a player without
## the say is told only the host kicks, not about Steam's Mute and Report.
func test_every_chip_says_the_seat_in_the_room() -> void:
	var pane: ManagePlayers = auto_free(ManagePlayers.new())
	add_child(pane)
	var card := pane._row({"name": "Bo", "color": Color.RED, "seat": 0, "slot": 2, "peer": 9})
	auto_free(card)
	assert_str(card._mark).is_equal("3")
	var mine := pane._row({"name": "Ann", "color": Color.BLUE, "seat": 1, "me": true})
	auto_free(mine)
	assert_str(mine._mark).is_equal("2")
	var session: NetSession = auto_free(NetSession.new())
	add_child(session)
	pane.session = session
	pane.open()
	assert_str(pane._note.text).is_equal(ManagePlayers.OFF_STEAM_NOTE)


## The list is offered to whoever has the say, and to everybody in a game a player hosts, on Steam
## or off it; not to a player at a dedicated server's game without the say.
func test_who_the_list_is_offered_to() -> void:
	assert_bool(ManagePlayers.offered(null, true)).is_false()
	var session: NetSession = auto_free(NetSession.new())
	assert_bool(ManagePlayers.offered(session, true)).is_true()
	var kept := Game.pending_config
	Game.pending_config = MatchConfig.new()
	assert_bool(ManagePlayers.offered(session, false)).is_true()
	Game.pending_config.server = "a server"
	assert_bool(ManagePlayers.offered(session, false)).is_false()
	assert_bool(ManagePlayers.offered(session, true)).is_true()
	Game.pending_config = kept
	_in_a_steam_game()
	assert_bool(ManagePlayers.offered(Net.session, false)).is_true()


## A player muted is known by their machine and seat, whichever slot they play this room in; a
## watcher by their name; everybody heard again once the game is over.
func test_the_muted() -> void:
	var bo := {"peer": 2, "seat": 0, "color": Color.RED, "name": "Bo"}
	var cy := {"peer": 3, "seat": 1, "color": Color.BLUE, "name": "Cy"}
	var dee := {"peer": 4, "name": "Dee"}
	Muted.mute(bo, true)
	Muted.mute(dee, true)
	assert_bool(Muted.is_muted(bo)).is_true()
	assert_bool(Muted.is_muted(cy)).is_false()
	assert_bool(Muted.watcher("Dee")).is_true()
	bo["slot"] = 3
	cy["slot"] = 1
	Muted.seen([bo, cy, dee])
	assert_bool(Muted.slot(3)).is_true()
	assert_bool(Muted.slot(1)).is_false()
	# Another room, another slot, the same player.
	bo["slot"] = 2
	Muted.seen([bo, cy])
	assert_bool(Muted.slot(3)).is_false()
	assert_bool(Muted.slot(2)).is_true()
	Muted.mute(bo, false)
	assert_bool(Muted.slot(2)).is_false()
	Muted.clear()
	assert_bool(Muted.watcher("Dee")).is_false()


## At a client in a Steam game, Players lists everybody the host said, the host's own player marked
## Host: Profile and Mute on each row and no Kick; Mute hides that player's emotes here, and Steam
## is told who was played with, once each.
func test_players_at_a_client() -> void:
	var session := _in_a_steam_game()
	_fake.friends[FRIEND] = "Bo"
	(
		session
		. host_controls
		. _guests_are(
			[
				{
					"peer": 1,
					"seat": 0,
					"slot": 0,
					"name": "Ann",
					"color": Color.BLUE,
					"plate": "ANN 1",
					"account": FRIEND,
					"host": true,
				},
				{
					"peer": 9,
					"seat": 0,
					"slot": 2,
					"name": "Cy",
					"color": Color.RED,
					"plate": "CY 2",
					"account": STRANGER,
				},
			]
		)
	)
	assert_array(_fake.calls).contains(["setPlayedWith %d" % FRIEND, "setPlayedWith %d" % STRANGER])
	session.host_controls._guests_are(session.host_controls.guests().duplicate())
	assert_int(_fake.calls.count("setPlayedWith %d" % STRANGER)).is_equal(1)
	var pane: ManagePlayers = auto_free(ManagePlayers.new())
	pane.session = session
	var button: Button = auto_free(Button.new())
	pane.button = button
	add_child(pane)
	pane.open()
	pane._process(0.0)
	assert_str(button.text).is_equal("Players")
	var rows := pane._rows.get_children()
	assert_int(rows.size()).is_equal(2)
	var cy: Control = rows[1]
	assert_object(cy.find_child("Kick", true, false)).is_null()
	assert_object(cy.find_child("Profile", true, false)).is_not_null()
	var mute := cy.find_child("Mute", true, false) as Button
	assert_str(mute.text).is_equal("Mute")
	mute.pressed.emit()
	assert_bool(Muted.slot(2)).is_true()
	assert_bool(Muted.slot(0)).is_false()
	pane._process(0.0)
	var again := pane._rows.get_children()
	assert_str((again[1].find_child("Mute", true, false) as Button).text).is_equal("Unmute")
	var said := pane.find_children("*", "Label", true, false).map(
		func(label: Label) -> String: return label.text
	)
	assert_array(said).contains(["Host · Bo on Steam"])
	await await_idle_frame()
