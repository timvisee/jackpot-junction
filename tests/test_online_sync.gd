extends GdUnitTestSuite
## Whether a client is looking at the same match as the host, GAME.md 10.3. A host runs a room
## full of bots for a while and a puppet match is fed its snapshots; afterwards every number
## either machine shows a player has to agree. Anything the host keeps and the snapshot leaves
## out shows up here as a difference rather than as a bug report from a play session.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")


func _rules() -> MatchRules:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 120.0
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
	# A couple of minutes of bots at each other, sampled the way the wire samples it. Compared
	# every time rather than only at the whistle: a target lying on its face, a crate in pieces
	# or a pot mid-cash-out is all state that comes and goes, and a difference that heals itself
	# before the end is still a difference somebody watched.
	var seen: Dictionary[String, bool] = {}
	for i: int in 240:
		await runner.simulate_frames(4, 17)
		client.apply_snapshot(host.build_snapshot())
		for line: String in _differences(host, client):
			seen[line] = true
	var differences := seen.keys()
	differences.sort()
	assert_array(differences).override_failure_message("\n".join(differences)).is_empty()
