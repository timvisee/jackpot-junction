extends GdUnitTestSuite
## The House's forecast at the Final Hand, STORY.md 8.2: its three acts by the match clock; where it
## expects a kart to be, turned along a wall as a kart is; its racks rising where a forecast ends,
## across the road, kept off everything a kart is sent to, closed to the bots while they stand and
## sent to clients; the models led along a person's own line at convergence; and at each screen the
## amendments counted, the racks the candidate got past, and the evaluation's line for them.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES := preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner
var _was_story := StoryState.new()


func before_test() -> void:
	_was_story = Game.settings.profile.story
	Game.settings.profile.story = StoryState.new()
	FinalHand.forget_forecasts()


func after_test() -> void:
	Game.settings.profile.story = _was_story
	Story.final_hand_on = false
	FinalHand.seat_index = -1
	FinalHand.forget_forecasts()


## A Final Hand on House Rules, a person at the first seat and three models, its clock
## [param share] of the way through once it is running.
func _final_hand(share := 0.0) -> Match:
	Story.final_hand_on = true
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 300.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.arena_layout = ArenaMaps.layout(FinalHand.MAP)
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.ANY, 0)]
	for i: int in 3:
		inputs.append(BotInput.new())
	match_node.start(inputs, 23)
	FinalHandTable.add_to(match_node)
	await _runner.simulate_frames(12, 17)
	match_node.time_left = rules.duration * (1.0 - share)
	return match_node


static func _forecast(match_node: Match) -> HouseForecast:
	return match_node.get_node("HouseForecast") as HouseForecast


## Observation from 30%, anticipation from half way, convergence from three quarters and on into
## overtime; none before, nor once the whistle has gone.
func test_the_acts_follow_the_clock() -> void:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = RULES.duplicate()
	match_node.rules.duration = 300.0
	match_node.state = Match.State.PLAYING
	var acts := {
		0.0: HouseForecast.Act.NONE,
		0.29: HouseForecast.Act.NONE,
		0.31: HouseForecast.Act.OBSERVATION,
		0.55: HouseForecast.Act.ANTICIPATION,
		0.8: HouseForecast.Act.CONVERGENCE,
		1.0: HouseForecast.Act.CONVERGENCE,
	}
	for share: float in acts:
		match_node.time_left = 300.0 * (1.0 - share)
		assert_int(HouseForecast.act_of(match_node)).is_equal(acts[share])
	match_node.state = Match.State.OVERTIME
	assert_int(HouseForecast.act_of(match_node)).is_equal(HouseForecast.Act.CONVERGENCE)
	match_node.state = Match.State.RESULTS
	assert_int(HouseForecast.act_of(match_node)).is_equal(HouseForecast.Act.NONE)


## A kart going straight is forecast a second and a half on at its speed, one turning round the
## way it turns; one going nowhere where it is; and one meeting a wall turned along it.
func test_the_forecast_runs_on() -> void:
	var straight := HouseForecast.project(Vector3.ZERO, Vector3(8.0, 0.0, 0.0), 0.0, 1.5, null)
	assert_int(straight.size()).is_equal(HouseForecast.STEPS + 1)
	assert_vector(straight[straight.size() - 1]).is_equal_approx(
		Vector3(12.0, 0.0, 0.0), Vector3.ONE * 0.01
	)
	var left := HouseForecast.project(Vector3.ZERO, Vector3(8.0, 0.0, 0.0), 1.5, 1.5, null)
	var right := HouseForecast.project(Vector3.ZERO, Vector3(8.0, 0.0, 0.0), -1.5, 1.5, null)
	assert_float(left[left.size() - 1].z).is_greater(1.0)
	assert_float(right[right.size() - 1].z).is_less(-1.0)
	var still := HouseForecast.project(
		Vector3(3.0, 0.0, 2.0), Vector3(0.5, 0.0, 0.0), 0.0, 1.5, null
	)
	assert_int(still.size()).is_equal(1)
	# Along the top of House Rules, under the wall of its first row, heading up into it a little.
	var grid := ArenaMaps.layout(FinalHand.MAP).parse()
	var start := grid.cell_center(Vector2i(3, 1))
	var slanted := HouseForecast.project(start, Vector3(8.0, 0.0, -2.0), 0.0, 1.5, grid)
	for point: Vector3 in slanted:
		assert_bool(grid.is_wall(grid.cell_of(point))).is_false()
	assert_float(slanted[slanted.size() - 1].x - start.x).is_greater(8.0)


