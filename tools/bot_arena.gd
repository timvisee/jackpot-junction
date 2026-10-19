extends GdUnitTestSuite
## Development harness: runs one whole match of bots and reports what each of them achieved, so
## "are the bots any good" is a number rather than an impression. Not part of the design, and not
## a check of it either. `tools/bot_arena` runs it once per level and seed, several at once, and
## adds the lines up; everything it is told comes in through the environment:
##
##   BOT_LEVEL     the difficulty, easy, normal or hard
##   BOT_SEED      the match's seed
##   BOT_MAP       a map other than the default one
##   BOT_SECONDS   how much of the match clock to watch, 150 unless it says
##   BOT_MIRROR    items,nitro,drift: the players' habits the bots read, GAME.md 9.1, all nought
##                 unless it says, which is a room of bots and nobody to copy
##   BOT_OLD_DIR   a directory of another brain's scripts, see tools/bot_arena, and
##   BOT_OLD_SEATS the seats that drive with it, for a match of one brain against another
##   BOT_COST      1 to time every brain's tick, which steps the brains from here rather than
##                 from their own nodes, in the same place in the frame
##   BOT_TRACE     1 to print the last ticks of a bot before it falls down a hole, gets stuck or
##                 sits still for a second and a half, and what the stalled ones were doing;
##                 BOT_TRACE_DRIVE=1 as well prints every tick of the first seat

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DEFAULT_RULES: MatchRules = preload("res://data/match/default.tres")
const SECONDS := 150.0
const KARTS := 4
## The goals a share of the time is reported for, GAME.md 9.1.
const GOALS: Array[StringName] = [
	&"wander",
	&"collect",
	&"hunt",
	&"bank",
	&"jackpot",
	&"item",
	&"flush",
	&"slot",
	&"flee",
	&"cover",
]
## The match statistics reported for each seat as they stand at the end, GAME.md 3.8.
const STATS: Array[StringName] = [
	&"banks",
	&"coins",
	&"jackpot_chips",
	&"pads_taken",
	&"flushes",
	&"deaths",
	&"coins_lost",
	&"max_mult",
	&"driven",
	&"pit_deaths",
	&"self_kills",
	&"drift_boosts",
	&"bullets",
	&"hits",
	&"items",
	&"jokers",
	&"nitro",
	&"turbo_pads",
	&"grazes",
	&"crates",
	&"targets",
	&"bounties",
	&"rams",
	&"oil_spins",
	&"bomb_kills",
]
## Farther than this in one tick, alive all the while, is a kart put down somewhere else.
const JUMP := 3.0
## How many ticks of each seat BOT_TRACE=1 keeps, to print when it falls down a hole.
const RECENT := 50

## The last few ticks of each seat, for BOT_TRACE.
var _recent: Array[PackedStringArray] = []
## Seconds stalled, by what the bot was doing, for BOT_TRACE.
var _stalls: Dictionary[String, float] = {}


## Steps every brain in turn in the brains' own place in the frame, before the karts, and adds up
## how long each one took, for BOT_COST.
class BrainClock:
	extends Node

	var brains: Array[Node] = []
	var spent: Array[int] = []
	var ticks: Array[int] = []

	func _ready() -> void:
		process_physics_priority = -1

	func _physics_process(delta: float) -> void:
		for i: int in brains.size():
			var brain := brains[i]
			if not is_instance_valid(brain):
				continue
			var began := Time.get_ticks_usec()
			brain.call(&"_physics_process", delta)
			spent[i] += Time.get_ticks_usec() - began
			ticks[i] += 1


func test_match() -> void:
	var level := OS.get_environment("BOT_LEVEL")
	if level.is_empty():
		level = "hard"
	var seed := int(OS.get_environment("BOT_SEED")) if OS.has_environment("BOT_SEED") else 4242
	var rows := await _run(level, seed)
	for row: Dictionary in rows:
		var line := "ARENA %s %d" % [level, seed]
		for key: String in row.keys():
			var value: Variant = row[key]
			if value is String or value is StringName:
				line += " %s=%s" % [key, value]
			else:
				line += " %s=%.4f" % [key, float(value)]
		print(line)


