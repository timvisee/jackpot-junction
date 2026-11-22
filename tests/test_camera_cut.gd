extends GdUnitTestSuite
## The cut to a kart driven here come back out of the picture, GAME.md 8.2, see [CameraCut]: dark
## for a moment and then the camera where it is going, rather than a swoop over the whole floor;
## only for one kart driven here, and only out of the picture.

const BOUNDS := AABB(Vector3(-20.0, 0.0, -11.25), Vector3(40.0, 1.0, 22.5))
const RIG_SCENE := preload("res://scenes/camera/camera_rig.tscn")
const STEP := 0.02

var _was_fixed := false
var _was_distance := 0.0


func before_test() -> void:
	_was_fixed = Game.settings.fixed_camera
	_was_distance = Game.settings.camera_distance
	Game.settings.fixed_camera = false
	Game.settings.camera_distance = 1.0


func after_test() -> void:
	Game.settings.fixed_camera = _was_fixed
	Game.settings.camera_distance = _was_distance


## A rig following [param here], every one of them driven here, settled on them.
func _following(here: Array[Node3D]) -> CameraRig:
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
	rig.targets.assign(here)
	rig.listener_targets.assign(here)
	_run(rig, 8.0)
	return rig


func _kart(at: Vector3) -> Node3D:
	var kart: Node3D = auto_free(Node3D.new())
	add_child(kart)
	kart.global_position = at
	return kart


## Runs [param rig] for [param seconds], noting how dark the picture got.
func _run(rig: CameraRig, seconds: float) -> float:
	var darkest := 0.0
	for i: int in roundi(seconds / STEP):
		rig._process(STEP)
		darkest = maxf(darkest, rig._cut.dark)
	return darkest


func test_a_lone_kart_back_out_of_the_picture_is_cut_to() -> void:
	var kart := _kart(Vector3(-15.0, 0.0, 6.0))
	var rig := _following([kart] as Array[Node3D])
	var close := rig._distance
	kart.global_position = Vector3(16.0, 0.0, -8.0)
	# Dark by the end of the dip, the camera put on the kart with it, nothing swooping.
	var darkest := _run(rig, CameraCut.DARKEN + STEP * 2.0)
	assert_float(darkest).is_equal_approx(1.0, 0.001)
	assert_float(rig._distance).is_less(close * 1.3)
	await await_idle_frame()
	var middle := rig.get_viewport().get_visible_rect().size * 0.5
	var at := rig.camera.unproject_position(kart.global_position)
	assert_float((at - middle).length()).is_less(middle.y * 0.6)
	# And back again.
	_run(rig, CameraCut.LIGHTEN + STEP * 2.0)
	assert_float(rig._cut.dark).is_equal(0.0)


func test_a_kart_back_inside_the_picture_glides() -> void:
	var kart := _kart(Vector3(-2.0, 0.0, 0.0))
	var rig := _following([kart] as Array[Node3D])
	await await_idle_frame()
	# Further than a kart drives in a frame, and still well inside the picture, which on a square
	# test window is narrower than it is deep.
	var spot := kart.global_position + Vector3(0.0, 0.0, -(FramedSpots.JUMP + 0.5))
	assert_bool(CameraCut._in_picture(rig.camera, spot)).is_true()
	kart.global_position = spot
	assert_float(_run(rig, 1.0)).is_equal(0.0)


func test_two_karts_driven_here_are_never_cut_away_from() -> void:
	var one := _kart(Vector3(-15.0, 0.0, 6.0))
	var two := _kart(Vector3(-12.0, 0.0, 4.0))
	var rig := _following([one, two] as Array[Node3D])
	one.global_position = Vector3(16.0, 0.0, -8.0)
	assert_float(_run(rig, 1.0)).is_equal(0.0)


func test_the_fixed_camera_is_never_cut() -> void:
	Game.settings.fixed_camera = true
	var kart := _kart(Vector3(-15.0, 0.0, 6.0))
	var rig := _following([kart] as Array[Node3D])
	kart.global_position = Vector3(16.0, 0.0, -8.0)
	assert_float(_run(rig, 1.0)).is_equal(0.0)
