extends GdUnitTestSuite
## The title screen, GAME.md 8.1a: a calm sunburst that stops short of the screen's sides, chips
## out at the edges, the opening the first time it comes up in a run, and the settings it opens
## with their whole foot left to the page, 8.5.

const TEST_SETTINGS_PATH := "user://test_title_screen.cfg"
const WARMUP_STAMP := "user://test_title_screen_warmup.cfg"
const TITLE_SCENE := preload("res://scenes/ui/title.tscn")
const SETTINGS_SCENE := preload("res://scenes/ui/settings_screen.tscn")

var _real: Settings


func before_test() -> void:
	_real = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = TEST_SETTINGS_PATH


func after_test() -> void:
	TitleIntro.force = false
	TitleIntro.played = false
	ShaderWarmup.force = false
	ShaderWarmup.done = false
	ShaderWarmup.stamp_path = ShaderWarmup.STAMP_PATH
	DirAccess.remove_absolute(ProjectSettings.globalize_path(WARMUP_STAMP))
	Game.settings = _real
	Settings.remove_files(TEST_SETTINGS_PATH)


## A title's background over a screen of [param size], centered on a mark like the title's.
func _background(size: Vector2) -> TitleBackground:
	var screen := Control.new()
	screen.size = size
	add_child(screen)
	var back := TitleBackground.add_to(screen)
	back.size = size
	var mark := Control.new()
	mark.size = Vector2(132.0, 132.0)
	mark.position = Vector2(size.x * 0.5 - 66.0, 90.0)
	screen.add_child(mark)
	back.anchor = mark
	return back


## The sunburst reaches neither side of the screen nor its foot, and is faded to nothing by its
## edge, whatever shape the screen is: the light is round the mark, not over the menu.
func test_the_sunburst_stops_short_of_the_sides_and_the_foot() -> void:
	for size: Vector2 in [Vector2(1600.0, 900.0), Vector2(1600.0, 720.0), Vector2(720.0, 1280.0)]:
		var back := _background(size)
		await await_idle_frame()
		var at := back.focus()
		var reach := back.reach()
		assert_float(reach).is_greater(0.0)
		assert_float(at.x - reach).is_greater(0.0)
		assert_float(at.x + reach).is_less(size.x)
		assert_float(at.y + reach).is_less(size.y)
		assert_float(TitleBackground.Sunburst.light_at(0.0, reach)).is_equal(1.0)
		assert_float(TitleBackground.Sunburst.light_at(reach * 0.6, reach)).is_less(0.6)
		assert_float(TitleBackground.Sunburst.light_at(reach, reach)).is_equal(0.0)
		back.get_parent().free()


## The chips fade the other way to the beams: gone at the mark, all there out at the edges.
func test_the_chips_fade_out_toward_the_mark() -> void:
	var back := _background(Vector2(1600.0, 900.0))
	await await_idle_frame()
	var at := back.focus()
	assert_float(back.chip_strength(at)).is_equal(0.0)
	assert_float(back.chip_strength(at + Vector2(back.reach() * 0.3, 0.0))).is_equal(0.0)
	assert_float(back.chip_strength(Vector2(0.0, 900.0))).is_equal(1.0)
	assert_float(back.chip_strength(Vector2(20.0, 450.0))).is_greater(
		back.chip_strength(Vector2(700.0, 450.0))
	)
	back.get_parent().free()


## The seal's rings come up band by band, the inner one first.
func test_the_seal_comes_up_band_by_band() -> void:
	var back := _background(Vector2(1600.0, 900.0))
	await await_idle_frame()
	back.rings = 0.3
	assert_float(back._seal.band_shown(0)).is_greater(back._seal.band_shown(1))
	assert_float(back._seal.band_shown(2)).is_equal(0.0)
	back.rings = 1.0
	for band: int in TitleBackground.SEAL_BANDS.size():
		assert_float(back._seal.band_shown(band)).is_equal(1.0)
	back.get_parent().free()


