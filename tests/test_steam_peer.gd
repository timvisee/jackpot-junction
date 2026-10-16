extends GdUnitTestSuite
## A Steam game's connection, GAME.md 10.8: what goes down the line compressed, a snapshot sent
## unreliably with a number and a late one dropped, and a whole session played through it. Over
## ENet on this machine, since the connection wraps any other, with [FakeSteam] for Steam.

const FreePorts := preload("res://tests/free_ports.gd")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")

## A block of free ports of its own for every test, see tests/free_ports.gd: the first for two ends
## talking, the next for a whole session.
var port := 0
var _host_root: Node
var _client_root: Node


func before_test() -> void:
	port = FreePorts.take()
	_host_root = auto_free(Node.new())
	_host_root.name = "HostRoot"
	add_child(_host_root)
	_client_root = auto_free(Node.new())
	_client_root.name = "ClientRoot"
	add_child(_client_root)
	get_tree().set_multiplayer(SceneMultiplayer.new(), _host_root.get_path())
	get_tree().set_multiplayer(SceneMultiplayer.new(), _client_root.get_path())


func after_test() -> void:
	get_tree().set_multiplayer(null, _host_root.get_path())
	get_tree().set_multiplayer(null, _client_root.get_path())
	Store.steam = null
	SteamStore.loopback_port = 0


## A few bytes go as they are; a snapshot's worth goes compressed, shorter, and comes back the same.
func test_what_goes_down_the_line_is_compressed() -> void:
	var peer := SteamPeer.new(ENetMultiplayerPeer.new())
	var few := PackedByteArray([1, 2, 3])
	var packed := peer.pack(few, MultiplayerPeer.TRANSFER_MODE_RELIABLE, 0)
	assert_int(packed[0]).is_equal(0)
	assert_array(Array(peer.unpack(packed, 1, 0))).is_equal(Array(few))
	var snapshot := var_to_bytes(_a_snapshot())
	packed = peer.pack(snapshot, MultiplayerPeer.TRANSFER_MODE_RELIABLE, 0)
	assert_int(packed[0] & SteamPeer.COMPRESSED).is_equal(SteamPeer.COMPRESSED)
	assert_int(packed.size()).is_less(snapshot.size() / 3)
	assert_bool(peer.unpack(packed, 1, 0) == snapshot).is_true()
	assert_that(peer.unpack(PackedByteArray(), 1, 0)).is_null()
	assert_that(peer.unpack(PackedByteArray([SteamPeer.COMPRESSED, 9, 9]), 1, 0)).is_null()


## A packet sent unreliably in order gets a number; one heard after a later one, or twice, is
## dropped; the numbers come round again after 65535; every peer and channel counts on its own.
func test_a_late_snapshot_is_dropped() -> void:
	var sender := SteamPeer.new(ENetMultiplayerPeer.new())
	var hearer := SteamPeer.new(ENetMultiplayerPeer.new())
	var ordered := MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED
	var first := sender.pack(PackedByteArray([1]), ordered, 0)
	var second := sender.pack(PackedByteArray([2]), ordered, 0)
	assert_int(first[0] & SteamPeer.NUMBERED).is_equal(SteamPeer.NUMBERED)
	assert_that(hearer.unpack(second, 2, 0)).is_not_null()
	assert_that(hearer.unpack(first, 2, 0)).is_null()
	assert_that(hearer.unpack(second, 2, 0)).is_null()
	assert_that(hearer.unpack(first, 3, 0)).is_not_null()
	assert_that(hearer.unpack(first, 2, 1)).is_not_null()
	sender._sent[0] = 0xFFFF
	var last := sender.pack(PackedByteArray([3]), ordered, 0)
	var round_again := sender.pack(PackedByteArray([4]), ordered, 0)
	assert_that(hearer.unpack(last, 4, 0)).is_not_null()
	assert_that(hearer.unpack(round_again, 4, 0)).is_not_null()


