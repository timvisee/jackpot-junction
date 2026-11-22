extends GdUnitTestSuite
## How far back the camera holds itself, GAME.md 8.2, see [CameraHold]: back as soon as the field
## needs it, with a little to spare, and in again only once the field has stayed close a moment.

const LEAST := 20.0
const MOST := 60.0


## A hold settled on a field that wants [param wanted], at the rig's clock [param now].
static func _held(wanted: float, now := 0.0) -> CameraHold:
	var hold := CameraHold.new()
	hold.hold(wanted, now, LEAST, MOST)
	return hold


func test_it_goes_back_at_once_with_room_to_spare() -> void:
	var hold := _held(30.0)
	assert_float(hold.distance).is_equal_approx(30.0 * (1.0 + CameraHold.SPARE), 0.001)
	var further := hold.hold(40.0, 0.1, LEAST, MOST)
	assert_float(further).is_equal_approx(40.0 * (1.0 + CameraHold.SPARE), 0.001)


func test_it_never_goes_past_the_most_nor_inside_the_least() -> void:
	assert_float(_held(70.0).distance).is_equal(MOST)
	assert_float(_held(10.0).distance).is_equal(LEAST)
	# A field just inside the closest shot is held at it, not a little behind it.
	assert_float(_held(LEAST * 0.9).distance).is_equal(LEAST)


func test_a_field_closing_up_a_little_is_held() -> void:
	var hold := _held(30.0)
	var was := hold.distance
	for i: int in 100:
		hold.hold(29.0, 0.1 * i, LEAST, MOST)
	assert_float(hold.distance).is_equal(was)


func test_a_field_that_stays_close_brings_it_in_after_a_moment() -> void:
	var hold := _held(40.0)
	var was := hold.distance
	# Closed right up, but not for long yet: held.
	hold.hold(25.0, 0.0, LEAST, MOST)
	hold.hold(25.0, CameraHold.SETTLED * 0.5, LEAST, MOST)
	assert_float(hold.distance).is_equal(was)
	# Still close once it has settled: in, to the field with its room to spare.
	hold.hold(25.0, CameraHold.SETTLED + 0.01, LEAST, MOST)
	assert_float(hold.distance).is_equal_approx(25.0 * (1.0 + CameraHold.SPARE), 0.001)


func test_a_field_that_closes_up_for_a_moment_does_not_bring_it_in() -> void:
	var hold := _held(40.0)
	var was := hold.distance
	hold.hold(25.0, 0.0, LEAST, MOST)
	hold.hold(39.0, CameraHold.SETTLED * 0.5, LEAST, MOST)
	hold.hold(25.0, CameraHold.SETTLED + 0.01, LEAST, MOST)
	assert_float(hold.distance).is_equal(was)


func test_coming_in_it_follows_the_field_and_stops_when_it_does() -> void:
	var hold := _held(40.0)
	hold.hold(30.0, 0.0, LEAST, MOST)
	hold.hold(30.0, CameraHold.SETTLED + 0.01, LEAST, MOST)
	# Closing up further: followed in.
	hold.hold(26.0, CameraHold.SETTLED + 0.1, LEAST, MOST)
	var closest := 26.0 * (1.0 + CameraHold.SPARE)
	assert_float(hold.distance).is_equal_approx(closest, 0.001)
	# Opening out a little again, within the room it has: held where it got to, not followed out.
	hold.hold(27.0, CameraHold.SETTLED + 0.2, LEAST, MOST)
	assert_float(hold.distance).is_equal_approx(closest, 0.001)
	# And closing up again a little does not bring it in until it has settled again.
	hold.hold(25.0, CameraHold.SETTLED + 0.3, LEAST, MOST)
	assert_float(hold.distance).is_equal_approx(closest, 0.001)


func test_reset_takes_the_next_field_as_it_is() -> void:
	var hold := _held(50.0)
	hold.reset()
	assert_float(hold.hold(25.0, 0.0, LEAST, MOST)).is_equal_approx(
		25.0 * (1.0 + CameraHold.SPARE), 0.001
	)


## Coming in goes by the field with the aim where the framing would put it, not where it is held
## off to one side, but never in past what the field needs from where the camera aims.
func test_an_aim_held_aside_does_not_keep_it_out() -> void:
	var hold := _held(40.0)
	# From the aim held the field needs 35, centered 30: in to the 35, not to the 30.
	hold.hold(35.0, 0.0, LEAST, MOST, true, 30.0)
	hold.hold(35.0, CameraHold.SETTLED + 0.01, LEAST, MOST, true, 30.0)
	assert_float(hold.distance).is_equal_approx(35.0, 0.001)
	assert_float(hold.distance).is_less(40.0 * (1.0 + CameraHold.SPARE))


## Nor does it come in while the field is not settled: a kart gliding in, or one driven here down.
func test_an_unsettled_field_does_not_bring_it_in() -> void:
	var hold := _held(40.0)
	var was := hold.distance
	for i: int in 40:
		hold.hold(25.0, 0.1 * i, LEAST, MOST, false)
	assert_float(hold.distance).is_equal(was)
	# And going back is not held up by it.
	assert_float(hold.hold(50.0, 4.1, LEAST, MOST, false)).is_greater(50.0)
