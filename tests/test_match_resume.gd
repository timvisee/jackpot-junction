extends GdUnitTestSuite
## A map in play carried over to a new host, GAME.md 10.8, see [MatchResume]: what a client takes
## of the match as its host goes, read off the puppet it draws; the match started from it at the
## new host, slot for slot, held on the grid; the seats kept for the players coming back, sat in
## their own karts; the start let go once they are in; and the handover going into the map rather
## than a lobby. Over ENet on this machine with [FakeSteam] for Steam where a session is needed.

const WAITING_ROOM_SCRIPT := preload("res://scenes/waiting/waiting_room.gd")
const FreePorts := preload("res://tests/free_ports.gd")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const BO := 76561197960287932

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
	Net.session = null
	Game.pending_config = null


func _quick_rules() -> MatchRules:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	rules.duration = 120.0
	return rules


func _a_match(root: Node) -> Match:
	var made: Match = auto_free(MATCH_SCENE.instantiate())
	made.name = "Match"
	made.rules = _quick_rules()
	made.with_hud = false
	made.offer_size = 0
	root.add_child(made)
	return made


func _until(done: Callable, most: int) -> void:
	var waited := 0
	while not done.call() and waited < most:
		await await_millis(25)
		waited += 25


## What the new host last saw: every slot, whose it is, and what each kart carried, read off the
## puppet the client draws; nothing for a lobby.
func test_a_client_takes_the_map_as_its_host_goes() -> void:
	SteamStore.loopback_port = port + 1
	Store.steam = SteamStore.new(FakeSteam.new())
	Store.steam.start(3141590)
	var host_match := _a_match(_host_root)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new()]
	host_match.start(inputs, 23)
	var host: NetSession = auto_free(NetSession.new())
	host.name = "Session"
	host.match_node = host_match
	_host_root.add_child(host)
	assert_int(host.host_steam()).is_equal(OK)
	Net.session = host
	Game.pending_config = SteamJoins.host_config(SteamLobby.Who.ANYONE)
	var client_match := _a_match(_client_root)
	client_match.start_puppet()
	var client: NetSession = auto_free(NetSession.new())
	client.name = "Session"
	client.match_node = client_match
	client.local_input = KartInput.new()
	_client_root.add_child(client)
	assert_int(client.join_steam(BO)).is_equal(OK)
	await _until(func() -> bool: return client.local_slot >= 0, 12000)
	await _until(func() -> bool: return host_match.is_running(), 4000)
	host_match.slots[0].banked = 250
	host_match.slots[0].kart.pot.add_coins(17)
	await _until(func() -> bool: return client_match.slots.size() == 2, 4000)
	await _until(func() -> bool: return client_match.slots[0].banked == 250, 4000)
	await _until(func() -> bool: return not client.host_controls.guests().is_empty(), 4000)
	var resume := MatchResume.capture(client)
	assert_dict(resume).is_not_empty()
	assert_str(str(resume["rules"]["map"])).is_equal(String(host_match.rules.map))
	var slots: Array = resume["slots"]
	assert_int(slots.size()).is_equal(2)
	assert_int(int(slots[0]["banked"])).is_equal(250)
	assert_int(int(slots[0]["coins"])).is_equal(17)
	assert_bool(slots[0]["here"]).is_false()
	assert_int(int(slots[0]["account"])).is_equal(Store.steam.account)
	assert_bool(slots[1]["here"]).is_true()
	assert_bool(slots[1]["human"]).is_true()
	# Nothing to carry over from a lobby.
	client_match.state = Match.State.LOBBY
	assert_dict(MatchResume.capture(client)).is_empty()
	# Nor from the waiting room, whose room is a match being played as well: its new host opens
	# the lobby afresh rather than starting a map from it.
	client_match.state = Match.State.PLAYING
	assert_dict(MatchResume.capture(client)).is_not_empty()
	var waiting_room: ArenaLayout = WAITING_ROOM_SCRIPT.LAYOUT
	client_match.arena_layout = waiting_room
	assert_str(waiting_room.resource_path).is_equal(MatchResume.WAITING_ROOM)
	assert_dict(MatchResume.capture(client)).is_empty()


