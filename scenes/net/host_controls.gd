class_name HostControls
extends Node
## The host's say over its game, GAME.md 10.3: who else is in it, showing any of them out, stopping
## the match for everybody at once, who may come in, what the next match is and where the room
## goes. Hosting at a player's own machine, all of it is that machine's. A game of a dedicated
## server has nobody at the host, GAME.md 9.3a, so the say is a player's at another machine: the
## first to sit down, and when they go, whoever has been in the longest since. What they choose goes
## over the wire from here and is done at the server, which takes it only from them and only as far
## as a menu could have said it.
##
## Lives under the [NetSession] at the same place on every machine, as a call from one to the other
## has to. Kept apart from [NetSession] so that file stays about the connection rather than the
## host.

## At a dedicated server: the say has passed to [param player], 0 for nobody, and the player with
## it has handed it to [param player] themselves, from Manage players.
signal changed_hands(player: int)
signal handed(player: int)
## On a client: the say has come to this machine, or gone from it.
signal granted_changed(mine: bool)
## At a dedicated server: the player with the say has said what the next match is, or that they
## are still choosing it, GAME.md 9.6, for the waiting room to take in and tell everybody.
signal planned(plan: Dictionary, still_choosing: bool)
## At a dedicated server: the player with the say wants the room to go [param where], one of
## [constant PLACES]: back to the waiting room, on to the next map, into a rematch, or from the
## waiting room into the match without waiting for everybody to be ready, GAME.md 9.6.
signal asked_to_go(where: StringName)
## At a dedicated server: the player with the say has changed Lobby settings, or shown [param
## player] out, for the server's log.
signal door_set
signal kicked(player: int)
## On a client: its kart left alone too long in a public game was handed to a bot, GAME.md 10.8,
## and it watches until a press takes the kart back, [param benched], or a press has.
signal benched_changed(benched: bool)
## On a client in a Steam game: come in during Last Call or on the podium, it watches until the next
## map, GAME.md 10.8, [param held], or is let go to sit down there.
signal held_changed(held: bool)
## On a client in a Steam game: its player took over [param from]'s kart in the middle of a match,
## with [param banked] banked, [param coins] in the pot and [param jokers] jokers, GAME.md 10.8.
signal took_over(from: String, banked: int, coins: int, jokers: int)

## How long a kicked client has to hear why before the host lets go of it, in seconds, and what it
## is told when the host showed it out.
const KICK_GRACE := 0.5
const REMOVED := "The host removed you from the game"
## How often a dedicated server looks for a change in who else is in the game, in seconds, to tell
## the player with the say.
const GUESTS_EVERY := 0.25
## Where the room can be asked to go.
const PLACES: Array[StringName] = [&"lobby", &"next", &"rematch", &"start"]
## How long a player's controls may be left alone in a public Steam game's match before a bot
## drives their kart, in seconds, GAME.md 10.8, and how far a stick has to be off its middle to
## count as touched.
const IDLE_FOR := 60.0
const TOUCHED := 0.2
## How long a new host carrying a map over holds its start for the players coming back to connect,
## in seconds, GAME.md 10.8; once they have, each is waited for to put the room up as at any map's
## start, see [constant StartGate.DEADLINE].
const RESUME_WAIT := 15.0

var session: NetSession
## Whether the host's say has stopped the match for everybody without waiting to be asked: on the
## host, what counts; on a client with the say, what it asked for, for its menu to show, GAME.md
## 3.8. Let go of when the say moves on, since the pause was the old holder's.
var forcing := false
## At a dedicated server: who has the say, 0 for nobody, and whether they are still choosing the
## match, which holds the room, GAME.md 9.6.
var peer := 0
var choosing := false
## On a client: whether the say is this machine's, and who handed it over, as they are called in
## the room: empty when it came with the game or passed on as its holder left.
var granted := false
var given_by := ""
## On a client in a public Steam game: whether its kart, left alone, is a bot's while it watches,
## GAME.md 10.8.
var benched := false
## On a client in a Steam game: whether it watches until the next map, come in too late in this one,
## GAME.md 10.8.
var held := false
## On a client of a game hosted at a player's machine off Steam, GAME.md 10.8: who hosts after the
## host, in order, each as the peer they are, the address the host reaches them at and their name,
## see [method succession_line]; the port the game is hosted on; what to host it from, see
## [method MatchResume.plan_of]; what the host is called; and the peer this machine is in it, kept
## for once the connection has gone. And the peer this machine was in a game handed over, said as
## it knocks at the new host, see [HostHandover].
var succession: Array = []
var succession_port := 0
var succession_plan := ""
var succession_host := ""
var succession_me := 0
var was_peer := 0

