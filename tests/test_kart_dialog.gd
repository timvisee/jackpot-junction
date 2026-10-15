extends GdUnitTestSuite
## The kart dialog, GAME.md 4.4: the kart on the lift with a tag for each part saying what it wears,
## the tray of a part's pieces with those not won yet empty and saying where they are won, the kart
## trying on what the cursor is on and wearing what is pressed, the name, the color and the plate
## on the bench, and a tab for each profile kept here, each kept in its own file.

const PATH := "user://test_kart_dialog.cfg"

var _settings_were: Settings
var _holder: Control


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	Game.settings.player_names[0] = "Snake Eyes Sam"
	_holder = Control.new()
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
	await get_tree().process_frame
	await get_tree().process_frame
	return dialog


func _cell(dialog: KartDialog, index: int) -> PartTray.TrayCell:
	return dialog.tray.cell_at(index)


## Out of any room it opens on the profile playing, every tag saying what its kart wears, the kart
## on the lift wearing it too, with the cursor on the flag's hook, the top left one.
func test_it_shows_what_the_kart_wears() -> void:
	Game.settings.set_seat_style(0, PackedInt32Array([1, 4, 2, 0, 0, 0]))
	Game.settings.set_seat_color(0, 3)
	var dialog := await _open()
	assert_int(dialog.owners.size()).is_equal(1)
	assert_str(dialog.kart_owner().display_name()).is_equal("Snake Eyes Sam")
	assert_str(dialog.hooks[0].worn).is_equal("Stripes")
	assert_str(dialog.hooks[1].worn).is_equal("Party")
	assert_str(dialog.hooks[2].worn).is_equal("Banner")
	assert_str(dialog.hooks[3].worn).is_equal("Smoke")
	assert_str(dialog.hooks[KartDialog.CARD_BACK].worn).is_equal(CardBack.STYLES[0])
	assert_array(Array(dialog.stage.shown.to_array().slice(0, 6))).is_equal([1, 4, 2, 0, 0, 0])
	assert_int(dialog.stage.shown_color).is_equal(3)
	assert_bool(dialog.hooks[2].has_focus()).is_true()
	assert_str(dialog.name_box.text).is_equal("Snake Eyes Sam")
	assert_bool(dialog.cans[3].chosen).is_true()


## A tag pressed sets its part's tray down: every piece of it, those everybody has and those won
## to be worn, the rest empty, saying where they are won; the cursor on the one worn.
func test_the_tray_holds_every_piece_and_says_where_the_rest_are_won() -> void:
	Game.settings.profile.loyalty.win(&"fedora")
	var dialog := await _open()
	dialog.open_tray(1)
	await get_tree().process_frame
	assert_bool(dialog.tray.visible).is_true()
	assert_int(dialog.tray.cells.size()).is_equal(KartStyle.HATS.size())
	assert_bool(dialog.hooks[1].lit).is_true()
	var fedora := _cell(dialog, KartStyle.HATS.find("Fedora"))
	assert_bool(fedora.owned).is_true()
	var crown := _cell(dialog, KartStyle.HATS.find("Crown"))
	assert_bool(crown.owned).is_true()
	var top_hat := _cell(dialog, KartStyle.HATS.find("Top hat"))
	assert_bool(top_hat.owned).is_false()
	assert_str(top_hat.where).is_not_empty()
	assert_str(top_hat.where).is_equal(KartOwner.won_at(1, KartStyle.HATS.find("Top hat")))
	assert_bool(_cell(dialog, 0).has_focus()).is_true()
	# The bench is put away under it.
	assert_bool(dialog.name_box.visible).is_false()
	assert_bool(dialog.cans[0].visible).is_false()


## The cursor on a piece has the kart try it on, without keeping it; one not won is not tried on.
## The tray put back, the kart wears what it did.
func test_the_kart_tries_on_what_the_cursor_is_on() -> void:
	Game.settings.profile.loyalty.win(&"fedora")
	var dialog := await _open()
	dialog.open_tray(1)
	await get_tree().process_frame
	var fedora := KartStyle.HATS.find("Fedora")
	_cell(dialog, fedora).grab_focus()
	assert_int(dialog.stage.shown.hat).is_equal(fedora)
	assert_int(KartStyle.from_array(Game.settings.seat_style(0)).hat).is_equal(0)
	_cell(dialog, KartStyle.HATS.find("Top hat")).grab_focus()
	assert_int(dialog.stage.shown.hat).is_equal(0)
	dialog.close_tray()
	assert_bool(dialog.tray.is_out()).is_false()
	assert_int(dialog.stage.shown.hat).is_equal(0)
	assert_bool(dialog.hooks[1].has_focus()).is_true()
	assert_bool(dialog.name_box.visible).is_true()


## A piece pressed is worn and kept, its tag says so and the tray marks it; one not won is not.
func test_a_piece_pressed_is_worn_and_kept() -> void:
	Game.settings.profile.loyalty.win(&"fedora")
	var dialog := await _open()
	var fedora := KartStyle.HATS.find("Fedora")
	assert_bool(dialog.wear(1, fedora)).is_true()
	assert_int(KartStyle.from_array(Game.settings.seat_style(0)).hat).is_equal(fedora)
	assert_str(dialog.hooks[1].worn).is_equal("Fedora")
	assert_bool(_cell(dialog, fedora).worn).is_true()
	assert_int(dialog.stage.shown.hat).is_equal(fedora)
	# Kept in the profile's own file, not only for this run.
	var again := Settings.new()
	again.path = PATH
	again.load_from_disk()
	assert_int(KartStyle.from_array(again.seat_style(0)).hat).is_equal(fedora)
	assert_bool(dialog.wear(1, KartStyle.HATS.find("Top hat"))).is_false()
	assert_int(KartStyle.from_array(Game.settings.seat_style(0)).hat).is_equal(fedora)


