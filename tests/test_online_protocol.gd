extends GdUnitTestSuite
## The moving parts underneath online play, GAME.md 10.3: the queue a client's controls are played
## back from, and the handover of the wheel between a client and the host. Both are easy to break
## without anything looking wrong, because what they get wrong is a tick here and a tick there.
##
## Held at the pieces themselves rather than over a wire, so a failure names the rule it broke.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DEFAULT_RULES: MatchRules = preload("res://data/match/default.tres")
const TICK := 1.0 / 60.0

var _runner: GdUnitSceneRunner


## A host running a real match with one networked player, for the tests that need a kart to do
## something to rather than a queue to feed. The runner has to be in place before the match
## starts, or the match builds itself outside the tree.
func _a_host() -> Match:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	var host: Match = auto_free(MATCH_SCENE.instantiate())
	host.rules = rules
	host.with_hud = false
	host.offer_size = 0
	_runner = scene_runner(host)
	var inputs: Array[KartInput] = [NetInput.new(), BotInput.new()]
	host.start(inputs, 23)
	return host


func _packet(steer: float, throttle: float, fire_pressed: bool = false) -> Array:
	var input := KartInput.new()
	input.steer = steer
	input.throttle = throttle
	input.fire_pressed = fire_pressed
	return NetInput.encode(input)


## One packet, one tick, in order. The client has already driven that tick itself and kept the
## answer, so a host that ran the same controls twice, or took two at once, would land somewhere
## the client never predicted and correct it for a mistake neither of them made.
func test_controls_are_played_back_one_tick_at_a_time() -> void:
	var input := NetInput.new()
	for i: int in 5:
		input.receive(_packet(float(i) * 0.1, 1.0), i + 1)
	assert_int(input.queued()).is_equal(5)
	# The queue is held until it has enough in hand, then plays out one a tick.
	input.poll(TICK)
	assert_int(input.applied_seq).is_equal(1)
	assert_float(input.steer).is_equal_approx(0.0, 0.001)
	input.poll(TICK)
	assert_int(input.applied_seq).is_equal(2)
	assert_float(input.steer).is_equal_approx(0.1, 0.001)
	input.poll(TICK)
	(
		assert_int(input.applied_seq)
		. override_failure_message("the host took more than one tick of controls at once")
		. is_equal(3)
	)
	assert_int(input.queued()).is_equal(2)


## Packets travel unreliably and arrive in whatever order they like. One that turns up late is
## older news than what has already been taken, and taking it would drive the kart backwards.
func test_a_packet_that_arrives_late_is_dropped() -> void:
	var input := NetInput.new()
	input.receive(_packet(0.0, 1.0), 5)
	input.receive(_packet(0.0, 1.0), 6)
	assert_int(input.last_seq).is_equal(6)
	input.receive(_packet(-1.0, 0.0), 4)
	(
		assert_int(input.last_seq)
		. override_failure_message("an older packet was taken as news")
		. is_equal(6)
	)
	assert_int(input.queued()).is_equal(2)
	# The same number twice is the same tick twice, which is also not news.
	input.receive(_packet(-1.0, 0.0), 6)
	assert_int(input.queued()).is_equal(2)


## A queue with nothing in it means a packet is late, not that the player let go. Holding the last
## controls is a tick out of date; letting go on their behalf would be wrong.
func test_an_empty_queue_holds_what_the_player_last_asked_for() -> void:
	var input := NetInput.new()
	for i: int in 3:
		input.receive(_packet(0.5, 1.0), i + 1)
	input.poll(TICK)
	input.poll(TICK)
	input.poll(TICK)
	assert_float(input.throttle).is_equal_approx(1.0, 0.001)
	var was := input.applied_seq
	# Nothing arrives for a while.
	for i: int in 5:
		input.poll(TICK)
	(
		assert_float(input.throttle)
		. override_failure_message("a late packet was taken as the player letting go")
		. is_equal_approx(1.0, 0.001)
	)
	(
		assert_int(input.applied_seq)
		. override_failure_message("the host answered for ticks it never received")
		. is_equal(was)
	)


