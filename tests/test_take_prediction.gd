extends GdUnitTestSuite
## What a client's own kart takes off the table, seen there first, GAME.md 10.3: chips, boxes and
## the Royal Flush pads, taken the tick the kart gets to them, held against the snapshots built
## before the host heard, settled by the host's word, and put back when the host never agrees. A
## host and a puppet match in one process, as test_online_sync.gd has them.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _host: Match
var _client: Match
var _runner: GdUnitSceneRunner
var _prediction: KartPrediction
var _takes: TakePrediction


func _rules() -> MatchRules:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 50.0
	return rules


## A running match on the host, a client that has heard it, and the client driving slot 0.
func _start() -> void:
	_host = auto_free(MATCH_SCENE.instantiate())
	_host.rules = _rules()
	_host.with_hud = false
	_runner = scene_runner(_host)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	_host.start(inputs, 91)
	await _runner.simulate_frames(20, 17)
	_client = auto_free(MATCH_SCENE.instantiate())
	_client.rules = _rules()
	_client.with_hud = false
	add_child(_client)
	_client.start_puppet()
	_client.apply_snapshot(_host.build_snapshot())
	_prediction = KartPrediction.new(_client.slots[0].kart)
	_takes = TakePrediction.new()


## The client's kart put at [param at], as driving there would, and a tick of what it takes.
func _drive_to(at: Vector3) -> void:
	var kart := _prediction.kart
	kart.global_position = Vector3(at.x, 0.0, at.z)
	_takes.step(_client, _prediction, 1.0 / 60.0)


## Somewhere on the floor clear of the host's karts, which would otherwise take it on the host.
func _clear_spot(offset: Vector3) -> Vector3:
	var center := (
		_host.arena.junction.global_position if _host.arena.junction != null else Vector3()
	)
	return center + offset


func _flights() -> int:
	var count := 0
	for node: Node in _client.arena.pickups.get_children():
		if node is PickupFlight:
			count += 1
	return count


## A chip is into the kart the tick the kart gets to it, and stays gone through the snapshots the
## host built before it heard; once the host says it is gone there is nothing left to fly twice.
func test_a_chip_is_taken_at_once_and_the_host_settles_it() -> void:
	await _start()
	var chip := Chip.new()
	_host.arena.place_drop(chip, _clear_spot(Vector3(4.0, 0.0, 3.0)))
	await _runner.simulate_frames(2, 17)
	_client.apply_snapshot(_host.build_snapshot())
	var id := chip.get_instance_id()
	var mine: Pickup = _client.puppet_pickups[id]
	var before := _flights()
	_drive_to(mine.global_position)
	assert_bool(mine.predicted_take()).override_failure_message("the chip was not taken").is_true()
	assert_int(_flights() - before).is_greater(0)
	# The host has not heard yet and goes on listing it.
	for i: int in 4:
		await _runner.simulate_frames(2, 17)
		_client.apply_snapshot(_host.build_snapshot())
	assert_bool(is_instance_valid(mine)).is_true()
	assert_bool(mine.predicted_take()).is_true()
	assert_bool(mine._visual == null).override_failure_message("the chip came back").is_true()
	# Taken on the host, it says so, and nothing flies a second time.
	var flying := _flights()
	chip.queue_free()
	await _runner.simulate_frames(2, 17)
	_client.apply_snapshot(_host.build_snapshot())
	assert_bool(_client.puppet_pickups.has(id)).is_false()
	assert_int(_flights()).is_less_equal(flying)


## A chip the host never gives this kart is back on the floor once the wait for it has run out.
func test_a_chip_the_host_never_agrees_on_comes_back() -> void:
	await _start()
	var chip := Chip.new()
	_host.arena.place_drop(chip, _clear_spot(Vector3(-4.0, 0.0, 3.0)))
	await _runner.simulate_frames(2, 17)
	_client.apply_snapshot(_host.build_snapshot())
	var mine: Pickup = _client.puppet_pickups[chip.get_instance_id()]
	_drive_to(mine.global_position)
	assert_bool(mine.predicted_take()).is_true()
	_prediction.kart.global_position += Vector3(0.0, 0.0, 6.0)
	await _runner.simulate_frames(80, 17)
	assert_bool(mine.predicted_take()).is_false()
	assert_bool(mine._visual != null).override_failure_message("the chip never came back").is_true()
	# Out of reach, nothing is taken; within it, it can be again.
	_takes.step(_client, _prediction, 1.0 / 60.0)
	assert_bool(mine.predicted_take()).is_false()
	_drive_to(mine.global_position)
	assert_bool(mine.predicted_take()).is_true()


