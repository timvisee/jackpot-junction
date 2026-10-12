extends GdUnitTestSuite
## Keeping the karts out from under the HUD, GAME.md 8.2: the rig goes further back or slides its
## aim until no kart it follows is under anything the HUD lays over the screen, see [ClearView]; a
## panel over the middle, which no distance clears, is left rather than the rig running away.

const BOUNDS := AABB(Vector3(-20.0, 0.0, -11.25), Vector3(40.0, 1.0, 22.5))
const RIG_SCENE := preload("res://scenes/camera/camera_rig.tscn")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const CATALOG: JokerCatalog = preload("res://data/jokers/catalog.tres")
## A player's corner at a big UI scale, the standings down the right, and a pick along the foot, in
## shares of the screen; the test runner's screen is square.
const CORNER := Rect2(0.0, 0.0, 0.3, 0.32)
const STANDINGS := Rect2(0.76, 0.4, 0.24, 0.22)
const STRIP := Rect2(0.2, 0.78, 0.6, 0.22)

var _was_fixed := false


func before_test() -> void:
	_was_fixed = Game.settings.fixed_camera
	Game.settings.fixed_camera = false


func after_test() -> void:
	Game.settings.fixed_camera = _was_fixed


## A rig watching karts parked at [param places] with [param covers] over the screen, settled.
func _watching(places: Array, covers: Array[Rect2]) -> CameraRig:
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
	rig.covers = covers
	var karts: Array[Node3D] = []
	for at: Vector3 in places:
		var kart: Node3D = auto_free(Node3D.new())
		add_child(kart)
		kart.global_position = at
		karts.append(kart)
	rig.targets.assign(karts)
	for i: int in 400:
		rig._process(0.05)
	return rig


## Where the middle of a kart at [param at] shows, in shares of the screen.
static func _shown(rig: CameraRig, at: Vector3) -> Vector2:
	var point := at + Vector3.UP * CameraRig.KART_MIDDLE
	return rig.camera.unproject_position(point) / rig.get_viewport().get_visible_rect().size


## Which of [param places] show under one of [param covers].
static func _under(rig: CameraRig, places: Array, covers: Array[Rect2]) -> Array:
	var under := []
	for at: Vector3 in places:
		for cover: Rect2 in covers:
			if cover.has_point(_shown(rig, at)):
				under.append(at)
	return under


## A panel off the edge of the screen nearest [param shown], reaching a little past it, as the
## HUD's corners and standings hang off the edges: over the corner where it is near two of them.
static func _panel_over(shown: Vector2) -> Rect2:
	var reach := 0.07
	var x := Vector2(0.0, shown.x + reach) if shown.x < 0.5 else Vector2(shown.x - reach, 1.0)
	var y := Vector2(shown.y - reach, shown.y + reach)
	if shown.y < 0.3:
		y = Vector2(0.0, shown.y + reach)
	elif shown.y > 0.7:
		y = Vector2(shown.y - reach, 1.0)
	return Rect2(x.x, y.x, x.y - x.x, y.y - y.x)


## A kart under a panel hung off the edge nearest it, in a corner, down a side or along the foot,
## is under none once the rig has dealt with them, every kart still on the screen.
func test_no_kart_is_left_under_a_panel() -> void:
	var spreads: Array = [
		[Vector3(-17.0, 0.0, -9.0), Vector3(17.0, 0.0, 9.0)],
		[Vector3(-17.0, 0.0, -9.0), Vector3(18.0, 0.0, 0.0), Vector3(0.0, 0.0, 10.0)],
		[Vector3(-12.0, 0.0, 10.0), Vector3(12.0, 0.0, 10.0)],
	]
	var none: Array[Rect2] = []
	for places: Array in spreads:
		var plain := _watching(places, none)
		var covers: Array[Rect2] = []
		for at: Vector3 in places:
			covers.append(_panel_over(_shown(plain, at)))
		assert_array(_under(plain, places, covers)).has_size(places.size())
		var rig := _watching(places, covers)
		(
			assert_array(_under(rig, places, covers))
			. override_failure_message("a kart is left under a panel in %s" % [places])
			. is_empty()
		)
		for at: Vector3 in places:
			assert_bool(rig.camera.is_position_in_frustum(at)).is_true()