## A resume as a client would have taken it: Ann here, Bo coming back, and a bot; Bo out and coming
## back, a chip, an item and a joker on the floor.
func _a_resume(joker: StringName) -> Dictionary:
	var ann := {
		"human": true,
		"here": true,
		"seat": 0,
		"device": DeviceInput.KEYBOARD,
		"color": 2,
		"team": -1,
		"name": "Ann",
		"banked": 120,
		"kills": 2,
		"deaths": 1,
		"x": 3.0,
		"z": -4.0,
		"h": 1.0,
		"alive": true,
		"lives": 1,
		"coins": 30,
		"mult": 2.5,
		"partial": 0.0,
		"item": "boost",
		"jokers": [String(joker)],
	}
	var bo := {
		"human": true,
		"here": false,
		"seat": 0,
		"account": BO,
		"color": 5,
		"team": -1,
		"name": "Bo",
		"banked": 400,
		"kills": 0,
		"deaths": 3,
		"x": -2.0,
		"z": 1.0,
		"h": 0.0,
		"alive": false,
		"respawn": 2.5,
		"lives": 0,
		"coins": 0,
		"mult": 1.0,
		"partial": 0.0,
		"item": "",
		"jokers": [],
	}
	var bot := {
		"human": false,
		"here": false,
		"color": 0,
		"team": -1,
		"name": "Ace",
		"banked": 60,
		"x": 0.0,
		"z": 5.0,
		"h": 0.0,
		"alive": true,
		"lives": 1,
		"coins": 4,
		"mult": 1.0,
		"item": "",
		"jokers": [],
	}
	return {
		"rules": _quick_rules().to_wire(),
		"state": Match.State.PLAYING,
		"time": 42.0,
		"bounty": [1, 3.0],
		"jackpots": [7.0],
		"floor":
		[
			{"kind": "chip", "x": 1.0, "z": 1.0, "gold": true, "value": 5},
			{"kind": "item", "x": -1.0, "z": 2.0, "item": "boost"},
			{"kind": "joker", "x": 2.0, "z": -1.0, "joker": String(joker)},
		],
		"slots": [ann, bo, bot],
	}


## The match the new host starts: slot for slot, held on the grid, every kart where it stood with
## what it carried, Bo out with a wait still to run, the clock, the bounty, the pile and the floor.
func test_the_new_host_starts_from_it() -> void:
	var host_match := _a_match(_host_root)
	var joker := host_match.joker_catalog.printed()[0].id
	var resume := _a_resume(joker)
	MatchResume.start(host_match, resume)
	assert_int(host_match.slots.size()).is_equal(3)
	assert_int(host_match.state).is_equal(Match.State.LOBBY)
	var ann := host_match.slots[0]
	assert_bool(ann.input is PlayerInput).is_true()
	assert_int((ann.input as PlayerInput).device).is_equal(DeviceInput.KEYBOARD)
	assert_str(ann.player_name).is_equal("Ann")
	assert_int(ann.color_index).is_equal(2)
	assert_int(ann.banked).is_equal(120)
	assert_int(ann.kills).is_equal(2)
	assert_float(ann.kart.global_position.x).is_equal_approx(3.0, 0.01)
	assert_float(ann.kart.motor.heading).is_equal_approx(1.0, 0.01)
	assert_int(ann.kart.pot.coins).is_equal(30)
	assert_float(ann.kart.pot.mult).is_equal(2.5)
	assert_str(String(ann.kart.held_item.id)).is_equal("boost")
	assert_array(ann.kart.jokers.ids()).is_equal([joker])
	var bo := host_match.slots[1]
	assert_bool(bo.input is BotInput).is_true()
	assert_int(bo.color_index).is_equal(5)
	assert_int(bo.banked).is_equal(400)
	assert_bool(bo.kart.alive).is_false()
	assert_float(bo.respawn_left).is_equal(2.5)
	assert_float(host_match.time_left).is_equal(42.0)
	assert_int(host_match.bounty_slot).is_equal(1)
	assert_float(host_match.arena.jackpot_zones[0].chips).is_equal(7.0)
	var kinds: Array[String] = []
	for node: Node in host_match.arena.pickups.get_children():
		if node is Chip and (node as Chip).dropped:
			kinds.append("chip")
		elif node is ItemBox and (node as ItemBox).fixed_item != null:
			kinds.append("item")
		elif node is FloorJoker:
			kinds.append("joker")
	kinds.sort()
	assert_array(kinds).is_equal(["chip", "item", "joker"])