## Nothing on the settled title is drawn again a frame, GAME.md 10.7: the burst and the seal turn
## whole, and the glow is drawn again only when it moves.
func test_the_title_turns_without_drawing_again() -> void:
	var back := _background(Vector2(1600.0, 900.0))
	await await_idle_frame()
	await await_idle_frame()
	var drawn := [0]
	for part: CanvasItem in [back, back._burst, back._seal]:
		part.draw.connect(func() -> void: drawn[0] += 1)
	var turned := back._burst.rotation
	for i: int in 5:
		await await_idle_frame()
	assert_float(back._burst.rotation).is_not_equal(turned)
	assert_int(drawn[0]).is_equal(0)
	back.get_parent().free()


## The opening lays each part from nothing to where it rests, the mark held back for the large one
## flying into its place, and ends with every part at its end however it ends.
func test_the_opening_lays_its_parts_and_ends_where_they_rest() -> void:
	var screen := Control.new()
	screen.size = Vector2(1600.0, 900.0)
	add_child(screen)
	var column := VBoxContainer.new()
	screen.add_child(column)
	var mark := Control.new()
	mark.custom_minimum_size = Vector2(132.0, 132.0)
	column.add_child(mark)
	var laid: Array[float] = []
	var intro := TitleIntro.over(screen, mark, column)
	intro.add(0.5, 1.0, func(by: float) -> void: laid.append(by))
	var ended := [false]
	intro.finished.connect(func() -> void: ended[0] = true)
	assert_float(laid[0]).is_equal(0.0)
	await await_idle_frame()
	assert_float(mark.modulate.a).is_equal(0.0)
	intro.finish()
	assert_bool(ended[0]).is_true()
	assert_float(laid[-1]).is_equal(1.0)
	assert_float(mark.modulate.a).is_equal(1.0)
	assert_bool(intro.is_queued_for_deletion()).is_true()
	assert_bool(TitleIntro.played).is_true()
	screen.free()


## Any key, button, click or tap ends the opening, and is spent on that rather than also pressing
## what the cursor lands on; the mouse moving or a stick drifting does not.
func test_any_press_skips_the_opening_and_nothing_else_does() -> void:
	var stays: Array[InputEvent] = [InputEventMouseMotion.new(), InputEventJoypadMotion.new()]
	for event: InputEvent in stays:
		assert_bool(TitleIntro._skips(event)).is_false()
	var key := InputEventKey.new()
	key.keycode = KEY_ENTER
	key.pressed = true
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_A
	button.pressed = true
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	for event: InputEvent in [key, button, click, tap]:
		assert_bool(TitleIntro._skips(event)).is_true()
	var let_go := InputEventKey.new()
	let_go.keycode = KEY_ENTER
	assert_bool(TitleIntro._skips(let_go)).is_false()


## The title opening holds the cursor, the buttons and the backdrop back until it is over, and a
## press puts every one of them where it rests with the cursor on Play.
func test_the_title_opens_and_a_press_skips_to_the_menu() -> void:
	TitleIntro.force = true
	var title: Control = auto_free(TITLE_SCENE.instantiate())
	var runner: GdUnitSceneRunner = scene_runner(title)
	await runner.simulate_frames(2, 17)
	var intro := title.get_node("Intro") as TitleIntro
	assert_object(intro).is_not_null()
	assert_bool(title.play_button.has_focus()).is_false()
	assert_float(title.play_button.modulate.a).is_equal(0.0)
	assert_float((title.get_node("Backdrop") as CanvasItem).modulate.a).is_equal(0.0)
	assert_float((title.get_node("Background") as TitleBackground).beams).is_equal(0.0)
	var key := InputEventKey.new()
	key.keycode = KEY_ENTER
	key.physical_keycode = KEY_ENTER
	key.pressed = true
	intro._input(key)
	await runner.simulate_frames(2, 17)
	assert_bool(is_instance_valid(intro)).is_false()
	assert_bool(title.play_button.has_focus()).is_true()
	assert_float(title.play_button.modulate.a).is_equal(1.0)
	assert_float((title.get_node("Backdrop") as CanvasItem).modulate.a).is_equal(1.0)
	assert_float((title.get_node("Background") as TitleBackground).beams).is_equal(1.0)