## The card back is the profile's, chosen from the backs it has won.
func test_the_card_back_is_chosen_from_those_won() -> void:
	Game.settings.profile.loyalty.win(&"gilt_back")
	var dialog := await _open()
	assert_bool(dialog.hooks[KartDialog.CARD_BACK].visible).is_true()
	var gilt := CardBack.STYLES.find("Gilt")
	dialog.wear(KartDialog.CARD_BACK, gilt)
	assert_int(Game.settings.profile.loyalty.card_back).is_equal(gilt)
	assert_str(dialog.hooks[KartDialog.CARD_BACK].worn).is_equal("Gilt")
	dialog.wear(KartDialog.CARD_BACK, CardBack.STYLES.find("Doodled"))
	assert_int(Game.settings.profile.loyalty.card_back).is_equal(gilt)


## B puts the tray back first, and only then the dialog away.
func test_back_puts_the_tray_back_before_the_dialog() -> void:
	var dialog := await _open()
	dialog.open_tray(2)
	await get_tree().process_frame
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	dialog._unhandled_input(cancel)
	assert_bool(dialog.tray.is_out()).is_false()
	assert_bool(dialog.is_closing()).is_false()
	dialog._unhandled_input(cancel)
	assert_bool(dialog.is_closing()).is_true()


## The name written on the tape is the seat's; the die rolls one the house makes up.
func test_the_name_is_written_or_rolled() -> void:
	var dialog := await _open()
	dialog.name_box.text = "Lady Luck"
	dialog.name_box.text_submitted.emit(dialog.name_box.text)
	assert_str(Game.settings.seat_name(0)).is_equal("Lady Luck")
	assert_str(dialog.keys[0].named).is_equal("Lady Luck")
	dialog.roll_name()
	assert_str(Game.settings.seat_name(0)).is_not_equal("Lady Luck")
	assert_str(Game.settings.seat_name(0)).is_equal(dialog.name_box.text)
	assert_str(dialog.name_box.text).is_not_empty()


## A can pressed is the seat's color from then on, its favorite.
func test_a_can_pressed_is_the_color() -> void:
	var dialog := await _open()
	dialog.pick_color(5)
	assert_int(Game.settings.seat_color(0)).is_equal(5)
	assert_bool(dialog.cans[5].chosen).is_true()
	assert_int(dialog.stage.shown_color).is_equal(5)


## The plate is typed onto the plate once there is a license; before one the learner's L is there,
## saying itself.
func test_the_plate_comes_with_the_license() -> void:
	var dialog := await _open()
	assert_bool(dialog.plate_field.visible).is_false()
	assert_bool(dialog.plate_note.visible).is_false()
	assert_bool(dialog._learner.visible).is_true()
	dialog.close()
	Game.settings.profile.license_number = "JJ-000042"
	Game.settings.profile.license_plate = "SES-773"
	var licensed := await _open()
	assert_bool(licensed.plate_field.visible).is_true()
	assert_bool(licensed._learner.visible).is_false()
	assert_str(licensed.plate_field.text).is_equal("SES-773")
	licensed.plate_field.plate_changed.emit("LUCKY 7")
	assert_str(Game.settings.profile.license_plate).is_equal("LUCKY 7")
	assert_str(licensed.stage.shown_plate).is_equal("LUCKY 7")


## Every other profile kept here has a tab of its own, after the profile playing's; what is changed
## on it is kept in its own file, the profile playing's left as it was.
func test_another_profile_is_dressed_in_its_own_file() -> void:
	Game.settings.save_to_disk()
	var other := Game.settings.new_profile()
	other.player_names[0] = "Dice Daisy"
	other.save_to_disk()
	var dialog := await _open()
	assert_int(dialog.owners.size()).is_equal(2)
	assert_str(dialog.keys[1].named).is_equal("Dice Daisy")
	dialog.switch_owner(1)
	assert_int(dialog.current).is_equal(1)
	assert_str(dialog.name_box.text).is_equal("Dice Daisy")
	assert_bool(dialog.wear(0, 3)).is_true()
	dialog.pick_color(6)
	var kept := Profile.at(Game.settings.profiles_dir(), other.id)
	assert_int(KartStyle.from_array(kept.kart_styles[0]).paint).is_equal(3)
	assert_int(kept.colors[0]).is_equal(6)
	assert_int(KartStyle.from_array(Game.settings.seat_style(0)).paint).is_equal(0)
	dialog.switch_owner(1)
	assert_int(dialog.current).is_equal(0)


## Where a piece is won is the landmark of the loyalty program that pays it; everybody's is won
## nowhere.
func test_where_a_piece_is_won() -> void:
	assert_str(KartOwner.won_at(1, KartStyle.HATS.find("Fedora"))).is_not_empty()
	assert_str(KartOwner.won_at(1, KartStyle.HATS.find("Cap"))).is_empty()
	assert_str(KartOwner.won_at(KartDialog.CARD_BACK, CardBack.STYLES.find("Gilt"))).is_not_empty()


## Every tray holds its part's None first, or its plain one where it has none: the trail's None,
## which comes after its plain smoke in the part's own order, at the front.
func test_none_comes_first_in_every_tray() -> void:
	var dialog := await _open()
	for part: int in KartDialog.CARD_BACK + 1:
		dialog.open_tray(part)
		await get_tree().process_frame
		var first := dialog.tray.cells[0]
		var choices := KartDialog.choices_of(part)
		var expected := choices.find("None") if "None" in choices else 0
		assert_int(first.index).override_failure_message("part %d" % part).is_equal(expected)
		assert_int(dialog.tray.cells.size()).is_equal(choices.size())
	dialog.open_tray(3)
	assert_str(dialog.tray.cells[0].named).is_equal("None")
	assert_str(dialog.tray.cells[1].named).is_equal("Smoke")


## The mouse over a piece has the kart wear it for as long as it is there; gone off it, the kart
## wears what it did.
func test_the_mouse_tries_a_piece_on_only_while_it_is_over_it() -> void:
	Game.settings.profile.loyalty.win(&"fedora")
	var dialog := await _open()
	dialog.open_tray(1)
	await get_tree().process_frame
	var fedora := dialog.tray.cell_at(KartStyle.HATS.find("Fedora"))
	fedora.mouse_entered.emit()
	assert_int(dialog.stage.shown.hat).is_equal(KartStyle.HATS.find("Fedora"))
	fedora.mouse_exited.emit()
	assert_int(dialog.stage.shown.hat).is_equal(0)