## At a dedicated server: the players in the order they first sat down, for the say to pass down.
var _order: Array[int] = []
## What the player with the say was last told about everybody else, and how long until it is
## looked at again.
var _told := ""
var _look_left := 0.0
## On a client with the say, and on every client in a Steam game: everybody else in the game, as the
## host last said.
var _guests: Array[Dictionary] = []
## In a Steam game, GAME.md 10.8: what each client was last told of everybody else, and the Steam
## accounts this machine has told Steam it played with.
var _told_each: Dictionary[int, String] = {}
var _played: Dictionary[int, bool] = {}
## In a public Steam game, GAME.md 10.8: at the host, how long each slot driven from elsewhere has
## been left alone, and the clients watching for it till a press brings them back.
var _idle: Dictionary[int, float] = {}
var _benched: Dictionary[int, bool] = {}
## In a Steam game, at the host: the newcomers watching until the next map, GAME.md 10.8, and the
## Steam account the game is to be handed to once the map in play is over, 0 for nobody.
var _next_map: Dictionary[int, bool] = {}
var _hand_on_to := 0
## At a new host carrying a map over, GAME.md 10.8: the seats kept for the players coming back, see
## [method MatchResume.seats_kept]; whether its start is held for them, how much longer for them to
## connect and then to put the room up; and the clients that have it up, see [method room_built].
var _kept_for: Dictionary = {}
var _resuming := false
var _resume_left := 0.0
var _loading_left := 0.0
var _built: Dictionary[int, bool] = {}
## At a host off Steam: what each client was last told of who hosts after it.
var _succession_told: Dictionary[int, String] = {}
## The clients come back to their own karts, who are told nothing about taking one over.
var _returned: Dictionary[int, bool] = {}


func _ready() -> void:
	Events.player_joined.connect(_on_player_joined)


static func of(owner: NetSession) -> HostControls:
	var made := HostControls.new()
	made.name = "Host"
	made.session = owner
	# Kept up while the room is stopped, which is when the list of players is looked at most.
	made.process_mode = Node.PROCESS_MODE_ALWAYS
	owner.connected.connect(made.tell_unlocks)
	return made


## Tells the host what this machine's loyalty program has added to a table, GAME.md 8.9: as it
## comes in, and again after every map or room it writes down, which may have won more. A dedicated
## server deals it whenever the host's say is here; a host with a player of its own deals its own.
func tell_unlocks() -> void:
	if session.is_host or not session._connected():
		return
	var added := Loyalty.unlocks_of(Game.settings.profile)
	_unlocks.rpc_id(1, added["jokers"], added["items"], added["dress"], added["kit"])


@rpc("any_peer", "call_remote", "reliable")
func _unlocks(
	jokers: PackedStringArray,
	items: PackedStringArray,
	dress: PackedStringArray,
	kit: PackedStringArray
) -> void:
	session.conduct.said(multiplayer.get_remote_sender_id())
	keep_unlocks(multiplayer.get_remote_sender_id(), jokers, items, dress, kit)


## At the host: [param player], a client it let in, has added [param jokers] and [param items] and
## won [param dress], kept as far as they are names, see [member NetDoor.unlocks], and said what
## of Kit's cards it may be dealt, [param kit], see [method KitCards.flag_of]: the one flag of the
## story's that goes over the wire, STORY.md 5.3. The host steps that client's karts through what
## it has won at the stalls of GAME.md 4.4.
func keep_unlocks(
	player: int,
	jokers: PackedStringArray,
	items: PackedStringArray,
	dress := PackedStringArray(),
	kit := PackedStringArray()
) -> void:
	if session.is_host and session.door.names.has(player):
		var said := {"jokers": jokers, "items": items, "dress": dress, "kit": kit}
		session.door.unlocks[player] = Loyalty.clean_unlocks(said)


