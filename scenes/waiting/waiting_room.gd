extends Node3D
## The room everybody waits in before a match, GAME.md 9.6.
##
## A match needs everybody at the table before it can start, and a menu is a poor place to wait:
## there is nothing to do in one and no way to tell whether the person who has not pressed
## anything yet is thinking or has walked off. So the waiting is done in a room. It is the corner
## of the garage of 9.4, the same concrete bay with the same light, a pad in the middle of it and
## three things to drift round while the last player finds their seat.
##
## Nothing is scored in here. There is no clock, nothing to shoot and nothing to collect: the only
## thing the room asks of anybody is that they drive onto the pad and stay on it, which is what
## says they are ready. When everybody has, the match begins and the room gives way to the arena.
##
## Online it is the room the connection is opened in, and the connection outlives it, see 10.3.
## The host seats everybody here and seats them again in the arena; a client drives in here, is
## told when the host leaves, and follows.

## Given once the room is up and everybody in it is seated, GAME.md 8.6.
signal loaded

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/waiting_room.tres")
## Where the football starts: in front of the pad, on open floor, clear of every prop and spawn.
const BALL_SPOT := Vector3(0.0, 0.0, 5.0)
const RULES: MatchRules = preload("res://data/match/waiting_room.tres")
## What a Steam game's room says about friends coming in, GAME.md 10.8.
const STEAM_HINT := "Friends join through Steam: invite them from the menu, or Join game"
## Where the stalls for dressing the kart start, GAME.md 4.4: the top left cell of the first of
## them, along the back wall on either side of the middle.
const STALLS := Vector2i(4, 1)

var match_node: Match
var ready_room: ReadyRoom
var config: MatchConfig
var session: NetSession
## The host's choice of match, null on any other machine.
var host_settings: HostSettings
## Something to knock about while waiting, GAME.md 9.6.
var ball: RoomBall
## Where everybody dresses their kart while they wait, GAME.md 4.4.
var stalls: StyleStalls
## Up while a client is trying the host's address, saying so, GAME.md 9.3.
var _connecting: StatusPane
## The room's limit on players as it was last said, to say it again when the host changes it.
var _said_limit := -1
## Whether the host came back to this room from a match, on a connection that was already open.
## Who may come in was settled when it was opened, so only the match is asked again, GAME.md 9.6.
var _came_back := false
## The room's pause menu, for the host's entries on it at a client given the say, GAME.md 9.3a.
var _menu: PauseMenu
## Whether the Final Hand's ticket has been torn at the door, STORY.md 8.1.
var _admitted := false


func _ready() -> void:
	config = Game.pending_config if Game.pending_config != null else MatchConfig.new()
	ArenaEnvironment.add_to(self)
	match_node = MATCH_SCENE.instantiate()
	match_node.name = "Match"
	# A copy, since the room is told how many teams there are, GAME.md 3.14, and a client is told
	# the rest of the host's.
	match_node.rules = RULES.duplicate()
	match_node.rules.teams = config.teams
	match_node.arena_layout = LAYOUT
	# What the table deals, GAME.md 8.9, as a map's does.
	Loyalty.deal_table(match_node, load("res://data/powerups/all.tres"), config.dedicated)
	# Nobody looks at a room hosted with nobody at it, GAME.md 9.3a.
	match_node.with_hud = not config.dedicated
	add_child(match_node)
	# Put up behind a loading screen, the way a map is, whoever is hosting.
	# Called the Lobby on the screen, GAME.md 9.6.
	await LoadingScreen.put_up(self, match_node, "Lobby")
	match config.online:
		"host":
			_take_seats()
			_host()
		"join":
			_join()
		_:
			_take_seats()
	_dress_the_room()
	ready_room = ReadyRoom.add_to(match_node)
	ready_room.seats = SeatLimit.seats_for(SeatLimit.limit(match_node, session))
	if config.online != "join":
		ready_room.everybody_ready.connect(_begin, CONNECT_ONE_SHOT)
	if not config.dedicated:
		DebugOverlay.add_to(self, match_node, session)
		# What the players here do in the lobby counts too, GAME.md 8.5, as they leave it.
		MatchRecord.add_to(match_node).maps = false
		CatalogRecord.add_to(match_node)
		LoyaltyRecord.add_to(match_node)
		AchievementRecord.add_to(match_node)
	# Even with nobody here to open it: it is what stops the room once everybody asks.
	var menu := PauseMenu.add_to(self, session)
	menu.names_and_colors = true
	_menu = menu
	# The players here dress their karts from the menu as well as at the stalls, GAME.md 4.4.
	if not config.dedicated:
		menu.offer_kart(match_node)
	# Whoever decides where the room goes chooses the match in here, GAME.md 9.6: the host online,
	# and on one machine the machine itself.
	if config.online != "join":
		_offer_the_settings(menu)
	elif session != null:
		_follow_the_say()
	loaded.emit()


