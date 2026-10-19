extends GdUnitTestSuite
## The chips on a Jackpot show what it holds, GAME.md 3.5 and 8.1c: none at all while it holds
## nothing, a few once it holds a little, more as it fills and the whole pile once it is full, in
## every room, eased on rather than popping, drawn rather than baked into the tile, and the same on
## a client's screen as on the host's.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
## A map in every room with a Jackpot, the Count Room's last: its tile carries the House's memory
## rather than chips, STORY.md 3.9.
const MAPS: Array[String] = [
	"lucky_crossing",
	"vault",
	"crossfire",
	"lucky_crossing_xl",
	"vault_xl",
	"crossfire_xl",
	"garage",
	"tutorial",
]
const FRAME := 1.0 / 60.0

var _runner: GdUnitSceneRunner


func _rules() -> MatchRules:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	rules.jackpot_accrual = 0.0
	return rules


func _arena(map: String) -> Arena:
	var arena: Arena = auto_free(Arena.new())
	arena.layout = load("res://data/maps/%s.tres" % map)
	add_child(arena)
	return arena


func _pile(zone: JackpotZone) -> JackpotPile:
	return zone.get_node_or_null(^"Pile") as JackpotPile


## Runs [param pile] on for [param seconds], a frame at a time.
func _run(pile: JackpotPile, seconds: float) -> void:
	for i: int in ceili(seconds / FRAME):
		pile._process(FRAME)


## In every room the pile is gone at nothing, there but small at a little, bigger at a half and
## whole at the cap, and what is on the tile is what the pile says it shows.
func test_every_room_shows_what_its_jackpot_holds() -> void:
	var rules := _rules()
	for map: String in MAPS:
		var arena := _arena(map)
		assert_int(arena.jackpot_zones.size()).override_failure_message(map).is_greater(0)
		for zone: JackpotZone in arena.jackpot_zones:
			var pile := _pile(zone)
			assert_object(pile).override_failure_message(map).is_not_null()
			var all := pile.chips()
			assert_int(all).override_failure_message(map).is_greater(6)
			# A room with no match on it is the pile as it was built.
			_run(pile, 0.1)
			assert_int(pile.visible_chips()).override_failure_message(map).is_equal(all)
			zone.rules = rules
			var seen: Array[int] = []
			for chips: float in [0.0, 5.0, 30.0, 60.0]:
				zone.chips = chips
				_run(pile, 1.5)
				assert_bool(pile.is_settled()).override_failure_message(map).is_true()
				assert_int(pile.visible_chips()).override_failure_message(map).is_equal(
					pile.shown()
				)
				seen.append(pile.shown())
			var called := "%s: %s of %d" % [map, seen, all]
			assert_int(seen[0]).override_failure_message(called).is_equal(0)
			assert_int(seen[1]).override_failure_message(called).is_greater(0)
			assert_int(seen[1]).override_failure_message(called).is_less(all / 3)
			assert_int(seen[2]).override_failure_message(called).is_greater(seen[1])
			assert_int(seen[3]).override_failure_message(called).is_greater(seen[2])
			assert_int(seen[3]).override_failure_message(called).is_equal(all)


## The Count Room's tile is the House's memory, with no chips on it to pile.
func test_the_count_room_keeps_its_memory_rather_than_a_pile() -> void:
	var arena := _arena("house_rules")
	for zone: JackpotZone in arena.jackpot_zones:
		var pile := _pile(zone)
		assert_bool(pile == null or pile.chips() == 0).is_true()


## The steps go with the traffic light, GAME.md 3.5: none at nothing, then one more at every edge
## of it, amber, halfway on to the cap, and the cap; a hot table's pile past the rules' cap is still
## the whole pile, and a zone with no match on it is too.
func test_the_steps_go_with_the_traffic_light() -> void:
	var zone: JackpotZone = auto_free(JackpotZone.new())
	assert_int(JackpotPile.step_of(zone)).is_equal(4)
	zone.rules = _rules()
	var steps: Array[int] = []
	for chips: float in [0.0, 0.6, 1.0, 19.0, 20.0, 39.0, 40.0, 59.0, 60.0, 120.0]:
		zone.chips = chips
		steps.append(JackpotPile.step_of(zone))
	assert_array(steps).is_equal([0, 0, 1, 1, 2, 2, 3, 3, 4, 4])


