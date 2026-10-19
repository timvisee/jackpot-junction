extends GdUnitTestSuite
## Driving your own kart on a client, GAME.md 10.3. A host and a client run in one process with a
## wire between them that holds every packet for a set number of ticks, so the round trip is a
## number this suite sets rather than something to hope about. The question it answers is the one
## a player asks: does my kart move when I move the stick, and does it end up where the host says.
##
## Both ends are driven by the engine's own physics clock, through [signal SceneTree.physics_frame],
## rather than by counting rendered frames. A client that ticked at a different rate to the host
## would be corrected for that rather than for anything the prediction did, and the numbers this
## measures would be about the harness.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const TICK := 1.0 / 60.0
## Ticks each way by default. Three is 100 ms of round trip, four times the 25 ms the first
## report was about. A test that wants a slower wire raises [member _lag].
const LAG := 3
## The host sends its state every other tick, the same as [NetSession] does.
const SNAPSHOT_EVERY := 2

var _host: Match
var _client: Match
var _runner: GdUnitSceneRunner
var _prediction: KartPrediction
var _input: KartInput
var _tick := 0
var _running := false
## Packets in flight, each with the tick it lands on.
var _up: Array[Dictionary] = []
var _down: Array[Dictionary] = []
## One packet in this many is thrown away on the way up, 0 for a clean wire.
var _drop_one_in := 0
## Ticks each way on this test's wire.
var _lag := LAG
## The map both machines play, or null for the rules' own.
var _layout: ArenaLayout
## What the run cost: how far the two machines ever drifted apart, how often that needed putting
## right, how big the worst one was, and how many ticks the deepest replay had to run.
var _worst_gap := 0.0
var _snapshots := 0
var _corrections := 0
var _worst_correction := 0.0
var _deepest_replay := 0
## The worst single tick of movement the kart made that its own speed does not account for: what
## a correction actually looks like from the seat, in meters. A kart driving smoothly reads zero
## here however much it is being corrected underneath.
var _worst_jump := 0.0
var _worst_turn := 0.0
## The tick the throttle went down, and the tick each machine's kart first moved for it. The
## difference between those two is the thing the whole exercise is about.
var _asked_at := -1
var _moved_here_at := -1
var _moved_there_at := -1
## The same for the nitro button: the tick it went down, and the tick each machine lit it.
var _nitro_at := -1
var _burned_here_at := -1
var _burned_there_at := -1
## The tick each machine's kart went over the edge of a hole.
var _fell_here_at := -1
var _fell_there_at := -1


## Every test gets its own wire. Packets left in flight from the last one would be delivered into
## this one's first few ticks, which is a confusing way to fail.
func before_test() -> void:
	_up.clear()
	_down.clear()
	_tick = 0
	_running = false
	_prediction = null
	_worst_gap = 0.0
	_snapshots = 0
	_corrections = 0
	_worst_correction = 0.0
	_deepest_replay = 0
	_worst_jump = 0.0
	_worst_turn = 0.0
	_asked_at = -1
	_moved_here_at = -1
	_moved_there_at = -1
	_nitro_at = -1
	_burned_here_at = -1
	_burned_there_at = -1
	_fell_here_at = -1
	_fell_there_at = -1
	_drop_one_in = 0
	_lag = LAG
	_layout = null


func after_test() -> void:
	_running = false
	if get_tree().physics_frame.is_connected(_on_tick):
		get_tree().physics_frame.disconnect(_on_tick)


func _rules() -> MatchRules:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 300.0
	return rules


## A host with one networked player and one bot, and a client watching it that drives slot 0.
func _connect() -> void:
	_host = auto_free(MATCH_SCENE.instantiate())
	_host.rules = _rules()
	_host.arena_layout = _layout
	_host.with_hud = false
	_host.offer_size = 0
	_runner = scene_runner(_host)
	var inputs: Array[KartInput] = [NetInput.new(), BotInput.new()]
	_host.start(inputs, 23)
	_client = auto_free(MATCH_SCENE.instantiate())
	_client.rules = _rules()
	_client.arena_layout = _layout
	_client.with_hud = false
	add_child(_client)
	_client.start_puppet()
	_input = KartInput.new()
	_client.set_local_slot(0, PlayerInput.new())
	await _runner.simulate_frames(20, 17)
	_client.apply_snapshot(_host.build_snapshot())
	_prediction = KartPrediction.new(_client.slots[0].kart)
	get_tree().physics_frame.connect(_on_tick)
	_running = true