## A rack is outlined, rises, stands as a wall and sinks, solid only while it is up, and sunk at
## the whistle it is gone the sooner.
func test_a_rack_rises_and_sinks() -> void:
	var holder: Node3D = auto_free(Node3D.new())
	add_child(holder)
	var rack := HouseRack.raise(holder, Vector3(2.0, 0.0, 3.0), Vector2(2.5, 1.25), 0, null)
	assert_bool(rack.is_solid()).is_false()
	assert_float(HouseRack.height_at(0.0)).is_equal(0.0)
	assert_float(HouseRack.height_at(HouseRack.MARK + HouseRack.RISE)).is_equal(1.0)
	assert_float(HouseRack.height_at(HouseRack.LIFE)).is_equal(0.0)
	rack._physics_process(HouseRack.MARK + HouseRack.RISE)
	assert_bool(rack.is_solid()).is_true()
	assert_bool(rack.has_risen()).is_true()
	assert_bool(rack.touches(Vector3(3.4, 0.0, 3.0), 0.4)).is_true()
	assert_bool(rack.touches(Vector3(4.5, 0.0, 3.0), 0.4)).is_false()
	rack.sink()
	rack._physics_process(HouseRack.SINK * 0.5)
	assert_float(HouseRack.height_at(rack.age)).is_less(1.0)
	rack._physics_process(HouseRack.SINK)
	assert_bool(rack.is_queued_for_deletion()).is_true()


## Where a kart's forecast ends, on the host, a rack rises across its road, two tiles of open floor;
## its tiles are closed to the bots while it stands; and it goes to a client, which raises its own
## of it, solid there too.
func test_a_rack_rises_where_the_forecast_ends() -> void:
	var match_node: Match = await _final_hand(0.55)
	var forecast := _forecast(match_node)
	forecast.set_physics_process(false)
	var grid := match_node.arena.grid
	var model := match_node.slots[1]
	model.kart.global_position = grid.cell_center(Vector2i(4, 1))
	var motion := HouseForecast.Motion.new()
	motion.at = model.kart.global_position
	motion.velocity = Vector3(8.0, 0.0, 0.0)
	forecast._motion[model.index] = motion
	assert_bool(forecast._raise_at(model, true)).is_true()
	var racks := MatchSnapshot.own_nodes(match_node, HouseRack.GROUP)
	assert_int(racks.size()).is_equal(1)
	var rack := racks[0] as HouseRack
	assert_int(rack.target).is_equal(model.index)
	var standing := forecast._standing[0]
	assert_int(standing.cells.size()).is_equal(2)
	for cell: Vector2i in standing.cells:
		assert_str(grid.glyph(cell)).is_equal(ArenaGrid.FLOOR)
	assert_float(rack.global_position.x - model.kart.global_position.x).is_greater(6.0)
	rack.age = HouseRack.MARK + HouseRack.RISE
	rack._lay()
	forecast._close_roads()
	for cell: Vector2i in standing.cells:
		assert_bool(match_node.nav.is_blocked(cell)).is_true()
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = match_node.rules
	client.arena_layout = match_node.arena_layout
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	client.apply_snapshot(match_node.build_snapshot())
	var copies := MatchSnapshot.own_nodes(client, HouseRack.GROUP)
	assert_int(copies.size()).is_equal(1)
	var copy := copies[0] as HouseRack
	assert_bool(copy.puppet).is_true()
	assert_float(copy.age).is_equal_approx(rack.age, 0.001)
	assert_vector(copy.global_position).is_equal_approx(rack.global_position, Vector3.ONE * 0.01)
	copy._lay()
	assert_bool(copy.is_solid()).is_true()
	# Gone into the floor at the host, it goes at the client, and its tiles are open again.
	rack.free()
	forecast._close_roads()
	for cell: Vector2i in standing.cells:
		assert_bool(match_node.nav.is_blocked(cell)).is_false()
	client.apply_snapshot(match_node.build_snapshot())
	await await_idle_frame()
	assert_int(MatchSnapshot.own_nodes(client, HouseRack.GROUP).size()).is_equal(0)


## Never on anything a kart is sent to, nor beside a rack already up, nor on a kart.
func test_a_rack_keeps_off_the_pads() -> void:
	var match_node: Match = await _final_hand(0.55)
	var forecast := _forecast(match_node)
	forecast.set_physics_process(false)
	var grid := match_node.arena.grid
	for y: int in grid.height:
		for x: int in grid.width:
			var cell := Vector2i(x, y)
			if grid.glyph(cell) != ArenaGrid.FLOOR:
				assert_bool(forecast._free(cell)).is_false()
	var kart := match_node.slots[0].kart
	assert_bool(forecast._free(grid.cell_of(kart.global_position))).is_false()


## The House's turret, in a rack's place now and then for a person, is gold, nobody's, never broken,
## and goes to a client as the House's.
func test_the_houses_turret() -> void:
	var match_node: Match = await _final_hand(0.55)
	var forecast := _forecast(match_node)
	forecast.set_physics_process(false)
	var person := match_node.slots[0]
	forecast._turret_at(Vector2i(12, 2), person)
	var turret := forecast._turrets[0]
	assert_int(turret.owner_slot).is_equal(-1)
	assert_bool(turret.fixture).is_true()
	turret.destroy()
	assert_bool(turret.alive).is_true()
	assert_float(turret.age).is_greater_equal(HouseTurret.life() - HouseRack.SINK)
	var entry: Dictionary = MatchSnapshot._turrets(match_node)[0]
	assert_bool(entry.has("f")).is_true()