## The tray has its own Close, and arrows that scroll it a trayful at a time.
func test_the_tray_closes_and_scrolls_by_its_buttons() -> void:
	var dialog := await _open()
	dialog.open_tray(1)
	await get_tree().process_frame
	await get_tree().process_frame
	var scroll := dialog.tray.find_child("Scroll", true, false) as ScrollContainer
	var on := dialog.tray.find_child("On", true, false) as Button
	var back := dialog.tray.find_child("Back", true, false) as Button
	assert_bool(back.disabled).is_true()
	assert_bool(on.disabled).is_false()
	on.pressed.emit()
	assert_int(scroll.scroll_horizontal).is_greater(0)
	assert_bool(back.disabled).is_false()
	(dialog.tray.find_child("Close", true, false) as Button).pressed.emit()
	assert_bool(dialog.tray.is_out()).is_false()
	assert_int(dialog.open_part).is_equal(-1)


## The shuffle's push button puts a piece of every part on at random, of those the profile has won
## or everybody has, and a color other than the one it was in, and keeps them.
func test_the_shuffle_dresses_every_part_from_what_is_won() -> void:
	Game.settings.set_seat_color(0, 3)
	var dialog := await _open()
	for each: int in 6:
		var color_was := Game.settings.seat_color(0)
		dialog.hooks[KartDialog.SHUFFLE].pressed.emit()
		var worn := KartStyle.from_array(Game.settings.seat_style(0)).to_array()
		for part: int in KartStyle.CHOICES.size():
			assert_bool(worn[part] in KartStyle.EVERYBODY[part]).is_true()
		assert_array(Array(dialog.stage.shown.to_array().slice(0, 6))).is_equal(
			Array(worn.slice(0, 6))
		)
		var color := Game.settings.seat_color(0)
		assert_int(color).is_not_equal(color_was)
		assert_int(dialog.stage.shown_color).is_equal(color)
		assert_bool(dialog.cans[color].chosen).is_true()


## The kart is shown standing as the dialog opens; a hook the cursor moves to, or a part's tray
## out, has it shown as that part is best seen, and a rope from that hook to the part. The
## shuffle's hook has none.
func test_a_hook_looked_at_has_its_view_and_its_rope() -> void:
	var dialog := await _open()
	await get_tree().process_frame
	assert_int(dialog.stage.part_shown).is_equal(-1)
	assert_array(dialog.roped_parts()).is_empty()
	dialog.hooks[1].grab_focus()
	await get_tree().process_frame
	assert_int(dialog.stage.part_shown).is_equal(1)
	assert_array(dialog.roped_parts()).is_equal([1])
	dialog.open_tray(5)
	await get_tree().process_frame
	assert_int(dialog.stage.part_shown).is_equal(5)
	assert_bool(dialog.stage.driving()).is_true()
	assert_array(dialog.roped_parts()).contains([5])
	dialog.close_tray()
	dialog.hooks[KartDialog.SHUFFLE].grab_focus()
	await get_tree().process_frame
	assert_int(dialog.stage.part_shown).is_equal(-1)


## The die is at the right end of the name's tape, inside it, and the bay has its frame on a
## screen with room round the dialog.
func test_the_die_is_in_the_name_box_and_the_bay_is_framed() -> void:
	var dialog := await _open()
	assert_bool(BayArt.NAME_TAPE.encloses(BayArt.DIE)).is_true()
	assert_float(BayArt.DIE.get_center().x).is_greater(BayArt.NAME_TAPE.get_center().x)
	assert_bool(dialog.is_framed()).is_equal(
		dialog.get_viewport().get_visible_rect().size.y >= CatalogDialog.SHORT
	)


## Every rack holds what is won, and everybody's, before what is still to be won, whatever order the
## part has them in.
func test_won_pieces_come_before_those_still_to_be_won() -> void:
	Game.settings.profile.loyalty.win(&"fedora")
	var dialog := await _open()
	for part: int in KartDialog.CARD_BACK + 1:
		dialog.open_tray(part)
		await get_tree().process_frame
		var still_to_win := false
		for cell: PartTray.TrayCell in dialog.tray.cells:
			(
				assert_bool(still_to_win and cell.owned)
				. override_failure_message(
					"part %d: %s after one still to be won" % [part, cell.named]
				)
				. is_false()
			)
			still_to_win = still_to_win or not cell.owned
	dialog.open_tray(1)
	var fedora := dialog.tray.cells.find(_cell(dialog, KartStyle.HATS.find("Fedora")))
	var top_hat := dialog.tray.cells.find(_cell(dialog, KartStyle.HATS.find("Top hat")))
	assert_int(fedora).is_less(top_hat)


## The mouse over a can, or the cursor on one, has the kart try its color on for as long as it is
## there; only pressed is it kept.
func test_a_can_tries_its_color_on_until_it_is_pressed() -> void:
	Game.settings.set_seat_color(0, 1)
	var dialog := await _open()
	dialog.cans[5].mouse_entered.emit()
	assert_int(dialog.stage.shown_color).is_equal(5)
	assert_int(Game.settings.seat_color(0)).is_equal(1)
	dialog.cans[5].mouse_exited.emit()
	assert_int(dialog.stage.shown_color).is_equal(1)
	dialog.cans[3].grab_focus()
	assert_int(dialog.stage.shown_color).is_equal(3)
	assert_int(Game.settings.seat_color(0)).is_equal(1)
	dialog.cans[3].pressed.emit()
	assert_int(Game.settings.seat_color(0)).is_equal(3)
	dialog.hooks[2].grab_focus()
	assert_int(dialog.stage.shown_color).is_equal(3)


