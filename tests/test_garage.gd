extends GdUnitTestSuite
## The Garage, GAME.md 9.4: a practice room with everything on the floor, nobody to fight but a
## pair of dummies to shoot at, and no clock running.

const GARAGE_SCENE := preload("res://scenes/garage/garage.tscn")
const GARAGE_SCRIPT := preload("res://scenes/garage/garage.gd")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/garage.tres")
const RULES: MatchRules = preload("res://data/match/garage.tres")

var _runner: GdUnitSceneRunner


func test_the_map_has_one_of_everything_to_practice_on() -> void:
	assert_array(LAYOUT.validate()).is_empty()
	var grid := LAYOUT.parse()
	# Four spawn points: two for players and two for the dummies to stand on.
	assert_int(grid.spawns.size()).is_equal(4)
	assert_int(grid.targets.size()).is_equal(3)
	assert_int(grid.joker_pads.size()).is_equal(1)
	assert_int(grid.turbo_pads.size()).is_equal(2)
	assert_int(grid.flush_pads.size()).is_equal(4)
	assert_int(grid.coin_pads.size()).is_greater_equal(4)
	assert_int(grid.power_pads.size()).is_greater_equal(2)
	assert_int(grid.crates.size()).is_greater_equal(8)
	assert_int(grid.pits.size()).is_equal(1)
	assert_int(grid.jackpots.size()).is_equal(1)
	assert_int(grid.slot_pads.size()).is_equal(1)
	# The Junction sits in the middle of the room.
	var middle := grid.rect_center(grid.junction)
	assert_vector(middle).is_equal_approx(Vector3.ZERO, Vector3.ONE * 0.01)
	# The Royal Flush pads stand on one ring round it, the outer of the two painted there.
	var ring := grid.cell_center(grid.flush_pads[0]).distance_to(middle)
	for pad: Vector2i in grid.flush_pads:
		assert_float(grid.cell_center(pad).distance_to(middle)).is_equal_approx(ring, 0.01)


## GAME.md 9.4: the floor round the Junction is open to drift round, out to past the outer ring and
## the lift's bay: nothing on it but the Junction and the Royal Flush pads on the ring.
func test_the_rings_run_on_open_floor() -> void:
	var grid := LAYOUT.parse()
	var middle := grid.rect_center(grid.junction)
	var ring := grid.cell_center(grid.flush_pads[0]).distance_to(middle)
	var clear := ring + grid.cell_size * 0.5
	for y: int in grid.height:
		for x: int in grid.width:
			var cell := Vector2i(x, y)
			if grid.glyph(cell) in [ArenaGrid.FLOOR, ArenaGrid.FLUSH_PAD, ArenaGrid.JUNCTION]:
				continue
			assert_float(grid.cell_center(cell).distance_to(middle)).is_greater(clear)
	# The lift's bay is open floor in the front left corner, well off the rings.
	var lift: Vector2i = GARAGE_SCRIPT.LIFT
	for y: int in KartLift.CELLS.y:
		for x: int in KartLift.CELLS.x:
			var cell := lift + Vector2i(x, y)
			assert_str(grid.glyph(cell)).is_equal(ArenaGrid.FLOOR)
			assert_float(grid.cell_center(cell).distance_to(middle)).is_greater(clear)


## GAME.md 9.4: nothing has a sign over it, so the floor is painted with what each part of it is
## for: two rings round the Junction, the outer one through the Royal Flush pads, old marks of laps
## round them, the targets' lanes and their firing line, the dummies' numbered bays and the pit's
## stripes.
func test_the_floor_is_painted_for_what_each_part_is_for() -> void:
	var garage: Node3D = auto_free(GARAGE_SCENE.instantiate())
	var runner: GdUnitSceneRunner = scene_runner(garage)
	await runner.simulate_frames(60, 17)
	var match_node: Match = garage.get_node("Match")
	var paint: GarageFloor = garage.get("floor_paint")
	assert_object(paint).is_not_null()
	var middle := match_node.arena.junction_position
	for pad: FlushPad in match_node.arena.flush_pads:
		var reach := pad.global_position - middle
		assert_float(Vector2(reach.x, reach.z).length()).is_equal_approx(paint.outer, 0.05)
	assert_float(paint.inner).is_greater(match_node.arena.junction_radius)
	assert_float(paint.inner).is_less(paint.outer)
	for mesh: MeshInstance3D in [paint.rings, paint.lines, paint.marks]:
		assert_int(mesh.mesh.get_surface_count()).is_equal(1)
	var words: Array[String] = []
	for label: Node in paint.find_children("*", "Label3D", false, false):
		words.append((label as Label3D).text)
	assert_array(words).contains_exactly_in_any_order([GarageFloor.FIRING_WORDS, "1", "2"])


