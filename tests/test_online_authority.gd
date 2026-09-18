extends GdUnitTestSuite
## Who decides what, GAME.md 10.3. The table there says a client may decide where its own kart is
## and what its own controls just did, and that everything else is the host's. This suite holds
## the second half of that to account: it takes a client and tries, one at a time, to have it
## decide something that is not its to decide.
##
## The two matches are driven directly rather than over a socket, so each test is a statement
## about the rules rather than about a wire.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const TICK := 1.0 / 60.0

var _host: Match
var _client: Match
var _runner: GdUnitSceneRunner


func _rules() -> MatchRules:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 300.0
	return rules


## A host running a real match and a client watching it, driving slot 0.
func _two_machines(offers: int = 0) -> void:
	_host = auto_free(MATCH_SCENE.instantiate())
	_host.rules = _rules()
	_host.with_hud = false
	_host.offer_size = offers
	_runner = scene_runner(_host)
	var inputs: Array[KartInput] = [NetInput.new(), BotInput.new()]
	_host.start(inputs, 23)
	_client = auto_free(MATCH_SCENE.instantiate())
	_client.rules = _rules()
	_client.with_hud = false
	add_child(_client)
	_client.start_puppet()
	_client.set_local_slot(0)
	await _runner.simulate_frames(20, 17)
	_client.apply_snapshot(_host.build_snapshot())


## A client cannot give itself a point. Banking is the host's from end to end, and what a client
## holds is a picture of the host's answer that the next snapshot overwrites.
func test_a_client_cannot_award_itself_a_score() -> void:
	await _two_machines()
	assert_int(_client.slots[0].banked).is_equal(0)
	_client.slots[0].banked = 9999
	_client.slots[0].kart.pot.add_coins(500)
	_client.apply_snapshot(_host.build_snapshot())
	(
		assert_int(_client.slots[0].banked)
		. override_failure_message("a client kept a score it had written itself")
		. is_equal(0)
	)
	assert_int(_host.slots[0].banked).is_equal(0)
	(
		assert_int(_client.slots[0].kart.pot.coins)
		. override_failure_message("a client kept coins it had written itself")
		. is_equal(_host.kart_of(0).pot.coins)
	)


## A client cannot decide it is alive, or that anybody else is dead. Lives and death are the
## host's, and a client is told.
func test_a_client_cannot_decide_who_is_alive() -> void:
	await _two_machines()
	var theirs: Kart = _client.slots[1].kart
	assert_bool(theirs.alive).is_true()
	# Killing somebody else's kart on this machine does nothing at all: a puppet is never killed
	# here, it is told, and the next snapshot says they are fine.
	theirs.die(&"test", 0)
	assert_bool(theirs.alive).override_failure_message("a client killed a kart").is_true()
	_client.apply_snapshot(_host.build_snapshot())
	assert_bool(theirs.alive).is_true()
	assert_bool(_host.kart_of(1).alive).is_true()
	# And the other way: a client cannot keep its own kart alive once the host has finished it.
	_host.kart_of(0).die(&"test", -1)
	_client.apply_snapshot(_host.build_snapshot())
	var mine: Kart = _client.slots[0].kart
	(
		assert_bool(mine.alive)
		. override_failure_message("a client outlived the host's word for it")
		. is_false()
	)
	mine.alive = true
	_client.apply_snapshot(_host.build_snapshot())
	assert_bool(mine.alive).is_false()


## A client's bullets are pictures. They do not travel, they do not hit anything, and a client
## cannot put one in the air on its own: GAME.md 10.3 keeps the bullet on the host because whether
## one lives depends on a bullet fired by somebody this machine only sees where they were.
func test_a_client_cannot_put_a_bullet_in_the_air() -> void:
	await _two_machines()
	assert_bool(_client.bullets.puppet).is_true()
	assert_int(_client.puppet_bullets.size()).is_equal(0)
	var mine: Kart = _client.slots[0].kart
	var prediction := KartPrediction.new(mine)
	var pulling := KartInput.new()
	pulling.fire = true
	for i: int in 10:
		prediction.predict(pulling, TICK, i + 1)
	(
		assert_int(prediction.pulls)
		. override_failure_message("the trigger did nothing on the client")
		. is_greater(0)
	)
	(
		assert_int(_client.puppet_bullets.size())
		. override_failure_message(
			"a client put %d bullets in the air" % _client.puppet_bullets.size()
		)
		. is_equal(0)
	)
	# And the host has heard nothing about any of it, because none of that went anywhere.
	assert_int(_host.kart_of(0).cannon.live_count()).is_equal(0)


