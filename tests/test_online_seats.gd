extends GdUnitTestSuite
## Several players at one client, GAME.md 10.3: a second sits down on a device of their own, is
## seated by the host in a seat of their own, drives it, and gets up again, the rest of that
## machine playing on. The host holds them to its lobby's limit, and can show one out without the
## other.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
## How much slack every wait in this suite gets, see test_online.gd.
const PATIENCE := 3

## Its own, since the suites run side by side; a suite that runs these again over a slower line,
## see [NetLag], takes another.
var port := 7837
var _host_root: Node
var _client_root: Node
var _host: NetSession
var _host_match: Match
var _client: NetSession
var _client_match: Match
var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	# By port, so that the lagged suite running beside this one has files of its own.
	Game.settings.path = "user://test_online_seats_%d.cfg" % port
	Game.settings.player_names[1] = "Second Seat"
	_host_root = auto_free(Node.new())
	_host_root.name = "HostRoot"
	add_child(_host_root)
	_client_root = auto_free(Node.new())
	_client_root.name = "ClientRoot"
	add_child(_client_root)
	get_tree().set_multiplayer(SceneMultiplayer.new(), _host_root.get_path())
	get_tree().set_multiplayer(SceneMultiplayer.new(), _client_root.get_path())


func after_test() -> void:
	MatchRecord.anywhere = false
	Net.session = null
	get_tree().set_multiplayer(null, _host_root.get_path())
	get_tree().set_multiplayer(null, _client_root.get_path())
	Settings.remove_files(Game.settings.path)
	Game.settings = _settings_were


func _wait_until(condition: Callable, max_millis: int) -> bool:
	var waited := 0
	var budget := max_millis * PATIENCE
	while not condition.call() and waited < budget:
		await await_millis(25)
		waited += 25
	return condition.call()


func _rules() -> MatchRules:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.lives = 3
	rules.duration = 120.0
	return rules


## A host with a player of its own and two bots, and a client seated in the first bot's kart.
func _seated() -> void:
	_host_match = auto_free(MATCH_SCENE.instantiate())
	_host_match.name = "Match"
	_host_match.rules = _rules()
	_host_match.with_hud = false
	_host_match.offer_size = 0
	_host_root.add_child(_host_match)
	var inputs: Array[KartInput] = [
		PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new(), BotInput.new()
	]
	_host_match.start(inputs, 23)
	_host = auto_free(NetSession.new())
	_host.name = "Session"
	_host.match_node = _host_match
	_host_root.add_child(_host)
	assert_int(_host.host(port)).is_equal(OK)
	_client_match = auto_free(MATCH_SCENE.instantiate())
	_client_match.name = "Match"
	_client_match.rules = _rules()
	_client_match.with_hud = true
	_client_root.add_child(_client_match)
	_client_match.start_puppet()
	_client = auto_free(NetSession.new())
	_client.name = "Session"
	_client.match_node = _client_match
	_client.local_input = KartInput.new()
	_client_root.add_child(_client)
	assert_int(_client.join("127.0.0.1", port)).is_equal(OK)
	var seated := await _wait_until(func() -> bool: return _client.local_slot >= 0, 4000)
	assert_bool(seated).override_failure_message("the client never sat down").is_true()


## Asks for a second seat at the client and waits for the host's answer either way.
func _sit_another_down() -> bool:
	_client.add_seat(0)
	return await _wait_until(
		func() -> bool: return _client.seats.size() == 2 and _client.seats[1].slot >= 0, 4000
	)


