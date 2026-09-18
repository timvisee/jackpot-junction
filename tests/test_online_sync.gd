extends GdUnitTestSuite
## Whether a client is looking at the same match as the host, GAME.md 10.3. A host runs a room
## full of bots and a puppet match is fed its snapshots; every number either machine shows a
## player has to agree, all the way through. Anything the host keeps and the snapshot leaves
## out turns up here as a difference rather than as a bug report from a play session.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")


func _rules() -> MatchRules:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 50.0
	return rules


## Every difference between the two matches, as readable lines. Empty means they agree.
func _differences(host: Match, client: Match) -> Array[String]:
	var out: Array[String] = []
	var check := func(what: String, a: Variant, b: Variant) -> void:
		if typeof(a) == TYPE_FLOAT or typeof(b) == TYPE_FLOAT:
			if is_equal_approx(float(a), float(b)):
				return
		elif a == b:
			return
		out.append("%s: host %s, client %s" % [what, a, b])
	check.call("state", host.state, client.state)
	check.call("time_left", host.time_left, client.time_left)
	check.call("bounty_slot", host.bounty_slot, client.bounty_slot)
	check.call("target_score", host.rules.target_score, client.rules.target_score)
	check.call("lives rule", host.rules.lives, client.rules.lives)
	check.call("duration rule", host.rules.duration, client.rules.duration)
	check.call("overtime rule", host.rules.overtime, client.rules.overtime)
	check.call(
		"payout", host.arena.junction.payout_multiplier, client.arena.junction.payout_multiplier
	)
	check.call("junction winning", host.arena.junction.winning, client.arena.junction.winning)
	check.call("slot count", host.slots.size(), client.slots.size())
	for i: int in mini(host.slots.size(), client.slots.size()):
		var a := host.slots[i]
		var b := client.slots[i]
		check.call("slot %d banked" % i, a.banked, b.banked)
		check.call("slot %d kills" % i, a.kills, b.kills)
		check.call("slot %d deaths" % i, a.deaths, b.deaths)
		check.call("slot %d colour" % i, a.color_index, b.color_index)
		check.call("slot %d score" % i, a.score(), b.score())
		for field: StringName in PlayerStats.FIELDS:
			check.call("slot %d stat %s" % [i, field], a.stats.value(field), b.stats.value(field))
		if a.kart == null or b.kart == null:
			check.call("slot %d has a kart" % i, a.kart != null, b.kart != null)
			continue
		check.call("slot %d coins" % i, a.kart.pot.coins, b.kart.pot.coins)
		check.call("slot %d mult" % i, a.kart.pot.mult, b.kart.pot.mult)
		check.call("slot %d lives" % i, a.kart.lives, b.kart.lives)
		check.call("slot %d alive" % i, a.kart.alive, b.kart.alive)
		check.call("slot %d nitro" % i, a.kart.nitro_charge, b.kart.nitro_charge)
		check.call("slot %d jokers" % i, a.kart.jokers.ids(), b.kart.jokers.ids())
		var a_item := String(a.kart.held_item.id) if a.kart.held_item != null else ""
		var b_item := String(b.kart.held_item.id) if b.kart.held_item != null else ""
		check.call("slot %d item" % i, a_item, b_item)
	for i: int in mini(host.arena.jackpot_zones.size(), client.arena.jackpot_zones.size()):
		check.call(
			"jackpot %d active" % i,
			host.arena.jackpot_zones[i].active,
			client.arena.jackpot_zones[i].active
		)
		check.call(
			"jackpot %d chips" % i,
			host.arena.jackpot_zones[i].chips,
			client.arena.jackpot_zones[i].chips
		)
	for i: int in mini(host.arena.crates.size(), client.arena.crates.size()):
		check.call("crate %d" % i, host.arena.crates[i].alive, client.arena.crates[i].alive)
	for i: int in mini(host.arena.flush_pads.size(), client.arena.flush_pads.size()):
		check.call(
			"flush pad %d owner" % i,
			host.arena.flush_pads[i].owner_slot,
			client.arena.flush_pads[i].owner_slot
		)
	for i: int in mini(host.arena.targets.size(), client.arena.targets.size()):
		check.call(
			"target %d standing" % i, host.arena.targets[i].alive, client.arena.targets[i].alive
		)
	return out