## Nothing over the screen, nothing changes: the same distance, the aim where it always is.
func test_with_nothing_over_the_screen_the_framing_is_the_plain_one() -> void:
	var places := [Vector3(-17.0, 0.0, -9.0), Vector3(6.0, 0.0, 3.0)]
	var none: Array[Rect2] = []
	var plain := _watching(places, none)
	var far: Array[Rect2] = [Rect2(0.0, 0.0, 0.05, 0.05)]
	var clear := _watching(places, far)
	assert_float(clear._distance).is_equal_approx(plain._distance, 0.01)
	assert_float(clear._across).is_equal_approx(0.0, 0.001)
	assert_float(clear._lift).is_equal_approx(plain._lift, 0.01)


## A panel over the middle of the screen holds a kart there however far back the rig goes: the kart
## is left under it, and the rig goes nowhere for it.
func test_a_panel_over_the_middle_is_left_rather_than_run_from() -> void:
	var middle: Array[Rect2] = [Rect2(0.3, 0.3, 0.4, 0.4)]
	var corners: Array[Vector3] = [Vector3(-10.0, -6.0, 0.0), Vector3(10.0, 6.0, 0.0)]
	var points: Array[Vector3] = [Vector3.ZERO]
	var fit := Vector2(0.55, 0.3)
	var answer := ClearView.solve(
		ClearView.flat(middle), points, corners, 40.0, 0.0, 24.0, 60.0, fit, fit, Vector2.ZERO, true
	)
	assert_int(answer.covered).is_equal(1)
	assert_float(answer.distance).is_less(60.0 * ClearView.FURTHEST)


## The aim glides from one slide to the next, a step a look, rather than jumping across the room.
func test_the_slide_moves_a_step_at_a_time() -> void:
	var low: Array[Rect2] = [Rect2(0.0, 0.5, 1.0, 0.5)]
	var corners: Array[Vector3] = [Vector3(-10.0, -6.0, 0.0), Vector3(10.0, 6.0, 0.0)]
	var points: Array[Vector3] = [Vector3(0.0, -6.0, 0.0)]
	var fit := Vector2(0.55, 0.3)
	var first := ClearView.solve(
		ClearView.flat(low), points, corners, 40.0, 0.0, 24.0, 60.0, fit, fit, Vector2.ZERO, true
	)
	assert_float(absf(first.slide.x)).is_less_equal(ClearView.STEP + 0.001)
	assert_float(absf(first.slide.y)).is_less_equal(ClearView.STEP + 0.001)
	# Between looks the slide in use is held.
	var held := ClearView.solve(
		ClearView.flat(low), points, corners, 40.0, 0.0, 24.0, 60.0, fit, fit, first.slide, false
	)
	assert_that(held.slide).is_equal(first.slide)


## A look taken a few slides a frame comes to the same answer as one taken at once, and no frame
## tries more than its share of slides, GAME.md 10.7.
func test_a_look_taken_a_few_slides_at_a_time_comes_to_the_same() -> void:
	var low := ClearView.flat(
		[Rect2(0.0, 0.5, 1.0, 0.5), Rect2(0.0, 0.0, 0.3, 0.3)] as Array[Rect2]
	)
	var corners: Array[Vector3] = [Vector3(-10.0, -6.0, 0.0), Vector3(10.0, 6.0, 0.0)]
	var points: Array[Vector3] = [Vector3(0.0, -6.0, 0.0), Vector3(-8.0, 5.0, 1.0)]
	var fit := Vector2(0.55, 0.3)
	var kept := Vector2(0.2, 0.0)
	var whole := ClearView.solve(
		low, points, corners, 40.0, 0.0, 24.0, 60.0, fit, fit, kept, true, 3
	)
	var look := ClearView.start(low, points, corners, 40.0, 0.0, 24.0, 60.0, fit, fit, kept, 3)
	var frames := 1
	while not look.step(CameraRig.CLEAR_TRIES):
		frames += 1
	assert_int(frames).is_greater(1)
	var answer := look.answer()
	assert_that(answer.slide).is_equal(whole.slide)
	assert_float(answer.distance).is_equal_approx(whole.distance, 0.001)


