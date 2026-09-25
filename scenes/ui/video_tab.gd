class_name VideoTab
extends ScrollContainer
## The Video page of the settings, GAME.md 8.5: the window, how sharp and how big the room and the
## UI are drawn, and what a room pays for on the card. Every change takes effect at once; the
## settings screen saves them on Back. It scrolls, as the Accessibility page does, for a phone's
## short screen under a big UI scale.
##
## What a platform has no use for is not there, GAME.md 8.5: a phone or a tablet plays full screen
## and in step with its own screen whatever it is told, so it has no Fullscreen and no V-sync, and
## a renderer without FSR 2 is not offered it.

## The upscalers the Upscaler box offers, see [constant Settings.UPSCALERS], by name.
const UPSCALER_NAMES: Array[String] = ["Bilinear", "FSR 1", "FSR 2"]

var _settings: Settings
var _column: VBoxContainer
## Whether this is a phone or a tablet, and whether the renderer is the desktop's, for the tests to
## build the page as another platform would.
var _handheld := false
var _full_renderer := true


static func make(
	settings: Settings,
	handheld := OS.has_feature("mobile"),
	full_renderer := Settings.full_renderer()
) -> VideoTab:
	var tab := VideoTab.new()
	tab.name = "Video"
	tab._settings = settings
	tab._handheld = handheld
	tab._full_renderer = full_renderer
	return tab


## The upscalers this renderer can offer, in the order the box lists them.
func upscalers() -> Array[String]:
	var offered: Array[String] = Settings.UPSCALERS.duplicate()
	if not _full_renderer:
		offered.erase(Settings.UPSCALE_FSR2)
	return offered


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_column = VBoxContainer.new()
	_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_column.add_theme_constant_override("separation", 12)
	add_child(_column)
	if not _handheld:
		_add_window()
	var limits: Array = []
	for limit: int in Settings.FRAME_LIMITS:
		limits.append("Unlimited" if limit == 0 else str(limit))
	var limit := MenuTheme.option(
		limits, maxi(Settings.FRAME_LIMITS.find(_settings.frame_limit), 0)
	)
	limit.item_selected.connect(
		func(index: int) -> void:
			_settings.frame_limit = Settings.FRAME_LIMITS[index]
			_apply()
	)
	_add("Frame rate limit", limit)
	var counter := MenuTheme.toggle(_settings.show_fps)
	counter.toggled.connect(func(on: bool) -> void: _settings.show_fps = on)
	_add("Show FPS", counter)
	var scale := HSlider.new()
	scale.min_value = 0.5
	scale.max_value = 1.0
	scale.step = 0.05
	scale.value = _settings.render_scale
	scale.custom_minimum_size = Vector2(320.0, 0.0)
	scale.value_changed.connect(
		func(v: float) -> void:
			_settings.render_scale = v
			_apply()
	)
	_add("Render scale", scale)
	var offered := upscalers()
	var names: Array = []
	for each: String in offered:
		names.append(UPSCALER_NAMES[Settings.UPSCALERS.find(each)])
	# FSR 2 kept from another renderer is drawn as FSR 1 here, see [method Settings.scaling_mode].
	var shown := _settings.upscaler
	if not shown in offered:
		shown = Settings.UPSCALE_FSR
	var upscaling := MenuTheme.option(names, maxi(offered.find(shown), 0))
	upscaling.item_selected.connect(
		func(index: int) -> void:
			_settings.upscaler = offered[index]
			_apply()
	)
	_add("Upscaler", upscaling)
	# Picked from a list rather than slid: a slider would grow and shrink the screen it is on under
	# the pointer dragging it, GAME.md 8.5.
	var sizes: Array = []
	for size: float in Settings.UI_SCALES:
		sizes.append("%d%%" % roundi(size * 100.0))
	var ui := MenuTheme.option(sizes, ui_scale_index(_settings.ui_scale))
	ui.item_selected.connect(
		func(index: int) -> void:
			_settings.ui_scale = Settings.UI_SCALES[index]
			_apply()
	)
	_add("UI scale", ui)
	# What a room pays for on the card, GAME.md 8.5. All of it takes effect at once: the smoothing
	# on the viewport, the bloom the next time a room is lit.
	var bloom := MenuTheme.toggle(_settings.bloom)
	bloom.toggled.connect(
		func(on: bool) -> void:
			_settings.bloom = on
			ArenaEnvironment.relight(get_tree())
	)
	_add("Bloom", bloom)
	var shadows := MenuTheme.option(
		["Off", "Low", "High"], maxi(Settings.SHADOW_LEVELS.find(_settings.shadows), 0)
	)
	shadows.item_selected.connect(
		func(index: int) -> void:
			_settings.shadows = Settings.SHADOW_LEVELS[index]
			_apply()
			ArenaEnvironment.relight(get_tree())
	)
	_add("Shadows", shadows)
	var samples := MenuTheme.option(
		["Off", "2x", "4x", "8x"], maxi(Settings.MSAA_SAMPLES.find(_settings.msaa), 0)
	)
	samples.item_selected.connect(
		func(index: int) -> void:
			_settings.msaa = Settings.MSAA_SAMPLES[index]
			_apply()
	)
	_add("MSAA", samples)
	var smoothing := MenuTheme.option(
		["Off", "FXAA", "SMAA"], maxi(Settings.SMOOTHINGS.find(_settings.screen_smoothing), 0)
	)
	smoothing.item_selected.connect(
		func(index: int) -> void:
			_settings.screen_smoothing = Settings.SMOOTHINGS[index]
			_apply()
	)
	_add("Screen smoothing", smoothing)
	var marks := MenuTheme.toggle(_settings.tire_marks)
	marks.toggled.connect(func(on: bool) -> void: _settings.tire_marks = on)
	_add("Tire marks", marks)


## The window mode and V-sync, which a desktop has and a phone does not.
func _add_window() -> void:
	var fullscreen := MenuTheme.toggle(_settings.fullscreen)
	fullscreen.toggled.connect(
		func(on: bool) -> void:
			_settings.fullscreen = on
			_apply()
	)
	_add("Fullscreen", fullscreen)
	var vsync := MenuTheme.toggle(_settings.vsync)
	vsync.toggled.connect(
		func(on: bool) -> void:
			_settings.vsync = on
			_apply()
	)
	_add("V-sync", vsync)


## The entry of [constant Settings.UI_SCALES] nearest [param size].
static func ui_scale_index(size: float) -> int:
	var best := 0
	for i: int in Settings.UI_SCALES.size():
		if absf(Settings.UI_SCALES[i] - size) < absf(Settings.UI_SCALES[best] - size):
			best = i
	return best


func _add(label: String, control: Control) -> void:
	_column.add_child(MenuTheme.row(label, control))


func _apply() -> void:
	_settings.apply_video(get_tree())