func test_a_client_sees_every_number_the_host_does() -> void:
	var host: Match = auto_free(MATCH_SCENE.instantiate())
	host.rules = _rules()
	# The hard bots, because they are the ones that actually shoot each other and cash out. A
	# quiet room is a room where two machines agree about nothing in particular.
	host.bot_difficulty = load("res://data/ai/hard.tres")
	host.with_hud = false
	var runner := scene_runner(host)
	var inputs: Array[KartInput] = [BotInput.new(), BotInput.new(), BotInput.new(), BotInput.new()]
	host.start(inputs, 91)
	# The client comes up the way a joining player's does: its own lobby settings, which are not
	# the host's, so anything it reads off its own rules rather than the host's shows up below.
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = _rules()
	client.rules.target_score = 777
	client.rules.duration = 60.0
	client.rules.overtime = false
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	client.set_local_slot(0)
	# What a session does the moment a client is let in, before it hands out a slot.
	client.rules.from_wire(host.rules.to_wire())
	# Forty seconds of hard bots at each other, sampled the way the wire samples it. The clock is
	# set so the run crosses into Last Call, which doubles the Junction's payout: a number the
	# host owns and the client draws with. Compared
	# every time rather than only at the whistle: a target lying on its face, a crate in pieces
	# or a pot mid-cash-out is all state that comes and goes, and a difference that heals itself
	# before the end is still a difference somebody watched.
	var seen: Dictionary[String, bool] = {}
	for i: int in 600:
		await runner.simulate_frames(4, 17)
		client.apply_snapshot(host.build_snapshot())
		for line: String in _differences(host, client):
			seen[line] = true
	var differences := seen.keys()
	differences.sort()
	assert_array(differences).override_failure_message("\n".join(differences)).is_empty()
	# Two matches that agree because nothing happened in either would prove nothing, so the room
	# has to have been a room: somebody shot, somebody died, somebody cashed out, somebody broke
	# something. If a change ever makes the bots sit still, this fails rather than going quiet.
	var totals: Dictionary[StringName, float] = {}
	for field: StringName in [&"bullets", &"deaths", &"banks", &"coins", &"crates"]:
		totals[field] = 0.0
		for slot: PlayerSlot in host.slots:
			totals[field] += slot.stats.value(field)
		(
			assert_float(totals[field])
			. override_failure_message("nothing happened: no %s in the whole match" % field)
			. is_greater(0.0)
		)


## GAME.md 6.2: only a bullet knocks a shooting target down, and a client runs no bullets of its
## own. No shipped map places one yet, so this builds a map that does.
func test_a_client_sees_which_shooting_targets_are_standing() -> void:
	var base: ArenaLayout = load("res://data/maps/lucky_crossing.tres")
	var layout: ArenaLayout = base.duplicate()
	# Two crates become two targets, which is the one glyph no map uses.
	layout.grid = base.grid.replace("B", "R")
	var host: Match = auto_free(MATCH_SCENE.instantiate())
	host.rules = _rules()
	host.arena_layout = layout
	host.with_hud = false
	var runner := scene_runner(host)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	host.start(inputs, 91)
	await runner.simulate_frames(12, 17)
	assert_int(host.arena.targets.size()).is_greater(0)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = _rules()
	client.arena_layout = layout
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	client.apply_snapshot(host.build_snapshot())
	assert_int(client.arena.targets.size()).is_equal(host.arena.targets.size())
	assert_bool(client.arena.targets[0].alive).is_true()
	# Down on the host: a client has no bullet to knock it over with, so it has to be told.
	var bullet: Bullet = auto_free(Bullet.new())
	bullet.owner_slot = 0
	assert_bool(host.arena.targets[0].take_hit(bullet)).is_true()
	client.apply_snapshot(host.build_snapshot())
	assert_bool(host.arena.targets[0].alive).is_false()
	assert_bool(client.arena.targets[0].alive).is_false()
	assert_bool(client.arena.targets[0].visible).is_false()
	# And back up with it rather than on a clock of its own.
	await runner.simulate_frames(20, 17)
	client.apply_snapshot(host.build_snapshot())
	assert_bool(client.arena.targets[0].alive).is_false()
	await runner.simulate_frames(260, 17)
	client.apply_snapshot(host.build_snapshot())
	assert_bool(host.arena.targets[0].alive).is_true()
	assert_bool(client.arena.targets[0].alive).is_true()


## Every gameplay event either crosses the wire or is on the list of ones that do not, GAME.md
## 10.3. Without this a signal added later simply never reaches a client, and the only symptom
## is a room that sounds wrong on one machine.
func test_every_event_is_either_relayed_or_named_as_local() -> void:
	var unaccounted: Array[String] = []
	# The script's own signals, not the ones every Node has.
	for info: Dictionary in Events.get_script().get_script_signal_list():
		var name := StringName(info["name"])
		if not NetSession.RELAYED_EVENTS.has(name) and not NetSession.LOCAL_EVENTS.has(name):
			unaccounted.append(String(name))
	unaccounted.sort()
	(
		assert_array(unaccounted)
		. override_failure_message(
			"not relayed and not named as local: %s" % ", ".join(unaccounted)
		)
		. is_empty()
	)
	# And nothing is claimed twice, which would be a quiet way of saying two different things.
	for name: StringName in NetSession.LOCAL_EVENTS:
		assert_bool(NetSession.RELAYED_EVENTS.has(name)).is_false()


