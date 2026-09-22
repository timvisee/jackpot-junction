extends GdUnitTestSuite
## The two passes a player can hand back, GAME.md 8.5: the bloom over a room and the smoothing
## on its edges. Both are worth what they cost on a card that can spare it, and both are the
## first thing to give up on one that cannot.

const ROOM: RoomLook = preload("res://data/rooms/after_hours.tres")

var _was_bloom := true
var _was_smoothing := true


func before_test() -> void:
	_was_bloom = Game.settings.bloom
	_was_smoothing = Game.settings.antialiasing


func after_test() -> void:
	Game.settings.bloom = _was_bloom
	Game.settings.antialiasing = _was_smoothing
	Game.settings.apply_video(get_tree())


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


## Edge smoothing is multisampling or, when that is handed back, the cheap screen-space pass.
## Something has to smooth a room made of straight lines.
func test_the_edges_are_smoothed_one_way_or_the_other() -> void:
	Game.settings.antialiasing = true
	Game.settings.apply_video(get_tree())
	assert_int(get_tree().root.msaa_3d).is_equal(Viewport.MSAA_2X)
	assert_int(get_tree().root.screen_space_aa).is_equal(Viewport.SCREEN_SPACE_AA_DISABLED)
	Game.settings.antialiasing = false
	Game.settings.apply_video(get_tree())
	assert_int(get_tree().root.msaa_3d).is_equal(Viewport.MSAA_DISABLED)
	assert_int(get_tree().root.screen_space_aa).is_equal(Viewport.SCREEN_SPACE_AA_FXAA)


## Both survive a trip through the settings file.
func test_both_are_remembered() -> void:
	var settings := Settings.new()
	settings.path = "user://test_video_settings.cfg"
	settings.bloom = false
	settings.antialiasing = false
	assert_int(settings.save_to_disk()).is_equal(OK)
	var read := Settings.new()
	read.path = settings.path
	read.load_from_disk()
	assert_bool(read.bloom).is_false()
	assert_bool(read.antialiasing).is_false()
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
