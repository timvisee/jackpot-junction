class_name NetSession
extends Node
## Online play, GAME.md 9.3 and 10.3: a host-authoritative listen server over ENet. The host runs
## the whole match and sends state snapshots; clients send their input every tick, render the
## replicated state through a puppet match, and receive gameplay events for HUD and audio.

signal connected
signal connection_failed
signal disconnected
signal slot_assigned(index: int)
## The host's match settings have been applied, GAME.md 10.3. A client waits for this before it
## builds anything, since the map it plays on is one of them.
signal rules_applied
## The whole room has agreed to stop, or somebody has started playing again. GAME.md 3.8.
signal pause_agreed(on: bool)
## On a client that asked to watch: the host has let it in to watch the room it is in, GAME.md
## 10.3. Said again in every room, as a seat is.
signal watching_started
## The host has left the waiting room of GAME.md 9.6 for the arena, and everybody goes with it.
signal match_beginning
## The match is over and the host is taking everybody back to the waiting room, GAME.md 9.6.
signal back_to_room
## The host has turned this machine away, and why, for the player to be told, GAME.md 10.3.
signal refused(reason: String)
## The host wants a password this client did not give, or not the one it gave, GAME.md 9.6.
signal locked(wrong: bool)
## On a client: the host had no room for another of its players, GAME.md 10.3.
signal seat_refused(seat: int)

const DEFAULT_PORT := 7777
## How long the two ends of a new connection have to agree on a version, in seconds. A machine
## that says nothing in that time, or says something the host turns down, is dropped.
const HANDSHAKE_TIMEOUT := 5.0
const SNAPSHOT_EVERY_TICKS := 2

## Whether this process is in the middle of raising an event a host relayed to it, which is never
## relayed again. Shared by every session in the process: a test running a host and a client side
## by side, both hearing the one [Events], had them passing player_joined back and forth forever.
static var _replaying := false

## The match this session is playing, or null while it is between rooms. Let go of the moment the
## match leaves the tree, see GAME.md 10.3: a session outlives its rooms, and one still holding the
## old match between rooms would be feeding a freed one every input, snapshot and seat that came.
var match_node: Match:
	set(value):
		if is_instance_valid(match_node) and match_node.tree_exiting.is_connected(_let_go):
			match_node.tree_exiting.disconnect(_let_go)
		match_node = value
		if value != null and not value.tree_exiting.is_connected(_let_go):
			value.tree_exiting.connect(_let_go)
## The slot this client's first player plays, -1 until the host assigns one.
var local_slot := -1
## The input the client's first player plays on; tests may swap it.
var local_input: KartInput = PlayerInput.new(DeviceInput.ANY, 0)
## What this machine's first player calls themselves, sent to the host once a seat is assigned.
## Empty leaves the host's funny name standing, GAME.md 3.8.
var player_name := ""
## On a client: whether it came to watch rather than to play, GAME.md 10.3. Said in the handshake,
## and the host never gives it a seat.
var watching := false
## On a client, the password it knocks with, GAME.md 9.6, and the server's at a game of a dedicated
## server, 9.3a; on the host, the door itself: who may come in, its password among it.
var password := ""
var server_password := ""
var door := NetDoor.new()
## How this machine's player dressed their kart, GAME.md 4.4, sent to the host with the name.
## Empty leaves the plain kart the host made.
var player_style := PackedInt32Array()
var is_host := false
## On the host: whether nobody plays at it, GAME.md 9.3a, a game of a dedicated server whose
## players are all at other machines. It never asks for a pause, so it never holds one up, and it
## is found through the server that lists it rather than by asking the network.
var dedicated := false
## On the host: whether the room it is in is an arena rather than the waiting room of GAME.md 9.6,
## which is what a newcomer is shown into, see [method _welcome]. Said by each room as it takes the
## session over.
var in_arena := false
## The version this machine gives when it connects, and on the host the one it holds everybody
## else to, GAME.md 10.3. The game's own unless a test says otherwise.
var version := ""
## Whether the window is in the background right now. A room does not stop for it, see
## [BackgroundRun].
var unfocused: bool:
	get:
		return _background.on
## Whether every machine in the match currently has its pause menu open. One player alone cannot
## stop the others playing, GAME.md 3.8, so this is the agreement rather than what anyone asked.
var paused := false

## On a client: its players, each a seat of its own, the first of them [member local_slot]'s,
## GAME.md 10.3. Made for the first as it is first seated; more as more sit down.
var seats: Array[ClientSeat]:
	get:
		return _here.seats

