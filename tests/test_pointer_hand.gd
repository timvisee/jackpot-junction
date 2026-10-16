extends GdUnitTestSuite
## The pointing hand, GAME.md 8.1a: with a mouse, whatever a click acts on shows the hand while the
## mouse is over it. The engine's buttons, switches, sliders, tabs and lists are given it as they
## come into the tree, the arrow on a button that cannot be pressed just now and between tabs, and
## a cursor of their own kept; what the game draws for itself and hears its own clicks on says
## where a click acts on it, as the kart dialog's hooks, cans and keys do, the catalog's suits and
## stack, the peeks on the title and the pages of Kit's folder. A field keeps its I-beam and the
## kart's turntable its hand that turns it.

const PATH := "user://test_pointer_hand.cfg"
const TITLE_SCENE := preload("res://scenes/ui/title.tscn")
const HAND := Control.CURSOR_POINTING_HAND
const ARROW := Control.CURSOR_ARROW

var _settings_were: Settings
var _holder: Control


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	_holder = Control.new()
	_holder.size = Vector2(1920.0, 1080.0)
	add_child(_holder)


func after_test() -> void:
	PlayerInput.typing = false
	if is_instance_valid(_holder):
		remove_child(_holder)
		_holder.free()
	Settings.remove_files(PATH)
	Game.settings = _settings_were


func _added(control: Control) -> Control:
	_holder.add_child(control)
	return control


static func _motion(at: Vector2) -> InputEventMouseMotion:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	return motion


func test_the_engines_controls_a_click_acts_on_show_the_hand() -> void:
	assert_int(_added(MenuTheme.button("Play")).mouse_default_cursor_shape).is_equal(HAND)
	assert_int(_added(CheckButton.new()).mouse_default_cursor_shape).is_equal(HAND)
	assert_int(_added(HSlider.new()).mouse_default_cursor_shape).is_equal(HAND)
	assert_int(_added(VScrollBar.new()).mouse_default_cursor_shape).is_equal(HAND)
	# The list a box drops, its items a control of the engine's own inside it.
	var box := _added(MenuTheme.option(["Low", "High"], 0)) as OptionButton
	assert_int(box.mouse_default_cursor_shape).is_equal(HAND)
	var items: Array[Control] = []
	for each: Node in box.get_popup().find_children("*", "", true, false):
		if each.is_class("PopupMenuItems"):
			items.append(each as Control)
	assert_int(items.size()).is_equal(1)
	assert_int(items[0].mouse_default_cursor_shape).is_equal(HAND)
	# What nothing is done to by a click keeps the arrow, and a field its I-beam.
	assert_int(_added(Label.new()).mouse_default_cursor_shape).is_equal(ARROW)
	assert_int(_added(ProgressBar.new()).mouse_default_cursor_shape).is_equal(ARROW)
	var field := _added(MenuTheme.field("", "", 12))
	assert_int(field.mouse_default_cursor_shape).is_equal(Control.CURSOR_IBEAM)


func test_a_button_that_cannot_be_pressed_shows_the_arrow() -> void:
	var button := _added(MenuTheme.button("Ready")) as Button
	button.disabled = true
	await await_idle_frame()
	assert_int(button.mouse_default_cursor_shape).is_equal(ARROW)
	button.disabled = false
	await await_idle_frame()
	assert_int(button.mouse_default_cursor_shape).is_equal(HAND)
	# Out of the tree and back, it is told again, and only once.
	_holder.remove_child(button)
	_holder.add_child(button)
	assert_int(button.draw.get_connections().size()).is_equal(1)
	button.queue_redraw()
	await await_idle_frame()
	assert_int(button.mouse_default_cursor_shape).is_equal(HAND)


## A button with a cursor of its own, as the grip a server is dragged by, keeps it, whether it can
## be pressed or not.
func test_a_cursor_of_its_own_is_kept() -> void:
	var grip := Button.new()
	grip.mouse_default_cursor_shape = Control.CURSOR_DRAG
	_added(grip)
	assert_int(grip.mouse_default_cursor_shape).is_equal(Control.CURSOR_DRAG)
	grip.disabled = true
	await await_idle_frame()
	assert_int(grip.mouse_default_cursor_shape).is_equal(Control.CURSOR_DRAG)


func test_a_row_of_tabs_shows_the_hand_over_a_tab_only() -> void:
	var bar := TabBar.new()
	bar.add_tab("Video")
	bar.add_tab("Sound")
	bar.add_tab("Controls")
	bar.size = Vector2(900.0, 48.0)
	_added(bar)
	bar.set_tab_disabled(2, true)
	bar.gui_input.emit(_motion(bar.get_tab_rect(1).get_center()))
	assert_int(bar.mouse_default_cursor_shape).is_equal(HAND)
	bar.gui_input.emit(_motion(Vector2(bar.size.x - 4.0, 8.0)))
	assert_int(bar.mouse_default_cursor_shape).is_equal(ARROW)
	bar.gui_input.emit(_motion(bar.get_tab_rect(2).get_center()))
	assert_int(bar.mouse_default_cursor_shape).is_equal(ARROW)
	bar.gui_input.emit(_motion(bar.get_tab_rect(0).get_center()))
	assert_int(bar.mouse_default_cursor_shape).is_equal(HAND)
	# A tab container's own row of tabs too.
	var tabs := TabContainer.new()
	var page := Control.new()
	page.name = "Page"
	tabs.add_child(page)
	_added(tabs)
	assert_int(tabs.get_tab_bar().mouse_default_cursor_shape).is_equal(HAND)


