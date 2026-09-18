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
	# has to have been a room. Driving and shooting happen constantly and are asked for on their
	# own; dying and cashing out are asked for together, because either one is enough to say the
	# match got somewhere and which of them a given run produces is up to the bots. Breaking a
	# crate is not asked for at all: it is the rarest thing on this list and a run that happens
	# not to manage one is a quiet match, not a broken one.
	var totals: Dictionary[StringName, float] = {}
	for field: StringName in [&"bullets", &"coins", &"deaths", &"banks"]:
		totals[field] = 0.0
		for slot: PlayerSlot in host.slots:
			totals[field] += slot.stats.value(field)
	for field: StringName in [&"bullets", &"coins"]:
		(
			assert_float(totals[field])
			. override_failure_message("nothing happened: no %s in the whole match" % field)
			. is_greater(0.0)
		)
	(
		assert_float(totals[&"deaths"] + totals[&"banks"])
		. override_failure_message("nothing happened: nobody died and nobody cashed out")
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


## GAME.md 8.5: the aim guide is drawn for the player driving. Online the kart they drive is a
## puppet moved by the host, which is not the same thing as a kart they are not driving.
func test_a_client_draws_the_aim_guide_on_the_kart_its_player_drives() -> void:
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
	# What a session does once the host says which slot is ours, input and all.
	var mine := PlayerInput.new()
	client.set_local_slot(1, mine)
	client.apply_snapshot(host.build_snapshot())
	await await_millis(60)
	var ours: Kart = client.slots[1].kart
	var theirs: Kart = client.slots[0].kart
	assert_bool(ours.puppet).is_true()
	assert_object(ours.input).is_equal(mine)
	assert_object(ours._aim_guide).is_not_null()
	assert_bool(ours._aim_guide.visible).is_true()
	# And not on the kart somebody else is driving, which is every other kart on this screen.
	assert_object(theirs._aim_guide).is_null()
	# It follows the nose, which is where an ordinary cannon shoots.
	assert_vector(ours.aim_direction()).is_equal_approx(-ours.global_basis.z, Vector3.ONE * 0.01)
	# A swivel cannon is free aim, and a client knows that from the arrow the host sends it.
	ours.aim_arrow_visible = true
	mine.aim = Vector2(0.0, -1.0)
	assert_vector(ours.aim_direction()).is_equal_approx(Vector3.FORWARD, Vector3.ONE * 0.01)
	# Turned off in the settings it goes, on a client the same as anywhere else.
	Game.settings.aim_guide = false
	await await_millis(60)
	assert_bool(ours._aim_guide.visible).is_false()
	Game.settings.aim_guide = true


## GAME.md 8.3: a kart bursting or a crate breaking throws what it was carrying clear of itself
## rather than having it appear on the floor. A client used to get only the second half of that,
## because a pickup's position is where it lands from the first snapshot it appears in and the
## flight is drawn on top of that.
func test_a_client_sees_a_dropped_pickup_thrown_clear() -> void:
	var host: Match = auto_free(MATCH_SCENE.instantiate())
	host.rules = _rules()
	host.with_hud = false
	var runner := scene_runner(host)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	host.start(inputs, 91)
	await runner.simulate_frames(20, 17)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = _rules()
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	client.apply_snapshot(host.build_snapshot())
	# A chip thrown clear of a point, the way a bursting kart scatters them.
	var chip := Chip.new()
	var origin := Vector3(2.0, 0.0, 2.0)
	host.arena.place_drop(chip, Vector3(3.0, 0.0, 3.0), origin)
	await runner.simulate_frames(2, 17)
	assert_bool(chip.throw_state().is_empty()).is_false()
	client.apply_snapshot(host.build_snapshot())
	var mine: Pickup = null
	for node: Node in client.arena.pickups.get_children():
		var found := node as Pickup
		if found != null and found.global_position.distance_to(Vector3(3.0, 0.0, 3.0)) < 0.2:
			mine = found
	assert_object(mine).override_failure_message("the client never got the chip").is_not_null()
	(
		assert_bool(mine.throw_state().is_empty())
		. override_failure_message("the chip appeared on the floor instead of being thrown there")
		. is_false()
	)
	# Flying from where the host threw it, and part way through rather than starting again.
	var state := mine.throw_state()
	assert_vector(state[0] as Vector3).is_equal_approx(
		origin + Vector3(0.0, Pickup.THROW_HEIGHT, 0.0), Vector3.ONE * 0.01
	)
	assert_float(state[1]).is_less(Pickup.THROW_TIME)
	assert_float(state[1]).is_greater(0.0)
	# And it lands, rather than hanging in the air for the rest of the match.
	await runner.simulate_frames(40, 17)
	assert_bool(mine.throw_state().is_empty()).is_true()


## A box a client drove through stays through, GAME.md 10.3. The snapshots arriving over the next
## round trip were built before the host had heard about it, and letting them put the box back is
## what left a kart stuck against a box it had already gone through, waiting to be dragged past.
func test_a_box_a_client_broke_stays_broken_until_the_host_says_otherwise() -> void:
	var host: Match = auto_free(MATCH_SCENE.instantiate())
	host.rules = _rules()
	host.with_hud = false
	var runner := scene_runner(host)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	host.start(inputs, 91)
	await runner.simulate_frames(20, 17)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = _rules()
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	client.apply_snapshot(host.build_snapshot())
	var mine: Crate = client.arena.crates[0]
	assert_bool(mine.alive).is_true()
	# Driven through here. The host has not heard yet and goes on saying the box is there.
	mine.predict_break()
	assert_bool(mine.alive).is_false()
	assert_int(mine.collision_layer).is_equal(0)
	for i: int in 8:
		await runner.simulate_frames(2, 17)
		client.apply_snapshot(host.build_snapshot())
	(
		assert_bool(mine.alive)
		. override_failure_message("a snapshot put the box back under the kart that broke it")
		. is_false()
	)
	# The host agrees, and that is that.
	host.arena.crates[0].hit(0)
	client.apply_snapshot(host.build_snapshot())
	assert_bool(mine.alive).is_false()
	assert_bool(mine.predicted_break()).is_false()
	# And the other way: a box this machine was wrong about comes back, because the host's word
	# is what settles it and a guess only ever buys itself a moment.
	var wrong: Crate = client.arena.crates[1]
	wrong.predict_break()
	assert_bool(wrong.alive).is_false()
	await runner.simulate_frames(80, 17)
	client.apply_snapshot(host.build_snapshot())
	(
		assert_bool(wrong.alive)
		. override_failure_message("a box this machine was wrong about never came back")
		. is_true()
	)
	assert_int(wrong.collision_layer).is_equal(Layers.WORLD)


## GAME.md 8.3: a pickup is never simply taken off the floor, it flies into the kart that took it.
## A client works out who took it from who was near enough, and the Coin Magnet triples how near
## that is: a chip pulled in from three metres away was outside the old answer, so nothing flew
## and the chip blinked out, which is the one thing a pickup is not supposed to do.
func test_a_chip_pulled_in_by_a_magnet_still_flies_into_the_kart() -> void:
	var host: Match = auto_free(MATCH_SCENE.instantiate())
	host.rules = _rules()
	host.with_hud = false
	var runner := scene_runner(host)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	host.start(inputs, 91)
	await runner.simulate_frames(20, 17)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = _rules()
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	client.apply_snapshot(host.build_snapshot())
	# A magnet on the host's kart, which the client has to be told about to judge the reach.
	host.kart_of(0).pickup_radius_bonus = 3.0
	var chip := Chip.new()
	var kart_at := host.kart_of(0).global_position
	host.arena.place_drop(chip, kart_at + Vector3(2.6, 0.0, 0.0))
	await runner.simulate_frames(2, 17)
	client.apply_snapshot(host.build_snapshot())
	(
		assert_float(client.slots[0].kart.pickup_radius_bonus)
		. override_failure_message("the client never heard about the magnet")
		. is_equal_approx(3.0, 0.01)
	)
	var id := chip.get_instance_id()
	assert_bool(client.puppet_pickups.has(id)).is_true()
	# Pulled in on the host, from further out than a kart without a magnet could reach.
	chip.queue_free()
	await runner.simulate_frames(2, 17)
	# The flight is parented where the pickup was, which is the arena's pickup holder.
	var before := 0
	for node: Node in client.arena.pickups.get_children():
		if node is PickupFlight:
			before += 1
	client.apply_snapshot(host.build_snapshot())
	var flying := 0
	for node: Node in client.arena.pickups.get_children():
		if node is PickupFlight:
			flying += 1
	(
		assert_int(flying - before)
		. override_failure_message("the chip blinked out instead of flying into the kart")
		. is_greater(0)
	)


## A rematch is a new match on every machine, GAME.md 8.4. A client keeps its own excitement
## meter and its own announcer, on purpose, and nothing was telling either of them the last match
## was over: the new one opened at the level the old one finished at, lights still going.
func test_a_new_match_puts_down_what_a_client_was_carrying() -> void:
	var host: Match = auto_free(MATCH_SCENE.instantiate())
	host.rules = _rules()
	host.with_hud = false
	var runner := scene_runner(host)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	host.start(inputs, 91)
	await runner.simulate_frames(20, 17)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = _rules()
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	client.apply_snapshot(host.build_snapshot())
	# A hot room, a streak going and the rig on somebody.
	client.intensity.add(1.0)
	client.intensity.bump()
	client.intensity.bump()
	client.announcer.streaks[0] = 4
	client.arena.disco.focus(client.slots[0].kart)
	await runner.simulate_frames(4, 17)
	assert_int(client.intensity.level).is_greater(1)
	# The host plays it again, and the countdown for the new one reaches this machine.
	host.rematch()
	await runner.simulate_frames(4, 17)
	assert_int(host.state).is_equal(Match.State.COUNTDOWN)
	client.apply_snapshot(host.build_snapshot())
	(
		assert_int(client.intensity.level)
		. override_failure_message("the new match opened at the old one's excitement level")
		. is_equal(1)
	)
	assert_float(client.intensity.value).is_equal_approx(0.0, 0.01)
	(
		assert_bool(client.announcer.streaks.is_empty())
		. override_failure_message("somebody was still on a streak from the last match")
		. is_true()
	)
	assert_object(client.arena.disco._focus).is_null()


## The floor goes out as what changed, GAME.md 10.3. Most of a snapshot used to be a list of
## chips that had not moved since the last one.
func test_the_floor_is_sent_as_what_changed() -> void:
	var host: Match = auto_free(MATCH_SCENE.instantiate())
	host.rules = _rules()
	host.with_hud = false
	var runner := scene_runner(host)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	host.start(inputs, 91)
	await runner.simulate_frames(20, 17)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = _rules()
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	var wire := PickupWire.new()
	# The first one is the whole floor, and the client ends up holding all of it.
	var whole := host.build_snapshot(wire)
	assert_bool(whole["whole"]).is_true()
	assert_int((whole["pickups"] as Array).size()).is_greater(5)
	client.apply_snapshot(whole)
	var floor_size := client.puppet_pickups.size()
	assert_int(floor_size).is_equal((whole["pickups"] as Array).size())
	# Nothing has happened, so the next one says nothing about the floor at all.
	var quiet := host.build_snapshot(wire)
	assert_bool(quiet["whole"]).is_false()
	(
		assert_int((quiet["pickups"] as Array).size())
		. override_failure_message("a quiet floor was sent in full anyway")
		. is_equal(0)
	)
	assert_int((quiet["gone"] as Array).size()).is_equal(0)
	assert_int(var_to_bytes(quiet).size()).is_less(var_to_bytes(whole).size())
	client.apply_snapshot(quiet)
	assert_int(client.puppet_pickups.size()).is_equal(floor_size)
	# One arrives and one goes, and only those two are mentioned.
	var fresh := Chip.new()
	host.arena.place_drop(fresh, Vector3(4.0, 0.0, 4.0))
	var doomed: Pickup = null
	for node: Node in host.arena.pickups.get_children():
		var found := node as Pickup
		if found != null and found != fresh:
			doomed = found
			break
	var doomed_id := doomed.get_instance_id()
	doomed.queue_free()
	await runner.simulate_frames(2, 17)
	var changed := host.build_snapshot(wire)
	# The one that arrived is in there. Possibly with a pad's own fresh chip beside it, since the
	# floor does not hold still for a test.
	var added: Array = []
	for entry: Dictionary in changed["pickups"]:
		added.append(entry["id"])
	assert_array(added).contains([fresh.get_instance_id()])
	assert_int(added.size()).is_less(4)
	assert_array(changed["gone"]).contains([doomed_id])
	client.apply_snapshot(changed)
	assert_bool(client.puppet_pickups.has(fresh.get_instance_id())).is_true()
	assert_bool(client.puppet_pickups.has(doomed_id)).is_false()
	# Said again for a few snapshots, because a lost packet must not leave a chip lying there.
	var again := host.build_snapshot(wire)
	(
		assert_array(again["gone"])
		. override_failure_message("a removal was said once and trusted to arrive")
		. contains([doomed_id])
	)
	# And a client that missed everything is put right by the next whole floor on its own.
	client.puppet_pickups.clear()
	for node: Node in client.arena.pickups.get_children():
		node.queue_free()
	await runner.simulate_frames(2, 17)
	for i: int in PickupWire.KEYFRAME_EVERY + 2:
		client.apply_snapshot(host.build_snapshot(wire))
	(
		assert_int(client.puppet_pickups.size())
		. override_failure_message("a client that lost the floor never got it back")
		. is_greater(5)
	)


## GAME.md 8.3: a pickup is never simply taken off the floor. A Coin Magnet drags chips toward
## the kart, and a client that was never told they were moving watched one sit where it first saw
## it and then blink out from there, which is both halves of the effect missed at once.
func test_a_chip_being_pulled_in_moves_on_a_client_and_then_flies() -> void:
	var host: Match = auto_free(MATCH_SCENE.instantiate())
	host.rules = _rules()
	host.with_hud = false
	var runner := scene_runner(host)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	host.start(inputs, 91)
	await runner.simulate_frames(20, 17)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = _rules()
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	var wire := PickupWire.new()
	host.kart_of(0).pickup_radius_bonus = 3.0
	var at := host.kart_of(0).global_position
	var chip := Chip.new()
	host.arena.place_drop(chip, at + Vector3(2.4, 0.0, 0.0))
	await runner.simulate_frames(2, 17)
	client.apply_snapshot(host.build_snapshot(wire))
	var mine: Pickup = client.puppet_pickups.get(chip.get_instance_id())
	assert_object(mine).override_failure_message("the client never got the chip").is_not_null()
	# Dragged in, which is what the magnet does on the host. Not all the way in: inside the
	# ordinary pickup radius the host simply collects it, and this is about the journey.
	chip.global_position = at + Vector3(1.5, 0.0, 0.0)
	await runner.simulate_frames(2, 17)
	client.apply_snapshot(host.build_snapshot(wire))
	(
		assert_vector(mine.global_position)
		. override_failure_message("the chip stayed where the client first saw it")
		. is_equal_approx(chip.global_position, Vector3.ONE * 0.05)
	)
	# Then taken, and it flies in from where it actually is rather than blinking out.
	var before := 0
	for node: Node in client.arena.pickups.get_children():
		if node is PickupFlight:
			before += 1
	chip.queue_free()
	await runner.simulate_frames(2, 17)
	client.apply_snapshot(host.build_snapshot(wire))
	var flying := 0
	for node: Node in client.arena.pickups.get_children():
		if node is PickupFlight:
			flying += 1
	(
		assert_int(flying - before)
		. override_failure_message("the chip blinked out instead of flying into the kart")
		. is_greater(0)
	)


## GAME.md 10.3: a kart driven here burns its own nitro. The host's word for it is a round trip
## old, and laying that over the top made nitro flicker on a client — lit here, put out by the
## next snapshot, lit again — which is the opposite of the instant the button is supposed to feel.
func test_nitro_on_a_client_is_not_put_out_by_the_host() -> void:
	var host: Match = auto_free(MATCH_SCENE.instantiate())
	host.rules = _rules()
	host.with_hud = false
	var runner := scene_runner(host)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	host.start(inputs, 91)
	await runner.simulate_frames(20, 17)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = _rules()
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	client.set_local_slot(0)
	client.apply_snapshot(host.build_snapshot())
	var mine: Kart = client.slots[0].kart
	var prediction := KartPrediction.new(mine)
	assert_bool(mine.predicted).is_true()
	# Lit here, on the tick the button went down. The host has not heard yet.
	var driving := KartInput.new()
	driving.nitro = true
	driving.throttle = 1.0
	KartPrediction.step(mine, driving, 1.0 / 60.0)
	assert_bool(mine.nitro_active).is_true()
	assert_bool(mine._flame._smoke.emitting).is_true()
	assert_bool(host.kart_of(0).nitro_active).is_false()
	# A snapshot arrives saying the kart is not burning any, because on the host it is not yet.
	client.apply_snapshot(host.build_snapshot())
	(
		assert_bool(mine._flame._smoke.emitting)
		. override_failure_message("the host's word put out a flame this machine had just lit")
		. is_true()
	)
	assert_bool(mine.nitro_active).is_true()
	# Somebody else's kart is drawn from the host's word, which is all anybody has of it.
	var theirs: Kart = client.slots[1].kart
	assert_bool(theirs.predicted).is_false()
	assert_bool(theirs._flame._smoke.emitting).is_false()
	assert_object(prediction).is_not_null()
