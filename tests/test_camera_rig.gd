extends GdUnitTestSuite
## The camera rig from GAME.md 8.2: it frames the karts rather than the arena, coming in as close
## as it can while keeping every one of them on screen.

const BOUNDS := AABB(Vector3(-20.0, 0.0, -11.25), Vector3(40.0, 1.0, 22.5))
const RIG_SCENE := preload("res://scenes/camera/camera_rig.tscn")


## A rig watching karts parked at [param places], settled.
func _watching(places: Array) -> CameraRig:
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
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


func test_framing_distance_is_sensible_and_the_camera_looks_down_at_the_centre() -> void:
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
	assert_float(rig._distance).is_between(25.0, 90.0)
	var forward := -rig.camera.global_basis.z
	assert_float(forward.y).is_less(-0.7)
	assert_float(rig.camera.global_position.y).is_greater(20.0)


func test_every_arena_corner_is_inside_the_frustum_after_a_frame() -> void:
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
	await await_idle_frame()
	rig.camera.fov = rig.base_fov * rig.zoom_min
	for x: float in [-20.0, 20.0]:
		for z: float in [-11.25, 11.25]:
			for y: float in [0.0, 1.0]:
				var corner := Vector3(x, y, z)
				(
					assert_bool(rig.camera.is_position_in_frustum(corner))
					. override_failure_message("corner %s not visible" % corner)
					. is_true()
				)


func test_pan_follows_the_targets_but_stays_within_the_limit() -> void:
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
	var far_target: Node3D = auto_free(Node3D.new())
	add_child(far_target)
	far_target.global_position = Vector3(18.0, 0.0, 10.0)
	rig.targets.assign([far_target])
	var pan: Vector3 = rig._target_pan()
	assert_float(pan.length()).is_equal_approx(rig.pan_limit, 0.001)
	assert_float(pan.x).is_greater(0.0)
	assert_float(pan.z).is_greater(0.0)


## GAME.md 8.4: a frantic match gives the camera a faint constant tremble, and the toggle in 8.5
## still switches every kind of shake off.
func test_a_tremble_keeps_the_camera_shaking_and_the_setting_still_silences_it() -> void:
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
	var shake_was := Game.settings.screen_shake
	Game.settings.screen_shake = true
	rig._shake = 0.0
	rig.tremble = 1.0
	await await_idle_frame()
	await await_idle_frame()
	assert_float(rig._shake).is_greater(0.0)
	rig.tremble = 0.0
	# Stepped by hand rather than by idle frames, which in a headless run are however long they
	# happen to be and say nothing about how long a shake takes to die away.
	for i: int in 40:
		rig._process(0.1)
	assert_float(rig._shake).is_equal_approx(0.0, 0.001)
	Game.settings.screen_shake = false
	rig.tremble = 1.0
	for i: int in 4:
		rig._process(0.1)
	assert_float(rig._shake).is_equal_approx(0.0, 0.001)
	Game.settings.screen_shake = shake_was


## GAME.md 8.2: the camera comes in on the karts. A fight in one corner of the arena is not a
## reason to keep the other three corners and the crowd on the screen.
func test_the_camera_comes_in_when_the_karts_are_together() -> void:
	var huddle: Array[Vector3] = [
		Vector3(4.0, 0.0, 2.0),
		Vector3(6.0, 0.0, 3.0),
		Vector3(5.0, 0.0, 4.5),
	]
	var rig := _watching(huddle)
	var wide: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(wide)
	wide.frame_arena(BOUNDS)
	assert_float(rig._distance).is_less(wide._distance * 0.8)
	assert_float(rig._distance).is_greater_equal(rig.follow_min_distance - 0.01)
	# And it is looking at them rather than at the middle of the floor.
	assert_float((rig._center + rig._pan).distance_to(Vector3(5.0, 0.0, 3.25))).is_less(1.0)


## However far apart they get, every one of them is still on the screen.
func test_every_kart_stays_on_screen_wherever_they_are() -> void:
	var spreads: Array = [
		[Vector3(4.0, 0.0, 2.0), Vector3(6.0, 0.0, 3.0)],
		[Vector3(-18.0, 0.0, -9.0), Vector3(18.0, 0.0, 9.0)],
		[Vector3(-18.0, 0.0, 9.0), Vector3(0.0, 0.0, 0.0), Vector3(18.0, 0.0, -9.0)],
	]
	for places: Array in spreads:
		var rig := _watching(places)
		for at: Vector3 in places:
			(
				assert_bool(rig.camera.is_position_in_frustum(at))
				. override_failure_message("a kart at %s is off the screen" % at)
				. is_true()
			)


## Spread to opposite corners they need the whole room again, and with nobody to follow the rig
## waits at the widest it goes.
func test_the_camera_pulls_back_out_for_a_spread_field_and_for_nobody() -> void:
	var huddled := _watching([Vector3(4.0, 0.0, 2.0), Vector3(6.0, 0.0, 3.0)])
	var spread := _watching([Vector3(-18.0, 0.0, -9.0), Vector3(18.0, 0.0, 9.0)])
	assert_float(spread._distance).is_greater(huddled._distance * 1.4)
	var empty := _watching([])
	assert_float(empty._distance).is_equal_approx(empty._arena_distance, 0.01)
