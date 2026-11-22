extends GdUnitTestSuite
## How a match is seen, GAME.md 8.2 and 8.5, see [ViewChoices]: what Auto makes of the screen it is
## played on, whom the camera keeps in the picture, and that the choices are remembered.

const DESK := Vector2(1920.0, 1080.0)

var _was: Dictionary = {}


func before_test() -> void:
	var settings := Game.settings
	_was = {
		screen = settings.screen,
		follows = settings.camera_follows,
		ui = settings.ui_scale,
		for_now = Settings.ui_scale_for_now,
	}
	settings.screen = ViewChoices.SCREEN_DESK
	settings.camera_follows = ViewChoices.FOLLOW_AUTO
	settings.ui_scale = 1.0
	Settings.ui_scale_for_now = 0.0


func after_test() -> void:
	var settings := Game.settings
	settings.screen = _was.screen
	settings.camera_follows = _was.follows
	settings.ui_scale = _was.ui
	Settings.ui_scale_for_now = _was.for_now


func test_auto_comes_in_closer_on_a_tv_and_a_handheld() -> void:
	var desk := ViewChoices.auto_distance(DESK)
	Game.settings.screen = ViewChoices.SCREEN_TV
	var tv := ViewChoices.auto_distance(DESK)
	Game.settings.screen = ViewChoices.SCREEN_HANDHELD
	var handheld := ViewChoices.auto_distance(DESK)
	assert_float(tv).is_less(handheld)
	assert_float(handheld).is_less(desk)


## Auto follows everybody at a desk, and only the karts driven here on a small screen: a TV, a
## handheld, a small window, or a UI drawn bigger than it was laid out.
func test_auto_follows_my_kart_on_a_small_screen() -> void:
	assert_str(ViewChoices.follows(DESK)).is_equal(ViewChoices.FOLLOW_EVERYONE)
	assert_str(ViewChoices.follows(Vector2(1280.0, 720.0))).is_equal(ViewChoices.FOLLOW_MINE)
	Game.settings.ui_scale = 1.25
	assert_str(ViewChoices.follows(DESK)).is_equal(ViewChoices.FOLLOW_MINE)
	Game.settings.ui_scale = 1.0
	Game.settings.screen = ViewChoices.SCREEN_TV
	assert_str(ViewChoices.follows(DESK)).is_equal(ViewChoices.FOLLOW_MINE)
	# Chosen, it is what was chosen, whatever the screen.
	Game.settings.camera_follows = ViewChoices.FOLLOW_NEARBY
	assert_str(ViewChoices.follows(DESK)).is_equal(ViewChoices.FOLLOW_NEARBY)


## A window of no size, as where there is none, is not a small one: it says nothing.
func test_no_window_is_not_a_small_screen() -> void:
	assert_bool(ViewChoices.small_screen(Vector2.ZERO)).is_false()
	assert_float(ViewChoices.auto_distance(Vector2.ZERO)).is_equal(ViewChoices.auto_distance(DESK))


## The screen is the window's own size, not the 1920 by 1080 the HUD is laid out in: the camera and
## the Video page's Auto measure the same window.
func test_the_screen_is_the_window() -> void:
	var window := Vector2(DisplayServer.window_get_size())
	var scale := maxf(DisplayServer.screen_get_scale(), 1.0)
	assert_vector(ViewChoices.screen_now()).is_equal_approx(window / scale, Vector2.ONE * 0.01)


func test_the_choices_are_remembered() -> void:
	var settings := Settings.new()
	settings.path = "user://test_view_choices.cfg"
	settings.screen = ViewChoices.SCREEN_TV
	settings.camera_follows = ViewChoices.FOLLOW_NEARBY
	settings.see_through_hud = false
	settings.kart_rings = ViewChoices.RINGS_ALL
	settings.kart_marker = true
	assert_int(settings.save_to_disk()).is_equal(OK)
	var read := Settings.new()
	read.path = settings.path
	read.load_from_disk()
	assert_str(read.screen).is_equal(ViewChoices.SCREEN_TV)
	assert_str(read.camera_follows).is_equal(ViewChoices.FOLLOW_NEARBY)
	assert_bool(read.see_through_hud).is_false()
	assert_str(read.kart_rings).is_equal(ViewChoices.RINGS_ALL)
	assert_bool(read.kart_marker).is_true()
	Settings.remove_files(settings.path)


## Out of the box: see-through on, rings and marker off until asked for, Auto for the camera.
func test_the_defaults() -> void:
	var fresh := Settings.new()
	assert_bool(fresh.see_through_hud).is_true()
	assert_str(fresh.kart_rings).is_equal(ViewChoices.RINGS_OFF)
	assert_bool(fresh.kart_marker).is_false()
	assert_str(fresh.camera_follows).is_equal(ViewChoices.FOLLOW_AUTO)
	assert_str(fresh.screen).is_equal(ViewChoices.default_screen())


## Picking a screen on the Video page puts the UI at the size it suits.
func test_picking_a_screen_sets_the_ui_scale_it_suits() -> void:
	var settings := Settings.new()
	settings.path = "user://test_view_choices.cfg"
	var tab: VideoTab = auto_free(VideoTab.make(settings, false, true))
	add_child(tab)
	var box: OptionButton = null
	for row: Node in tab._column.get_children():
		if (row.get_child(0) as Label).text == VideoTab.SCREEN:
			box = row.get_child(1) as OptionButton
	assert_object(box).is_not_null()
	box.select(1)
	box.item_selected.emit(1)
	assert_str(settings.screen).is_equal(ViewChoices.SCREEN_TV)
	assert_float(settings.ui_scale).is_equal(1.25)
	assert_float(Settings.UI_SCALES[tab._ui_box.selected]).is_equal(1.25)
	Game.settings.apply_video(get_tree())