## A client does not pick things up. The pickups on its floor are not even watching for a kart:
## whether something was collected is the host's, and a client is told when the floor changes.
func test_a_client_cannot_collect_what_it_drives_over() -> void:
	await _two_machines()
	var on_floor: Pickup = null
	for node: Node in _client.arena.pickups.get_children():
		var found := node as Pickup
		if found != null:
			on_floor = found
			break
	assert_object(on_floor).is_not_null()
	(
		assert_bool(on_floor.monitorable)
		. override_failure_message("a client's pickups were watching for karts")
		. is_false()
	)
	# Parked on top of it, for as long as anybody could want.
	var mine: Kart = _client.slots[0].kart
	mine.global_position = on_floor.global_position
	var coins := mine.pot.coins
	await _runner.simulate_frames(30, 17)
	_client.apply_snapshot(_host.build_snapshot())
	(
		assert_bool(is_instance_valid(on_floor))
		. override_failure_message("a client took a pickup off its own floor")
		. is_true()
	)
	assert_int(mine.pot.coins).is_equal(coins)


## Statistics are counted once, on the host. A client is told what everybody's figures are, and
## the events the host relays must not be counted again at the other end.
func test_a_client_does_not_count_statistics_for_itself() -> void:
	await _two_machines()
	var before := _client.slots[0].stats.value(&"jokers")
	assert_float(before).is_equal_approx(_host.slots[0].stats.value(&"jokers"), 0.001)
	# The kind of event the host relays. On the host it counts; on the client it must not.
	Events.joker_taken.emit(0, &"test_joker")
	await _runner.simulate_frames(2, 17)
	(
		assert_float(_host.slots[0].stats.value(&"jokers"))
		. override_failure_message("the host did not count a joker it was told about")
		. is_greater(before)
	)
	# The client's own figure only moves when the snapshot says so, and then it matches.
	_client.apply_snapshot(_host.build_snapshot())
	(
		assert_float(_client.slots[0].stats.value(&"jokers"))
		. override_failure_message("a client counted a relayed event on its own books")
		. is_equal_approx(_host.slots[0].stats.value(&"jokers"), 0.001)
	)


## The clock and the state of the match are the host's. A client holds what it was last told and
## does not run one of its own, which is what stops two machines finishing at different moments.
func test_a_client_does_not_run_the_clock() -> void:
	await _two_machines()
	_client.apply_snapshot(_host.build_snapshot())
	var told := _client.time_left
	assert_float(told).is_greater(0.0)
	# A full second of frames, with no snapshot to say otherwise.
	await _runner.simulate_frames(60, 17)
	(
		assert_float(_client.time_left)
		. override_failure_message("a client's clock ran on its own")
		. is_equal_approx(told, 0.001)
	)
	assert_float(_host.time_left).is_less(told)
	# Made up state does not survive the next thing the host says.
	_client.state = Match.State.RESULTS
	_client.apply_snapshot(_host.build_snapshot())
	assert_int(_client.state).is_equal(_host.state)


## A client's kart does not simulate itself. Everything it does comes through the prediction its
## session drives, which is what keeps one machine from quietly running a second physics.
func test_a_puppet_kart_does_not_drive_itself() -> void:
	await _two_machines()
	var mine: Kart = _client.slots[0].kart
	assert_bool(mine.puppet).is_true()
	assert_bool(mine.predicted).is_false()
	# A plain input, whose poll does nothing, so the throttle is still down when the tick comes
	# round. A player's input reads the keyboard every tick and would be back to nothing.
	var flat := KartInput.new()
	flat.throttle = 1.0
	mine.input = flat
	mine.motor.velocity = Vector3.ZERO
	var was := mine.global_position
	await _runner.simulate_frames(30, 17)
	(
		assert_float(mine.global_position.distance_to(was))
		. override_failure_message("a puppet drove itself on a throttle nobody was reading")
		. is_less(0.01)
	)