## One tick of the whole thing, on the same clock the host's karts move on: the client drives and
## sends, the wire delivers what is due, and the host answers what it has had time to see.
func _on_tick() -> void:
	if not _running or not is_instance_valid(_prediction.kart):
		return
	_tick += 1
	_prediction.predict(_input, TICK, _tick)
	if _drop_one_in <= 0 or _tick % _drop_one_in != 0:
		(
			_up
			. append(
				{
					"at": _tick + _lag,
					"seq": _tick,
					"state": NetInput.encode(_input),
					"claim": _prediction.claim(),
				}
			)
		)
	var host_input := _host.slots[0].input as NetInput
	for packet: Dictionary in _up.duplicate():
		if packet["at"] <= _tick:
			host_input.receive(packet["state"], packet["seq"], packet["claim"])
			_up.erase(packet)
	if _tick % SNAPSHOT_EVERY == 0:
		(
			_down
			. append(
				{
					"at": _tick + _lag,
					"ack": host_input.applied_seq,
					"state": KartPrediction.told(_host.kart_of(0)),
					"drove": host_input.claimed_state().is_empty(),
					"snapshot": _host.build_snapshot(),
				}
			)
		)
	for packet: Dictionary in _down.duplicate():
		if packet["at"] <= _tick:
			_snapshots += 1
			_client.apply_snapshot(packet["snapshot"])
			# As ClientSeat.settle has it: what the host says is in the air, and the shots it has
			# answered for.
			_prediction.hear(packet["ack"], packet["state"])
			if packet["drove"]:
				_prediction.reconcile(packet["ack"], packet["state"], TICK)
			else:
				_prediction.accept(packet["ack"])
			_down.erase(packet)
			if _prediction.last_correction > 0.0:
				_corrections += 1
				_worst_correction = maxf(_worst_correction, _prediction.last_correction)
				_deepest_replay = maxi(_deepest_replay, _prediction.last_replay)
			# How far putting it right moved the kart a player is looking at, which is the only
			# part of a correction anybody can see.
			_worst_jump = maxf(_worst_jump, _prediction.last_jump)
			_worst_turn = maxf(_worst_turn, _prediction.last_turn)
	_worst_gap = maxf(
		_worst_gap, _prediction.kart.global_position.distance_to(_host.kart_of(0).global_position)
	)
	if _asked_at < 0 and _input.throttle > 0.0:
		_asked_at = _tick
	if _moved_here_at < 0 and _prediction.kart.motor.speed() > 0.0:
		_moved_here_at = _tick
	if _moved_there_at < 0 and _host.kart_of(0).motor.speed() > 0.0:
		_moved_there_at = _tick
	if _nitro_at < 0 and _input.nitro:
		_nitro_at = _tick
	if _burned_here_at < 0 and _prediction.kart.nitro_active:
		_burned_here_at = _tick
	if _burned_there_at < 0 and _host.kart_of(0).nitro_active:
		_burned_there_at = _tick
	if _fell_here_at < 0 and _prediction.kart.falling:
		_fell_here_at = _tick
	if _fell_there_at < 0 and (_host.kart_of(0).falling or not _host.kart_of(0).alive):
		_fell_there_at = _tick


## Waits for [param ticks] physics ticks of the harness to have run.
func _drive(ticks: int) -> void:
	var until := _tick + ticks
	while _tick < until:
		(
			assert_bool(is_instance_valid(_prediction.kart))
			. override_failure_message("the kart being predicted was rebuilt under the test")
			. is_true()
		)
		await _runner.simulate_frames(4, 17)


func _report() -> String:
	return (
		(
			"gap %.3f m, %d of %d snapshots corrected (%d taken as read), worst %.3f m over %d ticks, "
			+ "worst unexplained jump %.4f m and %.2f deg"
		)
		% [
			_worst_gap,
			_corrections,
			_snapshots,
			_prediction.accepted,
			_worst_correction,
			_deepest_replay,
			_worst_jump,
			rad_to_deg(_worst_turn),
		]
	)


