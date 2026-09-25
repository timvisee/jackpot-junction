extends GdUnitTestSuite
## The frame rate in the corner of every screen, GAME.md 8.5: there while Show FPS is on, over
## whatever scene is up, and saying how many frames a second the game is drawing.

var _was := false


func before_test() -> void:
	_was = Game.settings.show_fps


func after_test() -> void:
	Game.settings.show_fps = _was


func test_the_counter_is_there_while_the_setting_is_on() -> void:
	var counter := Game.get_node_or_null("FrameCounter") as FrameCounter
	assert_object(counter).is_not_null()
	Game.settings.show_fps = false
	await get_tree().process_frame
	assert_bool(counter.visible).is_false()
	Game.settings.show_fps = true
	await get_tree().process_frame
	assert_bool(counter.visible).is_true()
	assert_str(counter._label.text).ends_with(" fps")
	assert_int(counter.layer).is_greater(100)
	# Off until somebody asks for it, and remembered once they have.
	var settings := Settings.new()
	assert_bool(settings.show_fps).is_false()
	settings.path = "user://test_frame_counter.cfg"
	settings.show_fps = true
	assert_int(settings.save_to_disk()).is_equal(OK)
	var read := Settings.new()
	read.path = settings.path
	read.load_from_disk()
	assert_bool(read.show_fps).is_true()
	DirAccess.remove_absolute(settings.path)