func _run(level: String, seed: int) -> Array[Dictionary]:
	var seconds := SECONDS
	if OS.has_environment("BOT_SECONDS"):
		seconds = float(OS.get_environment("BOT_SECONDS"))
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = seconds + 30.0
	# Nothing may end the match before the clock this harness is watching does.
	rules.target_score = 1 << 30
	var map := StringName(OS.get_environment("BOT_MAP"))
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 3
	match_node.bot_difficulty = load("res://data/ai/%s.tres" % level)
	if not map.is_empty():
		rules.map = map
		match_node.arena_layout = ArenaMaps.layout(map)
	var runner := scene_runner(match_node)
	var inputs: Array[KartInput] = []
	for i: int in KARTS:
		inputs.append(BotInput.new())
	match_node.start(inputs, seed)
	_read_mirror(match_node)
	var old := _old_seats()
	for seat: int in old:
		_swap_brain(match_node, seat)
	var clock: BrainClock = null
	if OS.get_environment("BOT_COST") == "1":
		clock = BrainClock.new()
		for i: int in KARTS:
			clock.brains.append(_brain(match_node, i))
			clock.spent.append(0)
			clock.ticks.append(0)
			clock.brains[i].set_physics_process(false)
		match_node.add_child(clock)
	var rows: Array[Dictionary] = []
	for i: int in KARTS:
		rows.append(_blank_row(match_node, i, old))
	var listening := _listen(rows)
	# Out of the countdown first: the clock this loop watches only runs once the flag drops.
	while match_node.state == Match.State.COUNTDOWN:
		await runner.simulate_frames(1, 1)
	var last: Array[Vector3] = []
	for i: int in KARTS:
		last.append(Vector3.INF)
	var guard := 0
	while rules.duration - match_node.time_left < seconds and match_node.is_running():
		guard += 1
		if guard > 200000:
			break
		await runner.simulate_frames(1, 1)
		_sample(match_node, rows, last)
	for heard: Array in listening:
		(heard[0] as Signal).disconnect(heard[1])
	if OS.get_environment("BOT_TRACE") == "1":
		var keys := _stalls.keys()
		keys.sort_custom(func(a: String, b: String) -> bool: return _stalls[a] > _stalls[b])
		for key: String in keys.slice(0, 25):
			print("STALL %6.1f s  %s" % [_stalls[key], key])
	for i: int in KARTS:
		_finish_row(match_node, rows[i], i)
		if clock != null:
			rows[i]["cost_us"] = float(clock.spent[i]) / maxf(float(clock.ticks[i]), 1.0)
	return rows


## The players' habits the bots read, from BOT_MIRROR, GAME.md 9.1: with nobody to copy the mirror
## keeps whatever it was set to.
func _read_mirror(match_node: Match) -> void:
	var said := OS.get_environment("BOT_MIRROR").split(",", false)
	if said.size() < 3:
		return
	match_node.bot_mirror.items = float(said[0])
	match_node.bot_mirror.nitro = float(said[1])
	match_node.bot_mirror.drift = float(said[2])


func _old_seats() -> Array[int]:
	var seats: Array[int] = []
	if OS.get_environment("BOT_OLD_DIR").is_empty():
		return seats
	for part: String in OS.get_environment("BOT_OLD_SEATS").split(",", false):
		seats.append(int(part))
	return seats


## Puts the other brain at the wheel of [param seat], with the trait the seat was dealt.
func _swap_brain(match_node: Match, seat: int) -> void:
	var kart := match_node.slots[seat].kart
	var current := kart.get_node("Brain") as BotBrain
	var script: GDScript = load(OS.get_environment("BOT_OLD_DIR").path_join("bot_brain.gd"))
	var brain: Node = script.new()
	brain.call(
		&"setup", kart, match_node, current.bot_trait, current.difficulty, current.rng
	)
	current.name = "Retired"
	current.set_physics_process(false)
	current.queue_free()
	brain.name = "Brain"
	kart.add_child(brain)