## A kart on the move is kept further clear of the HUD the faster it goes, so the camera is clear of
## where it is going by the time it has eased there; a parked one keeps a kart's room.
func test_a_moving_kart_is_kept_further_clear() -> void:
	var parked: CharacterBody3D = auto_free(CharacterBody3D.new())
	var going: CharacterBody3D = auto_free(CharacterBody3D.new())
	going.velocity = Vector3(8.0, 0.0, 0.0)
	var flying: CharacterBody3D = auto_free(CharacterBody3D.new())
	flying.velocity = Vector3(0.0, 0.0, -80.0)
	var rooms := CameraRig._rooms([parked, going, flying] as Array[Node3D])
	assert_float(rooms[0]).is_equal_approx(ClearView.KART_ROOM, 0.001)
	assert_float(rooms[1]).is_equal_approx(ClearView.KART_ROOM + 8.0 * CameraRig.SOON, 0.001)
	assert_float(rooms[2]).is_equal_approx(ClearView.KART_ROOM + CameraRig.SOON_MOST, 0.001)


## The fixed camera never follows anybody, so it keeps the whole floor out from under the HUD: it
## sits further back than it would with nothing over the screen, and the floor round the walls is
## clear of the corner.
func test_the_fixed_camera_keeps_the_floor_clear() -> void:
	Game.settings.fixed_camera = true
	var covers: Array[Rect2] = [CORNER]
	var rig := _watching([Vector3(4.0, 0.0, 2.0)], covers)
	assert_float(rig._distance).is_greater(rig._fixed_distance)
	var rim := rig._arena_points(-CameraRig.RIM_IN)
	for point: Vector3 in rim:
		var shown := (
			rig.camera.unproject_position(point) / rig.get_viewport().get_visible_rect().size
		)
		(
			assert_bool(CORNER.has_point(shown))
			. override_failure_message("the floor at %s is under the corner" % point)
			. is_false()
		)


## Cheap enough for a phone, GAME.md 10.7: a look, which works out afresh how to keep eight karts
## clear of a full HUD, comes a few times a second and is spread over a few frames, a tenth of a
## millisecond or so a frame on a desktop; a frame between looks keeps what the last one found and
## costs next to nothing more than the framing does with nothing over the screen.
func test_keeping_clear_is_cheap() -> void:
	var places: Array = []
	for i: int in 8:
		places.append(Vector3(-17.0 + 4.8 * i, 0.0, 9.0 if i % 2 == 0 else -9.0))
	var covers: Array[Rect2] = [CORNER, STANDINGS, STRIP, Rect2(0.7, 0.0, 0.3, 0.32)]
	var rig := _watching(places, covers)
	var started := Time.get_ticks_usec()
	for i: int in 20:
		rig._clear_left = 0.0
		rig._target_framing()
	var look := float(Time.get_ticks_usec() - started) / 20.0
	started = Time.get_ticks_usec()
	for i: int in 100:
		rig._clear_left = 1.0
		rig._target_framing()
	var between := float(Time.get_ticks_usec() - started) / 100.0
	var none: Array[Rect2] = []
	rig.covers = none
	started = Time.get_ticks_usec()
	for i: int in 100:
		rig._target_framing()
	var plain := float(Time.get_ticks_usec() - started) / 100.0
	assert_float(look).is_less(2000.0)
	assert_float(between).is_less(plain * 1.5 + 20.0)


## A rig following karts at [param places], the ones numbered in [param here] driven on this machine
## going [param going], meters a second, with [param covers] over the screen, settled.
func _driving(places: Array, here: Array[int], going: Vector3, covers: Array[Rect2]) -> CameraRig:
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
	rig.covers = covers
	var karts: Array[Node3D] = []
	for i: int in places.size():
		var kart: CharacterBody3D = auto_free(CharacterBody3D.new())
		add_child(kart)
		kart.global_position = places[i]
		karts.append(kart)
		if i in here:
			kart.velocity = going
			rig.listener_targets.append(kart)
	rig.targets.assign(karts)
	for i: int in 400:
		rig._process(0.05)
	return rig


