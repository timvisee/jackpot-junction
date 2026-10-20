extends GdUnitTestSuite
## Pin Alley's lamps, GAME.md 8.1c: a coin pad's ring is lit while the pad holds a chip and dark
## once it is taken, an item pad's disc the same for its box, every screen agreeing; the chevrons
## down a turbo lane chase the way it fires; a Jackpot's arrow is lit while it grows; for fewer
## flashes, 8.5, the lamps hold steady; and the lot is one thing to draw.

const MAP := "vault_xl"
const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const FRAME := 1.0 / 60.0

var _was_calm := false


func before_test() -> void:
	_was_calm = Game.settings.flash_reduction
	Game.settings.flash_reduction = false


func after_test() -> void:
	Game.settings.flash_reduction = _was_calm


func _rules() -> MatchRules:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 50.0
	return rules


func _arena() -> Arena:
	var arena: Arena = auto_free(Arena.new())
	arena.layout = load("res://data/maps/%s.tres" % MAP)
	add_child(arena)
	return arena


func _lamps(arena: Arena) -> PinballLamps:
	return arena.get_node(^"Lamps") as PinballLamps


func _start(arena: Arena) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	arena.start_economy(_rules(), rng, load("res://data/powerups/all.tres"))


## Runs the lamps on for [param seconds], a frame at a time.
func _run(lamps: PinballLamps, seconds: float) -> void:
	for i: int in ceili(seconds / FRAME):
		lamps._process(FRAME)


## The pickup lying on [param pad], or null.
func _held(pad: SpawningPad) -> Pickup:
	return pad.current if pad.current != null and is_instance_valid(pad.current) else null


## GAME.md 3.2: a coin pad's ring is lit with its chip on it, flashing as it lights, dark once
## the chip is gone, and lit again when the pad puts the next one out.
func test_a_coin_pads_lamp_is_lit_with_a_coin_and_dark_without() -> void:
	var arena := _arena()
	var lamps := _lamps(arena)
	assert_object(lamps).is_not_null()
	for pad: CoinPad in arena.coin_pads:
		var lamp := lamps.pad_lamp(arena.grid.cell_of(pad.position))
		assert_int(lamp).is_greater_equal(0)
		assert_bool(lamps.is_lit(lamp)).override_failure_message("lit with nothing").is_false()
	_start(arena)
	for pad: CoinPad in arena.coin_pads:
		assert_object(_held(pad)).is_not_null()
		assert_bool(lamps.is_lit(lamps.pad_lamp(arena.grid.cell_of(pad.position)))).is_true()
	var pad: CoinPad = arena.coin_pads[0]
	var lamp := lamps.pad_lamp(arena.grid.cell_of(pad.position))
	# It flashes as it lights and settles lit.
	assert_float(lamps.state(lamp).b).is_greater(0.5)
	_run(lamps, 1.0)
	assert_float(lamps.lit_now(lamp)).is_equal_approx(1.0, 0.001)
	assert_float(lamps.state(lamp).b).is_equal_approx(0.0, 0.001)
	# Taken, it goes dark; the others stay lit.
	pad._respawn_left = 999.0
	_held(pad).queue_free()
	await await_idle_frame()
	assert_bool(lamps.is_lit(lamp)).override_failure_message("lit once taken").is_false()
	_run(lamps, 1.0)
	assert_float(lamps.lit_now(lamp)).is_equal_approx(0.0, 0.001)
	var other := lamps.pad_lamp(arena.grid.cell_of(arena.coin_pads[1].position))
	assert_bool(lamps.is_lit(other)).is_true()
	# And lit again with the next one.
	pad._respawn_left = 0.0
	pad._physics_process(FRAME)
	assert_object(_held(pad)).is_not_null()
	assert_bool(lamps.is_lit(lamp)).is_true()


