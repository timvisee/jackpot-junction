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

const DEFAULT_PORT := 7777
## What an unfocused window runs at while this machine is in an online room, GAME.md 9.3. Fast
## enough that nobody can tell, slow enough that a game nobody is looking at is not spinning a
## graphics card flat out.
const UNFOCUSED_FPS := 60
const MAX_CLIENTS := 3
const SNAPSHOT_EVERY_TICKS := 2
const RELAYED_EVENTS: Array[StringName] = [
	&"coin_collected",
	&"mult_gained",
	&"grazed",
	&"kart_killed",
	&"kart_respawned",
	&"death_banked",
	&"bank_started",
	&"bank_tick",
	&"bank_completed",
	&"jackpot_collected",
	&"jackpot_full",
	&"jackpot_emptied",
	&"item_picked",
	&"item_used",
	&"joker_offered",
	&"joker_taken",
	&"match_state_changed",
	&"bullet_fired",
	&"bullet_bounced",
	&"bullet_struck",
	&"kart_bumped",
	&"turbo_taken",
	&"nitro_gained",
	&"pad_claimed",
	&"flush_completed",
	&"bounty_called",
	&"bounty_claimed",
	&"bounty_lapsed",
	&"kart_wounded",
	&"life_restored",
	&"crate_destroyed",
	&"target_struck",
	&"shield_popped",
	&"bomb_exploded",
	&"oil_hit",
	&"player_joined",
	&"player_left",
	&"countdown_tick",
	&"countdown_done",
	&"kart_crashed",
	&"kart_fell",
	&"nitro_started",
	&"drift_boosted",
]
## The events that stay on the machine that raised them. Between this and [constant
## RELAYED_EVENTS] every signal [Events] has is accounted for, and a test says so, so a new one
## has to be put in one list or the other rather than quietly never reaching a client.
##
## [code]announced[/code] is made on each machine by its own announcer, out of the events above,
## so relaying it would say everything twice. [code]wild_joker_dropped[/code] has nothing
## listening to it on any machine; the card it names arrives as a pickup like any other.
## [code]kart_corrected[/code] is about this machine's own guess being put right, which is news
## to nobody else: their picture of that kart never changed.
const LOCAL_EVENTS: Array[StringName] = [
	&"announced",
	&"wild_joker_dropped",
	&"kart_corrected",
]

var match_node: Match
## The slot this client plays, -1 until the host assigns one.
var local_slot := -1
## The input the client sends; tests may swap it.
var local_input: KartInput = PlayerInput.new()
## What this machine's player calls themselves, sent to the host once a seat is assigned. Empty
## leaves the host's funny name standing, GAME.md 3.8.
var player_name := ""
var is_host := false
## Whether the window is in the background right now. A room does not stop for it, see
## [method _run_unfocused].
var unfocused := false
## Whether every machine in the match currently has its pause menu open. One player alone cannot
## stop the others playing, GAME.md 3.8, so this is the agreement rather than what anyone asked.
var paused := false

var _tick := 0
var _peer_slots: Dictionary[int, int] = {}
var _relaying := false
## Whether this machine is asking for a pause, and which of the host's clients are.
var _asking := false
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
## What the window was set to before it went into the background, so it can be put back. -1
## while the window has the focus and nothing has been taken over.
var _focused_vsync := -1
var _focused_max_fps := 0


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(func() -> void: connected.emit())
	multiplayer.connection_failed.connect(func() -> void: connection_failed.emit())
	multiplayer.server_disconnected.connect(func() -> void: disconnected.emit())


