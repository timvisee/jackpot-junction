extends GdUnitTestSuite
## What a player can hand back of the picture, GAME.md 8.5: the bloom over a room and the
## smoothing on its edges above all. Both are worth what they cost on a card that can spare it,
## and both are the first thing to give up on one that cannot.

const ROOM: RoomLook = preload("res://data/rooms/after_hours.tres")

var _was_bloom := true
var _was_msaa := 2
var _was_smoothing := Settings.SMOOTH_OFF
var _was_ui_scale := 1.0
var _was_shadows := Settings.SHADOWS_HIGH


func before_test() -> void:
	_was_bloom = Game.settings.bloom
	_was_msaa = Game.settings.msaa
	_was_smoothing = Game.settings.screen_smoothing
	_was_ui_scale = Game.settings.ui_scale
	_was_shadows = Game.settings.shadows


func after_test() -> void:
	Game.settings.bloom = _was_bloom
	Game.settings.msaa = _was_msaa
	Game.settings.screen_smoothing = _was_smoothing
	Game.settings.ui_scale = _was_ui_scale
	Game.settings.shadows = _was_shadows
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
	Settings.remove_files(path)


## The bloom, the two smoothings and the tire marks of GAME.md 4.3 survive a trip through the
## settings file. A desktop lays every kart's marks until somebody says otherwise, and a file from
## when the marks were only on or off says which.
func test_the_picture_is_remembered() -> void:
	var settings := Settings.new()
	settings.path = "user://test_video_settings.cfg"
	assert_int(settings.tire_marks).is_equal(Settings.MARKS_FULL)
	settings.bloom = false
	settings.msaa = 4
	settings.screen_smoothing = Settings.SMOOTH_SMAA
	settings.tire_marks = Settings.MARKS_MINE
	assert_int(settings.save_to_disk()).is_equal(OK)
	var read := Settings.new()
	read.path = settings.path
	read.load_from_disk()
	assert_bool(read.bloom).is_false()
	assert_int(read.msaa).is_equal(4)
	assert_str(read.screen_smoothing).is_equal(Settings.SMOOTH_SMAA)
	assert_int(read.tire_marks).is_equal(Settings.MARKS_MINE)
	var old := ConfigFile.new()
	old.set_value("video", "tire_marks", false)
	old.save(settings.path)
	read.load_from_disk()
	assert_int(read.tire_marks).is_equal(Settings.MARKS_OFF)
	old.set_value("video", "tire_marks", true)
	old.save(settings.path)
	read.load_from_disk()
	assert_int(read.tire_marks).is_equal(Settings.MARKS_FULL)
	Settings.remove_files(settings.path)


## GAME.md 8.5: the crowd is one setting, Full, Half or Off, remembered through the file; a crowd
## switched off under the old switch of its own stays off.
func test_the_crowd_is_one_setting_and_the_old_switch_carries_over() -> void:
	var path := "user://test_video_settings_crowd.cfg"
	for size: float in Settings.CROWD_SIZES:
		var settings := Settings.new()
		settings.path = path
		settings.crowd_size = size
		assert_int(settings.save_to_disk()).is_equal(OK)
		var read := Settings.new()
		read.path = path
		read.load_from_disk()
		assert_float(read.crowd_size).is_equal(size)
	var old := ConfigFile.new()
	old.set_value("video", "crowd_size", 1.0)
	old.set_value("accessibility", "crowd", false)
	assert_int(old.save(path)).is_equal(OK)
	var read := Settings.new()
	read.path = path
	read.load_from_disk()
	assert_float(read.crowd_size).is_equal(0.0)
	Settings.remove_files(path)


## Offered on two pages, the box reads the setting again as its page comes up, so each shows what
## the other set.
func test_the_two_crowd_boxes_show_one_setting() -> void:
	var settings := Settings.new()
	settings.path = "user://test_video_settings_boxes.cfg"
	settings.crowd_size = 1.0
	var holder: Control = auto_free(Control.new())
	add_child(holder)
	var video := VideoTab.crowd_box(settings)
	var access := VideoTab.crowd_box(settings)
	holder.add_child(video)
	holder.add_child(access)
	access.visible = false
	video.select(2)
	video.item_selected.emit(2)
	assert_float(settings.crowd_size).is_equal(0.0)
	access.visible = true
	assert_str(access.get_item_text(access.selected)).is_equal("Off")


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
	Settings.remove_files(settings.path)


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
	Settings.remove_files(settings.path)


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
	Settings.remove_files(settings.path)


## GAME.md 8.5: the room's sun and lamp cast their shadows into big maps with soft edges, smaller
## ones with hard edges, or not at all. A desktop starts on the big ones and a phone on the small,
## which is what each renderer does of its own accord.
func test_the_shadows_follow_the_setting() -> void:
	var phone := OS.has_feature("mobile")
	assert_str(Settings.new().shadows).is_equal(
		Settings.SHADOWS_LOW if phone else Settings.SHADOWS_HIGH
	)
	var lighting: ArenaEnvironment = auto_free(ArenaEnvironment.new())
	add_child(lighting)
	Game.settings.shadows = Settings.SHADOWS_HIGH
	Game.settings.apply_video(get_tree())
	lighting.dress(ROOM)
	assert_int(get_tree().root.positional_shadow_atlas_size).is_equal(4096)
	assert_bool(lighting.lamp.shadow_enabled).is_equal(ROOM.lamp_shadow)
	Game.settings.shadows = Settings.SHADOWS_LOW
	Game.settings.apply_video(get_tree())
	assert_int(get_tree().root.positional_shadow_atlas_size).is_equal(2048)
	Game.settings.shadows = Settings.SHADOWS_OFF
	ArenaEnvironment.relight(get_tree())
	assert_bool(lighting.key.shadow_enabled).is_false()
	assert_bool(lighting.lamp.shadow_enabled).is_false()
	var settings := Settings.new()
	settings.path = "user://test_video_settings.cfg"
	settings.shadows = Settings.SHADOWS_OFF
	assert_int(settings.save_to_disk()).is_equal(OK)
	var read := Settings.new()
	read.path = settings.path
	read.load_from_disk()
	assert_str(read.shadows).is_equal(Settings.SHADOWS_OFF)
	Settings.remove_files(settings.path)


## GAME.md 8.5: the game draws no more frames a second than the limit says, as many as it can to
## start with, and as many as it can for a `--bench` whatever the limit.
func test_the_frame_rate_keeps_to_the_limit() -> void:
	var settings := Settings.new()
	assert_int(settings.frame_limit).is_equal(0)
	settings.frame_limit = 30
	settings.apply_video(get_tree())
	assert_int(Engine.max_fps).is_equal(30)
	Settings.uncapped_for_now = true
	settings.apply_video(get_tree())
	assert_int(Engine.max_fps).is_equal(0)
	Settings.uncapped_for_now = false
	settings.path = "user://test_video_settings.cfg"
	assert_int(settings.save_to_disk()).is_equal(OK)
	var read := Settings.new()
	read.path = settings.path
	read.load_from_disk()
	assert_int(read.frame_limit).is_equal(30)
	Settings.remove_files(settings.path)
	Engine.max_fps = 0
