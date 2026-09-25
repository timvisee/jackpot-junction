extends GdUnitTestSuite
## The Video page of the settings, GAME.md 8.5: what a platform has no use for is not on it. A phone
## or a tablet plays full screen and in step with its own screen whatever it is told, and a
## renderer without FSR 2 is not offered it.


func _page(handheld: bool, full_renderer: bool) -> VideoTab:
	var settings := Settings.new()
	settings.path = "user://test_video_tab.cfg"
	var tab: VideoTab = auto_free(VideoTab.make(settings, handheld, full_renderer))
	add_child(tab)
	return tab


## The names of the page's rows, top to bottom.
static func _rows(tab: VideoTab) -> Array[String]:
	var names: Array[String] = []
	for row: Node in tab._column.get_children():
		var label := row.get_child(0) as Label
		if label != null:
			names.append(label.text)
	return names


static func _upscaler_box(tab: VideoTab) -> OptionButton:
	for row: Node in tab._column.get_children():
		if (row.get_child(0) as Label).text == "Upscaler":
			return row.get_child(1) as OptionButton
	return null


func test_a_desktop_has_the_window_and_every_upscaler() -> void:
	var tab := _page(false, true)
	var rows := _rows(tab)
	assert_array(rows).contains(["Fullscreen", "V-sync", "Upscaler", "MSAA", "Show FPS"])
	assert_int(_upscaler_box(tab).item_count).is_equal(3)


func test_a_phone_has_no_window_settings_and_no_fsr_2() -> void:
	var tab := _page(true, false)
	var rows := _rows(tab)
	assert_array(rows).not_contains(["Fullscreen", "V-sync"])
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
