extends GdUnitTestSuite
## The title screen, GAME.md 8.1a: a calm sunburst that stops short of the screen's sides, chips
## out at the edges, the opening the first time it comes up in a run, and the settings it opens
## with their whole foot left to the page, 8.5.

const TEST_SETTINGS_PATH := "user://test_title_screen.cfg"
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
	assert_bool(back.has_focus()).is_true()
	assert_bool(screen.tabs.tabs_visible).is_false()
	assert_int(screen.tab_bar.tab_count).is_equal(screen.tabs.get_tab_count())
	assert_str(screen.tab_bar.get_tab_title(1)).is_equal(screen.tabs.get_tab_title(1))
	screen.tab_bar.current_tab = 2
	assert_int(screen.tabs.current_tab).is_equal(2)
	screen.switch_tab(1)
	assert_int(screen.tab_bar.current_tab).is_equal(3)
	assert_bool(screen.tab_hint.visible).is_equal(SettingsScreen.pad_plugged_in())
	assert_str(screen.tab_hint.get_parent().name).is_equal("TabsRow")