## Whether the host's say is at this machine: a host with a player at it, or a client given it.
func mine() -> bool:
	if session.is_host:
		return not session.dedicated
	return granted


## Everybody else in the host's game, for its Manage players, GAME.md 10.3: each client that plays,
## by the name and color of its seat, and each that watches, by the name it gave. On a client with
## the say, as the server last said, leaving out its own players.
func guests() -> Array[Dictionary]:
	if not session.is_host:
		return _guests
	return session.door.guests(
		session.match_node, session._peer_slots.held, session._watchers, multiplayer
	)


## Shows [param player] out of the game: told why, [param why], and let go of a moment later
## whatever it does with that, so it cannot stay by not listening. It may knock again. With [param
## number], one of several players at it, only that one goes, and the rest of them play on.
func kick(player: int, number := -1, why := REMOVED) -> void:
	if not session.is_host:
		if granted and session._connected():
			_kick.rpc_id(1, player, number)
		return
	if not multiplayer.get_peers().has(player):
		return
	var held: Dictionary = session._peer_slots.held.get(player, {})
	if number >= 0 and held.size() > 1 and held.has(number):
		session._empty_seat(player, number)
		session._seat_dropped.rpc_id(player, number)
		return
	# Out of a public Steam game for as long as it is hosted, GAME.md 10.8; a friend may come back.
	var account := ManagePlayers.account_at(session, player)
	if account != 0 and Store.public_game() and account not in session.door.barred:
		session.door.barred.append(account)
	_kicked.rpc_id(player, why)
	get_tree().create_timer(KICK_GRACE).timeout.connect(_let_go_of.bind(player))


func _let_go_of(player: int) -> void:
	if multiplayer.multiplayer_peer != null and multiplayer.get_peers().has(player):
		multiplayer.multiplayer_peer.disconnect_peer(player)


@rpc("authority", "call_remote", "reliable")
func _kicked(why: String) -> void:
	session._turned_away = true
	session._hang_up.call_deferred(why)


## At a dedicated server, the game is over with somebody still in it, and [param reason] says why:
## everybody left who was playing, leaving somebody watching nobody, GAME.md 9.3a.
func end_the_game(reason: String) -> void:
	if session.is_host and session._connected() and not multiplayer.get_peers().is_empty():
		_ended.rpc(reason)


@rpc("authority", "call_remote", "reliable")
func _ended(reason: String) -> void:
	session._turned_away = true
	session._hang_up.call_deferred(reason)


## The host stopping the match for everybody at once, GAME.md 3.8, rather than waiting for each
## of them to ask. It holds until the host lets go of it, which closing its menu does.
func force_pause(on: bool) -> void:
	if not session.is_host:
		if granted and session._connected():
			forcing = on
			_force.rpc_id(1, on)
		return
	forcing = on
	session._settle_pause()


## Lobby settings have changed who may come in, GAME.md 9.6. At a client with the say, the
## server's door is told; a host's own door has already changed.
func door_changed() -> void:
	if not session.is_host and granted and session._connected():
		_door_to.rpc_id(1, session.door.to_wire())


## What the next match is going to be, [param config], or that it is still being chosen: said to
## the server from a client with the say, which tells the room.
func plan(config: MatchConfig, still_choosing: bool) -> void:
	if not session.is_host and granted and session._connected():
		_plan.rpc_id(1, MatchOptions.to_wire(config), still_choosing)


## Asks the server to take the room [param where], one of [constant PLACES].
func go(where: StringName) -> void:
	if not session.is_host and granted and session._connected():
		_go.rpc_id(1, where)


## Hands the say to [param player], another client playing in the game, GAME.md 9.3a: asked of the
## server from the client with it.
func make_host(player: int) -> void:
	if not session.is_host and granted and session._connected():
		_make_host.rpc_id(1, player)


## At a dedicated server: [param player] has sat down. The first of them has the say.
func seated(player: int) -> void:
	if not session.is_host:
		return
	if player not in _order:
		_order.append(player)
	if not session.dedicated:
		return
	if peer == 0:
		_hand_to(player)