## The people at this machine, and nobody else. Bots do not wait for anybody and cannot drive
## onto a pad to say they are ready, so they are left for the arena, where the host's confirmed
## number of them is added.
func _take_seats() -> void:
	var inputs: Array[KartInput] = []
	for i: int in config.human_devices.size():
		inputs.append(PlayerInput.new(config.human_devices[i], i))
	if inputs.is_empty() and not config.dedicated:
		inputs.append(PlayerInput.new(DeviceInput.ANY, 0))
	# Every seat's name and dress rather than only those sitting down now: somebody taking a seat
	# in here takes theirs with it.
	match_node.start(
		inputs, 0, config.colors(), config.human_names, config.human_styles, config.human_teams
	)


func _host() -> void:
	if Net.online():
		# Back from a match with everybody still connected, GAME.md 9.6. The same connection, a
		# different room: everybody who follows is seated in here as they ask.
		session = Net.session
		_came_back = true
		Net.attach(match_node)
		session.in_arena = false
		session.re_seat()
	else:
		session = Net.open(match_node)
		session.dedicated = config.dedicated
		session.door.max_players = Game.settings.lobby_players
		session.door.watchers_allowed = Game.settings.lobby_watchers
		session.door.watchers_need_password = not Game.settings.lobby_watch_free
		session.door.title = Game.settings.lobby_title
		# A Steam game is for friends, or for those invited, and has no password, GAME.md 10.8.
		session.door.password = "" if config.steam else config.password
		session.door.server_password = config.server_password
		var error := session.host_steam() if config.steam else session.host(config.port)
		if error != OK:
			var on := "on Steam" if config.steam else "on port %d" % config.port
			ready_room_hint("Could not host %s: %s" % [on, error_string(error)])
			return
		if config.steam:
			_open_the_lobby()
	if config.steam:
		ready_room_hint(STEAM_HINT)
	elif not config.dedicated:
		ready_room_hint(
			"Friends join on port %d at %s" % [config.port, ", ".join(_local_addresses())]
		)


## A Steam game's lobby, the way Steam friends come in, GAME.md 10.8: made with the room, and gone
## with the session.
func _open_the_lobby() -> void:
	var lobbies := Store.steam.lobbies
	lobbies.failed.connect(_on_lobby_failed)
	lobbies.host(NetDoor.peers(false) + 1, config.invite_only)


func _on_lobby_failed(why: String) -> void:
	ready_room_hint(why)


## Where this game is, for the words while connecting: the host's on Steam, or an address.
func _where() -> String:
	if config.steam:
		var whose := (
			"%s's game" % config.steam_name if not config.steam_name.is_empty() else "the game"
		)
		return "%s on Steam" % whose
	return "%s:%d" % [config.address, config.port]


