extends GdUnitTestSuite
## The slower line the online suites are run over again, [NetLag]: it has the round trip it is
## set to, keeps in order what has to stay in order, and says a peer has gone only after the last
## of what it said before going.

const FreePorts := preload("res://tests/free_ports.gd")
const PATIENCE := 3
## A block of free ports of its own for every test, see tests/free_ports.gd.
var port := 0

var _host_root: Node
var _client_root: Node
var _host_echo: Echo
var _client_echo: Echo


## Both ends of a conversation, at the same place under each root so a call on one is a call on
## the other.
class Echo:
	extends Node

	var heard: Array = []
	var round_trips: Array[float] = []

	@rpc("any_peer", "call_remote", "reliable")
	func said(what: Variant) -> void:
		heard.append(what)

	@rpc("any_peer", "call_remote", "unreliable_ordered")
	func said_in_order(what: int) -> void:
		heard.append(what)

	@rpc("any_peer", "call_remote", "reliable")
	func knock(sent: int) -> void:
		answer.rpc_id(multiplayer.get_remote_sender_id(), sent)

	@rpc("any_peer", "call_remote", "reliable")
	func answer(sent: int) -> void:
		round_trips.append((Time.get_ticks_usec() - sent) / 1000000.0)


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
	_host_echo = Echo.new()
	_host_echo.name = "Echo"
	_host_root.add_child(_host_echo)
	_client_echo = Echo.new()
	_client_echo.name = "Echo"
	_client_root.add_child(_client_echo)


func after_test() -> void:
	NetLag.ping = 0.0
	NetLag.jitter = 0.0
	get_tree().set_multiplayer(null, _host_root.get_path())
	get_tree().set_multiplayer(null, _client_root.get_path())


func _wait_until(condition: Callable, max_millis: int) -> bool:
	var waited := 0
	while not condition.call() and waited < max_millis * PATIENCE:
		await await_millis(10)
		waited += 10
	return condition.call()


## A host and a client over the line as it is set, connected.
func _connect() -> void:
	var host := ENetMultiplayerPeer.new()
	assert_int(host.create_server(port, 2)).is_equal(OK)
	_host_root.multiplayer.multiplayer_peer = NetLag.over(host)
	var client := ENetMultiplayerPeer.new()
	assert_int(client.create_client("127.0.0.1", port)).is_equal(OK)
	_client_root.multiplayer.multiplayer_peer = NetLag.over(client)
	var both := func() -> bool:
		return (
			_client_root.multiplayer.get_peers().has(1)
			and not _host_root.multiplayer.get_peers().is_empty()
		)
	assert_bool(await _wait_until(both, 3000)).override_failure_message("never met").is_true()


## Off, the connection is the connection; on, it is under the line, and still found by what
## looks for the ENet connection.
func test_the_line_is_only_there_when_asked_for() -> void:
	var peer := ENetMultiplayerPeer.new()
	assert_object(NetLag.over(peer)).is_same(peer)
	assert_object(NetLag.enet(peer)).is_same(peer)
	NetLag.ping = 0.05
	var lagged := NetLag.over(peer)
	assert_bool(lagged is NetLag).is_true()
	assert_object(NetLag.enet(lagged)).is_same(peer)


## A knock answered takes the round trip the line is set to, and not a great deal more.
func test_a_knock_is_answered_a_round_trip_later() -> void:
	NetLag.ping = 0.1
	await _connect()
	for i: int in 5:
		_client_echo.knock.rpc_id(1, Time.get_ticks_usec())
		await await_millis(30)
	var answered := func() -> bool: return _client_echo.round_trips.size() == 5
	assert_bool(await _wait_until(answered, 2000)).is_true()
	for trip: float in _client_echo.round_trips:
		assert_float(trip).is_between(0.095, 0.4)


## Under jitter what is sent reliably or in order still arrives in the order it was sent.
func test_what_has_to_stay_in_order_does() -> void:
	NetLag.ping = 0.04
	NetLag.jitter = 0.02
	await _connect()
	var sent: Array = []
	for i: int in 30:
		_client_echo.said.rpc_id(1, i)
		sent.append(i)
		await await_millis(2)
	var all_in := func() -> bool: return _host_echo.heard.size() == sent.size()
	assert_bool(await _wait_until(all_in, 2000)).is_true()
	assert_array(_host_echo.heard).is_equal(sent)
	_host_echo.heard.clear()
	for i: int in 30:
		_client_echo.said_in_order.rpc_id(1, i)
		await await_millis(2)
	await await_millis(300)
	var last := -1
	for heard: int in _host_echo.heard:
		assert_int(heard).is_greater(last)
		last = heard


## A last word before the host lets go is heard before the letting go is.
func test_a_last_word_comes_before_the_hang_up() -> void:
	NetLag.ping = 0.1
	await _connect()
	var told: Array[String] = []
	_client_root.multiplayer.server_disconnected.connect(func() -> void: told.append("gone"))
	var peer: int = _host_root.multiplayer.get_peers()[0]
	_host_echo.said.rpc_id(peer, "goodbye")
	await await_millis(20)
	_host_root.multiplayer.multiplayer_peer.disconnect_peer(peer)
	var gone := func() -> bool: return told.has("gone")
	assert_bool(await _wait_until(gone, 2000)).is_true()
	assert_array(_client_echo.heard).is_equal(["goodbye"])
	# Gone for good once it has heard the last of it.
	assert_int(_client_root.multiplayer.multiplayer_peer.get_connection_status()).is_equal(
		MultiplayerPeer.CONNECTION_DISCONNECTED
	)