func test_a_second_player_at_a_client_sits_down_drives_and_leaves() -> void:
	await _seated()
	assert_bool(await _sit_another_down()).override_failure_message("no second seat").is_true()
	var second := _client.seats[1]
	assert_int(second.seat).is_equal(1)
	assert_int(second.slot).is_not_equal(_client.local_slot)
	# On the host: a seat of its own, somebody else's to drive, and under the name that seat of the
	# client's settings keeps.
	var hosted := _host_match.slots[second.slot]
	assert_bool(hosted.input is NetInput).is_true()
	var named := await _wait_until(func() -> bool: return hosted.player_name == "Second Seat", 4000)
	assert_bool(named).override_failure_message("the second seat kept the host's name").is_true()
	assert_int(_host.host_controls.guests().size()).is_equal(2)
	# On the client: played here, with a corner and a kart of its own.
	assert_bool(_client_match.is_local_seat(second.slot)).is_true()
	var blocks := await _wait_until(
		func() -> bool: return _client_match.hud._blocks.size() == 2, 4000
	)
	assert_bool(blocks).override_failure_message("the second player has no corner").is_true()
	# Driven from here, on its own controls.
	var controls := KartInput.new()
	second.input = controls
	var kart := _host_match.kart_of(second.slot)
	var start := kart.global_position
	controls.throttle = 1.0
	await await_millis(1500)
	assert_float(kart.global_position.distance_to(start)).is_greater(2.0)
	controls.throttle = 0.0
	# Up and gone: the seat is the host's to empty, the first player plays on.
	var index := second.slot
	_client.leave_seat(index)
	assert_int(_client.seats.size()).is_equal(1)
	assert_bool(_client_match.is_local_seat(index)).is_false()
	var emptied := await _wait_until(func() -> bool: return not hosted.input is NetInput, 4000)
	assert_bool(emptied).override_failure_message("the host kept the seat").is_true()
	assert_bool(_host_match.slots[_client.local_slot].input is NetInput).is_true()


## GAME.md 3.8: a second player at a client who sits in as another profile kept there is that
## profile on the host too: its name, its kart and its plate.
func test_a_profile_linked_at_a_client_reaches_the_host() -> void:
	await _seated()
	assert_bool(await _sit_another_down()).override_failure_message("no second seat").is_true()
	var second := _client.seats[1]
	var bob := Game.settings.new_profile()
	bob.player_names[0] = "Bob"
	bob.kart_styles[0] = PackedInt32Array([2, 1, 0, 3])
	bob.license_number = "0042"
	bob.license_plate = "BOB-1"
	bob.save_to_disk()
	Net.session = _client
	var slot := _client_match.slots[second.slot]
	assert_bool(SeatLink.link(_client_match, slot, bob.id)).is_true()
	var hosted := _host_match.slots[second.slot]
	var named := await _wait_until(func() -> bool: return hosted.player_name == "Bob", 4000)
	assert_bool(named).override_failure_message("the host kept the guest's name").is_true()
	assert_that(hosted.style.to_array()).is_equal(PackedInt32Array([2, 1, 0, 3]))
	var plate := hosted.kart.get_node("Body/Plate")
	assert_str(plate.get_meta(&"plate")).is_equal("BOB-1")
	# And said again as the seat sits down in the next room.
	assert_str(second.player_name).is_equal("Bob")
	assert_that(second.style).is_equal(PackedInt32Array([2, 1, 0, 3]))


## GAME.md 3.8: a client's players ask for their favorite colors as they sit down, and the host
## puts them in them, being free.
func test_a_clients_players_sit_down_in_their_favorites() -> void:
	Game.settings.set_seat_color(0, 5)
	Game.settings.set_seat_color(1, 6)
	await _seated()
	var first := _host_match.slots[_client.local_slot]
	var painted := await _wait_until(func() -> bool: return first.color_index == 5, 4000)
	assert_bool(painted).override_failure_message("the first seat kept the host's color").is_true()
	assert_bool(await _sit_another_down()).override_failure_message("no second seat").is_true()
	var second := _host_match.slots[_client.seats[1].slot]
	var also := await _wait_until(func() -> bool: return second.color_index == 6, 4000)
	assert_bool(also).override_failure_message("the second seat kept the host's color").is_true()