func _join() -> void:
	var back := Net.online()
	_came_back = back
	if back:
		# Followed the host back from a match: the connection is the one already open.
		session = Net.session
		Net.attach(match_node)
	else:
		session = Net.open(match_node)
		session.watching = config.watching
		session.password = config.password
		session.server_password = config.server_password
		session.local_input = PlayerInput.new(DeviceInput.ANY, 0)
		session.player_name = config.human_names[0] if not config.human_names.is_empty() else ""
		if not config.human_styles.is_empty():
			session.player_style = PackedInt32Array(config.human_styles[0])
	session.match_beginning.connect(_follow_the_host, CONNECT_ONE_SHOT)
	session.seat_refused.connect(_on_seat_refused)
	# After the signal rather than inside it: going to the title hangs the session up, and a session
	# cannot be freed while it is in the middle of saying something.
	session.disconnected.connect(
		func() -> void: Game.back_to_the_menu.call_deferred("The connection to the game was lost")
	)
	# A host that never answers is said so, rather than left for the player to work out alone in
	# an empty room, and so is one that answers with a version this game cannot play, GAME.md
	# 10.3. The reason is up long enough to be read.
	session.refused.connect(_fail)
	session.locked.connect(_ask_password)
	session.connection_failed.connect(func() -> void: _fail("Could not connect to %s" % _where()))
	if not back:
		var error := (
			session.join_steam(config.steam_host)
			if config.steam
			else session.join(config.address, config.port)
		)
		if error != OK:
			Game.go_to_title()
			return
		# Said while it is being tried, and put away once the host has answered: a room with
		# nobody in it yet is not a room to be looking at without knowing why.
		_connecting = StatusPane.add_to(self)
		_connecting.say("Connecting to %s..." % _where())
		session.rules_applied.connect(_connected, CONNECT_ONE_SHOT)
	match_node.start_puppet()
	if session.watching:
		# Nobody here takes a seat, so the line that says how to has nothing to say.
		session.watching_started.connect(
			func() -> void:
				ready_room_hint("You are watching")
				if ready_room != null:
					ready_room.hide_how_to_sit_down()
		)
	elif not config.server.is_empty():
		# Anybody in a game of a dedicated server can tell a friend where it is, GAME.md 9.3a: on
		# the server called what it calls itself, if anything, at its address.
		var on := "" if config.server_name.is_empty() else "on %s " % config.server_name
		ready_room_hint("Friends find this game in Play Online, %sat %s" % [on, config.server])
	if back:
		# Asked for rather than waited for: the host seats whoever asks once its room is up, and
		# this room is now up at this end to hear the answer.
		session.ready_for_seat()


## The host has answered with the room's rules: through the door.
func _connected() -> void:
	if _connecting != null:
		_connecting.queue_free()
		_connecting = null


## The room is being left before it was ever joined, and the player is told why.
## The host wants a password, GAME.md 9.6: asked for, over the room, and knocked again with. A
## wrong one goes back to LAN games saying so, and so does Back, without saying anything.
func _ask_password(wrong: bool) -> void:
	if _connecting != null:
		_connecting.queue_free()
		_connecting = null
	if match_node.hud != null:
		match_node.hud.stand_down()
	# Back to the screen the game was found on: LAN games, the games of the server it is on, or
	# Play Online's Steam friends.
	var found_on := Game.go_to_online if config.server.is_empty() else Game.back_to_the_server
	if config.steam:
		found_on = Game.go_to_play_online
	if wrong:
		# After the session has finished saying so: going hangs it up, and a session cannot be
		# freed in the middle of saying something.
		found_on.call_deferred("Wrong password")
		return
	var pane := PasswordPane.add_to(self)
	pane.left.connect(func() -> void: found_on.call())
	pane.entered.connect(
		func(typed: String) -> void:
			config.password = typed
			# The session that was turned away hung up but is still the one the game holds, and a
			# room opened with a session held is a room that has followed the host back from a
			# match: it would sit on the dead connection in an empty lobby rather than knock.
			Net.close()
			Game.go_to_waiting(config)
	)


func _fail(message: String) -> void:
	if _connecting != null:
		_connecting.queue_free()
		_connecting = null
	if match_node.hud != null:
		match_node.hud.stand_down()
	StatusPane.add_to(self).fail(message)


## Everybody is ready: through to the arena, with everybody who is here. The word goes out before
## this machine changes room, so the rooms change together rather than leaving a client driving
## round a lobby the host has already left.
func _begin() -> void:
	# The Final Hand's ticket first, its ADMIT ONE torn off at the door, STORY.md 8.1, where the
	# House dealt it; a dedicated server has no screen to tear it on.
	if config.final_hand and not _admitted and not config.dedicated:
		_admitted = true
		FinalHandPane.admit(self).admitted.connect(_begin)
		return
	var first := first_map_config()
	if session != null:
		session.begin_the_match()
	Game.start_match(first)