## The whole point, as a number: how many ticks pass between the throttle going down and the
## kart moving. On this machine it has to be the same tick. On the host it cannot be, because the
## packet is still traveling, and that gap is exactly what a player used to sit through.
func test_your_own_kart_answers_the_stick_at_once() -> void:
	await _connect()
	await _drive(10)
	assert_float(_prediction.kart.motor.speed()).is_equal_approx(0.0, 0.01)
	_input.throttle = 1.0
	await _drive(20)
	_running = false
	var here := _moved_here_at - _asked_at
	var there := _moved_there_at - _asked_at
	prints("MEASURE throttle to motion: here %d ticks, host %d ticks" % [here, there])
	assert_int(_asked_at).is_greater(0)
	(
		assert_int(here)
		. override_failure_message("own kart took %d ticks to answer the stick" % here)
		. is_equal(0)
	)
	# The host is a round trip behind, which is what a client used to wait for before it saw
	# its own kart move at all.
	(
		assert_int(there)
		. override_failure_message(
			"the host answered in %d ticks, expected at least %d" % [there, _lag]
		)
		. is_greater_equal(_lag)
	)


## Prediction is worth nothing if it wanders off. Driving hard for a few seconds, the kart on the
## client has to still be the kart on the host, and the corrections that keep it there have to be
## rare and small rather than a running argument.
## GAME.md 9.6 and 10.3: a room that fills tanks quickly, the lobby's and the Garage's, fills a
## client's quickly as well. The client drives its own tank and the host takes its word for it, so
## a client left on the plain rate refilled at a match's pace wherever it was.
func test_a_rooms_quick_tank_fills_on_the_client() -> void:
	await _connect()
	_host.rules.nitro_recharge_base = 25.0
	_client.rules.nitro_recharge_base = 25.0
	var here := _prediction.kart
	var there := _host.kart_of(0)
	here.nitro_charge = 0.0
	there.nitro_charge = 0.0
	# A second after the wait for the tank to start: 0.4 s at 25 times the rate of a 90 s tank is
	# worth about 0.11 of one, and the plain rate about 0.004.
	await _drive(60)
	_running = false
	assert_float(here.nitro_recharge_scale).is_equal(25.0)
	assert_float(here.nitro_charge).override_failure_message(_report()).is_greater(0.05)
	assert_float(there.nitro_charge).override_failure_message(_report()).is_greater(0.05)


## GAME.md 3.4 and 10.3: the Junction's faster tank is worked out on both machines, so a client
## cashing out watches its own tank fill as it waits rather than in steps as snapshots land.
func test_the_junction_fills_a_clients_tank_on_the_client() -> void:
	await _connect()
	var here := _prediction.kart
	var there := _host.kart_of(0)
	here.global_position = _host.arena.junction_position
	there.global_position = _host.arena.junction_position
	here.nitro_charge = 0.0
	there.nitro_charge = 0.0
	await _drive(4)
	assert_float(here.junction_recharge).is_equal(_host.rules.junction_nitro_recharge)
	# Two seconds of standing there. A tank takes 90 seconds to fill on its own, so the pad's
	# four times over is worth about 0.089 of one and going without it about 0.022.
	await _drive(120)
	_running = false
	assert_float(here.nitro_charge).override_failure_message(_report()).is_greater(0.05)
	assert_float(there.nitro_charge).override_failure_message(_report()).is_greater(0.05)
	assert_float(here.nitro_charge).override_failure_message(_report()).is_equal_approx(
		there.nitro_charge, 0.005
	)


func test_a_predicted_kart_stays_where_the_host_has_it() -> void:
	await _connect()
	_input.throttle = 1.0
	await _drive(60)
	_input.steer = 0.7
	await _drive(60)
	_input.steer = -0.7
	_input.handbrake = true
	await _drive(40)
	_input.handbrake = false
	_input.steer = 0.0
	await _drive(60)
	_running = false
	var host_kart := _host.kart_of(0)
	var own := _prediction.kart
	prints("MEASURE drive:", _report())
	assert_float(host_kart.global_position.distance_to(Vector3.ZERO)).is_greater(3.0)
	# A client is a round trip ahead of the host by design, so the two are never in the same
	# place. The lead is that round trip at whatever speed the kart is doing, and it has to be
	# that and not more: anything beyond it is prediction drifting rather than leading.
	var round_trip := float(_lag * 2 + SNAPSHOT_EVERY) * TICK
	var lead := host_kart.motor.speed() * round_trip
	(
		assert_float(own.global_position.distance_to(host_kart.global_position))
		. override_failure_message("%s, lead should be about %.2f m" % [_report(), lead])
		. is_less(lead + 0.5)
	)
	# The two machines mostly agree. A correction on every snapshot would mean they never do.
	assert_int(_corrections).override_failure_message(_report()).is_less(_snapshots / 4)
	assert_float(_worst_correction).override_failure_message(_report()).is_less(0.5)
	# Nothing a player could see. A clean wire should not move the kart at all beyond its own
	# driving, and this is the number that says so.
	assert_float(_worst_jump).override_failure_message(_report()).is_less(0.01)