## GAME.md 8.5: a second player at a client who gets up mid-map has what they did written into
## their profile at once, here at the client, which is where their profile is.
func test_a_player_leaving_a_client_mid_map_is_written_down() -> void:
	MatchRecord.anywhere = true
	await _seated()
	var record := MatchRecord.add_to(_client_match)
	assert_bool(await _sit_another_down()).override_failure_message("no second seat").is_true()
	var bob := Game.settings.new_profile()
	bob.save_to_disk()
	Game.settings.link_seat(1, bob.id)
	var second := _client.seats[1]
	var slot := _client_match.slots[second.slot]
	# Counted from the moment the seat was given, whatever the kart had done before it.
	var taken: Dictionary = record._since.get(second.slot, {})
	slot.stats.values[&"driven"] = float(taken.get(&"driven", 0.0)) + 300.0
	_client.leave_seat(second.slot)
	var kept := Profile.at(Game.settings.profiles_dir(), bob.id)
	assert_float(LifetimeStats.value_of(kept, &"driven")).is_equal_approx(300.0, 0.001)
	assert_bool(record.recorded).is_false()


## GAME.md 9.6: a lobby for two holds two, whichever machine the third sits down at.
func test_the_host_refuses_a_seat_past_its_limit() -> void:
	await _seated()
	_host.door.max_players = 2
	var refused := [false]
	_client.seat_refused.connect(func(_seat: int) -> void: refused[0] = true)
	_client.add_seat(0)
	var told := await _wait_until(func() -> bool: return refused[0], 4000)
	assert_bool(told).override_failure_message("the client was never told").is_true()
	assert_int(_client.seats.size()).is_equal(1)
	assert_int(SeatLimit.players(_host_match)).is_equal(2)


## One of two players at a client shown out, and the other left playing.
func test_the_host_shows_out_one_of_two_players_at_a_client() -> void:
	await _seated()
	assert_bool(await _sit_another_down()).is_true()
	var peer: int = _host.host_controls.guests()[0]["peer"]
	var index := _client.seats[1].slot
	_host.host_controls.kick(peer, 1)
	var gone := await _wait_until(func() -> bool: return _client.seats.size() == 1, 4000)
	assert_bool(gone).override_failure_message("the client kept the player").is_true()
	assert_bool(_client_match.is_local_seat(index)).is_false()
	assert_bool(_client.local_slot >= 0).is_true()
	assert_bool(_host.anybody_connected()).is_true()
	assert_int(_host.host_controls.guests().size()).is_equal(1)


## A player shown out before any snapshot has built their slot is no longer played here: the seat
## came off the books even though the slot was not there to take anything else off. Under load it
## stayed on, and the slot arriving afterwards was a corner nobody sat at.
func test_a_seat_shown_out_before_its_slot_arrives_is_gone() -> void:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = _rules()
	match_node.with_hud = false
	add_child(match_node)
	match_node.start_puppet()
	var here := LocalSeats.new()
	var second := here.sit_down(0)
	second.slot = 5
	match_node.add_local_seat(5, second.input as PlayerInput)
	assert_bool(match_node.is_local_seat(5)).is_true()
	here.stand_up(second, match_node)
	assert_bool(match_node.is_local_seat(5)).is_false()
	assert_int(here.seats.size()).is_equal(0)


## A second press on a pad whose seat has been asked for is the same player, not another one.
func test_a_second_press_on_the_same_pad_asks_for_nothing_more() -> void:
	var here := LocalSeats.new()
	assert_object(here.sit_down(1)).is_not_null()
	assert_object(here.sit_down(1)).is_null()
	assert_object(here.sit_down(2)).is_not_null()
	assert_int(here.seats.size()).is_equal(2)


## The host told of a seat a client already has says which one it is rather than handing it a
## second one and leaving the first to nobody.
func test_asking_again_for_a_seat_finds_the_one_it_has() -> void:
	await _seated()
	var peer: int = _host.host_controls.guests()[0]["peer"]
	var index := _client.local_slot
	assert_int(_host._peer_slots.seated_in(_host_match, peer, 0)).is_equal(index)
	var karts := _host_match.slots.size()
	_host._seat(peer, false, 0)
	assert_int(_host_match.slots.size()).is_equal(karts)
	assert_int(_host._peer_slots.slot_of(peer, 0)).is_equal(index)
	assert_int(_host._peer_slots.seated_in(_host_match, peer, 3)).is_equal(-1)
