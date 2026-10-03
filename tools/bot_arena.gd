extends GdUnitTestSuite
## Development harness: runs whole matches of bots and reports what they achieved, so "are the
## bots any good" is a number rather than an impression. Several seeds, because one match of
## four bots is mostly luck. Not part of the design, and not a check of it either.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DEFAULT_RULES: MatchRules = preload("res://data/match/default.tres")
const SECONDS := 150.0
const SEEDS: Array[int] = [4242, 77, 1315]
## Throttle at or below which a bot is taken to be backing off for a hole rather than driving.
const PIT_THROTTLE_MARK := 0.3


func test_seed_a() -> void:
	await _one("hard", SEEDS[0])


func test_seed_b() -> void:
	await _one("hard", SEEDS[1])


func test_seed_c() -> void:
	await _one("hard", SEEDS[2])


## One match, printed as a line the aggregator outside picks up. A test may run for five
## minutes, so one match per test rather than all of them in one.
func _one(difficulty: String, seed: int) -> void:
	var out := await _run(difficulty, seed)
	var line := "ARENA %s %d" % [difficulty, seed]
	for key: String in [
		"banked",
		"banks",
		"coins",
		"jackpot",
		"pads",
		"flushes",
		"kills",
		"deaths",
		"lost",
		"mult",
		"driven",
		"pits",
		"selfies",
		"boosts",
		"fell_reversing",
		"fell_avoiding",
		"fell_driving",
		"fall_speed",
		"lock_reversing",
		"lock_dodging",
		"lock_pit",
		"lock_driving",
		"speed",
		"steer",
		"walled",
		"full_lock",
		"samples",
	]:
		line += " %s=%.4f" % [key, out[key]]
	print(line)


func _run(difficulty: String, seed: int) -> Dictionary:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = SECONDS + 30.0
	# Nothing may end the match before the clock this harness is watching does.
	rules.target_score = 1 << 30
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 3
	match_node.bot_difficulty = load("res://data/ai/%s.tres" % difficulty)
	var runner := scene_runner(match_node)
	var inputs: Array[KartInput] = []
	for i: int in 4:
		inputs.append(BotInput.new())
	match_node.start(inputs, seed)
	# How a bot came to be over the hole, sampled the moment it goes in.
	var falls: Dictionary[String, float] = {"reversing": 0.0, "avoiding": 0.0, "driving": 0.0}
	var fall_speed := 0.0
	var fell := 0.0
	var watch := func(slot_index: int) -> void:
		if slot_index < 0 or slot_index >= match_node.slots.size():
			return
		var who: Variant = match_node.slots[slot_index].kart
		if who == null or not is_instance_valid(who):
			return
		var k: Kart = who
		var b: BotBrain = k.get_node_or_null("Brain")
		if b == null:
			return
		fell += 1.0
		fall_speed += k.motor.speed()
		print(
			(
				"FALL at (%.1f, %.1f) goal=%s throttle=%.2f brake=%.2f hold=%s rev=%.2f junction=%.1f"
				% [
					k.global_position.x,
					k.global_position.z,
					b.goal,
					b.input.throttle,
					b.input.brake,
					b.holding_position(),
					b.stuck._reverse_left,
					k.global_position.distance_to(match_node.arena.junction_position),
				]
			)
		)
		if b.stuck.maneuvering():
			falls["reversing"] += 1.0
		elif b.input.throttle <= PIT_THROTTLE_MARK:
			falls["avoiding"] += 1.0
		else:
			falls["driving"] += 1.0
	Events.kart_fell.connect(watch)
	var speed := 0.0
	var steer := 0.0
	var walled := 0.0
	var full_lock := 0.0
	var samples := 0.0
	var lock_reversing := 0.0
	var lock_dodging := 0.0
	var lock_pit := 0.0
	var lock_driving := 0.0
	# Driven by the match clock rather than by a frame count: a rendered frame carries however
	# many physics steps the last one happened to take, so counting frames measures a different
	# slice of the match every run and no two readings can be held against each other.
	# Out of the countdown first: the clock this loop watches only runs once the flag drops.
	while match_node.state == Match.State.COUNTDOWN:
		await runner.simulate_frames(1, 1)
	var guard := 0
	while rules.duration - match_node.time_left < SECONDS and match_node.is_running():
		guard += 1
		if guard > 60000:
			break
		await runner.simulate_frames(1, 1)
		for i: int in mini(4, match_node.slots.size()):
			# Read as a plain value first: a kart can be freed between frames, and putting a
			# freed instance into a typed variable is itself the error.
			var maybe: Variant = match_node.slots[i].kart
			if maybe == null or not is_instance_valid(maybe):
				continue
			var kart: Kart = maybe
			if not kart.is_active():
				continue
			var brain: BotBrain = kart.get_node_or_null("Brain")
			if brain == null:
				continue
			samples += 1.0
			speed += kart.motor.speed()
			steer += absf(brain.input.steer)
			walled += 1.0 if kart.touching_wall else 0.0
			if absf(brain.input.steer) > 0.9:
				full_lock += 1.0
				if brain.stuck.maneuvering():
					lock_reversing += 1.0
				elif brain._dodge_left > 0.0:
					lock_dodging += 1.0
				elif brain.input.brake > 0.5:
					lock_pit += 1.0
				else:
					lock_driving += 1.0
	Events.kart_fell.disconnect(watch)
	var out: Dictionary = {
		"fell_reversing": falls["reversing"],
		"fell_avoiding": falls["avoiding"],
		"fell_driving": falls["driving"],
		"fall_speed": fall_speed / maxf(fell, 1.0),
		"speed": speed / maxf(samples, 1.0),
		"steer": steer / maxf(samples, 1.0),
		"walled": walled / maxf(samples, 1.0),
		"full_lock": full_lock / maxf(samples, 1.0),
		"samples": samples,
		"lock_reversing": lock_reversing / maxf(samples, 1.0),
		"lock_dodging": lock_dodging / maxf(samples, 1.0),
		"lock_pit": lock_pit / maxf(samples, 1.0),
		"lock_driving": lock_driving / maxf(samples, 1.0),
		"banked": 0.0,
		"banks": 0.0,
		"coins": 0.0,
		"jackpot": 0.0,
		"pads": 0.0,
		"flushes": 0.0,
		"kills": 0.0,
		"deaths": 0.0,
		"lost": 0.0,
		"mult": 0.0,
		"driven": 0.0,
		"pits": 0.0,
		"selfies": 0.0,
		"boosts": 0.0,
	}
	for slot: PlayerSlot in match_node.slots:
		out["banked"] += slot.banked
		out["kills"] += slot.kills
		out["deaths"] += slot.deaths
		out["banks"] += slot.stats.value(&"banks")
		out["coins"] += slot.stats.value(&"coins")
		out["jackpot"] += slot.stats.value(&"jackpot_chips")
		out["pads"] += slot.stats.value(&"pads_taken")
		out["flushes"] += slot.stats.value(&"flushes")
		out["lost"] += slot.stats.value(&"coins_lost")
		out["mult"] += slot.stats.value(&"max_mult")
		out["driven"] += slot.stats.value(&"driven")
		out["pits"] += slot.stats.value(&"pit_deaths")
		out["selfies"] += slot.stats.value(&"self_kills")
		out["boosts"] += slot.stats.value(&"drift_boosts")
	return out
