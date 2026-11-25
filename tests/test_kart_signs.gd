extends GdUnitTestSuite
## Where the karts are when they are hard to see, GAME.md 8.2, 8.5 and 3.6: an arrow at the edge of
## the screen for a kart out of the picture, see [KartPointers]; the rings under the karts and the
## marker over a player's own, both asked for, see [KartRings]; and the ring a kart comes back with
## breathing where it stands until it drives off, see [SpawnRing].

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner
var _was: Dictionary = {}


func before_test() -> void:
	var settings := Game.settings
	_was = {
		rings = settings.kart_rings, marker = settings.kart_marker, arrows = settings.rival_arrows
	}
	settings.kart_rings = ViewChoices.RINGS_OFF
	settings.kart_marker = false


func after_test() -> void:
	Game.settings.kart_rings = _was.rings
	Game.settings.kart_marker = _was.marker
	Game.settings.rival_arrows = _was.arrows


## A match with a player at this screen and a bot, its HUD up.
func _playing() -> Match:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = true
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.ANY, -1), KartInput.new()]
	match_node.start(inputs, 5)
	await _runner.simulate_frames(12, 17)
	return match_node


func test_a_kart_out_of_the_picture_is_pointed_at_from_the_edge() -> void:
	var match_node := await _playing()
	var pointers := match_node.hud.get_node("KartPointers") as KartPointers
	var rival := match_node.kart_of(1)
	rival.global_position = match_node.camera_rig.camera.global_position + Vector3(400.0, 0.0, 0.0)
	rival.global_position.y = 0.0
	pointers._process(0.0)
	var arrows := pointers._signs.filter(
		func(each: Dictionary) -> bool: return each.color == match_node.slots[1].color()
	)
	assert_int(arrows.size()).is_equal(1)
	var at: Vector2 = arrows[0].at
	assert_float(at.x).is_equal_approx(pointers.size.x - KartPointers.INSET, 1.0)
	assert_float((arrows[0].way as Vector2).x).is_greater(0.5)


## A rival out of the picture is pointed at as Rival arrows says: faint, smaller and see-through,
## out of the box; as bold as a kart driven here's; or not at all. A kart driven here is always
## pointed at in full.
func test_a_rivals_arrow_is_as_asked() -> void:
	var match_node := await _playing()
	var pointers := match_node.hud.get_node("KartPointers") as KartPointers
	var camera := match_node.camera_rig.camera
	for seat: int in 2:
		var kart := match_node.kart_of(seat)
		kart.global_position = camera.global_position + Vector3(400.0 * (seat * 2 - 1), 0.0, 0.0)
		kart.global_position.y = 0.0
	var of_seat := func(seat: int) -> Array:
		pointers._process(0.0)
		return pointers._signs.filter(
			func(each: Dictionary) -> bool: return each.color == match_node.slots[seat].color()
		)
	var wanted := [
		[ViewChoices.RIVAL_ARROWS_FAINT, KartPointers.ARROW_FAINT, KartPointers.FAINT],
		[ViewChoices.RIVAL_ARROWS_FULL, KartPointers.ARROW, 1.0],
	]
	for each: Array in wanted:
		Game.settings.rival_arrows = each[0]
		var rival: Array = of_seat.call(1)
		assert_int(rival.size()).is_equal(1)
		assert_float(rival[0].length).is_equal(each[1])
		assert_float(rival[0].shows).is_equal(each[2])
		var mine: Array = of_seat.call(0)
		assert_float(mine[0].length).is_equal(KartPointers.ARROW_HERE)
		assert_float(mine[0].shows).is_equal(1.0)
	Game.settings.rival_arrows = ViewChoices.RIVAL_ARROWS_OFF
	assert_array(of_seat.call(1)).is_empty()
	assert_int((of_seat.call(0) as Array).size()).is_equal(1)


## The Garage's dummies are parked targets, not players: nothing points at one out of the picture.
func test_a_dummy_out_of_the_picture_is_not_pointed_at() -> void:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = true
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.ANY, -1), DummyInput.new()]
	match_node.start(inputs, 5)
	await _runner.simulate_frames(12, 17)
	assert_bool(match_node.slots[1].is_dummy()).is_true()
	var pointers := match_node.hud.get_node("KartPointers") as KartPointers
	var dummy := match_node.kart_of(1)
	dummy.global_position = match_node.camera_rig.camera.global_position + Vector3(400.0, 0.0, 0.0)
	dummy.global_position.y = 0.0
	pointers._process(0.0)
	var arrows := pointers._signs.filter(
		func(each: Dictionary) -> bool: return each.color == match_node.slots[1].color()
	)
	assert_array(arrows).is_empty()


func test_the_marker_is_over_my_kart_only_when_asked_for() -> void:
	var match_node := await _playing()
	var pointers := match_node.hud.get_node("KartPointers") as KartPointers
	var mine := match_node.slots[0].color()
	pointers._process(0.0)
	(
		assert_bool(pointers._signs.any(func(each: Dictionary) -> bool: return each.color == mine))
		. is_false()
	)
	Game.settings.kart_marker = true
	pointers._process(0.0)
	var marks := pointers._signs.filter(func(each: Dictionary) -> bool: return each.color == mine)
	assert_int(marks.size()).is_equal(1)
	assert_vector(marks[0].way as Vector2).is_equal(Vector2.DOWN)