## Down the left board the cursor goes from the trail to the card back and only then onto the bench,
## or onto the rack while it is out; with no card back here, from the trail. The bench is two rows:
## the cans over the name, its die and the plate, the shuffle's plate over the plate; with no plate
## to type, right from the die is the shuffle.
func test_the_cursor_goes_down_each_board_and_round_the_bench() -> void:
	Game.settings.profile.license_number = "JJ-000042"
	Game.settings.profile.license_plate = "SES-773"
	var dialog := await _open()
	var trail := dialog.hooks[3]
	var card_back := dialog.hooks[KartDialog.CARD_BACK]
	var shuffle := dialog.hooks[KartDialog.SHUFFLE]
	var ways: Array[Array] = [
		[trail, SIDE_BOTTOM, card_back],
		[card_back, SIDE_BOTTOM, dialog.cans[0]],
		[dialog.hooks[5], SIDE_BOTTOM, shuffle],
		[shuffle, SIDE_BOTTOM, dialog.plate_field],
		[dialog.cans[0], SIDE_BOTTOM, dialog.name_box],
		[dialog.cans[6], SIDE_BOTTOM, dialog.name_box],
		[dialog.cans[2], SIDE_RIGHT, dialog.cans[3]],
		[dialog.name_box, SIDE_RIGHT, dialog.die],
		[dialog.die, SIDE_RIGHT, dialog.plate_field],
		[dialog.plate_field, SIDE_LEFT, dialog.die],
		[dialog.name_box, SIDE_TOP, dialog.cans[0]],
		[dialog.die, SIDE_TOP, dialog.cans[-1]],
		[dialog.plate_field, SIDE_TOP, shuffle],
	]
	for way: Array in ways:
		var from: Control = way[0]
		var to: Control = way[2]
		(
			assert_object(from.find_valid_focus_neighbor(way[1]))
			. override_failure_message("%s %d should lead to %s" % [from.name, way[1], to.name])
			. is_same(to)
		)
	dialog.open_tray(1)
	assert_bool(card_back.find_valid_focus_neighbor(SIDE_BOTTOM) is PartTray.TrayCell).is_true()
	assert_bool(shuffle.find_valid_focus_neighbor(SIDE_BOTTOM) is PartTray.TrayCell).is_true()
	dialog.close_tray()
	assert_object(card_back.find_valid_focus_neighbor(SIDE_BOTTOM)).is_same(dialog.cans[0])
	card_back.visible = false
	dialog._link_bench()
	assert_object(trail.find_valid_focus_neighbor(SIDE_BOTTOM)).is_same(dialog.cans[0])
	assert_object(shuffle.find_valid_focus_neighbor(SIDE_LEFT)).is_same(trail)
	# With no plate to type, the learner's L in its place, right from the die is the shuffle.
	dialog.close()
	Game.settings.profile.license_number = ""
	var learner := await _open()
	assert_bool(learner.plate_field.visible).is_false()
	assert_object(learner.die.find_valid_focus_neighbor(SIDE_RIGHT)).is_same(
		learner.hooks[KartDialog.SHUFFLE]
	)


## A part looked at has the kart turned quickly to where that part is best seen, inside a second,
## where it drifts back slowly from where a hand left it.
func test_the_kart_turns_quickly_to_a_part() -> void:
	var stage := KartStage.new()
	stage.size = BayArt.VIEW.size
	_holder.add_child(stage)
	await get_tree().process_frame
	stage.yaw = KartStage.VIEWS[-1]["yaw"]
	stage.view(2)
	for step: int in 20:
		stage._process(0.05)
	var to: float = KartStage.VIEWS[2]["yaw"]
	assert_float(absf(angle_difference(stage.yaw, to))).is_less(KartStage.SWAY)
	assert_bool(stage.turning_to_view).is_false()


## A donut, as the shuffle sets one off, ends as it started: nowhere along it, its end too, does the
## kart jump from where it was the frame before.
func test_a_donut_ends_where_it_started() -> void:
	var stage := KartStage.new()
	stage.size = BayArt.VIEW.size
	_holder.add_child(stage)
	await get_tree().process_frame
	stage.play(KartStage.Move.DONUT)
	var mover := stage.get_node("Render/Spot/Moves") as Node3D
	var was := mover.transform
	var step := 1.0 / 60.0
	for frame: int in ceili(KartStage.MOVE_TIME[KartStage.Move.DONUT] / step) + 5:
		stage._step_move(step)
		var now := mover.transform
		assert_float(now.origin.distance_to(was.origin)).is_less(0.15)
		var turned := now.basis.get_rotation_quaternion().angle_to(
			was.basis.get_rotation_quaternion()
		)
		assert_float(turned).is_less(0.3)
		was = now
	assert_bool(stage.is_moving()).is_false()
	assert_bool(mover.transform.is_equal_approx(Transform3D.IDENTITY)).is_true()


## A move asked for in the middle of another, a shuffle pressed in its donut, waits for that one to
## end rather than cutting it short: the kart never jumps from one frame to the next.
func test_a_move_waits_for_the_one_it_is_in() -> void:
	var stage := KartStage.new()
	stage.size = BayArt.VIEW.size
	_holder.add_child(stage)
	await get_tree().process_frame
	stage.play(KartStage.Move.DONUT)
	var mover := stage.get_node("Render/Spot/Moves") as Node3D
	var was := mover.transform
	var step := 1.0 / 60.0
	var donut := KartStage.MOVE_TIME[KartStage.Move.DONUT]
	for frame: int in ceili(donut * 2.0 / step) + 5:
		if frame == 60:
			stage.play(KartStage.Move.DONUT)
		stage._step_move(step)
		var now := mover.transform
		assert_float(now.origin.distance_to(was.origin)).is_less(0.15)
		var turned := now.basis.get_rotation_quaternion().angle_to(
			was.basis.get_rotation_quaternion()
		)
		assert_float(turned).is_less(0.3)
		# Still in the second donut past where the first one, cut short, would have ended.
		if frame == ceili((donut + 1.0) / step):
			assert_bool(stage.is_moving()).is_true()
		was = now
	assert_bool(stage.is_moving()).is_false()