## Two ends on this machine: what one sends, the other hears as it was sent, the ordered one as
## ordered.
func test_two_ends_hear_each_other() -> void:
	var server_enet := ENetMultiplayerPeer.new()
	assert_int(server_enet.create_server(port, 2)).is_equal(OK)
	var client_enet := ENetMultiplayerPeer.new()
	assert_int(client_enet.create_client("127.0.0.1", port)).is_equal(OK)
	var server := SteamPeer.new(server_enet)
	var client := SteamPeer.new(client_enet)
	var connected := false
	for _round: int in 200:
		server.poll()
		client.poll()
		if client.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			connected = true
			break
		await await_millis(10)
	assert_bool(connected).is_true()
	var snapshot := var_to_bytes(_a_snapshot())
	client.set_target_peer(1)
	client.transfer_mode = MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED
	client.put_packet(snapshot)
	client.transfer_mode = MultiplayerPeer.TRANSFER_MODE_RELIABLE
	client.put_packet(PackedByteArray([7, 7]))
	var heard: Array[PackedByteArray] = []
	var modes: Array[int] = []
	for _round: int in 200:
		client.poll()
		server.poll()
		while server.get_available_packet_count() > 0:
			modes.append(server.get_packet_mode())
			heard.append(server.get_packet())
		if heard.size() >= 2:
			break
		await await_millis(10)
	assert_int(heard.size()).is_equal(2)
	var snapshot_heard := heard[0] if heard[0].size() > 2 else heard[1]
	assert_bool(snapshot_heard == snapshot).is_true()
	assert_array(modes).contains([MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED])
	client.close()
	server.close()


## A Steam game, hosted and joined: the friend is seated and plays the host's match, every packet
## through the Steam connection, and is counted by where it is rather than as nowhere.
func test_a_steam_game_is_hosted_and_joined() -> void:
	SteamStore.loopback_port = port + 1
	Store.steam = SteamStore.new(FakeSteam.new())
	Store.steam.start(3141590)
	var host_match: Match = auto_free(MATCH_SCENE.instantiate())
	host_match.name = "Match"
	host_match.rules = _quick_rules()
	host_match.with_hud = false
	host_match.offer_size = 0
	_host_root.add_child(host_match)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new()]
	host_match.start(inputs, 23)
	var host_session: NetSession = auto_free(NetSession.new())
	host_session.name = "Session"
	host_session.match_node = host_match
	_host_root.add_child(host_session)
	assert_int(host_session.host_steam()).is_equal(OK)
	assert_object(SteamPeer.of(host_session.multiplayer.multiplayer_peer)).is_not_null()
	var client_match: Match = auto_free(MATCH_SCENE.instantiate())
	client_match.name = "Match"
	client_match.rules = _quick_rules()
	client_match.with_hud = false
	_client_root.add_child(client_match)
	client_match.start_puppet()
	var client_session: NetSession = auto_free(NetSession.new())
	client_session.name = "Session"
	client_session.match_node = client_match
	client_session.local_input = KartInput.new()
	_client_root.add_child(client_session)
	assert_int(client_session.join_steam(76561197960287931)).is_equal(OK)
	var waited := 0
	while client_session.local_slot < 0 and waited < 12000:
		await await_millis(25)
		waited += 25
	assert_int(client_session.local_slot).is_equal(1)
	assert_bool(host_match.slots[1].input is NetInput).is_true()
	assert_str(host_session.guard.address_of(host_session.multiplayer.get_peers()[0])).is_equal(
		"127.0.0.1"
	)
	waited = 0
	while client_match.slots.size() < 2 and waited < 4000:
		await await_millis(25)
		waited += 25
	assert_int(client_match.slots.size()).is_equal(2)
	# The host leaving its lobby hangs the friend up at once, as a connection lost.
	var gone: Array[bool] = []
	client_session.disconnected.connect(func() -> void: gone.append(true))
	var joins: SteamJoins = auto_free(SteamJoins.new())
	var session_was := Net.session
	Net.session = client_session
	joins.hang_up()
	Net.session = session_was
	waited = 0
	while gone.is_empty() and waited < 2000:
		await await_millis(25)
		waited += 25
	assert_array(gone).has_size(1)


func _quick_rules() -> MatchRules:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	rules.duration = 60.0
	return rules


## Something the size and shape of a busy snapshot: many karts and pickups, as numbers.
func _a_snapshot() -> Dictionary:
	var karts: Array = []
	for i: int in 8:
		karts.append(
			{"position": Vector3(i, 0.5, i * 2.0), "yaw": 0.25 * i, "coins": 10 * i, "mult": 1.5}
		)
	var pickups: Array = []
	for i: int in 120:
		pickups.append([i, Vector3(i % 11, 0.0, i % 7), i % 3])
	return {"tick": 4242, "karts": karts, "pickups": pickups}
