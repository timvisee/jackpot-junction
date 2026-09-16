extends GdUnitTestSuite
## The camera rig frames the whole arena from GAME.md 8.2 at a sensible distance.

const BOUNDS := AABB(Vector3(-20.0, 0.0, -11.25), Vector3(40.0, 1.0, 22.5))
const RIG_SCENE := preload("res://scenes/camera/camera_rig.tscn")


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
	for i: int in 30:
		await await_idle_frame()
	assert_float(rig._shake).is_equal_approx(0.0, 0.001)
	Game.settings.screen_shake = false
	rig.tremble = 1.0
	for i: int in 4:
		await await_idle_frame()
	assert_float(rig._shake).is_equal_approx(0.0, 0.001)
	Game.settings.screen_shake = shake_was
