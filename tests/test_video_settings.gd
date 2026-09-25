extends GdUnitTestSuite
## What a player can hand back of the picture, GAME.md 8.5: the bloom over a room and the
## smoothing on its edges above all. Both are worth what they cost on a card that can spare it,
## and both are the first thing to give up on one that cannot.

const ROOM: RoomLook = preload("res://data/rooms/after_hours.tres")

var _was_bloom := true
var _was_msaa := 2
var _was_smoothing := Settings.SMOOTH_OFF
var _was_ui_scale := 1.0


func before_test() -> void:
	_was_bloom = Game.settings.bloom
	_was_msaa = Game.settings.msaa
	_was_smoothing = Game.settings.screen_smoothing
	_was_ui_scale = Game.settings.ui_scale


func after_test() -> void:
	Game.settings.bloom = _was_bloom
	Game.settings.msaa = _was_msaa
	Game.settings.screen_smoothing = _was_smoothing
	Game.settings.ui_scale = _was_ui_scale
	Settings.ui_scale_for_now = 0.0
	Game.settings.apply_video(get_tree())
	# The tests run at the size things were laid out at, whatever this machine's setting is.
	get_tree().root.content_scale_factor = 1.0


## The card room asks for bloom and gets it, until the player says otherwise.
func test_the_bloom_follows_the_setting() -> void:
	var lighting: ArenaEnvironment = auto_free(ArenaEnvironment.new())
	add_child(lighting)
	Game.settings.bloom = true
	lighting.dress(ROOM)
	assert_bool(lighting.world.environment.glow_enabled).is_true()
	Game.settings.bloom = false
	lighting.dress(ROOM)
	assert_bool(lighting.world.environment.glow_enabled).is_false()


## And it comes back on the room that is already lit rather than on the next match.
func test_a_lit_room_takes_the_setting_at_once() -> void:
	var lighting: ArenaEnvironment = auto_free(ArenaEnvironment.new())
	add_child(lighting)
	Game.settings.bloom = true
	lighting.dress(ROOM)
	Game.settings.bloom = false
	ArenaEnvironment.relight(get_tree())
	assert_bool(lighting.world.environment.glow_enabled).is_false()


## The edges are multisampled at as many samples as the MSAA box says, and the finished picture
## smoothed by whichever pass the Screen smoothing box says, each on its own.
func test_the_edges_are_smoothed_as_the_two_boxes_say() -> void:
	var cases: Array[Array] = [
		[2, Settings.SMOOTH_OFF, Viewport.MSAA_2X, Viewport.SCREEN_SPACE_AA_DISABLED],
		[0, Settings.SMOOTH_FXAA, Viewport.MSAA_DISABLED, Viewport.SCREEN_SPACE_AA_FXAA],
		[4, Settings.SMOOTH_SMAA, Viewport.MSAA_4X, Viewport.SCREEN_SPACE_AA_SMAA],
		[8, Settings.SMOOTH_OFF, Viewport.MSAA_8X, Viewport.SCREEN_SPACE_AA_DISABLED],
	]
	for case: Array in cases:
		Game.settings.msaa = case[0]
		Game.settings.screen_smoothing = case[1]
		Game.settings.apply_video(get_tree())
		assert_int(get_tree().root.msaa_3d).is_equal(case[2])
		assert_int(get_tree().root.screen_space_aa).is_equal(case[3])


## A settings file from when the two were one switch, Edge smoothing, reads as what that switch
## did: on was the multisampling, off the cheap pass over the picture.
func test_the_old_edge_smoothing_switch_carries_over() -> void:
	var path := "user://test_video_settings_old.cfg"
	for smoothed: bool in [true, false]:
		var old := ConfigFile.new()
		old.set_value("video", "antialiasing", smoothed)
		assert_int(old.save(path)).is_equal(OK)
		var read := Settings.new()
		read.path = path
		read.load_from_disk()
		assert_int(read.msaa).is_equal(2 if smoothed else 0)
		assert_str(read.screen_smoothing).is_equal(
			Settings.SMOOTH_OFF if smoothed else Settings.SMOOTH_FXAA
		)
	DirAccess.remove_absolute(path)


## The bloom, the two smoothings and the tire marks of GAME.md 4.3 survive a trip through the
## settings file. The marks are on until somebody turns them off.
func test_the_picture_is_remembered() -> void:
	var settings := Settings.new()
	settings.path = "user://test_video_settings.cfg"
	assert_bool(settings.tire_marks).is_true()
	settings.bloom = false
	settings.msaa = 4
	settings.screen_smoothing = Settings.SMOOTH_SMAA
	settings.tire_marks = false
	assert_int(settings.save_to_disk()).is_equal(OK)
	var read := Settings.new()
	read.path = settings.path
	read.load_from_disk()
	assert_bool(read.bloom).is_false()
	assert_int(read.msaa).is_equal(4)
	assert_str(read.screen_smoothing).is_equal(Settings.SMOOTH_SMAA)
	assert_bool(read.tire_marks).is_false()
	DirAccess.remove_absolute(settings.path)