## The drive hint over my kart at the start is not hidden under the marker: the marker goes over it
## while it is up, and back down to the kart once it has gone.
func test_the_marker_goes_over_a_hint_hung_over_my_kart() -> void:
	var match_node := await _playing()
	var pointers := match_node.hud.get_node("KartPointers") as KartPointers
	var kart := match_node.kart_of(0)
	var mine := match_node.slots[0].color()
	Game.settings.kart_marker = true
	var hint := kart.get_node_or_null("ControlHint") as ControlHint
	if hint == null:
		hint = ControlHint.attach(kart, DeviceInput.ANY)
	await _runner.simulate_frames(2)
	var row := hint.get_node("Row") as ScreenHint
	var top := row.top_on_screen(match_node.camera_rig.camera)
	pointers._process(0.0)
	var marks := pointers._signs.filter(func(each: Dictionary) -> bool: return each.color == mine)
	assert_float((marks[0].at as Vector2).y).is_less_equal(top.y - KartPointers.OVER_HINT + 0.01)
	hint.free()
	pointers._process(0.0)
	marks = pointers._signs.filter(func(each: Dictionary) -> bool: return each.color == mine)
	assert_float((marks[0].at as Vector2).y).is_greater(top.y)


func test_the_rings_go_under_the_karts_asked_for() -> void:
	var match_node := await _playing()
	var rings := match_node.hud.get_node("KartRings") as KartRings
	rings._process(0.0)
	assert_int(rings._rings.size()).is_equal(0)
	Game.settings.kart_rings = ViewChoices.RINGS_HERE
	rings._process(0.0)
	assert_array(rings._rings.keys()).contains_exactly([match_node.kart_of(0).get_instance_id()])
	Game.settings.kart_rings = ViewChoices.RINGS_ALL
	rings._process(0.0)
	assert_int(rings._rings.size()).is_equal(2)
	Game.settings.kart_rings = ViewChoices.RINGS_OFF
	rings._process(0.0)
	assert_int(rings._rings.size()).is_equal(0)


## Never two rings round a kart: while it wears the ring it came back with, its kart ring makes
## way, and comes in once that has gone.
func test_a_kart_ring_makes_way_for_the_ring_it_came_back_with() -> void:
	var match_node := await _playing()
	var rings := match_node.hud.get_node("KartRings") as KartRings
	var kart := match_node.kart_of(0)
	var id := kart.get_instance_id()
	Game.settings.kart_rings = ViewChoices.RINGS_HERE
	# The countdown's ring is round it still, standing where it started, and one it came back with.
	SpawnRing.spawn(match_node, kart.global_position, Color.RED).hold_on(kart)
	for i: int in 30:
		rings._process(1.0 / 60.0)
	var ring: MeshInstance3D = rings._rings[id][1]
	assert_bool(ring.visible).is_false()
	for held: Node in get_tree().get_nodes_in_group(SpawnRing.GROUP):
		held.free()
	for i: int in 6:
		rings._process(1.0 / 60.0)
	# Coming in, not there at once.
	assert_bool(ring.visible).is_true()
	assert_float(rings._shown[id]).is_less(1.0)
	for i: int in roundi(KartRings.COME_IN * 60.0):
		rings._process(1.0 / 60.0)
	assert_float(rings._shown[id]).is_equal(1.0)
	var material := ring.material_override as StandardMaterial3D
	assert_float(material.albedo_color.a).is_equal_approx(KartRings.COLOR_ALPHA, 0.001)


## Every kart's ring as the countdown starts, breathing where it stands only round the karts driven
## here: a rival's flare goes as it would, nobody here having it to find.
func test_the_countdown_rings_every_kart_and_holds_the_ones_driven_here() -> void:
	var match_node := await _playing()
	var rings := match_node.hud.get_node("KartRings") as KartRings
	rings._on_state_changed(Match.State.COUNTDOWN)
	var flares := match_node.get_children().filter(
		func(node: Node) -> bool: return node is SpawnRing
	)
	assert_int(flares.size()).is_greater_equal(match_node.slots.size())
	assert_bool(SpawnRing.on(match_node.kart_of(0))).is_true()
	assert_bool(SpawnRing.on(match_node.kart_of(1))).is_false()


## The ring a kart comes back with stays round it, breathing, as long as it stands there, and goes
## once it drives off.
func test_a_held_ring_breathes_until_the_kart_drives_off() -> void:
	var kart: Node3D = auto_free(Node3D.new())
	add_child(kart)
	kart.global_position = Vector3(3.0, 0.0, 2.0)
	var ring := SpawnRing.spawn(self, kart.global_position, Color.RED).hold_on(kart)
	for i: int in int((SpawnRing.LIFETIME + 3.0) * 60.0):
		ring._process(1.0 / 60.0)
	assert_bool(ring.is_queued_for_deletion()).is_false()
	assert_float(ring._ring_material.albedo_color.a).is_greater(0.1)
	kart.global_position += Vector3(2.0, 0.0, 0.0)
	for i: int in int((SpawnRing.FADE + 0.1) * 60.0):
		ring._process(1.0 / 60.0)
	assert_bool(ring.is_queued_for_deletion()).is_true()


## Held on a kart that never gets there, as on a client whose snapshot has not moved it yet and
## then never does, it does not stay for good.
func test_a_held_ring_does_not_wait_for_good() -> void:
	var kart: Node3D = auto_free(Node3D.new())
	add_child(kart)
	kart.global_position = Vector3(30.0, 0.0, 2.0)
	var ring := SpawnRing.spawn(self, Vector3.ZERO, Color.RED).hold_on(kart)
	var frames := SpawnRing.LIFETIME + SpawnRing.ARRIVING + SpawnRing.FADE + 0.2
	for i: int in int(frames * 60.0):
		if not ring.is_queued_for_deletion():
			ring._process(1.0 / 60.0)
	assert_bool(ring.is_queued_for_deletion()).is_true()