## Hands the game hosted here to the player at [param player], GAME.md 10.8: at once in the lobby
## and on the podium, and at the podium when asked during a map. A Steam game's lobby goes to their
## account; off Steam they are put first in line, and everybody follows them. Make host.
func hand_on(player: int) -> void:
	if not session.is_host or session.dedicated or player == 0:
		return
	if _in_a_map():
		_hand_on_to = player
		return
	var handover := get_tree().get_first_node_in_group(&"host_handover")
	if handover == null:
		return
	if Store.steam_game():
		var account := ManagePlayers.account_at(session, player)
		if account != 0:
			handover.call(&"hand_to", account)
		return
	_order.erase(player)
	_order.push_front(player)
	# Everybody told the new order before the host goes, see [method HostHandover.hand_down].
	_tell_succession()
	handover.call(&"hand_down", succession_line(), _hosted_port(), _plan_here())


## Who hosts after the host here off Steam, in order, GAME.md 10.8: every player at another machine
## who has been in it longest first, each by peer, the address the host reaches them at, name, and
## the slot each of their seats holds, so a map carried over keeps their own karts for them.
func succession_line() -> Array:
	var line: Array = []
	var here := session._player_peers()
	var order := _order.duplicate()
	for each: int in here:
		if each not in order:
			order.append(each)
	for each: int in order:
		if each in here:
			var address := session.guard.address_of(each)
			var seats: Dictionary = session._peer_slots.held.get(each, {}).duplicate()
			line.append(
				{"peer": each, "address": address, "name": _seat_name(each), "seats": seats}
			)
	return line


## Every client told who hosts after the host here, on which port and from what, whenever that
## changes, GAME.md 10.8, for the game to be handed down the line should the host go.
func _tell_succession() -> void:
	var line := succession_line()
	var port := _hosted_port()
	var host := ""
	for slot: PlayerSlot in session.match_node.slots if session.match_node != null else []:
		if slot.is_local_human():
			host = slot.display_name()
			break
	# The password only to those playing: somebody watching may have come in without it.
	var plans: Array[String] = [_plan_here(false), _plan_here()]
	var playing := session._player_peers()
	var peers := multiplayer.get_peers()
	for told: int in _succession_told.keys():
		if told not in peers:
			_succession_told.erase(told)
	for client: int in peers:
		var plan := plans[int(client in playing)]
		var said := str([line, port, plan, host])
		if _succession_told.get(client, "") != said:
			_succession_told[client] = said
			_succession_is.rpc_id(client, line, port, plan, host)


func _plan_here(with_password := true) -> String:
	return MatchResume.plan_of(Game.pending_config, session.door, -1, with_password)


func _hosted_port() -> int:
	var config := Game.pending_config
	return config.port if config != null else NetSession.DEFAULT_PORT


@rpc("authority", "call_remote", "reliable")
func _succession_is(line: Array, port: int, plan: String, host: String) -> void:
	succession = line
	succession_port = port
	succession_plan = plan
	succession_host = PlayerNames.clean(host)
	succession_me = multiplayer.get_unique_id()


## Whether a map is being played here, its podium not yet up.
func _in_a_map() -> bool:
	var match_node := session.match_node
	return session.in_arena and match_node != null and match_node.state != Match.State.RESULTS


## Who hosts the game after the host here, GAME.md 10.8: the player at another machine who has been
## in it longest, 0 for nobody, the first of [method succession_line]; their Steam account, and the
## name they go by in the room.
func successor() -> int:
	var here := session._player_peers()
	for each: int in _order:
		if each in here:
			return each
	return here[0] if not here.is_empty() else 0


func successor_account() -> int:
	return ManagePlayers.account_at(session, successor())


func successor_name() -> String:
	return _seat_name(successor())


## What is asked before a host leaves for the title, GAME.md 9.3 and 10.8: a game with somebody else
## playing in it goes on with them hosting it; one with nobody but watchers is over for them.
static func host_leave_words() -> Array[String]:
	var session := Net.session
	if session != null and not session.dedicated and session.host_controls.successor() != 0:
		var next := session.host_controls.successor_name()
		return ["Leave the game?", "%s hosts it after you." % next, "Leave", "Stay"]
	return [
		"Back to the title?",
		"Everybody who has joined will be disconnected.",
		"Disconnect everybody"
	]