## One-tick presses are the part nobody can afford to lose. A packet let go because the queue ran
## too long is still spent for what the player pressed in it.
func test_a_press_survives_a_packet_being_let_go() -> void:
	var input := NetInput.new()
	# More than the queue will hold, with the press in the very first one.
	input.receive(_packet(0.0, 0.0, true), 1)
	for i: int in NetInput.QUEUE_MAX + 3:
		input.receive(_packet(0.0, 0.0), i + 2)
	assert_int(input.queued()).is_equal(NetInput.QUEUE_MAX)
	input.poll(TICK)
	(
		assert_bool(input.fire_pressed)
		. override_failure_message("a button press was dropped with the packet that carried it")
		. is_true()
	)


## The wheel goes back to the host for the things one end cannot settle alone, GAME.md 10.3, and
## the client is told it has. Each of these is a moment a player would otherwise be corrected for.
func test_the_host_takes_the_wheel_for_what_it_has_to_settle() -> void:
	var host := _a_host()
	await _runner.simulate_frames(20, 17)
	var input := host.slots[0].input as NetInput
	var kart := host.kart_of(0)
	# While nothing is happening the host follows what the client says.
	input.receive(_packet(0.0, 1.0), 1)
	input.receive(_packet(0.0, 1.0), 2)
	input.poll(TICK)
	input.claim = KartPrediction.capture(kart)
	assert_bool(input.claimed_state().is_empty()).is_false()
	# Losing the tires on oil is not something a client can see coming.
	kart.hit_oil(1.0)
	(
		assert_bool(input.claimed_state().is_empty())
		. override_failure_message("a client kept the wheel through a spin-out")
		. is_true()
	)
	assert_float(input.denied_left).is_greater(0.0)
	# It comes back on its own once the moment has passed.
	for i: int in 40:
		input.poll(TICK)
	assert_float(input.denied_left).is_equal_approx(0.0, 0.001)
	# Going down a hole, dying and coming back are the same kind of thing.
	for what: String in ["fall", "die", "respawn"]:
		input.denied_left = 0.0
		input.claim = KartPrediction.capture(kart)
		match what:
			"fall":
				kart.alive = true
				kart.falling = false
				kart.start_fall()
			"die":
				kart.alive = true
				kart.die(&"test", -1)
			"respawn":
				kart.respawn(Vector3.ZERO, Vector3.FORWARD, 1.0)
		(
			assert_float(input.denied_left)
			. override_failure_message("a client kept the wheel through a %s" % what)
			. is_greater(0.0)
		)


## A claim has to be believable. The limit is what stops a kart appearing on the far side of the
## room, and it costs nothing because the host is simulating the kart either way.
func test_a_claim_from_too_far_away_is_refused() -> void:
	var host := _a_host()
	await _runner.simulate_frames(20, 17)
	var input := host.slots[0].input as NetInput
	var kart := host.kart_of(0)
	var was := kart.global_position
	# A step the kart could plausibly have taken is followed.
	var near := KartPrediction.capture(kart)
	near[0] = float(near[0]) + 0.2
	input.claim = near
	KartPrediction.follow_claim(kart, kart.global_position)
	assert_float(kart.global_position.x).is_equal_approx(was.x + 0.2, 0.01)
	assert_float(input.denied_left).is_equal_approx(0.0, 0.001)
	# One it could not is refused, and the host keeps driving.
	was = kart.global_position
	var far := KartPrediction.capture(kart)
	far[0] = float(far[0]) + NetInput.CLAIM_REACH + 5.0
	input.claim = far
	KartPrediction.follow_claim(kart, kart.global_position)
	(
		assert_float(kart.global_position.distance_to(was))
		. override_failure_message("a kart was moved across the room by asking")
		. is_less(0.01)
	)
	(
		assert_float(input.denied_left)
		. override_failure_message("the host went on taking that client's word for things")
		. is_greater(0.0)
	)