## The chips are drawn as a pile of their own across the Jackpots, never baked into the tile: the
## stacks they were built in are gone, and a mesh a material across both zones draws them.
func test_the_pile_is_drawn_rather_than_baked() -> void:
	var arena := _arena("vault")
	var zones := arena.get_node("JackpotZones")
	var drawn: Array[MultiMesh] = []
	for node: Node in zones.find_children("Chips*", "MultiMeshInstance3D", false, false):
		drawn.append((node as MultiMeshInstance3D).multimesh)
	assert_int(drawn.size()).is_greater(0)
	assert_int(zones.find_children("Stack*", "", true, false).size()).is_equal(0)
	for zone: JackpotZone in arena.jackpot_zones:
		var pile := _pile(zone)
		assert_int(pile.get_child_count()).is_equal(0)
		var used: Array[MultiMesh] = []
		for chip: Array in pile._chips:
			for piece: Array in chip:
				assert_bool(drawn.has(piece[0])).is_true()
				if not used.has(piece[0]):
					used.append(piece[0])
		# One draw for each thing the chips are made of, shared by both Jackpots.
		assert_int(used.size()).is_equal(drawn.size())


## A step is eased on: a moment after the Jackpot fills, some of its chips are still on their way,
## and a moment later every one has landed; collected, they go the same way.
func test_a_step_is_eased_rather_than_popped() -> void:
	var arena := _arena("lucky_crossing")
	var zone := arena.jackpot_zones[0]
	var pile := _pile(zone)
	zone.rules = _rules()
	zone.chips = 0.0
	_run(pile, 0.1)
	assert_int(pile.visible_chips()).is_equal(0)
	zone.chips = 60.0
	_run(pile, 3.0 * FRAME)
	assert_int(pile.visible_chips()).is_greater(0)
	assert_int(pile.visible_chips()).is_less(pile.chips())
	assert_bool(pile.is_settled()).is_false()
	_run(pile, 1.0)
	assert_int(pile.visible_chips()).is_equal(pile.chips())
	assert_bool(pile.is_settled()).is_true()
	zone.chips = 0.0
	_run(pile, 3.0 * FRAME)
	assert_int(pile.visible_chips()).is_greater(0)
	_run(pile, 1.0)
	assert_int(pile.visible_chips()).is_equal(0)


## A client is sent the Jackpots' chips with the rest of the zones and piles them up the same way,
## GAME.md 10.3: its piles show what the host's do, at a little and at full.
func test_a_client_sees_the_same_pile_as_the_host() -> void:
	var host: Match = auto_free(MATCH_SCENE.instantiate())
	host.rules = _rules()
	host.with_hud = false
	_runner = scene_runner(host)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	host.start(inputs, 11)
	await _runner.simulate_frames(12, 17)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = host.rules
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	for chips: float in [8.0, 60.0]:
		for zone: JackpotZone in host.arena.jackpot_zones:
			zone.chips = chips if zone.active else 0.0
		client.apply_snapshot(host.build_snapshot())
		await _runner.simulate_frames(90, 17)
		for i: int in host.arena.jackpot_zones.size():
			var mine := _pile(host.arena.jackpot_zones[i])
			var theirs := _pile(client.arena.jackpot_zones[i])
			assert_int(theirs.chips()).is_equal(mine.chips())
			assert_int(theirs.shown()).is_equal(mine.shown())
			assert_int(theirs.visible_chips()).is_equal(mine.visible_chips())
			var holds := host.arena.jackpot_zones[i].whole_chips()
			if holds == 0:
				assert_int(theirs.visible_chips()).is_equal(0)
			elif holds < host.rules.jackpot_amber:
				assert_int(theirs.visible_chips()).is_between(1, theirs.chips() / 3)
			else:
				assert_int(theirs.visible_chips()).is_equal(theirs.chips())
