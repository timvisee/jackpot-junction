extends GdUnitTestSuite
## The invitation that brought the player to the tables, STORY.md 6.1a: owed once to each profile
## with the story on, kept with its stub's number; coming on in turn and all at once on a press; not
## to be declined; accepted, its stub torn off and the title's own opening next.

const TITLE_SCENE := preload("res://scenes/ui/title.tscn")

var _was_story: StoryState


func before_test() -> void:
	_was_story = Game.settings.profile.story
	Game.settings.profile.story = StoryState.new()


func after_test() -> void:
	OpeningInvitation.again = false
	OpeningInvitation.held_off = false
	Game.settings.profile.story = _was_story


func _holder() -> Control:
	var holder: Control = auto_free(Control.new())
	holder.size = Vector2(1920.0, 1080.0)
	add_child(holder)
	return holder


## Owed to a profile with the story on until it is accepted, and never shown in a run nobody
## watches unless asked for; accepted, and its number, are kept with the profile.
func test_owed_once_to_each_profile_and_kept() -> void:
	var profile := Profile.new()
	assert_bool(OpeningInvitation.owed(profile)).is_true()
	assert_bool(OpeningInvitation.due(profile)).is_false()
	OpeningInvitation.again = true
	assert_bool(OpeningInvitation.due(profile)).is_true()
	OpeningInvitation.again = false
	# A debug build's `++ --story-invitation=0` leaves it out of this run alone, owed still;
	# `++ --story-invitation` shows it again.
	Story.read_arguments(PackedStringArray(["--story-invitation=0"]), Game.settings)
	assert_bool(OpeningInvitation.held_off).is_true()
	OpeningInvitation.again = true
	assert_bool(OpeningInvitation.due(profile)).is_false()
	assert_bool(OpeningInvitation.owed(profile)).is_true()
	Story.read_arguments(PackedStringArray(["--story-invitation"]), Game.settings)
	assert_bool(OpeningInvitation.held_off).is_false()
	assert_bool(OpeningInvitation.due(profile)).is_true()
	OpeningInvitation.again = false
	profile.story.on = false
	assert_bool(OpeningInvitation.owed(profile)).is_false()
	profile.story.on = true
	var number := OpeningInvitation.number_for(profile.story)
	assert_bool(RegEx.create_from_string("^[0-9]{4} [0-9]{4}$").search(number) != null).is_true()
	assert_str(OpeningInvitation.number_for(profile.story)).is_equal(number)
	profile.story.invited = true
	assert_bool(OpeningInvitation.owed(profile)).is_false()
	var file := ConfigFile.new()
	profile.story.write(file)
	var read := StoryState.new()
	read.read(file)
	assert_bool(read.invited).is_true()
	assert_str(read.invitation).is_equal(number)


## Up, it waits for its start, as it does behind the warm-up; started, it comes on in turn, the
## button last, and a press before then brings it all at once; the cursor walks nowhere else, and
## Back does nothing; accepted, the profile has accepted it, after a beat the stub is torn off
## along a ragged edge that matches the card's, and once card and envelope have dropped away and the
## table has been dark a moment it says so, fades and goes.
func test_comes_on_is_not_declined_and_tears_its_stub() -> void:
	var profile := Profile.new()
	var invitation := OpeningInvitation.over(_holder(), profile)
	await await_idle_frame()
	await await_millis(200)
	assert_float(invitation._time).is_equal(0.0)
	invitation.start()
	assert_bool(invitation.accept.disabled).is_true()
	assert_str(invitation.card.number).is_equal(profile.story.invitation)
	var press := InputEventAction.new()
	press.action = &"ui_accept"
	press.pressed = true
	invitation._input(press)
	assert_bool(invitation.accept.disabled).is_false()
	await await_idle_frame()
	assert_bool(invitation.accept.has_focus()).is_true()
	# The arrows and Tab walk the cursor nowhere: there is nothing else on this screen.
	for walk: StringName in OpeningInvitation.WALKS:
		var step := InputEventAction.new()
		step.action = walk
		step.pressed = true
		get_viewport().push_input(step)
		await await_idle_frame()
		assert_bool(invitation.accept.has_focus()).is_true()
	var back := InputEventAction.new()
	back.action = &"ui_cancel"
	back.pressed = true
	invitation._unhandled_input(back)
	assert_bool(is_instance_valid(invitation)).is_true()
	assert_bool(profile.story.invited).is_false()
	var gone := [false]
	invitation.accepted.connect(func() -> void: gone[0] = true)
	invitation.accept.pressed.emit()
	assert_bool(profile.story.invited).is_true()
	# Not torn at once: a beat first.
	await await_millis(int(OpeningInvitation.SETTLE * 1000.0))
	assert_bool(invitation.card.torn).is_false()
	await await_millis(int((OpeningInvitation.BEFORE_TEAR + 0.15) * 1000.0))
	assert_bool(invitation.card.torn).is_true()
	assert_bool(invitation.card.shows_stub).is_false()
	assert_object(invitation.stub).is_not_null()
	assert_bool(invitation.stub.stub_only).is_true()
	assert_array(invitation.stub._edge()).is_equal(invitation.card._edge())
	assert_int(invitation.card._edge().size()).is_greater(2)
	var left := (
		OpeningInvitation.TEAR
		+ OpeningInvitation.HOLD
		+ OpeningInvitation.DROP
		+ OpeningInvitation.DARK
	)
	await await_millis(int((left - 0.3) * 1000.0))
	assert_bool(gone[0]).is_false()
	await await_millis(int((0.3 + OpeningInvitation.FADE + 0.3) * 1000.0))
	assert_bool(gone[0]).is_true()
	assert_bool(is_instance_valid(invitation)).is_false()


## At the title it is up from the first, under the warm-up's pane where there is one, and starts
## once the shaders have compiled, before the opening: the title's own cursor waits, the title does
## not answer under it, and the music is held off; once it is accepted the cursor goes on Play and
## the music is let go.
func test_the_title_waits_for_it() -> void:
	OpeningInvitation.again = true
	var title: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(title)
	await await_idle_frame()
	var invitation := title.get("invitation") as OpeningInvitation
	assert_object(invitation).is_not_null()
	assert_bool(invitation._started).is_true()
	assert_bool(title.get("play_button").has_focus()).is_false()
	assert_bool(Audio.is_music_held()).is_true()
	OpeningInvitation.again = false
	invitation.come_on_now()
	await await_idle_frame()
	assert_bool(invitation.accept.has_focus()).is_true()
	# The title's buttons right behind it are never walked to.
	for walk: StringName in [&"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_focus_next"]:
		var step := InputEventAction.new()
		step.action = walk
		step.pressed = true
		get_viewport().push_input(step)
		await await_idle_frame()
		assert_bool(invitation.accept.has_focus()).is_true()
	invitation.accept.pressed.emit()
	var left := (
		OpeningInvitation.SETTLE
		+ OpeningInvitation.BEFORE_TEAR
		+ OpeningInvitation.TEAR
		+ OpeningInvitation.HOLD
		+ OpeningInvitation.DROP
		+ OpeningInvitation.DARK
	)
	await await_millis(int((left + 0.3) * 1000.0))
	assert_object(title.get("invitation")).is_null()
	assert_bool(title.get("play_button").has_focus()).is_true()
	assert_bool(Audio.is_music_held()).is_false()