## At a dedicated server: [param player] has gone. With the say, it passes to whoever has been here
## the longest since.
func left(player: int) -> void:
	_order.erase(player)
	if not session.is_host or not session.dedicated or player != peer:
		return
	var next := 0
	var here := session._player_peers()
	for each: int in _order:
		if each in here:
			next = each
			break
	_hand_to(next)


## Gives the say to [param player], or nobody, and takes it from whoever had it if they are still
## here: from [param by], who handed it over, named to the new holder.
func _hand_to(player: int, by := 0) -> void:
	var was := peer
	peer = player
	choosing = false
	# A pause the last holder made is theirs, and goes with the say: whoever has it now has not
	# stopped the room, and would otherwise find it held until they happened to close a menu.
	if forcing:
		forcing = false
		session._settle_pause()
	_told = ""
	_look_left = 0.0
	if was != 0 and was != player and multiplayer.get_peers().has(was):
		_granted.rpc_id(was, false)
	if player != 0:
		_granted.rpc_id(player, true, _seat_name(by) if by != 0 else "")
		_door_is.rpc_id(player, session.door.to_wire())
	changed_hands.emit(player)


## What [param player] is called in the room: their first seat's name, the one every screen shows.
func _seat_name(player: int) -> String:
	var match_node := session.match_node
	var seats: Dictionary = session._peer_slots.held.get(player, {})
	for number: int in seats:
		var index: int = seats[number]
		if match_node != null and index < match_node.slots.size():
			return match_node.slots[index].display_name()
	var named: String = session.door.names.get(player, "")
	return named if not named.is_empty() else "The host"


## At a dedicated server, the player with the say is told whenever somebody else comes, goes or
## changes, for their Manage players; in a Steam game, everybody is, for their Players, GAME.md
## 10.8.
func _process(delta: float) -> void:
	if not session.is_host or not session._connected():
		return
	# The host leaving the room lets go of everybody held for the next map, before they ask for a
	# seat in it, GAME.md 10.8.
	if not session._room_up and not _next_map.is_empty():
		_let_go_of_the_held()
	# Make host asked during a map, done once it is over.
	if _hand_on_to != 0 and not _in_a_map() and session._connected():
		var to := _hand_on_to
		_hand_on_to = 0
		hand_on(to)
	var steam := Store.steam_game()
	# A game hosted here off Steam: everybody told who hosts after it, GAME.md 10.8.
	var hosted_here := not steam and not session.dedicated
	if peer == 0 and not steam and not hosted_here:
		return
	_look_left -= delta
	if _look_left > 0.0:
		return
	_look_left = GUESTS_EVERY
	if steam:
		_tell_everybody()
	elif hosted_here:
		_tell_succession()
	if peer == 0:
		return
	var others: Array[Dictionary] = []
	for guest: Dictionary in guests():
		if int(guest["peer"]) != peer:
			others.append(guest)
	var said := str(others)
	if said != _told:
		_told = said
		_guests_are.rpc_id(peer, others)


## A kart left alone too long in a public Steam game's match is driven by a bot, GAME.md 10.8: at
## the host, each slot driven from elsewhere is timed; at a client watching for it, the first
## press takes it back.
func _physics_process(delta: float) -> void:
	if session.is_host:
		_hold_the_resume(delta)
	if not session.is_host:
		if benched and touched(session.local_input):
			benched = false
			session.watching = false
			benched_changed.emit(false)
			_back.rpc_id(1)
		return
	var match_node := session.match_node
	if not Store.public_game() or match_node == null or not session.in_arena:
		_idle.clear()
		return
	if not match_node.is_running():
		return
	for slot: PlayerSlot in match_node.slots:
		var input := slot.input as NetInput
		if input == null or touched(input):
			_idle.erase(slot.index)
			continue
		_idle[slot.index] = _idle.get(slot.index, 0.0) + delta
		if _idle[slot.index] >= IDLE_FOR:
			_idle.erase(slot.index)
			bench(slot.index)