## With keys or a pad in hand, what the cursor is on wears the key that presses it under it: a
## hook, a can, the name, the die; only that one, and none with the mouse in hand. Back wears
## Escape only while Escape would put the dialog away, not while the rack is out.
func test_what_the_cursor_is_on_wears_its_key() -> void:
	var dialog := await _open()
	dialog._keyboard = true
	dialog._pointer = false
	dialog.hooks[4].grab_focus()
	var bind := dialog._press_bind as InputGlyph
	assert_object(bind).is_not_null()
	assert_bool(BoardArt.hook_rect(4).has_point(bind.position)).is_true()
	assert_int(bind.kind).is_equal(InputGlyph.Kind.KEY)
	for control: Control in [dialog.cans[0], dialog.name_box, dialog.die]:
		control.grab_focus()
		bind = dialog._press_bind as InputGlyph
		assert_object(bind).override_failure_message(control.name).is_not_null()
		assert_float(bind.position.y).is_less(control.get_rect().end.y)
		assert_float(bind.position.y + bind.size.y).is_greater(control.get_rect().end.y)
	dialog._show_binds()
	assert_object(dialog.back.get_node_or_null("Bind")).is_not_null()
	dialog.open_tray(1)
	assert_object(dialog.back.get_node_or_null("Bind")).is_null()
	dialog.close_tray()
	assert_object(dialog.back.get_node_or_null("Bind")).is_not_null()
	dialog._keyboard = false
	dialog.hooks[KartDialog.CARD_BACK].grab_focus()
	assert_int((dialog._press_bind as InputGlyph).kind).is_equal(InputGlyph.Kind.FACE)
	dialog._pointer = true
	dialog.hooks[1].grab_focus()
	assert_object(dialog._press_bind).is_null()


## The card back is on no kart: its hook looked at holds up a hand of cards in the back, the kart
## left turned as it was, not to be turned, and the card back's rope tied to the hand; a back tried
## on in its rack is the one held up; looked away from, or its rack put back, the hand is put down.
func test_the_card_back_is_held_up_in_a_hand_of_cards() -> void:
	var dialog := await _open()
	dialog.hooks[1].grab_focus()
	for frame: int in 30:
		await get_tree().process_frame
	var facing := dialog.stage.yaw
	dialog.hooks[KartDialog.CARD_BACK].grab_focus()
	for frame: int in 30:
		await get_tree().process_frame
	assert_int(dialog.stage.part_shown).is_equal(KartDialog.CARD_BACK)
	assert_float(absf(angle_difference(dialog.stage.yaw, facing))).is_less(0.01)
	assert_bool(dialog._fan.is_held()).is_true()
	assert_int(dialog._fan.style).is_equal(dialog.kart_owner().card_back())
	# Behind the cards, it is not to be turned.
	assert_bool(dialog.stage.can_turn()).is_false()
	assert_bool(dialog._turn_hint.visible).is_false()
	dialog.stage.turn(0.5)
	assert_float(absf(angle_difference(dialog.stage.yaw, facing))).is_less(0.01)
	assert_array(dialog.roped_parts()).contains([KartDialog.CARD_BACK])
	assert_bool(Rect2(Vector2.ZERO, BayArt.STAGE).has_point(dialog._fan.anchor())).is_true()
	Game.settings.profile.loyalty.win(&"gilt_back")
	dialog.open_tray(KartDialog.CARD_BACK)
	await get_tree().process_frame
	var gilt := CardBack.STYLES.find("Gilt")
	dialog._try(gilt)
	await get_tree().process_frame
	assert_int(dialog._fan.style).is_equal(gilt)
	# The rack put back puts the hand down with it, the cursor left on the hook, until it moves.
	dialog.close_tray()
	for frame: int in 60:
		await get_tree().process_frame
	assert_object(get_viewport().gui_get_focus_owner()).is_same(dialog.hooks[KartDialog.CARD_BACK])
	assert_bool(dialog._fan.is_held()).is_false()
	assert_int(dialog.stage.part_shown).is_equal(-1)
	assert_array(dialog.roped_parts()).not_contains([KartDialog.CARD_BACK])
	dialog.hooks[1].grab_focus()
	dialog.hooks[KartDialog.CARD_BACK].grab_focus()
	await get_tree().process_frame
	assert_bool(dialog._fan.is_held()).is_true()
	dialog.hooks[1].grab_focus()
	for frame: int in 60:
		await get_tree().process_frame
	assert_bool(dialog._fan.is_held()).is_false()


## None of its marks are laid on the lift's turntable, which turns with it: a wheel off it again
## starts a new mark rather than running the last one on across it.
func test_no_marks_are_laid_on_the_turntable() -> void:
	var stage := KartStage.new()
	stage.size = BayArt.VIEW.size
	_holder.add_child(stage)
	stage.show_kart(KartStyle.new(), 0, "")
	await get_tree().process_frame
	await get_tree().process_frame
	var spot := stage.get_node("Render/Spot") as Node3D
	stage._lay_marks(1.0)
	for wheel: int in 2:
		assert_array(stage._marks._open[wheel]).is_empty()
	spot.position = Vector3(0.0, 0.0, 2.0)
	stage._lay_marks(1.0)
	spot.position = Vector3.ZERO
	stage._lay_marks(1.0)
	spot.position = Vector3(0.0, 0.0, 1.7)
	stage._lay_marks(1.0)
	for wheel: int in 2:
		var samples: Array = stage._marks._open[wheel]
		assert_int(samples.size()).is_equal(2)
		assert_bool(samples[1]["start"]).is_true()


## The fuzzy dice swing on their strings while a hand turns the kart and a little after, and hang
## still once it has stood a while.
func test_what_flies_from_it_swings_while_it_is_turned() -> void:
	var stage := KartStage.new()
	stage.size = BayArt.VIEW.size
	_holder.add_child(stage)
	var style := KartStyle.new()
	style.flag = KartStyle.FLAGS.find("Fuzzy dice")
	stage.show_kart(style, 0, "")
	await get_tree().process_frame
	await get_tree().process_frame
	assert_int(stage._sways.size()).is_equal(1)
	var dice := stage._sways[0]
	var step := 1.0 / 60.0
	for frame: int in ceili(KartStage.TURN_SWING / step) + 2:
		stage._settle_sways(step)
	assert_bool(dice.is_physics_processing()).is_false()
	stage.turn(0.2)
	stage._settle_sways(step)
	assert_bool(dice.is_physics_processing()).is_true()
	for frame: int in ceili(KartStage.TURN_SWING / step) + 2:
		stage._settle_sways(step)
	assert_bool(dice.is_physics_processing()).is_false()