## A kart takes one box at a time: the second waits for the host to say what was in the first.
func test_one_box_at_a_time() -> void:
	await _start()
	var first := ItemBox.new()
	first.fixed_item = (load("res://data/powerups/all.tres") as PowerUpTable).entries[0]
	var second := ItemBox.new()
	second.fixed_item = first.fixed_item
	_host.arena.place_drop(first, _clear_spot(Vector3(4.0, 0.0, -3.0)))
	_host.arena.place_drop(second, _clear_spot(Vector3(4.6, 0.0, -3.0)))
	await _runner.simulate_frames(2, 17)
	_client.apply_snapshot(_host.build_snapshot())
	var one: Pickup = _client.puppet_pickups[first.get_instance_id()]
	var two: Pickup = _client.puppet_pickups[second.get_instance_id()]
	_drive_to(one.global_position.lerp(two.global_position, 0.5))
	assert_int(int(one.predicted_take()) + int(two.predicted_take())).is_equal(1)


## A pad is this client's the tick it drives on, in its color, through the snapshots built before
## the host heard, and the host's word settles it either way: its own claim, the pads cleared for
## a flush, or, after the wait, nobody's claim at all.
func test_a_pad_is_claimed_at_once_and_the_host_settles_it() -> void:
	await _start()
	var pad: FlushPad = _client.arena.flush_pads[0]
	var color := Palette.player_color(_prediction.kart.color_index)
	_drive_to(pad.global_position)
	assert_bool(pad.predicted_claim()).override_failure_message("the pad was not taken").is_true()
	assert_int(pad.owner_slot).is_equal(0)
	assert_that(pad.owner_color).is_equal(color)
	_prediction.kart.global_position += Vector3(0.0, 0.0, 8.0)
	for i: int in 4:
		await _runner.simulate_frames(2, 17)
		_client.apply_snapshot(_host.build_snapshot())
	assert_int(pad.owner_slot).override_failure_message("a snapshot took the pad back").is_equal(0)
	# The host agrees.
	_host.arena.flush_pads[0].claim(0, color)
	_client.apply_snapshot(_host.build_snapshot())
	assert_bool(pad.predicted_claim()).is_false()
	assert_int(pad.owner_slot).is_equal(0)
	# Taken again by this kart it is only renewed, which is the host's to do.
	_drive_to(pad.global_position)
	assert_bool(pad.predicted_claim()).is_false()
	# One the host never agrees to is nobody's again once the wait is over.
	var other: FlushPad = _client.arena.flush_pads[1]
	_drive_to(other.global_position)
	assert_bool(other.predicted_claim()).is_true()
	_prediction.kart.global_position += Vector3(0.0, 0.0, 8.0)
	_client.apply_snapshot(_host.build_snapshot())
	await _runner.simulate_frames(80, 17)
	# Back as the host last had it the moment the wait runs out, not a snapshot later.
	assert_bool(other.predicted_claim()).is_false()
	assert_int(other.owner_slot).is_equal(-1)
	_client.apply_snapshot(_host.build_snapshot())
	assert_int(other.owner_slot).is_equal(-1)
	# And pads cleared for a flush are cleared at once, whatever this client thought.
	var third: FlushPad = _client.arena.flush_pads[2]
	_drive_to(third.global_position)
	assert_bool(third.predicted_claim()).is_true()
	for host_pad: FlushPad in _host.arena.flush_pads:
		host_pad.clear_and_disable(5.0)
	_client.apply_snapshot(_host.build_snapshot())
	assert_int(third.owner_slot).is_equal(-1)
	assert_bool(third.is_disabled()).is_true()


## A sound played ahead of the host is heard once: the host's word for the same thing, for the same
## slot, is counted off, and anybody else's is heard as ever.
func test_a_sound_played_ahead_is_not_heard_again() -> void:
	Audio._ahead.clear()
	Audio.ahead(&"pad_claimed", [2])
	Audio.ahead(&"pad_claimed", [2])
	assert_bool(Audio._heard_ahead(&"pad_claimed", 1)).is_false()
	assert_bool(Audio._heard_ahead(&"pad_claimed", 2)).is_true()
	assert_bool(Audio._heard_ahead(&"pad_claimed", 2)).is_true()
	assert_bool(Audio._heard_ahead(&"pad_claimed", 2)).is_false()
	Audio.ahead(&"coin_collected", [1, 1])
	assert_bool(Audio._heard_ahead(&"item_picked", 1)).is_false()
	assert_bool(Audio._heard_ahead(&"coin_collected", 1)).is_true()
	# Waited for only so long: a word that never came does not silence the next.
	Audio.ahead(&"item_picked", [3, &""])
	Audio._ahead["item_picked|3"] = Vector2i(1, Time.get_ticks_msec() - 1)
	assert_bool(Audio._heard_ahead(&"item_picked", 3)).is_false()
	Audio._ahead.clear()