## What the first map is built from: [method arena_config], and for Play the Grand Prix dealt
## now that everybody playing it is here, GAME.md 9.7, with the first of its maps.
func first_map_config() -> MatchConfig:
	var first := arena_config()
	Game.grand_prix = null
	if first.rounds > 0:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		# A room too big for the usual size deals the XL maps alone, GAME.md 6.3.
		var crowded := first.crowded()
		var maps := ArenaMaps.pool(first.normal_maps and not crowded, first.xl_maps or crowded)
		Game.grand_prix = GrandPrix.start(
			first.rounds, rng, first.keep_jokers, maps, first.tie_breaker
		)
		first.map = Game.grand_prix.current_map()
		# And its bots, once: the same ones drive every map of it.
		Game.grand_prix.deal_bots(
			load("res://data/ai/traits.tres"), first.network_seats + first.bot_count, rng
		)
	return first


## The host chooses the match in here, GAME.md 9.6: first thing on opening the room, and again
## from the pause menu. The room is open the whole time, so friends join while it is chosen.
func _offer_the_settings(menu: PauseMenu) -> void:
	Events.player_joined.connect(_on_player_joined)
	# Back from the Final Hand online, the next match is the room's own again, STORY.md 8.6.
	if _came_back and config.final_hand:
		FinalHand.clear_table(config)
	if config.dedicated:
		# Nobody here chooses: a player at another machine has the say, see 9.3a, and the room
		# goes to whatever they last said.
		session.host_controls.planned.connect(_on_planned)
		session.host_controls.changed_hands.connect(_on_hands_changed)
		_say_the_plan()
		return
	host_settings = HostSettings.add_to(self, config.online == "", session)
	host_settings.closed.connect(_chosen)
	menu.add_entry("Match settings", choose)
	# Hosting, who may come in first, then what the match is, GAME.md 9.6. Back from a match only
	# the match: the lobby's are on the pause menu for a host who wants them.
	_choose_or_ask(not _came_back)


## While the Final Hand is due for the profile playing the House asks first, at whichever machine
## has the say, every time Play opens a lobby, though not again on coming back to it from a match,
## STORY.md 8.1; then the match settings, [param lobby_first] as [method choose] has it.
func _choose_or_ask(lobby_first: bool) -> void:
	if not _came_back and FinalHand.offered(Game.settings.profile):
		FinalHandPane.add_to(self).answered.connect(_on_the_house)
		return
	choose(lobby_first)


## The House's question answered: its table set and shown, locked, or put off until Play next
## opens a lobby; the match settings either way.
func _on_the_house(take: bool) -> void:
	if take:
		FinalHand.set_table(config, Game.settings.difficulty)
		host_settings.set_by_the_house(config)
		ready_room.show_ticket()
	choose(not _came_back)


## Opens the choosing. The host's own karts wait where they are while it is open, as they do under
## any menu here, see [method _menu_up].
func choose(lobby_first := false) -> void:
	host_settings.open(lobby_first)
	_hold(true)
	_say_the_plan()


## Held for as long as a menu is up rather than once when it opens: the room opens the choosing on
## the first frame, before the match has finished starting, and a match that starts lets every
## kart go.
func _process(_delta: float) -> void:
	_hold(_menu_up())
	# The host's lobby may be made smaller or bigger while everybody waits in it, GAME.md 9.6, and
	# everybody in it is told.
	if config.online != "join" and SeatLimit.limit(match_node, session) != _said_limit:
		_say_the_plan()


func _chosen() -> void:
	host_settings.options.apply_to(config)
	_hold(false)
	_seat_the_teams()
	_say_the_plan()


## At a dedicated server, what the player with the say has chosen, or is choosing, GAME.md 9.3a.
func _on_planned(plan: Dictionary, _still_choosing: bool) -> void:
	MatchOptions.from_wire(config, plan)
	_seat_the_teams()
	_say_the_plan()


## The teams as the match has just been set up, GAME.md 3.14 and 9.6: everybody keeps a team that is
## still there, and the rest are seated on the smallest.
func _seat_the_teams() -> void:
	if match_node.rules.teams == config.teams:
		return
	match_node.rules.teams = config.teams
	TeamCorners.reseat(match_node)


## At a dedicated server, the say has passed to somebody else, who is not choosing anything yet;
## nor dealt the House's table, which was the last one's.
func _on_hands_changed(_player: int) -> void:
	if config.final_hand:
		FinalHand.clear_table(config)
	_say_the_plan()


