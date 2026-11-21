extends GdUnitTestSuite
## When the tutorial points the player at the clipboard again, GAME.md 9.4a, see [TutorialNudge]:
## standing still a while, or a longer while of nothing getting done however the kart drives, and
## again as long as it stays that way; headway or something else to do starts the wait over.

const STOPPED := 0.0
const DRIVING := 6.0
const DT := 1.0 / 60.0


## Standing still with nothing getting done: pointed at once the short while is up, then every
## longer while after, busy or not in between; getting on with the lesson brings the short one back.
func test_standing_still_points_at_it_then_less_often() -> void:
	var nudge := TutorialNudge.new()
	nudge.reset(0.0)
	assert_bool(nudge.step(TutorialNudge.STILL_FOR - 0.1, 0.0, STOPPED, false)).is_false()
	assert_bool(nudge.step(0.2, 0.0, STOPPED, false)).is_true()
	assert_bool(nudge.step(TutorialNudge.STILL_AGAIN - 0.1, 0.0, STOPPED, false)).is_false()
	assert_bool(nudge.step(0.2, 0.0, STOPPED, false)).is_true()
	assert_bool(nudge.step(1.0, 0.0, STOPPED, true)).is_false()
	assert_bool(nudge.step(TutorialNudge.STILL_AGAIN - 0.1, 0.0, STOPPED, false)).is_false()
	assert_bool(nudge.step(0.2, 0.0, STOPPED, false)).is_true()
	nudge.step(DT, TutorialNudge.HEADWAY, STOPPED, false)
	assert_bool(nudge.again).is_false()
	assert_bool(nudge.step(TutorialNudge.STILL_FOR + 0.1, 0.0, STOPPED, false)).is_true()


## Driving about with nothing getting done takes the longer while, and moving off starts the
## standing over: a kart that stops now and then is not standing about.
func test_driving_with_nothing_done_takes_the_longer_while() -> void:
	var nudge := TutorialNudge.new()
	nudge.reset(0.0)
	assert_bool(nudge.step(TutorialNudge.STILL_FOR - 1.0, 0.0, STOPPED, false)).is_false()
	assert_bool(nudge.step(0.1, 0.0, DRIVING, false)).is_false()
	assert_float(nudge.still).is_equal(0.0)
	assert_bool(nudge.step(TutorialNudge.STILL_FOR - 1.0, 0.0, STOPPED, false)).is_false()
	var left := TutorialNudge.QUIET_FOR - nudge.quiet
	assert_bool(nudge.step(left - 0.1, 0.0, DRIVING, false)).is_false()
	assert_bool(nudge.step(0.2, 0.0, DRIVING, false)).is_true()


## Getting on with the lesson starts the wait over; a bar creeping on nothing does not, nor one
## falling back as the nitro fills again, though burning it again, the bar coming back, does.
func test_only_headway_starts_it_over() -> void:
	var nudge := TutorialNudge.new()
	nudge.reset(1.0)
	nudge.step(TutorialNudge.STILL_FOR - 1.0, 1.0 + TutorialNudge.HEADWAY * 0.5, STOPPED, false)
	assert_float(nudge.quiet).is_greater(0.0)
	nudge.step(0.1, 0.6, STOPPED, false)
	assert_float(nudge.quiet).is_greater(0.0)
	nudge.step(0.1, 1.0, STOPPED, false)
	assert_float(nudge.quiet).is_equal(0.0)
	nudge.step(TutorialNudge.STILL_FOR - 0.5, 1.0, STOPPED, false)
	nudge.step(0.1, 1.0 + TutorialNudge.HEADWAY, STOPPED, false)
	assert_float(nudge.quiet).is_equal(0.0)
	assert_float(nudge.still).is_equal(0.0)


## Where driving round does not count, the final exam's fight, only standing still points at it.
func test_where_driving_does_not_count_only_standing_still_does() -> void:
	var nudge := TutorialNudge.new()
	nudge.reset(0.0)
	assert_bool(nudge.step(TutorialNudge.QUIET_FOR * 2.0, 0.0, DRIVING, false, false)).is_false()
	assert_bool(nudge.step(TutorialNudge.STILL_FOR + 0.1, 0.0, STOPPED, false, false)).is_true()
	assert_bool(TutorialFight.new().nudge_driving).is_false()
	assert_bool(TutorialDrive.new().nudge_driving).is_true()


## Busy with something else, a question or the hand, never points and starts the wait over.
func test_busy_starts_it_over() -> void:
	var nudge := TutorialNudge.new()
	nudge.reset(0.0)
	assert_bool(nudge.step(TutorialNudge.QUIET_FOR * 2.0, 0.0, STOPPED, true)).is_false()
	assert_bool(nudge.step(TutorialNudge.STILL_FOR - 0.5, 0.0, STOPPED, false)).is_false()