## The seats kept for the players coming back, by account and the number of their seat there.
func test_the_seats_kept() -> void:
	var kept := MatchResume.seats_kept(_a_resume(&"x"))
	var bo := "a%d" % BO
	assert_array(kept.keys()).is_equal([bo])
	assert_dict(kept[bo][0]).is_equal({"slot": 1, "color": 5, "team": -1, "name": "Bo"})
	# Off Steam a player is known by the peer they were.
	assert_str(MatchResume.returning(0, 7)).is_equal("p7")
	assert_str(MatchResume.returning(0, 0)).is_empty()


## A player coming back is kept their seat, and sits in their own kart, which their color finds.
func test_a_player_comes_back_to_their_own_kart() -> void:
	var host_match := _a_match(_host_root)
	var host: NetSession = auto_free(NetSession.new())
	host.name = "Session"
	host.match_node = host_match
	host.is_host = true
	_host_root.add_child(host)
	var resume := _a_resume(host_match.joker_catalog.printed()[0].id)
	MatchResume.start(host_match, resume)
	host.host_controls.resume_from(resume)
	host.host_controls.knocked(77, {"was": 3})
	assert_dict(host._peer_slots.kept).is_empty()
	host.host_controls.keep_seats_for(77, "a%d" % BO)
	var kept := host._peer_slots.kept_for(77, 0)
	assert_int(int(kept["color"])).is_equal(5)
	var slot := host_match.join_network(NetInput.new(), kept)
	assert_int(slot.index).is_equal(1)
	assert_int(slot.banked).is_equal(400)
	assert_bool(host.host_controls.holds_for_next_map(77)).is_false()


## With nobody to wait for the lamps go at once; with somebody, once they are in or the wait is out.
func test_the_start_is_held_for_the_players_coming_back() -> void:
	var host_match := _a_match(_host_root)
	var joker := host_match.joker_catalog.printed()[0].id
	var host: NetSession = auto_free(NetSession.new())
	host.name = "Session"
	host.match_node = host_match
	host.is_host = true
	_host_root.add_child(host)
	MatchResume.start(host_match, _a_resume(joker))
	host.host_controls.resume_from(_a_resume(joker))
	await await_millis(200)
	assert_int(host_match.state).is_equal(Match.State.LOBBY)
	host.host_controls._resume_left = 0.05
	await _until(func() -> bool: return host_match.state != Match.State.LOBBY, 2000)
	assert_bool(host_match.state != Match.State.LOBBY).is_true()


## Steam made this machine the owner of a game whose map was being played: into the map, carried
## over, rather than a lobby.
func test_the_handover_goes_into_the_map() -> void:
	var fake := FakeSteam.new()
	Store.steam = SteamStore.new(fake)
	Store.steam.start(3141590)
	var handover: HostHandover = auto_free(HostHandover.new())
	var lobbied: Array[MatchConfig] = []
	var played: Array[MatchConfig] = []
	handover.go_on = func(config: MatchConfig) -> void: lobbied.append(config)
	handover.play_on = func(config: MatchConfig) -> void: played.append(config)
	add_child(handover)
	var resume := _a_resume(&"x")
	resume["rules"]["map"] = "crossfire"
	handover._kind = HostHandover.Kind.STEAM
	handover._lobby = fake.friends_lobby(fake.account, {})
	handover._old_host = BO
	handover._resume = resume
	await await_millis(100)
	assert_array(lobbied).is_empty()
	assert_int(played.size()).is_equal(1)
	assert_bool(played[0].rehost).is_true()
	assert_str(String(played[0].map)).is_equal("crossfire")
	assert_dict(played[0].resume).is_equal(resume)
