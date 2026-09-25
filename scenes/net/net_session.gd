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
## Where the host says the waiting room's football is, see [RoomBall].
signal ball_moved(state: Array)
## The host has turned this machine away, and why, for the player to be told, GAME.md 10.3.
signal refused(reason: String)
## The host wants a password this client did not give, or not the one it gave, GAME.md 9.6.
signal locked(wrong: bool)

const DEFAULT_PORT := 7777
## How long the two ends of a new connection have to agree on a version, in seconds. A machine
## that says nothing in that time, or says something the host turns down, is dropped.
const HANDSHAKE_TIMEOUT := 5.0
const SNAPSHOT_EVERY_TICKS := 2
## How long a kicked client has to hear why before the host lets go of it, in seconds.
const KICK_GRACE := 0.5

## Whether this process is in the middle of raising an event a host relayed to it, which is never
## relayed again. Shared by every session in the process: in a test that runs a host and a client
## side by side, both hearing the one [Events], the client raising the host's player_joined was
## the host hearing it again, and the two passed it back and forth a hundred and fifty times a
## second. A game has one session, and a host is never relayed anything, so it changes nothing
## there.
static var _replaying := false

## The match this session is playing, or null while it is between rooms. Let go of the moment the
## match leaves the tree: a session outlives the rooms it is played in, see GAME.md 10.3, and in
## the frames between one room going and the next one taking over, a session still holding the
## old match would be feeding a freed one every input, snapshot and seat that arrived.
var match_node: Match:
	set(value):
		if is_instance_valid(match_node) and match_node.tree_exiting.is_connected(_let_go):
			match_node.tree_exiting.disconnect(_let_go)
		match_node = value
		if value != null and not value.tree_exiting.is_connected(_let_go):
			value.tree_exiting.connect(_let_go)
## The slot this client plays, -1 until the host assigns one.
var local_slot := -1
## The input the client sends; tests may swap it.
var local_input: KartInput = PlayerInput.new(DeviceInput.ANY, 0)
## What this machine's player calls themselves, sent to the host once a seat is assigned. Empty
## leaves the host's funny name standing, GAME.md 3.8.
var player_name := ""
## On a client: whether it came to watch rather than to play, GAME.md 10.3. Said in the handshake,
## and the host never gives it a seat.
var watching := false
## On a client, the password it knocks with, GAME.md 9.6; on the host, the door itself: who may
## come in, its lobby's limit on players and its password among it.
var password := ""
var door := NetDoor.new()
## How this machine's player dressed their kart, GAME.md 4.4, sent to the host with the name.
## Empty leaves the plain kart the host made.
var player_style := PackedInt32Array()
var is_host := false
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

var _tick := 0
var _peer_slots: Dictionary[int, int] = {}
## On the host: whether the room it is in can seat anybody yet. False from the moment it says it
## is going until it has arrived and called [method re_seat], see GAME.md 10.3.
var _room_up := true
## On the host: who has asked for a seat while there was no room to put them in, in the order
## they asked, to be seated as soon as there is.
var _waiting_to_sit: Array[int] = []
## On the host: the color and the name each client had in the room it is leaving, so it can be
## seated in that color and under that name on the other side.
var _kept_of: Dictionary[int, Dictionary] = {}
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
## On the host: whether it has stopped the match for everybody without waiting to be asked.
var _forcing := false
var _peer_asking: Dictionary[int, bool] = {}
## On a client: its own kart, driven here and corrected by the host, GAME.md 10.3.
var _prediction: KartPrediction
## The host's latest word on this client's kart, waiting for the physics step to act on it. An
## RPC lands in the idle frame, and a body moved there is a body moved between physics ticks:
## the engine interpolates the picture from one tick to the next, and a correction applied in
## the gap is drawn as a swerve through somewhere the kart never was. So it waits its turn.
var _authority: Array = []
## On the host: what it has told its clients is lying on the floor, so the next snapshot can
## carry what changed instead of all of it, GAME.md 10.3.
var _floor := PickupWire.new()
## The number this client puts on the next set of controls it sends. Every tick gets one whether
## or not the kart is being driven: a player who is dead and picking a joker, or waiting on the
## grid for the flag, is still pressing buttons the host has to hear, and a host that only ever
## accepts a higher number than the last would throw away everything they pressed.
var _input_seq := 0
var _background := BackgroundRun.new()
## On the host: the lamps of the map it has just arrived at, held for whoever is still building
## the room, GAME.md 10.3. Null once they have gone, and in every room that holds nothing.
var _gate: StartGate
## On a client the host has turned away: the connection going after that is what was asked for,
## not a failure to tell the player about on top of the reason they have already been given.
var _turned_away := false