## A client hears the room the host hears, GAME.md 10.3: the countdown, a kart hitting something,
## a kart going down a hole. None of it happens on a client, whose karts are puppets.
func test_the_sounds_of_the_room_reach_a_client() -> void:
	var host_root: Node = auto_free(Node.new())
	host_root.name = "HostRoot"
	add_child(host_root)
	var client_root: Node = auto_free(Node.new())
	client_root.name = "ClientRoot"
	add_child(client_root)
	get_tree().set_multiplayer(SceneMultiplayer.new(), host_root.get_path())
	get_tree().set_multiplayer(SceneMultiplayer.new(), client_root.get_path())
	var host: Match = auto_free(MATCH_SCENE.instantiate())
	host.name = "Match"
	host.rules = _rules()
	host.with_hud = false
	host.offer_size = 0
	host_root.add_child(host)
	var inputs: Array[KartInput] = [KartInput.new(), BotInput.new()]
	host.start(inputs, 23)
	var host_session: NetSession = auto_free(NetSession.new())
	host_session.name = "Session"
	host_session.match_node = host
	host_root.add_child(host_session)
	assert_int(host_session.host(7793)).is_equal(OK)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.name = "Match"
	client.rules = _rules()
	client.with_hud = false
	client_root.add_child(client)
	client.start_puppet()
	var client_session: NetSession = auto_free(NetSession.new())
	client_session.name = "Session"
	client_session.match_node = client
	client_session.local_input = KartInput.new()
	client_root.add_child(client_session)
	assert_int(client_session.join("127.0.0.1", 7793)).is_equal(OK)
	var waited := 0
	while client_session.local_slot < 0 and waited < 4000:
		await await_millis(25)
		waited += 25
	assert_bool(client_session.local_slot >= 0).is_true()
	# Counted on this machine, which stands in for both: the relay re-emits on the client and in
	# one process that is the same autoload. The room is busy with a real match raising these for
	# real, so each one carries a marker nothing else would send. An array rather than a counter
	# because a lambda that captures a number keeps its own copy of it.
	const MARK := 4242
	var heard: Array[String] = []
	Events.countdown_tick.connect(
		func(n: int) -> void:
			if n == MARK:
				heard.append("countdown")
	)
	Events.kart_crashed.connect(
		func(_s: int, force: float) -> void:
			if is_equal_approx(force, float(MARK)):
				heard.append("crash")
	)
	Events.kart_fell.connect(
		func(slot: int) -> void:
			if slot == MARK:
				heard.append("fall")
	)
	Events.drift_boosted.connect(
		func(slot: int) -> void:
			if slot == MARK:
				heard.append("boost")
	)
	Events.countdown_tick.emit(MARK)
	Events.kart_crashed.emit(MARK, float(MARK))
	Events.kart_fell.emit(MARK)
	Events.drift_boosted.emit(MARK)
	await await_millis(600)
	# Four raised here, four more arriving back over the wire from the host's relay.
	(
		assert_array(heard)
		. override_failure_message("heard %s" % ", ".join(heard))
		. contains_exactly_in_any_order(
			["countdown", "countdown", "crash", "crash", "fall", "fall", "boost", "boost"]
		)
	)
	get_tree().set_multiplayer(null, host_root.get_path())
	get_tree().set_multiplayer(null, client_root.get_path())


## GAME.md 8.1: at the whistle the rig swings onto the winner. A client never runs a whistle, so
## it has to take the result off the snapshot and light the same kart.
func test_the_rig_swings_onto_the_winner_on_a_client_too() -> void:
	var host: Match = auto_free(MATCH_SCENE.instantiate())
	host.rules = _rules()
	host.with_hud = false
	host.offer_size = 0
	var runner := scene_runner(host)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	host.start(inputs, 23)
	await runner.simulate_frames(20, 17)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = _rules()
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	client.apply_snapshot(host.build_snapshot())
	assert_object(client.arena.disco._focus).is_null()
	# Second player runs away with it, then the clock runs out.
	host.slots[1].banked = 900
	host.time_left = 0.0
	host.rules.overtime = false
	await runner.simulate_frames(6, 17)
	assert_int(host.state).is_equal(Match.State.RESULTS)
	assert_object(host.arena.disco._focus).is_equal(host.kart_of(1))
	client.apply_snapshot(host.build_snapshot())
	assert_int(client.state).is_equal(Match.State.RESULTS)
	assert_int(client.standings()[0].index).is_equal(1)
	assert_object(client.arena.disco._focus).is_equal(client.slots[1].kart)