## At the host in a Steam game: a newcomer, [param player], asking for its seat in Last Call, in
## sudden death or on the podium watches until the next map instead, GAME.md 10.8, told so, and is
## let go to sit down there as the host leaves for it. Says whether it is held.
func holds_for_next_map(player: int) -> bool:
	var match_node := session.match_node
	if not Store.steam_game() or match_node == null or not session.in_arena:
		return false
	if not match_node.in_the_finale() and match_node.state != Match.State.RESULTS:
		return false
	# Somebody coming back to their own kart of a map carried over sits in it whenever.
	if _returned.has(player):
		return false
	_next_map[player] = true
	session._watchers[player] = true
	session._watch(player)
	_held_here.rpc_id(player, true)
	return true


## At the host: the room is being left, and everybody held for the next map may sit down in it.
func _let_go_of_the_held() -> void:
	for player: int in _next_map:
		session._watchers.erase(player)
		session._watching_here.erase(player)
		if multiplayer.get_peers().has(player):
			_held_here.rpc_id(player, false)
	_next_map.clear()


@rpc("authority", "call_remote", "reliable")
func _held_here(on: bool) -> void:
	held = on
	session.watching = on
	held_changed.emit(on)


## At the host: somebody sat down in [param index] of the room, maybe in a bot's kart in the middle
## of a match, which a player from elsewhere in a Steam game is told, GAME.md 10.8: whose it was and
## what came with it. Looked at once the seat is on record.
func _on_player_joined(index: int) -> void:
	if session.is_host and Store.steam_game():
		_tell_who_was_here.call_deferred(index)


func _tell_who_was_here(index: int) -> void:
	var match_node := session.match_node
	if match_node == null or index >= match_node.slots.size() or not match_node.is_running():
		return
	var slot := match_node.slots[index]
	if slot.taken_from.is_empty() or slot.kart == null or not slot.input is NetInput:
		return
	for player: int in session._peer_slots.held:
		if index in (session._peer_slots.held[player] as Dictionary).values():
			if _returned.has(player):
				slot.taken_from = ""
				return
			var kart := slot.kart
			var jokers := kart.jokers.ids().size()
			_took_over_here.rpc_id(player, slot.taken_from, slot.banked, kart.pot.coins, jokers)
			# Told once.
			slot.taken_from = ""
			return


@rpc("authority", "call_remote", "reliable")
func _took_over_here(from: String, banked: int, coins: int, jokers: int) -> void:
	took_over.emit(PlayerNames.clean(from), banked, coins, jokers)


## At a new host carrying a map over, GAME.md 10.8: the seats [param resume] keeps for the players
## coming back, each sat in their own kart as they arrive, and the start held on the grid until
## they all have and have the room up, see [method _hold_the_resume].
func resume_from(resume: Dictionary) -> void:
	_kept_for = MatchResume.seats_kept(resume)
	_built.clear()
	_resuming = true
	_resume_left = RESUME_WAIT
	_loading_left = StartGate.DEADLINE


## A client has the room up, GAME.md 10.3: counted by the gate holding a map's lamps, and by a map
## carried over waiting on the players coming back.
func room_built(peer: int) -> void:
	if session._gate != null:
		session._gate.arrived(peer)
	_built[peer] = true


## A client let in at the host, having said [param words] as it knocked: one coming back to a map
## carried over is kept its own seats, by its Steam account or the peer it was in the old game,
## which [method PlayerSlot.bot_seat] finds by their color, GAME.md 10.8.
func knocked(player: int, words: Dictionary) -> void:
	if not session.is_host or _kept_for.is_empty():
		return
	var account := ManagePlayers.account_at(session, player)
	keep_seats_for(player, MatchResume.returning(account, int(words.get("was", 0))))


## The seats kept for the player who was [param who], see [method MatchResume.returning], given to
## [param player], come back to a map carried over, GAME.md 10.8, if any were.
func keep_seats_for(player: int, who: String) -> void:
	if who.is_empty() or not _kept_for.has(who):
		return
	var theirs: Dictionary[int, Dictionary] = {}
	for number: int in _kept_for[who]:
		var kept: Dictionary = _kept_for[who][number]
		theirs[number] = {"color": kept["color"], "name": kept["name"], "team": kept["team"]}
	session._peer_slots.kept[player] = theirs
	_returned[player] = true
	_kept_for.erase(who)