## At a client of a dedicated server, the host's say may be this machine's, GAME.md 9.3a: it made
## the game, or has been in it the longest since whoever had the say left. The match settings come
## with it, and the host's entries on the pause menu.
func _follow_the_say() -> void:
	session.host_controls.granted_changed.connect(_on_granted)
	if session.host_controls.mine():
		_take_the_say(true)


func _on_granted(mine: bool) -> void:
	if mine:
		_take_the_say(false)
	elif host_settings != null and host_settings.is_open():
		host_settings.close()


## The match settings for this machine, as a host has them: up at once for the game's maker, the
## lobby's own first; again for one [param arriving] back from a match with the say; and for
## somebody the say has just passed to, a word that it has, see [method HostSettings.tell_new_host],
## and the pause menu for when they want them.
func _take_the_say(arriving: bool) -> void:
	if host_settings == null:
		host_settings = HostSettings.add_to(self, false, session)
		host_settings.closed.connect(_chosen)
		_menu.add_entry("Match settings", choose)
	if config.creating:
		# Who may come in starts where its maker last left it, as a host's door does, GAME.md 9.6.
		config.creating = false
		session.door.max_players = Game.settings.lobby_players
		session.door.watchers_allowed = Game.settings.lobby_watchers
		session.door.watchers_need_password = not Game.settings.lobby_watch_free
		session.door.title = Game.settings.lobby_title
		session.host_controls.door_changed()
		_choose_or_ask(true)
	elif arriving:
		_choose_or_ask(false)
	else:
		HostSettings.tell_new_host(self, session.host_controls.given_by)


## Whether a menu at this screen has the controls: the match settings, the room's menu with whatever
## is up in its place, the House's question, or anything else with the cursor on it. The controls
## are working it, and a kart that drove off on them, revving, would be a kart nobody was driving.
func _menu_up() -> bool:
	if host_settings != null and host_settings.is_open():
		return true
	if PauseMenu.is_open_in(get_tree()):
		return true
	return get_viewport().gui_get_focus_owner() != null


## The karts at this screen [param held] where they are, still and quiet, see [member Kart.held].
func _hold(held: bool) -> void:
	for slot: PlayerSlot in match_node.slots:
		if slot.is_local_human() and slot.kart != null:
			slot.kart.held = held
	if match_node.puppet:
		# A client's own karts are driven here ahead of the host, so holding one still here would
		# only be driven past. They are held by sending the host nothing to drive them on, and
		# only go quiet here.
		if session != null:
			for each: ClientSeat in session.seats:
				each.held = held
		return


## Another player here asked the host for a seat and the game had none, GAME.md 10.3.
func _on_seat_refused(_seat: int) -> void:
	SeatLimit.say_full(self, SeatLimit.limit(match_node, session))


## Tells the room what the next match is, or that it is still being chosen. The host's own room
## hears it the same way the clients' rooms do.
func _say_the_plan() -> void:
	if config.online == "join":
		# A client with the say tells the server, and the server tells the room, 9.3a.
		if session != null:
			session.host_controls.plan(config, _choosing())
		return
	_said_limit = SeatLimit.limit(match_node, session)
	Events.room_planned.emit(config.bot_count, _said_limit)
	Events.match_planned.emit(
		MatchOptions.describe(config, _team_sizes()), _choosing(), config.final_hand
	)


## How the teams will stand, GAME.md 9.6, "2 v 2": everybody here on the team they are on, and the
## bots coming in with the match on the smallest, as many as there are seats for. Empty without
## teams.
func _team_sizes() -> Array[int]:
	if config.teams <= 0:
		return []
	var wanted: Array[int] = []
	for slot: PlayerSlot in match_node.slots:
		if slot.is_human():
			wanted.append(slot.team)
	var seats := SeatLimit.seats_for(SeatLimit.limit(match_node, session))
	var bots := clampi(config.bot_count, 0, maxi(seats - wanted.size(), 0))
	var sizes: Array[int] = []
	sizes.resize(config.teams)
	sizes.fill(0)
	for team: int in Teams.deal(wanted, config.teams, wanted.size() + bots):
		sizes[team] += 1
	return sizes.filter(func(size: int) -> bool: return size > 0)