func _exit_tree() -> void:
	_run_unfocused(false)
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_run_unfocused(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_run_unfocused(false)


## Keeps the match running while somebody has alt-tabbed away from it, GAME.md 9.3.
##
## A window the desktop has stopped putting on screen can block the frame it is waiting to
## present for a long time, and everything else waits behind it: physics, the wire, the lot. On
## the host that stops the whole room, and every client sits looking at a frozen arena until
## somebody clicks back. So a window in the background stops waiting for the desktop and runs
## free at a fixed rate instead, and is given back whatever it had the moment it returns.
func _run_unfocused(on: bool) -> void:
	if on == unfocused:
		return
	unfocused = on
	if DisplayServer.get_name() == "headless":
		return
	if on:
		_focused_vsync = DisplayServer.window_get_vsync_mode()
		_focused_max_fps = Engine.max_fps
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = UNFOCUSED_FPS
		return
	if _focused_vsync >= 0:
		DisplayServer.window_set_vsync_mode(_focused_vsync)
		Engine.max_fps = _focused_max_fps
		_focused_vsync = -1


func host(port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, MAX_CLIENTS)
	if error != OK:
		return error
	_compress(peer)
	multiplayer.multiplayer_peer = peer
	is_host = true
	_start_relaying()
	return OK


func join(address: String, port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error != OK:
		return error
	_compress(peer)
	multiplayer.multiplayer_peer = peer
	is_host = false
	return OK


## Snapshots are mostly the same words over and over, GAME.md 10.3: every dictionary key of
## every kart, bullet and pickup, thirty times a second. A busy one runs to about fourteen
## kilobytes written out and a tenth of that packed, so it is worth packing.
##
## This does not stop a big snapshot being broken up: the packet is split against the MTU before
## the datagrams carrying it are compressed, which is what the engine warns about. Fitting one
## in a single datagram means a smaller snapshot, not a smaller wire. Both ends have to agree on
## the compressor, so both are set from here.
static func _compress(peer: ENetMultiplayerPeer) -> void:
	peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)


func _physics_process(delta: float) -> void:
	if match_node == null or multiplayer.multiplayer_peer == null:
		return
	if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	if is_host:
		_tick += 1
		if _tick % SNAPSHOT_EVERY_TICKS == 0 and not multiplayer.get_peers().is_empty():
			_receive_snapshot.rpc(var_to_bytes(match_node.build_snapshot(_floor)))
			_send_authority()
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
	var slot := match_node.join_network(NetInput.new())
	if slot == null:
		multiplayer.multiplayer_peer.disconnect_peer(peer)
		return
	_peer_slots[peer] = slot.index
	# Somebody who has just arrived has none of the floor, so the next snapshot carries all of it
	# rather than the difference since a moment they were not here for.
	_floor.start_again()
	# The rules go first. A client arrives with whatever its own lobby was set to, and until it
	# is told otherwise it reads its own clock, its own target score and its own number of lives
	# off them, none of which is the match it has just joined.
	_set_rules.rpc_id(peer, match_node.rules.to_wire())
	_assign_slot.rpc_id(peer, slot.index, match_node.rng.seed)
	# Somebody who has only just sat down is not asking for a pause, so a room that was stopped
	# starts playing again.
	_settle_pause()


func _on_peer_disconnected(peer: int) -> void:
	if not is_host or not _peer_slots.has(peer):
		return
	var index: int = _peer_slots[peer]
	_peer_slots.erase(peer)
	# Whoever is left may be the whole room now, and they may all be waiting in the menu.
	_peer_asking.erase(peer)
	_settle_pause()
	if index < match_node.slots.size():
		match_node.leave_human(match_node.slots[index])


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


## The host's count: the match stops when it and every client are asking, and starts again the
## moment one of them is not.
func _settle_pause() -> void:
	if not is_host:
		return
	var all := _asking
	for peer: int in multiplayer.get_peers():
		all = all and bool(_peer_asking.get(peer, false))
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
	local_slot = index
	match_node.set_local_slot(index, local_input)
	# The host made this seat before it could ask who was sitting in it, GAME.md 3.8, so the
	# answer follows the moment the seat is known. An empty one leaves the funny name the host
	# already handed out standing.
	_claim_name.rpc_id(1, PlayerNames.clean(player_name))
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
	if name.is_empty() or index >= match_node.slots.size():
		return
	match_node.slots[index].player_name = name


## Takes over the driving of this client's own kart once the snapshot has built it. Called every
## snapshot rather than once, the same as the kart's voice is: which slot is ours arrives in a
## message of its own, and the karts may well have been built before it did.
func adopt_own_kart() -> void:
	if is_host or local_slot < 0 or local_slot >= match_node.slots.size():
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
	if data is Dictionary:
		match_node.apply_snapshot(data)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _send_input(state: Array, seq: int = 0, claim: Array = []) -> void:
	var peer := multiplayer.get_remote_sender_id()
	if not _peer_slots.has(peer):
		return
	var index: int = _peer_slots[peer]
	if index >= match_node.slots.size():
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
	Events.callv("emit_signal", [name] + args)


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
	for name: StringName in RELAYED_EVENTS:
		var count := _signal_arity(name)
		match count:
			0:
				Events.connect(name, _relay0.bind(name))
			1:
				Events.connect(name, _relay1.bind(name))
			2:
				Events.connect(name, _relay2.bind(name))
			3:
				Events.connect(name, _relay3.bind(name))
			_:
				Events.connect(name, _relay4.bind(name))


func _signal_arity(name: StringName) -> int:
	for info: Dictionary in Events.get_signal_list():
		if info["name"] == String(name):
			return (info["args"] as Array).size()
	return 0


func _relay(name: StringName, args: Array) -> void:
	if not _connected():
		return
	if not multiplayer.get_peers().is_empty():
		_relay_event.rpc(name, args)


func _relay0(name: StringName) -> void:
	_relay(name, [])


func _relay1(a: Variant, name: StringName) -> void:
	_relay(name, [a])


func _relay2(a: Variant, b: Variant, name: StringName) -> void:
	_relay(name, [a, b])


func _relay3(a: Variant, b: Variant, c: Variant, name: StringName) -> void:
	_relay(name, [a, b, c])


func _relay4(a: Variant, b: Variant, c: Variant, d: Variant, name: StringName) -> void:
	_relay(name, [a, b, c, d])
