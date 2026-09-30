extends GdUnitTestSuite
## The aim guide and the free-aim arrow, GAME.md 5.1: drawn from the kart as it is drawn, between
## physics ticks, not from where the last tick left it. On a screen that draws faster than the
## physics runs, a phone's at 90 Hz, dots placed off the tick jumped back and forth against the
## smoothed kart every frame.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")


func _start() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	add_child(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD, 0), KartInput.new()]
	match_node.start(inputs, 5)
	return match_node


## Neither is smoothed again by the engine: they are placed every drawn frame already, and
## smoothing that would put them a tick behind the kart they hang off.
func test_the_guide_and_the_arrow_are_not_smoothed_twice() -> void:
	var match_node := _start()
	await await_millis(80)
	var kart := match_node.kart_of(0)
	assert_object(kart._aim_guide).is_not_null()
	assert_int(kart._aim_guide.physics_interpolation_mode).is_equal(
		Node.PHYSICS_INTERPOLATION_MODE_OFF
	)
	assert_int(kart._aim_arrow.physics_interpolation_mode).is_equal(
		Node.PHYSICS_INTERPOLATION_MODE_OFF
	)


## Aimed down the nose, the guide turns with the kart as drawn; aimed by a stick, it points where
## the stick does, whichever way the drawn kart has turned.
func test_the_aim_turns_with_the_drawn_kart_only_when_it_follows_the_nose() -> void:
	var match_node := _start()
	await await_millis(80)
	var kart := match_node.kart_of(0)
	kart.global_basis = Basis.IDENTITY
	# Drawn a quarter turn round from where the tick has it.
	var shown := Transform3D(Basis(Vector3.UP, PI * 0.5), kart.global_position)
	var nose := KartAim.shown_direction(kart, shown)
	assert_vector(nose).is_equal_approx(-shown.basis.z, Vector3.ONE * 0.001)
	# A swivel cannon, as a client knows it from the arrow the host sends: the stick's way.
	kart.puppet = true
	kart.aim_arrow_visible = true
	(kart.input as PlayerInput).aim = Vector2(1.0, 0.0)
	assert_vector(KartAim.shown_direction(kart, shown)).is_equal_approx(
		Vector3.RIGHT, Vector3.ONE * 0.001
	)
	kart.puppet = false
	kart.aim_arrow_visible = false


## The first dot stands a muzzle and a spacing ahead of the kart as drawn, at a shot's height.
func test_the_dots_hang_off_the_drawn_kart() -> void:
	var match_node := _start()
	await await_millis(80)
	var kart := match_node.kart_of(0)
	var guide := KartAim.draw(kart, kart._aim_arrow, kart._aim_guide)
	var shown := kart.get_global_transform_interpolated()
	var toward := KartAim.shown_direction(kart, shown)
	var first: Vector3 = guide._dots[0].global_position
	var expected := shown.origin + toward * (kart.cannon_stats.muzzle_offset + AimGuide.SPACING)
	assert_float(first.y).is_equal_approx(Bullet.HEIGHT, 0.001)
	assert_float(Vector2(first.x, first.z).distance_to(Vector2(expected.x, expected.z))).is_less(
		0.001
	)
