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

## At a dedicated server: the say has passed to [param player], 0 for nobody.
signal changed_hands(player: int)
## On a client: the say has come to this machine, or gone from it.
signal granted_changed(mine: bool)
## At a dedicated server: the player with the say has said what the next match is, or that they
## are still choosing it, GAME.md 9.6, for the waiting room to take in and tell everybody.
signal planned(plan: Dictionary, still_choosing: bool)
## At a dedicated server: the player with the say wants the room to go [param where], one of
## [constant PLACES]: back to the waiting room, on to the next map, or into a rematch.
signal asked_to_go(where: StringName)
## At a dedicated server: the player with the say has changed Lobby settings, or shown [param
## player] out, for the server's log.
signal door_set
signal kicked(player: int)

## How long a kicked client has to hear why before the host lets go of it, in seconds.
const KICK_GRACE := 0.5
## How often a dedicated server looks for a change in who else is in the game, in seconds, to tell
## the player with the say.
const GUESTS_EVERY := 0.25
## Where the room can be asked to go.
const PLACES: Array[StringName] = [&"lobby", &"next", &"rematch"]

var session: NetSession
## On the host: whether it has stopped the match for everybody without waiting to be asked.
var forcing := false
## At a dedicated server: who has the say, 0 for nobody, and whether they are still choosing the
## match, which holds the room, GAME.md 9.6.
var peer := 0
var choosing := false
## On a client: whether the say is this machine's.
var granted := false

## At a dedicated server: the players in the order they first sat down, for the say to pass down.
var _order: Array[int] = []
## What the player with the say was last told about everybody else, and how long until it is
## looked at again.
var _told := ""
var _look_left := 0.0
## On a client with the say: everybody else in the game, as the server last said.
var _guests: Array[Dictionary] = []


static func of(owner: NetSession) -> HostControls:
	var made := HostControls.new()
	made.name = "Host"
	made.session = owner
	# Kept up while the room is stopped, which is when the list of players is looked at most.
	made.process_mode = Node.PROCESS_MODE_ALWAYS
	return made


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


## Shows [param player] out of the game: told why, and let go of a moment later whatever it does
## with that, so it cannot stay by not listening. It may knock again. With [param number], one of
## several players at it, only that one goes, and the rest of them play on.
func kick(player: int, number := -1) -> void:
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
	_kicked.rpc_id(player)
	get_tree().create_timer(KICK_GRACE).timeout.connect(_let_go_of.bind(player))


func _let_go_of(player: int) -> void:
	if multiplayer.multiplayer_peer != null and multiplayer.get_peers().has(player):
		multiplayer.multiplayer_peer.disconnect_peer(player)


@rpc("authority", "call_remote", "reliable")
func _kicked() -> void:
	session._turned_away = true
	session._hang_up.call_deferred("The host removed you from the game")


## The host stopping the match for everybody at once, GAME.md 3.8, rather than waiting for each
## of them to ask. It holds until the host lets go of it, which closing its menu does.
func force_pause(on: bool) -> void:
	if not session.is_host:
		if granted and session._connected():
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


## At a dedicated server: [param player] has sat down. The first of them has the say.
func seated(player: int) -> void:
	if not session.is_host or not session.dedicated:
		return
	if player not in _order:
		_order.append(player)
	if peer == 0:
		_hand_to(player)


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


func _hand_to(player: int) -> void:
	peer = player
	choosing = false
	_told = ""
	_look_left = 0.0
	if player != 0:
		_granted.rpc_id(player, true)
		_door_is.rpc_id(player, session.door.to_wire())
	changed_hands.emit(player)


## At a dedicated server, the player with the say is told whenever somebody else comes, goes or
## changes, for their Manage players.
func _process(delta: float) -> void:
	if peer == 0 or not session.is_host or not session._connected():
		return
	_look_left -= delta
	if _look_left > 0.0:
		return
	_look_left = GUESTS_EVERY
	var others: Array[Dictionary] = []
	for guest: Dictionary in guests():
		if int(guest["peer"]) != peer:
			others.append(guest)
	var said := str(others)
	if said != _told:
		_told = said
		_guests_are.rpc_id(peer, others)


## Whether the call being answered came from the player with the say, at a dedicated server.
func _from_the_host() -> bool:
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


@rpc("authority", "call_remote", "reliable")
func _granted(on: bool) -> void:
	granted = on
	if not on:
		_guests.clear()
	granted_changed.emit(on)


@rpc("authority", "call_remote", "reliable")
func _guests_are(others: Array) -> void:
	_guests.clear()
	for guest: Variant in others:
		if guest is Dictionary and (guest as Dictionary).has("peer"):
			_guests.append(guest)


@rpc("authority", "call_remote", "reliable")
func _door_is(state: Dictionary) -> void:
	session.door.from_wire(state)
