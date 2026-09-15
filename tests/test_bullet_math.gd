extends GdUnitTestSuite
## Pure bullet maths: aim assist steering and wall bounces, GAME.md 5.1 and 5.2.

const SPEED := 20.0
const CONE := 0.2094  # 12 degrees
const RANGE := 15.0
const STEP := 0.05


func test_no_steering_toward_a_target_outside_the_cone() -> void:
	var velocity := Vector3(0.0, 0.0, -SPEED)
	var steered := Bullet.steer_toward(
		velocity, Vector3.ZERO, Vector3(5.0, 0.0, -5.0), CONE, RANGE, STEP
	)
	assert_vector(steered).is_equal(velocity)


func test_no_steering_toward_a_target_beyond_range() -> void:
	var velocity := Vector3(0.0, 0.0, -SPEED)
	var steered := Bullet.steer_toward(
		velocity, Vector3.ZERO, Vector3(0.5, 0.0, -30.0), CONE, RANGE, STEP
	)
	assert_vector(steered).is_equal(velocity)


func test_steering_turns_toward_a_target_inside_the_cone_by_at_most_the_step() -> void:
	var velocity := Vector3(0.0, 0.0, -SPEED)
	var target := Vector3(1.0, 0.0, -10.0)
	var steered := Bullet.steer_toward(velocity, Vector3.ZERO, target, CONE, RANGE, STEP)
	assert_float(steered.length()).is_equal_approx(SPEED, 0.001)
	assert_float(steered.x).is_greater(0.0)
	assert_float(absf(velocity.angle_to(steered))).is_equal_approx(STEP, 0.001)


func test_steering_stops_once_aligned() -> void:
	var velocity := Vector3(0.0, 0.0, -SPEED)
	var target := Vector3(0.1, 0.0, -10.0)
	var steered := Bullet.steer_toward(velocity, Vector3.ZERO, target, CONE, RANGE, 1.0)
	assert_float(absf(steered.angle_to(target))).is_less(0.001)


func test_bounce_mirrors_the_component_into_the_wall() -> void:
	var velocity := Vector3(3.0, 0.0, -4.0)
	var bounced := velocity.bounce(Vector3(0.0, 0.0, 1.0))
	assert_vector(bounced).is_equal_approx(Vector3(3.0, 0.0, 4.0), Vector3.ONE * 0.001)