## The start of a map carried over, held on the grid, GAME.md 10.8: until every player coming back
## has connected, [constant RESUME_WAIT] at most, and then until each has the room up as at any
## map's start, [constant StartGate.DEADLINE] at most, every screen saying how many are ready,
## 10.3. The countdown runs then, from the top.
func _hold_the_resume(delta: float) -> void:
	var match_node := session.match_node
	if not _resuming or match_node == null or match_node.state != Match.State.LOBBY:
		_resuming = false
		return
	if not _kept_for.is_empty():
		_resume_left -= delta
		if _resume_left <= 0.0:
			# Not coming: nobody is held up for them any longer.
			_kept_for.clear()
	var ready := _resume_ready()
	match_node.loading = ready
	if not _kept_for.is_empty():
		return
	if ready.x < ready.y:
		_loading_left -= delta
		if _loading_left > 0.0:
			return
	_resuming = false
	match_node.loading = Vector2i.ZERO
	match_node.begin_from_lobby()


## How many players of a map carried over have the room up, out of how many are playing it or on
## their way back: those here, every seat of a client come back that has it up, and every seat
## still kept for somebody not back yet.
func _resume_ready() -> Vector2i:
	var count := Vector2i.ZERO
	for slot: PlayerSlot in session.match_node.slots:
		if slot.is_local_human():
			count += Vector2i.ONE
	# Connected at all, or still saying hello: a player is given their seats as they knock, before
	# they count as connected, and one still putting the room up is not counted as playing yet.
	var connected := session._peers()
	var scene := multiplayer as SceneMultiplayer
	if scene != null:
		connected.append_array(scene.get_authenticating_peers())
	for peer: int in _returned:
		if peer in connected:
			var seats := maxi((session._peer_slots.held.get(peer, {}) as Dictionary).size(), 1)
			count.y += seats
			count.x += seats if _built.has(peer) else 0
	for who: Variant in _kept_for:
		count.y += (_kept_for[who] as Dictionary).size()
	return count


## Whether [param input] says anybody is at the controls: a stick off its middle, a pedal, a button.
static func touched(input: KartInput) -> bool:
	if input == null:
		return false
	var held := input.handbrake or input.nitro or input.fire or input.joker_menu
	var pressed := input.fire_pressed or input.use_item_pressed or input.emote >= 0
	var moved := absf(input.steer) > TOUCHED or input.throttle > TOUCHED or input.brake > TOUCHED
	return held or pressed or moved or input.aim.length() > TOUCHED


## At the host: the player driving the slot [param index] from another machine has left it alone,
## GAME.md 10.8. A bot drives the kart from here as for somebody who leaves; one of several players
## at that machine goes from it, and the last watches until a press brings them back.
func bench(index: int) -> void:
	var seats := session._peer_slots
	for player: int in seats.held:
		var theirs: Dictionary = seats.held[player]
		for number: int in theirs:
			if int(theirs[number]) != index:
				continue
			session._empty_seat(player, number)
			if not (seats.held.get(player, {}) as Dictionary).is_empty():
				session._seat_dropped.rpc_id(player, number)
				return
			_benched[player] = true
			seats.take_all(player)
			session._watchers[player] = true
			session._watch(player)
			_bench_here.rpc_id(player)
			return


## At a client: its kart is a bot's, GAME.md 10.8, and it watches until a press.
@rpc("authority", "call_remote", "reliable")
func _bench_here() -> void:
	for each: ClientSeat in session.seats.duplicate():
		session._here.stand_up(each, session.match_node)
	session.local_slot = -1
	session.watching = true
	benched = true
	benched_changed.emit(true)


## At the host: a client watching since its kart was left alone pressed something, and is seated
## again, in a bot's kart, GAME.md 10.8.
@rpc("any_peer", "call_remote", "reliable")
func _back() -> void:
	var player := multiplayer.get_remote_sender_id()
	session.conduct.said(player)
	if not session.is_host or not _benched.has(player):
		return
	_benched.erase(player)
	session._watchers.erase(player)
	session._watching_here.erase(player)
	session._seat(player, false)