func test_the_room_runs_one_player_two_dummies_and_no_clock() -> void:
	# Nothing is heard on the way in either: the tones and the flag both come from the countdown,
	# and there is none. Watched from before the room is built, so nothing can be missed.
	var start_cues: Array[int] = []
	var tone := func(count: int) -> void: start_cues.append(count)
	var flag := func() -> void: start_cues.append(0)
	Events.countdown_tick.connect(tone)
	Events.countdown_done.connect(flag)
	var garage: Node3D = auto_free(GARAGE_SCENE.instantiate())
	var runner: GdUnitSceneRunner = scene_runner(garage)
	# Long enough for the countdown to run out, so the room is actually under way.
	await runner.simulate_frames(120, 17)
	var match_node: Match = garage.get_node("Match")
	assert_int(match_node.slots.size()).is_equal(3)
	assert_bool(match_node.slots[0].is_local_human()).is_true()
	assert_object(match_node.slots[0].bot_trait).is_null()
	# The other two are dummies rather than bots: nobody is playing against anybody in here.
	for slot: PlayerSlot in [match_node.slots[1], match_node.slots[2]]:
		assert_bool(slot.is_dummy()).is_true()
		assert_object(slot.bot_trait).is_null()
	assert_int(match_node.arena.targets.size()).is_equal(3)
	assert_int(match_node.arena.joker_pads.size()).is_equal(1)
	# No nightclub in here, whatever the excitement meter says.
	assert_bool(match_node.arena.disco.enabled).is_false()
	match_node.arena.disco.level = DiscoLights.COUNT
	await runner.simulate_frames(10, 17)
	assert_int(match_node.arena.disco.lit_count()).is_equal(0)
	# The clock stands still, so the room never reaches Last Call or the results.
	assert_bool(match_node.rules.timed).is_false()
	var left := match_node.time_left
	await runner.simulate_frames(40, 17)
	assert_float(match_node.time_left).is_equal(left)
	assert_int(match_node.state).is_equal(Match.State.PLAYING)
	assert_bool(match_node.hud._timer.visible).is_false()
	# Nobody is held on a grid in here, GAME.md 9.4: no countdown, so no gantry and no tones.
	Events.countdown_tick.disconnect(tone)
	Events.countdown_done.disconnect(flag)
	assert_float(match_node.rules.countdown).is_equal(0.0)
	assert_bool(match_node.hud._light.visible).is_false()
	assert_array(start_cues).is_empty()


func test_shooting_a_target_pays_the_shooter() -> void:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.arena_layout = LAYOUT
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start([KartInput.new()] as Array[KartInput], 43)
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var target: Target = match_node.arena.targets[0]
	assert_int(kart.pot.coins).is_equal(0)
	# Lined up 4 m below the target, shooting straight up the table.
	kart.global_position = target.global_position + Vector3(0.0, 0.0, 4.0)
	kart.face(Vector3(0.0, 0.0, -1.0))
	kart.cannon.stats.aim_assist = false
	kart.cannon.cooldown_left = 0.0
	await _runner.simulate_frames(2, 17)
	kart.cannon.fire(
		match_node.bullets,
		0,
		kart.global_position + Vector3(0.0, 0.0, -1.0),
		Vector3(0.0, 0.0, -1.0),
		Color.WHITE
	)
	await _runner.simulate_frames(20, 17)
	assert_bool(target.alive).is_false()
	assert_int(kart.pot.coins).is_equal(rules.target_coins)
	assert_float(match_node.slots[0].stats.value(&"targets")).is_equal(1.0)


## GAME.md 9.4: the dummies are targets rather than opponents. Nobody drives them, they carry
## something worth shooting them for, and they come back carrying something new, each to its own
## bay, backed in and facing out into the room.
func test_the_dummies_carry_loot_stand_still_and_come_back_restocked() -> void:
	var garage: Node3D = auto_free(GARAGE_SCENE.instantiate())
	var runner: GdUnitSceneRunner = scene_runner(garage)
	await runner.simulate_frames(120, 17)
	var match_node: Match = garage.get_node("Match")
	var dummies: Array[PlayerSlot] = []
	for slot: PlayerSlot in match_node.slots:
		if slot.is_dummy():
			dummies.append(slot)
	assert_int(dummies.size()).is_equal(2)
	for slot: PlayerSlot in dummies:
		assert_str(slot.display_name()).contains("Dummy")
		assert_int(slot.kart.pot.coins).is_greater(0)
		assert_object(slot.kart.held_item).is_not_null()
	var kart := dummies[0].kart
	var parked := kart.global_position
	assert_vector(parked).is_equal_approx(match_node.arena.spawn_points[1], Vector3.ONE * 0.05)
	assert_vector(-kart.global_basis.z).is_equal_approx(Vector3.BACK, Vector3.ONE * 0.01)
	await runner.simulate_frames(90, 17)
	# Standing where it was put, with nothing fired, however long the room runs.
	assert_vector(kart.global_position).is_equal_approx(parked, Vector3.ONE * 0.05)
	assert_float(dummies[0].stats.value(&"bullets")).is_equal(0.0)
	kart.die(&"bullet", 0)
	assert_bool(kart.alive).is_false()
	await runner.simulate_frames(200, 17)
	assert_bool(kart.alive).is_true()
	assert_int(kart.pot.coins).is_greater(0)
	assert_object(kart.held_item).is_not_null()
	# Back in its own bay rather than at whichever spawn was farthest from the player.
	assert_vector(kart.global_position).is_equal_approx(parked, Vector3.ONE * 0.05)
	assert_vector(-kart.global_basis.z).is_equal_approx(Vector3.BACK, Vector3.ONE * 0.01)