func _brain(match_node: Match, seat: int) -> Node:
	var who: Variant = match_node.slots[seat].kart
	if who == null or not is_instance_valid(who):
		return null
	return (who as Kart).get_node_or_null("Brain")


func _blank_row(match_node: Match, seat: int, old: Array[int]) -> Dictionary:
	var row: Dictionary = {
		"seat": seat,
		"old": 1.0 if seat in old else 0.0,
		"trait": str(match_node.slots[seat].bot_trait.id),
		"samples": 0.0,
		"speed": 0.0,
		"walled": 0.0,
		"full_lock": 0.0,
		"stuck_s": 0.0,
		"gave_up": 0.0,
		"put_down": 0.0,
		"stalled_s": 0.0,
		"neighbor": 0.0,
		"pulls": 0.0,
		"shot_at_me": 0.0,
		"wounds": 0.0,
		"died_with": 0.0,
		"death_lost": 0.0,
		"passing_banks": 0.0,
		"passing_banked": 0.0,
		"passing_mult": 0.0,
		"fell_bumped": 0.0,
		"fell_reversing": 0.0,
		"fell_avoiding": 0.0,
		"fell_driving": 0.0,
		"_pot": 0.0,
		"_gave": 0.0,
	}
	for goal: StringName in GOALS:
		row["g_" + str(goal)] = 0.0
	return row


## The match's own events each seat is counted on.
func _listen(rows: Array[Dictionary]) -> Array[Array]:
	var pulled := func(slot: int, _pad: int, _bet: int, _faces: PackedByteArray) -> void:
		if slot >= 0 and slot < rows.size():
			rows[slot]["pulls"] += 1.0
	var shot := func(victim: int, by: int) -> void:
		if victim >= 0 and victim < rows.size() and by != victim:
			rows[victim]["shot_at_me"] += 1.0
	var wounded := func(victim: int, _by: int, _cause: StringName) -> void:
		if victim >= 0 and victim < rows.size():
			rows[victim]["wounds"] += 1.0
	var banked := func(slot: int, _amount: int, lost: int) -> void:
		if slot >= 0 and slot < rows.size():
			rows[slot]["died_with"] += rows[slot]["_pot"]
			rows[slot]["death_lost"] += float(lost)
	# How a bot came to be over the hole, the moment it goes in: shoved there by somebody, backing
	# out of something, turning out of the hole too late, or simply driving in.
	var fell := func(slot: int) -> void:
		if slot < 0 or slot >= rows.size():
			return
		var who: Variant = Kart.of_slot(Engine.get_main_loop() as SceneTree, slot)
		if who == null or not is_instance_valid(who):
			return
		var kart: Kart = who
		var brain := kart.get_node_or_null("Brain")
		if brain == null:
			return
		var input: BotInput = brain.get(&"input")
		var how := "fell_driving"
		# On the wall clock, as the kart itself credits a push into a hole.
		var since := Time.get_ticks_msec() * 0.001 - kart.last_bump_time
		if kart.last_bump_slot >= 0 and since < 0.5:
			how = "fell_bumped"
		elif (brain.get(&"stuck") as RefCounted).call(&"maneuvering"):
			how = "fell_reversing"
		elif input.throttle <= 0.3:
			how = "fell_avoiding"
		rows[slot][how] += 1.0
		if OS.get_environment("BOT_TRACE") == "1":
			print("FALL seat=%d how=%s trait=%s" % [slot, how, rows[slot]["trait"]])
			for line: String in _recent[slot]:
				print("  " + line)
	# A cash-out the bot drove onto the Junction for, or one it rolled over on its way somewhere
	# else, and the mult it gave up with it.
	var started := func(slot: int) -> void:
		if slot < 0 or slot >= rows.size():
			return
		var who: Variant = Kart.of_slot(Engine.get_main_loop() as SceneTree, slot)
		var brain: Node = (who as Kart).get_node_or_null("Brain") if who != null else null
		rows[slot]["_meant"] = 1.0 if brain != null and brain.get(&"goal") == &"bank" else 0.0
	var cashed := func(slot: int, _coins: int, mult: float, total: int) -> void:
		if slot < 0 or slot >= rows.size() or rows[slot].get("_meant", 0.0) == 1.0:
			return
		rows[slot]["passing_banks"] += 1.0
		rows[slot]["passing_banked"] += float(total)
		if mult > 1.0:
			rows[slot]["passing_mult"] += 1.0
			if OS.get_environment("BOT_TRACE") == "1" and slot < _recent.size():
				print("PASSBANK seat=%d mult=%.1f total=%d" % [slot, mult, total])
				for line: String in _recent[slot].slice(-12):
					print("  " + line)
	# What a bot was doing when it was killed, and who by, for BOT_TRACE.
	var killed := func(victim: int, killer: int, cause: StringName) -> void:
		if victim < 0 or victim >= rows.size():
			return
		var who: Variant = Kart.of_slot(Engine.get_main_loop() as SceneTree, victim)
		var brain: Node = (who as Kart).get_node_or_null("Brain") if who != null else null
		if brain != null:
			var key := "d_" + str(brain.get(&"goal"))
			rows[victim][key] = rows[victim].get(key, 0.0) + 1.0
		if OS.get_environment("BOT_TRACE") == "1" and rows[victim].get("_deaths", 0.0) < 3.0:
			rows[victim]["_deaths"] = rows[victim].get("_deaths", 0.0) + 1.0
			print("DEATH seat=%d by=%d cause=%s trait=%s" % [victim, killer, cause, rows[victim]["trait"]])
			if victim < _recent.size():
				for line: String in _recent[victim].slice(-20):
					print("  " + line)
	var heard: Array[Array] = [
		[Events.kart_killed, killed],
		[Events.bank_started, started],
		[Events.bank_completed, cashed],
		[Events.kart_fell, fell],
		[Events.slot_spun, pulled],
		[Events.kart_shot, shot],
		[Events.kart_wounded, wounded],
		[Events.death_banked, banked],
	]
	for one: Array in heard:
		(one[0] as Signal).connect(one[1])
	return heard