## The rope from the hat is tied to the hat as it is: higher for a tall one than for none.
func test_the_hats_rope_is_tied_to_the_hat_worn() -> void:
	var dialog := await _open()
	for frame: int in 4:
		await get_tree().process_frame
	var bare := dialog.stage._hat()
	Game.settings.profile.loyalty.win(&"fedora")
	dialog.open_tray(1)
	# The cursor comes down onto the rack a frame on, and tries on what it lands on.
	await get_tree().process_frame
	dialog._choose(KartStyle.HATS.find("Fedora"))
	assert_int(KartStyle.from_array(Game.settings.seat_style(0)).hat).is_equal(
		KartStyle.HATS.find("Fedora")
	)
	dialog.close_tray()
	await get_tree().process_frame
	await get_tree().process_frame
	var topped := dialog.stage._hat()
	assert_float(topped.y).is_greater(bare.y)


## Every move it does by itself ends with it standing as it started.
func test_every_move_ends_as_it_started() -> void:
	for move: int in KartStage.MOVE_TIME:
		var length: float = KartStage.MOVE_TIME[move]
		var pose := KartMoves.pose(move, length, length)
		for key: String in ["lift", "pitch", "roll", "slide"]:
			(
				assert_float(absf(pose[key]))
				. override_failure_message("%s %s" % [KartStage.Move.keys()[move], key])
				. is_less(0.02)
			)
		assert_float(fposmod(pose["turned"] + 0.01, TAU)).is_less(0.03)
		assert_float(pose["squash"]).is_equal_approx(1.0, 0.01)


## Shown for its trail, the kart turns round on the lift to face the way out, drives off it to its
## laps on the floor in front of it, clear of the posts, and shown for another part drives back
## and hops up onto the lift. Never a jump from one frame to the next on the way, where it is or
## which way it faces, and it never rolls off before it faces the way out.
func test_the_kart_drives_off_to_its_laps_and_back() -> void:
	var stage := KartStage.new()
	stage.size = BayArt.VIEW.size
	_holder.add_child(stage)
	await get_tree().process_frame
	var spot := stage.get_node("Render/Spot") as Node3D
	var step := 1.0 / 60.0
	var was := spot.position
	var facing_was := spot.rotation.y
	stage.view(3)
	var nearest := 99.0
	for frame: int in 300:
		stage._process(step)
		assert_float(spot.position.distance_to(was)).is_less(0.12)
		assert_float(absf(angle_difference(facing_was, spot.rotation.y))).is_less(0.25)
		if spot.position.distance_to(was) > 0.0001 and stage._where == KartStage.Where.LEAVING:
			# Rolling off the way it faces.
			var going := (spot.position - was).normalized()
			var faces := Vector3.FORWARD.rotated(Vector3.UP, spot.rotation.y)
			assert_float(going.dot(faces)).is_greater(0.5)
		was = spot.position
		facing_was = spot.rotation.y
		if stage._where == KartStage.Where.LAPS:
			nearest = minf(nearest, spot.position.z)
	assert_bool(stage.is_away()).is_true()
	# Round in front of the lift's posts, never between them.
	assert_float(nearest).is_greater(BaySet.POST.z + 0.5)
	stage.view(2)
	var hopped := false
	for frame: int in 300:
		stage._process(step)
		assert_float(spot.position.distance_to(was)).is_less(0.12)
		assert_float(absf(angle_difference(facing_was, spot.rotation.y))).is_less(0.25)
		was = spot.position
		facing_was = spot.rotation.y
		hopped = hopped or stage.is_moving()
	assert_bool(stage.is_away()).is_false()
	assert_bool(hopped).is_true()
	assert_float(spot.position.length()).is_less(0.001)


## A move that needs room, as the shuffle's donut, is done out on the floor in front of the lift,
## not between its posts: driven out to, done, and driven back onto the lift, never a jump.
func test_a_donut_is_done_in_front_of_the_lift() -> void:
	var stage := KartStage.new()
	stage.size = BayArt.VIEW.size
	_holder.add_child(stage)
	await get_tree().process_frame
	var spot := stage.get_node("Render/Spot") as Node3D
	var step := 1.0 / 60.0
	var was := spot.position
	stage.perform(KartStage.Move.DONUT)
	var out_front := false
	for frame: int in 600:
		stage._process(step)
		assert_float(spot.position.distance_to(was)).is_less(0.12)
		was = spot.position
		if stage._where == KartStage.Where.SHOWING and stage.is_moving():
			out_front = true
			assert_float(spot.position.z).is_greater(BaySet.POST.z + 0.5)
	assert_bool(out_front).is_true()
	assert_bool(stage.is_away()).is_false()
	assert_float(spot.position.length()).is_less(0.001)


## The bay takes part in the story only quietly, STORY.md 6.10: the notes pinned up are the last of
## the story's own notes found, the latest first, six at the most, none before one is, a loose one
## never.
func test_the_bay_pins_up_the_last_notes_found() -> void:
	var profile := Game.settings.profile
	assert_array(BaySet._last_notes(profile, 6)).is_empty()
	profile.story.notes = PackedInt32Array([2, 5, Story.NOTE_COUNT + 40])
	assert_array(BaySet._last_notes(profile, 6)).is_equal([5, 2])
	profile.story.notes = PackedInt32Array([1, 2, 3, 4, 5, 6, 7, 8])
	assert_array(BaySet._last_notes(profile, 6)).is_equal([8, 7, 6, 5, 4, 3])
	profile.story.notes = PackedInt32Array()