## What the report asked for last: when the two do end up disagreeing, the host's word puts it
## right. Nothing in the game moves a kart four meters sideways, so this does it by hand, which
## is a harsher test than anything a dropped packet could manage.
func test_a_kart_knocked_out_of_step_is_put_back() -> void:
	await _connect()
	_input.throttle = 1.0
	await _drive(40)
	assert_int(_corrections).is_equal(0)
	var host_had := _host.kart_of(0).global_position
	_prediction.kart.global_position += Vector3(4.0, 0.0, 0.0)
	var knocked := _prediction.kart.global_position.distance_to(host_had)
	assert_float(knocked).is_greater(3.5)
	# One round trip later the host's answer arrives and the kart is where the host has it.
	await _drive(20)
	_running = false
	prints("MEASURE knocked out of step:", _report())
	(
		assert_int(_corrections)
		. override_failure_message("nothing noticed the kart was four meters out")
		. is_greater(0)
	)
	(
		assert_float(_prediction.kart.global_position.distance_to(_host.kart_of(0).global_position))
		. override_failure_message(_report())
		. is_less(1.5)
	)
	# This one is meant to show. Four meters out is a kart somewhere it is not, and gliding it
	# back across the room would be stranger to watch than arriving. Some of it is still walked
	# off rather than all of it landing at once.
	assert_float(_worst_jump).override_failure_message(_report()).is_greater(1.0)
	assert_float(_worst_jump).override_failure_message(_report()).is_less(
		knocked - KartPrediction.EASE_MAX + 0.1
	)
	# What is left of it is the picture's alone: the kart claims where the simulation has it, not
	# where it is drawn, so the host believes it again at once rather than once the picture has
	# caught up, and drives it on its own no longer than it has to.
	var claimed := _prediction.claim()
	var simulated := _prediction.simulated_transform().origin
	var gap := Vector2(claimed[0], claimed[1]).distance_to(Vector2(simulated.x, simulated.z))
	assert_float(gap).is_less(0.001)
	var believed := _prediction.accepted
	_running = true
	await _drive(30)
	_running = false
	assert_int(_prediction.accepted).override_failure_message(_report()).is_greater(believed)


## A wire that loses a packet in every five. The host carries on with the controls it last had,
## which is not what this machine did with that tick, so the two disagree and keep having to be
## put back in step. What matters is that it stays a nudge rather than becoming a fight.
func test_a_lossy_wire_still_keeps_the_kart_in_place() -> void:
	await _connect()
	_drop_one_in = 5
	_input.throttle = 1.0
	await _drive(60)
	_input.steer = 0.5
	await _drive(60)
	_running = false
	prints("MEASURE one packet in five lost:", _report())
	(
		assert_float(_prediction.kart.global_position.distance_to(_host.kart_of(0).global_position))
		. override_failure_message(_report())
		. is_less(2.0)
	)
	# Every correction stays inside the range that is walked off rather than snapped, so a lossy
	# wire reads as a kart settling rather than as a kart teleporting.
	assert_float(_worst_correction).override_failure_message(_report()).is_less(KartPrediction.SNAP)
	# The point of walking a correction in rather than applying it. On a wire dropping a packet
	# in five the kart is put right a dozen times, and not one of those moves the kart a player
	# is looking at at all: the picture never jumps, it only ever stops lagging.
	assert_float(_worst_jump).override_failure_message(_report()).is_less(0.01)
	assert_float(rad_to_deg(_worst_turn)).override_failure_message(_report()).is_less(0.1)


## Nitro is the button with the most immediate effect in the game, and the one the report named
## first. It has to burn on the tick it is pressed: it changes how fast the kart is about to go,
## and a round trip spent at the wrong speed is a round trip of being corrected for it.
func test_nitro_burns_on_the_tick_it_is_pressed() -> void:
	await _connect()
	_input.throttle = 1.0
	await _drive(40)
	assert_bool(_prediction.kart.nitro_active).is_false()
	_input.nitro = true
	await _drive(90)
	_running = false
	var here := _burned_here_at - _nitro_at
	var there := _burned_there_at - _nitro_at
	prints(
		(
			"MEASURE nitro to burning: here %d ticks, host %d ticks; tanks %.3f and %.3f"
			% [here, there, _prediction.kart.nitro_charge, _host.kart_of(0).nitro_charge]
		)
	)
	(
		assert_int(here)
		. override_failure_message("nitro took %d ticks to light on this machine" % here)
		. is_equal(0)
	)
	(
		assert_int(there)
		. override_failure_message(
			"the host lit it in %d ticks, expected at least %d" % [there, LAG]
		)
		. is_greater_equal(_lag)
	)
	(
		assert_float(_prediction.kart.nitro_charge)
		. override_failure_message(
			"tanks %.3f and %.3f" % [_prediction.kart.nitro_charge, _host.kart_of(0).nitro_charge]
		)
		. is_equal_approx(_host.kart_of(0).nitro_charge, 0.06)
	)
	assert_float(_worst_jump).override_failure_message(_report()).is_less(0.01)


