extends GdUnitTestSuite
## The Video page of the settings, GAME.md 8.5: what a platform has no use for is not on it. A phone
## or a tablet plays full screen and in step with its own screen whatever it is told, and a
## renderer without FSR 2 is not offered it.

const SETTINGS_SCENE := preload("res://scenes/ui/settings_screen.tscn")


func _page(handheld: bool, full_renderer: bool) -> VideoTab:
	var settings := Settings.new()
	settings.path = "user://test_video_tab.cfg"
	var tab: VideoTab = auto_free(VideoTab.make(settings, handheld, full_renderer))
	add_child(tab)
	return tab


## The names of the rows under the heading [param group], or of every row on the page, group by
## group, for none.
static func _rows(tab: VideoTab, group := "") -> Array[String]:
	var names: Array[String] = []
	for each: Node in tab._groups.get_children():
		if not group.is_empty() and each.name != group:
			continue
		for row: Node in each.get_children():
			var label := row.get_child(0) as Label
			if row.name != "Heading" and label != null:
				names.append(label.text)
	return names


static func _upscaler_box(tab: VideoTab) -> OptionButton:
	for each: Node in tab._groups.get_children():
		for row: Node in each.get_children():
			if (row.get_child(0) as Label).text == "Upscaler":
				return row.get_child(1) as OptionButton
	return null


func test_a_desktop_has_the_window_and_every_upscaler() -> void:
	var tab := _page(false, true)
	var rows := _rows(tab)
	assert_array(rows).contains(
		["Fullscreen", "Window size", "V-sync", "Upscaler", "MSAA", "Show FPS"]
	)
	assert_int(_upscaler_box(tab).item_count).is_equal(3)


func test_a_phone_has_no_window_settings_and_no_fsr_2() -> void:
	var tab := _page(true, false)
	var rows := _rows(tab)
	assert_array(rows).not_contains(["Fullscreen", "Window size", "V-sync"])
	assert_array(rows).contains(["Render scale", "Upscaler", "Shadows", "Frame rate limit"])
	var box := _upscaler_box(tab)
	assert_int(box.item_count).is_equal(2)
	assert_str(box.get_item_text(1)).is_equal("FSR 1")


## FSR 2 kept from a desktop's settings reads as the FSR 1 it is drawn with on a phone's renderer.
func test_fsr_2_from_elsewhere_shows_as_fsr_1() -> void:
	var settings := Settings.new()
	settings.path = "user://test_video_tab.cfg"
	settings.upscaler = Settings.UPSCALE_FSR2
	var tab: VideoTab = auto_free(VideoTab.make(settings, true, false))
	add_child(tab)
	assert_int(_upscaler_box(tab).selected).is_equal(1)


## GAME.md 8.5: Texture detail is on the page on a desktop and on a phone alike, Auto, Low and High,
## and Ultra too where the renderer is the desktop's, said to the mouse and to a screen reader, and
## sets the setting.
func test_texture_detail_is_on_every_page() -> void:
	for handheld: bool in [false, true]:
		var tab := _page(handheld, not handheld)
		assert_array(_rows(tab)).contains([VideoTab.TEXTURES])
		var box := tab.find_child("TextureDetail", true, false) as OptionButton
		assert_object(box).is_not_null()
		assert_int(box.item_count).is_equal(3 if handheld else 4)
		assert_str(box.get_item_text(box.item_count - 1)).is_equal("High" if handheld else "Ultra")
		# Auto says which of Low or High it comes out as on this screen, in brackets.
		assert_str(box.get_item_text(box.selected)).starts_with("Auto (")
		assert_str(box.accessibility_name).is_equal(VideoTab.TEXTURES)
		assert_str(box.accessibility_description).is_equal(VideoTab.TEXTURES_TIP)
		assert_str(box.tooltip_text).is_equal(VideoTab.TEXTURES_TIP)
		box.select(1)
		box.item_selected.emit(1)
		assert_str(tab._settings.texture_detail).is_equal(Settings.TEXTURES_LOW)


## Ultra kept from a desktop's settings reads as the High it is drawn at on a phone's renderer.
func test_ultra_from_elsewhere_shows_as_high() -> void:
	var settings := Settings.new()
	settings.path = "user://test_video_tab.cfg"
	settings.texture_detail = Settings.TEXTURES_ULTRA
	var tab: VideoTab = auto_free(VideoTab.make(settings, true, false))
	add_child(tab)
	var box := tab.find_child("TextureDetail", true, false) as OptionButton
	assert_str(box.get_item_text(box.selected)).is_equal("High")


## GAME.md 8.5: the page's rows in groups under headings, what is seen and played down the left and
## what it costs the card down the right, each row in the group it belongs with.
func test_the_rows_stand_in_groups_under_headings() -> void:
	var tab := _page(false, true)
	var headings: Array[String] = []
	for each: Node in tab._groups.get_children():
		headings.append((each.get_node("Heading/Title") as Label).text)
	assert_array(headings).is_equal(
		[VideoTab.DISPLAY, VideoTab.CAMERA, VideoTab.TABLE, VideoTab.PERFORMANCE, VideoTab.GRAPHICS]
	)
	assert_int(tab._groups.split).is_equal(3)
	assert_array(_rows(tab, VideoTab.DISPLAY)).contains_exactly(
		[VideoTab.SCREEN, "Fullscreen", "Window size", "UI scale", "Brightness"]
	)
	assert_array(_rows(tab, VideoTab.CAMERA)).contains_exactly(
		["Camera distance", VideoTab.FOLLOWS, VideoTab.FIXED]
	)
	assert_array(_rows(tab, VideoTab.TABLE)).contains_exactly(
		["Look", "Looks bar", "Tire marks", "Crowd"]
	)
	assert_array(_rows(tab, VideoTab.PERFORMANCE)).contains_exactly(
		["V-sync", "Frame rate limit", "Render scale", "Upscaler", "Show FPS"]
	)
	var graphics: Array[String] = [
		VideoTab.QUALITY,
		"Shadows",
		VideoTab.TEXTURES,
		"Ambient occlusion",
		"Bloom",
		"MSAA",
		"Screen smoothing",
	]
	assert_array(_rows(tab, VideoTab.GRAPHICS)).contains_exactly(graphics)


