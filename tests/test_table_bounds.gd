extends GdUnitTestSuite
## The picture kept over the arena while the camera follows, GAME.md 8.2, see [TableBounds]: no
## more than a strip at each edge of the screen past it, the arena in the middle where the view is
## wider than it.

const BOUNDS := AABB(Vector3(-20.0, 0.0, -11.25), Vector3(40.0, 1.0, 22.5))
const HALF := Vector2(20.0, 11.25)
const RIG_SCENE := preload("res://scenes/camera/camera_rig.tscn")
const PITCH := 55.0

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


static func _view() -> Vector2:
	var tan_v := tan(deg_to_rad(35.0) * 0.5)
	return Vector2(tan_v * 16.0 / 9.0, tan_v)


func test_a_view_inside_the_arena_is_left_alone() -> void:
	var slid := TableBounds.shift(Vector3.ZERO, Vector3.ZERO, HALF, 20.0, PITCH, _view())
	assert_vector(slid).is_equal_approx(Vector3.ZERO, Vector3.ONE * 0.001)


func test_a_view_past_a_wall_is_slid_back_to_a_little_past_it() -> void:
	var look := Vector3(HALF.x, 0.0, 0.0)
	var slid := TableBounds.shift(look, Vector3.ZERO, HALF, 20.0, PITCH, _view())
	assert_float(slid.x).is_less(-1.0)
	# Slid, it is as far past the wall as it may be and no further: asked again, it stays.
	var again := TableBounds.shift(look + slid, Vector3.ZERO, HALF, 20.0, PITCH, _view())
	assert_vector(again).is_equal_approx(Vector3.ZERO, Vector3.ONE * 0.001)
	# The column a strip in from the right edge of the screen lands on the wall.
	var inner := 1.0 - TableBounds.EDGE * 2.0
	var edge := (look + slid).x + 20.0 * _view().x * inner
	assert_float(edge).is_equal_approx(HALF.x, 0.01)


func test_a_view_wider_than_the_arena_puts_it_in_the_middle() -> void:
	var look := Vector3(6.0, 0.0, 3.0)
	var slid := TableBounds.shift(look, Vector3.ZERO, HALF, 90.0, PITCH, _view())
	assert_float((look + slid).x).is_equal_approx(0.0, 0.01)


## Following a kart along the right wall, the camera no longer aims at the kart with half the
## screen crowd: past the wall is a strip at the edge of the screen, and the kart is on screen.
func test_a_kart_along_the_wall_does_not_take_the_picture_off_the_table() -> void:
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
	var kart: Node3D = auto_free(Node3D.new())
	add_child(kart)
	kart.global_position = Vector3(19.0, 0.0, 0.0)
	rig.targets.assign([kart] as Array[Node3D])
	for i: int in 400:
		rig._process(0.05)
	await await_idle_frame()
	var screen := rig.get_viewport().get_visible_rect().size
	var column := Vector2(screen.x * (1.0 - TableBounds.EDGE), screen.y * 0.5)
	var from := rig.camera.project_ray_origin(column)
	var way := rig.camera.project_ray_normal(column)
	var edge := from + way * (-from.y / way.y)
	assert_float(edge.x).is_less(HALF.x + 0.5)
	rig.camera.fov = rig.base_fov * rig.zoom_min
	assert_bool(rig.camera.is_position_in_frustum(kart.global_position)).is_true()


## The near side is counted at the height of the stands past it, which rise toward the camera: the
## row a strip up from the foot of the screen comes down to that height inside the near wall.
func test_the_near_side_is_counted_at_the_stands_height() -> void:
	var look := Vector3(0.0, 0.0, HALF.y)
	var slid := TableBounds.shift(look, Vector3.ZERO, HALF, 20.0, PITCH, _view())
	assert_float(slid.z).is_less(-1.0)
	var tilt := deg_to_rad(PITCH)
	var back := Vector3(0.0, sin(tilt), cos(tilt))
	var up := Vector3(0.0, cos(tilt), -sin(tilt))
	var eye := look + slid + back * 20.0
	var way := -back - up * _view().y * (1.0 - TableBounds.EDGE * 2.0)
	var row := eye + way * ((TableBounds.NEAR_HEIGHT - eye.y) / way.y)
	assert_float(row.z).is_equal_approx(HALF.y, 0.01)