## How slow the line to each client is, see [NetPing]: made once the session is in the tree.
var ping: NetPing
## The host's say over its game, see [HostControls]: made with the session, since the menus that
## ask it are made for sessions that may not be in the tree.
var host_controls := HostControls.of(self)
## The waiting room's football on the wire, see [BallWire], and the jokers chosen, see [JokerWire].
var ball := BallWire.new()
var jokers := JokerWire.new(self)
## At the host: who has sent what no copy of the game sends, see [NetConduct], and the door before
## anybody is let in, see [NetGuard], made once the session knows its connection.
var conduct := NetConduct.new(self)
var guard: NetGuard

var _tick := 0
## On the host: the seats its clients hold, see [PeerSeats].
var _peer_slots := PeerSeats.new()
var _here := LocalSeats.new()
## On the host: whether the room it is in can seat anybody yet. False from the moment it says it
## is going until it has arrived and called [method re_seat], see GAME.md 10.3.
var _room_up := true
## On the host: who has asked for a seat while there was no room to put them in, in the order
## they asked, to be seated as soon as there is.
var _waiting_to_sit: Array[int] = []
## On the host: the clients that have connected and not yet been seated anywhere. A newcomer the
## match has no room for is turned away; one that has played here before is kept on in case a seat
## comes free.
var _newcomers: Array[int] = []
var _relaying := false
## On the host: the clients that came to watch, GAME.md 10.3, and of them the ones watching the
## room it is in now, which are the ones sent its snapshots.
var _watchers: Dictionary[int, bool] = {}
## On the host: when each watcher may put up their next emote, in engine ticks of milliseconds.
var _watcher_next: Dictionary[int, int] = {}
var _watching_here: Dictionary[int, bool] = {}
## Whether this machine is asking for a pause, and which of the host's clients are.
var _asking := false
var _peer_asking: Dictionary[int, bool] = {}
## On the host: what it has told its clients is lying on the floor, so the next snapshot can
## carry what changed instead of all of it, GAME.md 10.3.
var _floor := PickupWire.new()
var _background := BackgroundRun.new()
## On the host: the lamps of the map it has just arrived at, held for whoever is still building
## the room, GAME.md 10.3. Null once they have gone, and in every room that holds nothing.
var _gate: StartGate
## On a client the host has turned away: the connection going after that is what was asked for,
## not a failure to tell the player about on top of the reason they have already been given.
var _turned_away := false
var _handshake := NetHandshake.of(self)


func _init() -> void:
	add_child(host_controls)
	add_child(ball)
	add_child(jokers)


func _ready() -> void:
	if version.is_empty():
		version = Game.version()
	Events.joker_taken.connect(jokers.took_here)
	jokers.malformed.connect(conduct.heard)
	ball.malformed.connect(conduct.heard)
	ball.claimed.connect(func(peer: int, _state: Array) -> void: conduct.spoke(peer))
	guard = NetGuard.new(multiplayer)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(
		func() -> void:
			if not _turned_away:
				connection_failed.emit()
	)
	multiplayer.server_disconnected.connect(
		func() -> void:
			if not _turned_away:
				disconnected.emit()
	)
	# A client is told how many players the host's room holds, for its own to say when it is full
	# and to know when to stop asking for seats, GAME.md 9.6.
	Events.room_planned.connect(_on_room_planned)
	ping = NetPing.new()
	ping.name = "Ping"
	add_child(ping)
	var scene := multiplayer as SceneMultiplayer
	if scene != null:
		scene.auth_callback = _handshake.answer
		scene.auth_timeout = HANDSHAKE_TIMEOUT
		scene.peer_authenticating.connect(_handshake.knock)
		scene.peer_authenticating.connect(
			func(peer: int) -> void:
				if is_host:
					guard.came(peer)
		)
		scene.peer_authentication_failed.connect(guard.timed_out)