## The floor ahead of a kart driven here is kept in view, GAME.md 8.2, so its player sees what they
## are driving toward: on the screen, and out from under a panel the HUD has there, the kart too.
func test_the_floor_ahead_of_a_kart_driven_here_is_kept_in_view() -> void:
	var places := [Vector3(-10.0, 0.0, -4.0), Vector3(12.0, 0.0, 6.0)]
	var here: Array[int] = [0]
	var going := Vector3(-12.0, 0.0, -6.0)
	var none: Array[Rect2] = []
	var plain := _driving(places, here, going, none)
	assert_int(plain._ahead.size()).is_equal(1)
	var ahead := plain._ahead[0]
	# As far as the kart gets in a moment, the way it is going.
	assert_float((ahead - places[0]).normalized().dot(going.normalized())).is_greater(0.99)
	var shown := (
		plain.camera.unproject_position(ahead) / plain.get_viewport().get_visible_rect().size
	)
	var covers: Array[Rect2] = [_panel_over(shown)]
	assert_bool(covers[0].has_point(shown)).is_true()
	var rig := _driving(places, here, going, covers)
	var seen := (
		rig.camera.unproject_position(rig._ahead[0]) / rig.get_viewport().get_visible_rect().size
	)
	(
		assert_bool(covers[0].has_point(seen))
		. override_failure_message("the floor ahead is under the panel at %s" % seen)
		. is_false()
	)
	assert_bool(rig.camera.is_position_in_frustum(rig._ahead[0])).is_true()
	assert_array(_under(rig, [places[0]], covers)).is_empty()


## Only the karts driven here are looked ahead of: a rival's road is not this player's. Standing
## still, a kart is looked ahead of the way it faces, a short way.
func test_only_karts_driven_here_are_looked_ahead_of() -> void:
	var places := [Vector3(-4.0, 0.0, 0.0), Vector3(6.0, 0.0, 3.0)]
	var here: Array[int] = [0]
	var none: Array[Rect2] = []
	var rig := _driving(places, here, Vector3.ZERO, none)
	var driven := rig.listener_targets[0]
	driven.rotation.y = -PI * 0.5
	rig._process(0.05)
	assert_int(rig._ahead.size()).is_equal(1)
	var ahead := rig._ahead[0] - driven.global_position
	assert_float(Vector2(ahead.x, ahead.z).length()).is_equal_approx(CameraRig.AHEAD_LEAST, 0.01)
	assert_float(ahead.x).is_greater(CameraRig.AHEAD_LEAST * 0.99)


## A match with [param seats] of its players at this screen, the rest bots, with its HUD, and a
## joker in each kart's hand.
func _match_here(seats: int) -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = true
	var inputs: Array[KartInput] = []
	for i: int in 4:
		# One player plays on every device, as a lone player does.
		var device := DeviceInput.ANY if seats == 1 else i
		inputs.append(PlayerInput.new(device, i) if i < seats else KartInput.new())
	scene_runner(match_node)
	match_node.start(inputs, 21)
	for slot: PlayerSlot in match_node.slots:
		slot.kart.jokers.add(CATALOG.jokers[0])
	return match_node


## Where [param control]'s middle is, in shares of the screen.
static func _middle_of(control: Control) -> Vector2:
	var rect := control.get_global_transform() * Rect2(Vector2.ZERO, control.size)
	return rect.get_center() / control.get_viewport().get_visible_rect().size


## Whether one of [param covers] holds [param point].
static func _held(covers: Array[Rect2], point: Vector2) -> bool:
	return covers.any(func(cover: Rect2) -> bool: return cover.has_point(point))


## What the HUD tells the camera is over the room: each corner, the standings and the cards of a
## hand, each as big as it is drawn rather than the whole screen a hand is laid out in; and a pick
## only where it shares the screen, since alone it may cover the table.
func test_the_hud_tells_the_camera_what_it_covers() -> void:
	for seats: int in [1, 2]:
		var match_node := _match_here(seats)
		var hud := match_node.hud
		var slot := match_node.slots[0]
		slot.offer = JokerOffer.new(slot.kart, CATALOG.offer(match_node.rng, 3, []))
		for i: int in 3:
			await get_tree().process_frame
		# Gathered a few times a second rather than every frame: this once, now.
		var gathering := hud.get_node("Covers") as HudCovers
		gathering._process(HudCovers.EVERY)
		var covers := gathering.covers()
		assert_array(match_node.camera_rig.covers).is_equal(covers)
		assert_bool(_held(covers, _middle_of(hud.block_of(0)))).is_true()
		assert_bool(_held(covers, _middle_of(hud.scoreboard()))).is_true()
		for cover: Rect2 in covers:
			assert_float(cover.get_area()).is_less(0.25)
		var picker := hud.picker_of(0)
		var card := picker._cards[picker._cards.size() - 1]
		assert_bool(_held(covers, _middle_of(card))).is_equal(seats > 1)
		# Sharing, the pick has the hand's place, and the hand steps aside for it.
		var hand := hud.hand_of(0)
		assert_bool(hand.visible).is_equal(seats == 1)
		if seats == 1:
			assert_bool(_held(covers, _middle_of(hand._cards[0]))).is_true()


