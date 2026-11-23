extends GdUnitTestSuite
## The karts driven here are never off the screen, GAME.md 8.2, see [KeptInView]: whoever else the
## camera follows, however close the player has it and however fast the kart goes.

const BOUNDS := AABB(Vector3(-20.0, 0.0, -11.25), Vector3(40.0, 1.0, 22.5))
const RIG_SCENE := preload("res://scenes/camera/camera_rig.tscn")
## A handheld's distance: a little closer than Auto comes in on one, closer than the field fits;
## and its screen, a Steam Deck's. The headless screen is square, which fits a field far closer.
const HANDHELD := 0.55
const DECK := Vector2i(1280, 800)

## The settings these tests change, put back after each, see test_camera_rig.gd for why.
var _was_fixed := false
var _was_distance := 0.0
var _was_follows := ""
var _was_size := Vector2i.ZERO


func before_test() -> void:
	_was_fixed = Game.settings.fixed_camera
	_was_distance = Game.settings.camera_distance
	_was_follows = Game.settings.camera_follows
	Game.settings.fixed_camera = false
	Game.settings.camera_distance = HANDHELD
	_was_size = get_tree().root.size
	get_tree().root.size = DECK


func after_test() -> void:
	Game.settings.fixed_camera = _was_fixed
	Game.settings.camera_distance = _was_distance
	Game.settings.camera_follows = _was_follows
	get_tree().root.size = _was_size


## A rig following [param mine], driven here, and [param rivals], parked where they are.
func _following(mine: Vector3, rivals: Array[Vector3]) -> CameraRig:
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
	var driven: CharacterBody3D = auto_free(CharacterBody3D.new())
	add_child(driven)
	driven.global_position = mine
	var karts: Array[Node3D] = [driven]
	for at: Vector3 in rivals:
		var rival: Node3D = auto_free(Node3D.new())
		add_child(rival)
		rival.global_position = at
		karts.append(rival)
	rig.targets.assign(karts)
	rig.listener_targets.assign([driven] as Array[Node3D])
	return rig


## Whether [param at] is on [param rig]'s screen.
static func _on_screen(rig: CameraRig, at: Vector3) -> bool:
	if rig.camera.is_position_behind(at):
		return false
	var size := rig.get_viewport().get_visible_rect().size
	return Rect2(Vector2.ZERO, size).has_point(rig.camera.unproject_position(at))


## Whether the kart driven at [param rig] is on its screen, the floor round it and all.
func _mine_shown(rig: CameraRig) -> bool:
	var at := rig.listener_targets[0].global_position
	for point: Vector3 in KeptInView.around(PackedVector3Array([at])):
		if not _on_screen(rig, point):
			return false
	return true


func test_points_on_the_screen_are_left_where_they_are() -> void:
	var seen: Array[Vector3] = [Vector3(1.0, 1.0, 0.0), Vector3(-1.0, -1.0, 0.0)]
	var view := Vector2(0.5, 0.3)
	var slid := KeptInView.slide(seen, view, 20.0, Vector2(0.5, -0.5))
	assert_vector(slid).is_equal_approx(Vector2(0.5, -0.5), Vector2.ONE * 0.001)


## Off the side of the screen, the aim slides just as far as brings it in, and no further.
func test_a_point_off_the_screen_slides_the_aim_the_least_way() -> void:
	var seen: Array[Vector3] = [Vector3(15.0, 0.0, 0.0)]
	var slid := KeptInView.slide(seen, Vector2(0.5, 0.3), 20.0)
	assert_vector(slid).is_equal_approx(Vector2(5.0, 0.0), Vector2.ONE * 0.001)


## Two that cannot both be on the screen miss it by as much as each other.
func test_points_too_far_apart_are_split_between_the_edges() -> void:
	var seen: Array[Vector3] = [Vector3(15.0, 0.0, 0.0), Vector3(-15.0, 0.0, 0.0)]
	var slid := KeptInView.slide(seen, Vector2(0.5, 0.3), 20.0, Vector2(3.0, 0.0))
	assert_vector(slid).is_equal_approx(Vector2.ZERO, Vector2.ONE * 0.001)


## Following the rivals near at a handheld's distance, a rival at the near side of the table used
## to slide the picture down until the player's own kart, at the far side, went off its top.
func test_a_rival_near_never_takes_my_kart_off_the_screen() -> void:
	Game.settings.camera_follows = ViewChoices.FOLLOW_NEARBY
	var rig := _following(Vector3(0.0, 0.0, -9.5), [Vector3(2.0, 0.0, 8.0)] as Array[Vector3])
	for i: int in 400:
		rig._process(0.05)
	assert_bool(_mine_shown(rig)).is_true()


## Following everybody closer than they all fit, the field may go off the edges; the player's own
## kart, in a corner away from the rest, does not.
func test_following_everyone_close_never_takes_my_kart_off_the_screen() -> void:
	Game.settings.camera_follows = ViewChoices.FOLLOW_EVERYONE
	var rivals: Array[Vector3] = [Vector3(16.0, 0.0, 8.0), Vector3(12.0, 0.0, 9.0)]
	var rig := _following(Vector3(-17.0, 0.0, -9.0), rivals)
	for i: int in 400:
		rig._process(0.05)
	assert_bool(_mine_shown(rig)).is_true()


## However far behind the kart the camera's eases are, the last word has it on the screen: a kart
## driven four meters a frame, short of what counts as coming back somewhere else, is on the screen
## every frame, where the eases alone would lose it in two.
func test_a_kart_outrunning_the_camera_is_on_the_screen_every_frame() -> void:
	Game.settings.camera_follows = ViewChoices.FOLLOW_NEARBY
	var rig := _following(Vector3(-16.0, 0.0, -6.0), [Vector3(-8.0, 0.0, 6.0)] as Array[Vector3])
	for i: int in 200:
		rig._process(0.05)
	var driven := rig.listener_targets[0] as CharacterBody3D
	var lost := 0
	for step: Vector3 in [Vector3(4.0, 0.0, 1.5), Vector3(-4.0, 0.0, -1.5)]:
		for i: int in 7:
			driven.global_position += step
			rig._process(1.0 / 60.0)
			if not _mine_shown(rig):
				lost += 1
	assert_int(lost).is_zero()