func _exit_tree() -> void:
	var scene := multiplayer as SceneMultiplayer
	if scene != null and scene.auth_callback == _handshake.answer:
		scene.auth_callback = Callable()
	if scene != null and scene.peer_authenticating.is_connected(_handshake.knock):
		scene.peer_authenticating.disconnect(_handshake.knock)
	_background.run(false)
	# Closed now and taken off a frame later, see [NetPeer]: taken off from here, with this node
	# and its children still in the tree, a release build raised an error for each of them.
	NetPeer.let_go(multiplayer, multiplayer.multiplayer_peer)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_background.run(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_background.run(false)


func host(port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, NetDoor.peers(dedicated))
	if error != OK:
		return error
	NetLine.compress(peer)
	# Everything a client hears comes from the host, so at a server, 9.3a, nobody is told about the
	# others coming and going: with two going at once, that telling was an error in its log.
	var scene := multiplayer as SceneMultiplayer
	if dedicated and scene != null:
		scene.server_relay = false
	multiplayer.multiplayer_peer = NetLag.over(peer)
	is_host = true
	_start_relaying()
	if not dedicated:
		LanBeacon.open(self, port)
	return OK


## Made it to the host: the connection gets its usual patience back, which a moment of a busy
## network should not cost anybody.
func _on_connected() -> void:
	var enet := NetLag.enet(multiplayer.multiplayer_peer)
	var server := enet.get_peer(1) if enet != null else null
	if server != null:
		NetLine.made(server)
	connected.emit()


func join(address: String, port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error != OK:
		return error
	NetLine.compress(peer)
	var server := peer.get_peer(1)
	if server != null:
		NetLine.trying(server)
	multiplayer.multiplayer_peer = NetLag.over(peer)
	is_host = false
	_turned_away = false
	return OK


func _on_room_planned(_bots: int, most: int) -> void:
	if not is_host:
		door.max_players = most


## Closes the connection and says why: [param reason], or the password it wants, [param wrong] if
## this one gave one it was not.
func _hang_up(reason: String, wrong := false) -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	if reason.is_empty():
		locked.emit(wrong)
	else:
		refused.emit(reason)


## Everybody in the waiting room is ready and the host is going through to the arena, GAME.md
## 9.6. Says so to everybody who is here, so the rooms change together rather than leaving a
## client driving round a lobby the host has already left.
func begin_the_match() -> void:
	if is_host and _connected():
		_leaving()
		_match_beginning.rpc()


@rpc("authority", "call_remote", "reliable")
func _match_beginning() -> void:
	match_beginning.emit()


## The match is over and the host is taking everybody back to the waiting room, GAME.md 9.6. Said
## before the host goes, the same as going the other way.
func back_to_the_room() -> void:
	if is_host and _connected():
		_leaving()
		_back_to_room.rpc()


@rpc("authority", "call_remote", "reliable")
func _back_to_room() -> void:
	back_to_room.emit()


## The match has left the tree, with the room it was in. Held again when the next room attaches.
func _let_go() -> void:
	match_node = null
	_gate = null


## The host is about to change room. Nobody can be seated until it has arrived, and it notes the
## color everybody is in so they get it back there.
func _leaving() -> void:
	_room_up = false
	_watching_here.clear()
	_peer_slots.keep_room(match_node)


## A client that has followed the host into another room asks for its seat there, once the room
## is built and pointed at this session: a seat and rules sent the moment the host arrived could
## reach a client still in the old room, and be applied to a match about to be taken down.
func ready_for_seat() -> void:
	if not is_host and _connected():
		var numbers: Array[int] = []
		for each: ClientSeat in _players():
			each.forget_room()
			numbers.append(each.seat)
		_seat_me.rpc_id(1, numbers)


## Asked for every player at this client, by its numbers for them: the first, and anybody who sat
## down beside them, GAME.md 10.3.
@rpc("any_peer", "call_remote", "reliable")
func _seat_me(numbers: Array = [0]) -> void:
	if not is_host:
		return
	var peer := multiplayer.get_remote_sender_id()
	_peer_slots.ask(peer, numbers)
	# Between rooms the seats on record are the old room's, and everybody is still in them, so
	# the asking is only queued; it is checked against the seats once there is a room to sit in.
	if not _room_up:
		if peer not in _waiting_to_sit:
			_waiting_to_sit.append(peer)
		return
	if _peer_slots.has(peer) or _watching_here.has(peer):
		return
	_seat_all(peer, _newcomers.has(peer))
	_settle_pause()


## Seats every player [param peer] asked for, the first as a newcomer when [param fresh].
func _seat_all(peer: int, fresh: bool) -> void:
	var numbers: Array = _peer_slots.asked_of(peer)
	for i: int in numbers.size():
		_seat(peer, fresh and i == 0, int(numbers[i]))


## Another player at a client sits down, GAME.md 10.3: seated if the game has room for them, and
## told it has not otherwise, the way somebody at the host's own machine is, see [SeatLimit].
@rpc("any_peer", "call_remote", "reliable")
func _seat_another(number: int) -> void:
	if not is_host:
		return
	var peer := multiplayer.get_remote_sender_id()
	if not _peer_slots.may_add(peer, number) or match_node == null or not _room_up:
		_seat_refused.rpc_id(peer, number)
		return
	if _peer_slots.slot_of(peer, number) >= 0:
		return
	if SeatLimit.full(match_node, self):
		_seat_refused.rpc_id(peer, number)
		return
	_peer_slots.ask_one_more(peer, number)
	_seat(peer, false, number)


## Seats everybody who is already here in the match this session has just been pointed at.
##
## The rules and the seat are sent once, as a peer arrives. The waiting room and the arena are two
## matches, and a client told the first one's rules knows nothing of the second, so it is all said
## again, to the same peers in the order [method peer_seats] lists them, each taking the next seat
## the new match has free: the seats the waiting room kept for them, see GAME.md 9.6.
func re_seat() -> void:
	if not is_host:
		return
	_peer_slots.held.clear()
	_room_up = true
	# Nobody has any of the new floor, so the next snapshot carries all of it.
	_floor.start_again()
	var connected := _peers()
	var waiting := _waiting_to_sit.duplicate()
	_waiting_to_sit.clear()
	for peer: int in waiting:
		if peer not in connected:
			continue
		if peer in _newcomers:
			_welcome(peer)
		else:
			_seat_all(peer, false)
	_settle_pause()


## Holds the countdown of the map the host has just arrived at until every client has the room up
## as well, or until [constant StartGate.DEADLINE] runs out, GAME.md 10.3. For a match started
## held on the grid, see [member Match.hold_start]; the lamps go when the gate opens.
func hold_the_start() -> void:
	if not is_host or match_node == null:
		return
	var here := 0
	for slot: PlayerSlot in match_node.slots:
		if slot.is_local_human():
			here += 1
	# Held for the players on their way in, not for somebody who is only watching.
	_gate = StartGate.new(_player_peers(), here, _peer_slots)
	_step_gate(0.0)


## A client has its copy of the room up and is ready for the lamps, GAME.md 10.3. The host only
## counts it while it is holding them; a client arriving in the middle of a match says it too.
func room_built() -> void:
	if not is_host and _connected():
		_room_built.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _room_built() -> void:
	if is_host and _gate != null:
		_gate.arrived(multiplayer.get_remote_sender_id())


## Where the gate is, for every screen to show, and the lamps once it opens.
func _step_gate(delta: float) -> void:
	if _gate == null or match_node == null:
		return
	var done := _gate.step(delta, _player_peers())
	match_node.loading = Vector2i.ZERO if done else _gate.count()
	if done:
		_gate = null
		match_node.begin_from_lobby()


## The clients connected just now, or nobody when there is no connection left to have any.
func _peers() -> PackedInt32Array:
	return multiplayer.get_peers() if _connected() else PackedInt32Array()


## Whether anybody is connected, to play or to watch: who a host leaving would disconnect.
func anybody_connected() -> bool:
	return not _peers().is_empty()


## The clients connected to play, leaving out anybody who came to watch, GAME.md 10.3.
func _player_peers() -> PackedInt32Array:
	var players := PackedInt32Array()
	for peer: int in _peers():
		if not _watchers.has(peer):
			players.append(peer)
	return players


## Gives [param peer] a seat in the match this session is pointed at, in the color it had in the
## room before if it had one, and tells it the rules and the seat. A newcomer the match has no
## room for is turned away; somebody coming back from another room is left connected, in case a
## seat comes free.
func _seat(peer: int, fresh: bool, number := 0) -> void:
	if match_node == null:
		return
	if _watchers.has(peer):
		_watch(peer)
		return
	var seated := _peer_slots.seated_in(match_node, peer, number)
	if seated >= 0:
		_assign_slot.rpc_id(peer, seated, match_node.rng.seed, number)
		return
	var kept := _peer_slots.kept_for(peer, number)
	var slot := match_node.join_network(NetInput.new(), kept.get("color", -1))
	if slot == null:
		if fresh:
			_turn_away(peer)
		elif number != 0:
			_seat_refused.rpc_id(peer, number)
		return
	# The name it had in the last room, the funny one it was handed there among them, GAME.md 3.8.
	if not str(kept.get("name", "")).is_empty():
		slot.player_name = kept["name"]
	_newcomers.erase(peer)
	var first := _peer_slots.put(peer, number, slot.index)
	host_controls.seated(peer)
	# Somebody who has just sat down has none of the floor, so the next snapshot carries all of it
	# rather than the difference since a moment they were not here for.
	_floor.start_again()
	# The rules go first. A client arrives with whatever its own lobby was set to, and until it
	# is told otherwise it reads its own clock, its own target score and its own number of lives
	# off them, none of which is the match it has just joined.
	if first:
		_set_rules.rpc_id(peer, match_node.rules.to_wire())
	_assign_slot.rpc_id(peer, slot.index, match_node.rng.seed, number)
	# How the run stands, GAME.md 9.7. Everybody else was told at each whistle; somebody who has
	# just sat down in the middle of a Grand Prix, or on its podium, was not there to hear it.
	if first and Game.grand_prix != null:
		_relay_event.rpc_id(peer, &"grand_prix_scored", [Game.grand_prix.to_wire()])


## A newcomer, into whichever room the host is in, GAME.md 10.3. Joining always opens the waiting
## room, so a host there seats it on the spot. Anywhere else it is given the word everybody else
## was given on their way in, follows it the same way, and is seated once it asks from the other
## side. A match with no seat for it turns it away now rather than after it has built the room.
func _welcome(peer: int) -> void:
	if _watchers.has(peer):
		_newcomers.erase(peer)
		if not in_arena:
			_watch(peer)
		else:
			_match_beginning.rpc_id(peer)
		return
	if not in_arena:
		_seat(peer, true)
		return
	if match_node == null or not SeatLimit.has_seat(match_node):
		_turn_away(peer)
		return
	_match_beginning.rpc_id(peer)


## Lets [param peer], come to watch, watch the room this session is pointed at, GAME.md 10.3: the
## rules and the run as a player is told them, and from now on the snapshots, with no seat and
## nothing it sends heard.
func _watch(peer: int) -> void:
	if match_node == null:
		return
	_watching_here[peer] = true
	_floor.start_again()
	_set_rules.rpc_id(peer, match_node.rules.to_wire())
	_start_watching.rpc_id(peer)
	if Game.grand_prix != null:
		_relay_event.rpc_id(peer, &"grand_prix_scored", [Game.grand_prix.to_wire()])


@rpc("authority", "call_remote", "reliable")
func _start_watching() -> void:
	watching_started.emit()


func _turn_away(peer: int) -> void:
	_newcomers.erase(peer)
	multiplayer.multiplayer_peer.disconnect_peer(peer)


## The seats the connected clients hold, in the order [method re_seat] seats them again. The
## waiting room reads it on the way out, to keep each of them a seat in the arena in the color
## they had in the room.
func peer_seats() -> Array[int]:
	return _peer_slots.all_slots()


func _physics_process(delta: float) -> void:
	# Ahead of the checks on the connection: a gate with nobody left on the other end of it has
	# nobody to wait for, and opens.
	if is_host:
		_step_gate(delta)
		guard.watch(delta)
	if match_node == null or multiplayer.multiplayer_peer == null:
		return
	if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	if is_host:
		_tick += 1
		var audience := not (_peer_slots.is_empty() and _watching_here.is_empty())
		if _tick % SNAPSHOT_EVERY_TICKS == 0 and audience:
			# To the seated only, and whoever is watching this room. A client still on its way in
			# from another room would draw this match in that one: the arena's karts driving round
			# the waiting room.
			var bytes := var_to_bytes(match_node.build_snapshot(_floor))
			for peer: int in _peer_slots.peers():
				_receive_snapshot.rpc_id(peer, bytes)
			for peer: int in _watching_here:
				_receive_snapshot.rpc_id(peer, bytes)
			_send_authority()
	elif watching:
		# Somebody watching has no kart, but has emotes, GAME.md 3.8: asked of the host, which puts
		# them up on every screen.
		local_input.poll(delta)
		if local_input.emote >= 0:
			_watcher_emote.rpc_id(1, local_input.emote, player_name)
	else:
		# Every player here, each driven here first and sent second, GAME.md 10.3. The kart
		# answers the stick on this frame; the packet carries the number of the tick it answered,
		# so the host's reply can be held against what this machine thought at the time.
		for each: ClientSeat in seats:
			if each.slot < 0:
				continue
			each.adopt(match_node)
			each.settle(delta)
			var sent := each.step(match_node, delta)
			_send_input.rpc_id(1, sent[0], sent[1], sent[2], each.seat)
			jokers.tell(each)


func _on_peer_connected(peer: int) -> void:
	if not is_host:
		return
	guard.settled(peer)
	var enet := NetLag.enet(multiplayer.multiplayer_peer)
	if enet != null and enet.get_peer(peer) != null:
		NetLine.made(enet.get_peer(peer))
	_newcomers.append(peer)
	# Arriving while the host is between rooms: shown into the one it is going to, once it is up.
	if not _room_up:
		_waiting_to_sit.append(peer)
		return
	_welcome(peer)
	# Somebody who has only just sat down is not asking for a pause, so a room that was stopped
	# starts playing again.
	_settle_pause()


func _on_peer_disconnected(peer: int) -> void:
	conduct.forget(peer)
	guard.settled(peer)
	_waiting_to_sit.erase(peer)
	_newcomers.erase(peer)
	_peer_slots.kept.erase(peer)
	_watchers.erase(peer)
	_watcher_next.erase(peer)
	door.forget(peer)
	_watching_here.erase(peer)
	host_controls.left(peer)
	if not is_host or not _peer_slots.has(peer):
		return
	var held := _peer_slots.take_all(peer)
	# Whoever is left may be the whole room now, and they may all be waiting in the menu.
	_peer_asking.erase(peer)
	_settle_pause()
	for number: int in held:
		PeerSeats.vacate(match_node, held[number])


## One of [param peer]'s players gets up and goes, and the rest of them stay.
func _empty_seat(peer: int, number: int) -> void:
	PeerSeats.vacate(match_node, _peer_slots.take(peer, number))


## A player at a client has left from their switch in the pause menu, GAME.md 10.3.
@rpc("any_peer", "call_remote", "reliable")
func _leave_seat(number: int) -> void:
	if is_host:
		_empty_seat(multiplayer.get_remote_sender_id(), number)


## Says whether this machine wants the match stopped. The host adds up the answers; online the
## match only stops once every machine has said yes, GAME.md 3.8.
func want_pause(wanted: bool) -> void:
	_asking = wanted
	if is_host:
		_settle_pause()
	elif _connected():
		_ask_pause.rpc_id(1, wanted)
	else:
		# No host to ask yet, and nobody else here either, so this machine is the whole room.
		_agree_pause(wanted)


## The host's count: the match stops when it and every client are asking, or when the host says
## so, and starts again the moment one of them is not.
func _settle_pause() -> void:
	if not is_host:
		return
	# A host nobody plays at has no menu to ask with, and leaves it to the players.
	var all := _asking or dedicated
	# Somebody watching has nothing to stop, and is not waited for.
	for peer: int in _player_peers():
		all = all and bool(_peer_asking.get(peer, false))
	all = all or host_controls.forcing
	_agree_pause(all)
	if not multiplayer.get_peers().is_empty():
		_settled_pause.rpc(all)


## At the host, in a call from a client: the slot that client plays as its seat [param number], or
## null for one it does not.
func sender_slot(number: int) -> PlayerSlot:
	if not is_host or match_node == null:
		return null
	var index := _peer_slots.slot_of(multiplayer.get_remote_sender_id(), number)
	return match_node.slots[index] if index >= 0 and index < match_node.slots.size() else null


func _connected() -> bool:
	var peer := multiplayer.multiplayer_peer
	return peer != null and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func _agree_pause(on: bool) -> void:
	if paused == on:
		return
	paused = on
	pause_agreed.emit(on)


@rpc("any_peer", "call_remote", "reliable")
func _ask_pause(wanted: bool) -> void:
	if not is_host:
		return
	_peer_asking[multiplayer.get_remote_sender_id()] = wanted
	_settle_pause()


@rpc("authority", "call_remote", "reliable")
func _settled_pause(on: bool) -> void:
	_agree_pause(on)


## The host's match numbers, GAME.md 10.3. Applied in place: a client's rules are its own copy,
## made by [method MatchConfig.rules], and the arena and the karts are already holding it.
@rpc("authority", "call_remote", "reliable")
func _set_rules(data: Dictionary) -> void:
	if match_node != null and match_node.rules != null:
		match_node.rules.from_wire(data)
	rules_applied.emit()


@rpc("authority", "call_remote", "reliable")
func _assign_slot(index: int, _seed: int, number := 0) -> void:
	if match_node == null:
		return
	var each := _here.numbered(number)
	if each == null:
		if number != 0:
			return
		each = _players()[0]
	# Moved, a seat is no longer played in the slot it had.
	if each.slot >= 0 and each.slot != index:
		match_node.drop_local_seat(each.slot)
	each.slot = index
	if each == seats[0]:
		local_slot = index
		match_node.set_local_slot(index, each.input)
	else:
		match_node.add_local_seat(index, each.input as PlayerInput)
	# Who is sitting in it, the moment the seat is known, see [SeatClaims]; and from when.
	SeatClaims.say(self, each, number)
	if index < match_node.slots.size():
		MatchRecord.seat_taken(match_node, match_node.slots[index])
	slot_assigned.emit(index)


## What the client at the other end calls itself. The host owns every name in the room, as it
## owns everything else that decides what a player sees, and it reaches the other screens in the
## snapshot like the rest of the roster.
@rpc("any_peer", "call_remote", "reliable")
func _claim_name(claimed: String, number := 0) -> void:
	if not is_host:
		return
	var index := _peer_slots.slot_of(multiplayer.get_remote_sender_id(), number)
	var name := PlayerNames.clean(claimed)
	if name.is_empty() or match_node == null or index >= match_node.slots.size():
		return
	if index < 0:
		return
	match_node.slots[index].player_name = name


## How the client at the other end dressed its kart, GAME.md 4.4. Its own to say, as its name is;
## the host puts it on, and it reaches the other screens in the snapshot.
@rpc("any_peer", "call_remote", "reliable")
func _claim_style(claimed: PackedInt32Array, number := 0) -> void:
	if not is_host or match_node == null:
		return
	var index := _peer_slots.slot_of(multiplayer.get_remote_sender_id(), number)
	if index >= 0 and index < match_node.slots.size():
		StyleStalls.dress(match_node.slots[index], claimed)


## The plate on the back of the client's kart, GAME.md 4.4, its own to say as its dress is: the
## host puts it on, cleaned, and it reaches the other screens in the snapshot, 10.3.
@rpc("any_peer", "call_remote", "reliable")
func _claim_plate(claimed: String, number := 0) -> void:
	if not is_host or match_node == null:
		return
	var index := _peer_slots.slot_of(multiplayer.get_remote_sender_id(), number)
	if index < 0 or index >= match_node.slots.size() or match_node.slots[index].kart == null:
		return
	var body := match_node.slots[index].kart.get_node_or_null("Body") as Node3D
	KartVisuals.plate_like(body, LicensePlate.valid(claimed))


## A player at this client has changed their name or their color in the room, GAME.md 4.4, the
## one in [param index] or the first: said to the host, which decides, and the snapshot brings the
## answer back to every screen.
func claim_name(claimed: String, index := -1) -> void:
	var each := _here.at(index)
	if each == null:
		each = _players()[0]
	each.player_name = PlayerNames.clean(claimed)
	if each == seats[0]:
		player_name = each.player_name
	if not is_host and _connected() and not each.player_name.is_empty():
		_claim_name.rpc_id(1, each.player_name, each.seat)


func claim_color(color: int, index := -1) -> void:
	var each := _here.at(index)
	if each == null:
		each = _players()[0]
	if not is_host and _connected():
		_claim_color.rpc_id(1, color, each.seat)


## A client asking for another color, which it gets if nobody else in the room is in it.
@rpc("any_peer", "call_remote", "reliable")
func _claim_color(color: int, number := 0) -> void:
	if not is_host or match_node == null:
		return
	var index := _peer_slots.slot_of(multiplayer.get_remote_sender_id(), number)
	if index >= 0 and index < match_node.slots.size():
		SeatIdentity.paint(match_node, match_node.slots[index], color)


## An emote from somebody watching, put up on every screen as the karts' are, at most as often.
@rpc("any_peer", "call_remote", "reliable")
func _watcher_emote(emote: int, watcher: String) -> void:
	var peer := multiplayer.get_remote_sender_id()
	if not is_host or not _watchers.has(peer) or emote < 0 or emote >= EmoteArt.EMOTES.size():
		return
	var now := Time.get_ticks_msec()
	if now < _watcher_next.get(peer, 0):
		return
	_watcher_next[peer] = now + roundi(Emotes.COOLDOWN * 1000.0)
	# Under the name the host gave them, which is theirs to be seen by, not what they sent.
	var named: String = door.names.get(peer, PlayerNames.clean(watcher))
	Events.watcher_emoted.emit(named if not named.is_empty() else "Watcher", emote)


## This client's players, the first made for it from [member local_input], [member player_name]
## and [member player_style] the first time it is asked for.
func _players() -> Array[ClientSeat]:
	return _here.here(local_input, player_name, player_style)


## The player at this client in [param index], or null for a seat played elsewhere.
func seat_at(index: int) -> ClientSeat:
	return _here.at(index)


## Another player at this client sits down on [param device], GAME.md 10.3, the way somebody at
## the host does: asked of the host, which seats them if the game has room and says it has not
## otherwise, see [method LocalSeats.sit_down].
func add_seat(device: int) -> void:
	if is_host or watching or not _connected():
		return
	_players()
	var made := _here.sit_down(device)
	if made != null:
		_seat_another.rpc_id(1, made.seat)


## One of this client's players gets up and goes, from their switch in the pause menu, GAME.md
## 10.3: their seat is the host's to empty, and they go from this machine at once.
func leave_seat(index: int) -> void:
	var each := _here.at(index)
	if each == null or is_host:
		return
	if _connected():
		_leave_seat.rpc_id(1, each.seat)
	_drop_here(each)


## Takes [param each] off this machine: its seat is somebody else's now, or nobody's. If it was the
## first, whoever sat down after it is the first now.
func _drop_here(each: ClientSeat) -> void:
	_here.stand_up(each, match_node)
	if seats.is_empty() or each.slot != local_slot:
		return
	var first := seats[0]
	local_slot = first.slot
	local_input = first.input
	player_name = first.player_name
	player_style = first.style
	if match_node != null and first.slot >= 0:
		match_node.set_local_slot(first.slot, first.input)


## On a client: the host had no room for the player it asked it to seat.
@rpc("authority", "call_remote", "reliable")
func _seat_refused(number: int) -> void:
	var each := _here.numbered(number)
	if each != null and each.slot < 0:
		seats.erase(each)
	seat_refused.emit(number)


## On a client: the host has shown one of its several players out, GAME.md 10.3.
@rpc("authority", "call_remote", "reliable")
func _seat_dropped(number: int) -> void:
	var each := _here.numbered(number)
	if each != null:
		_drop_here(each)


@rpc("authority", "call_remote", "unreliable_ordered")
func _receive_snapshot(bytes: PackedByteArray) -> void:
	var data: Variant = bytes_to_var(bytes)
	if data is Dictionary and match_node != null:
		match_node.apply_snapshot(data)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _send_input(
	state: Variant, seq: Variant = 0, claim: Variant = [], number: Variant = 0
) -> void:
	var peer := multiplayer.get_remote_sender_id()
	conduct.spoke(peer)
	if not (state is Array and seq is int and claim is Array and number is int):
		conduct.heard(peer)
		return
	var index := _peer_slots.slot_of(peer, number)
	if match_node == null or index < 0 or index >= match_node.slots.size():
		return
	var input := match_node.slots[index].input as NetInput
	if input != null and not input.receive(state, seq, claim):
		conduct.heard(peer)


## One line about this client's first player's kart for the debug overlay, empty on a host or
## before a slot has been handed out.
func prediction_debug() -> String:
	return seats[0].debug_text() if not seats.is_empty() else ""


## Each client is told what the host made of its own kart, and only its own: everybody else's
## pose is already in the snapshot that went to everybody. The reply carries the whole motor, not
## just a position, because a kart mid-drift is most of what it is about to do.
func _send_authority() -> void:
	for peer: int in _peer_slots.held:
		for number: int in _peer_slots.held[peer]:
			var index: int = _peer_slots.held[peer][number]
			if index >= match_node.slots.size():
				continue
			var slot := match_node.slots[index]
			var input := slot.input as NetInput
			if input == null or slot.kart == null:
				continue
			# Whether the host drove this kart itself this tick. While it did not, the client's
			# own answer is the one that stands and there is nothing here to put right.
			var host_drove := input.claimed_state().is_empty()
			_receive_authority.rpc_id(
				peer, input.applied_seq, KartPrediction.capture(slot.kart), host_drove, number
			)


## Kept for the physics step rather than acted on, see [method ClientSeat.hold]. An RPC lands in
## the idle frame, and a body moved there is a body moved between physics ticks: the engine
## interpolates the picture from one tick to the next, and a correction applied in the gap is
## drawn as a swerve through somewhere the kart never was. So it waits its turn.
@rpc("authority", "call_remote", "unreliable")
func _receive_authority(ack: int, state: Array, host_drove := true, number := 0) -> void:
	var each := _here.numbered(number)
	if each != null:
		each.hold(ack, state, host_drove)


@rpc("authority", "call_remote", "reliable")
func _relay_event(name: StringName, args: Array) -> void:
	if _already_heard(name, args):
		return
	_replaying = true
	Events.callv("emit_signal", [name] + args)
	_replaying = false


## Whether this machine already raised this for itself. A client pulls its own trigger on the tick
## the button goes down, GAME.md 10.3, so the host's word for that same shot, arriving a round trip
## later, would be the same shot heard twice.
func _already_heard(name: StringName, args: Array) -> bool:
	if args.is_empty():
		return false
	if name == &"bullet_fired":
		for each: ClientSeat in seats:
			if each.fired_first(int(args[0])):
				return true
	if name == &"joker_taken" and args.size() >= 2:
		return jokers.heard_already(int(args[0]), StringName(args[1]))
	return false


## The host forwards gameplay events so clients' HUD and audio react like the host's.
func _start_relaying() -> void:
	if _relaying:
		return
	_relaying = true
	for name: StringName in NetEvents.RELAYED:
		Events.connect(name, _relay_any.bind(name))


func _relay(name: StringName, args: Array) -> void:
	if _replaying or not _connected():
		return
	if not multiplayer.get_peers().is_empty():
		_relay_event.rpc(name, args)


## Whatever [Events] signal it is, with however many arguments: the name comes last, bound.
func _relay_any(...raised: Array) -> void:
	var name: StringName = raised.pop_back()
	_relay(name, raised)
