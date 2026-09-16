class_name NetSession
extends Node
## Online play, GAME.md 9.3 and 10.3: a host-authoritative listen server over ENet. The host runs
## the whole match and sends state snapshots; clients send their input every tick, render the
## replicated state through a puppet match, and receive gameplay events for HUD and audio.

signal connected
signal connection_failed
signal disconnected
signal slot_assigned(index: int)

const DEFAULT_PORT := 7777
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
	&"kart_bumped",
	&"turbo_taken",
	&"nitro_gained",
	&"crate_destroyed",
	&"shield_popped",
	&"bomb_exploded",
	&"player_joined",
	&"player_left",
]

var match_node: Match
## The slot this client plays, -1 until the host assigns one.
var local_slot := -1
## The input the client sends; tests may swap it.
var local_input: KartInput = PlayerInput.new()
var is_host := false

var _tick := 0
var _peer_slots: Dictionary[int, int] = {}
var _relaying := false


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(func() -> void: connected.emit())
	multiplayer.connection_failed.connect(func() -> void: connection_failed.emit())
	multiplayer.server_disconnected.connect(func() -> void: disconnected.emit())


func _exit_tree() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null


func host(port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, MAX_CLIENTS)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	is_host = true
	_start_relaying()
	return OK


func join(address: String, port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	is_host = false
	return OK


func is_connected_to_host() -> bool:
	return not is_host and local_slot >= 0


func _physics_process(delta: float) -> void:
	if match_node == null or multiplayer.multiplayer_peer == null:
		return
	if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	if is_host:
		_tick += 1
		if _tick % SNAPSHOT_EVERY_TICKS == 0 and not multiplayer.get_peers().is_empty():
			_receive_snapshot.rpc(var_to_bytes(match_node.build_snapshot()))
	elif local_slot >= 0:
		local_input.poll(delta)
		_send_input.rpc_id(1, NetInput.encode(local_input))


func _on_peer_connected(peer: int) -> void:
	if not is_host:
		return
	var slot := match_node.join_network(NetInput.new())
	if slot == null:
		multiplayer.multiplayer_peer.disconnect_peer(peer)
		return
	_peer_slots[peer] = slot.index
	_assign_slot.rpc_id(peer, slot.index, match_node.rng.seed)


func _on_peer_disconnected(peer: int) -> void:
	if not is_host or not _peer_slots.has(peer):
		return
	var index: int = _peer_slots[peer]
	_peer_slots.erase(peer)
	if index < match_node.slots.size():
		match_node.leave_human(match_node.slots[index])


@rpc("authority", "call_remote", "reliable")
func _assign_slot(index: int, _seed: int) -> void:
	local_slot = index
	match_node.set_local_slot(index)
	slot_assigned.emit(index)


@rpc("authority", "call_remote", "unreliable")
func _receive_snapshot(bytes: PackedByteArray) -> void:
	var data: Variant = bytes_to_var(bytes)
	if data is Dictionary:
		match_node.apply_snapshot(data)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _send_input(state: Array) -> void:
	var peer := multiplayer.get_remote_sender_id()
	if not _peer_slots.has(peer):
		return
	var index: int = _peer_slots[peer]
	if index >= match_node.slots.size():
		return
	var input := match_node.slots[index].input as NetInput
	if input != null:
		input.receive(state)


@rpc("authority", "call_remote", "reliable")
func _relay_event(name: StringName, args: Array) -> void:
	Events.callv("emit_signal", [name] + args)


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
	var peer := multiplayer.multiplayer_peer
	if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
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