## With shaders to compile, their pane comes up first over the screen as the opening starts it,
## and the opening waits; skipped, or done, the opening plays from its start.
func test_the_opening_waits_for_the_shaders() -> void:
	TitleIntro.force = true
	ShaderWarmup.done = false
	ShaderWarmup.force = true
	ShaderWarmup.stamp_path = WARMUP_STAMP
	DirAccess.remove_absolute(ProjectSettings.globalize_path(WARMUP_STAMP))
	var title: Control = auto_free(TITLE_SCENE.instantiate())
	var runner: GdUnitSceneRunner = scene_runner(title)
	await runner.simulate_frames(10, 17)
	var intro := title.get_node("Intro") as TitleIntro
	assert_object(title.warming).is_not_null()
	assert_float(intro._time).is_equal(0.0)
	assert_float(title.play_button.modulate.a).is_equal(0.0)
	assert_bool(title.warming.get_index() > intro.get_index()).is_true()
	# A press while it compiles is the pane's, not the opening's.
	var key := InputEventKey.new()
	key.keycode = KEY_A
	key.pressed = true
	intro._input(key)
	assert_bool(intro._over).is_false()
	title.warming.skip()
	await runner.simulate_frames(10, 17)
	assert_object(title.warming).is_null()
	assert_float(intro._time).is_greater(0.0)
	assert_bool(intro._over).is_false()
	intro.finish()
	assert_bool(title.play_button.has_focus()).is_true()


## Where nothing is drawn, and for a tool's run, there is no opening: the title is simply there.
func test_no_opening_where_nothing_is_drawn() -> void:
	assert_bool(TitleIntro.wanted()).is_false()
	var title: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(title)
	assert_object(title.get_node_or_null("Intro")).is_null()
	assert_bool(title.play_button.has_focus()).is_true()


## The settings keep their foot for the page, GAME.md 8.5: the title at the left of the head and
## Back at its right, the tabs a bar of their own kept with the pages, and the shoulder buttons at
## its end only while a gamepad is plugged in.
func test_the_settings_leave_their_foot_to_the_page() -> void:
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	await await_idle_frame()
	var back := screen.find_child("Back", true, false) as Button
	assert_str(back.get_parent().name).is_equal("Head")
	assert_str(screen.status.get_parent().name).is_equal("Head")
	# The cursor starts on the page's first thing rather than on Back, and down from the head goes
	# there, whatever is nearest under it.
	var first := SettingsScreen._first_focusable(screen.tabs.get_current_tab_control())
	assert_object(first).is_not_null()
	assert_bool(first.has_focus()).is_true()
	assert_object(back.find_valid_focus_neighbor(SIDE_BOTTOM)).is_same(first)
	assert_object(screen.tab_bar.find_valid_focus_neighbor(SIDE_BOTTOM)).is_same(first)
	assert_bool(screen.tabs.tabs_visible).is_false()
	assert_int(screen.tab_bar.tab_count).is_equal(screen.tabs.get_tab_count())
	assert_str(screen.tab_bar.get_tab_title(1)).is_equal(screen.tabs.get_tab_title(1))
	screen.tab_bar.current_tab = 2
	assert_int(screen.tabs.current_tab).is_equal(2)
	screen.switch_tab(1)
	assert_int(screen.tab_bar.current_tab).is_equal(3)
	first = SettingsScreen._first_focusable(screen.tabs.get_current_tab_control())
	assert_object(back.find_valid_focus_neighbor(SIDE_BOTTOM)).is_same(first)
	assert_bool(screen.tab_hint.visible).is_equal(SettingsScreen.pad_plugged_in())
	assert_str(screen.tab_hint.get_parent().name).is_equal("TabsRow")