## GAME.md 8.5: two columns side by side where the page is wide enough, the Display, Camera and
## Table groups on the left and the rest on the right; one under the other where it is not.
func test_the_groups_stand_in_two_columns_where_there_is_room() -> void:
	var tab := _page(false, true)
	tab.size = Vector2(1800.0, 900.0)
	await await_idle_frame()
	var display := tab._groups.get_node(VideoTab.DISPLAY) as Control
	var table := tab._groups.get_node(VideoTab.TABLE) as Control
	var performance := tab._groups.get_node(VideoTab.PERFORMANCE) as Control
	assert_bool(tab._groups.two_columns(tab._groups.size.x)).is_true()
	assert_float(performance.position.y).is_equal(0.0)
	assert_float(performance.position.x).is_greater(display.size.x)
	assert_float(table.position.x).is_equal(0.0)
	tab.size = Vector2(900.0, 900.0)
	await await_idle_frame()
	assert_bool(tab._groups.two_columns(tab._groups.size.x)).is_false()
	assert_float(performance.position.x).is_equal(0.0)
	assert_float(performance.position.y).is_greater(table.position.y)


## A pad walks the page as it stands: down a column from one group into the next, and right from a
## row on the left to the one across from it on the right.
func test_a_pad_walks_down_a_column_and_across_to_the_other() -> void:
	var tab := _page(false, true)
	tab.size = Vector2(1800.0, 1400.0)
	await await_idle_frame()
	var display := tab._groups.get_node(VideoTab.DISPLAY) as Control
	var camera := tab._groups.get_node(VideoTab.CAMERA) as Control
	var performance := tab._groups.get_node(VideoTab.PERFORMANCE) as Control
	var last_row := display.get_child(display.get_child_count() - 1)
	var under := (last_row.get_child(1) as Control).find_valid_focus_neighbor(SIDE_BOTTOM)
	assert_bool(camera.is_ancestor_of(under)).is_true()
	var first := display.get_child(1).get_child(1) as Control
	var across := first.find_valid_focus_neighbor(SIDE_RIGHT)
	assert_bool(performance.is_ancestor_of(across)).is_true()
	assert_bool(display.is_ancestor_of(across.find_valid_focus_neighbor(SIDE_LEFT))).is_true()


## GAME.md 8.5: the fixed camera is one setting under Camera here and in Accessibility, and each
## page's switch shows what the other set as its page comes up.
func test_the_fixed_camera_is_one_setting_on_both_pages() -> void:
	var settings_were := Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_video_tab.cfg"
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	var on_video := _switch(screen, "Video")
	var on_access := _switch(screen, "Accessibility")
	screen.tabs.current_tab = screen.tabs.get_node("Video").get_index()
	await await_idle_frame()
	on_video.button_pressed = true
	assert_bool(Game.settings.fixed_camera).is_true()
	screen.tabs.current_tab = screen.tabs.get_node("Accessibility").get_index()
	await await_idle_frame()
	assert_bool(on_access.button_pressed).is_true()
	on_access.button_pressed = false
	screen.tabs.current_tab = screen.tabs.get_node("Video").get_index()
	await await_idle_frame()
	assert_bool(on_video.button_pressed).is_false()
	Settings.remove_files(Game.settings.path)
	Game.settings = settings_were


## The fixed camera's switch on the settings page [param page].
static func _switch(screen: SettingsScreen, page: String) -> CheckButton:
	for row: Node in screen.tabs.get_node(page).find_children("*", "HBoxContainer", true, false):
		var label := row.get_child(0) as Label
		if label != null and label.text == VideoTab.FIXED:
			return row.get_child(1) as CheckButton
	return null


## GAME.md 8.5: Render scale and Brightness say beside their sliders what they are set to, a share
## of the screen's size and of the room's own exposure, and say it again as they move.
func test_the_two_sliders_say_what_they_are_set_to() -> void:
	var tab := _page(false, true)
	for named: String in ["Render scale", "Brightness"]:
		var both := _control(tab, named)
		var slider := both.get_child(0) as HSlider
		var said := both.get_node("Value") as Label
		assert_str(said.text).is_equal("100%")
		slider.value = 0.8
		assert_str(said.text).is_equal("80%")
		# The slider, which takes the cursor, is the one named for a screen reader.
		assert_str(slider.accessibility_name).is_equal(named)
	assert_float(tab._settings.render_scale).is_equal_approx(0.8, 0.001)
	assert_float(tab._settings.brightness).is_equal_approx(0.8, 0.001)


## What stands beside the row named [param named] on [param tab].
static func _control(tab: VideoTab, named: String) -> Control:
	for each: Node in tab._groups.get_children():
		for row: Node in each.get_children():
			var label := row.get_child(0) as Label
			if row.name != "Heading" and label != null and label.text == named:
				return row.get_child(1) as Control
	return null
