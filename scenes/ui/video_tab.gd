class_name VideoTab
extends ScrollContainer
## The Video page of the settings, GAME.md 8.5: the window, how sharp and how big the room and the
## UI are drawn, and what a room pays for on the card. Every change takes effect at once; the
## settings screen saves them on Back. It scrolls, as the Accessibility page does, for a phone's
## short screen under a big UI scale.

var _settings: Settings
var _column: VBoxContainer


static func make(settings: Settings) -> VideoTab:
	var tab := VideoTab.new()
	tab.name = "Video"
	tab._settings = settings
	return tab


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_column = VBoxContainer.new()
	_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_column.add_theme_constant_override("separation", 12)
	add_child(_column)
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
	var upscalers := MenuTheme.option(
		["Bilinear", "FSR 1", "FSR 2"], maxi(Settings.UPSCALERS.find(_settings.upscaler), 0)
	)
	upscalers.item_selected.connect(
		func(index: int) -> void:
			_settings.upscaler = Settings.UPSCALERS[index]
			_apply()
	)
	_add("Upscaler", upscalers)
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