## At convergence each model follows the person's own line a little behind them, each a little
## further than the last, and before it goes its own way.
func test_the_models_follow_the_line() -> void:
	var match_node: Match = await _final_hand(0.8)
	await _runner.simulate_frames(4, 17)
	var forecast := _forecast(match_node)
	forecast.set_physics_process(false)
	var trail := PackedVector3Array()
	for i: int in 45:
		trail.append(Vector3(-10.0 + float(i) * 0.5, 0.0, 0.0))
	forecast._trails[0] = trail
	forecast.act = HouseForecast.Act.CONVERGENCE
	forecast._lead()
	var led: Array[float] = []
	for slot: PlayerSlot in match_node.slots:
		var brain := HouseForecast._brain_of(slot)
		if brain == null:
			continue
		assert_bool(brain.led_to.is_finite()).is_true()
		led.append(brain.led_to.x)
	assert_int(led.size()).is_equal(3)
	assert_float(led[0]).is_greater(led[1])
	assert_float(led[1]).is_greater(led[2])
	forecast.act = HouseForecast.Act.ANTICIPATION
	forecast._lead()
	for slot: PlayerSlot in match_node.slots:
		var brain := HouseForecast._brain_of(slot)
		if brain != null:
			assert_bool(brain.led_to.is_finite()).is_false()


## At this screen: the racks raised at the candidate counted once gone, as beaten unless the
## candidate drove into them, and an amendment accepted counted where the Final Hand is due.
func test_the_watch_keeps_count() -> void:
	var match_node: Match = await _final_hand(0.55)
	var table := match_node.get_node("FinalHandTable") as FinalHandTable
	var watch := table.watch
	assert_object(watch).is_not_null()
	var candidate := match_node.slots[0]
	var beaten := HouseRack.raise(match_node, Vector3(10.0, 0.0, 5.0), Vector2.ONE, 0, null)
	beaten.age = HouseRack.MARK + HouseRack.RISE
	beaten._lay()
	var hit := HouseRack.raise(match_node, candidate.kart.global_position, Vector2.ONE, 0, null)
	hit.age = HouseRack.MARK + HouseRack.RISE
	hit._lay()
	watch._count_racks(candidate)
	beaten.free()
	hit.free()
	watch._count_racks(candidate)
	assert_int(FinalHand.raised).is_equal(2)
	assert_int(FinalHand.beaten).is_equal(1)
	watch.due = true
	watch._on_accepted()
	assert_int(Game.settings.profile.story.amendments).is_equal(1)
	watch.due = false
	watch._on_accepted()
	assert_int(Game.settings.profile.story.amendments).is_equal(1)
	assert_int(watch.accepted).is_equal(2)


## The amendment over the HUD: its number and line, stamped once the candidate has played on.
func test_an_amendment_is_stamped() -> void:
	var hud: Control = auto_free(Control.new())
	hud.size = Vector2(1920.0, 1080.0)
	add_child(hud)
	var notice := HouseAmendment.over(hud, 2)
	assert_str(notice.words).is_equal(StoryLines.AMENDMENTS[1])
	var stamped := [false]
	notice.accepted.connect(func() -> void: stamped[0] = true)
	notice.driving = false
	notice._process(HouseAmendment.IN + HouseAmendment.READ + 0.1)
	assert_bool(notice.is_accepted()).is_false()
	notice.driving = true
	notice._process(0.1)
	assert_bool(stamped[0]).is_true()


## The evaluation's line for the forecasts, and the deviation from them where it made any.
func test_the_evaluation_counts_the_forecasts() -> void:
	var match_node: Match = await _final_hand(0.9)
	FinalHand.raised = 7
	FinalHand.beaten = 5
	FinalHand.off_by = 3.0
	FinalHand.forecasts = 10
	var lines := FinalHand.evaluation(match_node)
	var found := false
	for line: Array in lines:
		if line[0] == "FORECASTS BEATEN":
			found = true
			assert_str(str(line[1])).is_equal("5 OF 7")
		if line[0] == "DEVIATION FROM MODEL":
			assert_str(str(line[1])).starts_with("30%")
	assert_bool(found).is_true()


## The amendments accepted are kept with the profile and counted with the rest of the terms.
func test_the_amendments_are_kept() -> void:
	var profile := Profile.new()
	profile.story.amendments = 3
	profile.story.maps = 2
	assert_int(StoryFill.accepted_of(profile)).is_equal(5)
	var file := ConfigFile.new()
	profile.story.write(file)
	var read := StoryState.new()
	read.read(file)
	assert_int(read.amendments).is_equal(3)