## GAME.md 7.1: an item pad's disc is lit with its box on it and dark once it is taken; a chip
## dropped on a pad that is not its middle lights nothing.
func test_an_item_pads_lamp_is_lit_with_an_item_and_dark_without() -> void:
	var arena := _arena()
	var lamps := _lamps(arena)
	_start(arena)
	assert_int(arena.power_pads.size()).is_greater(0)
	for pad: PowerUpPad in arena.power_pads:
		var lamp := lamps.pad_lamp(arena.grid.cell_of(pad.position))
		assert_int(lamp).is_greater_equal(0)
		assert_int(int(lamps.state(lamp).r)).is_equal(PinballLamps.Kind.ITEM)
		assert_bool(lamps.is_lit(lamp)).is_true()
	var pad: PowerUpPad = arena.power_pads[0]
	var lamp := lamps.pad_lamp(arena.grid.cell_of(pad.position))
	pad._respawn_left = 999.0
	_held(pad).queue_free()
	await await_idle_frame()
	assert_bool(lamps.is_lit(lamp)).is_false()
	var stray := Chip.new()
	arena.place_drop(stray, pad.position + Vector3(0.4, 0.0, 0.0))
	assert_bool(lamps.is_lit(lamp)).override_failure_message("a stray chip lit it").is_false()


## GAME.md 10.3: a client is sent the floor, not the lamps, and lights the same ones the host
## does, a pad's lamp going dark on both once its chip is taken.
func test_a_client_lights_the_lamps_the_host_does() -> void:
	var host: Match = auto_free(MATCH_SCENE.instantiate())
	host.rules = _rules()
	host.with_hud = false
	host.arena_layout = load("res://data/maps/%s.tres" % MAP)
	var runner := scene_runner(host)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	host.start(inputs, 23)
	await runner.simulate_frames(20, 17)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = host.rules
	client.with_hud = false
	client.arena_layout = host.arena_layout
	add_child(client)
	client.start_puppet()
	client.apply_snapshot(host.build_snapshot())
	var mine := _lamps(host.arena)
	var theirs := _lamps(client.arena)
	assert_int(theirs.multimesh.instance_count).is_equal(mine.multimesh.instance_count)
	var taken: CoinPad = host.arena.coin_pads[2]
	_assert_agree(host, mine, theirs)
	taken._respawn_left = 999.0
	_held(taken).queue_free()
	await runner.simulate_frames(2, 17)
	client.apply_snapshot(host.build_snapshot())
	await runner.simulate_frames(2, 17)
	var lamp := mine.pad_lamp(host.arena.grid.cell_of(taken.position))
	assert_bool(mine.is_lit(lamp)).is_false()
	_assert_agree(host, mine, theirs)


func _assert_agree(host: Match, mine: PinballLamps, theirs: PinballLamps) -> void:
	var lit := 0
	var pads: Array[SpawningPad] = []
	pads.append_array(host.arena.coin_pads)
	pads.append_array(host.arena.power_pads)
	for pad: SpawningPad in pads:
		var lamp := mine.pad_lamp(host.arena.grid.cell_of(pad.position))
		assert_bool(mine.is_lit(lamp)).is_equal(_held(pad) != null)
		(
			assert_bool(theirs.is_lit(lamp))
			. override_failure_message("the client's lamp %d disagrees" % lamp)
			. is_equal(mine.is_lit(lamp))
		)
		if mine.is_lit(lamp):
			lit += 1
	assert_int(lit).is_greater(0)


## The chevrons down every turbo lane are the one look's, run in its order from the plate the
## way the lane fires, and a kart on the plate sends a run of light down it.
func test_the_chevrons_chase_the_way_their_lane_fires() -> void:
	var arena := _arena()
	var lamps := _lamps(arena)
	assert_object(lamps.look()).is_not_null()
	assert_object(lamps.look().shader).is_equal(PinballLamps.SHADER)
	assert_object(lamps.material_override).is_equal(lamps.look())
	assert_float(lamps.look().get_shader_parameter(&"steady")).is_equal(0.0)
	assert_int(arena.turbo_pads.size()).is_greater(0)
	for i: int in arena.turbo_pads.size():
		var pad: TurboPad = arena.turbo_pads[i]
		var lane := lamps.lane(i)
		assert_int(lane.size()).is_equal(PinballInserts.CHEVRONS)
		var way := Vector3(pad.direction.x, 0.0, pad.direction.z).normalized()
		var last := -INF
		for k: int in lane.size():
			var lamp := lane[k]
			var state := lamps.state(lamp)
			assert_int(int(state.r)).is_equal(PinballLamps.Kind.CHEVRON)
			assert_float(state.a).is_equal(float(k))
			assert_bool(lamps.is_lit(lamp)).is_true()
			var place := lamps.place(lamp)
			# Pointing the way the pad fires, and further down the lane the later in the run.
			assert_vector(place.basis.x.normalized()).is_equal_approx(way, Vector3.ONE * 0.001)
			var along := (place.origin - pad.position).dot(way)
			assert_float(along).is_greater(last)
			last = along
	var kart := Kart.new()
	lamps._on_plate(kart, 0)
	kart.free()
	for lamp: int in lamps.lane(0):
		assert_float(lamps.state(lamp).b).is_equal(1.0)
	_run(lamps, PinballLamps.LAUNCH + 0.1)
	for lamp: int in lamps.lane(0):
		assert_float(lamps.state(lamp).b).is_equal_approx(0.0, 0.001)