## GAME.md 9.4: the Garage is a room for trying the button rather than for rationing it, so a
## tank fills in a few seconds instead of a minute and a half.
func test_nitro_comes_back_almost_at_once_in_here() -> void:
	assert_float(RULES.nitro_recharge_base).is_greater(10.0)
	var garage: Node3D = auto_free(GARAGE_SCENE.instantiate())
	var runner: GdUnitSceneRunner = scene_runner(garage)
	await runner.simulate_frames(120, 17)
	var match_node: Match = garage.get_node("Match")
	var kart := match_node.kart_of(0)
	kart.nitro_charge = 0.0
	await runner.simulate_frames(60, 17)
	# A second of standing still is worth a fifth of a tank in here; in a match it is a ninetieth.
	assert_float(kart.nitro_charge).is_greater(0.15)


## GAME.md 9.4: a room with no clock and no target has no running order, so the standings stand
## down. Two dummy karts ranked against the player is a table about nothing.
func test_the_garage_shows_no_standings() -> void:
	var garage: Node3D = auto_free(GARAGE_SCENE.instantiate())
	var runner: GdUnitSceneRunner = scene_runner(garage)
	await runner.simulate_frames(30, 17)
	var match_node: Match = garage.get_node("Match")
	assert_bool(match_node.hud._scoreboard.visible).is_false()


## GAME.md 9.4 and 4.4: the kart is dressed on the lift along the front wall rather than at stalls.
## Stopped in its bay, the kart dialog comes up on the seat's tab over the room, which waits under
## it; a piece worn there is on the kart in the room at once; put away, the room goes on, and the
## kart has to leave the bay before stopping in it brings the dialog up again. The pause menu has
## a way to it too.
func test_stopping_on_the_lift_brings_the_kart_dialog_up() -> void:
	var settings_were := Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_garage_lift.cfg"
	var garage: Node3D = auto_free(GARAGE_SCENE.instantiate())
	var runner: GdUnitSceneRunner = scene_runner(garage)
	await runner.simulate_frames(60, 17)
	var match_node: Match = garage.get_node("Match")
	assert_object(match_node.arena.find_child("StyleStalls", false, false)).is_null()
	assert_object(garage.find_child("YourKart", true, false)).is_not_null()
	var lift: KartLift = garage.get("lift")
	var kart := match_node.kart_of(0)
	var middle := lift.area.get_center()
	kart.global_position = Vector3(middle.x, kart.global_position.y, middle.y)
	kart.velocity = Vector3.ZERO
	await runner.simulate_frames(60, 17)
	var dialog := garage.get_node_or_null("KartDialog") as KartDialog
	assert_object(dialog).is_not_null()
	assert_bool(garage.get_tree().paused).is_true()
	assert_int(dialog.kart_owner().seat).is_equal(0)
	var cap := KartStyle.HATS.find("Cap")
	assert_bool(dialog.wear(1, cap)).is_true()
	assert_int(kart.style.hat).is_equal(cap)
	assert_int(match_node.slots[0].style.hat).is_equal(cap)
	assert_int(KartStyle.from_array(Game.settings.seat_style(0)).hat).is_equal(cap)
	dialog.close()
	await runner.simulate_frames(10, 17)
	assert_bool(garage.get_tree().paused).is_false()
	assert_object(garage.get_node_or_null("KartDialog")).is_null()
	# Still standing in the bay: no dialog again until it has left it.
	await runner.simulate_frames(60, 17)
	assert_object(garage.get_node_or_null("KartDialog")).is_null()
	garage.get_tree().paused = false
	Settings.remove_files("user://test_garage_lift.cfg")
	Game.settings = settings_were