## GAME.md 8.8: every chip of the suits the catalog shows, and the half of the stack's field that
## can step that way.
func test_the_catalogs_suits_and_stack_show_the_hand() -> void:
	var suits := _added(SuitFilter.new())
	assert_int(suits.get_child_count()).is_equal(SuitFilter.ORDER.size())
	for chip: Control in suits.get_children():
		assert_int(chip.mouse_default_cursor_shape).is_equal(HAND)
	var stepper := _added(StackStepper.new()) as StackStepper
	stepper.size = StackStepper.SIZE
	stepper.show_stack(1, 3)
	var less := Vector2(StackStepper.SIZE.x * 0.25, StackStepper.SIZE.y * 0.5)
	var more := Vector2(StackStepper.SIZE.x * 0.75, StackStepper.SIZE.y * 0.5)
	stepper._gui_input(_motion(less))
	assert_int(stepper.mouse_default_cursor_shape).is_equal(ARROW)
	stepper._gui_input(_motion(more))
	assert_int(stepper.mouse_default_cursor_shape).is_equal(HAND)
	# Stepped as far as it goes under the pointer, the hand goes.
	stepper.show_stack(3, 3)
	assert_int(stepper.mouse_default_cursor_shape).is_equal(ARROW)


## GAME.md 4.4a: every hook, can, the die, Back and the rack's places and buttons, and a key on the
## rail under the mouse; a can somebody else is in cannot be pressed, and the kart on the
## turntable keeps the hand that turns it, the boxes their I-beam.
func test_the_kart_dialog_shows_the_hand_over_what_a_click_acts_on() -> void:
	var dialog := KartDialog.open(_holder)
	await await_idle_frame()
	await await_idle_frame()
	var pressed: Array[Control] = [dialog.die, dialog.back]
	pressed.append_array(dialog.hooks)
	pressed.append_array(dialog.cans)
	pressed.append_array(dialog._rail.arrows)
	for each: Control in pressed:
		var shape := each.mouse_default_cursor_shape
		assert_int(shape).override_failure_message(str(each.name)).is_equal(HAND)
	assert_int(dialog.stage.mouse_default_cursor_shape).is_equal(Control.CURSOR_DRAG)
	assert_int(dialog.name_box.mouse_default_cursor_shape).is_equal(Control.CURSOR_IBEAM)
	assert_int(dialog.plate_field.mouse_default_cursor_shape).is_equal(Control.CURSOR_IBEAM)
	dialog.cans[2].say(false, "Lucky Lou")
	await await_idle_frame()
	assert_int(dialog.cans[2].mouse_default_cursor_shape).is_equal(ARROW)
	dialog.open_tray(1)
	await await_idle_frame()
	for cell: Control in dialog.tray.cells:
		assert_int(cell.mouse_default_cursor_shape).is_equal(HAND)
	var close := dialog.tray.get_node("Close") as Control
	assert_int(close.mouse_default_cursor_shape).is_equal(HAND)
	var rail := dialog._rail
	var key := dialog.keys[0]
	rail._gui_input(_motion(key.position + key.size * 0.5))
	assert_int(rail.mouse_default_cursor_shape).is_equal(HAND)
	rail._gui_input(_motion(Vector2(rail.size.x - 4.0, 4.0)))
	assert_int(rail.mouse_default_cursor_shape).is_equal(ARROW)


## The license and the bay peeking in on the title, Kit's folder peeking in, and the folder waiting
## on a map under way, which does not open.
func test_the_peeks_show_the_hand() -> void:
	Game.settings.license_number = "JJ-212212"
	var title: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(title)
	await await_idle_frame()
	title.call("show_clubhouse", true)
	await await_idle_frame()
	var license := title.find_child("LicensePeek", true, false) as Control
	var bay := title.find_child("BayPeek", true, false) as Control
	assert_int(license.mouse_default_cursor_shape).is_equal(HAND)
	assert_int(bay.mouse_default_cursor_shape).is_equal(HAND)
	var folder := _added(FolderPeek.new())
	assert_int(folder.mouse_default_cursor_shape).is_equal(HAND)
	var waiting := FolderPeek.new()
	waiting.standing = true
	waiting.waiting = true
	assert_int(_added(waiting).mouse_default_cursor_shape).is_equal(ARROW)


## STORY.md 7.2: the hand over the open folder, whose pages turn on a click, and the arrow beside
## it, where a click puts it away.
func test_kits_folder_shows_the_hand_over_its_pages() -> void:
	var profile := Game.settings.profile
	profile.story.notes = PackedInt32Array([1, 3])
	profile.story.notes_read = PackedInt32Array([1, 3])
	var notes := NotesFolder.open(_holder, profile, true)
	for i: int in 80:
		if not notes.is_busy():
			break
		await await_millis(50)
	var over := notes.folder.get_global_rect().get_center() - notes.global_position
	notes.gui_input.emit(_motion(over))
	assert_int(notes.mouse_default_cursor_shape).is_equal(HAND)
	notes.gui_input.emit(_motion(Vector2(4.0, 4.0)))
	assert_int(notes.mouse_default_cursor_shape).is_equal(ARROW)