## GAME.md 8.5: for a player who asked for fewer flashes the lamps hold steady, and a pad's lamp
## lights without its flash; asked for mid-match, the look holds steady within a moment.
func test_fewer_flashes_holds_the_lamps_steady() -> void:
	Game.settings.flash_reduction = true
	var arena := _arena()
	var lamps := _lamps(arena)
	assert_float(lamps.look().get_shader_parameter(&"steady")).is_equal(1.0)
	_start(arena)
	for pad: CoinPad in arena.coin_pads:
		var lamp := lamps.pad_lamp(arena.grid.cell_of(pad.position))
		assert_bool(lamps.is_lit(lamp)).is_true()
		assert_float(lamps.state(lamp).b).override_failure_message("it flashed").is_equal(0.0)
	Game.settings.flash_reduction = false
	await await_millis(int(PinballLamps.LOOK_EVERY * 1000.0) + 200)
	assert_float(lamps.look().get_shader_parameter(&"steady")).is_equal(0.0)
	Game.settings.flash_reduction = true
	await await_millis(int(PinballLamps.LOOK_EVERY * 1000.0) + 200)
	assert_float(lamps.look().get_shader_parameter(&"steady")).is_equal(1.0)


## GAME.md 3.5: a Jackpot's arrow is lit while that Jackpot is the one growing and dark while it
## is not, and pulses once it holds as much as turns its light amber.
func test_a_jackpots_arrow_is_lit_while_it_grows() -> void:
	var arena := _arena()
	var lamps := _lamps(arena)
	_start(arena)
	lamps._look_round()
	assert_int(arena.jackpot_zones.size()).is_equal(2)
	for zone: JackpotZone in arena.jackpot_zones:
		var arrow := lamps.arrow(zone.index)
		assert_int(arrow).is_greater_equal(0)
		assert_bool(lamps.is_lit(arrow)).is_equal(zone.active)
	var growing: JackpotZone = arena.jackpot_zones[0]
	arena.activate_jackpot(growing.index)
	growing.chips = float(growing.rules.jackpot_amber)
	lamps._look_round()
	_run(lamps, 1.0)
	var arrow := lamps.arrow(growing.index)
	assert_float(lamps.lit_now(arrow)).is_equal_approx(1.0, 0.001)
	assert_float(lamps.state(arrow).b).is_equal_approx(1.0, 0.001)
	var other := lamps.arrow(arena.jackpot_zones[1].index)
	assert_float(lamps.lit_now(other)).is_equal_approx(0.0, 0.001)


## GAME.md 10.7: every lamp is an instance of one multimesh, drawn in one look, casting no
## shadow, with no light among them, lying a hair over the floor and under the pads' inlays.
func test_the_lamps_are_one_thing_to_draw() -> void:
	var arena := _arena()
	var lamps := _lamps(arena)
	var grid := arena.grid
	var count := (
		grid.coin_pads.size()
		+ grid.power_pads.size()
		+ PinballInserts.chevrons(grid).size()
		+ PinballInserts.arrows(grid).size()
	)
	assert_int(lamps.multimesh.instance_count).is_equal(count)
	assert_int(lamps.multimesh.mesh.get_surface_count()).is_equal(1)
	assert_int(lamps.cast_shadow).is_equal(GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	assert_array(lamps.find_children("*", "Light3D", true, false)).is_empty()
	for i: int in lamps.multimesh.instance_count:
		var y := lamps.place(i).origin.y
		assert_float(y).is_greater(0.0)
		assert_float(y).is_less(ArenaPads.LIFT)