## Everybody in the game, GAME.md 10.8: the host's own players first, then everybody else, each with
## the slot they play this room in and their Steam account, 0 where there is none.
func everybody() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var match_node := session.match_node
	if session.is_host and not session.dedicated and match_node != null:
		var own := Store.steam.account if Store.on() else 0
		for slot: PlayerSlot in match_node.slots:
			if slot.is_local_human():
				var plate := KartVisuals.plate_worn(slot.kart) if slot.kart != null else ""
				var each := {"peer": 1, "seat": slot.index, "slot": slot.index, "host": true}
				each.merge({"name": slot.display_name(), "color": slot.color(), "plate": plate})
				each["account"] = own
				found.append(each)
	for guest: Dictionary in guests():
		var each := guest.duplicate()
		each["account"] = ManagePlayers.account_at(session, int(guest["peer"]))
		found.append(each)
	return found


## In a Steam game, each client is told who else is in it whenever that changes, GAME.md 10.8, and
## Steam told this machine played with them.
func _tell_everybody() -> void:
	var all := everybody()
	_heard_of(all)
	for client: int in multiplayer.get_peers():
		var others: Array[Dictionary] = []
		for each: Dictionary in all:
			if int(each["peer"]) != client:
				others.append(each)
		var said := str(others)
		if said != _told_each.get(client, ""):
			_told_each[client] = said
			_guests_are.rpc_id(client, others)


## Everybody in the game, [param all], as this machine knows them: which slot is whom, for whose
## emotes are muted, and each new Steam account told to Steam as played with.
func _heard_of(all: Array[Dictionary]) -> void:
	Muted.seen(all)
	if not Store.on():
		return
	for each: Dictionary in all:
		var account := int(each.get("account", 0))
		if account != 0 and not _played.has(account):
			_played[account] = true
			Store.steam.played_with(account)


## Whether the call being answered came from the player with the say, at a dedicated server. Every
## call that asks counts as one sent by hand, whoever sent it, see [method NetConduct.said].
func _from_the_host() -> bool:
	session.conduct.said(multiplayer.get_remote_sender_id())
	if not session.is_host or not session.dedicated or peer == 0:
		return false
	return multiplayer.get_remote_sender_id() == peer


@rpc("any_peer", "call_remote", "reliable")
func _kick(player: int, number: int) -> void:
	if not _from_the_host() or player == peer:
		return
	kicked.emit(player)
	kick(player, number)


@rpc("any_peer", "call_remote", "reliable")
func _force(on: bool) -> void:
	if _from_the_host():
		force_pause(on)


@rpc("any_peer", "call_remote", "reliable")
func _door_to(state: Dictionary) -> void:
	if not _from_the_host():
		return
	session.door.from_wire(state)
	_door_is.rpc_id(peer, session.door.to_wire())
	door_set.emit()


@rpc("any_peer", "call_remote", "reliable")
func _plan(chosen: Dictionary, still_choosing: bool) -> void:
	if not _from_the_host():
		return
	choosing = still_choosing
	planned.emit(chosen, still_choosing)


@rpc("any_peer", "call_remote", "reliable")
func _go(where: StringName) -> void:
	if _from_the_host() and where in PLACES:
		asked_to_go.emit(where)


## Only to somebody else who plays in the game: a watcher has no say to have.
@rpc("any_peer", "call_remote", "reliable")
func _make_host(player: int) -> void:
	if not _from_the_host() or player == peer or not session._player_peers().has(player):
		return
	handed.emit(player)
	_hand_to(player, peer)


@rpc("authority", "call_remote", "reliable")
func _granted(on: bool, by := "") -> void:
	granted = on
	given_by = by if on else ""
	if not on:
		_guests.clear()
		forcing = false
	granted_changed.emit(on)


@rpc("authority", "call_remote", "reliable")
func _guests_are(others: Array) -> void:
	_guests.clear()
	for guest: Variant in others:
		if guest is Dictionary and (guest as Dictionary).has("peer"):
			_guests.append(guest)
	if Store.steam_game():
		_heard_of(_guests)


@rpc("authority", "call_remote", "reliable")
func _door_is(state: Dictionary) -> void:
	session.door.from_wire(state)