## Whether whoever decides where the room goes is still choosing the match: at this machine, or at
## a dedicated server, the player at another machine who has the say.
func _choosing() -> bool:
	if host_settings != null:
		return host_settings.is_open()
	return session != null and session.dedicated and session.host_controls.choosing


## Somebody arrived. They were not here to hear the plan the first time, so it is said again.
func _on_player_joined(_slot: int) -> void:
	_say_the_plan()


## What the arena is built from: the configuration the room was opened with, and everybody at
## this machine as the room has them now. A seat taken in here is as much a part of the match as
## the one that came in through the door, and the arena keeps the color, the name and the dress
## each of them had in the room rather than handing out new ones on the way across.
func arena_config() -> MatchConfig:
	config.take_locals(match_node)
	# Everybody connected from elsewhere is kept a seat, in the color they had in here and in the
	# order the host will seat them again, and the bots the host asked for are on top of everybody
	# here, as many of them as the arena has seats left for.
	var kept: Array[int] = []
	var sides: Array[int] = []
	if session != null:
		for index: int in session.peer_seats():
			if index < match_node.slots.size():
				kept.append(match_node.slots[index].color_index)
				sides.append(match_node.slots[index].team)
	var remote := kept.size()
	config.network_seats = remote
	config.network_colors = kept
	config.network_teams = sides
	config.seats = SeatLimit.seats_for(SeatLimit.limit(match_node, session))
	var free := config.seats - config.human_devices.size() - remote
	config.bot_count = clampi(config.bot_count, 0, maxi(free, 0))
	return config


## The host has gone through. A client follows into the same arena; which one it is arrives on
## the wire with the rest of the rules, see 10.3.
func _follow_the_host() -> void:
	Game.start_match(config)


## What the room is dressed as: nothing is being played in it, so it is not dressed as a match.
## No crowd to watch a waiting room, no lights over it, no hoardings selling anything to nobody,
## and the camera holds the whole room rather than following anybody -- everybody in here is
## waiting on everybody else, so what has to be on screen is the pad and who is standing on it.
func _dress_the_room() -> void:
	match_node.arena.disco.enabled = false
	match_node.arena.crowd.enabled = false
	match_node.arena.billboards.visible = false
	if match_node.hud != null:
		match_node.hud.waiting = true
	match_node.camera_rig.show_the_room(0.8)
	WaitingProps.add_to(match_node.arena)
	stalls = StyleStalls.add_to(match_node, STALLS)
	TeamCorners.add_to(match_node)
	# The host, or this machine alone, kicks the ball and a client is told where it went, until a
	# kart of its own kicks it, see [RoomBall].
	var joining := config.online == "join"
	ball = RoomBall.add_to(match_node, BALL_SPOT, not joining)
	if session != null:
		ball.here = session.multiplayer.get_unique_id() if joining else 1
		if joining:
			session.ball.told.connect(ball.follow)
			ball.claimed.connect(session.ball.claim)
		else:
			ball.moved.connect(session.ball.share)
			session.ball.claimed.connect(ball.adopt)


## The line under the ready count that says how somebody at another machine gets in. Held until
## the room is built, since the room is what says it.
func ready_room_hint(words: String) -> void:
	if ready_room != null:
		ready_room.say_how_to_join(words)
		return
	await get_tree().process_frame
	if ready_room != null:
		ready_room.say_how_to_join(words)


## IPv4 addresses of this machine other than loopback, for the joining line.
func _local_addresses() -> PackedStringArray:
	var result: PackedStringArray = []
	for address: String in IP.get_local_addresses():
		if address.contains(".") and not address.begins_with("127."):
			result.append(address)
	if result.is_empty():
		result.append("127.0.0.1")
	return result


## Pressing the join button on a device nobody is playing with adds that player, the same as it
## does in a match, and heard first for the same reason: a pad's join button is its pause button,
## and a pad nobody is driving pressing it is somebody sitting down. This is the room that is for,
## so the HUD says so out loud.
func _input(event: InputEvent) -> void:
	if not event.is_action_pressed(InputActions.JOIN) or get_tree().paused or PlayerInput.typing:
		return
	var device := DeviceInput.KEYBOARD if event is InputEventKey else event.device
	if SeatLimit.join(self, match_node, session, device):
		get_viewport().set_input_as_handled()
