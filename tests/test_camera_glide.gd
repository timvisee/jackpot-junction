extends GdUnitTestSuite
## The camera moving smoothly, GAME.md 8.2: a kart that joins, or comes back across the room, glides
## into the framing rather than being in it all at once, see [FramedSpots], and the camera eases
## toward the framing without ever setting off or stopping with a jolt, see [CameraEase].

const BOUNDS := AABB(Vector3(-20.0, 0.0, -11.25), Vector3(40.0, 1.0, 22.5))
const RIG_SCENE := preload("res://scenes/camera/camera_rig.tscn")
## A frame at sixty a second, which is what the camera's motion is measured in.
const FRAME := 1.0 / 60.0
## The most the camera may speed up or slow down, in meters a second each second, and how quickly
## that may change, each second, as a kart appears across the room. Measured in a match with the
## camera close in on a huddle and a kart appearing in the far corner: eased by its aim alone it
## went from standing to 160 m/s in a frame, about 10,000 m/s² and 630,000 m/s³; now it peaks at
## about 430 m/s² and 4,700 m/s³. The rigs here: 10,700 m/s² and 675,000 m/s³ before, about
## 310 m/s² and 3,700 m/s³ now.
const MOST_PULL := 1500.0
const MOST_JERK := 40000.0

var _was_fixed := false


func before_test() -> void:
	_was_fixed = Game.settings.fixed_camera
	Game.settings.fixed_camera = false


func after_test() -> void:
	Game.settings.fixed_camera = _was_fixed


## A kart, a plain node, at [param at].
func _kart(at: Vector3) -> Node3D:
	var kart: Node3D = auto_free(Node3D.new())
	add_child(kart)
	kart.global_position = at
	return kart


## A rig following [param karts], settled close in on them.
func _following(karts: Array[Node3D]) -> CameraRig:
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
	rig.targets.assign(karts)
	for i: int in 600:
		rig._process(FRAME)
	return rig


## A huddle in the near left corner of the floor.
func _huddle() -> Array[Node3D]:
	var karts: Array[Node3D] = []
	for at: Vector3 in [Vector3(-15.0, 0.0, 8.0), Vector3(-12.0, 0.0, 6.0), Vector3(-14.0, 0, 5.0)]:
		karts.append(_kart(at))
	return karts


## The camera's greatest speeding up and its greatest change in that, over [param seconds] of
## frames from [param change] on, two settled frames before it to measure it from: x the pull, in
## meters a second each second, and y the jerk.
static func _roughest(rig: CameraRig, seconds: float, change: Callable) -> Vector2:
	var places: Array[Vector3] = []
	for i: int in 2:
		rig._process(FRAME)
		places.append(rig.camera.global_position)
	change.call()
	for i: int in int(seconds / FRAME):
		rig._process(FRAME)
		places.append(rig.camera.global_position)
	var most := Vector2.ZERO
	var pull_was := Vector3.INF
	for i: int in range(2, places.size()):
		var pull := (places[i] - places[i - 1] * 2.0 + places[i - 2]) / (FRAME * FRAME)
		most.x = maxf(most.x, pull.length())
		if pull_was.is_finite():
			most.y = maxf(most.y, (pull - pull_was).length() / FRAME)
		pull_was = pull
	return most


## A kart new to the shot glides in from the nearest edge of the box the others are in, where it
## changes nothing, to where it really is, easing in and out over [constant FramedSpots.GLIDE].
func test_a_kart_new_to_the_shot_glides_in_from_the_others() -> void:
	var spots := FramedSpots.new()
	var karts := _huddle()
	spots.place(karts, 0.0, Vector3.ZERO)
	# The first karts of a shot are taken where they are, as the shot opens on them.
	for i: int in karts.size():
		assert_vector(spots.placed[i]).is_equal(karts[i].global_position)
	var new := _kart(Vector3(16.0, 0.0, -9.0))
	karts.append(new)
	spots.place(karts, 1.0, Vector3.ZERO)
	var edge := Vector3(-12.0, 0.0, 5.0)
	assert_vector(spots.placed[3]).is_equal_approx(edge, Vector3.ONE * 0.001)
	spots.place(karts, 1.0 + FramedSpots.GLIDE * 0.5, Vector3.ZERO)
	var half := edge.lerp(new.global_position, 0.5)
	assert_vector(spots.placed[3]).is_equal_approx(half, Vector3.ONE * 0.001)
	spots.place(karts, 1.0 + FramedSpots.GLIDE, Vector3.ZERO)
	assert_vector(spots.placed[3]).is_equal(new.global_position)
	# The others never moved for it.
	for i: int in 3:
		assert_vector(spots.placed[i]).is_equal(karts[i].global_position)


