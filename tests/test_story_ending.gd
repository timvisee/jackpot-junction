extends GdUnitTestSuite
## After the stamp, STORY.md 8.5 and 8.6: when it came down and the deviation then kept; the
## decisions approved in the player's name counted from it at the House's rate; the payslip's count
## since the last shift; and the House's profile of the player on the title's green line.


func _ended() -> Profile:
	var profile := Profile.new()
	profile.license_number = "JJ-212212"
	profile.story.seconds = Story.FINAL_HAND_AT
	return profile


## The stamp keeps when it came down and the evaluation's deviation.
func test_the_stamp_keeps_its_moment() -> void:
	var profile := _ended()
	var lines: Array[Array] = [["DEVIATION FROM MODEL", "37%  ·  TARGET: ANY"], ["STATUS", ""]]
	var before := Time.get_unix_time_from_system()
	FinalHand.stamp_down(profile, lines, "2026-10-16")
	assert_bool(profile.story.ended()).is_true()
	assert_float(profile.story.stamped_at).is_greater_equal(before)
	assert_int(profile.story.deviation).is_equal(37)
	var file := ConfigFile.new()
	profile.story.write(file)
	var read := StoryState.new()
	read.read(file)
	assert_float(read.stamped_at).is_equal_approx(profile.story.stamped_at, 0.01)
	assert_int(read.deviation).is_equal(37)


## At the House's rate: some 4.1 billion a day, forty-eight thousand a second.
func test_the_house_approves_at_its_rate() -> void:
	assert_int(FinalHand.approvals_in(86400.0)).is_equal(FinalHand.APPROVALS_A_DAY)
	assert_int(FinalHand.approvals_in(1.0)).is_between(47000, 48000)
	assert_int(FinalHand.approvals_in(-5.0)).is_equal(0)


## Each shift after the ending counts what went out in the player's name since the one before,
## since the stamp for the first, and the payslip says so.
func test_a_shift_counts_since_the_last() -> void:
	var profile := _ended()
	profile.story.final_hand = "2026-10-16"
	profile.story.stamped_at = Time.get_unix_time_from_system() - 60.0
	var slot := PlayerSlot.new(0, PlayerInput.new(DeviceInput.ANY, 0))
	Story.count(profile, slot, 120.0, {}, true, true)
	assert_int(profile.story.shifts).is_equal(1)
	assert_int(profile.story.since).is_between(
		FinalHand.approvals_in(59.0), FinalHand.approvals_in(62.0)
	)
	var small := StorySlip.small_print(Story.Stage.OPERATOR, profile)
	assert_str(small).contains(StoryFill.number(profile.story.since))
	assert_str(small).contains("SINCE YOUR LAST SHIFT")
	profile.story.shift_at -= 10.0
	Story.count(profile, slot, 120.0, {}, true, true)
	assert_int(profile.story.since).is_between(
		FinalHand.approvals_in(9.0), FinalHand.approvals_in(12.0)
	)


## The profile starts at 100 less the deviation, each shift closes 4% of what is left, and each
## bet off the books and card of Kit's knocks it back a point and a half; never over 99.9.
func test_the_profile_closes_in() -> void:
	var profile := _ended()
	profile.story.deviation = 40
	assert_float(StoryFill.profile_share(profile)).is_equal_approx(60.0, 0.01)
	profile.story.shifts = 10
	var closed := 100.0 - 40.0 * pow(0.96, 10.0)
	assert_float(StoryFill.profile_share(profile)).is_equal_approx(closed, 0.01)
	profile.story.kit_cards = PackedStringArray(["brake_check", "blind_spot"])
	assert_float(StoryFill.profile_share(profile)).is_equal_approx(closed - 3.0, 0.01)
	profile.story.shifts = 10000
	profile.story.kit_cards = PackedStringArray()
	assert_float(StoryFill.profile_share(profile)).is_equal(StoryFill.PROFILE_MOST)
	var line := StoryFill.fill(StoryLines.STATUS_LINE, profile)
	assert_str(line).contains("PROFILE 99.9%")
	# A profile from before keeps its deviation on its evaluation.
	var older := _ended()
	older.story.evaluation = {"lines": [["DEVIATION FROM MODEL", "25%  ·  TARGET: ANY"]]}
	assert_float(StoryFill.profile_share(older)).is_equal_approx(75.0, 0.01)


## The record feeds up a line at a time and counts from the stamp.
func test_the_record_counts() -> void:
	var holder: Control = auto_free(Control.new())
	holder.size = Vector2(1920.0, 1080.0)
	add_child(holder)
	var profile := _ended()
	var record := ApprovalRecord.feed(holder, profile, Time.get_unix_time_from_system() - 10.0)
	assert_bool(record.is_fed()).is_false()
	assert_int(record.approved_now()).is_greater_equal(FinalHand.approvals_in(10.0))
	for i: int in StoryLines.APPROVAL_RECORD.size() + 1:
		record._process(ApprovalRecord.FEED + ApprovalRecord.GAP)
	assert_bool(record.is_fed()).is_true()
