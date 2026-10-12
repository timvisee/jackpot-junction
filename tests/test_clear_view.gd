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
		middle, points, corners, 40.0, 0.0, 24.0, 60.0, fit, fit, Vector2.ZERO, true
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
		low, points, corners, 40.0, 0.0, 24.0, 60.0, fit, fit, Vector2.ZERO, true
	)
	assert_float(absf(first.slide.x)).is_less_equal(ClearView.STEP + 0.001)
	assert_float(absf(first.slide.y)).is_less_equal(ClearView.STEP + 0.001)
	# Between looks the slide in use is held.
	var held := ClearView.solve(
		low, points, corners, 40.0, 0.0, 24.0, 60.0, fit, fit, first.slide, false
	)
	assert_that(held.slide).is_equal(first.slide)


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


## Cheap enough to look every tenth of a second: eight karts and a full HUD in about a millisecond a
## look on a desktop, and a few on a slow machine.
func test_a_look_is_cheap() -> void:
	var places: Array = []
	for i: int in 8:
		places.append(Vector3(-17.0 + 4.8 * i, 0.0, 9.0 if i % 2 == 0 else -9.0))
	var covers: Array[Rect2] = [CORNER, STANDINGS, STRIP, Rect2(0.7, 0.0, 0.3, 0.32)]
	var rig := _watching(places, covers)
	var started := Time.get_ticks_usec()
	for i: int in 20:
		rig._clear_left = 0.0
		rig._target_framing()
	var each := float(Time.get_ticks_usec() - started) / 20.0
	assert_float(each).is_less(4000.0)


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
		inputs.append(PlayerInput.new(i, i) if i < seats else KartInput.new())
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
		var covers := (hud.get_node("Covers") as HudCovers).covers()
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