## A kart that comes back somewhere else, further than any kart drives in a frame, glides over from
## where it was counted; one that drives is counted where it is, every frame.
func test_a_kart_that_comes_back_elsewhere_glides_over() -> void:
	var spots := FramedSpots.new()
	var karts := _huddle()
	spots.place(karts, 0.0, Vector3.ZERO)
	karts[0].global_position += Vector3(0.5, 0.0, 0.0)
	spots.place(karts, 0.1, Vector3.ZERO)
	assert_vector(spots.placed[0]).is_equal(karts[0].global_position)
	var was := karts[0].global_position
	karts[0].global_position = Vector3(17.0, 0.0, -9.0)
	spots.place(karts, 0.2, Vector3.ZERO)
	assert_vector(spots.placed[0]).is_equal_approx(was, Vector3.ONE * 0.001)
	assert_vector(spots.place_of(karts[0])).is_equal_approx(was, Vector3.ONE * 0.001)
	spots.place(karts, 0.2 + FramedSpots.GLIDE, Vector3.ZERO)
	assert_vector(spots.placed[0]).is_equal(karts[0].global_position)
	# Gone from the shot and back, it glides in again rather than jumping in.
	var others: Array[Node3D] = [karts[1], karts[2]]
	spots.place(others, 5.0, Vector3.ZERO)
	spots.place(karts, 5.1, Vector3.ZERO)
	assert_float(spots.placed[0].distance_to(karts[0].global_position)).is_greater(1.0)


## However far away a kart appears, the camera takes it in as one smooth move rather than a jolt,
## and then has every kart on the screen: one that comes back across the room, and one that joins.
func test_the_camera_moves_smoothly_when_a_kart_appears_far_away() -> void:
	var karts := _huddle()
	var rig := _following(karts)
	var close := rig._distance
	var far := karts[1]
	var back := _roughest(rig, 3.0, func() -> void: far.global_position = Vector3(17.0, 0.0, -9.0))
	assert_float(rig._distance).is_greater(close * 1.4)
	# Back into the huddle, the camera close in on it again, and a kart joins in the far corner.
	far.global_position = Vector3(-13.0, 0.0, 7.0)
	for i: int in 600:
		rig._process(FRAME)
	var joined := _kart(Vector3(17.0, 0.0, -9.0))
	var join := _roughest(rig, 3.0, func() -> void: rig.targets.append(joined))
	for most: Vector2 in [back, join]:
		assert_float(most.x).is_less(MOST_PULL)
		assert_float(most.y).is_less(MOST_JERK)
	await await_idle_frame()
	rig.camera.fov = rig.base_fov * rig.zoom_min
	for kart: Node3D in rig.targets:
		(
			assert_bool(rig.camera.is_position_in_frustum(kart.global_position))
			. override_failure_message("a kart at %s is off the screen" % kart.global_position)
			. is_true()
		)


## Eased in two steps, the camera still keeps up with fast driving as it did eased in one: something
## moving steadily is followed about the time it is given behind, no further behind than one ease
## of that time left it at sixty frames a second, and a move starts from standing rather than at
## full tilt.
func test_the_ease_keeps_up_as_it_did() -> void:
	var follower := CameraEase.new()
	var speed := 20.0
	var lag := 0.6
	var at := 0.0
	var one := 0.0
	var blend := 1.0 - exp(-FRAME / lag)
	for i: int in 600:
		at += speed * FRAME
		follower.follow(Vector3(at, 0.0, 0.0), lag, FRAME)
		one = lerpf(one, at, blend)
	var behind := at - follower.value.x
	assert_float(behind).is_less_equal(at - one + 0.001)
	assert_float(behind).is_greater(speed * lag * 0.95)
	assert_float(follower.speed.x).is_equal_approx(speed, 0.1)
	var still := CameraEase.new()
	still.follow(Vector3(10.0, 0.0, 0.0), lag, FRAME)
	assert_float(still.speed.x).is_less(1.0)
	# Where one ease set off at once at its fastest: ten meters asked for, sixteen meters a second.
	assert_float(lerpf(0.0, 10.0, blend) / FRAME).is_greater(15.0)