## A wall is a wall on both machines, GAME.md 10.3. The kart used to be drawn part way through
## one: a correction still being walked in is a picture lagging behind a simulation, and nothing
## tested whether there was room to lag into.
func test_a_kart_is_never_drawn_inside_a_wall() -> void:
	await _connect()
	var bounds := _client.arena.bounds()
	var wall := -bounds.size.z * 0.5
	var start := Vector3(bounds.size.x * 0.5 - 2.0, 0.0, wall + 4.0)
	_prediction.kart.global_position = start
	_host.kart_of(0).global_position = start
	_prediction.kart.motor.heading = 0.0
	_host.kart_of(0).motor.heading = 0.0
	# Flat out into it, at an angle, on a wire dropping a packet in five. A clean run at a wall
	# barely disagrees with the host at all; the corrections that could push a kart through one
	# are the ones a lossy wire produces, so those are the conditions to ask about.
	_input.throttle = 1.0
	_input.nitro = true
	_input.steer = 0.25
	_drop_one_in = 5
	var deepest := 0.0
	for i: int in 90:
		await _drive(1)
		# How far past the inside face of the wall the kart is drawn, at any point in the run.
		deepest = maxf(deepest, wall - _prediction.kart.global_position.z)
	_running = false
	prints("MEASURE wall: deepest %.3f m past the wall, %s" % [deepest, _report()])
	(
		assert_float(deepest)
		. override_failure_message("drawn %.2f m inside the wall" % deepest)
		. is_less(0.6)
	)


## Driving into a hole, GAME.md 3.6. The kart used to carry on across the gap on this machine,
## get dragged back by the correction and only then start falling. It goes over the edge here.
func test_a_kart_falls_down_a_hole_when_it_drives_into_one() -> void:
	await _connect()
	var hole: Pit = _client.arena.pits[0]
	# Put the kart on the lip of the hole and drive it in, from above it.
	var at := hole.global_position + Vector3(0.0, 0.0, -3.0)
	KartPrediction.restore(_prediction.kart, KartPrediction.capture(_prediction.kart))
	_prediction.kart.global_position = at
	_host.kart_of(0).global_position = at
	_input.throttle = 1.0
	_input.steer = 0.0
	_prediction.kart.motor.heading = PI
	_host.kart_of(0).motor.heading = PI
	await _drive(60)
	_running = false
	(
		assert_bool(_fell_here_at >= 0)
		. override_failure_message("the kart drove over the hole without going down it")
		. is_true()
	)
	# The point of the exercise: it went down on this machine before the host had any idea, and
	# stayed down rather than being lifted back out by the next correction to arrive.
	prints("MEASURE hole: fell here at %d, host at %d" % [_fell_here_at, _fell_there_at])
	(
		assert_bool(_fell_there_at < 0 or _fell_here_at < _fell_there_at)
		. override_failure_message("fell here at %d, host at %d" % [_fell_here_at, _fell_there_at])
		. is_true()
	)
	assert_bool(_prediction.kart.falling or not _prediction.kart.alive).is_true()
	# It falls here and nowhere else: whether that cost a life is the host's to say, and the
	# client waits to be told rather than killing its own kart.
	assert_bool(_prediction.kart.puppet).is_true()


