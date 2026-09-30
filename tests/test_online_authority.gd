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


## Ticks of controls from the client in slot 0 as the host hears them: [param shape] set on a plain
## input and packed the way a client packs it, sent [param times] over, since the host holds a
## couple in hand before it plays any, see [constant NetInput.QUEUE_REFILL].
func _send(shape: Callable, times := 3) -> void:
	var input := _host.slots[0].input as NetInput
	for i: int in times:
		var controls := KartInput.new()
		shape.call(controls)
		input.receive(NetInput.encode(controls), input.last_seq + 1)


## A client picks a joker from the cards the host dealt it and from nothing else, GAME.md 10.3: it
## sends its controls, never a card, and the host reads the pick off its own offer. A card by a
## number the host never dealt is nothing at all.
func test_a_client_picks_only_from_the_cards_the_host_dealt() -> void:
	await _two_machines(3)
	var kart := _host.kart_of(0)
	var held := kart.jokers.ids()
	kart.die(&"test", -1)
	var offer := _host.slots[0].offer
	assert_object(offer).override_failure_message("the host dealt no cards").is_not_null()
	var dealt: Array[StringName] = []
	for joker: Joker in offer.choices:
		dealt.append(joker.id)
	await _runner.simulate_frames(40, 17)
	_send(func(controls: KartInput) -> void: controls.joker_select = 42)
	_send(func(controls: KartInput) -> void: controls.joker_select = dealt.size())
	await _runner.simulate_frames(10, 17)
	assert_bool(offer.is_done()).override_failure_message("a card nobody dealt").is_false()
	assert_array(kart.jokers.ids()).is_equal(held)
	_send(func(controls: KartInput) -> void: controls.joker_select = 1)
	await _runner.simulate_frames(10, 17)
	assert_bool(offer.is_done()).is_true()
	assert_bool(dealt[1] in kart.jokers.ids()).is_true()
	for id: StringName in kart.jokers.ids():
		assert_bool(id in held or id == dealt[1]).override_failure_message(id).is_true()


## A client's word for its own kart is where it went, not what it holds: a claim of a fuller tank,
## a boost, a turbo or a power-up the host never gave it, or of more speed than the kart has, is
## held to what the host made of the same tick itself.
func test_a_client_cannot_claim_more_than_the_host_gave_it() -> void:
	await _two_machines()
	await _runner.simulate_frames(10, 17)
	var kart := _host.kart_of(0)
	kart.nitro_charge = 0.1
	var claim := KartPrediction.capture(kart)
	var fields := KartMotor.STATE_FIELDS
	claim[2 + fields.find(&"speed_bonus")] = 5.0
	claim[2 + fields.find(&"boost_time_left")] = 9.0
	claim[2 + fields.find(&"turbo_time_left")] = 9.0
	claim[2 + fields.find(&"velocity")] = Vector3(200.0, 0.0, 0.0)
	claim[2 + fields.find(&"forward_speed")] = 200.0
	claim[claim.size() - 2] = 1.0
	claim[claim.size() - 1] = true
	(_host.slots[0].input as NetInput).claim = claim
	KartPrediction.follow_claim(kart, kart.global_position)
	assert_float(kart.nitro_charge).is_less_equal(0.1 + ClaimCheck.NITRO_SLACK)
	assert_bool(kart.nitro_active).override_failure_message("lit on a tank too low").is_false()
	assert_float(kart.motor.speed_bonus).is_equal(1.0)
	assert_float(kart.motor.boost_time_left).is_less_equal(ClaimCheck.TIME_SLACK)
	assert_float(kart.motor.turbo_time_left).is_less_equal(ClaimCheck.TIME_SLACK)
	var limit := kart.motor.max_speed() + ClaimCheck.SPEED_SLACK
	assert_float(kart.motor.velocity.length()).is_less_equal(limit + 0.001)
	assert_float(kart.velocity.length()).is_less_equal(limit + 0.001)


## A client cannot say its kart went further than it could drive: each claim spends the reach the
## kart has banked driving at its limit, a few ticks of it at most, and one past that is not
## followed, however near it is to where the host has the kart.
func test_a_client_cannot_claim_further_than_it_could_drive() -> void:
	await _two_machines()
	await _runner.simulate_frames(10, 17)
	var kart := _host.kart_of(0)
	var input := _host.slots[0].input as NetInput
	var tick := (kart.motor.max_speed() + ClaimCheck.SPEED_SLACK) / 60.0
	var jump := tick * ClaimCheck.REACH_TICKS + 0.3
	assert_float(jump).is_less(NetInput.CLAIM_REACH)
	var was := kart.global_position
	var claim := KartPrediction.capture(kart)
	claim[0] = float(claim[0]) + jump
	input.claim = claim
	KartPrediction.follow_claim(kart, was)
	assert_float(kart.global_position.distance_to(was)).is_less(0.01)
	assert_float(input.denied_left).is_greater(0.0)
	# At the kart's limit, tick after tick, it is followed; a fifth over it, it runs out of reach.
	input.denied_left = 0.0
	var followed := 0
	for i: int in 30:
		var from := kart.global_position
		var step := KartPrediction.capture(kart)
		step[0] = float(step[0]) + tick * (0.95 if i < 10 else 1.2)
		input.claim = step
		KartPrediction.follow_claim(kart, from)
		if kart.global_position.distance_to(from) > 0.0:
			followed += 1
	assert_int(followed).is_greater_equal(10)
	assert_float(input.denied_left).override_failure_message("never ran out").is_greater(0.0)


## Controls that are not controls, from a client that is broken or means harm, are dropped whole:
## a word where a number goes, or a number that is not one, and a claim of either is not a claim.
func test_the_host_drops_controls_that_are_not_controls() -> void:
	await _two_machines()
	var input := _host.slots[0].input as NetInput
	var seq := input.last_seq
	var worded := NetInput.encode(KartInput.new())
	worded[0] = "full left"
	input.receive(worded, seq + 1)
	var broken := NetInput.encode(KartInput.new())
	broken[1] = NAN
	input.receive(broken, seq + 2)
	var aimed := NetInput.encode(KartInput.new())
	aimed[NetInput.FIELDS] = {"x": 1}
	input.receive(aimed, seq + 3)
	assert_int(input.last_seq).override_failure_message("a broken packet was heard").is_equal(seq)
	var claim := KartPrediction.capture(_host.kart_of(0))
	claim[0] = INF
	input.receive(NetInput.encode(KartInput.new()), seq + 4, claim)
	assert_int(input.last_seq).is_equal(seq + 4)
	input.poll(1.0 / 60.0)
	input.poll(1.0 / 60.0)
	assert_array(input.claimed_state()).is_empty()