## GAME.md 3.8: the Clubhouse puts the Catalog, the Garage and Back in the place of the title's own
## buttons, the cursor on the first, nothing over them moving; Back, the button or the key, brings
## the title's own back, the cursor on the Clubhouse; and the Catalog opens the catalog over the
## title, the cursor back on it once it goes.
func test_the_clubhouse_holds_the_garage_and_the_catalog() -> void:
	var title: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(title)
	await await_idle_frame()
	var clubhouse := title.find_child("Clubhouse", true, false) as Button
	var garage := title.find_child("Garage", true, false) as Button
	var catalog := title.find_child("Catalog", true, false) as Button
	assert_bool(clubhouse.visible).is_true()
	assert_bool(garage.visible).is_false()
	assert_bool(catalog.visible).is_false()
	var mark := title.get("_mark") as Control
	var mark_at := mark.global_position
	var play_at: Vector2 = title.play_button.global_position
	clubhouse.pressed.emit()
	assert_bool(title.in_clubhouse()).is_true()
	assert_bool(title.play_button.visible).is_false()
	assert_bool(catalog.has_focus()).is_true()
	# The column keeps its height: the mark stays where it was, and the Catalog stands where Play
	# did, the Garage under it.
	await await_idle_frame()
	await await_idle_frame()
	assert_vector(mark.global_position).is_equal_approx(mark_at, Vector2.ONE)
	assert_vector(catalog.global_position).is_equal_approx(play_at, Vector2.ONE)
	assert_float(garage.global_position.y).is_greater(catalog.global_position.y)
	catalog.pressed.emit()
	await await_idle_frame()
	var dialog := title.get_node("Catalog") as CatalogDialog
	assert_object(dialog).is_not_null()
	dialog.close()
	await await_idle_frame()
	assert_bool(catalog.has_focus()).is_true()
	var back := InputEventAction.new()
	back.action = &"ui_cancel"
	back.pressed = true
	title._unhandled_input(back)
	assert_bool(title.in_clubhouse()).is_false()
	assert_bool(title.play_button.visible).is_true()
	assert_bool(clubhouse.has_focus()).is_true()
	await await_idle_frame()
	await await_idle_frame()
	assert_vector(mark.global_position).is_equal_approx(mark_at, Vector2.ONE)


## The License tab has the way to the catalog at its foot, whatever the license, which opens it
## over the settings, from a room's pause menu too; its Tab is the catalog's while it is up.
func test_the_license_tab_opens_the_catalog() -> void:
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	await await_idle_frame()
	var tab := screen.find_child("License", true, false) as LicenseTab
	assert_object(tab.catalog).is_not_null()
	tab.catalog.pressed.emit()
	await await_idle_frame()
	assert_object(tab.catalog_dialog).is_not_null()
	assert_object(tab.catalog_dialog.get_parent()).is_same(screen)
	tab.catalog_dialog.close()
	await await_idle_frame()
	assert_object(tab.catalog_dialog).is_null()


## The License tab has the way to the loyalty program's map beside the catalog's once the House has
## welcomed the profile, saying how much of it is won, and none before; it opens the program over
## the settings.
func test_the_license_tab_opens_the_program() -> void:
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	await await_idle_frame()
	var tab := screen.find_child("License", true, false) as LicenseTab
	assert_object(tab.program).is_null()
	remove_child(screen)
	Game.settings.profile.loyalty.welcomed = true
	var welcomed: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(welcomed)
	await await_idle_frame()
	tab = welcomed.find_child("License", true, false) as LicenseTab
	assert_object(tab.program).is_not_null()
	assert_object(tab.find_child("Won", true, false)).is_not_null()
	tab.program.pressed.emit()
	await await_idle_frame()
	assert_object(tab.program_dialog).is_not_null()
	tab.program_dialog.close()
	await await_idle_frame()
	assert_object(tab.program_dialog).is_null()
	Game.settings.profile.loyalty.welcomed = false


## The Driving School is a way in to the license until it is earned, among the title's own buttons;
## then a lesson to go back over, under the Clubhouse, and the title's own buttons are fewer.
func test_the_school_goes_under_the_clubhouse_once_licensed() -> void:
	var before: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(before)
	await await_idle_frame()
	var school: Button = before.find_child("DrivingSchool", true, false)
	assert_bool((before.get("_main") as Array).has(school)).is_true()
	assert_bool(school.visible).is_true()
	remove_child(before)
	Game.settings.license_number = "JJ-212212"
	var title: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(title)
	await await_idle_frame()
	school = title.find_child("DrivingSchool", true, false)
	assert_bool((title.get("_main") as Array).has(school)).is_false()
	assert_bool(school.visible).is_false()
	title.call("show_clubhouse", true)
	assert_bool(school.visible).is_true()
	assert_bool((title.get("_clubhouse") as Array).has(school)).is_true()
	title.call("show_clubhouse", false)
	assert_bool(school.visible).is_false()