## The fixed camera of GAME.md 8.5 is remembered too, and is off until somebody asks for it.
func test_the_fixed_camera_is_off_until_it_is_asked_for() -> void:
	var settings := Settings.new()
	settings.path = "user://test_fixed_camera.cfg"
	assert_bool(settings.fixed_camera).is_false()
	settings.fixed_camera = true
	assert_int(settings.save_to_disk()).is_equal(OK)
	var read := Settings.new()
	read.path = settings.path
	read.load_from_disk()
	assert_bool(read.fixed_camera).is_true()
	DirAccess.remove_absolute(settings.path)


## A setting that is off looks like a setting that is off, GAME.md 8.5. The engine's empty tick
## box is a dark outline on a dark menu: a row that was off showed nothing beside it at all.
func test_a_switch_can_be_seen_either_way() -> void:
	var off := MenuTheme.toggle(false)
	var on := MenuTheme.toggle(true)
	var empty: Texture2D = off.get_theme_icon("unchecked")
	var full: Texture2D = on.get_theme_icon("checked")
	assert_object(empty).is_not_null()
	assert_object(full).is_not_null()
	assert_bool(empty == full).is_false()
	# Both are drawn rather than blank, and the one that is on carries the house's gold.
	var dark := empty.get_image()
	var lit := full.get_image()
	var drawn := 0
	for x: int in dark.get_width():
		if dark.get_pixel(x, dark.get_height() / 2).a > 0.5:
			drawn += 1
	assert_int(drawn).is_greater(dark.get_width() / 2)
	# A quarter of the way across, which is the track itself: clear of the soft edge round it and
	# clear of the knob, which sits at the far end while it is on.
	var middle := lit.get_pixel(lit.get_width() / 4, lit.get_height() / 2)
	assert_float(middle.r).is_greater(middle.b)
	off.free()
	on.free()


## GAME.md 8.5: the UI scale draws every menu and the HUD bigger or smaller: as laid out on a
## desktop to start with, half as big again on a phone, and remembered. One given on the command
## line is used for the run and never saved over the player's own.
func test_the_ui_scale_sizes_the_menus_and_the_hud() -> void:
	var fresh := Settings.new()
	assert_float(fresh.ui_scale).is_equal(1.5 if OS.has_feature("mobile") else 1.0)
	assert_bool(Settings.UI_SCALES.has(fresh.ui_scale)).is_true()
	Game.settings.ui_scale = 1.5
	Game.settings.apply_video(get_tree())
	assert_float(get_tree().root.content_scale_factor).is_equal(1.5)
	Settings.ui_scale_for_now = 1.25
	Game.settings.apply_video(get_tree())
	assert_float(get_tree().root.content_scale_factor).is_equal(1.25)
	Settings.ui_scale_for_now = 0.0
	var settings := Settings.new()
	settings.path = "user://test_video_settings.cfg"
	settings.ui_scale = 1.75
	Settings.ui_scale_for_now = 1.25
	assert_int(settings.save_to_disk()).is_equal(OK)
	var read := Settings.new()
	read.path = settings.path
	read.load_from_disk()
	assert_float(read.ui_scale).is_equal(1.75)
	DirAccess.remove_absolute(settings.path)


## A phone plays full screen to start with, and a desktop in a window.
func test_a_phone_starts_full_screen() -> void:
	assert_bool(Settings.new().fullscreen).is_equal(OS.has_feature("mobile"))


## A phone or a tablet starts without bloom or the multisampled smoothing, on the cheap pass over
## the picture instead, and at four fifths of the render scale, its card being the one that cannot
## spare them; a desktop starts with the lot.
func test_a_phone_starts_on_the_lighter_picture() -> void:
	var fresh := Settings.new()
	var phone := OS.has_feature("mobile")
	assert_bool(fresh.bloom).is_equal(not phone)
	assert_int(fresh.msaa).is_equal(0 if phone else 2)
	assert_str(fresh.screen_smoothing).is_equal(
		Settings.SMOOTH_FXAA if phone else Settings.SMOOTH_OFF
	)
	assert_float(fresh.render_scale).is_equal(0.8 if phone else 1.0)


## GAME.md 8.5: a room drawn under the screen's size is brought up to it the way the Upscaler box
## says, the plain stretch unless somebody asks for more. FSR 2 needs the desktop's renderer, and
## anywhere else is FSR 1.
func test_the_room_is_brought_up_to_size_the_way_the_box_says() -> void:
	var settings := Settings.new()
	assert_str(settings.upscaler).is_equal(Settings.UPSCALE_BILINEAR)
	assert_int(settings.scaling_mode()).is_equal(Viewport.SCALING_3D_MODE_BILINEAR)
	settings.upscaler = Settings.UPSCALE_FSR
	assert_int(settings.scaling_mode()).is_equal(Viewport.SCALING_3D_MODE_FSR)
	settings.upscaler = Settings.UPSCALE_FSR2
	var wanted := (
		Viewport.SCALING_3D_MODE_FSR2 if Settings.full_renderer() else Viewport.SCALING_3D_MODE_FSR
	)
	assert_int(settings.scaling_mode()).is_equal(wanted)
	settings.path = "user://test_video_settings.cfg"
	assert_int(settings.save_to_disk()).is_equal(OK)
	var read := Settings.new()
	read.path = settings.path
	read.load_from_disk()
	assert_str(read.upscaler).is_equal(Settings.UPSCALE_FSR2)
	DirAccess.remove_absolute(settings.path)