## A box taken at ramming speed, GAME.md 6.2. Passing through one is right, but the box has to go
## with it: a client that drove through a box still standing on its own screen is a kart seen
## plowing through solid scenery until the snapshot catches up.
func test_a_box_driven_through_goes_off_the_floor_here() -> void:
	await _connect()
	var crate: Crate = _client.arena.crates[0]
	assert_bool(crate.alive).is_true()
	# Lined up on it, flat out, with nitro, which is what takes a kart through a box.
	var at := crate.global_position + Vector3(0.0, 0.0, 2.2)
	_prediction.kart.global_position = at
	_host.kart_of(0).global_position = at
	_prediction.kart.motor.heading = 0.0
	_host.kart_of(0).motor.heading = 0.0
	_input.throttle = 1.0
	_input.nitro = true
	var host_crate: Crate = _host.arena.crates[0]
	var broke_here := -1
	var broke_there := -1
	for i: int in 60:
		await _drive(1)
		if broke_here < 0 and not crate.alive:
			broke_here = _tick
		if broke_there < 0 and not host_crate.alive:
			broke_there = _tick
	_running = false
	prints("MEASURE box: went here at %d, host at %d" % [broke_here, broke_there])
	(
		assert_int(broke_here)
		. override_failure_message("the kart drove through a box that stayed on the floor")
		. is_greater(0)
	)
	# Off the floor here first, and not solid any more either, so the kart is through it rather
	# than grinding along a box nobody can see the point of.
	assert_int(crate.collision_layer).is_equal(0)
	# Whether it then stays off the floor is asked in test_online_sync.gd rather than here: both
	# matches in this harness share one physics space, so the kart breaks the host's box at the
	# same moment as its own and there is never a snapshot saying otherwise to stand up to.
	(
		assert_bool(broke_there < 0 or broke_here <= broke_there)
		. override_failure_message("here at %d, host at %d" % [broke_here, broke_there])
		. is_true()
	)


## The request this was built for: the client's own answer stands until two karts touch, and then
## the host settles it. Neither machine can settle a bump on its own, since each sees the other
## where it last heard, so each predicting its own side would have both shoved and neither right.
func test_touching_another_kart_hands_the_wheel_to_the_host() -> void:
	await _connect()
	_input.throttle = 1.0
	await _drive(30)
	var host_input := _host.slots[0].input as NetInput
	(
		assert_bool(host_input.claimed_state().is_empty())
		. override_failure_message("the host was not taking the client's word for driving")
		. is_false()
	)
	# Parked right on top of the bot, which is a contact the host has to resolve.
	var bot := _host.kart_of(1)
	bot.global_position = _host.kart_of(0).global_position + Vector3(1.0, 0.0, 0.0)
	_input.steer = 1.0
	await _drive(20)
	_running = false
	(
		assert_float(host_input.denied_left)
		. override_failure_message("running into somebody left the client still steering")
		. is_greater(0.0)
	)
	(
		assert_bool(host_input.claimed_state().is_empty())
		. override_failure_message("the host was still following a claim mid-contact")
		. is_true()
	)


## The other half of taking a client's word for things: a claim has to be believable. This is the
## limit that stops a kart appearing on the far side of the arena, and it is the host's own
## simulation that catches it, because the host is still driving the kart anyway.
func test_a_claim_from_nowhere_is_refused() -> void:
	await _connect()
	_input.throttle = 1.0
	await _drive(30)
	var host_input := _host.slots[0].input as NetInput
	var was_at := _host.kart_of(0).global_position
	var bogus := KartPrediction.capture(_prediction.kart)
	bogus[0] = float(bogus[0]) + 12.0
	host_input.receive(NetInput.encode(_input), host_input.last_seq + 1, bogus)
	await _drive(6)
	_running = false
	(
		assert_float(_host.kart_of(0).global_position.distance_to(was_at))
		. override_failure_message("a kart was moved twelve meters by asking")
		. is_less(3.0)
	)
	(
		assert_float(host_input.denied_left)
		. override_failure_message("the host kept taking that client's word for things")
		. is_greater(0.0)
	)


