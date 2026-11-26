extends GdUnitTestSuite
## The kart dialog before a license, GAME.md 4.4a: while the kart wears the learner's L its plate's
## hook waits for one, the L hanging there and its tape saying so, and pressed it asks whether to
## earn the license now rather than hanging out a rack of frames for a plate there is none of, see
## [BaySchool]; the shuffle leaves the frame as it is, and a frame won is new only once there is a
## plate for it.

const PATH := "user://test_kart_learner.cfg"
const FRAME := KartStyle.FRAME
const GOLD := 1

var _settings_were: Settings
var _holder: Control
## How many times Earn it now went to the school.
var _schooled := 0


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	Game.settings.profile.story.on = false
	_schooled = 0
	_holder = Control.new()
	_holder.size = Vector2(1600.0, 900.0)
	add_child(_holder)


func after_test() -> void:
	PlayerInput.typing = false
	if is_instance_valid(_holder):
		remove_child(_holder)
		_holder.free()
	Settings.remove_files(PATH)
	Game.settings = _settings_were


func _open() -> KartDialog:
	var dialog := KartDialog.open(_holder)
	dialog.school.to_school = func() -> void: _schooled += 1
	await get_tree().process_frame
	await get_tree().process_frame
	return dialog


func _license() -> void:
	Game.settings.profile.license_number = "JJ-000042"
	Game.settings.profile.license_plate = "SES-773"


static func _cancel() -> InputEventAction:
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	return cancel


## Before a license the plate's hook has the learner's L hanging in it rather than a plate, its tape
## saying so; once there is one it is the plate's frame again, as every other hook is its piece.
func test_the_plate_hook_waits_for_a_license() -> void:
	var dialog := await _open()
	var hook := dialog.hooks[FRAME]
	assert_bool(hook.learner).is_true()
	assert_bool(hook.picture.visible).is_false()
	for part: int in KartDialog.CARD_BACK + 1:
		if part != FRAME:
			assert_bool(dialog.hooks[part].learner).is_false()
	dialog.close()
	_license()
	var licensed := await _open()
	assert_bool(licensed.hooks[FRAME].learner).is_false()
	assert_bool(licensed.hooks[FRAME].picture.visible).is_true()


## Pressed before a license, the plate's hook hangs out no rack of frames: it asks whether to earn
## the license now, the cursor on Earn it now, which goes to the driving school.
func test_pressed_it_offers_the_driving_school() -> void:
	var dialog := await _open()
	dialog.hooks[FRAME].pressed.emit()
	await get_tree().process_frame
	assert_bool(dialog.tray.is_out()).is_false()
	assert_int(dialog.open_part).is_equal(-1)
	assert_bool(dialog.school.is_asking()).is_true()
	var question := dialog.school.question
	assert_str(question.said()).contains(BaySchool.QUESTION)
	assert_str(question.yes_button().text).is_equal(BaySchool.EARN)
	assert_bool(question.yes_button().has_focus()).is_true()
	question.yes_button().pressed.emit()
	assert_int(_schooled).is_equal(1)
	assert_bool(dialog.school.is_asking()).is_false()


## Back while the question is up puts only the question away, the cursor back on the hook; and the
## dialog's own keys, the page keys, the shuffle's and Next new's, wait for it.
func test_back_puts_the_question_away() -> void:
	var before := Game.settings.seat_style(0)
	var color_before := Game.settings.seat_color(0)
	var dialog := await _open()
	dialog.hooks[FRAME].grab_focus()
	dialog.hooks[FRAME].pressed.emit()
	await get_tree().process_frame
	var shuffle := InputEventAction.new()
	shuffle.action = KartDialog.SHUFFLE_ACTION
	shuffle.pressed = true
	dialog._input(shuffle)
	assert_array(Array(Game.settings.seat_style(0))).is_equal(Array(before))
	assert_int(Game.settings.seat_color(0)).is_equal(color_before)
	dialog._unhandled_input(_cancel())
	await get_tree().process_frame
	assert_bool(dialog.school.is_asking()).is_false()
	assert_bool(dialog.is_closing()).is_false()
	assert_bool(dialog.hooks[FRAME].has_focus()).is_true()
	assert_int(_schooled).is_equal(0)
	dialog._unhandled_input(_cancel())
	assert_bool(dialog.is_closing()).is_true()


## With a license the plate's hook hangs out its rack of frames as it always has.
func test_with_a_license_it_opens_the_frames() -> void:
	_license()
	var dialog := await _open()
	dialog.hooks[FRAME].pressed.emit()
	await get_tree().process_frame
	assert_bool(dialog.tray.is_out()).is_true()
	assert_int(dialog.open_part).is_equal(FRAME)
	assert_bool(dialog.school.is_asking()).is_false()


## A frame won before a license is not worn, nor put on by the shuffle, nor new: it waits, new, for
## the plate the license brings.
func test_a_frame_waits_for_the_plate() -> void:
	var profile := Game.settings.profile
	profile.loyalty.win(&"clean_record")
	var owner := KartOwner.for_seat(0)
	assert_bool(owner.owns(FRAME, GOLD)).is_true()
	assert_bool(owner.may_change(FRAME)).is_false()
	assert_bool(owner.wear(FRAME, GOLD)).is_false()
	var all_gold := PackedInt32Array([0, 0, 0, 0, GOLD, 0, 0])
	owner.dress(all_gold)
	assert_int(owner.style().frame).is_equal(0)
	assert_bool(owner.new_pieces().has(Vector2i(FRAME, GOLD))).is_false()
	_license()
	assert_bool(owner.may_change(FRAME)).is_true()
	assert_bool(owner.new_pieces().has(Vector2i(FRAME, GOLD))).is_true()
	assert_bool(owner.wear(FRAME, GOLD)).is_true()
	assert_int(owner.style().frame).is_equal(GOLD)


## The shuffle leaves a learner's frame as it was, whatever it rolls.
func test_the_shuffle_leaves_the_frame() -> void:
	Game.settings.profile.loyalty.win(&"clean_record")
	var dialog := await _open()
	for i: int in 12:
		dialog.shuffle()
		assert_int(dialog.kart_owner().style().frame).is_equal(0)


## Another profile's kart with no license waits the same, but the school would earn the license
## of the profile playing, so the question only says how one is had, with nothing to go to.
func test_another_profile_is_only_told() -> void:
	_license()
	Game.settings.save_to_disk()
	var other := Game.settings.new_profile()
	other.player_names[0] = "Dice Daisy"
	other.save_to_disk()
	var dialog := await _open()
	assert_bool(dialog.hooks[FRAME].learner).is_false()
	dialog.switch_owner(1)
	assert_bool(dialog.hooks[FRAME].learner).is_true()
	dialog.hooks[FRAME].pressed.emit()
	await get_tree().process_frame
	var question := dialog.school.question
	assert_str(question.said()).contains("Dice Daisy")
	assert_bool(question.yes_button().visible).is_false()
	assert_bool(question.no_button().has_focus()).is_true()
	question.no_button().pressed.emit()
	assert_int(_schooled).is_equal(0)
	assert_bool(dialog.school.is_asking()).is_false()