func _ready() -> void:
	if version.is_empty():
		version = Game.version()
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
	var scene := multiplayer as SceneMultiplayer
	if scene != null:
		scene.auth_callback = _on_handshake
		scene.auth_timeout = HANDSHAKE_TIMEOUT
		scene.peer_authenticating.connect(_on_authenticating)


func _exit_tree() -> void:
	var scene := multiplayer as SceneMultiplayer
	if scene != null and scene.auth_callback == _on_handshake:
		scene.auth_callback = Callable()
	if scene != null and scene.peer_authenticating.is_connected(_on_authenticating):
		scene.peer_authenticating.disconnect(_on_authenticating)
	_background.run(false)
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_background.run(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_background.run(false)


func host(port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, NetDoor.MAX_CLIENTS + NetDoor.MAX_WATCHERS)
	if error != OK:
		return error
	NetLine.compress(peer)
	multiplayer.multiplayer_peer = peer
	is_host = true
	_start_relaying()
	LanBeacon.open(self, port)
	return OK


## Made it to the host: the connection gets its usual patience back, which a moment of a busy
## network should not cost anybody.
func _on_connected() -> void:
	var enet := multiplayer.multiplayer_peer as ENetMultiplayerPeer
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
	multiplayer.multiplayer_peer = peer
	is_host = false
	_turned_away = false
	return OK


## A new connection, before anything else is said on it, GAME.md 10.3. The client opens by
## saying which version it is; the host waits to hear it.
func _on_authenticating(peer: int) -> void:
	if not is_host:
		var words := NetDoor.knock(version, watching, PlayerNames.clean(player_name), password)
		(multiplayer as SceneMultiplayer).send_auth(peer, var_to_bytes(words))


## The other end of the handshake. The host answers every client with its own version and whether
## it can come in, which it can on a version this one plays with and with a seat for it; a client
## turned away is left to run out of [constant HANDSHAKE_TIMEOUT], which drops it, so a client too
## old to understand the answer still goes. A client that is let in lets the host in; one that is
## not says why.
func _on_handshake(peer: int, data: PackedByteArray) -> void:
	var scene := multiplayer as SceneMultiplayer
	var said: Variant = bytes_to_var(data) if not data.is_empty() else null
	var words: Dictionary = said if said is Dictionary else {}
	if is_host:
		# Full is only known while there is a room to be full: between rooms nobody is refused.
		var room := {
			"no_seat": _room_up and match_node != null and not _has_seat(match_node),
			"players": _player_peers().size(),
			"humans": _player_peers().size() + NetDoor.locals(match_node),
			"watchers": _watchers.size(),
			"match": match_node,
		}
		var answer := door.answer(version, peer, words, room)
		scene.send_auth(peer, var_to_bytes(answer))
		if answer["welcome"]:
			if answer["watch"]:
				_watchers[peer] = true
			scene.complete_auth(peer)
		return
	if bool(words.get("welcome", false)):
		scene.complete_auth(peer)
		return
	_turned_away = true
	# After the handshake has returned rather than inside it: hanging up in the middle of the
	# peer's own poll pulls the connection out from under it.
	if NetDoor.wants_password(version, words):
		_hang_up.call_deferred("", str(words["locked"]) == NetDoor.WRONG)
	else:
		_hang_up.call_deferred(NetDoor.refusal(version, words))


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
	_kept_of.clear()
	_watching_here.clear()
	if match_node == null:
		return
	for peer: int in _peer_slots:
		var index: int = _peer_slots[peer]
		if index < match_node.slots.size():
			var slot := match_node.slots[index]
			_kept_of[peer] = {"color": slot.color_index, "name": slot.player_name}


## Where the waiting room's football is, from the host that kicks it to everybody watching it,
## GAME.md 9.6. Sent often and unreliably: a telling that goes missing is overtaken by the next.
func share_ball(state: Array) -> void:
	if is_host and _connected() and not multiplayer.get_peers().is_empty():
		_ball_state.rpc(state)


@rpc("authority", "call_remote", "unreliable_ordered")
func _ball_state(state: Array) -> void:
	ball_moved.emit(state)


## A client that has followed the host into another room asks for its seat there, once the room
## is built and pointed at this session. Asking rather than being told is what makes the change
## safe: a seat and a set of rules sent the moment the host arrived could reach a client that was
## still in the old room, and be applied to a match that is about to be taken down.
func ready_for_seat() -> void:
	if not is_host and _connected():
		_seat_me.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _seat_me() -> void:
	if not is_host:
		return
	var peer := multiplayer.get_remote_sender_id()
	# Between rooms the seats on record are the old room's, and everybody is still in them, so
	# the asking is only queued; it is checked against the seats once there is a room to sit in.
	if not _room_up:
		if peer not in _waiting_to_sit:
			_waiting_to_sit.append(peer)
		return
	if _peer_slots.has(peer) or _watching_here.has(peer):
		return
	_seat(peer, _newcomers.has(peer))
	_settle_pause()


## Seats everybody who is already here in the match this session has just been pointed at.
##
## The rules and the seat are sent once, as a peer arrives, which is all a match that runs from
## beginning to end in one room ever needs. The waiting room and the arena are two matches: a
## client told the first one's rules on the way in knows nothing about the second, and the slot
## it was given belongs to a match that has been taken down. So it is all said again, to the same
## peers, in the order [method peer_seats] lists them, each taking the next seat the new match
## has free for somebody: the seats the waiting room kept for them, see GAME.md 9.6.
func re_seat() -> void:
	if not is_host:
		return
	_peer_slots.clear()
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
			_seat(peer, false)
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
	_gate = StartGate.new(_player_peers(), here)
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
func _seat(peer: int, fresh: bool) -> void:
	if match_node == null:
		return
	if _watchers.has(peer):
		_watch(peer)
		return
	var kept: Dictionary = _kept_of.get(peer, {})
	var slot := match_node.join_network(NetInput.new(), kept.get("color", -1))
	if slot == null:
		if fresh:
			_turn_away(peer)
		return
	# The name it had in the last room, the funny one it was handed there among them, GAME.md 3.8.
	if not str(kept.get("name", "")).is_empty():
		slot.player_name = kept["name"]
	_newcomers.erase(peer)
	_peer_slots[peer] = slot.index
	# Somebody who has just sat down has none of the floor, so the next snapshot carries all of it
	# rather than the difference since a moment they were not here for.
	_floor.start_again()
	# The rules go first. A client arrives with whatever its own lobby was set to, and until it
	# is told otherwise it reads its own clock, its own target score and its own number of lives
	# off them, none of which is the match it has just joined.
	_set_rules.rpc_id(peer, match_node.rules.to_wire())
	_assign_slot.rpc_id(peer, slot.index, match_node.rng.seed)
	# How the run stands, GAME.md 9.7. Everybody else was told at each whistle; somebody who has
	# just sat down in the middle of a Grand Prix, or on its podium, was not there to hear it.
	if Game.grand_prix != null:
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
	if match_node == null or not _has_seat(match_node):
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


## Whether [param in_match] has somewhere for one more player: a bot to take over, or room for
## another kart.
static func _has_seat(in_match: Match) -> bool:
	if PlayerSlot.bot_seat(in_match.slots) != null:
		return true
	return in_match.slots.size() < in_match.rules.max_players


func _turn_away(peer: int) -> void:
	_newcomers.erase(peer)
	multiplayer.multiplayer_peer.disconnect_peer(peer)


## The seats the connected clients hold, in the order [method re_seat] seats them again. The
## waiting room reads it on the way out, to keep each of them a seat in the arena in the color
## they had in the room.
func peer_seats() -> Array[int]:
	var seats: Array[int] = []
	for peer: int in _peer_slots:
		seats.append(_peer_slots[peer])
	return seats


func _physics_process(delta: float) -> void:
	# Ahead of the checks on the connection: a gate with nobody left on the other end of it has
	# nobody to wait for, and opens.
	if is_host:
		_step_gate(delta)
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
			for peer: int in _peer_slots:
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
	elif local_slot >= 0:
		adopt_own_kart()
		_settle_authority(delta)
		local_input.poll(delta)
		# Driven here first and sent second, GAME.md 10.3. The kart answers the stick on this
		# frame; the packet carries the number of the tick it answered, so the host's reply can
		# be held against what this machine thought at the time.
		_step_own_offer()
		_input_seq += 1
		var claim: Array = []
		if _prediction != null and is_instance_valid(_prediction.kart):
			var driving := _drivable()
			if driving != _prediction.kart.predicted:
				# Killed, frozen on the grid or handed back: stop driving and forget the ticks
				# in hand, since nobody will be asking about them. Or the other way round.
				if driving:
					_prediction.resume()
				else:
					_prediction.suspend()
			if driving:
				_prediction.predict(local_input, delta, _input_seq)
				# What this machine made of the tick goes with the controls that made it. The
				# host follows it rather than second-guessing it, GAME.md 10.3, which is what
				# keeps a kart from being corrected for driving perfectly well.
				claim = KartPrediction.capture(_prediction.kart)
		var packet := NetInput.encode(local_input)
		if _prediction != null and is_instance_valid(_prediction.kart):
			# The aim goes out as a direction rather than as whatever the stick happened to read,
			# because a mouse reads nothing at all: the pointer is on this screen and the host
			# has one of its own, GAME.md 10.3.
			packet[NetInput.FIELDS] = KartAim.pointed_flat(_prediction.kart)
		_send_input.rpc_id(1, packet, _input_seq, claim)


func _on_peer_connected(peer: int) -> void:
	if not is_host:
		return
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
	_waiting_to_sit.erase(peer)
	_newcomers.erase(peer)
	_kept_of.erase(peer)
	_watchers.erase(peer)
	_watcher_next.erase(peer)
	door.forget(peer)
	_watching_here.erase(peer)
	if not is_host or not _peer_slots.has(peer):
		return
	var index: int = _peer_slots[peer]
	_peer_slots.erase(peer)
	# Whoever is left may be the whole room now, and they may all be waiting in the menu.
	_peer_asking.erase(peer)
	_settle_pause()
	if match_node == null or index >= match_node.slots.size():
		return
	# In the waiting room the seat is emptied rather than handed to a bot, GAME.md 9.6: a room
	# with no end has no score for one to keep, and the bots come in with the match.
	if match_node.rules.timed:
		match_node.leave_human(match_node.slots[index])
	else:
		VacantSeat.leave(match_node, match_node.slots[index])


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


## The host stopping the match for everybody at once, GAME.md 3.8, rather than waiting for each
## of them to ask. It holds until the host lets go of it, which closing its menu does.
func force_pause(on: bool) -> void:
	if not is_host:
		return
	_forcing = on
	_settle_pause()


## Whether the host is holding the match stopped for everybody.
func forcing_pause() -> bool:
	return _forcing


## The host's count: the match stops when it and every client are asking, or when the host says
## so, and starts again the moment one of them is not.
func _settle_pause() -> void:
	if not is_host:
		return
	var all := _asking
	# Somebody watching has nothing to stop, and is not waited for.
	for peer: int in _player_peers():
		all = all and bool(_peer_asking.get(peer, false))
	all = all or _forcing
	_agree_pause(all)
	if not multiplayer.get_peers().is_empty():
		_settled_pause.rpc(all)


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
func _assign_slot(index: int, _seed: int) -> void:
	if match_node == null:
		return
	local_slot = index
	match_node.set_local_slot(index, local_input)
	# The host made this seat before it could ask who was sitting in it, GAME.md 3.8, so the
	# answer follows the moment the seat is known. An empty one leaves the funny name the host
	# already handed out standing.
	_claim_name.rpc_id(1, PlayerNames.clean(player_name))
	if not player_style.is_empty():
		_claim_style.rpc_id(1, player_style)
	slot_assigned.emit(index)


## What the client at the other end calls itself. The host owns every name in the room, as it
## owns everything else that decides what a player sees, and it reaches the other screens in the
## snapshot like the rest of the roster.
@rpc("any_peer", "call_remote", "reliable")
func _claim_name(claimed: String) -> void:
	if not is_host:
		return
	var peer := multiplayer.get_remote_sender_id()
	if not _peer_slots.has(peer):
		return
	var index: int = _peer_slots[peer]
	var name := PlayerNames.clean(claimed)
	if name.is_empty() or match_node == null or index >= match_node.slots.size():
		return
	match_node.slots[index].player_name = name


## How the client at the other end dressed its kart, GAME.md 4.4. Its own to say, as its name is;
## the host puts it on, and it reaches the other screens in the snapshot.
@rpc("any_peer", "call_remote", "reliable")
func _claim_style(claimed: PackedInt32Array) -> void:
	if not is_host:
		return
	var peer := multiplayer.get_remote_sender_id()
	if not _peer_slots.has(peer) or match_node == null:
		return
	var index: int = _peer_slots[peer]
	if index < match_node.slots.size():
		StyleStalls.dress(match_node.slots[index], claimed)


## This client's player has changed their name or their color in the room, GAME.md 4.4: said to
## the host, which decides, and the snapshot brings the answer back to every screen.
func claim_name(claimed: String) -> void:
	player_name = PlayerNames.clean(claimed)
	if not is_host and _connected() and not player_name.is_empty():
		_claim_name.rpc_id(1, player_name)


func claim_color(color: int) -> void:
	if not is_host and _connected():
		_claim_color.rpc_id(1, color)


## A client asking for another color, which it gets if nobody else in the room is in it.
@rpc("any_peer", "call_remote", "reliable")
func _claim_color(color: int) -> void:
	if not is_host or match_node == null:
		return
	var index: int = _peer_slots.get(multiplayer.get_remote_sender_id(), -1)
	if index >= 0 and index < match_node.slots.size():
		SeatIdentity.paint(match_node, match_node.slots[index], color)


## Everybody else in the host's game, for its Manage players, GAME.md 10.3: each client that plays,
## by the name and color of its seat, and each that watches, by the name it gave.
func guests() -> Array[Dictionary]:
	return door.guests(match_node, _peer_slots, _watchers)


## Shows [param peer] out of the game: told why, and let go of a moment later whatever it does
## with that, so it cannot stay by not listening. It may knock again.
func kick(peer: int) -> void:
	if not is_host or not multiplayer.get_peers().has(peer):
		return
	_kicked.rpc_id(peer)
	get_tree().create_timer(KICK_GRACE).timeout.connect(_let_go_of.bind(peer))


func _let_go_of(peer: int) -> void:
	if multiplayer.multiplayer_peer != null and multiplayer.get_peers().has(peer):
		multiplayer.multiplayer_peer.disconnect_peer(peer)


@rpc("authority", "call_remote", "reliable")
func _kicked() -> void:
	_turned_away = true
	_hang_up.call_deferred("The host removed you from the game")


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


## Takes over the driving of this client's own kart once the snapshot has built it. Called every
## snapshot rather than once, the same as the kart's voice is: which slot is ours arrives in a
## message of its own, and the karts may well have been built before it did.
func adopt_own_kart() -> void:
	if is_host or match_node == null or local_slot < 0 or local_slot >= match_node.slots.size():
		return
	var kart := match_node.slots[local_slot].kart
	if kart == null:
		return
	if _prediction != null and is_instance_valid(_prediction.kart) and _prediction.kart == kart:
		return
	_prediction = KartPrediction.new(kart)


@rpc("authority", "call_remote", "unreliable")
func _receive_snapshot(bytes: PackedByteArray) -> void:
	var data: Variant = bytes_to_var(bytes)
	if data is Dictionary and match_node != null:
		match_node.apply_snapshot(data)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _send_input(state: Array, seq: int = 0, claim: Array = []) -> void:
	var peer := multiplayer.get_remote_sender_id()
	if not _peer_slots.has(peer):
		return
	var index: int = _peer_slots[peer]
	if match_node == null or index >= match_node.slots.size():
		return
	var input := match_node.slots[index].input as NetInput
	if input != null:
		input.receive(state, seq, claim)


## One line about this client's own kart for the debug overlay, empty on a host or before a slot
## has been handed out.
func prediction_debug() -> String:
	if _prediction == null or not is_instance_valid(_prediction.kart):
		return ""
	return _prediction.debug_text()


## The joker pick in front of this player, answered here, GAME.md 10.3. The host is running the
## same pick off the same controls and its answer is the one that counts, but waiting a round
## trip to see the cursor move, and another to see a card taken, is the whole of what made
## picking a joker on a client feel broken. The snapshot leaves this one alone while it is open.
func _step_own_offer() -> void:
	if local_slot < 0 or local_slot >= match_node.slots.size():
		return
	var slot := match_node.slots[local_slot]
	if slot.offer != null and not slot.offer.is_done():
		slot.offer.poll_input(local_input)


## Whether this client is driving its own kart rather than watching it, GAME.md 10.3. A kart the
## host has frozen on the grid, killed or sent rolling out the end of the match is none of this
## machine's business to move, so it goes back to following the snapshot until it is again.
func _drivable() -> bool:
	if _prediction == null or not is_instance_valid(_prediction.kart):
		return false
	return _prediction.kart.alive and match_node.is_running()


## Each client is told what the host made of its own kart, and only its own: everybody else's
## pose is already in the snapshot that went to everybody. The reply carries the whole motor, not
## just a position, because a kart mid-drift is most of what it is about to do.
func _send_authority() -> void:
	for peer: int in _peer_slots:
		var index: int = _peer_slots[peer]
		if index >= match_node.slots.size():
			continue
		var slot := match_node.slots[index]
		var input := slot.input as NetInput
		if input == null or slot.kart == null:
			continue
		# Whether the host drove this kart itself this tick. While it did not, the client's own
		# answer is the one that stands and there is nothing here to put right.
		var host_drove := input.claimed_state().is_empty()
		_receive_authority.rpc_id(
			peer,
			input.applied_seq,
			KartPrediction.capture(slot.kart),
			host_drove,
			slot.kart.cannon.live_count()
		)


## Kept rather than acted on, see [member _authority]. Only the newest is worth anything: an
## older one describes a tick the newer has already answered for.
@rpc("authority", "call_remote", "unreliable")
func _receive_authority(ack: int, state: Array, host_drove := true, live := 0) -> void:
	if _authority.is_empty() or ack >= int(_authority[0]):
		_authority = [ack, state, host_drove, live]


func _settle_authority(delta: float) -> void:
	if _authority.is_empty():
		return
	if _prediction != null and is_instance_valid(_prediction.kart) and _prediction.kart.predicted:
		_prediction.host_live = int(_authority[3])
		if bool(_authority[2]):
			_prediction.reconcile(int(_authority[0]), _authority[1], delta)
		else:
			# The host followed this machine's own answer for that tick, so there is nothing to
			# put right. The history is trimmed and the kart carries on undisturbed, which is
			# most ticks of most matches and the whole point of claiming at all.
			_prediction.accept(int(_authority[0]))
	_authority = []


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
	if name != &"bullet_fired" or _prediction == null or args.is_empty():
		return false
	return int(args[0]) == local_slot and _prediction.kart.predicted


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