## The shuffle's die spins as a slot machine's reel: its faces run on through it, never one the same
## as the one before, a little past the last as it stops, and it comes to rest on that one.
func test_the_shuffle_die_spins_as_a_reel() -> void:
	var dialog := await _open()
	var die := dialog.hooks[KartDialog.SHUFFLE]
	die.roll()
	assert_int(die._reel.size()).is_equal(PartHook.ROLL_FACES + 1)
	for k: int in range(1, die._reel.size()):
		assert_int(die._reel[k]).is_not_equal(die._reel[k - 1])
	assert_float(PartHook.reel_run(0.0)).is_equal(0.0)
	assert_float(PartHook.reel_run(PartHook.ROLL_STOP)).is_greater(PartHook.ROLL_FACES)
	assert_float(PartHook.reel_run(1.0)).is_equal_approx(PartHook.ROLL_FACES, 0.001)
	var was := 0.0
	for k: int in 41:
		var run := PartHook.reel_run(PartHook.ROLL_STOP * k / 40.0)
		assert_float(run).is_greater_equal(was)
		was = run
	await get_tree().create_timer(PartHook.ROLL + 0.1).timeout
	assert_int(die.face).is_equal(die._reel[-1])


## The name's die is thrown as a cube: up off the tape and tumbling over, and rolled to rest with
## another face than it showed turned out to the viewer.
func test_the_name_die_tumbles_and_lands_on_another_face() -> void:
	var dialog := await _open()
	var die := dialog.die
	var was := die.face
	die.throw()
	assert_int(die.face).is_not_equal(was)
	die._thrown = NameDie.TUMBLE * 0.3
	assert_float(die._rise()).is_greater(NameDie.LIFT + NameDie.THROW * 0.5)
	die._thrown = NameDie.TUMBLE * NameDie.ROLLED
	var landed := die._turned() * NameDie.facing(die.face).inverse() * Vector3.BACK
	assert_float(landed.z).is_greater(0.999)
	die._thrown = 0.0
	await get_tree().create_timer(NameDie.TUMBLE + 0.1).timeout
	assert_bool(die.is_thrown()).is_false()


## With more keys than the rail has room for, they scroll along it: by the wheel, dragged by the
## mouse or a finger, by a chevron at either end, and to the one the page keys turn to; they fade
## out toward an end there are more past, its chevron showing. A key pressed, rather than dragged,
## turns the dialog to it.
func test_the_keys_scroll_along_the_rail() -> void:
	Game.settings.save_to_disk()
	for i: int in Profile.MOST - 1:
		var other := Game.settings.new_profile()
		other.player_names[0] = "Profile %d" % i
		other.save_to_disk()
	var dialog := await _open()
	var rail := dialog._rail
	assert_float(rail.most()).is_greater(0.0)
	assert_float(rail.scrolled()).is_equal(0.0)
	assert_float(dialog.keys[0].seen).is_equal(1.0)
	assert_float(dialog.keys[-1].fades[-1].y).is_equal(0.0)
	# A chevron only toward more keys; pressed, it scrolls a railful on.
	await get_tree().create_timer(KeyRail.ARROW_FADE * 2.0).timeout
	assert_bool(rail.arrows[0].visible).is_false()
	assert_bool(rail.arrows[1].visible).is_true()
	rail.arrows[1].pressed.emit()
	await get_tree().create_timer(KeyRail.EASE_RATE * 10.0).timeout
	assert_float(rail.scrolled()).is_greater(KeyRail.WHEEL_STEP)
	assert_bool(rail.arrows[0].visible).is_true()
	rail.arrows[0].pressed.emit()
	await get_tree().create_timer(KeyRail.EASE_RATE * 10.0).timeout
	assert_float(rail.scrolled()).is_equal(0.0)
	var along := Vector2(rail.size.x * 0.5, KeyRail.DEEP * 0.5)
	assert_bool(rail._has_point(along)).is_true()
	rail._gui_input(_mouse(MOUSE_BUTTON_WHEEL_DOWN, true, along))
	await get_tree().create_timer(KeyRail.EASE_RATE * 10.0).timeout
	assert_float(rail.scrolled()).is_equal_approx(KeyRail.WHEEL_STEP, 0.5)
	assert_float(dialog.keys[0].fades[0].y).is_less(1.0)
	# Each key's picture on a whole pixel of the screen, so it does not shimmer as it moves.
	rail.scroll_to(KeyRail.WHEEL_STEP + 0.37, true)
	var screen := get_viewport().get_final_transform() * rail.get_global_transform_with_canvas()
	for each: KeyTag in dialog.keys:
		var edge := (screen * Vector2(each.position.x - KeyTag.AROUND, 0.0)).x
		assert_float(absf(edge - roundf(edge))).is_less(0.01)
	rail.scroll_to(KeyRail.WHEEL_STEP, true)
	# Dragged back by a finger, the mouse it stands in for: it scrolls, and picks nothing.
	rail._gui_input(_mouse(MOUSE_BUTTON_LEFT, true, along))
	var drag := InputEventMouseMotion.new()
	drag.position = along + Vector2(KeyRail.WHEEL_STEP * 0.5, 0.0)
	rail._gui_input(drag)
	assert_float(rail.scrolled()).is_equal_approx(KeyRail.WHEEL_STEP * 0.5, 0.5)
	rail._gui_input(_mouse(MOUSE_BUTTON_LEFT, false, drag.position))
	assert_int(dialog.current).is_equal(0)
	var key := dialog.keys[2]
	var on := key.position + key.size * 0.5
	rail._gui_input(_mouse(MOUSE_BUTTON_LEFT, true, on))
	rail._gui_input(_mouse(MOUSE_BUTTON_LEFT, false, on))
	assert_int(dialog.current).is_equal(2)
	# The page keys round to the last: it is scrolled into sight, the first faded out.
	dialog.switch_owner(-3)
	await get_tree().create_timer(KeyRail.EASE_RATE * 10.0).timeout
	assert_int(dialog.current).is_equal(dialog.keys.size() - 1)
	assert_float(rail.scrolled()).is_equal_approx(rail.most(), 0.5)
	assert_float(dialog.keys[-1].seen).is_equal(1.0)
	assert_float(dialog.keys[-1].fades[-1].y).is_equal(1.0)
	assert_bool(dialog.keys[0].visible).is_false()