## A turbo pad shoves the kart on the tick it drives onto the arrow, GAME.md 10.3. A pad is
## painted on the floor and is in the same place on both machines, which makes it as safe to
## predict against as a wall. Left to the host, the shove arrived a round trip late and then lost
## to this machine's own answer about where the kart was, which is to say it never arrived.
func test_a_turbo_pad_shoves_the_kart_this_machine_drives() -> void:
	await _connect()
	var pad: TurboPad = _client.arena.turbo_pads[0]
	# It can see a kart being driven here at all, which is where this went wrong: a predicted
	# kart sits on the puppets' layer and the pad was only looking for the host's.
	assert_int(pad.collision_mask & Layers.PUPPET).is_not_equal(0)
	var mine := _prediction.kart
	assert_bool(mine.predicted).is_true()
	# Lined up along the arrow and shoved. The shove is movement, so it happens here.
	mine.motor.heading = atan2(-pad.direction.x, -pad.direction.z)
	var heard: Array[int] = []
	var listener := func(slot: int) -> void: heard.append(slot)
	Events.turbo_taken.connect(listener)
	mine.apply_turbo(pad.direction)
	Events.turbo_taken.disconnect(listener)
	_running = false
	(
		assert_bool(mine.motor.turboing())
		. override_failure_message("the pad's shove did not reach the kart on this machine")
		. is_true()
	)
	assert_vector(mine.motor.forward_vector()).is_equal_approx(pad.direction, Vector3.ONE * 0.01)
	# And nothing is announced for it. The host drives over the same pad a moment later and its
	# word is what the room hears, so a machine announcing its own guess would say it twice.
	(
		assert_array(heard)
		. override_failure_message("a client announced its own predicted turbo")
		. is_empty()
	)
	# Somebody else's kart is drawn here where the host last said it was, a round trip ago, and
	# is not this machine's to shove about on the strength of that.
	var theirs := _client.slots[1].kart
	assert_bool(theirs.predicted).is_false()
	theirs.global_position = pad.global_position
	pad._pending.clear()
	pad._on_body_entered(theirs)
	(
		assert_int(pad._pending.size())
		. override_failure_message("this machine lined up a kart it only has a picture of")
		. is_equal(0)
	)
	pad._on_body_entered(mine)
	assert_int(pad._pending.size()).is_equal(1)


## A pop bumper's kick, GAME.md 6.2, is movement, and a bumper stands in the same place on both
## machines: the kart this machine drives is thrown off one on the tick it touches it, the host
## throws it the same way on the same claim a round trip later, and nothing is put right. Left to
## the host, a kick would have arrived a round trip late and been walked in as a correction, the
## kart seen driving into the bumper and then dragged back out of it.
func test_a_bumper_throws_the_kart_this_machine_drives_as_the_host_does() -> void:
	_layout = ArenaMaps.layout(&"vault_xl")
	await _connect()
	var bumper: Bumper = _client.arena.bumpers[1]
	var mine := _prediction.kart
	var theirs := _host.kart_of(0)
	var at := bumper.global_position + Vector3(0.0, 0.0, 4.0)
	mine.global_position = at
	theirs.global_position = at
	mine.motor.heading = 0.0
	theirs.motor.heading = 0.0
	_input.throttle = 1.0
	var thrown_here := -1
	var thrown_there := -1
	var hit_at := Vector3.ZERO
	for i: int in 150:
		await _drive(1)
		if thrown_here < 0 and mine.motor.thrown():
			thrown_here = _tick
			hit_at = mine.global_position
			# Let go, so the two come to rest and can be laid side by side.
			_input.throttle = 0.0
		if thrown_there < 0 and theirs.motor.thrown():
			thrown_there = _tick
	_running = false
	prints(
		"MEASURE bumper: thrown here at %d, host at %d;" % [thrown_here, thrown_there], _report()
	)
	assert_int(thrown_here).override_failure_message("never thrown here").is_greater(0)
	assert_int(thrown_there).override_failure_message("never thrown at the host").is_greater(0)
	assert_int(thrown_here).is_less_equal(thrown_there)
	# Thrown back the way it came, off the bumper, and at rest a couple of meters out.
	assert_float(mine.global_position.z - hit_at.z).is_greater(1.0)
	# Where it came to rest is where the host has it: the same kick, not one put right.
	(
		assert_float(mine.global_position.distance_to(theirs.global_position))
		. override_failure_message(_report())
		. is_less(KartPrediction.IGNORE)
	)
	assert_int(_prediction.snaps).is_equal(0)
	assert_float(_worst_jump).override_failure_message(_report()).is_less(0.01)
	assert_float(_worst_correction).override_failure_message(_report()).is_less(0.1)


## GAME.md 8.3: when the host puts a client's kart back, the client says so. A player who can see
## that is a player who can tell a bad connection from a bad kart, and it is the only way to know
## from inside a real match how often this is happening.
func test_a_correction_lights_the_sync_indicator() -> void:
	await _connect()
	_input.throttle = 1.0
	await _drive(30)
	var seen: Array[float] = []
	var snapped: Array[bool] = []
	var listener := func(meters: float, was_snap: bool) -> void:
		seen.append(meters)
		snapped.append(was_snap)
	Events.kart_corrected.connect(listener)
	# Knocked well out of place, which is the loud kind.
	_prediction.kart.global_position += Vector3(4.0, 0.0, 0.0)
	await _drive(20)
	_running = false
	Events.kart_corrected.disconnect(listener)
	(
		assert_int(seen.size())
		. override_failure_message("a correction happened and nothing said so")
		. is_greater(0)
	)
	assert_float(seen[0]).is_greater(KartPrediction.IGNORE)