## A pick with nobody else on this screen keeps the middle and stands over the hand of cards,
## which tucks into the bottom edge to give it room, GAME.md 8.3: nothing of the one is over the
## other. Holding the hand open reads it instead, at full size, the pick out of the way.
func test_a_lone_pick_stands_over_the_tucked_hand() -> void:
	var match_node := _match_here(1)
	var hud := match_node.hud
	var slot := match_node.slots[0]
	slot.offer = JokerOffer.new(slot.kart, CATALOG.offer(match_node.rng, 3, []))
	for i: int in 4:
		await get_tree().process_frame
	var hand := hud.hand_of(0)
	var picker := hud.picker_of(0)
	assert_bool(hand.tucked).is_true()
	assert_bool(hand.visible).is_true()
	var lowest := 0.0
	for child: Node in picker.get_children():
		var part := child as Control
		if part != null and part.visible:
			lowest = maxf(
				lowest, (part.get_global_transform() * Rect2(Vector2.ZERO, part.size)).end.y
			)
	assert_float(lowest).is_less_equal(hand.reach())
	# Pressed again every frame: a stray event from a real device on the machine can let it go. The
	# kart opens its hand on a physics tick, which a quick frame can come before.
	var aside := false
	var untucked := false
	for i: int in 60:
		Input.action_press(InputActions.JOKER_MENU)
		await get_tree().process_frame
		aside = not picker.visible
		untucked = not hand.tucked
		if aside and untucked:
			break
	Input.action_release(InputActions.JOKER_MENU)
	assert_bool(aside).is_true()
	assert_bool(untucked).is_true()


## What the camera keeps clear is drawn over a match for testing, GAME.md 8.2: not unless the
## Debug page's switch is on, or the run was asked for it with `--show-clearance`.
func test_what_the_camera_keeps_clear_is_drawn_when_asked() -> void:
	var was := Game.settings.show_clearance
	Game.settings.show_clearance = false
	var match_node := _match_here(1)
	var view := match_node.hud.get_node("Clearance") as ClearanceView
	await _frames(2)
	assert_bool(view.visible).is_false()
	ClearanceView.read_arguments(PackedStringArray(["--show-clearance"]))
	await _frames(2)
	var forced := view.visible
	ClearanceView.forced = false
	Game.settings.show_clearance = true
	await _frames(2)
	var switched := view.visible
	Game.settings.show_clearance = was
	assert_bool(forced).is_true()
	assert_bool(switched).is_true()


## Drawn to cost next to nothing while it is up, GAME.md 10.7: the panels are drawn again only as
## they change, and each kart's ring, and the bar to the floor ahead of the kart driven here, are
## the same few drawings moved about rather than made again.
func test_what_the_camera_keeps_clear_is_drawn_cheaply() -> void:
	var match_node := _match_here(1)
	var view := match_node.hud.get_node("Clearance") as ClearanceView
	ClearanceView.forced = true
	# The HUD settles first: the cards of the hand glide into place, the hints come up.
	await _frames(120)
	var draws := view.panel_draws
	var rings := view._rings.size()
	await _frames(60)
	ClearanceView.forced = false
	assert_int(view.panel_draws).is_less_equal(draws + 1)
	assert_int(view._rings.size()).is_equal(rings)
	# A ring for each kart, and one for the floor ahead of the one driven here, with its bar.
	assert_int(rings).is_equal(match_node.slots.size() + 1)
	(
		assert_int(view._bars.filter(func(bar: ColorRect) -> bool: return bar.visible).size())
		. is_equal(1)
	)


## [param count] frames, each processed: the signal comes before the frame's own processing.
func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().process_frame