## One tick's look at every seat.
func _sample(match_node: Match, rows: Array[Dictionary], last: Array[Vector3]) -> void:
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	for i: int in KARTS:
		# Read as a plain value first: a kart can be freed between frames, and putting a freed
		# instance into a typed variable is itself the error.
		var maybe: Variant = match_node.slots[i].kart
		if maybe == null or not is_instance_valid(maybe):
			continue
		var kart: Kart = maybe
		var brain := kart.get_node_or_null("Brain")
		if not kart.is_active() or brain == null:
			last[i] = Vector3.INF
			continue
		var row := rows[i]
		row["_pot"] = float(kart.pot.value())
		if last[i] != Vector3.INF and kart.global_position.distance_to(last[i]) > JUMP:
			row["put_down"] += 1.0
		last[i] = kart.global_position
		row["samples"] += 1.0
		row["speed"] += kart.motor.speed()
		row["walled"] += 1.0 if kart.touching_wall else 0.0
		var input: BotInput = brain.get(&"input")
		row["full_lock"] += 1.0 if absf(input.steer) > 0.9 else 0.0
		var stuck: RefCounted = brain.get(&"stuck")
		if stuck.call(&"maneuvering"):
			row["stuck_s"] += tick
			if (
				OS.get_environment("BOT_TRACE") == "1"
				and row.get("_was_stuck", 0.0) == 0.0
				and row.get("_stuck_dumps", 0.0) < 4.0
			):
				row["_stuck_dumps"] = row.get("_stuck_dumps", 0.0) + 1.0
				print("STUCK seat=%d trait=%s wall=%s" % [i, row["trait"], kart.touching_wall])
				for line: String in _recent[i].slice(-25):
					print("  " + line)
			row["_was_stuck"] = 1.0
		else:
			row["_was_stuck"] = 0.0
		var gave: bool = stuck.call(&"gave_up")
		if gave and row["_gave"] == 0.0:
			row["gave_up"] += 1.0
		row["_gave"] = 1.0 if gave else 0.0
		if kart.motor.speed() < 0.5 and not brain.call(&"holding_position"):
			row["stalled_s"] += tick
			if OS.get_environment("BOT_TRACE") == "1":
				var near := 99.0
				for j: int in KARTS:
					var other: Variant = match_node.slots[j].kart
					if j != i and other != null and is_instance_valid(other):
						near = minf(near, kart.global_position.distance_to(other.global_position))
				var why := "%s thr=%.1f brk=%.1f man=%s wall=%s kart<2=%s prot=%s" % [
					brain.get(&"goal"),
					input.throttle,
					input.brake,
					stuck.call(&"maneuvering"),
					kart.touching_wall,
					near < 2.0,
					kart.protection_left > 0.0,
				]
				_stalls[why] = _stalls.get(why, 0.0) + tick
				row["_stalled_run"] = row.get("_stalled_run", 0.0) + tick
				if row["_stalled_run"] > 1.5 and row.get("_dumped", 0.0) < 3.0:
					row["_dumped"] = row.get("_dumped", 0.0) + 1.0
					row["_stalled_run"] = -1000.0
					print("STALLED seat=%d trait=%s" % [i, row["trait"]])
					for line: String in _recent[i]:
						print("  " + line)
		else:
			row["_stalled_run"] = 0.0
		if OS.get_environment("BOT_TRACE") == "1":
			_trace(i, kart, brain, input)
		var key := "g_" + str(brain.get(&"goal"))
		if row.has(key):
			row[key] += 1.0
		var nearest := INF
		for j: int in KARTS:
			var other: Variant = match_node.slots[j].kart
			if j == i or other == null or not is_instance_valid(other):
				continue
			if (other as Kart).is_active():
				nearest = minf(nearest, kart.global_position.distance_to(other.global_position))
		row["neighbor"] += nearest if nearest < INF else 0.0


