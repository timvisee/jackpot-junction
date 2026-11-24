extends GdUnitTestSuite
## The Quality box over the Video page's Graphics group, GAME.md 8.5, see [QualityPresets]: a
## preset sets the six under it at once, and the box says which one they are set as, or Custom.


func _page(settings: Settings, handheld: bool, full_renderer: bool) -> VideoTab:
	settings.path = "user://test_quality_presets.cfg"
	var tab: VideoTab = auto_free(VideoTab.make(settings, handheld, full_renderer))
	add_child(tab)
	return tab


## The box beside the row named [param named] on [param tab].
static func _box(tab: VideoTab, named: String) -> OptionButton:
	var group := tab._groups.get_node(VideoTab.GRAPHICS)
	for row: Node in group.get_children():
		var label := row.get_child(0) as Label
		if row.name != "Heading" and label.text == named:
			return row.get_child(1) as OptionButton
	return null


## A desktop starts on High; Ultra is offered there and Custom is only said, never picked.
func test_a_desktop_starts_on_high() -> void:
	var tab := _page(Settings.new(), false, true)
	var box := _box(tab, VideoTab.QUALITY)
	assert_int(box.item_count).is_equal(5)
	assert_str(box.get_item_text(box.selected)).is_equal("High")
	assert_str(box.get_item_text(3)).is_equal("Ultra")
	assert_bool(box.is_item_disabled(4)).is_true()
	assert_str(box.accessibility_name).is_equal(VideoTab.QUALITY)


## A phone's own start, the six as a phone has them to begin with, reads as Low, its texture detail
## Auto drawn at the print's own size; and a phone's renderer has no Ultra.
func test_a_phones_start_reads_as_low() -> void:
	var settings := Settings.new()
	settings.shadows = Settings.SHADOWS_LOW
	settings.texture_detail = Settings.TEXTURES_AUTO
	settings.occlusion = 0.0
	settings.bloom = 0.0
	settings.msaa = 0
	settings.screen_smoothing = Settings.SMOOTH_FXAA
	var tab := _page(settings, true, false)
	var box := _box(tab, VideoTab.QUALITY)
	assert_int(box.item_count).is_equal(4)
	assert_str(box.get_item_text(box.selected)).is_equal("Low")


## Picking a preset sets the six at once, and each box under it shows its new setting.
func test_a_preset_sets_the_six_at_once() -> void:
	var tab := _page(Settings.new(), false, true)
	var box := _box(tab, VideoTab.QUALITY)
	box.select(1)
	box.item_selected.emit(1)
	for key: StringName in QualityPresets.SETS[1]:
		assert_that(tab._settings.get(key)).is_equal(QualityPresets.SETS[1][key])
	assert_str(_shown(tab, "Shadows")).is_equal("Low")
	assert_str(_shown(tab, "Ambient occlusion")).is_equal("Off")
	assert_str(_shown(tab, "Bloom")).is_equal("Normal")
	assert_str(_shown(tab, "MSAA")).is_equal("Off")
	assert_str(_shown(tab, "Screen smoothing")).is_equal("SMAA")
	assert_str(_shown(tab, VideoTab.TEXTURES)).starts_with("Auto")
	assert_str(box.get_item_text(box.selected)).is_equal("Medium")


## One of the six changed by hand makes the box say Custom; set back, the preset again.
func test_one_changed_by_hand_says_custom() -> void:
	var tab := _page(Settings.new(), false, true)
	var quality := _box(tab, VideoTab.QUALITY)
	var msaa := _box(tab, "MSAA")
	msaa.select(2)
	msaa.item_selected.emit(2)
	assert_str(quality.get_item_text(quality.selected)).is_equal(QualityPresets.CUSTOM)
	msaa.select(1)
	msaa.item_selected.emit(1)
	assert_str(quality.get_item_text(quality.selected)).is_equal("High")


## Texture detail is compared as it is drawn: High picked by hand is not Auto where Auto comes out
## Low, and is where Auto comes out High.
func test_texture_detail_counts_as_it_is_drawn() -> void:
	var settings := Settings.new()
	QualityPresets.use(settings, 2)
	settings.texture_detail = Settings.TEXTURES_HIGH
	assert_int(QualityPresets.of(settings, Settings.TEXTURES_LOW, true)).is_equal(-1)
	assert_int(QualityPresets.of(settings, Settings.TEXTURES_HIGH, true)).is_equal(2)


static func _shown(tab: VideoTab, named: String) -> String:
	var box := _box(tab, named)
	return box.get_item_text(box.selected)