## Pulling the trigger, GAME.md 10.3. The bullet is the host's, because whether it lives depends
## on somebody else's bullet this machine only sees where they were a round trip ago. Everything
## about the trigger a player can feel is not: the cannon goes on cooldown and the shot is heard
## on the tick the button goes down.
func test_the_trigger_answers_at_once_and_the_bullet_comes_from_the_host() -> void:
	await _connect()
	_input.throttle = 1.0
	await _drive(20)
	var heard: Array[int] = []
	var listener := func(slot: int) -> void: heard.append(slot)
	Events.bullet_fired.connect(listener)
	assert_float(_prediction.kart.cannon.cooldown_left).is_equal_approx(0.0, 0.001)
	assert_int(_host.kart_of(0).cannon.live_count()).is_equal(0)
	_input.fire = true
	await _drive(1)
	Events.bullet_fired.disconnect(listener)
	# Heard here, on the tick, and the cannon is on cooldown for it.
	(
		assert_int(heard.size())
		. override_failure_message("the trigger made no sound until the host answered")
		. is_greater(0)
	)
	(
		assert_float(_prediction.kart.cannon.cooldown_left)
		. override_failure_message("the cannon was still ready after firing")
		. is_greater(0.0)
	)
	# And no bullet here: this machine does not get to decide there is one.
	assert_int(_client.puppet_bullets.size()).is_equal(0)
	# The host fires it a round trip later, and it arrives as a puppet like everybody else's.
	await _drive(30)
	_running = false
	(
		assert_int(_host.kart_of(0).cannon.live_count())
		. override_failure_message("the host never fired the shot")
		. is_greater(0)
	)


## The cap on bullets in the air refuses a shot past it, GAME.md 5.1, and a client cannot count
## them itself: it has no bullets of its own. So the host says how many are up and this machine
## counts the ones it has pulled since against the same limit, which makes it cautious: held down
## against a full sky it stops answering and leaves it to the host, because the count it is
## working from is a round trip old and a shot promised and not delivered is worse than one that
## arrives late. The host's word comes after: a shot it fired is heard then, and a shot it refused
## clicks dry here as it would on the host.
func test_a_client_holds_itself_to_the_bullet_limit() -> void:
	await _connect()
	await _drive(20)
	var cap := _prediction.kart.cannon.current_stats().max_live_bullets
	assert_int(cap).is_greater(0)
	# The bot across the table is stood down: shot dead part way, the kart would stop firing on
	# the host while this wire, which has no seat to suspend the prediction, went on pulling.
	_host.kart_of(1).input = KartInput.new()
	# Counted on the prediction itself. Both matches share one Events, so listening for the shot
	# would hear the host's as well and this is about what this machine decided on its own.
	_input.fire = true
	var most_up := 0
	var jams := [0]
	var heard := func(slot: int) -> void:
		if slot == _prediction.kart.slot:
			jams[0] += 1
	Events.cannon_jammed.connect(heard)
	for i: int in 180:
		await _drive(1)
		most_up = maxi(most_up, _host.kart_of(0).cannon.live_count())
	Events.cannon_jammed.disconnect(heard)
	_running = false
	var pulled := _prediction.pulls
	var host_pulls := int(_host.slots[0].stats.value(&"bullets"))
	prints(
		(
			"MEASURE trigger: %d pulled here, %d on the host, most in the air %d of %d"
			% [pulled, host_pulls, most_up, cap]
		)
	)
	assert_int(pulled).override_failure_message("the trigger did nothing").is_greater_equal(cap)
	(
		assert_int(most_up)
		. override_failure_message(
			"the host had %d bullets up against a cap of %d" % [most_up, cap]
		)
		. is_less_equal(cap)
	)
	# Never ahead of the host by more than the shots a round trip holds: past that a player would
	# hear a cannon their kart is not firing, which is the one thing this must not do.
	assert_int(jams[0]).override_failure_message("a full sky said nothing").is_greater(0)
	(
		assert_int(pulled)
		. override_failure_message("%d pulled here against %d on the host" % [pulled, host_pulls])
		. is_less_equal(host_pulls + 2)
	)