## Keeps this tick of [param seat] for BOT_TRACE.
func _trace(seat: int, kart: Kart, brain: Node, input: BotInput) -> void:
	while _recent.size() <= seat:
		_recent.append(PackedStringArray())
	var target: Vector3 = brain.get(&"target")
	var line := (
		"pos=(%.1f,%.1f) vel=(%.1f,%.1f) hd=%.2f goal=%s tgt=(%.1f,%.1f) st=%.2f th=%.2f br=%.2f hb=%s"
		% [
			kart.global_position.x,
			kart.global_position.z,
			kart.motor.velocity.x,
			kart.motor.velocity.z,
			kart.motor.heading,
			brain.get(&"goal"),
			target.x,
			target.z,
			input.steer,
			input.throttle,
			input.brake,
			input.handbrake,
		]
	)
	var driver: Object = brain.get(&"drive") if &"drive" in brain else brain
	var path: PackedVector3Array = driver.get(&"_path")
	var at: int = driver.get(&"_path_index")
	if at < path.size():
		var to := path[at] - kart.global_position
		line += " wp=%d/%d d=%.1f ang=%.2f" % [
			at, path.size(), to.length(),
			kart.motor.forward_vector().signed_angle_to(Vector3(to.x, 0, to.z), Vector3.UP)
		]
	if seat == 0 and OS.get_environment("BOT_TRACE_DRIVE") == "1":
		print("DRIVE " + line)
	_recent[seat].append(line)
	if _recent[seat].size() > RECENT:
		_recent[seat].remove_at(0)


func _finish_row(match_node: Match, row: Dictionary, seat: int) -> void:
	var slot := match_node.slots[seat]
	var samples := maxf(row["samples"], 1.0)
	for key: String in ["speed", "walled", "full_lock", "neighbor"]:
		row[key] = row[key] / samples
	for goal: StringName in GOALS:
		row["g_" + str(goal)] = row["g_" + str(goal)] / samples
	row["banked"] = float(slot.banked)
	row["kills"] = float(slot.kills)
	row["end_pot"] = row["_pot"]
	for stat: StringName in STATS:
		row[str(stat)] = slot.stats.value(stat)
	row.erase("_pot")
	row.erase("_gave")
	row.erase("_stalled_run")
	row.erase("_dumped")
	row.erase("_was_stuck")
	row.erase("_meant")
	row.erase("_deaths")
	row.erase("_stuck_dumps")