## With room for every key, the rail takes the pointer only over them, for the kart under it to be
## turned there, and the wheel does not scroll it.
func test_keys_with_room_do_not_scroll() -> void:
	var dialog := await _open()
	var rail := dialog._rail
	assert_float(rail.most()).is_equal(0.0)
	var past := Vector2(rail.size.x - 10.0, KeyRail.DEEP * 0.5)
	assert_bool(rail._has_point(past)).is_false()
	rail._gui_input(_mouse(MOUSE_BUTTON_WHEEL_DOWN, true, past))
	await get_tree().process_frame
	assert_float(rail.scrolled()).is_equal(0.0)


func _mouse(button: MouseButton, down: bool, at: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = down
	event.position = at
	return event


## While a box is typed into, the binds of the keys that are letters are hidden, the page keys' and
## the shuffle's: they are typed, rather than turning the tabs or shuffling.
func test_letter_binds_hide_while_typing() -> void:
	Game.settings.save_to_disk()
	var other := Game.settings.new_profile()
	other.player_names[0] = "Dice Daisy"
	other.save_to_disk()
	var dialog := await _open()
	dialog._keyboard = true
	dialog._pointer = false
	dialog._show_binds()
	assert_object(dialog._page_hint).is_not_null()
	assert_object(dialog.hooks[KartDialog.SHUFFLE].get_node_or_null("Bind")).is_not_null()
	dialog.name_box.grab_focus()
	assert_bool(PlayerInput.typing).is_true()
	assert_object(dialog._page_hint).is_null()
	assert_object(dialog.hooks[KartDialog.SHUFFLE].get_node_or_null("Bind")).is_null()
	assert_bool(dialog._rail.hinted).is_true()
	dialog.hooks[1].grab_focus()
	assert_bool(PlayerInput.typing).is_false()
	assert_object(dialog._page_hint).is_not_null()


## Hung out, the rack rises into its place from behind the bench's edge; put away, it drops back
## and only then is hidden.
func test_the_rack_slides_up_and_down() -> void:
	var dialog := await _open()
	dialog.open_tray(1)
	assert_bool(dialog.tray.visible).is_true()
	assert_float(dialog.tray.position.y).is_greater(BayArt.TRAY.position.y)
	await get_tree().create_timer(PartTray.SLIDE_IN + 0.1).timeout
	assert_float(dialog.tray.position.y).is_equal_approx(BayArt.TRAY.position.y, 0.5)
	dialog.close_tray()
	assert_bool(dialog.tray.is_out()).is_false()
	assert_bool(dialog.tray.visible).is_true()
	await get_tree().create_timer(PartTray.SLIDE_OUT + 0.1).timeout
	assert_bool(dialog.tray.visible).is_false()
	assert_float(dialog.tray.position.y).is_greater(BayArt.TRAY.end.y)


## On a touch screen a finger dragged across the kart turns it, as the mouse does, and only once
## over: the phone makes a mouse of the finger too, which comes before it, see
## [method _phone_drag], and is left to the finger. A list under the dialog worked by finger, as a
## room's menu is, leaves the finger on the kart to it, see [method TouchInput.keep_touches].
func test_a_finger_turns_the_kart() -> void:
	var was_touch := TouchInput.enabled
	TouchInput.enabled = true
	var list := ScrollContainer.new()
	list.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	list.size = get_viewport().get_visible_rect().size
	_holder.add_child(list)
	var under := TouchScroll.attach(list)
	var dialog := await _open()
	var stage := dialog.stage
	assert_bool(stage.can_turn()).is_true()
	var at := stage.get_global_rect().intersection(get_viewport().get_visible_rect()).get_center()
	var facing := stage.yaw
	_phone_drag(at, [Vector2(20.0, 0.0), Vector2(20.0, 0.0), Vector2(10.0, 0.0)])
	# Fifty of the screen's pixels across, in the stage's own, the dialog being scaled to the screen.
	var across := 50.0 / stage.get_global_transform().get_scale().x
	var turned := angle_difference(facing, stage.yaw)
	assert_float(turned).is_equal_approx(across * KartStage.DRAG_TURN, 0.001)
	assert_bool(under.get("_finger") == -1).is_true()
	TouchInput.enabled = was_touch
	assert_bool(TouchInput.kept_from(list)).is_true()
	assert_bool(TouchInput.kept_from(stage)).is_false()
	dialog.close()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_bool(TouchInput.kept_from(list)).is_false()
	# The mouse the phone made of the finger off the screen again, so a test after this one does not
	# find it over whatever it puts up.
	var away := InputEventMouseMotion.new()
	away.position = Vector2(-100.0, -100.0)
	get_viewport().push_input(away, true)


## A finger put down at [param at], moved by each of [param moves] and let go, as a phone tells it:
## the mouse it makes of the finger first, then the finger itself, each time.
func _phone_drag(at: Vector2, moves: Array[Vector2]) -> void:
	var viewport := get_viewport()
	var press := _mouse(MOUSE_BUTTON_LEFT, true, at)
	press.device = InputEvent.DEVICE_ID_EMULATION
	viewport.push_input(press, true)
	var touch := InputEventScreenTouch.new()
	touch.position = at
	touch.pressed = true
	viewport.push_input(touch, true)
	var now := at
	for move: Vector2 in moves:
		now += move
		var motion := InputEventMouseMotion.new()
		motion.device = InputEvent.DEVICE_ID_EMULATION
		motion.position = now
		motion.relative = move
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		viewport.push_input(motion, true)
		var drag := InputEventScreenDrag.new()
		drag.position = now
		drag.relative = move
		viewport.push_input(drag, true)
	var release := _mouse(MOUSE_BUTTON_LEFT, false, now)
	release.device = InputEvent.DEVICE_ID_EMULATION
	viewport.push_input(release, true)
	var lift := InputEventScreenTouch.new()
	lift.position = now
	viewport.push_input(lift, true)
