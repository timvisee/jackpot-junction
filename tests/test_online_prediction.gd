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
## Ticks each way. Three is 100 ms of round trip, four times the 25 ms the report was about.
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
## What the run cost: how far the two machines ever drifted apart, how often that needed putting
## right, how big the worst one was, and how many ticks the deepest replay had to run.
var _worst_gap := 0.0
var _snapshots := 0
var _corrections := 0
var _worst_correction := 0.0
var _deepest_replay := 0
## The worst single tick of movement the kart made that its own speed does not account for: what
## a correction actually looks like from the seat, in metres. A kart driving smoothly reads zero
## here however much it is being corrected underneath.
var _worst_jump := 0.0
var _worst_turn := 0.0
## The tick the throttle went down, and the tick each machine's kart first moved for it. The
## difference between those two is the thing the whole exercise is about.
var _asked_at := -1
var _moved_here_at := -1
var _moved_there_at := -1


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
	_drop_one_in = 0


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
	_host.with_hud = false
	_host.offer_size = 0
	_runner = scene_runner(_host)
	var inputs: Array[KartInput] = [NetInput.new(), BotInput.new()]
	_host.start(inputs, 23)
	_client = auto_free(MATCH_SCENE.instantiate())
	_client.rules = _rules()
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
	var seq := _prediction.predict(_input, TICK)
	if _drop_one_in <= 0 or seq % _drop_one_in != 0:
		_up.append({"at": _tick + LAG, "seq": seq, "state": NetInput.encode(_input)})
	var host_input := _host.slots[0].input as NetInput
	for packet: Dictionary in _up.duplicate():
		if packet["at"] <= _tick:
			host_input.receive(packet["state"], packet["seq"])
			_up.erase(packet)
	if _tick % SNAPSHOT_EVERY == 0:
		(
			_down
			. append(
				{
					"at": _tick + LAG,
					"ack": host_input.applied_seq,
					"state": KartPrediction.capture(_host.kart_of(0)),
					"snapshot": _host.build_snapshot(),
				}
			)
		)
	for packet: Dictionary in _down.duplicate():
		if packet["at"] <= _tick:
			_snapshots += 1
			_client.apply_snapshot(packet["snapshot"])
			_prediction.reconcile(packet["ack"], packet["state"], TICK)
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
			"gap %.3f m, %d of %d snapshots corrected, worst %.3f m over %d ticks, "
			+ "worst unexplained jump %.4f m and %.2f deg"
		)
		% [
			_worst_gap,
			_corrections,
			_snapshots,
			_worst_correction,
			_deepest_replay,
			_worst_jump,
			rad_to_deg(_worst_turn),
		]
	)


## The whole point, as a number: how many ticks pass between the throttle going down and the
## kart moving. On this machine it has to be the same tick. On the host it cannot be, because the
## packet is still travelling, and that gap is exactly what a player used to sit through.
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
			"the host answered in %d ticks, expected at least %d" % [there, LAG]
		)
		. is_greater_equal(LAG)
	)


## Prediction is worth nothing if it wanders off. Driving hard for a few seconds, the kart on the
## client has to still be the kart on the host, and the corrections that keep it there have to be
## rare and small rather than a running argument.
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
	var round_trip := float(LAG * 2 + SNAPSHOT_EVERY) * TICK
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
## right. Nothing in the game moves a kart four metres sideways, so this does it by hand, which
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
		. override_failure_message("nothing noticed the kart was four metres out")
		. is_greater(0)
	)
	(
		assert_float(_prediction.kart.global_position.distance_to(_host.kart_of(0).global_position))
		. override_failure_message(_report())
		. is_less(1.5)
	)
	# This one is meant to show. Four metres out is a kart somewhere it is not, and gliding it
	# back across the room would be stranger to watch than arriving. Some of it is still walked
	# off rather than all of it landing at once.
	assert_float(_worst_jump).override_failure_message(_report()).is_greater(1.0)
	assert_float(_worst_jump).override_failure_message(_report()).is_less(
		knocked - KartPrediction.EASE_MAX + 0.1
	)


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