## A client drives its own kart only while there is something to drive, GAME.md 10.3. On the grid,
## dead, or rolling out the end of a match, the kart follows the snapshot instead: none of those
## is a state anybody steers out of, and predicting one would be arguing with the host about a
## kart that is not going anywhere.
func test_a_client_only_drives_while_there_is_driving_to_do() -> void:
	var host := _a_host()
	await _runner.simulate_frames(20, 17)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = DEFAULT_RULES.duplicate()
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	client.set_local_slot(0)
	client.apply_snapshot(host.build_snapshot())
	var prediction := KartPrediction.new(client.slots[0].kart)
	var mine := prediction.kart
	assert_bool(mine.predicted).is_true()
	assert_int(mine.collision_mask & Layers.WORLD).is_not_equal(0)
	# Down a hole, which is one of the ways this happens and the one that costs the kart its
	# collisions on the way past.
	prediction.predict(KartInput.new(), TICK, 1)
	mine.start_fall()
	assert_int(mine.collision_mask).is_equal(0)
	# Stood down: the kart stops being something this machine moves, and forgets the ticks it was
	# holding, since nobody is going to ask about them.
	prediction.suspend()
	assert_bool(mine.predicted).is_false()
	assert_float(prediction.last_correction).is_equal_approx(0.0, 0.001)
	# And picked back up, solid again, with nothing carried over from before. A kart that came
	# back from this still able to drive through walls is a bug that has happened once already.
	mine.falling = false
	prediction.resume()
	assert_bool(mine.predicted).is_true()
	(
		assert_int(mine.collision_mask & Layers.WORLD)
		. override_failure_message("a kart came back from a stand-down able to drive through walls")
		. is_not_equal(0)
	)
	# A correction arriving with no history to compare against puts the kart where the host has it
	# rather than guessing, which is what a client that has just started driving again needs.
	var host_state := KartPrediction.capture(host.kart_of(0))
	host.kart_of(0).global_position = Vector3(5.0, 0.0, 5.0)
	prediction.reconcile(1, KartPrediction.capture(host.kart_of(0)), TICK)
	(
		assert_float(mine.global_position.distance_to(Vector3(5.0, 0.0, 5.0)))
		. override_failure_message("a kart with nothing to replay did not take the host's word")
		. is_less(KartPrediction.EASE_MAX + 0.1)
	)
	assert_object(host_state).is_not_null()


## What the host is following, said out loud. A client is told which of the two answers stood, so
## it knows whether there is anything to put right; getting this backwards would have a client
## either correcting itself for nothing or never correcting at all.
func test_the_host_says_whether_it_drove_or_followed() -> void:
	var host := _a_host()
	await _runner.simulate_frames(20, 17)
	var input := host.slots[0].input as NetInput
	var kart := host.kart_of(0)
	# Following: there is a claim in hand and nothing has been taken out of the client's hands.
	input.claim = KartPrediction.capture(kart)
	assert_bool(input.claimed_state().is_empty()).is_false()
	# Driving: the host has the wheel, so there is something for the client to be put right about.
	input.deny_claim(NetInput.CLAIM_DENIED)
	(
		assert_bool(input.claimed_state().is_empty())
		. override_failure_message("the host said it was following a claim it had refused")
		. is_true()
	)
	# A tick with nothing claimed at all is also the host driving, which is what happens when a
	# client's packets have not arrived.
	input.denied_left = 0.0
	input.claim = []
	assert_bool(input.claimed_state().is_empty()).is_true()


## GAME.md 9.3: the room does not stop because somebody looked at something else. A window the
## desktop has stopped drawing can hold the whole main loop up on the frame it is waiting to
## present, and on the host that is every client frozen until they click back.
func test_the_session_takes_the_window_over_while_it_is_in_the_background() -> void:
	var session: NetSession = auto_free(NetSession.new())
	add_child(session)
	assert_bool(session.unfocused).is_false()
	session.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_bool(session.unfocused).is_true()
	# Told twice is still once: the window is only taken over, and put back, on a change.
	session.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_bool(session.unfocused).is_true()
	session.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_bool(session.unfocused).is_false()
